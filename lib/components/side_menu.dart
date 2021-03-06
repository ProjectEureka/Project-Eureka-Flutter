import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_eureka_flutter/models/user_model.dart';
import 'package:project_eureka_flutter/screens/home_screen.dart';
import 'package:project_eureka_flutter/screens/new_question_screen.dart';
import 'package:project_eureka_flutter/screens/profile_screen.dart';
import 'package:project_eureka_flutter/screens/settings_screen.dart';
import 'package:project_eureka_flutter/services/email_auth.dart';
import 'package:project_eureka_flutter/services/users_service.dart';

class SideMenu extends StatefulWidget {
  final String title;

  SideMenu({
    this.title,
  });

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool loading = true;
  UserModel user = UserModel(
    firstName: '',
    lastName: '',
    email: '',
    pictureUrl: '',
  );
  String userId = EmailAuth().getCurrentUser().uid;

  @override
  void initState() {
    initGetCurrentUser();
    super.initState();
  }

  void initGetCurrentUser() {
    UserService().getUserById(userId).then((payload) {
      setState(() {
        user = payload;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
            ),
            accountName: Text(
              '${user.firstName} ${user.lastName}',
              style: TextStyle(fontSize: 18.0),
            ),
            accountEmail: Text('${EmailAuth().getCurrentUser().email}'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 50.0,
                backgroundColor: Colors.transparent,
                backgroundImage: loading
                    ? AssetImage('assets/images/profile_default_image.png')
                    : user.pictureUrl == ""
                        ? AssetImage('assets/images/profile_default_image.png')
                        : NetworkImage(user.pictureUrl),
              ),
            ),
          ),
          sideMenuListTile(context, 'Home', Home(), Icons.home),
          Divider(color: Colors.grey.shade400, height: 1.0),
          sideMenuListTile(
            context,
            'Profile',
            Profile(userId: userId),
            Icons.person,
          ),
          Divider(color: Colors.grey.shade400, height: 1.0),
          sideMenuListTile(
            context,
            'Create New Post',
            NewQuestion(),
            Icons.edit,
          ),
          Divider(color: Colors.grey.shade400, height: 1.0),
          sideMenuListTile(
            context,
            'Settings',
            Settings(),
            Icons.settings,
          ),
        ],
      ),
    );
  }
}

ListTile sideMenuListTile(
    BuildContext context, String string, Widget newScreen, IconData leading) {
  return ListTile(
      title: Text(string, style: TextStyle(fontSize: 16.0)),
      leading: Icon(leading, size: 27.0),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.pushReplacement(context,
            CupertinoPageRoute(builder: (BuildContext context) => newScreen));
      });
}
