
import 'package:crypto/crypto.dart';
import 'package:fctech/utils/SuperUserMode.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:fctech/utils/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/local_database_service.dart';
import '../utils/SharedPrefsUtil.dart';

class ConversationPage extends StatefulWidget {
  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  List<dynamic> conversations = [];
  List<String> participants = []; // List to store participants
  String conversationType = 'individual'; // Default conversation type
  String conversationName = ''; // Default conversation name
  String cursorID='';
  List<dynamic> currentConversation = [];

  final TextEditingController _participantController = TextEditingController(); // Controller for participant input

  @override
  void initState() {
    super.initState();
    _fetchConversation();
  }

  Future<void> _clearparticipants()async {
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    participants=[];
    participants.add(authToken?['username']);
  }


  Future<void> _fetchConversation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/messages/listUserConversations'),
        body: jsonEncode(
          authToken),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as List;
        setState(() {
          conversations = jsonResponse;
        });
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text(
                'Falha ao obter conversas: por favor tente mais tarde'),
            actions: [
              TextButton(
                onPressed: () {
                  print(response.body);
                  Navigator.of(context).pop();
                  },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Falha ao obter conversas, verifique a rede e tente de novo.'),
          actions: [
            TextButton(
              onPressed: () {
                print(e);
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final TextEditingController _messageController = TextEditingController(); // Controller for message input
    bool isConversationOpen = currentConversation.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Conversa'),
      ),
      body: isConversationOpen
          ? Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: currentConversation.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(

                  title: Text(currentConversation[index]['content']),
                  subtitle: Text('Enviado por: ${currentConversation[index]['senderId']}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Digite sua mensagem aqui...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_messageController.text); // Assuming you have a _sendMessage function
                  },
                ),
              ),
            ),
          ),
        ],
      )
          : ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(conversations[index]),
            leading: Icon(Icons.chevron_right),
            trailing: Icon(Icons.expand),
            onTap: () {
              _fetchCurrentConversation(index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddParticipantDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }


  String sanitizeForSQLite(String input) {
    final invalidCharacters = RegExp(r'[^\w]');
    return input.replaceAll(invalidCharacters, '_');
  }

  void _fetchCurrentConversation(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    String conversationId = conversations[index];
    String idforsql=sanitizeForSQLite(conversationId);
    final databaseService = await LocalDatabaseService.create(idforsql);
    bool isDatabaseEmpty = await databaseService.isDatabaseEmpty(idforsql);
    if (true) {//change for when we have the method to check for new messages, it'll be like isdatabaseempty&&nonewMessages
    final response = await http.post(
      Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/messages/listConversationByIdCursor'),
      body: jsonEncode({
        'token': authToken,
        "pageSize": 15,
        "cursorStr": null,
        'conversationId': conversationId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      //final jsonResponse = jsonDecode(response.body) as List;
      final JsonCode = jsonDecode(response.body) as Map<String,dynamic>;
       String cursorId= JsonCode['nextCursorStr'];
      List jsonResponse= JsonCode['messages'];
      //String cursorId= '';
      jsonResponse.sort((a, b) => DateTime.fromMillisecondsSinceEpoch(a['timestamp']).compareTo(DateTime.fromMillisecondsSinceEpoch(b['timestamp'])));
      for(var Message in jsonResponse){
        await databaseService.insertContent(idforsql, Message);
      }
      print(jsonResponse);
      Navigator.of(context).push(
        MaterialPageRoute(

          builder: (context) => CurrentConversationPage(conversation: jsonResponse,conversationID: conversationId, authToken: authToken,cursor: cursorId),
        ),
      );
    } else {
      print('Falha ao buscar a conversa: por favor tente mais tarde');
    }
    }
    else{
      List<dynamic>conversation= await databaseService.getAllContent(idforsql);
      Navigator.of(context).push(
        MaterialPageRoute(

          builder: (context) => CurrentConversationPage(conversation:conversation ,conversationID: conversationId, authToken: authToken,cursor:"" ),
        ),
      );
    }

  }

  void _createNewConversation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();

    // Construct the conversation data
    List<String> participants = this.participants;
    String conversationType = this.conversationType;
    String conversationName = this.conversationName;

    Map<String, dynamic> conversationData = {
      'participants': participants,
      'conversationName': conversationName,
      'conversationType': conversationType,
    };

    // Construct the request body
    Map<String, dynamic> requestBody = {
      'token': authToken,
      'conversationData': conversationData,
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/messages/createConversation'),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        // Conversation created successfully
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text(
                'Falha ao criar a conversa por favor tente mais tarde'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Falha ao criar conversa'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showAddParticipantDialog() {
    List<TextEditingController> controllers = [TextEditingController()];
    String? conversationType;
    TextEditingController _conversationNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Criar Conversa'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    TextField(
                      controller: _conversationNameController,
                      decoration: InputDecoration(labelText: 'Nome da conversa'),
                    ),
                    DropdownButton<String>(
                      value: conversationType,
                      hint: Text('Tipo da conversa'),
                      onChanged: (String? newValue) {
                        setState(() {
                          conversationType = newValue;
                        });
                      },
                      items: <String>['individual', 'grupo']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    ...controllers.map((controller) => TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'Nome do usuário'),
                    )),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          controllers.add(TextEditingController());
                        });
                      },
                      child: Text('Adicionar outro usuário'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    conversationName = _conversationNameController.text;
                    this.conversationType = conversationType!;
                    //_clearparticipants();
                    participants = controllers.map((controller) => controller.text).toList();
                    _createNewConversation();
                    print(participants);
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage(String message)async{

  }
  void _addParticipant(String username) {
    if (username.isNotEmpty) {
      setState(() {
        participants.add(username);
        if (participants.length > 2) {
          conversationType = 'group';
        } else {
          conversationType = 'individual';
          if (participants.length == 2) {
            conversationName = participants.join('-');
          }
        }
      });
    }
  }
}
class CurrentConversationPage extends StatefulWidget {
  final String conversationID;
  final List<dynamic> conversation;
  final Map<String, dynamic>? authToken;
  final String cursor;

  CurrentConversationPage({Key? key, required this.conversation, required this.conversationID,required this.authToken, required this.cursor})
      : super(key: key);

  @override
  _CurrentConversationPageState createState() => _CurrentConversationPageState();
}
class _CurrentConversationPageState extends State<CurrentConversationPage> {
  List<dynamic> conversation = [];
  bool scrollingtop  =false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  String cursorId ="";

  Color getColorFromId(String id) {
    final bytes = utf8.encode(id);
    final digest = sha1.convert(bytes);
    return Color(digest.bytes[0] << 16 + digest.bytes[1] << 8 + digest.bytes[2]);
  }

  @override
  void initState() {
    super.initState();
    this.conversation = widget.conversation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null && android != null&&
          notification.title==widget.conversationID) {
        _fetchCurrentConversation(widget.conversationID);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
          }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        scrollingtop=true;
        if (_scrollController.position.pixels == 0) { // At top of the screen
          _loadMoreMessages();
        }
      }
    });
  }

  void _loadMoreMessages()async {
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final response = await http.post(
      Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/messages/listConversationByIdCursor'),
      body: jsonEncode({
        'token': authToken,
        "pageSize": 15,
        "cursorStr": cursorId,
        'conversationId': widget.conversationID,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      //final jsonResponse = jsonDecode(response.body) as List;
      final JsonCode = jsonDecode(response.body) as Map<String,dynamic>;
      String cursorId= JsonCode['nextCursorStr'];
      List jsonResponse= JsonCode['messages'];    jsonResponse.sort((a, b) =>
          DateTime.fromMillisecondsSinceEpoch(a['timestamp']).compareTo(
              DateTime.fromMillisecondsSinceEpoch(b['timestamp'])));
      setState(() {
        conversation.addAll(jsonResponse);
        conversation.sort((a, b) =>
            DateTime.fromMillisecondsSinceEpoch(a['timestamp']).compareTo(
                DateTime.fromMillisecondsSinceEpoch(b['timestamp'])));
        this.conversation = conversation;
        this.cursorId=cursorId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });
    } else {
      print('Falha ao buscar a conversa tente mais tarde');
    }
  }

    // Add your logic here to load more messages



  void _scrollToBottom() {
    if(!scrollingtop)
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }


  String time(DateTime time){
    DateTime currentTime=DateTime.now();
    Duration diff = currentTime.difference(time);
    if (diff.inSeconds<60)
    return diff.inSeconds.toString()+' secs\n atrás';
    if (diff.inMinutes<60)
      return diff.inMinutes.toString()+' mins\n atrás';
    if (diff.inHours<24)
      return diff.inHours.toString()+' horas\n atrás';
    if (diff.inDays<30)
      return diff.inDays.toString()+' dias\n atrás';

    String current=time.day.toString()+"/"+time.month.toString()+" -"+time.hour.toString()+":"+time.minute.toString()+'\n atrás';
    return current;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversa'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: conversation.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: conversation[index]['senderId'] == widget.authToken?['username'] ? Colors.lightGreenAccent : Colors.lightBlue,
                    borderRadius: BorderRadius.circular(40), // Adjust the value to change the oval shape
                  ),
                  child: ListTile(
                    leading: Text(time(DateTime.fromMillisecondsSinceEpoch(conversation[index]['timestamp']))),
                    title: Text(conversation[index]['senderId']),
                    subtitle: Text(conversation[index]['content']),
                  ),
                );
              },
            ),
          ),
          TextField(
            maxLength: 500,
            cursorColor: Color(50),
            controller: _textController,
            onSubmitted: (message) {
              _sendMessage(message);
              _textController.clear();
            },
            decoration: InputDecoration(
              labelText: 'Escreve a tua mensagem',
                suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if(_textController.text.isNotEmpty){
                        _sendMessage(_textController.text);
                        _textController.clear();
                      }

                    }
                    ),
                ),
            ),
        ],
      ),
    );
  }



  Future<void> _sendMessage(String message) async {
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();

    // Construct the conversation data
    String conversationID = widget.conversationID;

    Map<String, dynamic> MessageData = {
      'message': message,
      'conversationName': conversationID,
    };

    // Construct the request body
    Map<String, dynamic> requestBody = {
      'token': authToken,
      'messageData': MessageData,
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/messages/sendMessage'),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print("success");
         _fetchCurrentConversation(widget.conversationID);
      } else {
        print(response.body);
      }
    }

    catch (e) {
    print(e);
    }
  }

  Future<bool> checkRecentMessages(Map<String, dynamic> authToken, String messageId) async {
    final response = await http.post(
      Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/messages/checkRecentMessages'),
      body: jsonEncode({
        'token': authToken,
        'messageId': messageId,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print(response.body);
      // Assuming the server returns a boolean to indicate if a new message exists
      return jsonDecode(response.body);
    } else {
      print('Falha ao obter novas mensagens tente mais tarde');
      return false;
    }
  }

  void _fetchCurrentConversation(String conversationId) async {
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();

    String lastMessageId = this.conversation.isNotEmpty ? conversation.last
        ['messageID'] : 0;

    bool newMessageExists = await checkRecentMessages(
        authToken!, lastMessageId );

    if (newMessageExists) {
      final response = await http.post(
        Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/messages/listConversationByIdCursor'),
        body: jsonEncode({
          'token': authToken,
          "pageSize": 20,
          "cursorStr": null,
          'conversationId': conversationId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        //final jsonResponse = jsonDecode(response.body) as List;
        final JsonCode = jsonDecode(response.body) as Map<String,dynamic>;
        String cursorId= JsonCode['nextCursorStr'];
        List jsonResponse= JsonCode['messages'];    jsonResponse.sort((a, b) =>
            DateTime.fromMillisecondsSinceEpoch(a['timestamp']).compareTo(
                DateTime.fromMillisecondsSinceEpoch(b['timestamp'])));
        setState(() {
          this.conversation = jsonResponse;
          this.cursorId=cursorId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });
      } else {
        print('Falha ao buscar a conversa tente mais tarde');
      }
    }
  }

}
