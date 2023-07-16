import 'dart:convert';

import 'package:fctech/utils/SharedPrefsUtil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AnomalyPage extends StatefulWidget {
  @override
  _AnomalyPageState createState() => _AnomalyPageState();
}

class _AnomalyPageState extends State<AnomalyPage> {
  TextEditingController _descriptionController = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _selectedType;
  List<String> _anomalyTypes = ["Normal", "Importante", "Urgente"];

  Future<void> createAnomalyReport() async {
    // Validate input
    if (_descriptionController.text.trim().isEmpty ||
        _latitude == null ||
        _longitude == null ||
        _selectedType == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Por favor garante que preencheu todo o formulário '),
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

    // Prepare request data
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();

    final anomalyData = {
      'description': _descriptionController.text,
      'lat': _latitude,
      'lng': _longitude,
      'type': _selectedType,
    };

    final request = {
      'token': authToken,
      'anomaly': anomalyData,
    };

    final url = Uri.parse(
        'https://wired-compass-389110.oa.r.appspot.com/rest/reportAnomaly/createAnomaly');
    final headers = {'Content-Type': 'application/json;charset=utf-8'};
    final body = jsonEncode(request);

    try {
      final response = await http.post(url, body: body, headers: headers);

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Sucesso'),
            content: Text('Bilhete de Anomalia criado com sucesso.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Clear input fields
                  _descriptionController.clear();
                  _latitude = null;
                  _longitude = null;
                  _selectedType = null;
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text(response.body),
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
          content: Text('Falha ao criar bilhete de anomalia, por favor tente de novo.'),
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


  Future<void> fetchCurrentCoordinates() async {
    LatLng? selectedLatLng;

    // Get current location if permission is granted
    bool isPermissionGranted = await Permission.location.isGranted;
    LatLng initialLatLng;

    if (isPermissionGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        initialLatLng = LatLng(position.latitude, position.longitude);
      } catch (e) {
        // If error occurred, use the initial location
        initialLatLng = LatLng(38.66100540431834, -9.204493048694877);
      }
    } else {
      initialLatLng = LatLng(38.66100540431834, -9.204493048694877);
    }

    // Open a new page or dialog containing the map
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
              Navigator.of(context).pop(selectedLatLng);
            },
            child: Text('OK'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Bilhete de Anomalia'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            TextField(
              maxLength: 500,
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchCurrentCoordinates,
              child: Text('Obter coordenadas correntes'),
            ),
            SizedBox(height: 10),
            Text(
              'Latitude: ${_latitude ?? ''}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 10),
            Text(
              'Longitude: ${_longitude ?? ''}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue;
                });
              },
              items: _anomalyTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Tipo de anomalia'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: createAnomalyReport,
              child: Text('Criar bilhete de Anomalia'),
            ),
          ],
        ),
      ),
    );
  }
}
class ListAnomalyPage extends StatefulWidget {
  @override
  _ListAnomalyPageState createState() => _ListAnomalyPageState();
}
class MapDialog extends StatefulWidget {
  final LatLng initialLatLng;
  final Function(LatLng?) onMapTap;

  const MapDialog({
    required this.initialLatLng,
    required this.onMapTap,
    Key? key,
  }) : super(key: key);

  @override
  _MapDialogState createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: MarkerId("selected-location"),
        position: widget.initialLatLng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // Adjust the height according to your needs
      child: GoogleMap(
        key: UniqueKey(), // Use a UniqueKey to force rebuilding the widget when markers change
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: widget.initialLatLng,
          zoom: 18.0,
        ),
        myLocationEnabled: true,
        onTap: (LatLng latLng) {
          print(latLng);
          setState(() {
            _markers.clear();
            _markers.add(
              Marker(
                markerId: MarkerId("selected-location"),
                position: latLng,
              ),
            );
          });
          widget.onMapTap(latLng);
        },
        markers: _markers,
      ),
    );
  }
}

Set<Marker> _allMarkers = {};


class _ListAnomalyPageState extends State<ListAnomalyPage> {
  List<Anomaly> _anomalies = [];
  List<String> _anomalyTypes = ["Pendente", "Resolvido",'Todas'];
  String _selectedState = 'Pendente';
  Future<bool> isSu() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? authTokenJson = prefs.getString('authToken');
  if (authTokenJson == null) {
  print('Por favor fazer login de novo');
  return false;
  }
  return jsonDecode(authTokenJson)['role']=='SU';
}

  void _navigateToMapPage(Set<Marker> markers) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPage(markers: markers),
      ),
    );
  }

  void _addAllMarkers() {
    Set<Marker> allMarkers = {};

    for (final anomaly in _anomalies) {
      final marker = Marker(
        markerId: MarkerId(anomaly.anomalyID),
        position: LatLng(anomaly.lat, anomaly.lng),
        infoWindow: InfoWindow(
          title: anomaly.userSubmitted,
          snippet: anomaly.description,
        ),
      );
      allMarkers.add(marker);
    }

    _navigateToMapPage(allMarkers);
  }

  void _showMapDialog(LatLng initialLatLng) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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

  Future<void> fetchAllAnomalies() async {
    try {
      final response = await http.get(Uri.parse(
          'https://wired-compass-389110.oa.r.appspot.com/rest/listAnomalies/listAllAnomalies'));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as List;
        _anomalies = jsonResponse
            .map((item) => Anomaly.fromJson(item))
            .toList(); // Convert to List<Anomaly>
        setState(() {});
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Erro'),
            content: Text(
                'Falha ao obter anomalias: por favor tente mais tarde'),
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
          content: Text('Falha ao obter anomailias, por favor tente mais tarde.'),
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


  Future<void> fetchAnomaliesByState(String state) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
      if(_selectedState=='Todas'){
        fetchAllAnomalies();
        return;
      }
      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/listAnomalies/listAnomaliesByState'),
        body: jsonEncode({
          'token': authToken,
          'status': _selectedState,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as List;
        _anomalies = jsonResponse
            .map((item) => Anomaly.fromJson(item))
            .toList(); // Convert to List<Anomaly>
        setState(() {});
        print(_anomalies);
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Error'),
            content: Text(
                'Falha ao obter anomalias: por favor tente mais tarde'),
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
          content: Text('Falha ao obter anomalias. Por favor tente de novo.'),
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


  void _showInMap(Anomaly anomaly) {
    _showMapDialog(LatLng(anomaly.lat, anomaly.lng));
  }

  Future<void> _showOptionsDialog(Anomaly anomaly) async {
    // Getting the information before showing the dialog
    final bool isUserSu = await isSu();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Opções de anomalia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isUserSu)
                ListTile(
                  title: Text('Apagar Anomalia'),
                  onTap: () {
                    Navigator.of(context).pop(); // This will close the dialog
                    _deleteAnomaly(anomaly);
                  },
                ),
              if (isUserSu)
                ListTile(
                  title: Text('Mudar o Estado da Anomalia'),
                  onTap: () {
                    Navigator.of(context).pop(); // This will close the dialog
                    _changeAnomalyState(anomaly);
                  },
                ),
              ListTile(
                title: Text('Mostrar no mapa'),
                onTap: () {
                  Navigator.of(context).pop(); // This will close the dialog
                  _showInMap(anomaly);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listar Anomalias'),
      ),
      body: ListView.builder(
        itemCount: _anomalies.length,
        itemBuilder: (context, index) {
          final anomaly = _anomalies[index];
          return ListTile(
            title: Text(anomaly.userSubmitted),
            subtitle: Text(anomaly.description),
            trailing: Text(anomaly.state),
            onTap: () {
              _showOptionsDialog(anomaly);
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton(
                onPressed: _addAllMarkers,
                child: Text('Adicionar anomalias ao mapa'),
              ),
              DropdownButton<String>(
                value: _selectedState,
                onChanged: (String? state) {
                  if (state != null && state.isNotEmpty) {
                    setState(() {
                      _selectedState = state;
                    });
                    fetchAnomaliesByState(state);
                  }
                },
                items: _anomalyTypes.map((String state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                hint: Text('Selecionar o estado'),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
  Future<void> _deleteAnomaly(Anomaly anomaly) async {

    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final response = await http.delete(
      Uri.parse(
          'https://wired-compass-389110.oa.r.appspot.com/rest/reportAnomaly/deleteAnomaly'),
      body: jsonEncode({
        'token': authToken,
        'anomalyID':anomaly.anomalyID,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Success'),
          content: Text('Anomalia apagada com sucesso.'),
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
    else{
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text(response.body),
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

  Future<void> _changeAnomalyState(Anomaly anomaly) async {
     String State=anomaly.state;
    if(State!="Resolvido"){
      State="Resolvido";}
    else{
      State="Pendente";}

     Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final response = await http.post(
      Uri.parse(
          'https://wired-compass-389110.oa.r.appspot.com/rest/reportAnomaly/changeAnomalyState'),
      body: jsonEncode({
        'token': authToken,
        'anomalyID':anomaly.anomalyID,
        'newState':State,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Sucesso'),
          content: Text('Mudada a anomalia.'),
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
    else{
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text(response.body),
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



class Anomaly {
  final String anomalyID;
  final String userSubmitted;
  final String description;
  final double lat;
  final double lng;
  final String type;
  final String state;

  Anomaly({
    required this.anomalyID,
    required this.userSubmitted,
    required this.description,
    required this.lat,
    required this.lng,
    required this.type,
    required this.state,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      anomalyID: json['anomalyID'],
      userSubmitted: json['userSubmitted'],
      description: json['description'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      type: json['type'],
      state: json['state'],
    );
  }
}

class MapPage extends StatelessWidget {
  final Set<Marker> markers;

  const MapPage({required this.markers, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de anomalias'),
      ),
      body: GoogleMap(
        // Use markers received as parameter
        markers: markers,
        // Customize other properties as needed
        initialCameraPosition: const CameraPosition(
          target: LatLng(38.661100623195296, -9.204582006024465),
          zoom: 15,
        ),
      ),
    );
  }
}
