import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../utils/SharedPrefsUtil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart' as storage;

import 'Mainpage.dart';

class PostsNavigationPage extends StatefulWidget {
  PostsNavigationPage({Key? key}) : super(key: key);

  @override
  _PostsNavigationPageState createState() => _PostsNavigationPageState();
}

class _PostsNavigationPageState extends State<PostsNavigationPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController tagController = TextEditingController();


  Future<String?> showDialogWithInput(BuildContext context, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Procura por $label'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('OK'),
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
        title: Text('Posts'),
      ),
      backgroundColor: Colors.lightBlue[100],
      body: Center( // center the content
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MenuButton(
                icon: Icons.image,
                title: 'Carregar imagem',
                onTap: () {
                  Navigator.pushNamed(context, '/post_image');
                },
              ),
              SizedBox(height: 20), // add spacing between buttons
              MenuButton(
                icon: Icons.person,
                title: 'Posts de um user',
                onTap: () async {
                  final username = await showDialogWithInput(context, 'Username');
                  if (username != null && username.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostsPage(username: username),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20), // add spacing between buttons
              MenuButton(
                icon: Icons.tag,
                title: 'Posts com tag',
                onTap: () async {
                  final tag = await showDialogWithInput(context, 'Tag');
                  if (tag != null && tag.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TagPostsPage(tag: tag),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20), // add spacing between buttons
              MenuButton(
                icon: Icons.my_library_books,
                title: 'Meus Posts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelfPostsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class GetSelfPostsRequest {
  var token;
  int pageSize;
  String cursorStr;

  GetSelfPostsRequest({required this.token, required this.pageSize, required this.cursorStr});

  Map<String, dynamic> toJson() => {
    'token': token,
    'pageSize': pageSize,
    'cursorStr': cursorStr,
  };
}

class SelfPostsPage extends StatefulWidget {
  SelfPostsPage({Key? key}) : super(key: key);

  @override
  _SelfPostsPageState createState() => _SelfPostsPageState();
}

class _SelfPostsPageState extends State<SelfPostsPage> {
  late var authToken;
  int pageSize = 10;
  String cursorStr = '';
  List<Map<String, dynamic>> postsData = [];
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    loadAuthToken().then((_) => getSelfPosts());
  }

  Future<void> loadAuthToken() async {
    authToken = await SharedPrefsUtil.checkAuthToken();
  }

  Future<void> getSelfPosts() async {
    var url = Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/listPosts/getSelfPosts');
    var request = GetSelfPostsRequest(token: authToken, pageSize: pageSize, cursorStr: cursorStr);
    var response = await http.post(url, body: json.encode(request.toJson()), headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('this is the data for the response: '+data.toString());
      if (data['posts'] != null) {
        setState(() {
          cursorStr = data['nextCursorStr'];
          postsData += data['posts'].map<Map<String, dynamic>>((post) => Map<String, dynamic>.from(post)).toList();
        });
      }
    } else {
      print(response.statusCode);
      print('Request failed with status: ${response.body}.');
    }
  }


  Future<Widget> _getPostWidget(String postId) async {
    var postUrl = 'https://storage.googleapis.com/wired-compass-389110.appspot.com/'+postId;
    var isVideo = postId.toLowerCase().endsWith(".mp4");

    if (isVideo) {
      _controller = VideoPlayerController.network(postUrl);
      await _controller.initialize();
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Image.network(
          postUrl,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Os meus posts'),
      ),
      body: GridView.builder(
        itemCount: postsData.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 2.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsPage(postData: postsData[index]),
                ),
              );
            },
            child: FutureBuilder<Widget>(
              future: _getPostWidget(postsData[index]['postId']),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: snapshot.data!,
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getSelfPosts,
        tooltip: 'Load More',
        child: Icon(Icons.add_box),
      ),
        backgroundColor: Colors.lightBlue[100],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
class GetPostsRequest {
  var token;
  int pageSize;
  String cursorStr;
  String username;

  GetPostsRequest({required this.token, required this.pageSize, required this.cursorStr, required this.username});

  Map<String, dynamic> toJson() => {
    'token': token,
    'pageSize': pageSize,
    'cursorStr': cursorStr,
    'username': username,
  };
}

class PostsPage extends StatefulWidget {
  final String username;
  PostsPage({Key? key, required this.username}) : super(key: key);

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  late var authToken;
  int pageSize = 9;
  String cursorStr = '';
  List<Map<String, dynamic>> postsData = [];
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    loadAuthToken().then((_) => getPosts());
  }

  Future<void> loadAuthToken() async {
    authToken = await SharedPrefsUtil.checkAuthToken();
  }

  Future<void> getPosts() async {
    var url = Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/listPosts/getPosts');
    var request = GetPostsRequest(token: authToken, pageSize: pageSize, cursorStr: cursorStr, username: widget.username);
    var response = await http.post(url, body: json.encode(request.toJson()), headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var data = json.decode(utf8.decode(response.bodyBytes));
      if (data['posts'] != null) {
        setState(() {
          cursorStr = data['nextCursorStr'];
          postsData += data['posts'].map<Map<String, dynamic>>((post) => Map<String, dynamic>.from(post)).toList();
        });
      }
    } else {
      print(response.statusCode);
      print('Request failed with status: ${response.body}.');
    }
  }


  Future<Widget> _getPostWidget(String postId) async {
    var postUrl = 'https://storage.googleapis.com/wired-compass-389110.appspot.com/'+postId;
    var isVideo = postId.toLowerCase().endsWith(".mp4");

    if (isVideo) {
      _controller = VideoPlayerController.network(postUrl);
      await _controller.initialize();
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Image.network(
          postUrl,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Página de posts de ${widget.username}'),
      ),
      body: GridView.builder(
        itemCount: postsData.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 2.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsPage(postData: postsData[index]),
                ),
              );
            },
            child: FutureBuilder<Widget>(
              future: _getPostWidget(postsData[index]['postId']),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: snapshot.data!,
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getPosts,
        tooltip: 'Load More',
        child: Icon(Icons.add_box),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
// Rest of the code here (methods for creating video thumbnails, video player widgets, etc.)
// would be same as your original _SelfPostsPageState

class GetTagPostsRequest {
  var token;
  int pageSize;
  String cursorStr;
  String tag;

  GetTagPostsRequest({required this.token, required this.pageSize, required this.cursorStr, required this.tag});

  Map<String, dynamic> toJson() => {
    'token': token,
    'pageSize': pageSize,
    'cursorStr': cursorStr,
    'tag': tag,
  };
}

class TagPostsPage extends StatefulWidget {
  final String tag;
  TagPostsPage({Key? key, required this.tag}) : super(key: key);

  @override
  _TagPostsPageState createState() => _TagPostsPageState();
}

class _TagPostsPageState extends State<TagPostsPage> {
  late var authToken;
  int pageSize = 9;
  String cursorStr = '0';
  List<Map<String, dynamic>> postsData = [];
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    loadAuthToken().then((_) => getTagPosts());
  }

  Future<void> loadAuthToken() async {
    authToken = await SharedPrefsUtil.checkAuthToken();
  }

  Future<void> getTagPosts() async {
    var url = Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/listPosts/getTagPosts');
    var request = GetTagPostsRequest(token: authToken, pageSize: pageSize, cursorStr: cursorStr, tag: widget.tag);
    var response = await http.post(url, body: json.encode(request.toJson()), headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var data =  json.decode(utf8.decode(response.bodyBytes));
      if (data['posts'] != null) {
        setState(() {
          cursorStr = data['nextCursorStr'];
          postsData += data['posts'].map<Map<String, dynamic>>((post) => Map<String, dynamic>.from(post)).toList();
        });
      }
    } else {
      print(response.statusCode);
      print('Request failed with status ${response.statusCode}: ${response.body}.');
    }
  }


  Future<Widget> _getPostWidget(String postId) async {
    var postUrl = 'https://storage.googleapis.com/wired-compass-389110.appspot.com/'+postId;
    var isVideo = postId.toLowerCase().endsWith(".mp4");

    if (isVideo) {
      _controller = VideoPlayerController.network(postUrl);
      await _controller.initialize();
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Image.network(
          postUrl,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página de posts com ${widget.tag}'),
      ),
      body: GridView.builder(
        itemCount: postsData.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 2.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsPage(postData: postsData[index]),
                ),
              );
            },
            child: FutureBuilder<Widget>(
              future: _getPostWidget(postsData[index]['postId']),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: snapshot.data!,
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getTagPosts,
        tooltip: 'Load More',
        child: Icon(Icons.add_box),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}



class PostDetailsPage extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostDetailsPage({Key? key, required this.postData}) : super(key: key);

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  late final VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late var authToken;

  @override
  void initState() {
    super.initState();
    loadAuthToken();
    if (!widget.postData['isPhoto']) {
      _controller = VideoPlayerController.network(
        'https://storage.googleapis.com/wired-compass-389110.appspot.com/' + widget.postData['postId'],
      );
      _initializeVideoPlayerFuture = _controller.initialize();

      // Ensure the video starts to play as soon as it's initialized and set to loop.
      _initializeVideoPlayerFuture.then((_) {
        _controller.setLooping(true);
        _controller.play();
      });
    }
  }
  Future<void> loadAuthToken() async {
    authToken = await SharedPrefsUtil.checkAuthToken();

  }
  Future<String>getUsername() async{
    return  await SharedPrefsUtil.GetUsername();
  }
  Future<bool> _isUserPostOwner() async {
    var currentUsername = await getUsername();
    return widget.postData['uploaderUsername'] == currentUsername;
  }

  Future<void> _deleteFile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              new CircularProgressIndicator(),
              new Text("Deleting"),
            ],
          ),
        );
      },
    );
    final scopes = [storage.StorageApi.devstorageFullControlScope];
    Future<Map<String, dynamic>> loadJsonCredentials() async {
      String jsonString = await rootBundle.loadString(
          'assets/wired-compass-389110-eff07c28fd11.json');
      return jsonDecode(jsonString);
    }

    var credentials = ServiceAccountCredentials.fromJson(
        await loadJsonCredentials());
    var client = await clientViaServiceAccount(credentials, scopes);

    var storageAPI = storage.StorageApi(client);

    var bucketName = 'wired-compass-389110.appspot.com';



    try {
      // Upload the file to the bucket
      await storageAPI.objects.delete(bucketName,widget.postData['postId']);


      Map<String, dynamic> requestBody = {
        'token': authToken,
        'postId': widget.postData['postId'],
      };
      final response = await http.post(
        Uri.parse(
            'https://wired-compass-389110.oa.r.appspot.com/rest/posts/deletePost'),
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
          title: Text('Apagado'),
          content: Text('O seu ficheiro foi apagado!'),
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
          content: Text('Uma falha ocorreu ao apagar o ficheiro: $errorMessage'),
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
        title: Text("Detalhes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: widget.postData['isPhoto']
                  ? Image.network('https://storage.googleapis.com/wired-compass-389110.appspot.com/'+widget.postData['postId'], fit: BoxFit.cover)
                  : FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            SizedBox(height: 10),
            Text('Descrição: ${widget.postData['description']}'),
            SizedBox(height: 10),
            Wrap(
              children: widget.postData['tags'].map<Widget>((tag) {
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => TagPostsPage(tag: tag)),
                    );
                  },
                  child: Chip(
                    label: Text(tag),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PostsPage(username: widget.postData['uploaderUsername'])),
                );
              },
              child: Text('De: ${widget.postData['uploaderUsername']}'),
            ),
            FutureBuilder<bool>(
              future: _isUserPostOwner(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!) {
                  return ElevatedButton(
                    onPressed: _deleteFile,
                    child: Text('Apagar Post'),
                  );
                } else if (snapshot.hasError) {
                  return Text('Erro: volte a tentar mais tarde.');
                } else {
                  // While data is loading
                  return Container();
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller.value.isInitialized) {
      _controller.dispose();
    }
  }
}
