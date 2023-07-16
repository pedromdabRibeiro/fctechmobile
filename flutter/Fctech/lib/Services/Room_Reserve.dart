import 'dart:convert';
import 'package:fctech/Services/GoogleMap.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fctech/utils/SharedPrefsUtil.dart';
import 'package:fctech/utils/SuperUserMode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:http/http.dart' as http;
import 'package:fctech/Services/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Pages/Anomaly.dart';
import '../Pages/Mainpage.dart';

class ReservasPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservas'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingPage()),
                );
              },
              child: Container(
                color: Colors.lightBlue[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.list_alt, size: 48.0,),
                      Text('Listar Reservas')
                    ],
                  ),
                ),
              ),
            ),
          ),
          Divider(
              color: Colors.grey),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyDateTimePicker()),
                );
              },
              child: Container(
                color: Colors.lightBlue[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.school, size: 48.0,),
                      Text('Reservar uma Sala')
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class MyDateTimePicker extends StatefulWidget {
  @override
  _MyDateTimePickerState createState() => _MyDateTimePickerState();
}

class _MyDateTimePickerState extends State<MyDateTimePicker> {
  DateTime selectedStartDateTime = DateTime.now();
  DateTime selectedEndDateTime = DateTime.now();
 List<int> _numberOfHours=[1,2,3,4,5,6,7,8,9,10,11,12];
 int _selectedHour=1;
  List<String> _departments = [];
  String _selectedDepartment = 'Escolha o Departmento';
  List<Map<String, dynamic>> departmentsList = [];
  List<Map<String, dynamic>> classroomsList = [];
  List<String> _rooms = [];
  String _selectedRoom = 'Escolha a Sala';
  late var token ; // replace with your actual token

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }
  Future<Map<String, dynamic>> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    print(authTokenJson);
    return jsonDecode(authTokenJson!);

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
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedStartDateTime,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          selectedStartDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }


  Future<void> _selectEndDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedEndDateTime,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedEndDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          selectedEndDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _bookClassroom() async {
    print(_selectedRoom);

    // Create a new SnackBar with a CircularProgressIndicator
    final snackBarLoading = SnackBar(
        content: Row(
            children: [
              CircularProgressIndicator(),
              Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text('A reservar a sala...')
              ),
            ]
        )
    );

    // Display the SnackBar with CircularProgressIndicator
    ScaffoldMessenger.of(context).showSnackBar(snackBarLoading);

    var authToken = await SharedPrefsUtil.checkAuthToken();
    final departmentInfo = departmentsList.firstWhere(
            (department) => department['departmentName'] == _selectedDepartment);

    Map<String, dynamic> requestBody = {
      'token': authToken,
      'startingHour': selectedStartDateTime.millisecondsSinceEpoch,
      'numberOfHours': _selectedHour,
      'classroomName': _selectedRoom,
      'departmentNumber': departmentInfo['departmentNumber'],
      'dayToBook':selectedStartDateTime.year.toString()+"/"+selectedStartDateTime.month.toString()+"/"+
                  selectedStartDateTime.day.toString(),
    };

    final response = await http.post(Uri.parse(
        'https://wired-compass-389110.oa.r.appspot.com/rest/manageClassroom/bookClassroom'),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    // Remove the previous SnackBar with CircularProgressIndicator
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Check the status code of the response
    if (response.statusCode == 200) {
      print("Classroom booked successfully!");
      // Create a new SnackBar with a success message and an OK button
      final snackBarSuccess = SnackBar(
        content: Text('Reservado com sucesso'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            // Code to be executed when the user taps the "OK" button
          },
        ),
      );

      // Display the SnackBar with the success message and the OK button
      ScaffoldMessenger.of(context).showSnackBar(snackBarSuccess);
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Falha ao reservar a sala');
    }
  }
  String getProperTime(DateTime time){
    return time.day.toString()+'/'+time.month.toString()+'/'+time.year.toString()+' '
        +time.hour.toString()+':'+ (time.minute < 10 ? '0'+time.minute.toString() : time.minute.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Reservar uma Sala'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Selecione uma sala',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedDepartment,
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
                  _selectedDepartment = newValue!;
                  _fetchClassrooms();
                });
              },
              items: _departments.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
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

            ElevatedButton(
              onPressed: () => _showMapDialog(),
              child: Text(
                'Ver localização da sala',
              ),
            ),
            Text(
              'Horas de inicio:\n${getProperTime(selectedStartDateTime)}',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDateTime(context),
              child: Text(
                'Selecionar horas de inicio',
              ),
            ),
            Text(
              'Número de horas',
            ),
            DropdownButton<int>(
              value: _selectedHour,
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
              onChanged: (int? newValue) {
                setState(() {
                  _selectedHour = newValue!;
                });
              },
              items: _numberOfHours.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
      SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => _bookClassroom(),
        child: Text(
          'Submeter Reserva',
        ),
      ),

          ],
        ),
      ),
    );
  }

Future<void>GetLocation(Map<String,dynamic> classroom) async{
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
  Future<void> _showMapDialog()async {
    final departmentInfo = departmentsList.firstWhere(
            (department) => department['departmentName'] == _selectedDepartment);

    final Map<String, dynamic> requestBody = {
      "departmentNumber": departmentInfo['departmentNumber'] ,
      "classroomName": _selectedRoom
    };
  print(requestBody);
    final response = await http.post(
      Uri.parse(
        'https://wired-compass-389110.oa.r.appspot.com/rest/listWaypoint/getEspecificClassroom',
      ),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> classroomsJson = await jsonDecode(response.body);

      print(classroomsJson);
      LatLng initialLatLng = LatLng(
          classroomsJson['lat'] , classroomsJson['lng'] );
      showDialog(
        context: context,
        builder: (context) =>
            Dialog(
              child: MapDialog(
                initialLatLng: initialLatLng,
                onMapTap: (LatLng? latLng) {
                  // Handle the map marker tap if needed
                  Navigator.pop(context);
                },
              ),
            ),
      );
    }
    else{
      print(response.body);
    }
  }
}

class BookingPage extends StatefulWidget {
  BookingPage({Key? key}) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  Future<List>? bookings;
  List<String> _departments = [];
  String _selectedDepartment = 'Escolha o Departmento';
  List<Map<String, dynamic>> departmentsList = [];
  List<Map<String, dynamic>> classroomsList = [];
  List<String> _rooms = [];
  String _selectedRoom = 'Escolha a Sala';
  late var token ;
  DateTime selectedStartDateTime = DateTime.now();
  TextEditingController classroom = TextEditingController();

  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<List> fetchBookings(String path, dynamic data) async {

    print( data);
    final response = await http.post(
      Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/ListBookedClassrooms/$path'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => model).toList();
    } else {print(response.statusCode);
      print(response.body);
      throw Exception('Failed to load bookings');
    }
  }
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedStartDateTime,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedStartDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          selectedStartDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
        });
      }
    }
  }



  Future<void> Gettickets() async{
    var trueauthToken= await SharedPrefsUtil.checkAuthToken();
    setState(() {
      bookings = fetchBookings("listOwnBooking",trueauthToken);
     });
  }

  Future<void> GetDateTickets() async{
    var trueauthToken= await SharedPrefsUtil.checkAuthToken();
    setState(() {
      bookings = fetchBookings("listOwnBookingWithDay", {"token": trueauthToken, "day": selectedStartDateTime.year.toString()+"/"+selectedStartDateTime.month.toString()+"/"+
          selectedStartDateTime.day.toString(),});
    });
  }
  Future<void> GetDateClassTickets() async{
    var trueauthToken= await SharedPrefsUtil.checkAuthToken();
    setState(() {
      bookings = fetchBookings("listBookingWithDay", {"token": trueauthToken, "day": selectedStartDateTime.year.toString()+"/"+selectedStartDateTime.month.toString()+"/"+
          selectedStartDateTime.day.toString(),"classroom":_selectedRoom});
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Lista de reservas'),
      ),
      body: SingleChildScrollView( // Add this line
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: Text('Listar todas as propias reservas'),
                onPressed: () {
                  Gettickets();
                },
              ),
              ElevatedButton(
                child: Text('Listar propias reservas dado um dia'),
                onPressed: () {
                  _selectDateTime(context);
                  GetDateTickets();
                },
              ),
              DropdownButton<String>(
                value: _selectedDepartment,
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
                    _selectedDepartment = newValue!;
                    _fetchClassrooms();
                  });
                },
                items: _departments.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
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
              ElevatedButton(
                child: Text('Listar reservas dado uma sala e um dia'),
                onPressed: () {
                  _selectDateTime(context);
                  GetDateClassTickets();
                },
              ),
              FutureBuilder<List>(
                future: bookings,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      shrinkWrap: true, // Add this line
                      physics: NeverScrollableScrollPhysics(), // And this one
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var booking = snapshot.data![index];
                        return ListTile(
                                title: Text(booking["classroomName"]),
                          trailing: Icon(Icons.expand_more),
                                subtitle: Text(DateTime.fromMillisecondsSinceEpoch(booking["startingHour"]).toIso8601String().split(":00.000")[0].split('T').join()
                                    +'\n'+DateTime.fromMillisecondsSinceEpoch(booking["endingHour"]).toIso8601String().split(":00.000")[0].split('T').join(),
                                ),
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Detalhes de Reserva'),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                Text('Número de departamento: ${booking["departmentNumber"]}'),
                                                Text('Sala: ${booking["classroomName"]}'),
                                                Text('Hora de inicio: ${DateTime.fromMillisecondsSinceEpoch(booking["startingHour"]).toIso8601String().split(":00.000")[0].split('T').join()}'),
                                                Text('Hora de termino: ${DateTime.fromMillisecondsSinceEpoch(booking["endingHour"]).toIso8601String().split(":00.000")[0].split('T').join()}'),
                                                Text('Dia: ${booking["dayToBook"]}'),
                                                Text('Quem reservou: ${booking["booker"]}'),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            ElevatedButton(
                                              child: Text('Fechar'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            ElevatedButton(
                                              child: Text('Apagar Reserva'),
                                              onPressed: () {
                                                ApagarReserva(context,booking); // Implement your "Apagar Reserva" functionality here
                                                //Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                  );
                                },
                              );
                            },


                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  return CircularProgressIndicator();
                },
              )
            ],
          ),
        ),
      ), // End of new line
    );
  }

  void ApagarReserva(BuildContext context, booking) async{
    var trueauthToken= await SharedPrefsUtil.checkAuthToken();

    final response = await http.post(
      Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/manageClassroom/cancelBooking'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({ 'token': trueauthToken,
            'bookingID':booking['bookingID'],
        })
    );
    if (response.statusCode == 200) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
      title: Text('Sucesso'),
      content: Text('Apagou a reserva'),
      actions: [
        TextButton(
          onPressed: () {
            Gettickets();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            },
          child: Text('OK'),
        ),
      ],
    ),
    );
    } else {print(response.body);
      print(response.statusCode);
      showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Erro'),
        content: Text('Falha a apagar a reserva'),
        actions: [
          TextButton(
            onPressed: () {
              Gettickets();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
    Navigator.of(context).pop();
    }

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
}
