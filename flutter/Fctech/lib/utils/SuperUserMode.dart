import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../Pages/Mainpage.dart';
import '../Pages/Upload_image.dart';
import '../Services/local_database_service.dart';


class SuperUserModePage extends StatelessWidget {
  @override
  Future<void> listUsers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    if (authTokenJson == null) {
      print('Auth token not found!');
      return;
    }
    Map<String, dynamic> authToken = jsonDecode(authTokenJson);
    String role = authToken['role'];

    String endpoint;
    switch (role) {
      case 'USER':
        endpoint = '/rest/getUsers/listUsers';
        break;
      case 'GBO':
        endpoint = '/rest/getUsers/listGBO';
        break;
      case 'GS':
        endpoint = '/rest/getUsers/listGS';
        break;
      case 'SU':
        endpoint = '/rest/getUsers/listSU';
        break;
      default:
        print('Invalid role: $role');
        return;
    }


    final url = Uri.parse(
        'http://wired-compass-389110.oa.r.appspot.com' + endpoint);
    final headers = {'Content-Type': 'application/json;charset=utf-8'};

    final response = await http.get(url, headers: headers);

    List<Map<String, String>> parseUsersFromString(List<dynamic> usersJson) {
      final List<Map<String, String>> users = [];

      for (var userObj in usersJson) {
        if (userObj is Map<String, dynamic>) {
          final user = Map<String, String>.from(userObj)
              .map((key, value) => MapEntry(key, value.toString()));
          users.add(user);
        }
      }

      return users;
    }

    if (response.statusCode == 200) {
      final LocalDatabaseService _localDatabaseService = LocalDatabaseService('users');
      _localDatabaseService.clearDatabase('my_content');

      List<dynamic> usersJson = jsonDecode(response.body);
      List<Map<String, String>> users = parseUsersFromString(usersJson);

      for (var user in users) {
        // Insert user into the local database
        await _localDatabaseService.insertContent('my_content',user);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserListPage(users: users),
        ),
      );
    } else {
      print('Failed to list users! Error code: ${response.statusCode}');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super User Mode'),
      ),
      backgroundColor: Colors.lightBlue[100], // Set the background color to blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdateRolePage()),
                );
              },
              child: Text('Atualizar o papel de um User'),
            ),
            ElevatedButton(
              onPressed:  () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CameraPage()),);
              },
              child: Text('Tirar foto para o onde estou'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => listUsers(context),
              child: Text('Listar Users'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/show_all_tickets');
              },
              child: Text('Mostrar Tickets'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create_restaurant');
              },
              child: Text('Criar restaurante'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create_department');
              },
              child: Text('Criar departamento'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create_classroom');
              },
              child: Text('Criar sala de aula'),
            ),
          ],
        ),
      ),
    );
  }

}


class RestaurantRequest {
  RestaurantData restaurantData;

  RestaurantRequest(this.restaurantData);

  Future<Map<String, dynamic>> toJson() async {
    Map<String, dynamic> token = await getAuthToken();
    return {
      'token': token,
      'restaurantData': restaurantData.toJson(),
    };
  }
}

Future<Map<String, dynamic>> getAuthToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? authTokenJson = prefs.getString('authToken');
  print(authTokenJson);
  return jsonDecode(authTokenJson!);

}



class UpdateRolePage extends StatefulWidget {
  @override
  _UpdateRolePageState createState() => _UpdateRolePageState();
}

class _UpdateRolePageState extends State<UpdateRolePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _variableController = TextEditingController();
  String? _selectedRole;
  List<String> _roles = ["ALUNO", "TRABALHADOR", "PROFESSOR", "MT", "MA", "GT", "GA", "SU"];



  Future<void> updateRole() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> token = await getAuthToken();

      var body = jsonEncode({
        "token": token,
        "updatedUsername": _usernameController.text,
        "newRole": _selectedRole,
        "variable": _selectedRole == "PROFESSOR" || _selectedRole == "MT" || _selectedRole == "MA" ? _variableController.text : "",
      });

      print(body);

      var response = await http.post(
        Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/updateRole'),
        body: body,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(response.body);
      }
    }
  }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Atualizado'),
          content: Text('O papel da pessoa foi atualizado com sucesso!'),
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
          content: Text('Não foi possivel atualizar o papel da pessoa: $errorMessage'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atualizar o papel de um user'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor escolher o user';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                  ),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecione um papel';
                    }
                    return null;
                  },
                ),
                if (_selectedRole == "PROFESSOR" || _selectedRole == "MT" || _selectedRole == "MA")
                TextFormField(
                  controller: _variableController,
                  decoration: InputDecoration(
                    labelText: 'Variable',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Favor preencher o campo';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: updateRole,
                  child: Text('Atualizar papel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class MarkRestaurantPage extends StatefulWidget {
  @override
  _MarkRestaurantPageState createState() => _MarkRestaurantPageState();
}
class RestaurantData {
  double lat;
  double lng;
  String restaurantName;
  String description;
  List<String> menu;
  String workingHours;

  RestaurantData(
      this.restaurantName,
      this.lat,
      this.lng,
      this.description,
      this.menu,
      this.workingHours,
      );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'restaurantName': restaurantName,
    'description': description,
    'menu': menu,
    'workingHours': workingHours,
  };

}

class _MarkRestaurantPageState extends State<MarkRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController restaurantNameController = TextEditingController();
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController menuController = TextEditingController();
  TextEditingController workingHoursController = TextEditingController();
  LatLng selectedLocation = LatLng(38.660961061071426, -9.2044984606523);
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Criar Restaurante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: restaurantNameController,
                decoration: InputDecoration(labelText: 'Nome de Restaurante'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the restaurant name';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: getUserLocation,
                child: Text('Obter localização atual'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Descrição'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor submeta uma descrição';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: menuController,
                decoration: InputDecoration(labelText: 'Menu'),
                validator: (value) {

                  return null;
                },
              ),
              TextFormField(
                controller: workingHoursController,
                decoration: InputDecoration(labelText: 'Working Hours'),
                validator: (value) {

                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    markRestaurant();
                  }
                },
                child: Text('Mark Restaurant'),
              ),
            ],
          ),
        ),
      ),
    );

  }

  void markRestaurant() async {
    final restaurantRequest = RestaurantRequest(
      RestaurantData(
        restaurantNameController.text,
        double.parse(latController.text),
        double.parse(lngController.text),
        descriptionController.text,
        menuController.text.split(','),
        workingHoursController.text,
      ),
    );

    final url = 'http://wired-compass-389110.oa.r.appspot.com/rest/markWaypoint/markRestaurant';
    final headers = <String, String>{'Content-Type': 'application/json'};

    final body = jsonEncode(await restaurantRequest.toJson()); // await here

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      // Restaurant marked successfully
      ScaffoldMessenger.of(context).showSnackBar( // ScaffoldMessenger instead of _scaffoldKey.currentState
        SnackBar(content: Text('Restaurant marked successfully')),
      );
    } else {
      // Failed to mark restaurant
      ScaffoldMessenger.of(context).showSnackBar( // ScaffoldMessenger instead of _scaffoldKey.currentState
        SnackBar(content: Text('Failed to mark restaurant')),
      );
    }
  }
  Future<void> getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // User denied location forever. Handle accordingly.
        return;
      }
      if (permission == LocationPermission.denied) {
        // Location permission is denied but not forever. Handle accordingly.
        return;
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latController.text = position.latitude.toString();
      lngController.text = position.longitude.toString();
    });
  }
}

class DepartmentRequest {
  Map<String,dynamic> token;
  DepartmentData departmentData;

  DepartmentRequest(this.token, this.departmentData);

  Map<String, dynamic> toJson() => {
    'token': token,
    'departmentData': departmentData.toJson(),
  };
}

class DepartmentData {
  String departmentName;
  int departmentNumber;
  double lat;
  double lng;
  String description;

  DepartmentData(
      this.departmentName,
      this.departmentNumber,
      this.lat,
      this.lng,
      this.description,
      );

  Map<String, dynamic> toJson() => {
    'departmentName': departmentName,
    'departmentNumber': departmentNumber,
    'lat': lat,
    'lng': lng,
    'description': description,
  };
}

class MarkDepartmentPage extends StatefulWidget {
  @override
  _MarkDepartmentPageState createState() => _MarkDepartmentPageState();
}
class UserListPage extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  UserListPage({required this.users});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('User List'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Value')),
          ],
          rows: [
            ...widget.users.expand((user) => user.entries.map((entry) {
              final type = entry.key;
              final value = entry.value ?? '';

              return DataRow(cells: [
                DataCell(Text(type)),
                DataCell(Text(value.toString())),
              ]);
            })),
          ],
        ),
      ),
    );
  }




  @override

  final LocalDatabaseService _localDatabaseService = LocalDatabaseService('users');
}

class _MarkDepartmentPageState extends State<MarkDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng selectedLocation = LatLng(38.660961061071426, -9.2044984606523);

  TextEditingController departmentNameController = TextEditingController();
  TextEditingController departmentNumberController = TextEditingController();
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Mark Department'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: departmentNameController,
                decoration: InputDecoration(labelText: 'Department Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the department name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: departmentNumberController,
                decoration: InputDecoration(labelText: 'Department Number'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the department number';
                  }
                  return null;
                },
              ), ElevatedButton(
                onPressed: getUserLocation,
                child: Text('Get Current Location'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {

                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    markDepartment();
                  }
                },
                child: Text('Mark Department'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void markDepartment() async {
    final departmentRequest = DepartmentRequest(
      await getAuthToken(), // Provide your AuthToken instance here
      DepartmentData(
        departmentNameController.text,
        int.parse(departmentNumberController.text),
        double.parse(latController.text),
        double.parse(lngController.text),
        descriptionController.text,
      ),
    );

    final url = 'http://wired-compass-389110.oa.r.appspot.com/rest/markWaypoint/markDepartment';
    final headers = <String, String>{'Content-Type': 'application/json'};

    final body = jsonEncode(await departmentRequest.toJson()); // await here

    final response = await http.post(
        Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      // Restaurant marked successfully
      ScaffoldMessenger.of(context)
          .showSnackBar( // ScaffoldMessenger instead of _scaffoldKey.currentState
        SnackBar(content: Text('Department marked successfully')),
      );
    } else {
      // Failed to mark restaurant
      ScaffoldMessenger.of(context)
          .showSnackBar( // ScaffoldMessenger instead of _scaffoldKey.currentState
        SnackBar(content: Text('Failed to mark department')),
      );
    }
  }
  Future<void> getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // User denied location forever. Handle accordingly.
        return;
      }
      if (permission == LocationPermission.denied) {
        // Location permission is denied but not forever. Handle accordingly.
        return;
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latController.text = position.latitude.toString();
      lngController.text = position.longitude.toString();
    });
  }
}
class ClassroomRequest {
  Map<String,dynamic> token;
  ClassroomData classroomData;

  ClassroomRequest(this.token, this.classroomData);

  Map<String, dynamic> toJson() => {
    'token': token,
    'classroomData': classroomData.toJson(),
  };
}

class ClassroomData {
  String classroomName;
  double lat;
  double lng;
  int departmentNum;
  String path;
  bool reservable;
  ClassroomData(
      this.classroomName,
      this.lat,
      this.lng,
      this.departmentNum,
      this.path,
      this.reservable
      );

  Map<String, dynamic> toJson() => {
    'classroomName': classroomName,
    'lat': lat,
    'lng': lng,
    'departmentNumber': departmentNum,
    'path': path,
    'isBookable':reservable,
  };
}

class MarkClassroomPage extends StatefulWidget {
  @override
  _MarkClassroomPageState createState() => _MarkClassroomPageState();
}

class _MarkClassroomPageState extends State<MarkClassroomPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController classroomNameController = TextEditingController();
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();
  TextEditingController departmentNumController = TextEditingController();
  TextEditingController pathController = TextEditingController();
  bool _isbookable=false ;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Mark Classroom'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: classroomNameController,
                decoration: InputDecoration(labelText: 'Classroom Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the classroom name';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: getUserLocation,
                child: Text('Get Current Location'),
              ),
              TextFormField(
                controller: departmentNumController,
                decoration: InputDecoration(labelText: 'Department Number'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the department number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: pathController,
                decoration: InputDecoration(labelText: 'Path'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the path';
                  }
                  return null;
                },
              ),
              CheckboxListTile(
                title: Text('Reservável'),
            value: _isbookable,
            onChanged: (bool? value){
              setState(() {
                _isbookable = value!;
              });
              },

            ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    markClassroom();
                  }
                },
                child: Text('Mark Classroom'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void markClassroom() async {
    final classroomRequest = ClassroomRequest(
      await getAuthToken(), // Provide your AuthToken instance here
      ClassroomData(
        classroomNameController.text,
        double.parse(latController.text),
        double.parse(lngController.text),
        int.parse(departmentNumController.text),
        pathController.text,
        _isbookable,
      ),
    );

    final url = 'http://wired-compass-389110.oa.r.appspot.com/rest/markWaypoint/markClassroom';
    final headers = <String, String>{'Content-Type': 'application/json'};

    final body = jsonEncode(await classroomRequest.toJson()); // await here

    final response = await http.post(
        Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      // Restaurant marked successfully
      ScaffoldMessenger.of(context)
          .showSnackBar( // ScaffoldMessenger instead of _scaffoldKey.currentState
        SnackBar(content: Text('Classroom marked successfully')),
      );
    } else {
      // Failed to mark restaurant
      print(response.statusCode);
      print(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar( // ScaffoldMessenger instead of _scaffoldKey.currentState
        SnackBar(content: Text('Failed to mark classroom')),

      );
    }
  }
  Future<void> getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // User denied location forever. Handle accordingly.
        return;
      }
      if (permission == LocationPermission.denied) {
        // Location permission is denied but not forever. Handle accordingly.
        return;
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latController.text = position.latitude.toString();
      lngController.text = position.longitude.toString();
      print(latController.text);
      print(lngController.text);
    });
  }
}

