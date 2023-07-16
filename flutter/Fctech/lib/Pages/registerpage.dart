import 'package:fctech/utils/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
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

import '../utils/SharedPrefsUtil.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobilePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _compAddressController = TextEditingController();
  final _localityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _nifController = TextEditingController();
  String? _privacy;
  final ImagePicker _picker = ImagePicker();
  File? _file;

  String pfp="none";

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _file = File(photo!.path);
    });

  }

  @override
  Future<void> _uploadFile() async {
    final scopes = [storage.StorageApi.devstorageFullControlScope];
    int length = 22;
    Future<Map<String, dynamic>> loadJsonCredentials() async {
      String jsonString = await rootBundle.loadString(
          'assets/wired-compass-389110-eff07c28fd11.json');
      return jsonDecode(jsonString);
    }

    var credentials = ServiceAccountCredentials.fromJson(
        await loadJsonCredentials());
    var client = await clientViaServiceAccount(credentials, scopes);

    var storageAPI = storage.StorageApi(client);

    if (_file == null) {
      print("No file selected.");
      return;
    }
    if (_file!.lengthSync() >= 35000000) {
      print("tamanho demasiado grande");
      return;
    }

    var bucketName = 'wired-compass-389110.appspot.com';
    var uuid = Uuid();
    var objectName = '${uuid.v4()}.${_file!
        .path
        .split('.')
        .last}'; // This will append the file extension to the UUID

    // Create a StorageObject to specify metadata about the file
    var object = storage.Object()
      ..bucket = bucketName
      ..name = objectName;

    // Create a Media object to specify the file's data and content type
    var media = storage.Media(_file!.openRead(), _file!.lengthSync());


    try {
      // Upload the file to the bucket
      await storageAPI.objects.insert(object, bucketName, uploadMedia: media);
      var acl = storage.ObjectAccessControl()
        ..entity = 'allUsers'
        ..role = 'READER';

      await storageAPI.objectAccessControls.insert(acl, bucketName, objectName);

      pfp=objectName;
      print('File uploaded successfully');
    }
   catch (e) {
  // Replace the loading dialog with an error dialog
  Navigator.pop(context);

    }
  }


      @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _mobilePhoneController.dispose();
    _addressController.dispose();
    _compAddressController.dispose();
    _localityController.dispose();
    _zipCodeController.dispose();
    _nifController.dispose();
    super.dispose();
  }

  void _register() async {

    if (_formKey.currentState!.validate()) {
      if (_privacy == null) {
        // Privacy setting not selected, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select your privacy setting')),
        );
        return;
      }
      if (_passwordController.text == _confirmPasswordController.text) {
        await _uploadFile();
        // Prepare the parameters
        Map<String, dynamic> params = {
            "username": _usernameController.text,
            "email": _emailController.text,
            "name": _nameController.text,
            "password": _passwordController.text,
            "nif": _nifController.text,
            "phone": _phoneController.text,
            "mobilePhone": _mobilePhoneController.text,
            "privacy": _privacy,
            "address": _addressController.text,
            "compAddress": _compAddressController.text,
            "locality": _localityController.text,
            "zipCode": _zipCodeController.text,
            "photo": pfp,
          };

        // Make the HTTP POST request
        final response = await http.post(
          Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(params),
        );

        // Check the response status and show an appropriate message
        if (response.statusCode == 200) {
          print("success");

          // Show snack bar with success message and an action to navigate to login page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Irá receber um email daqui a 5 minutos com a confirmação da criação da conta'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {
                  // When action button is pressed, navigate to login page
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ),
          );
        } else {
          print("failed register");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.body)),
          );
          print(response.body);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Passwords don't match")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(title: Text('Registar')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_file != null)

                      AspectRatio(
                    aspectRatio: 1, // You can modify this as per your requirement
                    child: Image.file(
                      _file!,
                      fit: BoxFit.scaleDown, // This will ensure your image covers the entire space
                    ),
                  ),
                 // ... your TextFormField widgets
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Nome de utilizador (*)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor submeta um nome';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email (*)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor submeta um email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nome (*)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor submeta um name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password (*)'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor submeta uma password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirmação da Password  (*)'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor submeta confirmação da  password ';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Telefone'),
                ),
                TextFormField(
                  controller: _mobilePhoneController,
                  decoration: InputDecoration(labelText: 'Telemovel'),
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Endereço'),
                ),
                TextFormField(
                  controller: _compAddressController,
                  decoration: InputDecoration(labelText: 'Endereço complementario'),
                ),
                TextFormField(
                  controller: _localityController,
                  decoration: InputDecoration(labelText: 'Localidade'),
                ),
                TextFormField(
                  controller: _zipCodeController,
                  decoration: InputDecoration(labelText: 'Codigo zip'),
                ),
                TextFormField(
                  controller: _nifController,
                  decoration: InputDecoration(labelText: 'NIF'),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Privacidade'),
                  value: _privacy,
                  onChanged: (newValue) {
                    setState(() {
                      _privacy = newValue;
                    });
                  },
                  items: [
                    DropdownMenuItem(child: Text('Publico'), value: 'public'),
                    DropdownMenuItem(child: Text('Privado'), value: 'private'),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Escolher imagem de perfil'),
                ),
                ElevatedButton(
                  onPressed: _register,
                  child: Text('Registrar'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}