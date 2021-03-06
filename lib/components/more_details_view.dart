import 'package:flutter/material.dart';
import 'package:project_eureka_flutter/components/eureka_image_viewer.dart';
import 'package:project_eureka_flutter/models/more_details_model.dart';
import 'package:project_eureka_flutter/models/user_answer_model.dart';
import 'package:project_eureka_flutter/screens/chat_screens/chat_screen.dart';
import 'package:project_eureka_flutter/screens/home_screen.dart';
import 'package:project_eureka_flutter/screens/new_form_screens/new_form.dart';
import 'package:project_eureka_flutter/screens/profile_screen.dart';
import 'package:project_eureka_flutter/services/close_question_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class MoreDetailsView extends StatefulWidget {
  final MoreDetailModel moreDetailModel;
  final bool isAnswer;
  final UserAnswerModel userAnswerModel;
  final bool isCurrUser;
  final firestore;
  final String currUserId;
  final bool choosingBestAnswer;

  MoreDetailsView(
      {this.moreDetailModel,
      @required this.isAnswer,
      this.userAnswerModel,
      @required this.isCurrUser,
      this.firestore,
      this.currUserId,
      this.choosingBestAnswer});

  @override
  _MoreDetailsViewState createState() => _MoreDetailsViewState();
}

class _MoreDetailsViewState extends State<MoreDetailsView> {
  Padding profileIcon() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 15.0, 0.0),
      child: GestureDetector(
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => Profile(
                        notSideMenu: true,
                        userId: widget.isAnswer
                            ? widget.userAnswerModel.user.id
                            : widget.moreDetailModel.user.id,
                      )));
        },
        child: CircleAvatar(
          radius: widget.isAnswer ? 20.0 : 40.0,
          backgroundColor: Colors.transparent,
          backgroundImage: (widget.isAnswer
                  ? widget.userAnswerModel.user.pictureUrl == ''
                  : widget.moreDetailModel.user.pictureUrl == '')
              ? AssetImage('assets/images/profile_default_image.png')
              : NetworkImage(
                  widget.isAnswer
                      ? widget.userAnswerModel.user.pictureUrl
                      : widget.moreDetailModel.user.pictureUrl,
                ),
        ),
      ),
    );
  }

  Row _profileName() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.isAnswer
              ? '${widget.userAnswerModel.user.firstName} ${widget.userAnswerModel.user.lastName}'
              : '${widget.moreDetailModel.user.firstName} ${widget.moreDetailModel.user.lastName}',
          style: TextStyle(
              fontSize: widget.isAnswer ? 13.0 : 17.0,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        if (widget.isAnswer)
          widget.userAnswerModel.user.averageRating > 0.0
              ? Text(
                  "  " +
                      widget.userAnswerModel.user.averageRating.toString() +
                      " ⭐",
                )
              : Text("   N/A ⭐")
      ],
    );
  }

  Widget _questionCategory() {
    return widget
            .isAnswer // this widget will only show when this component is used for question details
        ? Container()
        : Row(
            children: [
              Text(
                "Category: ",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
              Text(
                widget.moreDetailModel.question.category,
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
                textAlign: TextAlign.left,
              ),
            ],
          );
  }

  Widget _timeAgo(DateTime dateTime) {
    return Row(
      children: [
        Text(
          widget.isAnswer ? "Answered: " : "Asked: ",
          // This widget will build depending on if the component is for answers or question
          style: TextStyle(
              fontSize: widget.isAnswer ? 12.5 : 16.0,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        Text(
          timeago.format(dateTime),
          style: TextStyle(
              fontSize: widget.isAnswer ? 11.5 : 14.0,
              fontWeight: FontWeight.w300),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Row _profileNameAndIcon() {
    final DateTime dateTime = DateTime.parse(widget.isAnswer
            ? widget.userAnswerModel.answer.answerDate
            : widget.moreDetailModel.question.questionDate)
        .subtract(Duration(hours: -7));

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        profileIcon(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.0),
            _profileName(),
            if (!widget.isAnswer)
              widget.moreDetailModel.user.averageRating == 0.0
                  ? Text("Not rated yet ⭐")
                  : Text(
                      widget.moreDetailModel.user.averageRating.toString() +
                          " ⭐",
                    ),
            SizedBox(height: widget.isAnswer ? 0.0 : 10.0),
            _questionCategory(),
            _timeAgo(dateTime),
          ],
        ),
      ],
    );
  }

  // Will only show if this component is used for Answer and it has a bestAnswer
  Widget bestAnswerHeader() {
    return widget.isAnswer
        ? (widget.userAnswerModel.answer.bestAnswer
            ? Text(
                "Best Answer",
                style: TextStyle(
                    fontSize: 15.0,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              )
            : Container())
        : Container();
  }

  // builds a title if only if the component is used as question
  Widget _questionTitle() {
    return widget.isAnswer
        ? Container()
        : Text(
            widget.moreDetailModel.question.title,
            style: TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
            ),
          );
  }

  Text _moreDetailsDescription() {
    return Text(
      widget.isAnswer
          ? widget.userAnswerModel.answer.description
          : widget.moreDetailModel.question.description,
      style: TextStyle(fontSize: 16.0),
    );
  }

  RichText _mediaLinkText(int i) {
    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: "Image ${1 + i}",
            style: TextStyle(
              fontSize: widget.isAnswer ? 14.0 : 15.0,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
          i + 1 == //this will check if index is at end of list
                  (widget.isAnswer
                      ? widget.userAnswerModel.answer.mediaUrls.length
                      : widget.moreDetailModel.question.mediaUrls.length)
              ? TextSpan() // if true, no comma
              : TextSpan(
                  // if false, add comma after link
                  text: ' , ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ],
      ),
    );
  }

  Wrap _mediaLinksBuilder() {
    return Wrap(
      children: [
        Text(
          'Media: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: widget.isAnswer ? 15.0 : 16.0,
          ),
        ),
        SizedBox(width: 10.0),
        for (int i = 0;
            (widget.isAnswer
                ? i < widget.userAnswerModel.answer.mediaUrls.length
                : i < widget.moreDetailModel.question.mediaUrls.length);
            i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(00.0, 0.0, 15.0, 5.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EurekaImageViewer(
                      imagePath: widget.isAnswer
                          ? widget.userAnswerModel.answer.mediaUrls[i]
                          : widget.moreDetailModel.question.mediaUrls[i],
                      isUrl: true,
                    ),
                  ),
                );
              },
              child: _mediaLinkText(i),
            ),
          ),
      ],
    );
  }

  Widget _moreDetailsMedia() {
    return widget.isAnswer
        ? (widget.userAnswerModel.answer.mediaUrls.length == 0
            ? Container()
            : _mediaLinksBuilder())
        : (widget.moreDetailModel.question.mediaUrls.length == 0
            ? Container()
            : _mediaLinksBuilder());
  }

  Container _moreDetailsBody() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: widget.isAnswer ? 5.0 : 15.0,
          ),
          bestAnswerHeader(),
          _questionTitle(),
          SizedBox(height: widget.isAnswer ? 0.0 : 15.0),
          _moreDetailsDescription(),
          SizedBox(height: widget.isAnswer ? 5.0 : 15.0),
          _moreDetailsMedia(),
        ],
      ),
    );
  }

  IconButton messageIcon() {
    return IconButton(
      color: Color(0xFF00ADB5),
      icon: Icon(Icons.message_outlined),
      onPressed: () {
        addChatToFirebase(
            widget.isAnswer ? widget.userAnswerModel : widget.moreDetailModel);
      },
    );
  }

  void createChat(dynamic obj, String groupChatId) {
    widget.firestore.collection('messages').doc(groupChatId).set({
      'chatIDUser': widget.currUserId,
      'recipientId': obj.user.id,
      'questionTitle': widget.moreDetailModel.question.title,
      'questionId': widget.moreDetailModel.question.id,
      'timestamp': DateTime.now(),
      'lastMessageSender': widget.currUserId,
      'unseen': true,
      'groupChatId': groupChatId,
      widget.currUserId.toString(): false,
      obj.user.id.toString(): false,
    });

    editChat(false, groupChatId, obj.user.id, obj.user.firstName);
  }

  void editChat(bool unseenByMe, String groupChatId, String recipientId,
      String recipientName) {
    if (unseenByMe) {
      widget.firestore
          .collection('messages')
          .doc(groupChatId)
          .update({'unseen': false});
    }
    widget.firestore
        .collection('messages')
        .doc(groupChatId)
        .update({widget.currUserId.toString(): true});

    enterChat(recipientId, recipientName, groupChatId);
  }

  void enterChat(String recipientId, String recipientName, String groupChatId) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
                  groupChatId: groupChatId,
                  recipientId: recipientId,
                  recipient: recipientName,
                  questionId: widget.moreDetailModel.question.id,
                )));
  }

  void addChatToFirebase(dynamic obj) {
    String groupChatId =
        '${widget.currUserId.toString()}-${obj.user.id}-${widget.moreDetailModel.question.id}';
    String groupChatIdReversed =
        '${obj.user.id}-${widget.currUserId.toString()}-${widget.moreDetailModel.question.id}';

    widget.firestore
        .collection('messages')
        .doc(groupChatId)
        .get()
        .then((snapshot) {
      if (snapshot.data() == null) {
        // check if chat exists with with chatId string
        widget.firestore
            .collection('messages')
            .doc(groupChatIdReversed)
            .get()
            .then((snapshot) {
          if (snapshot.data() ==
              null) // if it doesn't exist, also check if there is already a chat created by recipient
          {
            createChat(obj, groupChatId);
          } else // otherwise enter chat with reversed chatId
          {
            editChat(
                (snapshot.data()['unseen'] &&
                    snapshot.data()['lastMessageSender'] != widget.currUserId),
                groupChatIdReversed,
                obj.user.id,
                obj.user.firstName);
          }
        });
      } else {
        editChat(
            (snapshot.data()['unseen'] &&
                snapshot.data()['lastMessageSender'] != widget.currUserId),
            groupChatId,
            obj.user.id,
            obj.user.firstName);
      }
    });
  }

  /* DROP DOWN MENU - BEGIN */
  Future<void> _archiveQuestion() async {
    await CloseQuestionService()
        .archiveQuestion(widget.moreDetailModel.question.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          'Question was archived',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          FlatButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Home(),
                    ), //archive question
                  ),
              child: Text('Back to Home')),
        ],
      ),
    );
  }

  void _answerQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewForm(
          isAnswer: true,
          questionId: widget.moreDetailModel.question.id,
        ),
      ), // standard form
    );
  }

  PopupMenuButton _questionMenu(bool isArchived, bool isClosed) {
    return PopupMenuButton<String>(
      onSelected: (String result) {
        setState(() {
          switch (result) {
            case 'Answer':
              {
                _answerQuestion();
              }
              break;
            case 'Archive':
              {
                _archiveQuestion();
              }
              break;
          }
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (widget.moreDetailModel.question.closed != true)
          const PopupMenuItem<String>(
            value: 'Answer',
            child: Text('Answer'),
          ),
        if (widget.moreDetailModel.question.visible != false)
          const PopupMenuItem<String>(
            value: 'Archive',
            child: Text('Archive'),
          )
      ],
    );
  }

  /* DROP DOWN MENU - END */

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 8.0),
          child: Column(
            children: [
              _profileNameAndIcon(),
              _moreDetailsBody(),
              widget.isAnswer
                  ? Padding(
                      padding:
                          const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
                      child: Divider(
                        color: Colors.black,
                        thickness: 1.0,
                        height: 0.0,
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        widget.isAnswer
            ? Positioned(
                right: 0.0,
                top: 0.0,
                child: Transform.scale(
                    scale: 1.20,
                    child: (widget.moreDetailModel == null &&
                            widget.userAnswerModel == null)
                        ? Container()
                        : widget.userAnswerModel.user.id == widget.currUserId
                            ? Container()
                            : widget.choosingBestAnswer == null
                                ? messageIcon()
                                : Container()))
            : Positioned(
                right: 0.0,
                top: 35.0,
                child: Transform.scale(
                  scale: 1.30,
                  child: widget.isCurrUser
                      ? (widget.moreDetailModel.question.visible == false
                          ? Container()
                          : _questionMenu(false, false))
                      : widget.choosingBestAnswer == null
                          ? messageIcon()
                          : Container(),
                ),
              ),
      ],
    );
  }
}
