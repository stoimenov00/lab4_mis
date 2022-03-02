import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

void main() => runApp(new TodoApp());

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        title: "Планер за испити",
        home: new TodoList());
  }
}

class TodoList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new TodoListState();
}

class User {
  String user;
  String pass;
  Map<String, DateTime> _ispiti = new HashMap<String, DateTime>();
  List<String> _dates =  new List<String>();
  User(this.user, this.pass);
}

class TodoListState extends State<TodoList> {
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();
  DateTime showFor = DateTime.now();
  Map<String, DateTime> _showIspiti = new HashMap<String, DateTime>();
  String _newispit = "";
  String _newPassword = "";
  String _newLogin = "";
  String _loggedInUser = "";
  String sanitizeDateTime(DateTime dateTime) =>
      "${dateTime.year}-${dateTime.month}-${dateTime.day}";

  List<User> users = new List();

  FlutterLocalNotificationsPlugin localNotification;



  Future<void> _showNotification(String title, String body) async {
    tz.initializeTimeZones();
    final String currentTimeZone =
    await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    var androidDetails = new AndroidNotificationDetails(
        "channelId", "Local Notification", "This is the description",
        importance: Importance.max);
    var iosDetails = new IOSNotificationDetails();
    var generalNotificationDetails =
    new NotificationDetails(android: androidDetails, iOS: iosDetails);
    await localNotification.show(0, title, body, generalNotificationDetails);
  }

  void _registriraj() {
    User u = new User(_newLogin, _newPassword);
    users.add(u);
    _showNotification(
        "Успешна регистрација", "Успешно се регистрира корисник " + u.user);
  }

  void _login() {
    for (User u in users) {
      if (_newLogin == u.user) {
        if (_newPassword == u.pass) {
          _showNotification(
              "Успешна најава", "Успешно се најавивте " + _loggedInUser);
          setState(() {
            _loggedInUser = _newLogin;
          });
        }
      }
    }
  }

  void _dodajIspit() {
    if (_newispit.length > 0) {
      setState(() {
        if (_loggedInUser != "") {
          for (User u in users) {
            if (u.user == _loggedInUser) {
              DateTime ss = new DateTime(selectedDate.year, selectedDate.month,
                  selectedDate.day, selectedTime.hour, selectedTime.minute);
              u._dates.add(sanitizeDateTime(ss));
              u._ispiti[_newispit] = ss;
              _showNotification(
                  "Полагате испит",
                  "Полагате испит по предметот " +
                      _newispit +
                      " на " +
                      "${DateFormat('dd-MM-yyyy - kk:mm').format(ss)}");
            }
          }
        }
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var androidInitialize = new AndroidInitializationSettings('ic_launcher');
    
    var iOSImtialize = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        android: androidInitialize, iOS: iOSImtialize);
    localNotification = new FlutterLocalNotificationsPlugin();
    localNotification.initialize(initializationSettings);
  }

  _odberiVreme(BuildContext context) async {
    final TimeOfDay timeOfDay = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (timeOfDay != null && timeOfDay != selectedTime) {
      setState(() {
        selectedTime = timeOfDay;
      });
    }
  }

  _dateFilter(BuildContext context) async {
    DateTime sDate = null;
    User sU = null;
    if (_loggedInUser != "") {
      for (User u in users) {
        if (u.user == _loggedInUser) {
          sDate = u._ispiti.values.last;
          sU = u;
        }
      }
    }

    final DateTime selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(2025),
      initialDate: sDate,
      selectableDayPredicate: (DateTime val) {
        String sanitized = sanitizeDateTime(val);
        return sU._dates.contains(sanitized);
      },
    );
    if (selected != null)
      setState(() {
        _showIspiti.clear();
        for (String ispit in sU._ispiti.keys) {
          if (sanitizeDateTime(sU._ispiti[ispit])
              .compareTo(sanitizeDateTime(selected)) ==
              0) {
            _showIspiti[ispit] = sU._ispiti[ispit];
          }
        }
        showFor = selected;
      });
  }

  _selectDate(BuildContext context) async {
    final DateTime selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2025),
    );
    if (selected != null && selected != selectedDate)
      setState(() {
        selectedDate = selected;
      });
  }

  void _setNewLoginUState(String user) {
    if (user.length > 0) {
      setState(() {
        _newLogin = user;
      });
    }
  }

  void _setNewLoginPState(String pass) {
    if (pass.length > 0) {
      setState(() {
        _newPassword = pass;
      });
    }
  }

  void _setNewispitState(String ispit) {
    if (ispit.length > 0) {
      setState(() {
        _newispit = ispit;
      });
    }
  }

  Widget _buttons() {
    return new Row(
      children: [
        _loggedInUser == ""
            ? new IconButton(onPressed: _pushRegister, icon: Icon(Icons.login))
            : new IconButton(onPressed: _logout, icon: Icon(Icons.logout)),
        _loggedInUser == ""
            ? new IconButton(onPressed: _nothing, icon: Icon(Icons.add))
            : new IconButton(onPressed: _pushDodajIspit, icon: Icon(Icons.add)),


      ],
    );
  }

  Widget _buildListaNaIspiti() {
    return new ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _showIspiti.length,
      itemBuilder: (context, index) {
        String key = _showIspiti.keys.elementAt(index);
        return new Card(
          child: new ListTile(
            title: Column(
              children: [
                new Text(
                  "$key",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                new Text(
                  "${DateFormat('dd-MM-yyyy - kk:mm').format(_showIspiti[key])}",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
            onTap: () => null,
          ),
          margin: EdgeInsets.all(10),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Планер на испити'),
        actions: [
          _buttons(),
        ],
      ),
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          children: [
            _buildListaNaIspiti(),
          ],
        ),
      ),
      floatingActionButton: _datum(),
    );
  }

  void _pushRegister() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return _buildRegister();
    }));
  }

  void _logout() {
    _loggedInUser = "";
    setState(() {
      _loggedInUser = "";
      _showIspiti.clear();
      print("Logged off " + _loggedInUser);
    });
  }

  void _pushDodajIspit() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return _buildDodajIspit();
    }));
  }

  Widget _datum() {
    User sU = null;
    for (User u in users) {
      if (_loggedInUser == u.user) {
        sU = u;
      }
    }
    if (_loggedInUser == "" || sU._ispiti.isEmpty || _loggedInUser == "") {
      return Container();
    } else {
      return FloatingActionButton(
        onPressed: () {
          _dateFilter(context);
        },
        tooltip: 'Increment',
        child: Text("датум"),
      );
    }
  }

  void _nothing() {
    showAlertDialog(context);
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Грешка"),
      content: Text("Најпрво треба да се најавет!"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _buildRegister() {
    Widget _textElement() {
      return Column(
        children: [
          new TextField(
            autofocus: true,
            onSubmitted: (val) {
              _login();
            },
            onChanged: (val) {
              _setNewLoginUState(val);
            },
            decoration: new InputDecoration(
                hintText: 'Корисничко име', contentPadding: EdgeInsets.all(16)),
          ),
          new TextField(
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            onSubmitted: (val) {
              _login();
            },
            onChanged: (val) {
              _setNewLoginPState(val);
            },
            decoration: new InputDecoration(
                hintText: 'Лозинка', contentPadding: EdgeInsets.all(16)),
          ),
        ],
      );
    }

    return new Scaffold(
        appBar: new AppBar(title: new Text('Автентикација')),
        body: new Container(
            padding: EdgeInsets.all(16),
            child: new Column(
              children: <Widget>[
                _textElement(),
                new SizedBox(
                  height: 40,
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new ElevatedButton(
                      onPressed: () {
                        _login();
                        Navigator.pop(context);
                      },
                      child: new Text("Најава"),
                    ),
                    new ElevatedButton(
                      onPressed: () {
                        _registriraj();
                        Navigator.pop(context);
                      },
                      child: new Text("Регистрација"),
                    ),
                  ],
                )
              ],
            )));
  }

  Widget _buildDodajIspit() {
    Widget _textElement() {
      return Column(
        children: [
          new TextField(
            autofocus: true,
            onSubmitted: (val) {
              _dodajIspit();
            },
            onChanged: (val) {
              _setNewispitState(val);
            },
            decoration: new InputDecoration(
                hintText: 'Име на предметот',
                contentPadding: EdgeInsets.all(16)),
          ),
          ElevatedButton(
            onPressed: () {
              _selectDate(context);
            },
            child: Text("Избери датум"),
          ),
          ElevatedButton(
            onPressed: () {
              _odberiVreme(context);
            },
            child: Text("Избери време"),
          ),
        ],
      );
    }

    return new Scaffold(
        appBar: new AppBar(title: new Text('Додај термин за испит')),
        body: new Container(
            padding: EdgeInsets.all(16),
            child: new Column(
              children: <Widget>[
                _textElement(),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new ElevatedButton(
                      onPressed: () {
                        _dodajIspit();
                        Navigator.pop(context);
                      },
                      child: new Text("Додај"),
                    ),
                  ],
                )
              ],
            )));
  }
}