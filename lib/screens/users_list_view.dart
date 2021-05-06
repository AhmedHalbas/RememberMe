import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class UsersListView extends StatefulWidget {
  @override
  _UsersListViewState createState() => _UsersListViewState();
}

class _UsersListViewState extends State<UsersListView> {
  Map<String, dynamic> _db = new Map();

  File _JsonData =
      new File('/data/user/0/com.app.remember.me/app_flutter/emb.json');

  @override
  void initState() {
    if (_JsonData.existsSync()) _db = json.decode(_JsonData.readAsStringSync());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users List'),
      ),
      body: Container(
        child: FutureBuilder(
          builder: (context, status) {
            return ImageGrid(db: _db);
          },
        ),
      ),
    );
  }
}

class ImageGrid extends StatelessWidget {
  final Map<String, dynamic> db;
  const ImageGrid({Key key, this.db}) : super(key: key);

  showAlertDialog(BuildContext context, String name, String details) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      title: Center(child: Text('$name Details')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            details + '.',
            style: TextStyle(fontSize: 25),
          )
        ],
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var usersList = db.keys.toList(growable: false);
    return GridView.builder(
      itemCount: db.keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, childAspectRatio: 3.0 / 4.6),
      itemBuilder: (context, index) {
        var data = usersList[index].split(':');
        String name = data[0];
        String details = data[1];
        String image = data[2];

        File file = new File(image);
        PersistentBottomSheetController bottomSheetController;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: InkWell(
              onTap: () => {showAlertDialog(context, name, details)},
              child: Padding(
                padding: new EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Image.file(
                        File(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Expanded(
                        child: Text(
                      name,
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
