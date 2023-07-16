import 'package:fctech/Services/GoogleMap.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fctech/Services/local_database_service.dart';

class FindRoom extends StatefulWidget {
  const FindRoom({Key? key}) : super(key: key);

  @override
  _FindRoomState createState() => _FindRoomState();
}

class _FindRoomState extends State<FindRoom> {
  List<String> _departments = [];
  String _selectedDepartment = 'Escolha o  Departmento';
  String _roomName = '';
  List<Map<String, dynamic>> departmentsList = [];
  List<Map<String, dynamic>> classroomsList = [];
  List<String> _rooms = [];
  String _selectedRoom = 'Escolha a Sala';
  bool _isroom=false ;
  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchClassrooms() async {

    final departmentInfo = departmentsList.firstWhere(
            (department) =>
        department['departmentName'] == _selectedDepartment);

    print(departmentInfo['departmentNumber']);
    Map<String, dynamic> requestBody = {
      'departmentNumber': departmentInfo['departmentNumber'],
    };
    final response = await http.post(Uri.parse(
        'https://wired-compass-389110.oa.r.appspot.com/rest/listWaypoint/getClassroom'),body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},);


    if (response.statusCode == 200) {
      final List<dynamic> classroomsJson = jsonDecode(response.body);
      classroomsList = classroomsJson.cast<Map<String, dynamic>>().toList();
      print(response.body);


    } else {
      print(response.body);
      print(response.statusCode);
      throw Exception('Falha ao obter departamentos');
    }

    List<String> classrooms = classroomsList
        .map((classroom) =>
    classroom.containsKey('classroomName') ? classroom['classroomName'].toString() : '')
        .toList();

    setState(() {
      _rooms= classrooms;
      if (_rooms.isNotEmpty) {
        _selectedRoom = _rooms.first;
      }
    });
  }
  Future<void> _fetchDepartments() async {
    final databaseService = await LocalDatabaseService.create('departments');
    bool isDatabaseEmpty = await databaseService.isDatabaseEmpty('my_departments');

    if (true) {
      final response = await http.get(Uri.parse(
          'https://wired-compass-389110.oa.r.appspot.com/rest/listWaypoint/listDepartments'));

      if (response.statusCode == 200) {
        final List<dynamic> departmentsJson = jsonDecode(response.body);
        departmentsList = departmentsJson.cast<Map<String, dynamic>>().toList();
        print(response.body);

        // Save departments to the local database
        for (var department in departmentsList) {
          await databaseService.insertContent('my_departments',department);
        }
      } else {
        throw Exception('Falha ao obter departamentos');
      }
    } else {
      // Fetch departments from the local database
      departmentsList = await databaseService.getAllContent('my_departments');
    }

    List<String> departments = departmentsList
        .map((department) =>
    department.containsKey('departmentName') ? department['departmentName'].toString() : '')
        .toList();

    setState(() {
      _departments = departments;
      if (_departments.isNotEmpty) {
        _selectedDepartment = _departments.first;
      }
    });
  }

  Future<Map<String,dynamic>> _searchForRoom(int departmentNumb, String roomName) async {
   print(roomName);
    final Map<String, dynamic> requestBody = {
      "departmentNumber": departmentNumb,
      "classroomName": roomName
    };

    final response = await http.post(
      Uri.parse(
        'https://wired-compass-389110.oa.r.appspot.com/rest/listWaypoint/getEspecificClassroom',
      ),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String,dynamic> classroomsJson = jsonDecode(response.body);
     return classroomsJson;
      } else {
      print(response.body);
        // Show notification that room was not found
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sala não existe'),
              content: Text('A sala não existe por favor verifique se submeteu a sala certa.'),
              actions: [
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
    return (new Map<String,dynamic>());
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encontrar sala'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                onChanged: (String? value) {
                  setState(() {
                    _selectedDepartment = value!;
                    _fetchClassrooms();
                  });
                },
                items: _departments
                    .map((department) =>
                    DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    ))
                    .toList(),
                hint: Text("Escolha o  Departmento"),
                style: TextStyle(
                  color: Colors.black,
                  // set the text color of the dropdown items
                  fontSize: 16.0, // set the font size of the dropdown items
                ),
                icon: Icon(Icons.arrow_drop_down),
                // set the dropdown icon
                iconSize: 24.0,
                // set the size of the dropdown icon
                elevation: 16,
                // set the elevation of the dropdown menu
                underline: Container(
                  height: 2,
                  color: Colors.grey,
                  // set the underline color of the dropdown button
                ),
              ),
            ),
            SizedBox(height: 20),
            CheckboxListTile(
              title: Text('Procurar por sala'),
              value: _isroom,
              onChanged: (bool? value){
                setState(() {
                  _isroom = value!;
                });
              },
            ),
            if(_isroom)
            DropdownButton<String>(
              value: _selectedRoom,
              icon: Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(
                color: Colors.deepPurple,
              ),
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRoom = newValue!;
                });
              },
              items: _rooms.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_isroom) {
                  // Search for the room
                  final departmentInfo = departmentsList.firstWhere(
                          (department) =>
                      department['departmentName'] == _selectedDepartment);

                   Map<String,dynamic> classroom= await _searchForRoom(departmentInfo['departmentNumber'],_selectedRoom);
                    if(classroom.isNotEmpty){
                    final classroomName=classroom['classroomName'];
                    final description=classroom['path'];
                    final lat = classroom['lat'] as double;
                    final lng = classroom['lng'] as double;
                    final latLng = LatLng(lat, lng);
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyGoogleMap.withParams(
                          name: classroomName,
                          description: description,
                          position: latLng,
                        ),
                        )
                    );
                    }
                } else {
                 // Update the locations in the map
                  final departmentInfo = departmentsList.firstWhere(
                          (department) =>
                      department['departmentName'] == _selectedDepartment);
                  final departmentName = departmentInfo['departmentName'] as String;
                  final description = departmentInfo['description'] as String;
                  final lat = departmentInfo['lat'] as double;
                  final lng = departmentInfo['lng'] as double;
                  final latLng = LatLng(lat, lng);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyGoogleMap.withParams(
                      name: departmentName,
                      description: description,
                      position: latLng,
                    ),
                    )
                  );

                   }
              },
              child: Text('Encontrar'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}
