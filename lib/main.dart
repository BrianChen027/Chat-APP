import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// void main() {
//   runApp(const MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // 使用firebase_options.dart中的配置
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat Demo',
      theme: ThemeData(
        useMaterial3: true, // 确保使用Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          secondary: Colors.deepOrange,
        ),
      ),
      // 使用ChatScreen作为应用的起始界面
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MessagesList(),
            ),
            NewMessage(),
          ],
        ),
      ),
    );
  }
}

class MessagesList extends StatefulWidget {
  @override
  _MessagesListState createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 可以在这里添加监听Firestore的逻辑，以便新消息添加时滚动到底部
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // 这里是设置stream属性的地方
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('createdAt', descending: true) // 确保消息以发送时间的降序排列
          .snapshots(),
      builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final chatDocs = chatSnapshot.data?.docs ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return Flexible(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: chatDocs.length,
            itemBuilder: (ctx, index) {
              var reversedIndex = chatDocs.length - 1 - index;
              var data = chatDocs[reversedIndex].data() as Map<String, dynamic>;
              return _buildMessageItem(context, data, true);
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageItem(
      BuildContext context, Map<String, dynamic> data, bool isMe) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
      bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.deepPurple[300] : Colors.deepOrange[300],
            borderRadius: borderRadius,
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          // 移除width属性，添加maxWidth限制泡泡最大宽度
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75, // 最大宽度为屏幕宽度的75%
          ),
          child: Text(
            data['text'] ?? 'Missing text',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23.0, // 调整字体大小
            ),
          ),
        ),
      ],
    );
  }
}

class NewMessage extends StatefulWidget {
  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();

  void _sendMessage() {
    FocusScope.of(context).unfocus();
    FirebaseFirestore.instance.collection('chats').add({
      'text': _controller.text,
      'createdAt': Timestamp.now(),
    }).then((_) {
      print("---------------------------------------------------");
      print("Message added to the collection");
    }).catchError((error) {
      print("---------------------------------------------------");
      print("Failed to add message: $error");
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Send a message...',
                filled: true,
                fillColor: Colors.deepPurple[50],
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.deepPurple),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
