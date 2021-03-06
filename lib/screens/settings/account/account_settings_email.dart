import 'package:flutter/material.dart';
import 'package:project_eureka_flutter/components/eureka_appbar.dart';
import 'package:project_eureka_flutter/components/eureka_rounded_button.dart';
import 'package:project_eureka_flutter/components/eureka_text_form_field.dart';
import 'package:project_eureka_flutter/services/email_auth.dart';

class AccountSettingsEmail extends StatefulWidget {
  @override
  _AccountSettingsEmailState createState() => _AccountSettingsEmailState();
}

class _AccountSettingsEmailState extends State<AccountSettingsEmail> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final EmailAuth _emailAuth = EmailAuth();
  String email;
  static final RegExp _regExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  void updateUserEmail(context) async {
    await _emailAuth.updateEmail(email);
    _showDialog(context);
  }

  void _validateAndSubmit(context) {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    updateUserEmail(context);
  }

  Container _emailTextForm() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'What would you like to change your email to?',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            EurekaTextFormField(
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              labelText: "Email",
              errValidatorMsg: "Email required.",
              regExp: _regExp,
              onSaved: (value) => email = value.trim(),
            )
          ],
        ),
      ),
    );
  }

  Future<dynamic> _showDialog(context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Email Changed"),
          content: Text("You can now sign in with your new email."),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                "Done",
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF00ADB5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Container _updateEmailButton(context) {
    return Container(
      child: EurekaRoundedButton(
        buttonText: "Change email",
        onPressed: () => _validateAndSubmit(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EurekaAppBar(
        title: 'Update Email',
        appBar: AppBar(),
      ),
      body: _emailTextForm(),
      bottomNavigationBar: _updateEmailButton(context),
    );
  }
}
