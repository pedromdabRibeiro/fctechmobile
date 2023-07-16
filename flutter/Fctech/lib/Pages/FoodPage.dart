import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fctech/Services/GoogleMap.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagina de restauração',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FoodPage(),
    );
  }
}

class FoodPage extends StatefulWidget {
  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    final response = await http.get(Uri.parse('http://wired-compass-389110.oa.r.appspot.com/rest/listWaypoint/listRestaurants'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      print(data);
      final restaurants = data.map((item) => Restaurant.fromJson(item)).toList();
      setState(() {
        _restaurants = restaurants;
      });
    } else {
      print(response.body);
    }
  }

  Future<void> fetchRestaurantDetails(String restaurantName) async {
    final response = await http.post(
      Uri.parse('https://wired-compass-389110.oa.r.appspot.com/rest/listWaypoint/getRestaurant'),
      body: jsonEncode({'restaurantName': restaurantName}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      final restaurant = Restaurant.fromJson(data);
      setState(() {
        _selectedRestaurant = restaurant;
      });
    } else {
      print('Falha ao obter os detalhes do restaurante tente mais tarde.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Lista de Restaurantes'),
    ),
    body: ListView.builder(
    itemCount: _restaurants.length,
    itemBuilder: (context, index) {
    final restaurant = _restaurants[index];
    return ListTile(
    title: Text(restaurant.restaurantName),
    trailing: Icon(Icons.expand_more),
      onTap: () {
    fetchRestaurantDetails(restaurant.restaurantName);
    },

    );
    },
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    persistentFooterButtons: _selectedRestaurant != null
    ? [
    ElevatedButton(
    onPressed: () {
    setState(() {
    _selectedRestaurant = null;
    });
    },
    child: Text('Voltar à lista'),
    ),
    ]
        : null,
      bottomSheet: _selectedRestaurant != null
          ? Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        color: Colors.blueGrey[100],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalhes do Restaurante:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Nome: ${_selectedRestaurant!.restaurantName}'),
              if(_selectedRestaurant!.owner!=null)
              Text('Dono:${_selectedRestaurant!.owner}'),
              Text('Descrição: ${_selectedRestaurant!.description}'),
              Text('Horário: ${_selectedRestaurant!.workingHours}'),
              SizedBox(height: 16),
              Text(
                'Menu:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _selectedRestaurant!.menu.length,
                itemBuilder: (context, index) {
                  final menuItem = _selectedRestaurant!.menu[index];
                  return ListTile(
                    title: Text(menuItem),
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  navigateToGoogleMaps(
                    _selectedRestaurant!.restaurantName,
                    _selectedRestaurant!.lat,
                    _selectedRestaurant!.lng,
                  );
                },
                child: Text('Abrir no Google Maps'),
              ),
              FutureBuilder<bool>(
                future: canManage(_selectedRestaurant),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();  // or some other placeholder
                  } else if (snapshot.hasError) {
                    return Text('Erro: ${snapshot.error}');
                  } else {
                    return snapshot.data == true ? ElevatedButton(
                      onPressed: () {
                        manageRestaurant(_selectedRestaurant);
                      },
                      child: Text('Gerir o restaurante'),
                    ) : Container();
                  }
                },
              ),
            ],
          ),
        ),
      )
          : null,
      backgroundColor: Colors.lightBlue[100],
    );
  }
  void navigateToGoogleMaps(String restaurantName, double lat, double lng) {
    final latLng = LatLng(lat, lng);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyGoogleMap.withParams(
          name: restaurantName,
            description: _selectedRestaurant!.description,
            position: latLng,
        ),
      ),
    );
  }

  void manageRestaurant(Restaurant? selectedRestaurant) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ManageRestaurantDialog(selectedRestaurant: selectedRestaurant);
      },
    );
  }
}

Future<bool> canManage(Restaurant? selectedRestaurant) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');

    if (authTokenJson == null) {
      print('Por favor fazer login de novo!');
      return false;
    }
    Map<String, dynamic> authToken = jsonDecode(authTokenJson);
  if(selectedRestaurant?.owner==authToken['username']||authToken['role']=='SU') {
    return true;
  }
  return false;
  }
class Restaurant {
  final String restaurantName;
  final double lat;
  final double lng;
  final String description;
  final List<String> menu;
  final String workingHours;
  final String owner;
  final List<String> employees;
  Restaurant({
    required this.restaurantName,
    required this.lat,
    required this.lng,
    required this.description,
    required this.menu,
    required this.workingHours,
    required this.owner,
    required this.employees,

  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final menu = List<String>.from(json['menu'] ?? []);
    final employees = List<String>.from(json['employees'] ?? []);
    return Restaurant(
      restaurantName: json['restaurantName'],
      lat: json['lat'],
      lng: json['lng'],
      description: json['description'],
      menu: menu,
      workingHours: json['workingHours'] ?? '',
      owner:json['owner'] ?? '',
      employees:employees,
    );
  }
}
class _ManageRestaurantDialog extends StatefulWidget {
  final Restaurant? selectedRestaurant;

  _ManageRestaurantDialog({this.selectedRestaurant});

  @override
  _ManageRestaurantDialogState createState() => _ManageRestaurantDialogState();
}

class _ManageRestaurantDialogState extends State<_ManageRestaurantDialog> {

  String? _newEmployee;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Gerir Restaurante'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // Add Menu Item
            ElevatedButton(
              child: Text('Adicionar Item ao Menu'),
              onPressed: () {
                String newMenuItem = '';
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Adicionar Item ao Menu'),
                      content: TextField(
                        decoration: InputDecoration(labelText: 'Nome do item a adicionar ao menu'),
                        onChanged: (value) {
                          newMenuItem = value;
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return FutureBuilder(
                                  future: addMenuItem(newMenuItem),
                                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ElevatedButton(
              child: Text('Mudar o Dono'),
              onPressed: () {
                String newOwner = '';
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Mudar o Dono'),
                      content: TextField(
                        decoration: InputDecoration(labelText: 'Mudar o Dono'),
                        onChanged: (value) {
                          newOwner = value;
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return FutureBuilder(
                                  future: changeOwner(newOwner),
                                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Padding(padding: EdgeInsets.all(8.0)),
            ElevatedButton(
              child: Text('Remover Item do menu'),
              onPressed: () {
                String? selectedMenuItem;
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          title: Text('Remover Item do menu'),
                          content: DropdownButton<String>(
                            hint: Text('Selecionar item'),
                            value: selectedMenuItem,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedMenuItem = newValue;
                              });
                            },
                            items: widget.selectedRestaurant!.menu.map((String menuItem) {
                              return DropdownMenuItem<String>(
                                value: menuItem,
                                child: Text(menuItem),
                              );
                            }).toList(),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                if (selectedMenuItem != null) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return FutureBuilder(
                                        future: removeMenuItem(selectedMenuItem!),
                                        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Por favor selecione o item que tenciona remover.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            Padding(padding: EdgeInsets.all(8.0)),
            ElevatedButton(
              child: Text('Adicionar funcionario'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String newEmployee = '';
                    return AlertDialog(
                      title: Text('Adicionar funcionario'),
                      content: TextField(
                        decoration: InputDecoration(labelText: 'Nome do funcionario'),
                        onChanged: (value) {
                          newEmployee = value;
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            if (newEmployee.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return FutureBuilder(
                                    future: addEmployee(newEmployee),
                                    builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Por favor adicione o nome do funcionario.'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            Padding(padding: EdgeInsets.all(8.0)),
            ElevatedButton(
              child: Text('Remover funcionario'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String? selectedEmployee;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text('Remover funcionario'),
                          content: DropdownButton<String>(
                            hint: Text('Selecione o funcionario a remover'),
                            value: selectedEmployee,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedEmployee = newValue;
                              });
                            },
                            items: widget.selectedRestaurant!.employees.map((String employee) {
                              return DropdownMenuItem<String>(
                                value: employee,
                                child: Text(employee),
                              );
                            }).toList(),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                if (selectedEmployee != null) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return FutureBuilder(
                                        future: removeEmployee(selectedEmployee!),
                                        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Por favor selecione o funcionario.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Fechar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }


  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authTokenJson = prefs.getString('authToken');
    return authTokenJson;
  }


  Future <void> removeMenuItem(String selectedMenuItem)async {
    String? authTokenJson= await getAuthToken();
    // Create the request body

    if (authTokenJson == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Por favor volte a fazer login'),
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
    Map<String, dynamic> requestBody = {
      'token': jsonDecode(authTokenJson),
      'restaurantName': widget.selectedRestaurant?.restaurantName,
      'menuItem':selectedMenuItem,

    };

    // Convert the request body to JSON
    String requestJson = jsonEncode(requestBody);

    // Make the POST request
    String url = 'https://wired-compass-389110.oa.r.appspot.com/rest/manageRestaurant/removeItemFromMenu';
    http.Response response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestJson,
    );

    // Handle the response
    if (response.statusCode == 200) {
      // Report ticket created successfully
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Sucesso'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
          content: Text('Removido o item : '+ selectedMenuItem),
        ),
      );
    } else {
      // Failed to create the report ticket
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Falha ao remover o item: ${response.statusCode} ${response.body}'),
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



Future <void> addMenuItem(String newMenuItem)async {
    String? authTokenJson= await getAuthToken();
  // Create the request body

    if (authTokenJson == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Por favor volte a fazer login'),
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
  Map<String, dynamic> requestBody = {
    'token': jsonDecode(authTokenJson),
    'restaurantName': widget.selectedRestaurant?.restaurantName,
    'menuItem':newMenuItem,

  };

  // Convert the request body to JSON
  String requestJson = jsonEncode(requestBody);

  // Make the POST request
  String url = 'https://wired-compass-389110.oa.r.appspot.com/rest/manageRestaurant/addItemToMenu';
  http.Response response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: requestJson,
  );

  // Handle the response
  if (response.statusCode == 200) {
    // Report ticket created successfully
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sucesso'),
        content: Text('Adicionado ao menu o item: ' +newMenuItem),
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
  } else {
    // Failed to create the report ticket
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Erro'),
        content: Text('Failha ao adicionar o item: ${response.statusCode} ${response.body}'),
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

  Future <void> addEmployee(String newEmployee)async {
    String? authTokenJson= await getAuthToken();
    // Create the request body

    if (authTokenJson == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Por favor volte a fazer login'),
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
    Map<String, dynamic> requestBody = {
      'token': jsonDecode(authTokenJson),
      'restaurantName': widget.selectedRestaurant?.restaurantName,
      'employee':newEmployee,

    };

    // Convert the request body to JSON
    String requestJson = jsonEncode(requestBody);

    // Make the POST request
    String url = 'https://wired-compass-389110.oa.r.appspot.com/rest/manageRestaurant/addEmployee';
    http.Response response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestJson,
    );

    // Handle the response
    if (response.statusCode == 200) {
      // Report ticket created successfully
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Sucess'),
          content: Text('Adicionado o funcionário:'+newEmployee),
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
    } else {
      // Failed to create the report ticket
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Falha ao adicionar o funcionário:tente mais tarde'),
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
  Future <void> removeEmployee(String selectedEmployee)async {
    String? authTokenJson= await getAuthToken();
    // Create the request body

    if (authTokenJson == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Por favor volte a fazer login'),
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
    Map<String, dynamic> requestBody = {
      'token': jsonDecode(authTokenJson),
      'restaurantName': widget.selectedRestaurant?.restaurantName,
      'employee':selectedEmployee,

    };

    // Convert the request body to JSON
    String requestJson = jsonEncode(requestBody);

    // Make the POST request
    String url = 'https://wired-compass-389110.oa.r.appspot.com/rest/manageRestaurant/removeEmployee';
    http.Response response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestJson,
    );

    // Handle the response
    if (response.statusCode == 200) {
      // Report ticket created successfully
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Sucesso'),
          content: Text('Removido o funcionário:'+ selectedEmployee),
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
    } else {
      // Failed to create the report ticket
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Erro'),
          content: Text('Falha ao remover o funcionário:tente mais tarde'),
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

 Future<void> changeOwner(String newOwner) async {
   String? authTokenJson= await getAuthToken();
   // Create the request body

   if (authTokenJson == null) {
     showDialog(
       context: context,
       builder: (_) => AlertDialog(
         title: Text('Error'),
         content: Text('Por favor fazer login de novo'),
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
    if(newOwner.isEmpty)
      newOwner="";

   Map<String, dynamic> requestBody = {
     'token': jsonDecode(authTokenJson),
     'restaurantName': widget.selectedRestaurant?.restaurantName,
     'newOwner':newOwner,

   };
    // Convert the request body to JSON
   String requestJson = jsonEncode(requestBody);
   print(requestJson);

   // Make the POST request
   String url = 'https://wired-compass-389110.oa.r.appspot.com/rest/manageRestaurant/changeOwner';
   http.Response response = await http.post(
     Uri.parse(url),
     headers: {'Content-Type': 'application/json'},
     body: requestJson,
   );

   // Handle the response
   if (response.statusCode == 200) {
     // Report ticket created successfully
     showDialog(
       context: context,
       builder: (_) => AlertDialog(
         title: Text('Success'),
         content: Text('Dono mudado para: ' +newOwner),
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
   } else {
     // Failed to create the report ticket
     showDialog(
       context: context,
       builder: (_) => AlertDialog(
         title: Text('Erro'),
         content: Text('Falha ao mudar o dono: ${response.statusCode} ${response.body}'),
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


