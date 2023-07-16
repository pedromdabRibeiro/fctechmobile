import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/SharedPrefsUtil.dart';

class ReportUserPage extends StatefulWidget {
  @override
  _ReportUserPageState createState() => _ReportUserPageState();
}

class _ReportUserPageState extends State<ReportUserPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _userTargetController = TextEditingController();
  String? _selectedReason;
  TextEditingController _descriptionController = TextEditingController();

  List<String> _reasons = [
    "Comportamento Inapropriado", "Assedio", "Spam", "Personificacao",
    "Intimidacao", "Discurso de Odio", "Violencia",
  ];

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    return authTokenJson;
  }

  Future<void> _submitReportTicket() async {
    if (_formKey.currentState!.validate()) {
      // Retrieve auth token
      String? authTokenJson = await getAuthToken();

      if (authTokenJson == null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text('Token invalido por favor fazer login de novo'),
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
        return;
      }

      // Prepare the request data
      String userTarget = _userTargetController.text;
      String? reasonToReport = _selectedReason;
      String description = _descriptionController.text;

      print(reasonToReport);
      // Create the request body
      Map<String, dynamic> requestBody = {
        'token': jsonDecode(authTokenJson),
        'ticket': {
          'userSubmitted': jsonDecode(authTokenJson)['username'] as String,
          'userTarget': userTarget,
          'reasonToReport': reasonToReport,
          'description': description,
        },
      };

      // Convert the request body to JSON
      String requestJson = jsonEncode(requestBody);

      // Make the POST request
      String url = 'http://wired-compass-389110.oa.r.appspot.com/rest/reportTicket/createTicket';
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestJson,
      );

      // Handle the response
      if (response.statusCode == 200) {
        // Report ticket created successfully
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Sucesso'),
            content: Text('Criado report de um utilizador'),
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
      } else {
        // Failed to create the report ticket
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text('Falha ao reportar utilizador: por favor tente mais tarde'),
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
  }

  @override
  void dispose() {
    _userTargetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar : AppBar(
        title: Text('Reportar utilizador'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _userTargetController,
                  decoration: InputDecoration(labelText: 'Utilizador a reportar'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor meter pessoa';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedReason = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Razão por reportar',
                  ),
                  items: _reasons.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor escolha uma razao';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  maxLength: 700,
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Descrição do motivo por reportar'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor submeter razão';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submitReportTicket,
                  child: Text('Submeter'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MyReportTicketsPage()),
                    );
                  },
                  child: Text('Ver os meus reports'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyReportTicketsPage extends StatefulWidget {
  @override
  _MyReportTicketsPageState createState() => _MyReportTicketsPageState();
}

class _MyReportTicketsPageState extends State<MyReportTicketsPage> {
  List<Map<String, dynamic>> _tickets = [];

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    return authTokenJson;
  }
  Future<void> _fetchTickets() async {
    String? authTokenJson = await getAuthToken();

    if (authTokenJson == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Auth Token invalido por favor fazer login de novo'),
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
      return;
    }

    String url = 'http://wired-compass-389110.oa.r.appspot.com/rest/listReportTickets/listUserTickets';
    http.Response response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: authTokenJson,
    );

    if (response.statusCode == 200) {
      _tickets = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      setState(() {});
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Falha ao listar bilhetes de report :por favor tente mais tarde'),
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

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus bilhetes de  report'),
      ),
      body: ListView.builder(
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return ListTile(
            title: Text(ticket['userTarget']+': '+ticket['reasonToReport']),
            subtitle: Text(ticket['description']),
          );
        },
      ),
    );
  }
}


class ShowAllTicketsPage extends StatefulWidget {
  @override
  _ShowAllTicketsPageState createState() => _ShowAllTicketsPageState();
}

class _ShowAllTicketsPageState extends State<ShowAllTicketsPage> {
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    fetchTickets();

  }

  Future<void> fetchTickets() async {
    try {
      final response = await http.get(Uri.parse('http://wired-compass-389110.oa.r.appspot.com/rest/listReportTickets/listAllTickets'));
      if (response.statusCode == 200) {
        _tickets = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        print(_tickets);
        setState(() {});

      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text('Falha ao obter report tickets por favor tente mais tarde'),
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
      // Handle network or API call error
    }
  }

  Future <void> deleteTicket(int index) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();

    final url = Uri.parse(
        'http://wired-compass-389110.oa.r.appspot.com/rest/reportTicket/deleteTickets');
    final body = jsonEncode({
      'token': authToken,
      'ticketID': _tickets[index]['ticketID'],
    });
    final headers = {'Content-Type': 'application/json;charset=utf-8'};

    final response = await http.delete(url, body: body, headers: headers);

    // Handle delete ticket functionality for the ticket at the given index
    // You can make a DELETE request to your REST API to delete the ticket
    if (response.statusCode == 200) {
      // Show a popup or snackbar with the message "Ticket successfully deleted"
      showDialog(
        context: context, // Assuming you have access to the context
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Bilhete Apagado'),
            content: Text('Bilhete apagado com sucesso'),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  // Close the popup and refresh the page
                  Navigator.of(context).pop();
                 fetchTickets();
                },
              ),
            ],
          );
        },
      );
    }
    else {
      // Show a popup or snackbar with the response body
      showDialog(
        context: context, // Assuming you have access to the context
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erro'),
            content: Text(response.body),
            actions: [
              ElevatedButton(
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

  Future<void> updateTicketStatus(int index) async {
    List<String> statuses = ["Resolvido", "Em analise", "Por analisar"];
    String selectedStatus = statuses[0]; // Default selected status

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder( // <--- Use StatefulBuilder here
        builder: (BuildContext context, StateSetter setState) { // <--- StateSetter for this subtree
          return AlertDialog(
            title: Text('Atualizar o estado do Bilhete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedStatus,
                  onChanged: (String? newValue) {
                    setState(() { // <--- This now refers to the local state
                      selectedStatus = newValue!;
                    });
                  },
                  items: statuses.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
                        print('ticketID:'+ _tickets[index]['ticketID'].toString());
                        print('newState:'+selectedStatus);
                        print('token:'+authToken.toString());
                        final url = Uri.parse('http://wired-compass-389110.oa.r.appspot.com/rest/reportTicket/changeTicketState');
                        final body = jsonEncode({
                          'token': authToken,
                          'ticketID': _tickets[index]['ticketID'],
                          'newState': selectedStatus,
                        });
                        final headers = {'Content-Type': 'application/json;charset=utf-8'};

                        final response = await http.post(url, body: body, headers: headers);

                        if (response.statusCode == 200) {
                          print('response=200');
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Bilhete atualizado'),
                                content: Text('Bilhete atualizado para o estado: $selectedStatus'),
                                actions: [
                                  ElevatedButton(
                                    child: Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      fetchTickets(); // Refresh the ticket list
                                    },
                                  ),
                                ],
                              );
                            },
                          );

                          // Update the ticket status in the local list
                          _ShowAllTicketsPageState().setState(() {
                            _tickets[index]['state'] = selectedStatus;
                          });
                        } else {
                          print('response='+ response.statusCode.toString());
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Erro'),
                                content: Text(response.body),
                                actions: [
                                  ElevatedButton(
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

                        //Navigator.of(context).pop();
                      },
                      child: Text('Submeter'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bilhetes de report'),
      ),
      body: ListView.builder(
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return ListTile(
            title: Text(ticket['userTarget'] + ': ' + ticket['reasonToReport']),
            subtitle: Text('Estado:'+ticket['state']+'\n'+'descrição:'+ticket['description']),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Opções do bilhete'),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          deleteTicket(index);
                          Navigator.of(context).pop();
                        },
                        child: Text('Apagar Bilhete'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                           updateTicketStatus(index);

                        },
                        child: Text('Atualizar estado'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }}
