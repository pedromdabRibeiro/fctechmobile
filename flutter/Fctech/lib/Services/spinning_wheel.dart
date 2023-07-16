import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import '../Pages/Mainpage.dart';
import '../utils/SharedPrefsUtil.dart';

class SpinningWheelPage extends StatefulWidget {
  @override
  _SpinningWheelPageState createState() => _SpinningWheelPageState();
}
Future<void> AddPoints(int Points)async {
  Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
  final url = Uri.parse(
      'http://wired-compass-389110.oa.r.appspot.com/rest/points/addPoints');
  final body = jsonEncode({
    'token': authToken,
    'points': Points,
  });
  final headers = {'Content-Type': 'application/json;charset=utf-8'};
  print(body);
  final response = await http.post(url, body: body, headers: headers);
  if (response.statusCode == 200) {
    print('pontos adicionados com sucesso');
  }
  else{
    print(response.statusCode);
    print('Response:'+response.body);
  }
}

class _SpinningWheelPageState extends State<SpinningWheelPage> {
  StreamController<int> selected = StreamController<int>();
  final items = <int>[10,10,20,50,40,50,5,30,10,20,10,0,50,10,10,40,5];
  bool first=true;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Roda dos pontos'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FortuneWheel(
              selected: selected.stream,
              items: [
                for (var it in items) FortuneItem(child: Text(it.toString())),
              ],
              duration: Duration(seconds: 3),
            ),
          ),
          ElevatedButton(
            child: Text("Rodar a roda"),
            onPressed: () {
              if(first) {
                int selectedItem = Fortune.randomInt(0, items.length);
                selected.add(selectedItem);
                Future.delayed(Duration(seconds: 3), () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                    new AlertDialog(
                      title: new Text("Parabéns!"),
                      content: new Text(
                          "Ganhaste ${items[selectedItem]} pontos"),
                      actions: <Widget>[
                        ElevatedButton(
                          child: Text('OK'),
                          onPressed: () {
                            AddPoints(items[selectedItem]);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => MainPage()));
                          },
                        )
                      ],
                    ),
                  );
                });
              first=false;
              }
              },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}
