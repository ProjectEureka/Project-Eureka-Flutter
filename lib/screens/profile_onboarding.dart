import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_eureka_flutter/components/eureka_appbar.dart';
import 'package:project_eureka_flutter/components/eureka_camera_form.dart';
import 'package:project_eureka_flutter/components/eureka_profile_button.dart';
import 'package:project_eureka_flutter/components/eureka_rounded_button.dart';
import 'package:project_eureka_flutter/components/eureka_text_form_field.dart';
import 'package:project_eureka_flutter/components/eureka_toggle_switch.dart';
import 'package:project_eureka_flutter/screens/home_page.dart';
import 'package:project_eureka_flutter/models/user_model.dart';
import 'package:project_eureka_flutter/services/email_auth.dart';
import 'package:project_eureka_flutter/services/profile_onboarding_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileOnboarding extends StatefulWidget {
  final bool isProfile;

  ProfileOnboarding({
    @required this.isProfile,
  });

  @override
  _ProfileOnboardingState createState() => _ProfileOnboardingState();
}

class _ProfileOnboardingState extends State<ProfileOnboarding> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String mediaPath = '';
  ImagePicker picker = ImagePicker();
  bool _isUploading = false;
  FirebaseStorage storage = FirebaseStorage.instance;

  static final RegExp _nameRegExp = RegExp(
      "[a-zA-ZàáâäãåąčćęèéêëėįìíîïłńòóôöõøùúûüųūÿýżźñçčšžÀÁÂÄÃÅĄĆČĖĘÈÉÊËÌÍÎÏĮŁŃÒÓÔÖÕØÙÚÛÜŲŪŸÝŻŹÑßÇŒÆČŠŽ∂ð ,.'-]");

  int _role = 0;
  String _firstName;
  String _lastName;
  String _city;

  EurekaAppBar _profileOnboardingAppBar() {
    return EurekaAppBar(
      title: widget.isProfile ? 'Edit Your Profile' : 'Create Your Profile',
      appBar: AppBar(),
      actions: [
        widget.isProfile
            ? IconButton(
                icon: Icon(
                  Icons.cancel,
                  color: Color(0xFF00ADB5),
                ),
                onPressed: () => Navigator.pop(context))
            : Container(),
      ],
    );
  }

  Container _submitButton() {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: FlatButton(
        onPressed: () {
          _validateAndSubmit();
        },
        color: Color(0xFF00ADB5),
        minWidth: MediaQuery.of(context).size.width - 50.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          padding: EdgeInsets.all(10.0),
          child: Text(
            'Confirm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25.0,
            ),
          ),
        ),
      ),
    );
  }

  Future<List<String>> uploadFiles() async {
    List<String> _mediaUrls = [];

    setState(() {
      _isUploading = true;
    });

    /// iterates through _mediaPath list and upload one by one.

    File file = File(mediaPath);

    print('this is mediaPath:' + mediaPath.toString());

    /// These next two varibles format the file name, best fit for Firebase.
    String fileName = mediaPath
        .substring(mediaPath.lastIndexOf("/"), mediaPath.lastIndexOf("."))
        .replaceAll("/", "");
    String uploadName =
        'images/profile/userId_${EmailAuth().getCurrentUser().uid}/$fileName.jpg';

    try {
      /// uploads the file
      TaskSnapshot snapshot = await storage.ref(uploadName).putFile(file);

      /// get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _mediaUrls.add(downloadUrl);
      });
    } catch (e) {
      print(e);
    }

    setState(() {
      _isUploading = false;
    });

    return _mediaUrls;
  }

  SingleChildScrollView _scrollingForm() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
            child: Text(
              'Do you prefer to help people with their questions or ask questions?',
              textAlign: TextAlign.center,
            ),
          ),
          EurekaToggleSwitch(
            labels: ['None', 'Student', 'Teacher'],
            initialLabelIndex: _role,
            setState: (index) {
              setState(() {
                _role = index;
              });
            },
          ),
          GestureDetector(
            onTap: () async {
              String temp = await showModalBottomSheet(
                  context: context,
                  builder: (context) => EurekaProfileButton(picker: picker));
              setState(() {
                if (temp == null) {
                  mediaPath = '';
                } else {
                  mediaPath = temp;
                }
              });
            },
            child: CircleAvatar(
              backgroundColor: Colors.grey[400],
              radius: 50.0,
              child: mediaPath == ''
                  ? Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                    )
                  : CircleAvatar(
                      backgroundImage: AssetImage(mediaPath),
                      radius: 50.0,
                    ),
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
          EurekaTextFormField(
            labelText: 'First Name',
            errValidatorMsg: 'First name is required.',
            regExp: _nameRegExp,
            onSaved: (value) => _firstName = value.trim(),
          ),
          EurekaTextFormField(
            labelText: 'Last Name',
            errValidatorMsg: 'Last name is required.',
            regExp: _nameRegExp,
            onSaved: (value) => _lastName = value.trim(),
          ),
          EurekaTextFormField(
            labelText: 'City',
            errValidatorMsg: 'Your city is required.',
            regExp: _nameRegExp,
            onSaved: (value) => _city = value.trim(),
          ),
        ],
      ),
    );
  }

  void _validateAndSubmit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();

    User _firebaseUser = EmailAuth().getCurrentUser();
    ProfileOnboardingService _profileOnboardingService =
        new ProfileOnboardingService();

    List<String> mediaUrl = await uploadFiles();

    /// Create the user object to be sent out.
    UserModel user = new UserModel(
      id: _firebaseUser.uid,
      firstName: _firstName,
      lastName: _lastName,
      firebaseUuid: _firebaseUser.uid,
      email: _firebaseUser.email,
      city: _city,
      category: [], //we don't have form field for this
      pictureUrl: mediaUrl[0],
      role: _role,
      ratings: [],
      averageRating: 0.0,
    );

    /// Using the profile onboarding serivce, send data to backend
    try {
      if (widget.isProfile) {
        // Using HTTP PUT to update instead
        // This currently doesn't work until we can get the current user_id
        await _profileOnboardingService.updateUser(_firebaseUser.uid, user);

        Navigator.pop(context);
      } else {
        // Using HTTP POST to add new user
        await _profileOnboardingService.addUser(user);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Home(),
          ),
          (Route<void> route) => false,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _profileOnboardingAppBar(),
      body: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: _scrollingForm(),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: _submitButton(),
      ),
    );
  }
}
