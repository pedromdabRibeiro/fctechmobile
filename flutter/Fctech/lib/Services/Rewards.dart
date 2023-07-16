import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../utils/SharedPrefsUtil.dart';

class RewardPage extends StatefulWidget {
  final String rewards;

  RewardPage({Key? key, required this.rewards}) : super(key: key);

  @override
  _RewardPageState createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  List rewards = [];

  @override
  void initState() {
    super.initState();
    loadRewards();
  }

  loadRewards() {
    setState(() {
      rewards = jsonDecode(widget.rewards);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recompensas'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: rewards.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(rewards[index]["rewardKey"]),
                content: Text('Custo em Pontos: ${rewards[index]["points"]} \nDescrição: ${rewards[index]["description"]}'),
                actions: [
                  TextButton(
                      onPressed: () => purchaseReward(rewards[index]["rewardKey"]),
                      child: Text('Comprar Recompensa')
                  ),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar')
                  ),
                ],
              ),
            ),
            child: Card(
              child: Center(child: Text(rewards[index]["rewardKey"])),
            ),
          );
        },
      ),
    );
  }
  Future<void> purchaseReward(String rewardKey)async{
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final url = Uri.parse(
        'http://wired-compass-389110.oa.r.appspot.com/rest/points/redeemReward');
    final body = jsonEncode({
      'token': authToken,
      'rewardKey': rewardKey,
    });
    final headers = {'Content-Type': 'application/json;charset=utf-8'};
    print(body);
    final response = await http.post(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      _showSuccessDialog();
   //   Navigator.pop(context);
    }
    else{
      _showErrorDialog(response.body);
      print(response.statusCode);
      print('Response:'+response.body);
     // Navigator.pop(context);
    }
  }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Comprado'),
          content: Text('O seu item foi comprado com sucesso, ira ser contactado em breve!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                // Navigate back to /main page
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Falha'),
          content: Text('Uma falha ocorreu por favor verifique os seus pontos e tente mais tarde'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}