import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:http/http.dart' as http;
import 'package:project_eureka_flutter/models/question_model.dart';

class NewQuestionService {
  Future<http.Response> postNewQuestion(QuestionModel question) async {
    await DotEnv.load();

    final response = await http.post(
      Uri.https(
        DotEnv.env['HOST'],
        '/v1/questions/',
      ),
      headers: <String, String>{
        'Content-type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        question.toJson(),
      ),
    );

    if (response.statusCode == 201) {
      print('Question was added to database.');
      return response;
    } else {
      throw Exception('Failed to add question to database.');
    }
  }
}
