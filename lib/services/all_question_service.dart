import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:http/http.dart' as http;
import 'package:project_eureka_flutter/models/question_model.dart';

class AllQuestionService {
  // GET
  Future<List<QuestionModel>> getQuestions() async {
    await DotEnv.load();

    final response =
        await http.get(Uri.https(DotEnv.env['HOST'], '/v1/questions'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, then parse the JSON.
      // Backend service returns a list of json instances, while we need a list of question objects.
      // JSON parser will go through each json instance, transform it to a question object,
      //   and append to the list that will be used in eureka_list_view
      // Loop is reversed, as we want to sort the questions by date and show the most recent questions on top
      //   (new questions are appending to the bottom of the database)

      final body = json.decode(response.body);
      print("All questions were loaded");
      List<QuestionModel> questionsActive = List();
      List<QuestionModel> questionsClosed = List();

      body.reversed.forEach((question) {
        if (question['visible']) {
          question['closed']
              ? questionsClosed.add(QuestionModel.fromJson(question))
              : questionsActive.add(QuestionModel.fromJson(question));
        }
      });

      return List<QuestionModel>.from(questionsActive)..addAll(questionsClosed);
    } else {
      throw Exception('Failed to load questions');
    }
  }
}
