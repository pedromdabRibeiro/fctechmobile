import 'package:fctech/Services/Rewards.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fctech/services/local_database_service.dart';
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

import '../utils/SharedPrefsUtil.dart';
class News {
  final String imageUrl;
  final String title;
  final String summary;
  final String date;
  final String articleUrl;
  News(this.imageUrl, this.title, this.summary, this.date, this.articleUrl);
  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'title': title,
    'summary': summary,
    'date': date,
    'articleUrl': articleUrl,
  };

  // Create a News object from a Map<String, dynamic>
  factory News.fromJson(Map<String, dynamic> json) => News(
    json['imageUrl'] as String,
    json['title'] as String,
    json['summary'] as String,
    json['date'] as String,
    json['articleUrl'] as String,
  );
}

Future<List<News>> fetchNews(bool hotrefresh ) async {
  final databaseService = await LocalDatabaseService.create('News');
  var news = <News>[];

  if(hotrefresh) {
    try {
      final response = await http.get(Uri.parse('https://www.fct.unl.pt/noticias'));
      if (response.statusCode == 200) {
        var document = parse(response.body);
        var newsElements = document.querySelectorAll('.views-row');

        for (var newsElement in newsElements) {
          final imageUrl = newsElement.querySelector('.noticia-imagem a img')?.attributes['src'];
          final title = newsElement.querySelector('.noticia-corpo .views-field-title a')?.text;
          final summary = newsElement.querySelector('.noticia-corpo .views-field-field-resumo-value p')?.text;
          final date = newsElement.querySelector('.noticia-corpo .views-field-created')?.text;

          var articleElement = newsElement.querySelector('.noticia-corpo .views-field-title a');
          if (articleElement == null) {
            continue;
          }

          final articleUrl = 'https://www.fct.unl.pt/' +(articleElement.outerHtml).split('<a href="/')[1].split('">')[0];

          if (imageUrl != null && title != null && summary != null && date != null ) {
            news.add(News(imageUrl, title, summary, date, articleUrl));
            await databaseService.insertContent('my_news', news.last.toJson());
          }
        }
      } else {
        print("Failed to load news from the internet");
      }
    } catch (e) {
      print("Caught exception: $e");
    }
  }

  List<Map<String, dynamic>> newsMapList = await databaseService.getAllContent('my_news');
  news = newsMapList.map((newsMap) => News.fromJson(newsMap)).toList();

  return news;
}

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<News>> newsFuture;

  @override
  void initState() {
    super.initState();
    newsFuture = fetchNews(true);
  }

  Future<void> refreshNews() async {
    setState(() {
      newsFuture = fetchNews(true);
    });
  }

  Future<void> _launchWebsite(String url) async {
    if (!await launchUrl(
        Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notícias'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshNews,
        child: FutureBuilder<List<News>>(
          future: newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return ListView(
                children: [
                  Center(
                    child: Text('Por favor para usar esta ferramenta ligue a internet'),
                  ),
                ],
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final news = snapshot.data![index];
                  return ListTile(
                    leading: Image.network(news.imageUrl),
                    title: Text(news.title),
                    subtitle: Text(news.summary),
                    onTap: () => _launchWebsite(news.articleUrl),
                  );
                },
              );
            }
          },
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MenuButton({Key? key, required this.icon, required this.title, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
class MainPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    Future<bool> isSuperUser = isSuper();
    dailyLogin( context);
    return FutureBuilder<bool>(
      future: isSuperUser,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // show loading spinner while waiting for isSuperUser
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
            backgroundColor: Colors.lightBlue[100],
            appBar: AppBar(
              title: Text('FCtech'),
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  children: [
                MenuButton(icon: Icons.person_pin_circle,
                      title: 'Ver o meu perfil',
                      onTap: () => Navigator.pushNamed(context, '/user_profile')),
                    MenuButton(icon: Icons.person_2_rounded,
                        title: 'Ver o  perfil de outra pessoa',
                        onTap: () =>  Navigator.pushNamed(context, '/Get_profile')),
                    MenuButton(icon: Icons.calendar_month,
                        title: 'Calendário',
                        onTap: () => Navigator.pushNamed(context, '/calendar')),
                    MenuButton(icon: Icons.newspaper,
                        title: 'Notícias',
                        onTap: () => Navigator.pushNamed(context, '/Noticias')),
                MenuButton(icon: Icons.quiz,
                    title: 'Ver posts',
                    onTap: () => Navigator.pushNamed(context, '/Get_post')),
                MenuButton(icon: Icons.chat,
                    title: 'Conversas',
                    onTap: () => Navigator.pushNamed(context, '/Conversas')),
                MenuButton(icon: Icons.map,
                    title: 'Encontrar uma sala',
                    onTap: () => Navigator.pushNamed(context, '/find_room')),
                MenuButton(icon: Icons.school,
                    title: 'Reservar uma sala',
                    onTap: () => Navigator.pushNamed(context, '/time')),
                MenuButton(icon: Icons.fastfood,
                    title: 'Encontrar sítio para comer',
                    onTap: () => Navigator.pushNamed(context, '/food')),
                MenuButton(icon: Icons.settings,
                    title: 'Opções',
                    onTap: () => Navigator.pushNamed(context, '/user_settings')),
                MenuButton(icon: Icons.logout,
                    title: 'Sair',
                    onTap: () async {
                      await logout(context);
                      Navigator.of(context).pushReplacementNamed('/login');
                    }),
                  ],
                  scrollDirection: Axis.vertical,
                ),
              ),
            ),
            floatingActionButton: snapshot.data == true
                ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/superuser_mode');
              },
              child: Icon(Icons.star),
              backgroundColor: Colors.red,
            )
                : null,
          );
        }
      },
    );
  }

  Future<void> dailyLogin(BuildContext context) async {
    bool newLogin=false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? dailyLogin = await prefs.getInt('DailyLogin');
    String? lastLogin = prefs.getString('LastLogin');
    String? YearPref=prefs.getString('SelectedYear');
    if(YearPref == null)
      prefs.setString('SelectedYear',DateTime.now().year.toString());

    if (dailyLogin == null) {
      dailyLogin = 1;
      prefs.setString(
          'LastLogin', DateTime.now().add(const Duration(days: 1)).toString());
      lastLogin = await prefs.getString('LastLogin');
      newLogin=true;
    }
      if(DateTime.parse(lastLogin!).isBefore(DateTime.now())||newLogin){
      if(DateTime.parse(lastLogin).add(const Duration(days: 2)).isAfter(DateTime.now())){
        prefs.setInt('DailyLogin', dailyLogin++);
        prefs.setString(
            'LastLogin', DateTime.now().add(const Duration(days: 1)).toString());
      }
    else {
      prefs.setInt('DailyLogin',1);
      prefs.setString(
          'LastLogin', DateTime.now().add(const Duration(days: 1)).toString());

    }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Obrigado!'),
              content: Text('Obrigado por usar a nossa aplicação por $dailyLogin dias seguidos'),
              actions: <Widget>[
          ListTile(title: Row(children: <Widget>[
          Expanded(child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/wheel'), // wrap in an anonymous function
          child: Text('Rodar a roda'),
          ),
          ),
          Expanded(
          child: ElevatedButton(
          onPressed: () {
          showDialog(
          context: context,
          builder: (BuildContext context) {
          String selectedOption = 'facil'; // Default selected option
          return AlertDialog(
          title: Text('Selecione a dificuldade'),
          content: DropdownButton<String>(
          value: selectedOption,
          items: <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
          value: 'facil',
          child: Text('Facil'),
          ),
          DropdownMenuItem<String>(
          value: 'normal',
          child: Text('Normal'),
          ),
          DropdownMenuItem<String>(
          value: 'dificil',
          child: Text('Dificil'),
          ),
          ],
          onChanged: (String? newValue) {
          if (newValue != null) {
          selectedOption = newValue;
          Navigator.of(context).pop(); // Close the dialog box
          switch (selectedOption) {
          case 'facil':
          Navigator.of(context).pushNamed('/Ondeestoufacil');
          break;
          case 'normal':
          Navigator.of(context).pushNamed('/Ondeestounormal');
          break;
          case 'dificil':
          Navigator.of(context).pushNamed('/Ondeestoudificil');
          break;
          }
          }
          },
          ),
          );
          },
          );
          },
          child: Text('Onde Estou?'),
          ),
          ),
          Expanded(child:  ElevatedButton(
          onPressed: () => Navigator.of(context).pop(), // wrap in an anonymous function
          child: Text('Ok'),
          ),
          ),
          ],
          ),
          ),
          ]
          );
        },
      );
    }
  }
}

  Future<bool> isSuper() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    if (authTokenJson == null) {
      print('Auth token not found!');
      return false;
    }
    Map<String, dynamic> authToken = jsonDecode(authTokenJson);
    print(authToken['role']);
    return  'SU'== authToken['role'];
  }


  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    String? fCMToken = prefs.getString('fCMToken');
    print(fCMToken);
    print("logging out");
    prefs.remove('SelectedYear');
    final databaseService = await LocalDatabaseService.create('Calendar');
    databaseService.clearDatabase('my_calendar');
    if (authTokenJson == null) {
    print('Auth token not found!');
    Navigator.pushNamed(context, '/login');
    return;
  }
  try{
  final url = Uri.parse('http://wired-compass-389110.oa.r.appspot.com/rest/logout');
  final body = jsonEncode({'token': jsonDecode(authTokenJson), 'firebaseToken': fCMToken});;
  final headers = {'Content-Type': 'application/json;charset=utf-8'};

  final response = await http.post(url, body: body, headers: headers);

  if (response.statusCode == 200) {
    // Logout successful, clear authToken from SharedPreferences and navigate to LoginPage
    await prefs.remove('authToken');
    Navigator.pushNamed(context, '/login');
  } else {
    await prefs.remove('authToken');
    Navigator.pushNamed(context, '/login');
    // Logout failed, handle the error
    print('Logout failed! Error code: ${response.statusCode}');
  }
  }catch(e){
    await prefs.remove('authToken');
    Navigator.pushNamed(context, '/login');
  }
}

class UserProfile {
  static const String _url = 'https://wired-compass-389110.oa.r.appspot.com/rest/getUsers/giveUser';
  Future<Map<String, dynamic>> getUserProfile() async {
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(authToken),
    );
    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }
}

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();

}

class _UserProfilePageState extends State<UserProfilePage> {
  int? Streak;
  bool _showAllData = false;
  Map<String, String> translations = {
    'username': 'Usuário',
    'name': 'Nome',
    'email': 'Email',
    'mobilePhone': 'Numero de Telémovel',
    'phone': 'Numero de Telefone',
    'role': 'Tipo',
    'points': 'Pontos',
    'privacy': 'Privacidade',
  };
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil do usuário'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_left),
            onPressed: () {
              setState(() {
                _showAllData = !_showAllData;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_rounded),
            onPressed: () {
              goToShop(context);
            },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: FutureBuilder(
        future: UserProfile().getUserProfile(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData) {
            // Render the user profile data
            final data = snapshot.data!;
            var keys = _showAllData
                ? data.keys.toList()
                : data.keys.where((key) => translations.keys.contains(key))
                .toList();
            keys = keys.reversed.toList();
            return ListView.builder(
              itemCount: keys.length + 2, // Increase item count by one for the 'streak'
              itemBuilder: (context, index) {
                if (index == 0) { // Show image at position 0
                  return FutureBuilder(
                    future: getPostWidget(data['photo']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else {
                        return snapshot.data ?? Container();
                      }
                    },
                  );
                } else if (index == 1) { // Show 'streak' at position 1
                  return FutureBuilder(
                    future: getStreak(), // This should be your method to get the 'streak'
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Failed to load streak: ${snapshot.error}');
                      } else {

                        return ListTile(
                          leading: Icon(Icons.local_fire_department), // Fire icon to represent 'streak'
                          title: Text('Série diária de utilização',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(Streak.toString()),
                        );
                      }
                    },
                  );
                } else { // For all other positions, show data
                  final key = keys[index - 2]; // Adjust index for the data and 'streak'
                  final value = data[key] ?? '';
                  final type = translations[key] ?? key;
                  return ListTile(
                    title: Text(type,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(value.toString()),
                  );
                }
              },
            );
          } else if (snapshot.hasError) {
            return Text('Failed to load user profile: ${snapshot.error}');
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }


  Future<Widget> getPostWidget(String postId) async {
    var postUrl = 'https://storage.googleapis.com/wired-compass-389110.appspot.com/' + postId;

     // Check the file extension
    String fileExtension = path.extension(postUrl).toLowerCase();

    if (fileExtension != '.png' && fileExtension != '.jpeg' && fileExtension != '.jpg') {
      // If the extension is not .png or .jpeg, return a default image or widget
      return Container(
        child: Center(
          child: Text('Não tem foto'),
        ),
      );
    }

    return Container(
      width: 300.0,
      height: 300.0,
      child: Image.network(
        postUrl,
        fit: BoxFit.contain,
      ),
    );
  }

  getStreak()async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Streak = prefs.getInt('DailyLogin');
    print(Streak);
  }

  void goToShop(BuildContext context) async{
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final url = Uri.parse(
        'http://wired-compass-389110.oa.r.appspot.com/rest/rewards/listRewards');
    final body = jsonEncode(authToken);

    final headers = {'Content-Type': 'application/json;charset=utf-8'};
    print(body);
    final response = await http.post(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      print(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RewardPage(rewards: response.body)),
      );
    }
    else{
      print(response.statusCode);
      print('Response:'+response.body);
    }
  }
}

class GetUserProfilePage extends StatefulWidget {
  @override
  _GetUserProfilePageState createState() => _GetUserProfilePageState();
}

class _GetUserProfilePageState extends State<GetUserProfilePage> {
  bool _showAllData = false;
  String _username = '';
  Future<Map<String, dynamic>>? _userProfileFuture;

  Map<String, String> translations = {
    'username': 'Usuário',
    'name': 'Nome',
    'email': 'Email',
    'mobilePhone': 'Numero de Telémovel',
    'phone': 'Numero de Telefone',
    'role': 'Tipo',
    'privacy': 'Privacidade',
  };

  Future<Map<String, dynamic>> getUserProfile(String username) async {
    var authToken = await SharedPrefsUtil.checkAuthToken();
    var response = await http.post(
      Uri.parse(
          'https://wired-compass-389110.oa.r.appspot.com/rest/getUsers/giveEspecificUser'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'token': authToken,
        'userQuery': username,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Failed to load user profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil do usuário'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_left),
            onPressed: () {
              setState(() {
                _showAllData = !_showAllData;
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: Column(
        children: <Widget>[
          TextField(
            onChanged: (value) {
              setState(() {
                _username = value;
              });
            },
            onSubmitted:(value){ setState(() {
              _userProfileFuture = getUserProfile(_username);
            });
            } ,
            decoration: InputDecoration(
              labelText: "Nome do utilizador",
              suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () { setState(() {
                    _userProfileFuture = getUserProfile(_username);
                  }
                  );
                  }
                  )
            ),
          ),
          _userProfileFuture == null
              ? Container()
              : FutureBuilder(
            future: _userProfileFuture,
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, dynamic>> snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                var keys = _showAllData
                    ? data.keys.toList()
                    : data.keys
                    .where((key) => translations.keys.contains(key))
                    .toList();
                keys = keys.reversed.toList();
                return Expanded(
                  child: ListView.builder(
                    itemCount: keys.length + 1, // Added +1 for the image
                    itemBuilder: (context, index) {
                      if (index == 0) { // Show image at position 0
                        return FutureBuilder(
                          future: getPostWidget(data['photo']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else {
                              return snapshot.data ?? Container();
                            }
                          },
                        );
                      } else { // For all other positions, show data
                        final key = keys[index -
                            1]; // Adjust index for the data
                        final value = data[key] ?? '';
                        final type = translations[key] ?? key;
                        return ListTile(
                          title: Text(type,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(value.toString()),
                        );
                      }
                    },
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Failed to load user profile: ${snapshot.error}');
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<Widget> getPostWidget(String postId) async {
    var postUrl = 'https://storage.googleapis.com/wired-compass-389110.appspot.com/' +
        postId;

    // Check the file extension
    String fileExtension = path.extension(postUrl).toLowerCase();
    print(fileExtension);
    if (fileExtension != '.png' && fileExtension != '.jpeg' &&
        fileExtension != '.jpg') {
      // If the extension is not .png or .jpeg, return a default image or widget
      return Container(
        child: Center(
          child: Text('Não tem foto'),
        ),
      );
    }

    return Container(
      width: 300.0,
      height: 300.0,
      child: Image.network(
        postUrl,
        fit: BoxFit.contain,
      ),
    );
  }
}