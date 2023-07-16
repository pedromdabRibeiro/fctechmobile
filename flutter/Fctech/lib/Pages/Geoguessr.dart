import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Services/spinning_wheel.dart';
import '../utils/SharedPrefsUtil.dart';
import 'Anomaly.dart';

class OndeEstou extends StatefulWidget {
  final String difficulty;

  OndeEstou({required this.difficulty});

  @override
  _OndeEstouState createState() => _OndeEstouState();

}

class _OndeEstouState extends State<OndeEstou> {

  bool isLoading = true; // to track if we are still loading data
  Widget? currentPostWidget; // to store the current post widget

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  _initializeData() async {
    print('initializing data');
    posts = await _getGuesses(widget.difficulty);
    if (posts.isNotEmpty) {
      print('not empty posts');
      print(posts[0]);
      currentPostWidget = await _getPostWidget(posts[0]['gameLocationId']);
    }
    isLoading = false;
    setState(() {}); // triggers a rebuild of the widget tree
  }

  double? _latitude;
  double? _longitude;
  double score = 0.0;
  double difficultyMultiplier = 1.0;
  int postIndex = 0;
  List<Map<String,dynamic>> posts = [];
  late Future<List<Map<String,dynamic>>> postsFuture;

  Future<Widget> _getPostWidget(String postId) async {
    print('_getPostwidget');
    var postUrl = 'https://storage.googleapis.com/wired-compass-389110.appspot.com/'+postId;
    var isVideo = postId.toLowerCase().endsWith(".mp4");

      return AspectRatio(
        aspectRatio: 1.0,
        child: Image.network(
          postUrl,
          fit: BoxFit.cover,
        ),
      );
    }



  Future<List<Map<String,dynamic>>> _getGuesses(String difficulty) async {
    print('_getGuesses');
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    List<Map<String,dynamic>> posts = [];
    print('getting guesses');


    String Difficulty=widget.difficulty;
    switch (difficulty) {
      case 'facil':
        Difficulty = 'Easy';
        double difficultyMultiplier = 1.0;
        break;
      case 'normal':
        Difficulty = 'Normal';
        double difficultyMultiplier = 1.5;
        break;
      case 'dificil':
        Difficulty = 'Hard';
        double difficultyMultiplier = 2.0;
        break;
      default:
        break;
    }
  print('https://wired-compass-389110.oa.r.appspot.com/rest/geoguesser/list${Difficulty}GameLocations');
    final response = await http.post(
      Uri.parse(
          'https://wired-compass-389110.oa.r.appspot.com/rest/geoguesser/list${Difficulty}GameLocations'),
      body: jsonEncode(authToken),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print(response.body);
      posts = List<Map<String,dynamic>>.from(jsonDecode(response.body));

      setState(() {
        postIndex = 0;
      });
    } else {
      print(response.statusCode);
      print(response.body);
    }
    print('after getting the guesses');
    return posts;
  }


  Future<void> fetchCurrentCoordinates() async {
    LatLng? selectedLatLng;

    bool isPermissionGranted = await Permission.location.isGranted;
    LatLng initialLatLng;

    if (isPermissionGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        initialLatLng = LatLng(position.latitude, position.longitude);
      } catch (e) {
        initialLatLng = LatLng(38.66100540431834, -9.204493048694877);
      }
    } else {
      initialLatLng = LatLng(38.66100540431834, -9.204493048694877);
    }

    selectedLatLng = await showDialog<LatLng>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Selecione localização'),
        content: MapDialog(
          initialLatLng: initialLatLng,
          onMapTap: (LatLng? latLng) {
            selectedLatLng = latLng;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedLatLng == null) {
                _latitude = initialLatLng.latitude;
                _longitude = initialLatLng.longitude;
              } else {
                _latitude = selectedLatLng?.latitude;
                _longitude = selectedLatLng?.longitude;
              }
              Navigator.of(context).pop();
              Future.delayed(Duration(milliseconds: 500), () {
                Guess();
              });
              },
            child: Text('Adivinhar'),
          ),
        ],
      ),
    );

    if (selectedLatLng == null) {
      return;
    }

    try {
      setState(() {
        _latitude = selectedLatLng?.latitude;
        _longitude = selectedLatLng?.longitude;
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Falha ao obter as coordenadas.'),
          actions: [
            TextButton(
              onPressed: () {
                Guess();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }



Future<void> Guess() async {

    // Fetch the current post and the coordinates of its location
    Map<String, dynamic> post = posts[postIndex];
    double postLatitude = post['lat'];
    double postLongitude = post['lng'];
    print(post);
    // Calculate the distance from the guessed coordinates to the actual ones
    double distance = Geolocator.distanceBetween(_latitude!, _longitude!, postLatitude, postLongitude);

    // Award points based on the distance
    // Feel free to adjust this logic to fit your game mechanics
    if (distance < 2) {
      score += 10*difficultyMultiplier;  // Add 1000 points if the guess is within 100 meters
    } else if (distance < 10) {
      score += 5*difficultyMultiplier;  // Add 500 points if the guess is within 1000 meters
    } else if (distance < 20) {
      score += 2*difficultyMultiplier;  // Add 100 points if the guess is within 10 kilometers
    }

    print( 'score is :$score');
    // Move to the next post

    if (postIndex >= 4) {
     print('rewards');   // Show congratulatory popup after the 5th guess
       showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Parabéns '),
            content: Text('Pontuaste $score pontos!'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  AddPoints(score.toInt());
                  // Navigate back to /main page
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/main');
                },
              ),
            ],
          );
        },
      );
    return;
    }
    postIndex++;
    print(postIndex);
    Widget it= await _getPostWidget(posts[postIndex]['gameLocationId']);
    // Update the score in the UI
    setState(() {currentPostWidget= it;});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Onde estou'),
          centerTitle: true,
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              Expanded(
                child: currentPostWidget ?? SizedBox.shrink(),
              ),
              ElevatedButton(
                onPressed: () => fetchCurrentCoordinates(),
                child: Text('Onde estou'),
              ),
            ],
          ),
        ),
      );
    }
  }

}
