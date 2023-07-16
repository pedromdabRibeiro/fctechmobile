import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_database_service.dart';


List<Event> createProjectEventFromJson(Map<String, dynamic> json) {
  String title ='Projeto '+ json['UC'] + ': ' + json['description'];
  String description = 'Começou: ' + json['InitialDate'] + ', Acaba: ' + json['EndDate'];

  DateTime startDate = parseDate(json['InitialDate']);
  DateTime endDate = parseDate(json['EndDate']);

  Event startEvent = Event('Inicio do $title', description, startDate, endDate);
  Event EndEvent = Event('Fim do $title', description, endDate, endDate);

  return [startEvent,EndEvent];
}
Event createPersonalEventFromJson(Map<String, dynamic> json, int i) {
  print(json);
  String title = json['title']+i.toString();
  String description = 'UUID: '+json['eventId']+' descrição: '+json['description'];
  DateTime startDate = parseDate(json['startDate']);
  DateTime endDate = parseDate(json['endDate']);
print('this is the startDate $startDate \n this is the end date $endDate \n -------------------------------');
  return Event(title, description, startDate, endDate);
}

Event createTestOrExamEventFromJson(Map<String, dynamic> json, String type) {
  print('title processing ');
  String title = 'Avaliação teórica '+json['UC'];
  print('title processed correctly');
  String description = 'Sala: ' + json['Rooms']['Room1'];
  print('rooms processed correctly');// Add more details as needed
  DateTime date = parseDate(json['InitialDate']);
  print('initial date processed correctly');
  DateTime endDate = parseDate(json['EndDate']);
  print('final date processed correctly');
  return Event(title, description, date, endDate);
}
DateTime parseDate(String date) {
  List<String> parts = date.split(' ');
  List<String> dateParts = parts[0].split('/');
  List<String> timeParts = parts[1].split(':');

  // Note that month and day are zero-based, so subtract 1 from month
  return DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]), int.parse(timeParts[0]), int.parse(timeParts[1]));
}

List<Event> createClassEventFromJson(Map<String, dynamic> json, int year) {
  String title = 'Aula '+ json['UC'] + ': ' + json['typeClass']+' '+json['weekDay'];
  String description = 'Sala: ' + json['room'] + ', Professor: ' + json['professor'];
  print('\n $json aula a ser criada :)');
  List<Event> events = [];
   DateTime _startDate = new DateTime(year, json['startMonth'], json['startDay'],
       int.parse(json['startHour'].split(":")[0]),
       int.parse(json['startHour'].split(":")[1]));
  print('this is the start date for the class $json,  ${_startDate}');
   DateTime endDate = new DateTime(year, json['endMonth'], json['endDay'],
       int.parse(json['endingHour'].split(":")[0]),
       int.parse(json['endingHour'].split(":")[1]));
   int k = 0;
   for (var i = _startDate; i.isBefore(endDate);
   i = i.add(new Duration(days: 7))) { // Assuming this is a weekly class
     k++;
     print('Dia de aula $i');
     events.add(new Event(
         title + ' nº $k', description, i, i.add(Duration(hours: endDate
         .difference(_startDate)
         .inHours))));

 }
  return events;
}

Future<List<Event>> parseJsonToEvents(String jsonString) async {
  dynamic jsonObject = jsonDecode(jsonString);
  print('starting processing events');
  List<Event> events = [];

  // Check if jsonObject is a Map (as it was before) or a List (new personal events)
  if (jsonObject is Map<String, dynamic>) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentYear = int.parse(prefs.getString('SelectedYear') ?? '0');

    jsonObject.forEach((key, value) {
      if (key.startsWith("AllTests of")) {
        value.forEach((testKey, testData) {
          print('entering tests');
          Event testEvent = createTestOrExamEventFromJson(testData, "Teste");
          events.add(testEvent);
        });
      } else if (key.startsWith("AllClasses of")) {
        value.forEach((classKey, classData) {
          print('entering classes $classKey');
          List<Event> classEvents = createClassEventFromJson(classData, currentYear);
          print(classEvents.length);
          events.addAll(classEvents);
          events.forEach((element) {print(' data da aula ${element.date}'); });
        });
      } else if (key.startsWith("Exam of")) {
        value.forEach((examKey, examData) {
          print('entering exams');
          Event examEvent = createTestOrExamEventFromJson(examData, "Exam");
          events.add(examEvent);
        });
      } else if (key.startsWith("AllProjects of")) {
        value.forEach((projectKey, projectData) {
          print('entering projects');
          List<Event> projectEvents = createProjectEventFromJson(projectData);
          events.addAll(projectEvents);
        });
      }
    });

    // existing code for saving to database and scheduling notifications
    final databaseService = await LocalDatabaseService.create('Calendar');
    databaseService.clearDatabase('my_calendar');
    print('database has ${events.length} number of events to add');
    for( int i =0; i<events.length;i++) {
      print('adding data $i to database, ${events.elementAt(i)}');
      await databaseService.insertContent('my_calendar', events.elementAt(i).toMap());
    }
    scheduleNotifications(events);

  } else if (jsonObject is List<dynamic>) {
    int k=0;
    jsonObject.forEach((eventData) {

      print('entering personal events');
      Event personalEvent = createPersonalEventFromJson(eventData,k++);
      events.add(personalEvent);
    });

    // you would likely want to save these personal events to the database and schedule notifications as well
    final databaseService = await LocalDatabaseService.create('Calendar');
    print('database has ${events.length} number of events to add');
    for( int i =0; i<events.length;i++) {
      print('adding data $i to database, ${events.elementAt(i)}');
      await databaseService.insertContent('my_calendar', events.elementAt(i).toMap());
    }
    scheduleNotifications(events);
  }

  return events;
}

void scheduleNotifications(List<Event> events)async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // your app icon


  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  for (var i = 0; i < events.length; i++) {
    var event = events[i];

    if(event.date.isBefore(DateTime.now())){
      continue;
    }
    final dayBeforeEvent = event.date.subtract(Duration(days: 1));

    final scheduleNotificationDateTime = DateTime(
      dayBeforeEvent.year,
      dayBeforeEvent.month,
      dayBeforeEvent.day,
      9,
      0,
    ); // Scheduling the notification at 9:00 AM on the day before the event's date.

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
    );

    flutterLocalNotificationsPlugin.schedule(
      i, // notification id
      'Avaliação da faculdade', // notification title
      event.title, // notification body
      scheduleNotificationDateTime,
      platformChannelSpecifics,
    );
  }
}

class Event {
  final String title;
  final String description;
  final DateTime date;
  final DateTime enddate;

  Event(this.title, this.description, this.date, this.enddate);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String()+'Z', // convert DateTime to string
      'enddate': enddate.toIso8601String(), // convert DateTime to string
    };
  }
}