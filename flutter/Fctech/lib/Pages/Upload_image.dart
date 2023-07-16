import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:exif/exif.dart';
import 'package:video_player/video_player.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:uuid/uuid.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import '../utils/SharedPrefsUtil.dart';


class ExifDataUploadPage extends StatefulWidget {
  @override
  _ExifDataUploadPageState createState() => _ExifDataUploadPageState();
}


class _ExifDataUploadPageState extends State<ExifDataUploadPage> {
  File? _file;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _controller;
  final TextEditingController _textControllerDesc = TextEditingController();
  final TextEditingController _textControllerTags = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _file = File(photo!.path);
    });

  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _file = File(video!.path);
      _controller = VideoPlayerController.file(_file!)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
          print(_controller!.value.duration);
          print(_controller!.value.size);
          _printVideoInformation();
        });
    });

  }

  Future<double> _getVideoDuration() async{
    final videoInfo = FlutterVideoInfo();
    var a = await videoInfo.getVideoInfo(_file!.path);
    return a!.duration!/1000.0;
  }
  Future<int?> _getVideoSize() async{
    final videoInfo = FlutterVideoInfo();
    var a = await videoInfo.getVideoInfo(_file!.path);
    return a!.filesize;
  }


  Future<double> _getVideoLat() async{
    final videoInfo = FlutterVideoInfo();
    var a = await videoInfo.getVideoInfo(_file!.path);
    return convertLatLng(a!.location)[0];
  }
  Future<double> _getVideoLong() async{
    final videoInfo = FlutterVideoInfo();
    var a = await videoInfo.getVideoInfo(_file!.path);
    return convertLatLng(a!.location)[1];
  }
  List<double> convertLatLng(String? latLngString) {
    // Extract latitude and longitude substrings
    String latLng = latLngString!.substring(0, latLngString.length - 1); // Remove the trailing "/"
    String latitude = latLng.substring(1, 9);
    String longitude = latLng.substring(10);

    // Remove "+" symbol from latitude
    latitude = latitude.substring(1);

    // Convert latitude and longitude to numerical values
    double lat = double.parse(latitude.substring(0,latitude.length-1));
    double lng = double.parse(longitude);

    // Adjust signs of latitude and longitude
    if (lat > 0) {
      latitude = '+$latitude';
    }
    if (lng > 0) {
      longitude = '+$longitude';
    }

    // Return latitude and longitude as a list
    return [lat, lng];
  }


  Future<void> _printVideoInformation()async{
    final videoInfo = FlutterVideoInfo();
    var a = await videoInfo.getVideoInfo(_file!.path);
    print('video location is->');
    print(a!.location);
    print('video length is ->');
    print(a.duration);
    print('video name is ->');
  }

  double toDecimal(List<String> coordinate, String direction) {
    print(coordinate.length);
    var degrees = double.parse(coordinate[0]);
    var minutes = double.parse(coordinate[1]);

    var dd = degrees + (minutes / 60) ;

    if (direction == "S" || direction == "W") {
      dd = dd * -1;
    } // negate if south or west

    return dd;
  }
  Future<List<double>> getImageLocation(File file) async {
    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);
    if (data.isEmpty) {
      print("No EXIF data found");
      return [0.0,0.0];
    }
    if (data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
      var latitudeData = data['GPS GPSLatitude']?.values.toList()[0];
      var latitudeList = [latitudeData.numerator.toString(), latitudeData.denominator.toString()];
      var latitude = toDecimal(latitudeList, data['GPS GPSLatitudeRef']!.printable);
      var longitudeData = data['GPS GPSLongitude']?.values.toList()[0];
      var longitudeList = [longitudeData.numerator.toString(), longitudeData.denominator.toString()];
      var longitude = toDecimal(longitudeList, data['GPS GPSLongitudeRef']!.printable);

     print(latitude);
     print(longitude);
     print("here we get the latitude as a string:->"+latitude.toString());
      return [latitude,longitude];
    } else {
      print("No location data available");
      return [0.0,0.0];
    }
  }
  Future<double> _getImageLat() async {
     List<double> list=await getImageLocation(_file!);
     return list[0];
  }

  Future<double> _getImageLong() async {
    List<double> list=await getImageLocation(_file!);
    return list[1];
  }
 @override
  Future<void> _uploadFile() async {
   showDialog(
     context: context,
     barrierDismissible: false,
     builder: (BuildContext context) {
       return Dialog(
         child: new Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             new CircularProgressIndicator(),
             new Text("A dar upload..."),
           ],
         ),
       );
     },
   );
    final scopes = [storage.StorageApi.devstorageFullControlScope];
    int length=22;
    Future<Map<String, dynamic>> loadJsonCredentials() async {
      String jsonString = await rootBundle.loadString('assets/wired-compass-389110-eff07c28fd11.json');
      return jsonDecode(jsonString);
    }

    var credentials = ServiceAccountCredentials.fromJson(await loadJsonCredentials());
    var client = await clientViaServiceAccount(credentials, scopes);

    var storageAPI = storage.StorageApi(client);

    if (_file == null) {
      print("Nenhum ficheiro  selecionado.");
      return;
    }
    if(_file!.lengthSync()>=35000000){
      print("tamanho demasiado grande");
      return;
    }

    var bucketName = 'wired-compass-389110.appspot.com';
    var uuid = Uuid();
    var objectName = '${uuid.v4()}.${_file!.path.split('.').last}'; // This will append the file extension to the UUID

    // Create a StorageObject to specify metadata about the file
    var object = storage.Object()
      ..bucket = bucketName
      ..name = objectName;

    // Create a Media object to specify the file's data and content type
    var media = storage.Media(_file!.openRead(), _file!.lengthSync());


   try {
     // Upload the file to the bucket
     await storageAPI.objects.insert(object,  bucketName, uploadMedia: media);
     var acl = storage.ObjectAccessControl()
       ..entity = 'allUsers'
       ..role = 'READER';

     await storageAPI.objectAccessControls.insert(acl, bucketName, objectName);

     print('File uploaded successfully');
     var authToken = await SharedPrefsUtil.checkAuthToken();
     var user= await SharedPrefsUtil.GetUsername();
     // Construct the conversation data
     bool photo=_file!.path.split('.').last=="png"||_file!.path.split('.').last=="jpg";
     double? lat;
     double? long;
     double? length;
     var fileLastModified = await _file!.lastModified();
     List<String> tagsList = _textControllerTags.text.split(',');

     if (photo) {
       lat = await _getImageLat();
       long = await _getImageLong();
     } else {
       lat = await _getVideoLat();
       long = await _getVideoLong();
       length = await _getVideoDuration();
     }


     Map<String, dynamic> fileData = {
       'uploaderUsername': user ,
       'size': _file!.lengthSync(),
       'lat': lat,
       'lng': long,
       'file_creation_date':fileLastModified.millisecondsSinceEpoch,
       'description': _textControllerDesc.text,
       'tags': tagsList,
       'isPhoto': photo,
       'length': photo ? 0 : length,
       'fileName': objectName,
     };

     // Construct the request body
     Map<String, dynamic> requestBody = {
       'token': authToken,
       'postData': fileData,
     };


     final response = await http.post(
       Uri.parse(
           'https://wired-compass-389110.oa.r.appspot.com/rest/posts/createPost'),
       body: jsonEncode(requestBody),
       headers: {'Content-Type': 'application/json'},
     );
     if (response.statusCode == 200) {
       print("success");
       // Replace the loading dialog with a success dialog
       Navigator.pop(context);
       _showSuccessDialog();
     } else {
       print(response.statusCode);
       print(response.body);
       // Replace the loading dialog with an error dialog
       Navigator.pop(context);
       _showErrorDialog('HTTP status code: ${response.statusCode}');
     }
   } catch (e) {
     // Replace the loading dialog with an error dialog
     Navigator.pop(context);
     _showErrorDialog(e.toString());
   }
 }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload feito com sucesso '),
          content: Text('O teu ficheiro fez upload com sucesso'),
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
          title: Text('Upload falhou '),
          content: Text('Um erro inesperado aconteceu ao dar upload: por favor'
              'tente mais tarde'),
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
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página de upload'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_file != null)
                _controller == null
                    ? AspectRatio(
                  aspectRatio: 1, // You can modify this as per your requirement
                  child: Image.file(
                    _file!,
                    fit: BoxFit.scaleDown, // This will ensure your image covers the entire space
                  ),
                )
                    : _controller!.value.isInitialized
                    ? Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: AspectRatio(
                    aspectRatio:1,
                    child: VideoPlayer(_controller!),
                  ),
                )
                    : Container(),
              ListTile(title: Row(children: <Widget>[
                    Expanded(child: ElevatedButton(
                            onPressed: _pickImage,
                           child: Text('Escolher imagem'),),),
                    Expanded(child:  ElevatedButton(
                          onPressed: _pickVideo,
                          child: Text('Escolher  vídeo'),
                            )),
                  ],
                ),
              ),
              TextField(
                maxLength: 500,
                controller: _textControllerDesc,
                decoration: InputDecoration(
                  labelText: 'Escreve a descrição do teu post',
                ),
              ),
              TextField(
                maxLength: 500,
                controller: _textControllerTags,
                decoration: InputDecoration(
                  labelText: 'Escreve as tags do teu post, separa cada tag por ,',
                ),
              ),
              ElevatedButton(
                onPressed: _uploadFile,
                child: Text('Upload'),
              ),

            ],
          ),
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}


class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  Location location = Location();
  File? _file;
  TextEditingController _textControllerDesc = TextEditingController();
  List<String> tagsList = []; // TODO:  Initialize this with your tags
  String dificulty='facil';
  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }
  Future<void> showDifficultyDialog(BuildContext context) async {
    String? difficulty = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Select Difficulty'),
        content: SizedBox(
          width: 200,
          child: ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Fácil'),
                onTap: () {
                  Navigator.of(context).pop('facil');
                },
              ),
              ListTile(
                title: const Text('Médio'),
                onTap: () {
                  Navigator.of(context).pop('normal');
                },
              ),
              ListTile(
                title: const Text('Difícil'),
                onTap: () {
                  Navigator.of(context).pop('dificil');
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (difficulty != null) {
      // Save difficulty or do something with it, then take picture
      // For example, you could save it to state in your page:
      // setState(() {
      //   _difficulty = difficulty;
      // });

      // Now, take picture
      takePicture(difficulty);
    }
  }

  Future<void> takePicture(String difficulty) async {
    if (!controller!.value.isInitialized) {
      print("Controller is not initialized");
      return null;
    }

    final image = await controller!.takePicture();

    _file = File(image.path);
    dificulty=difficulty;
    _uploadFile();

  }

  Future<void> _uploadFile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              new CircularProgressIndicator(),
              new Text("A dar upload..."),
            ],
          ),
        );
      },
    );
    final scopes = [storage.StorageApi.devstorageFullControlScope];
    int length=22;
    Future<Map<String, dynamic>> loadJsonCredentials() async {
      String jsonString = await rootBundle.loadString('assets/wired-compass-389110-eff07c28fd11.json');
      return jsonDecode(jsonString);
    }

    var credentials = ServiceAccountCredentials.fromJson(await loadJsonCredentials());
    var client = await clientViaServiceAccount(credentials, scopes);

    var storageAPI = storage.StorageApi(client);

    if (_file == null) {
      print("Nenhum ficheiro  selecionado.");
      return;
    }
    if(_file!.lengthSync()>=35000000){
      print("tamanho demasiado grande");
      return;
    }

    var bucketName = 'wired-compass-389110.appspot.com';
    var uuid = Uuid();
    var objectName = '${uuid.v4()}.${_file!.path.split('.').last}'; // This will append the file extension to the UUID

    // Create a StorageObject to specify metadata about the file
    var object = storage.Object()
      ..bucket = bucketName
      ..name = objectName;

    // Create a Media object to specify the file's data and content type
    var media = storage.Media(_file!.openRead(), _file!.lengthSync());


    try {
      // Upload the file to the bucket
      await storageAPI.objects.insert(object,  bucketName, uploadMedia: media);
      var acl = storage.ObjectAccessControl()
        ..entity = 'allUsers'
        ..role = 'READER';

      await storageAPI.objectAccessControls.insert(acl, bucketName, objectName);

      print('File uploaded successfully');
      var authToken = await SharedPrefsUtil.checkAuthToken();
      var user= await SharedPrefsUtil.GetUsername();
      // Construct the conversation data
      bool photo=_file!.path.split('.').last=="png"||_file!.path.split('.').last=="jpg";
      double? lat;
      LocationData long= await location.getLocation();
      double? length;
      var fileLastModified = await _file!.lastModified();



      Map<String, dynamic> geoGuesserData = {
        'fileName': objectName,
        'lat':long.latitude,
        'lng':long.longitude,
        'difficulty':dificulty,
      };

      // Construct the request body
      Map<String, dynamic> requestBody = {
        'token': authToken,
        'geoGuesserData': geoGuesserData,
      };


      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/geoguesser/createLocation'),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print("success");
        // Replace the loading dialog with a success dialog
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        print(response.statusCode);
        print(response.body);
        // Replace the loading dialog with an error dialog
        Navigator.pop(context);
        _showErrorDialog('HTTP status code: ${response.statusCode}');
      }
    } catch (e) {
      // Replace the loading dialog with an error dialog
      Navigator.pop(context);
      _showErrorDialog(e.toString());
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Tirar foto')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () =>  showDifficultyDialog(context),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload feito com sucesso '),
          content: Text('O teu ficheiro fez upload com sucesso'),
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
          title: Text('Upload falhou '),
          content: Text('Um erro inesperado aconteceu ao dar upload'),
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