import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
      home: const InitialScreen(),
    );
  }
}

// Friend Data
class Friend {
  final String uid;
  final String email;

  Friend({required this.uid, required this.email});

  factory Friend.fromDocument(DocumentSnapshot doc) {
    return Friend(
      uid: doc.id,
      email: doc['email'] ?? '',
    );
  }
}

// Friend List loading
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  Future<List<Friend>> _fetchFriendsList() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final List<dynamic> friendsIds = userDoc.data()?['friends'] ?? [];
    List<Friend> friendsList = [];
    for (String friendId in friendsIds) {
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();
      final friend = Friend.fromDocument(friendDoc);
      friendsList.add(friend);
    }
    return friendsList;
  }

  Future<void> _navigateToChatRoom(String friendUid) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    String chatRoomId = await _getOrCreateChatRoom(currentUserUid, friendUid);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(chatRoomId: chatRoomId),
      ),
    );
  }

  Future<String> _getOrCreateChatRoom(
      String currentUserUid, String friendUid) async {
    List<String> members = [currentUserUid, friendUid];
    members.sort(); // 将成员 UID 排序

    final chatRoomsQuery = await FirebaseFirestore.instance
        .collection('chatrooms')
        .where('members', isEqualTo: members) // 使用排序后的成员数组进行查询
        .limit(1)
        .get();

    if (chatRoomsQuery.docs.isNotEmpty) {
      // 如果找到现有聊天室，返回第一个聊天室的 ID
      return chatRoomsQuery.docs.first.id;
    } else {
      // 如果没有找到，创建新的聊天室
      final newChatRoomDoc =
          await FirebaseFirestore.instance.collection('chatrooms').add({
        'members': [currentUserUid, friendUid],
      });
      return newChatRoomDoc.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends List"),
        //  backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddFriendScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Friend>>(
        future: _fetchFriendsList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.error != null) {
            // Do error handling stuff
            return const Center(child: Text('An error occurred'));
          } else {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text("No friends found."));
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (ctx, index) {
                  final friend = snapshot.data![index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child:
                          Text(friend.email[0].toUpperCase()), // 使用好友邮箱的首字母作为头像
                    ),
                    title: Text(friend.email), // 这里可以替换为 friend.name
                    subtitle: Text("Tap to chat"), // 可以添加状态消息或最后消息预览
                    onTap: () => _navigateToChatRoom(friend.uid),
                  );
                },
                separatorBuilder: (context, index) => Divider(),
              );
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const FriendRequestsScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// Adding Friend function
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Friend\'s Email'),
            ),
            ElevatedButton(
              onPressed: _sendFriendRequest,
              child: const Text('Add Friend'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final friendEmail = _emailController.text.trim();

    if (currentUser == null || friendEmail.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid data")));
      return;
    }

    // 查找电子邮件对应的用户
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot =
        await usersCollection.where('email', isEqualTo: friendEmail).get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not found.")));
      return;
    }

    // 获取好友的UID
    final friendUid = querySnapshot.docs.first.id;
    if (friendUid == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You cannot add yourself.")));
      return;
    }

    // 检查是否已发送好友请求
    final friendshipsCollection =
        FirebaseFirestore.instance.collection('friendships');
    final existingRequest = await friendshipsCollection
        .where('requester', isEqualTo: currentUser.uid)
        .where('accepter', isEqualTo: friendUid)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Friend request already sent.")));
      return;
    }

    // 发送好友请求
    await friendshipsCollection.add({
      'requester': currentUser.uid,
      'accepter': friendUid,
      'status': 'pending',
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Friend request sent.")));
    Navigator.pop(context); // Optionally, return to the previous screen
  }
}

// Request Friend List
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login."))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('friendships')
                  .where('status', isEqualTo: 'pending')
                  .where('accepter', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requestsDocs = snapshot.data?.docs ?? [];
                if (requestsDocs.isEmpty) {
                  return const Center(child: Text("No friend requests."));
                }

                return ListView.builder(
                  itemCount: requestsDocs.length,
                  itemBuilder: (ctx, index) {
                    final doc = requestsDocs[index];
                    // 使用 FutureBuilder 异步加载请求者的电子邮件
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc['requester'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          // 成功获取到用户数据，显示电子邮件
                          String email =
                              snapshot.data!['email'] ?? 'Unknown email';
                          return ListTile(
                            title: Text('Request from $email'), // 显示请求者的电子邮件
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () => _acceptRequest(doc.id,
                                      doc['requester'], currentUser!.uid),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _declineRequest(doc.id),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // 数据加载中或加载失败
                          return ListTile(
                            title: const Text('Loading...'),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _acceptRequest(
      String friendshipDocId, String requesterId, String accepterId) async {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      final requesterRef =
          FirebaseFirestore.instance.collection('users').doc(requesterId);
      final accepterRef =
          FirebaseFirestore.instance.collection('users').doc(accepterId);

      // 将双方添加到对方的好友列表中
      transaction.update(requesterRef, {
        'friends': FieldValue.arrayUnion([accepterId])
      });
      transaction.update(accepterRef, {
        'friends': FieldValue.arrayUnion([requesterId])
      });

      // 更新好友关系状态为已接受
      final friendshipRef = FirebaseFirestore.instance
          .collection('friendships')
          .doc(friendshipDocId);
      transaction.update(friendshipRef, {'status': 'accepted'});
    }).then((_) {
      print("Friendship accepted and friends list updated for both users.");
    }).catchError((error) {
      print("Failed to accept friendship: $error");
    });
  }

  void _declineRequest(String docId) async {
    // 选择删除该请求
    await FirebaseFirestore.instance
        .collection('friendships')
        .doc(docId)
        .delete();
    // 或者，更新状态为declined（取决于您的应用逻辑）
    await FirebaseFirestore.instance
        .collection('friendships')
        .doc(docId)
        .update({
      'status': 'declined',
    });
  }
}

// Login or Register Page
class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Flutter Chat"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "Welcome to Flutter Chat Demo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen(isLogin: true)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple, // 文字颜色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("Login"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(isLogin: false)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange, // 文字颜色
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("Register"),
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

  const LoginScreen({super.key, required this.isLogin});

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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        // 跳转到好友列表页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FriendsListScreen()),
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
        title: const Text('登录失败'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('确定'),
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

        // 跳转到好友列表页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FriendsListScreen()),
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
      appBar: AppBar(title: const Text("Login/Register")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
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

class ChatRoomScreen extends StatelessWidget {
  final String chatRoomId;

  const ChatRoomScreen({Key? key, required this.chatRoomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Room")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // 传递 chatRoomId 到 MessagesList，以便根据聊天室 ID 加载消息
              child: MessagesList(chatRoomId: chatRoomId),
            ),
            // 同样，传递 chatRoomId 到 NewMessage，以便知道将新消息发送到哪个聊天室
            NewMessage(chatRoomId: chatRoomId),
          ],
        ),
      ),
    );
  }
}

class MessagesList extends StatefulWidget {
  final String chatRoomId; // 添加chatRoomId作为成员变量

  const MessagesList({Key? key, required this.chatRoomId})
      : super(key: key); // 修改构造函数以接受chatRoomId
  // const MessagesList({super.key});

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
    final currentUserUid =
        FirebaseAuth.instance.currentUser?.uid; // 获取当前用户的 UID

    return StreamBuilder(
      // 这里是设置stream属性的地方
      stream: FirebaseFirestore.instance
          .collection('chats_record')
          .doc(widget.chatRoomId) // 使用widget.chatRoomId访问成员变量
          .collection('messages')
          .orderBy('createdAt', descending: true)
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

              // 根据消息的 senderId 和当前用户 UID 判断是否为发送者
              bool isMe = data['senderId'] == currentUserUid;
              return _buildMessageItem(context, data, isMe);
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
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    // final isMe = data['senderId'] == currentUserUid; // 根据senderId判断是否为当前用户发送
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
            // borderRadius: borderRadius,
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
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
  final String chatRoomId;
  const NewMessage({Key? key, required this.chatRoomId}) : super(key: key);

  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text;
    if (text.isEmpty) return; // 防止发送空消息

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _controller.text.trim().isEmpty) {
      return; // 确保用户已登录且消息不为空
    }

    FocusScope.of(context).unfocus();
    FirebaseFirestore.instance
        .collection('chats_record')
        .doc(widget.chatRoomId) // 使用正确的聊天室ID
        .collection('messages') // 指定到正确的子集合
        .add({
      'text': text,
      'createdAt': Timestamp.now(),
      'senderId': currentUser.uid,
      // 可能还需要包括发送者信息，如 'senderId': FirebaseAuth.instance.currentUser?.uid,
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
