import 'package:flutter/material.dart';
import 'package:project_eureka_flutter/components/eureka_appbar.dart';
import 'package:project_eureka_flutter/components/eureka_rounded_button.dart';
import 'package:project_eureka_flutter/components/more_details_view.dart';
import 'package:project_eureka_flutter/models/user_answer_model.dart';
import 'package:project_eureka_flutter/screens/more_details_page.dart';
import 'package:project_eureka_flutter/screens/rating_screen.dart';
import 'package:project_eureka_flutter/services/close_question_service.dart';
import 'package:project_eureka_flutter/services/email_auth.dart';

class ChooseBestAnswer extends StatefulWidget {
  final String questionId;
  final List<UserAnswerModel> answers;

  const ChooseBestAnswer({
    this.questionId,
    this.answers,
  });

  @override
  _ChooseBestAnswerState createState() => _ChooseBestAnswerState();
}

class _ChooseBestAnswerState extends State<ChooseBestAnswer> {
  int bestAnswerIndex = -1;

  void bestAnswerSelector(int i) {
    setState(() {
      bestAnswerIndex = i;
    });
  }

  Future<void> _closeQuestion(String answerId) async {
    final response =
        await CloseQuestionService().closeQuestion(widget.questionId, answerId);
    print("Status " +
        response.statusCode.toString() +
        ". Question closed successfully - " +
        widget.questionId.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EurekaAppBar(
        title: 'Choose the Best Answer',
        appBar: AppBar(),
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 269.0,
          ),
          margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
          padding: EdgeInsets.fromLTRB(3, 0, 3, 0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.all(
              Radius.circular(20.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Answers",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: Color(0xFF00ADB5),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                for (UserAnswerModel userAnswer in widget.answers)
                  GestureDetector(
                    onTap: () => bestAnswerSelector(
                      widget.answers.indexOf(userAnswer),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.answers.indexOf(userAnswer) ==
                                bestAnswerIndex
                            ? Color(0x6600ADB5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20.0),
                        ),
                      ),
                      child: MoreDetailsView(
                        isAnswer: true,
                        userAnswerModel: userAnswer,
                        isCurrUser: false,
                        choosingBestAnswer: true
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: EurekaRoundedButton(
          onPressed: bestAnswerIndex == -1
              ? null
              : () => widget.answers[bestAnswerIndex].user.id ==
                      EmailAuth().getCurrentUser().uid
                  ? {
                      _closeQuestion(widget.answers[bestAnswerIndex].answer.id),
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (Route<void> route) => false),
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MoreDetails(
                            questionId: widget.questionId,
                          ),
                        ),
                      ),
                    }
                  : Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Rating(
                          userInfo: widget.answers[bestAnswerIndex].user,
                          questionId: widget.questionId,
                          answerId: widget.answers[bestAnswerIndex].answer.id,
                        ),
                      ), //archive question
                    ),
          buttonText: 'Select Best Answer',
        ),
      ),
    );
  }
}
