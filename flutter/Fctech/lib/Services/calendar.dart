import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/SharedPrefsUtil.dart';
import 'local_database_service.dart';

class CalendarPage extends StatefulWidget {
  CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {

  DateTime? _focusedDay;
  DateTime? _selectedDay;
  late Future _initFuture;


  @override
  void initState() {
    initializeDateFormatting('pt_PT', null);
    super.initState();
    _initFuture =
        Future.delayed(Duration(seconds: 2), () => _loadEventsFromDatabase());
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      await _loadEventsFromDatabase();
      print('lista de eventos final $_events');
      setState(() {});
    });
  }

  Future<void> _loadEventsFromDatabase() async {
    _focusedDay ??= DateTime.now();
    _selectedDay ??= DateTime.now();
    _events.clear();
    DateTime current = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int selectedYear = int.parse(prefs.getString('SelectedYear') ?? '0');
    print(selectedYear);


    if (selectedYear != _focusedDay?.year) {
      _focusedDay = DateTime.utc(selectedYear, current.month, current.day);
      ;
    }
    final databaseService = await LocalDatabaseService.create('Calendar');
    List<Map<String, dynamic>> eventList = await databaseService.getAllContent(
        'my_calendar');
    for (Map<String, dynamic> eventMap in eventList) {
      //print(DateTime.parse(eventMap['enddate']));
      // Converte o mapa para um objeto Event
      // Você precisará adaptar isso de acordo com a estrutura do mapa
      Event event = Event(
        eventMap['title'],
        eventMap['description'],
        DateTime.parse(eventMap['date']),
        DateTime.parse(eventMap['enddate']),
      );
      DateTime eventDate = DateTime(
          event.date.year, event.date.month, event.date.day);
      // Adicione o evento à lista de eventos
      if (_events[eventDate] != null) {
        _events[eventDate]!.add(event);
      } else {
        _events[eventDate] = [event];
      }
    }
    setState(() {
      print(_events);
      _events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text('Calendário'),
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.error != null) {
            // If there's an error
            return Center(child: Text('Um erro ocorreu tente mais tarde'));
          } else {
            // If data loaded successfully
            return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SimpleCalendar(
                    focusedDay: _focusedDay ?? DateTime.now(),
                    selectedDay: _selectedDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getEventsForDay,
                  ),
                  ..._getEventsForDay(_selectedDay!).map(
                        (Event event) =>
                        ListTile(
                          title: Text(event.title),
                          onTap: () => _showEventDetails(event),
                          trailing: Icon(Icons.expand),
                        ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddEventDialog,
      ),
    );
  }

  Future<void> _GetCurrentTime() async {
    DateTime current = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int selectedYear = int.parse(prefs.getString('SelectedYear') ?? '0');
    print(selectedYear);
    if (selectedYear != _focusedDay?.year) {
      setState(() {
        _focusedDay = DateTime.utc(selectedYear, current.month, current.day);
      });
    }
  }


  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(event.title),
            content: Text(
                'Às ${time(event.date)} \nAté às ${time(event.enddate)}\n${event
                    .description}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              if(event.description.contains('UUID:'))
                TextButton(
                  onPressed: () => DeleteEvent(event.title, event.description),
                  child: const Text('Apagar Evento'),),

            ],
          ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        final _titleController = TextEditingController();
        final _descriptionController = TextEditingController();
        DateTime _selectedDate = _selectedDay != null ? _selectedDay! : DateTime
            .now();
        TimeOfDay _startTime = TimeOfDay.now();
        TimeOfDay _endTime = TimeOfDay.now();

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text('Criar evento'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(labelText: 'Nome'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mete nome por favor';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(labelText: 'Descrição'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mete uma descrição por favor';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (picked != null)
                              setState(() {
                                _startTime = picked;
                              });
                          },
                          child: Text('Hora de inicio'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (picked != null)
                              setState(() {
                                _endTime = picked;
                              });
                          },
                          child: Text('Hora de termino'),
                        ),
                        Text('Hora de inicio: ${_startTime.format(context)}'),
                        Text('Hora de termino: ${_endTime.format(context)}'),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text('Cancelar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Criar evento'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Transform time into DateTime
                        DateTime startDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _startTime.hour,
                          _startTime.minute,
                        );
                        DateTime endDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _endTime.hour,
                          _endTime.minute,
                        );

                        _addEvent(
                          _titleController.text,
                          _descriptionController.text,
                          startDateTime,
                          endDateTime,
                        );
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }

  List<Event> _getEventsForDay(DateTime date) {
    return _events[date] ?? [];
  }


  final Map<DateTime, List<Event>> _events = {
    // Add more dates and events...
  };

  String time(DateTime date) {
    String times = "";
    times += date.hour.toString() + ':';

    if (date.minute < 10)
      times += '0';
    times += date.minute.toString();

    return times;
  }

  String fixTime(String time) {
    String result = time.replaceAll("-", "/");

    return result.substring(0, 16).replaceAll('T', ' ');
  }

  void _addEvent(String title, String description, DateTime startDate,
      DateTime endDate) async {
    // Criação da nova instância do evento
    Event newEvent = Event(title, description, startDate, endDate);

    // Conversão do evento em um formato aceitável para o banco de dados
    // Você precisará substituir este código pelo seu próprio método de conversão


    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final url = Uri.parse(
        'http://wired-compass-389110.oa.r.appspot.com/rest/personalEvent/createPersonalEvent');
    final body = jsonEncode({
      'token': authToken,
      'title': newEvent.title,
      'description': newEvent.description,
      'startDate': fixTime(newEvent.date.toIso8601String()),
      'endDate': fixTime(newEvent.enddate.toString()),
    });
    final headers = {'Content-Type': 'application/json;charset=utf-8'};
    print(body);
    final response = await http.post(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      Map<String, dynamic> eventMap = {
        'title': newEvent.title,
        'description': 'UUID:' + response.body + ' descrição:' +
            newEvent.description,
        'date': newEvent.date.toIso8601String(),
        'enddate': newEvent.enddate.toString()
      };
      // Inserção do evento no banco de dados
      final databaseService = await LocalDatabaseService.create('Calendar');
      await databaseService.insertContent('my_calendar', eventMap);
      setState(() {});
      Navigator.pushReplacementNamed(context, '/calendar');
    } else {
      print('${response.statusCode} \n ${response.body}');
      throw Exception('Falha ao criar o evento por favor criar de novo');
    }
    // Adição do evento à lista de eventos na memória
  }

  DeleteEvent(String title, String description) async{
    Map<String, dynamic>? authToken = await SharedPrefsUtil.checkAuthToken();
    final url = Uri.parse(
        'http://wired-compass-389110.oa.r.appspot.com/rest/personalEvent/deletePersonalEvent');
    final body = jsonEncode({
      'token': authToken,
      'uuid': description.split('descrição:')[0].split('UUID:')[1],
    });
    final headers = {'Content-Type': 'application/json;charset=utf-8'};
    print(body);
    final response = await http.post(url, body: body, headers: headers);
    if (response.statusCode == 200) {
      final databaseService = await LocalDatabaseService.create('Calendar');
      await databaseService.deleteContent('my_calendar', title);
      Navigator.pushReplacementNamed(context, '/calendar');
    }
    else {
      print('${response.statusCode} \n ${response.body}');
      throw Exception('Falha ao apagar o evento por favor criar de novo');
    }
  }
}


class Event {
  final String title;
  final String description;
  final DateTime date;
  final DateTime enddate;

  const Event(this.title, this.description, this.date,this.enddate);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(), // convert DateTime to string
      'enddate': enddate.toIso8601String(), // convert DateTime to string
    };
  }
}

class SimpleCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) eventLoader;

  const SimpleCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.eventLoader,
  });
  Color determineColor(List<Event> events) {
    for (var event in events) {
      if (event.title.startsWith("Inicio")||event.title.startsWith('Fim ')) {
        return Colors.limeAccent;
      }
      else if (event.title.startsWith("Aula")) {
        return Colors.green;
      }
    }
    return Colors.grey;
  }

  int calculateTotalGridCount(DateTime focusedDay) {
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    int extraDays = (7 - ((daysInMonth + startingWeekday - 1) % 7)) % 7;
    return daysInMonth + startingWeekday - 1 + extraDays;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    final totalGridCount = calculateTotalGridCount(focusedDay);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                final previousMonth = DateTime(focusedDay.year, focusedDay.month - 1);
                onDaySelected(previousMonth, previousMonth);
              },
            ),
            Text(
              DateFormat.yMMMM('pt_PT').format(focusedDay),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1);
                onDaySelected(nextMonth, nextMonth);
              },
            ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: totalGridCount,
          itemBuilder: (context, index) {
            final dayIndex = index - startingWeekday + 2;
            if (dayIndex < 1) {
              return Container(); // Empty cells before the first day
            }
            else if (dayIndex > daysInMonth) {
              final nextMonthDay = DateTime(focusedDay.year, focusedDay.month + 1, dayIndex - daysInMonth);
              final nextMonthEvents = eventLoader(nextMonthDay);

              final isSelected = selectedDay != null && isSameDay(selectedDay!, nextMonthDay);
              final hasEvents = nextMonthEvents.isNotEmpty;

              return InkWell(
                onTap: () {
                  final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1);
                  onDaySelected(nextMonthDay, nextMonth);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected ? Border.all(color: Colors.blue) : null,
                    borderRadius: BorderRadius.circular(4),
                      color: Colors.blue.shade300
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E('pt_PT').format(nextMonthDay),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        nextMonthDay.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            else {
              final day = DateTime(focusedDay.year, focusedDay.month, dayIndex);
              final events = eventLoader(day);

              final isSelected = selectedDay != null && isSameDay(selectedDay!, day);
              final hasEvents = events.isNotEmpty;

              return InkWell(

                onTap: () => onDaySelected(day, focusedDay),
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected ? Border.all(color: Colors.blue) : null,
                    borderRadius: BorderRadius.circular(4),
                    color: hasEvents ? determineColor(events) : null,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      Text(

                        DateFormat.E('pt_PT').format(day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],

    );
  }
}


bool isSameDay(DateTime? dayA, DateTime? dayB) {
  return dayA?.year == dayB?.year &&
      dayA?.month == dayB?.month &&
      dayA?.day == dayB?.day;
}
