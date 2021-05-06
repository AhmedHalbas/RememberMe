import 'package:remember_me/components/app_button.dart';
import 'package:remember_me/database/database.dart';
import 'package:remember_me/models/user.model.dart';
import 'package:remember_me/screens/home.dart';
import 'package:remember_me/services/facenet.service.dart';
import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AuthActionButton extends StatefulWidget {
  AuthActionButton(this._initializeControllerFuture,
      {Key key, @required this.onPressed, @required this.isLogin, this.reload});
  final Future _initializeControllerFuture;
  final Function onPressed;
  final bool isLogin;
  final Function reload;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  /// service injection
  final FaceNetService _faceNetService = FaceNetService();
  final DataBaseService _dataBaseService = DataBaseService();

  final TextEditingController _userTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _detailsTextEditingController =
      TextEditingController(text: '');

  User predictedUser;
  String imagepath;
  bool predictOutput;

  Future _signUp(context) async {
    /// gets predicted data from facenet service (user face detected)
    List predictedData = _faceNetService.predictedData;
    String user = _userTextEditingController.text;
    String details = _detailsTextEditingController.text;

    /// creates a new user in the 'database'
    await _dataBaseService.saveData(user, details, predictedData, imagepath);

    /// resets the face stored in the face net sevice
    this._faceNetService.setPredictedData(null);
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();
    return userAndPass ?? null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          // Ensure that the camera is initialized.
          await widget._initializeControllerFuture;
          // onShot event (takes the image and predict output)
          dynamic data = await widget.onPressed();
          predictOutput = data[0];
          imagepath = data[1];

          if (predictOutput) {
            if (widget.isLogin) {
              var userAndPass = _predictUser();
              if (userAndPass != null) {
                this.predictedUser = User.fromDB(userAndPass);
              }
            }
            PersistentBottomSheetController bottomSheetController =
                Scaffold.of(context)
                    .showBottomSheet((context) => signSheet(context));

            bottomSheetController.closed.whenComplete(() => widget.reload());
          }
        } catch (e) {
          // If an error occurs, log the error to the console.
          print(e);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color(0xFF0F0BDB),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CAPTURE',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.camera_alt, color: Colors.white)
          ],
        ),
      ),
    );
  }

  signSheet(context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isLogin && predictedUser != null
              ? Column(
                  children: [
                    Text(
                      'This is ' + predictedUser.userName + '.',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      'Details: ' + predictedUser.userDetails + '.',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                )
              : widget.isLogin
                  ? Container(
                      child: Text(
                      'User not found 😞',
                      style: TextStyle(fontSize: 20),
                    ))
                  : Container(),
          Container(
            child: Column(
              children: [
                !widget.isLogin
                    ? AppTextField(
                        controller: _userTextEditingController,
                        labelText: "Name",
                      )
                    : Container(),
                SizedBox(height: 10),
                widget.isLogin
                    ? Container()
                    : AppTextField(
                        controller: _detailsTextEditingController,
                        labelText: "Details",
                      ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                !widget.isLogin
                    ? AppButton(
                        text: 'Add New User',
                        onPressed: () async {
                          await _signUp(context);
                        },
                        icon: Icon(
                          Icons.person_add,
                          color: Colors.white,
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
