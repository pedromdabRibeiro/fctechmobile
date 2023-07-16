import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class SharedPrefsUtil {
  static Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson= prefs.getString('authToken');
    Map<String, dynamic> authToken = jsonDecode(authTokenJson!);
    if(authToken['creationDate']+1000 * 60 * 60 * 12<DateTime.now().millisecondsSinceEpoch&&
        DateTime.now().millisecondsSinceEpoch<authToken['expirationDate']) {
     await  _updateToken();
      authTokenJson = await getAuthToken();
    }
    return authTokenJson;

  }

  static Future<Map<String, dynamic>?> checkAuthToken() async {
    String? authTokenJson = await getAuthToken();
    if (authTokenJson == null) {
      print('Token inválido, por favor fazer login de novo');
      return null;
    }
    Map<String, dynamic> authToken = jsonDecode(authTokenJson!);
    if(authToken['creationDate']+1000 * 60 * 60 * 12<DateTime.now().millisecondsSinceEpoch&&
        DateTime.now().millisecondsSinceEpoch<authToken['expirationDate']) {
     await  _updateToken();
       authTokenJson = await getAuthToken();
    }

    return jsonDecode(authTokenJson!);
  }

  static Future<String>GetUsername() async{

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson= prefs.getString('authToken');
    Map<String, dynamic> authToken = jsonDecode(authTokenJson!);
    return authToken['username'];
  }
  static Future<void> _updateToken() async{

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson= prefs.getString('authToken');
    Map<String, dynamic> authToken = jsonDecode(authTokenJson!);
    final url = 'http://wired-compass-389110.oa.r.appspot.com/rest/utils/getNewToken';
    final headers = <String, String>{'Content-Type': 'application/json'};

    final body = jsonEncode(await authToken); // await here

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      final authToken1 = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String authTokenJson = jsonEncode(authToken1);
      await prefs.setString('authToken', authTokenJson);

    }
    return;
  }

}



