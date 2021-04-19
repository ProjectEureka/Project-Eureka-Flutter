import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:project_eureka_flutter/models/more_details_model.dart';

class MoreDetailService {
  Future<MoreDetailModel> getMoreDetail(String questionId) async {
    await DotEnv.load();

    final http.Response response = await http.get(
      Uri.http(DotEnv.env['HOST'] + ':' + DotEnv.env['PORT'],
          'v1/questions/$questionId/details'),
    );

    return MoreDetailModel.fromJson(json.decode(response.body));
  }
}