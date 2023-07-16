import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/processDate.dart';
import '../utils/SharedPrefsUtil.dart';
import 'Anomaly.dart';
import 'ReportUser.dart';

class UserSettingsPage extends StatelessWidget {


  Future<int?> showYearPicker(BuildContext context) async {
    int? selectedYear;
    int startYear=2018;
    final yearList = List<int>.generate(DateTime.now().year - startYear + 1, (i) => i + startYear);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    String role=authToken?['role'];
    print(role);
    if(role!='PROFESSOR'&&role!='ALUNO'){
      return 0;
    }
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione um ano'),
          content: DropdownButton<int>(
            value: yearList.last,
            items: yearList.map((int year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text('$year'),
              );
            }).toList(),
            onChanged: (int? newValue) async {
              selectedYear = newValue;
              prefs.setString('SelectedYear',selectedYear.toString());
              DateTime current = DateTime.now();
              print(selectedYear);
              Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
               // Construct the request body
              Map<String, dynamic> requestBody = {
              'token': authToken,
              'year': selectedYear,
              };
              try {
                final response = await http.post(
                  Uri.parse(
                      'https://wired-compass-389110.oa.r.appspot.com/rest/listSchedule/getOwnSchedule$role'),
                  body: jsonEncode(requestBody),
                  headers: {'Content-Type': 'application/json'},
                );
                if (response.statusCode == 200) {

                  final response1 = await http.post(
                  Uri.parse(
                  'https://wired-compass-389110.oa.r.appspot.com/rest/personalEvent/getPersonalEventsByYear'),
                  body: jsonEncode(requestBody),
                  headers: {'Content-Type': 'application/json'},
                  );
                  print( "this is my response for personal events \n"+response1.body);
                  await parseJsonToEvents(response.body);
                   parseJsonToEvents(response1.body);
                  // Conversation created successfully
                } else {
                  print(response.statusCode);
                  showDialog(
                    context: context,
                    builder: (_) =>
                        AlertDialog(
                          title: Text('Error'),
                          content: Text(
                              'Falha ao obter o horario:por favor tente mais '
                                  'tarde'),
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
                  builder: (_) =>
                      AlertDialog(
                        title: Text('Erro'),
                        content: Text('Falha, por favor tente mais tarde'),
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
    Navigator.of(context).pop(selectedYear);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Settings de utilizador'),
      ),
      body: ListView(
        children: <Widget>[
      ListTile(
      leading: Icon(Icons.access_time_outlined),
      title: Text('Mudar de ano'),
      onTap: () {showYearPicker(context);}
    ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Mudar a  Password'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Mudar o  Perfil'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeProfilePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_remove),
            title: Text('Apagar a conta'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeleteAccountPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.report),
            title: Text('Reportar Utilizador'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportUserPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.report_problem),
            title: Text('Reportar Anomalia'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnomalyPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Listar Anomalias'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListAnomalyPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Mudar Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: oldPasswordController,
              decoration: InputDecoration(labelText: 'Password Antiga'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: 'Nova Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirmar  Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () {
                changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                  confirmPasswordController.text,
                );
              },
              child: Text('Mudar Password'),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> changePassword(String oldPassword, String newPassword,
      String confirmPassword) async {
    if (newPassword == confirmPassword) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
      final url = Uri.parse(
          'http://wired-compass-389110.oa.r.appspot.com/rest/changePassword');
      final body = jsonEncode({
        'token': authToken,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      final headers = {'Content-Type': 'application/json;charset=utf-8'};

      final response = await http.post(url, body: body, headers: headers);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password mudada com sucesso')),
        );
        // Password changed successfully, redirect to login page
        Navigator.pushNamed(context, '/main');
      } else {
        if (response.statusCode == 406) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sessão inválida por favor volte a fazer login')),
          );
          Navigator.pushNamed(context, '/login');
        }
        // Password change failed, handle the error
        print('Change password failed! Error code: ${response.statusCode}');
      }
    } else {
      print("As novas passwords não são iguais");
    }
  }
}

  class ChangeProfilePage extends StatefulWidget {
  @override
  _ChangeProfilePageState createState() => _ChangeProfilePageState();
}

class _ChangeProfilePageState extends State<ChangeProfilePage> {
  final newEmailController = TextEditingController();
  final newNameController = TextEditingController();
  final newNifController = TextEditingController();
  final newPhoneController = TextEditingController();
  final newMobilePhoneController = TextEditingController();
  final newPrivacyController = TextEditingController();
  final newAddressController = TextEditingController();
  final newCompAddressController = TextEditingController();
  final newLocalityController = TextEditingController();
  final newZipCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Mudar Perfil'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: newEmailController,
                decoration: InputDecoration(labelText: 'Novo email'),
              ),
              TextField(
                controller: newNameController,
                decoration: InputDecoration(labelText: 'Novo Nome'),
              ),
              TextField(
                controller: newNifController,
                decoration: InputDecoration(labelText: 'Novo NIF'),
              ),
              TextField(
                controller: newPhoneController,
                decoration: InputDecoration(labelText: 'Novo numero de telefone'),
              ),
              TextField(
                controller: newMobilePhoneController,
                decoration: InputDecoration(labelText: 'Novo numero de telémovel'),
              ),
              TextField(
                controller: newPrivacyController,
                decoration: InputDecoration(labelText: 'Nova  Privacidade'),
              ),
              TextField(
                controller: newAddressController,
                decoration: InputDecoration(labelText: 'Adresso novo'),
              ),
              TextField(
                controller: newCompAddressController,
                decoration: InputDecoration(labelText: 'CompAddress novo'),
              ),
              TextField(
                controller: newLocalityController,
                decoration: InputDecoration(labelText: 'Nova Localidade'),
              ),
              TextField(
                controller: newZipCodeController,
                decoration: InputDecoration(labelText: 'ZipCode Novo'),
              ),
              ElevatedButton(
                onPressed: () {
                  updateUser(
                    newEmailController.text,
                    newNameController.text,
                    newNifController.text,
                    newPhoneController.text,
                    newMobilePhoneController.text,
                    newPrivacyController.text,
                    newAddressController.text,
                    newCompAddressController.text,
                    newLocalityController.text,
                    newZipCodeController.text,
                  );
                },
                child: Text('Atualizar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateUser(
      String newEmail,
      String newName,
      String newNif,
      String newPhone,
      String newMobilePhone,
      String newPrivacy,
      String newAddress,
      String newCompAddress,
      String newLocality,
      String newZipCode,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final url = Uri.parse('http://wired-compass-389110.oa.r.appspot.com/rest/updateUser');
    final body = jsonEncode({
      'updatedUsername': authToken?['username'],
      'token': authToken,
      'newEmail': newEmail,
      'newName': newName,
      'newNif': newNif,
      'newPhone': newPhone,
      'newMobilePhone': newMobilePhone,
      'newPrivacy': newPrivacy,
      'newAddress': newAddress,
      'newCompAddress': newCompAddress,
      'newLocality': newLocality,
      'newZipCode': newZipCode,
    });
    final headers = {'Content-Type': 'application/json;charset=utf-8'};

    final response = await http.put(url, body: body, headers: headers);

    if (response.statusCode == 200) {
      // Profile updated successfully, redirect to the main page
      Navigator.pushNamed(context, '/main');
    } else {

      if(response.statusCode==406){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('token invalido por favor fazer login de novo')),
        );
        Navigator.pushNamed(context, '/login');
      }
      // Profile update failed, handle the error
      print('Update profile failed! Error code: ${response.statusCode}');
    }
  }
}
class DeleteAccountPage extends StatefulWidget {
  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final deletedUsernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Apagar Conta'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: deletedUsernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteAccount(deletedUsernameController.text);
              },
              child: Text('Apagar conta'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> deleteAccount(String deletedUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    if (authTokenJson == null) {
      print('Auth token not found!');
      return;
    }
    Map<String, dynamic> authToken = jsonDecode(authTokenJson);

    final url = Uri.parse('http://wired-compass-389110.oa.r.appspot.com/rest/delete');
    final body = jsonEncode({
      'token': authToken,
      'deletedUsername': deletedUsername,
    });
    final headers = {'Content-Type': 'application/json;charset=utf-8'};

    final response = await http.delete(url, body: body, headers: headers);

    if (response.statusCode == 200) {
      if (authToken['username'] != deletedUsername) {
        Navigator.pushNamed(context, '/main');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        await prefs.clear();
      }
    } else {
      // Account deletion failed, handle the error
      print('Falha ao apagar a conta codigo de erro: ${response.statusCode}');
    }
  }
}

