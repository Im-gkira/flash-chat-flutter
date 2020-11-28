import 'package:flutter/cupertino.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
String loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ignore: deprecated_member_use
  final _auth = FirebaseAuth.instance;
  // ignore: deprecated_member_use
  String message;
  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        loggedInUser = currentUser.email;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _auth.signOut();
                Alert(
                    context: context,
                    title: "LOGOUT",
                    content: Column(
                      children: <Widget>[
                        Icon(
                          Icons.announcement_outlined,
                          color: Colors.black87,
                          size: 120.0,
                        )
                      ],
                    ),
                    buttons: [
                      DialogButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          "LOGOUT",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      )
                    ]).show();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        message = value; //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      if (message != null && message != '') {
                        _firestore.collection("Messages").add({
                          "text": message,
                          "sender": loggedInUser,
                          "messageTime": Timestamp.now(),
                        });//Implement send functionality.
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Messages').orderBy('messageTime', descending: false).snapshots(),
        // ignore: missing_return
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }
          final messages = snapshot.data.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messageText = message.data()['text'];
            final messageSender = message.data()['sender'];

            final activeUser = loggedInUser;

            if (messageText!=null && messageText != '') {
              final messageBubble =
                  MessageBubble(text: messageText, sender: messageSender, isMe: activeUser == messageSender);
              {
                messageBubbles.add(messageBubble);
              }
            }
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.all(25.0),
              children: messageBubbles,
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender,this.isMe});
  final text;
  final sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(crossAxisAlignment: isMe?CrossAxisAlignment.end:CrossAxisAlignment.start, children: [
        Text(
          sender,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
          ),
        ),
        Material(
          elevation: 7.0,
          borderRadius: BorderRadius.only(
              topLeft: isMe?Radius.circular(30.0):Radius.circular(0.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
              topRight: isMe?Radius.circular(0.0):Radius.circular(30.0),
          ),
              color: isMe?Colors.lightBlueAccent:Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Expanded(child: Text('$text')),
          ),
          textStyle: TextStyle(
            fontSize: 16.0,
            color: isMe?Colors.white:Colors.black87,
          ),
        ),
      ]),
    );
  }
}
