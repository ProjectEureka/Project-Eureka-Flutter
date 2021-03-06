import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_eureka_flutter/components/eureka_image_viewer.dart';
import 'package:project_eureka_flutter/components/eureka_profile_button.dart';
import 'package:project_eureka_flutter/models/user_model.dart';
import 'package:project_eureka_flutter/screens/call_screens/call_page.dart';
import 'package:project_eureka_flutter/components/eureka_appbar.dart';
import 'package:project_eureka_flutter/services/email_auth.dart';
import 'package:project_eureka_flutter/services/users_service.dart';
import 'package:project_eureka_flutter/services/video_communication.dart';
import 'package:project_eureka_flutter/screens/more_details_page.dart';
import 'dart:math';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:project_eureka_flutter/screens/profile_screen.dart';
import 'package:intl/intl.dart';

// Initialize global variable for channel name for the call receiver; accessible for in ChatScreen and MessageBubble classes
String channelNameAnswer = "";

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipient;
  final String questionId;
  final String groupChatId;

  const ChatScreen({
    Key key,
    this.recipientId,
    this.recipient,
    this.questionId,
    this.groupChatId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User loggedInUser = EmailAuth().getCurrentUser();
  FirebaseStorage storage = FirebaseStorage.instance;

  String messageText;
  String userId;

  // Initialize channel name on caller's side
  String channelNameCall = "";

  // initialize token on the caller's side that will be requested from the backend
  String _tokenCall = "";

  // used to get the user's firstName fir the system message when starting the call
  UserModel user = UserModel(
    firstName: '',
  );

  // Used for the animated video call button to turn off / turn on animation
  bool showAnimationButton;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    userId = loggedInUser.uid;

    // initialize channel names for two cases:
    // 1: channelNameCall - user calls and joins the channel; (initialized to empty string)
    // 2: channelNameAnswer - user clicks answer and joins the created channel
    channelNameAnswer = widget.recipientId + "-" + userId;

    UserService().getUserById(userId).then((payload) {
      setState(() {
        user = payload;
      });
    });

    _controller = AnimationController(
      vsync: this,
    );
    _controller.repeat(
      period: Duration(seconds: 1),
    );
    showAnimationButton = false;
    _checkAnswerToken();
  }

  @override
  void dispose() {
    _controller.dispose();
    _firestore.collection('messages').doc(widget.groupChatId).update({
      userId: false,
    });
    super.dispose();
  }

  // check if call has been started - every 3 seconds
  // that will start the animated video call button
  void _checkAnswerToken() async {
    while (true) {
      if (!mounted) {
        // once left the chat page, break the loop
        break;
      }
      // listen to answerToken every 4 seconds
      await Future.delayed(Duration(seconds: 4));
      await VideoCallService().getTokenAnswer(channelNameAnswer).then(
        (payload) {
          if (!mounted)
            return; // allow last call check to complete and prevent setState
          payload != "error"
              ? setState(() => showAnimationButton = true)
              : setState(() => showAnimationButton = false);
        },
      );
    }
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  // create and receive token after starting the call
  Future<void> initGetTokenCall() async {
    channelNameCall = userId + "-" + widget.recipientId;
    String tokenAnswer = "";
    // first check if call has already been started by another user
    await VideoCallService().getTokenAnswer(channelNameAnswer).then(
      (payload) {
        tokenAnswer = payload;
      },
    );
    // if call wasn't started, start the call
    // otherwise, join the existing call
    if (tokenAnswer == "error") {
      await VideoCallService().getTokenCall(channelNameCall).then(
        (payload) {
          setState(() {
            _tokenCall = payload;
          });
        },
      );
    } else {
      channelNameCall = channelNameAnswer;
      _tokenCall = tokenAnswer;
    }
  }

  Future<void> callUser() async {
    await initGetTokenCall();
    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    // this message will be sent from caller's side after call is finished
    if (channelNameCall != channelNameAnswer) {
      _firestore
          .collection('messages')
          .doc(widget.groupChatId)
          .collection(widget.groupChatId)
          .add({
        'text': user.firstName + " started the call",
        'sender': "system - " + userId,
        'timestamp': DateTime.now(),
        'idFrom': userId,
        'idTo': widget.recipientId,
      });
      _firestore.collection('messages').doc(widget.groupChatId).update({
        'timestamp': DateTime.now(),
        'unseen': true,
        'lastMessageSender': loggedInUser.uid
      });
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          token: _tokenCall,
          channelName: channelNameCall,
          action: "call",
        ),
      ),
    );
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<String> uploadImage(String mediaPath) async {
    String _mediaUrl = '';

    File file = File(mediaPath);

    /// These next two varibles format the file name, best fit for Firebase.
    String fileName = mediaPath
        .substring(mediaPath.lastIndexOf("/"), mediaPath.lastIndexOf("."))
        .replaceAll("/", "");
    String uploadName =
        'images/chat/${widget.groupChatId}/userId_$userId/$fileName.jpg';

    try {
      /// uploads the file
      TaskSnapshot snapshot = await storage.ref(uploadName).putFile(file);

      /// get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _mediaUrl = downloadUrl;
      });
    } catch (e) {
      print(e);
    }

    return _mediaUrl;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EurekaAppBar(
        appBar: AppBar(),
        actions: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: [
              showAnimationButton
                  ? Container(
                      alignment: Alignment(0, 0.15),
                      child: CustomPaint(
                        painter: SpritePainter(_controller),
                        child: SizedBox(
                          width: 80.0,
                          height: 80.0,
                        ),
                      ),
                    )
                  : Container(
                      alignment: Alignment(0, 0.15),
                      child: CustomPaint(
                        child: SizedBox(
                          width: 80.0,
                          height: 80.0,
                        ),
                      ),
                    ),
              IconButton(
                  icon: Icon(Icons.photo_camera_front, size: 40.0),
                  onPressed: () async {
                    await callUser();
                    if (channelNameCall != channelNameAnswer) {
                      _firestore
                          .collection('messages')
                          .doc(widget.groupChatId)
                          .collection(widget.groupChatId)
                          .add({
                        'text': "Call ended",
                        'sender': "system",
                        'timestamp': DateTime.now(),
                        'idFrom': userId,
                        'idTo': widget.recipientId,
                      });
                      _firestore
                          .collection('messages')
                          .doc(widget.groupChatId)
                          .update({
                        'timestamp': DateTime.now(),
                        'unseen': true,
                        'lastMessageSender': loggedInUser.uid
                      });
                    }
                  }),
            ],
          ),
          SizedBox(width: 30.0)
          //camera button for call will go here
        ],
        title: Column(
          children: [
            SizedBox(height: 50.0),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => Profile(
                              notSideMenu: true,
                              userId: widget.recipientId,
                            )));
              },
              child: Text(
                widget.recipient,
              ),
            ),
            FlatButton(
              color: Colors.blueGrey.withOpacity(0.5),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoreDetails(
                      questionId: widget.questionId,
                    ),
                  ),
                );
              },
              child: Text(
                'Question Details',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .doc(widget.groupChatId)
                  .collection(widget.groupChatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                //uses async snapshot
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data.docs;
                List<MessageBubble> messageBubbles = [];
                for (var message in messages) {
                  final messageText = message.data()['text'];
                  final messageSender = message.data()['sender'];
                  final messageTimestamp = message.data()['timestamp'];
                  final messageIsImage = message.data()['isImage'] == null ? false : message.data()['isImage'];
                  final messageBubble = MessageBubble(
                      sender: messageSender,
                      text: messageText,
                      isMe: loggedInUser.email == messageSender,
                      // if sender String contains "system", this message will appear in the center (it is a system message)
                      isSystem: messageSender.contains("system"),
                      // if sender String contains caller's ID, show Answer button. Caller won't see answer button
                      showAnswerButton: messageSender.contains(widget.recipientId),
                      messageIsImage: messageIsImage,
                      timestamp: messageTimestamp.toDate());

                  messageBubbles.add(messageBubble);
                }

                return Expanded(
                  child: ListView(
                    reverse: true,
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                    children: messageBubbles,
                  ),
                );
              },
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding:
                  EdgeInsets.only(left: 10, bottom: 10, top: 10, right: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Container(
                    width: 60,
                    child: FlatButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        color: Colors.cyan,
                        onPressed: () async {
                          String image = await showModalBottomSheet(
                              context: context,
                              builder: (context) =>
                                  EurekaProfileButton(picker: ImagePicker()));
                          String imageUrl = await uploadImage(image);
                          messageTextController.clear();
                          var currentTimeAndDate = DateTime.now();
                          _firestore
                              .collection('messages')
                              .doc(widget.groupChatId)
                              .collection(widget.groupChatId)
                              .add({
                            'text': imageUrl,
                            'sender': loggedInUser.email,
                            'timestamp': currentTimeAndDate,
                            'idFrom': userId,
                            'idTo': widget.recipientId,
                            'isImage': true
                          });
                          _firestore
                              .collection('messages')
                              .doc(widget.groupChatId)
                              .get()
                              .then((snapshot) {
                            if (snapshot.data()[widget.recipientId] == false) {
                              _firestore
                                  .collection('messages')
                                  .doc(widget.groupChatId)
                                  .update({
                                'timestamp': DateTime.now(),
                                'unseen': true,
                                'lastMessageSender': loggedInUser.uid
                              });
                            } else {
                              _firestore
                                  .collection('messages')
                                  .doc(widget.groupChatId)
                                  .update({
                                'timestamp': DateTime.now(),
                                'unseen': false,
                                'lastMessageSender': loggedInUser.uid
                              });
                            }
                          });
                        },
                        child: Icon(
                          Icons.image,
                          color: Colors.white,
                        )),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0)),
                    color: Colors.cyan,
                    onPressed: () async {
                      messageTextController.clear();
                      var currentTimeAndDate = DateTime.now();
                      _firestore
                          .collection('messages')
                          .doc(widget.groupChatId)
                          .collection(widget.groupChatId)
                          .add({
                        'text': messageText.trim(),
                        'sender': loggedInUser.email,
                        'timestamp': currentTimeAndDate,
                        'idFrom': userId,
                        'idTo': widget.recipientId,
                      });
                      _firestore
                          .collection('messages')
                          .doc(widget.groupChatId)
                          .get()
                          .then((snapshot) {
                        if (snapshot.data()[widget.recipientId] == false) {
                          _firestore
                              .collection('messages')
                              .doc(widget.groupChatId)
                              .update({
                            'timestamp': DateTime.now(),
                            'unseen': true,
                            'lastMessageSender': loggedInUser.uid
                          });
                        } else {
                          _firestore
                              .collection('messages')
                              .doc(widget.groupChatId)
                              .update({
                            'timestamp': DateTime.now(),
                            'unseen': false,
                            'lastMessageSender': loggedInUser.uid
                          });
                        }
                      });
                    },
                    child: Text(
                      'Send',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getTime(DateTime dateTime) {
  String formattedTime = DateFormat.jm().format(dateTime);
  String formattedDate = DateFormat.MMMMd().format(dateTime);
  return formattedDate + ', ' + formattedTime;
}

class MessageBubble extends StatelessWidget {
  MessageBubble(
      {this.sender,
      this.text,
      this.isMe,
      this.isSystem,
      this.timestamp,
      this.showAnswerButton,
      this.messageIsImage});

  final String sender;
  final String text;
  final bool isMe;
  final bool isSystem;
  final bool showAnswerButton;
  final DateTime timestamp;
  final bool messageIsImage;

  // Answer call from the button tha appears in chat
  Future<String> answerCall() async {
    String tokenAnswer = "";
    await VideoCallService().getTokenAnswer(channelNameAnswer).then(
      (payload) {
        tokenAnswer = payload;
      },
    );
    if (tokenAnswer != "error") {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      return tokenAnswer;
    }
    return tokenAnswer;
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : isSystem
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              getTime(timestamp),
              style: TextStyle(fontSize: 12.0, color: Colors.black),
            ),
            Material(
              borderRadius: isMe
                  ? BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0))
                  : isSystem
                      ? BorderRadius.all(Radius.circular(30.0))
                      : BorderRadius.only(
                          topRight: Radius.circular(30.0),
                          bottomLeft: Radius.circular(30.0),
                          bottomRight: Radius.circular(30.0)),
              elevation: 5.0, //adds shadow
              color: isMe ? Colors.cyan : Colors.white,

              child: Column(
                children: <Widget>[
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      child: messageIsImage == false
                          ? Text(text,
                              style: TextStyle(
                                fontSize: 17.0,
                                color: isMe
                                    ? Colors.white
                                    : isSystem
                                        ? Colors.blue
                                        : Colors.black,
                              ),
                              textAlign: TextAlign.start)
                          : GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EurekaImageViewer(
                                        imagePath: text, isUrl: true),
                                  ),
                                );
                              },
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: 200, maxHeight: 150),
                                child: FadeInImage.memoryNetwork(
                                    image: text,
                                    placeholder: kTransparentImage),
                              )),
                    ),
                  ),
                ],
              ),
            ),

            // Answer button when call started by another user.
            // Button will stay in chat, however won't work if call is not active
            if (showAnswerButton & isSystem & text.contains('started the call'))
              SizedBox.fromSize(
                size: Size(70, 56), // button width and height
                child: Material(
                  color: Colors.transparent, // button color
                  child: InkWell(
                    splashColor: Colors.blueGrey, // splash color
                    onTap: () async {
                      String tokenAnswer = await answerCall();
                      // Show alert if token was expired (call ended)
                      if (tokenAnswer == "error")
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text('Error'),
                                  content: Text(
                                    'Call is inactive.',
                                    textAlign: TextAlign.center,
                                  ),
                                  actions: <Widget>[
                                    FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Close')),
                                  ],
                                ));
                      // if token received, join the call
                      if (tokenAnswer != "error")
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallPage(
                              token: tokenAnswer,
                              channelName: channelNameAnswer,
                              action: "answer",
                            ),
                          ),
                        );
                    }, // button pressed
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.photo_camera_front, size: 30.0), // icon
                        Text("Answer",
                            style: TextStyle(fontSize: 17.0)), // text
                      ],
                    ),
                  ),
                ),
              )
          ]),
    );
  }
}

// Used for animated video call button when receiving the call
class SpritePainter extends CustomPainter {
  final Animation<double> _animation;

  SpritePainter(this._animation) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);
    Color color = Color.fromRGBO(0, 117, 194, opacity);
    double size = rect.width / 2;
    double area = size * size;
    double radius = sqrt(area * value / 4);
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) {
    return true;
  }
}
