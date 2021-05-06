import 'package:flutter/material.dart';

class User {
  String userName;
  String userDetails;

  User({@required this.userName, @required this.userDetails});

  static User fromDB(String dbUser) {
    return new User(
        userName: dbUser.split(':')[0], userDetails: dbUser.split(':')[1]);
  }
}
