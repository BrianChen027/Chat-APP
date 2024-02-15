import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // 使用firebase_options.dart中的配置
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      // home: const ChatScreen(),
      home: InitialScreen(),
    );
  }
}

// Login or Register Page
class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Flutter Chat"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Welcome to Flutter Chat Demo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 20), // 添加一些间隔
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginScreen(isLogin: true)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.deepPurple, // 按钮背景色
                  onPrimary: Colors.white, // 文字颜色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text("Login"),
              ),
              SizedBox(height: 10), // 添加一些间隔
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginScreen(isLogin: false)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange, // 按钮背景色
                  onPrimary: Colors.white, // 文字颜色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  final bool isLogin;

  LoginScreen({required this.isLogin});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final user = userCredential.user;
      if (user != null) {
        // 可选：更新用户的最后登录时间或其他信息
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // 跳转到聊天室页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      print("====================================");
      print(e);
      print(e.code);
      if (e.code == 'invalid-credential') {
        errorMessage = 'This email is not exist, or password incorrect!';
      } else {
        errorMessage = 'Happen unpredict error, please try again later!';
      }
      // 显示错误消息对话框
      _showErrorDialog(errorMessage);
    } catch (e) {
      // 处理登录错误
      print("Login--------------------------------------------");
      print("Login failed: $e");
      _showErrorDialog('Happen unpredict error, please try again later!');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('登录失败'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('确定'),
            onPressed: () {
              Navigator.of(ctx).pop(); // 关闭对话框
            },
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final user = userCredential.user;
      if (user != null) {
        // 将用户信息存储到Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'uid': user.uid,
        });

        // 跳转到聊天室页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      print("====================================");
      print(e);
      print(e.code);
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already exist, please try another email!';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password should be at least 6 characters';
      } else {
        errorMessage = 'Happen unpredict error, please try again later!';
      }
      // 显示错误消息对话框
      _showErrorDialog(errorMessage);
    } catch (e) {
      // 处理注册错误
      print("Register--------------------------------------------");
      print("Register failed: $e");
      _showErrorDialog('Happen unpredict error, please try again later!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionText = widget.isLogin ? "Login" : "Register";
    final oppositeActionText = widget.isLogin ? "Register" : "Login";
    final performAction = widget.isLogin ? _login : _register;

    return Scaffold(
      appBar: AppBar(title: Text("Login/Register")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: performAction,
                child: Text(actionText),
              ),
              TextButton(
                onPressed: () {
                  // 切换到另一个界面
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            LoginScreen(isLogin: !widget.isLogin)),
                  );
                },
                child: Text("Switch to $oppositeActionText"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: const SafeArea(
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
  const MessagesList({super.key});

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
          return const Center(child: CircularProgressIndicator());
        }
        final chatDocs = chatSnapshot.data?.docs ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
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
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.deepPurple[300] : Colors.deepOrange[300],
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          // 移除width属性，添加maxWidth限制泡泡最大宽度
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75, // 最大宽度为屏幕宽度的75%
          ),
          child: Text(
            data['text'] ?? 'Missing text',
            style: const TextStyle(
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
  const NewMessage({super.key});

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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
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
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
