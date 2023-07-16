import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyGoogleMap extends StatefulWidget {
  final String? name;
  final String? description;
  final LatLng? position;

  // Default constructor
  MyGoogleMap({
    Key? key,
  }) : this.name = null, this.description = null, this.position = null, super(key: key);

  // Constructor with parameters
  MyGoogleMap.withParams({
    Key? key,
    required this.name,
    required this.description,
    required this.position,
  }) : super(key: key);

  @override
  _MyGoogleMapState createState() => _MyGoogleMapState();
}
Set<Marker> _markers = {};
GoogleMapController? _controller;

class _MyGoogleMapState extends State<MyGoogleMap> {
  List<Location> _locations = [];

  // Define an initial camera position.
  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(38.6612, -9.2054),
    zoom: 17.00,
  );
  Set<Polyline> _polylines = {};
  Future<void> _openMapsApp(double latitude, double longitude) async {
    String googleMapsUrl = 'https://maps.google.com/?daddr=$latitude,$longitude';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }
  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isDenied) {
      // You can show a message to the user to enable location permissions
    }

  }
  Future<void> _centerOnUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17.00,
        ),
      ),
    );
  }

void updateLocations(String title,String description,LatLng lat){
_locations=<Location>[
  Location(
    position: lat,
    title: title,
    description: description
  ),
];
}
  @override
  @override
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.satellite, // hide Google's markers
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true, // Show user's current location on the map
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
              markers: _markers, // Display the markers
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: _centerOnUserLocation,
              tooltip: 'Center on user location',
              child: const Icon(Icons.my_location),
            ),
          ),

        ],
      ),
    );

  }


  @override
  void initState() {
    super.initState();
    _markers.clear();
    if (widget.name != null && widget.description != null && widget.position != null) {
      print("this is the classroom's name"+widget.name!);
      print("this is the classroom's path"+widget.description!);
      print("this is the classroom's position"+widget.position.toString());
      _locations = [
        Location(
          position: widget.position!,
          title: widget.name!,
          description: widget.description!,
        ),
      ];
    } else {

      _locations = [
        Location(
          position: LatLng(38.66077084379047, -9.20576489080115),
          title: 'Edificio VII Departmento de Matematica',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.6602021854601, -9.20405534195831),
          title: 'UNINOVA',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66269953627849, -9.205399879919552),
          title: 'Biblioteca ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.661153672745165, -9.203475401220794),
          title: 'EDII Departamento de Informatica ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66261201673472, -9.207738941306138),
          title: 'Departamento de quimica ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66228704979071, -9.207937224153513),
          title: 'Departamento de ciencias e engenharia do ambiente ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66216155624676, -9.207888417774463),
          title: 'Edificio departamental',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.662243616435696, -9.207797731163604),
          title: 'Departamento de ciencias da vida ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.661272640910546, -9.205734484917112),
          title: 'Departamento de fisica ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66051688988329, -9.206528443251047),
          title: 'Ed. VIII - Departamento de Engenharia Mecanica e Industrial, ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66017276936702, -9.207066237585298),
          title: 'Ed. IX - Departamento de Engenharia Civil ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66287037990078, -9.207197108838429),
          title: 'Ed. IV ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66319995662946, -9.207248492875351),
          title: 'Ed. III  ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.663320323404434, -9.206899815481949),
          title: 'Grande Auditorio ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.6604200009746, -9.20483344308885),
          title: 'Ed. X - Departamento de Engenharia Eletrotecnica ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        Location(
          position: LatLng(38.66052829242095, -9.203035401881296),
          title: 'Ed. VI ',
          description: 'Toca para ver percurso ate ao edificio',
        ),
        // Add more locations as needed
      ];
      // The previous _locations initialization code goes here...
    }


    bool _showInfoWindow = false;
    Location _selectedLocation;

    _requestLocationPermission().then((_) {
      _locations.forEach((location) {
        _markers.add(
          Marker(
            markerId: MarkerId(location.position.toString()),
            position: location.position,
            infoWindow: InfoWindow(
                title: location.title,
                snippet: location.description,
                onTap: () {_selectedLocation = location;
                _showInfoWindow = true;
                _showDialogBox(context, location.description);
                /*  _openMapsApp(
                    location.position.latitude,
                    location.position.longitude,
                  );*/
                }
            ),
          ),
        );
        print(_markers);
      });
      setState(() {}); // Trigger a rebuild to update the markers on the map
    });
  }
}
void _showDialogBox(BuildContext context, String description) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Location Info"),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Close"),
          ),
        ],
      );
    },
  );
}

class Location {
  final LatLng position;
  final String title;
  final String description;

  Location({required this.position, required this.title, required this.description});
}

