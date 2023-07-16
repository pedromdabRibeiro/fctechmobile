
import'package:fctech/Services/GoogleMap.dart';
  import 'package:fctech/Pages/OfflineMode.dart';
  import 'package:fctech/Pages/registerpage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:flutter/material.dart';
  import 'dart:convert';
  import 'package:http/http.dart' as http;

  import 'package:shared_preferences/shared_preferences.dart';

  import '../Pages/FoodPage.dart';
import '../Pages/Mainpage.dart';
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Services/processDate.dart';
import 'SharedPrefsUtil.dart';

  class LoginPage extends StatefulWidget {
    @override
    _LoginPageState createState() => _LoginPageState();
  }
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.max,
  );
  Future<void> login(BuildContext context,String username, String password) async {
    final url = Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/login');
    final body = jsonEncode({'username': username, 'password': password});
    final headers = {'Content-Type': 'application/json;charset=utf-8'};

    final response = await http.post(url, body: body, headers: headers);

    if (response.statusCode == 200) {
      // Login successful, do something with the response
      final authToken = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String authTokenJson = jsonEncode(authToken);
      await prefs.setString('authToken', authTokenJson);

      print('Login successful! Auth token: $authToken');
      final _firebaseMessaging=FirebaseMessaging.instance;
      await _firebaseMessaging.requestPermission();
      final fCMToken=await _firebaseMessaging.getToken();
      await prefs.setString('fCMToken', fCMToken.toString());

      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);


      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // If `onMessage` is triggered with a notification, construct our own
        // local notification to show to users using the created channel.
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  icon: 'ic_stat_logo',
                  // other properties...
                ),
              ));
        }
      });
      print('Token:$fCMToken');

      final url1 = Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/utils/linkNewDevice');
      final body1 = jsonEncode({'token': jsonDecode(authTokenJson), 'firebaseToken': fCMToken});
      final headers1 = {'Content-Type': 'application/json;charset=utf-8'};
      print(body1);
      final response1 = await http.post(url1, body: body1, headers: headers1);

      if (response1.statusCode == 200) {
      await loadCalendar();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
      else{
        print(response1.body);
      }
    } else {
      // Login failed, show error message
     /* if(response.statusCode==403){
        print('Login falhou! Por favor tentar mais tardeError code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User não ativo')),
        );
      }*/
      print('Login failed! Error code: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username ou password errada')),
      );
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // Create an instance of FlutterLocalNotificationsPlugin
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize the plugin for Android
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize the plugin with settings
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Get title and body of the message
    String title = message.notification?.title ?? '';
    String body = message.notification?.body ?? '';

    // Create Android and IOS Notification Details
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'email_notifications', // channel ID
        'Email Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false);

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,);

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics
    );

    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Payload: ${message.data}');
  }


  class _LoginPageState extends State<LoginPage> {
    TextEditingController _usernameController = TextEditingController();
    TextEditingController _passwordController = TextEditingController();

    
    void _onOfflineModePressed() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OfflineModePage()),
      );
    }

    void _onMapPressed() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyGoogleMap()),
      );
    }

    @override
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.lightBlue[100],
        bottomNavigationBar: BottomAppBar(
          color: Colors.lightBlue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.map),
                onPressed: _onMapPressed,
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.zero,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    login(context, _usernameController.text,
                        _passwordController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                  child: Text('Login'),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FoodPage()),
                  );
                },
                child: Text(
                  'Encontrar sítio para comer',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text(
                  'Registar',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> loadCalendar()async {
    // Construct the request body
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    String role=authToken?['role'];
    if(role!='PROFESSOR'&&role!='ALUNO'){
      return ;
    }

    Map<String, dynamic> requestBody = {
      'token': authToken,
      'year': DateTime.now().year,
    };
    try {
      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/listSchedule/getOwnSchedule$role'),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('200');
        print(response.body);
        final response2 = await http.post(
          Uri.parse(
              'https://wired-compass-389110.oa.r.appspot.com/rest/personalEvent/getPersonalEventsByYear'),
          body: jsonEncode(requestBody),
          headers: {'Content-Type': 'application/json'},
        );
        print("this is my response for personal events \n" + response2.body);
        await parseJsonToEvents(response.body);
        if(response2.statusCode==200) {
          await parseJsonToEvents(response2.body);
          // Conversation created successfully
        }
        return;
      } else {
        print('not 200');
        print(response.statusCode);
        return;
      }
    } catch (e) {
     print(e);
      return;
    }

  }