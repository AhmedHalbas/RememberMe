import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remember_me/components/app_text_field.dart';
import 'package:remember_me/database/database.dart';
import 'package:remember_me/screens/sign-in.dart';
import 'package:remember_me/screens/sign-up.dart';
import 'package:remember_me/screens/users_list_view.dart';
import 'package:remember_me/services/facenet.service.dart';
import 'package:remember_me/services/location.dart';
import 'package:remember_me/services/ml_vision_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Services injection
  FaceNetService _faceNetService = FaceNetService();
  MLVisionService _mlVisionService = MLVisionService();
  DataBaseService _dataBaseService = DataBaseService();
  Location _location = Location();
  TwilioFlutter twilioFlutter;

  CameraDescription cameraDescription;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _startUp();
    _startTime();
    _showNotification();
  }

  Future selectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => UsersListView()),
    );
  }

  _initNotification() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logo');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  _showNotification() async {
    _initNotification();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'repeating channel id',
      'repeating channel name',
      'repeating description',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
          'click here if you\'re lost, looking for someone, want to remember someone or to tell someone where you are.'),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        'We\'re Here For You',
        'click here if you\'re lost, looking for someone, want to remember someone or to tell someone where you are.',
        RepeatInterval.everyMinute,
        platformChannelSpecifics,
        androidAllowWhileIdle: true);
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("Save"),
      onPressed: () async {
        if (_globalKey.currentState.validate()) {
          _globalKey.currentState.save();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('phone', phoneController.text);
          Navigator.of(context).pop();

          _scaffoldKey.currentState.showSnackBar(new SnackBar(
              content:
                  Text('Phone ${phoneController.text} Saved Successfully')));

          _getLoc();
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      title: Center(child: Text('Emergency Number')),
      content: Form(
          key: _globalKey,
          child: AppTextField(
            controller: phoneController,
            labelText: 'Enter Phone Number',
            isPhone: true,
            keyboardType: TextInputType.phone,
          )),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _startTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool firstTime = prefs.getBool('first_time');

    if (firstTime != null && !firstTime) {
      // not first time

      _getLoc();
    } else {
      prefs.setBool('first_time', false);
      //show alert

      showAlertDialog(context);
    }
  }

  _twilio(lat, long, phoneNum) {
    twilioFlutter = TwilioFlutter(
        accountSid: env['accountSid'],
        authToken: env['authToken'],
        twilioNumber: env['twilioNumber']);

    twilioFlutter.sendSMS(
        toNumber: phoneNum,
        messageBody:
            'Location Changed \n https://www.google.com/maps/search/?api=1&query=$lat,$long');
  }

  _getLoc() async {
    await _location.getCurrentLocation();
    print('Lat:' + _location.latitude.toString());

    _location.positionStream.onData((data) async {
      _location.count++;

      if (data != null && _location.count >= 2) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String num = prefs.getString('phone');
        if (num != null) {
          _twilio(data.latitude.toString(), data.longitude.toString(), num);
          _scaffoldKey.currentState
              .showSnackBar(new SnackBar(content: Text('Sending Message...')));
          print('Changed Loc: ' +
              data.latitude.toString() +
              ', ' +
              data.longitude.toString());
        }
      }
    });
  }

  /// 1 Obtain a list of the available cameras on the device.
  /// 2 loads the face net model
  _startUp() async {
    _setLoading(true);

    List<CameraDescription> cameras = await availableCameras();

    /// takes the front camera
    cameraDescription = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );

    // start the services
    await _faceNetService.loadModel();
    await _dataBaseService.loadDB();
    _mlVisionService.initialize();

    _setLoading(false);
  }

  // shows or hides the circular progress indicator
  _setLoading(bool value) {
    setState(() {
      loading = value;
    });
  }

  Future<void> _deleteCacheDir() async {
    final cacheDir = await getTemporaryDirectory();

    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  }

  Future<void> _deleteAppDir() async {
    final appDir = await getApplicationSupportDirectory();

    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Container(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20, top: 20),
            child: PopupMenuButton<String>(
              child: Icon(
                Icons.more_vert,
                color: Colors.black,
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'Clear Data':
                    _dataBaseService.cleanDB();
                    await _deleteAppDir();
                    await _deleteCacheDir();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Clear Data'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: !loading
          ? SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Image(image: AssetImage('assets/logo.png')),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        children: [
                          Text(
                            "Remember Me",
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SignIn(
                                  cameraDescription: cameraDescription,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.lightBlue,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Check User',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Icon(Icons.login, color: Colors.white)
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SignUp(
                                  cameraDescription: cameraDescription,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.lightBlue,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Add New User',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Icon(Icons.person_add, color: Colors.white)
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    UsersListView(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.lightBlue,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Users List',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Icon(Icons.list, color: Colors.white)
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
