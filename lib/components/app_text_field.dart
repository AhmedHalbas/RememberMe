import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  AppTextField(
      {Key key,
      @required this.labelText,
      @required this.controller,
      this.keyboardType = TextInputType.text,
      this.autofocus = false,
      this.isdetails = false,
      this.isPhone})
      : super(key: key);

  final String labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool autofocus;
  final bool isdetails;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // ignore: missing_return
      validator: (value) {
        if (isPhone) {
          if (value.isEmpty || !value.startsWith('+20') || value.length != 13)
            return 'Starts With +20 and Length: 13';
        }
      },
      controller: this.controller,
      autofocus: this.autofocus,
      cursorColor: Color(0xFF5BC8AA),
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintText: labelText,
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.grey[200],
        enabledBorder: new OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: const BorderRadius.all(
            const Radius.circular(10.0),
          ),
        ),
        focusedBorder: new OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: const BorderRadius.all(
            const Radius.circular(10.0),
          ),
        ),
      ),
      obscureText: isdetails,
      keyboardType: keyboardType,
    );
  }
}
