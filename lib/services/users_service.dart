import 'package:project_eureka_flutter/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // GET
  Future<UserModel> getUserById(String uid) async {
    await DotEnv.load();

    final response = await http.get(Uri.http(
        DotEnv.env['HOST'] + ':' + DotEnv.env['PORT'], '/v1/users/' + uid));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      UserModel user = UserModel.fromJson(body);
      return user;
    } else {
      throw Exception('Failed to load user');
    }
  }
}