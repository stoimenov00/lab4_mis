import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoder/geocoder.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(new TodoApp());

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        title: "Потсетник за испити",
        home: new TodoList());
    //new MapApp());
  }
}

class MapApp extends StatefulWidget {
  @override
  _MapAppState createState() => _MapAppState();
}

class MapUtils {
  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Couldopen the map.';
    }
  }
}

double long = 41.9981;
double lat = 21.4254;
LatLng point = LatLng(long, lat);
var location = [];
List<Marker> _markers = [];

class _MapAppState extends State<MapApp> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            onTap: (p) async {
              location = await Geocoder.google(
                  'AIzaSyDmtibS0H1FBkoe7RLpiviV69LD1rJkkHA')
                  .findAddressesFromCoordinates(
                  new Coordinates(p.latitude, p.longitude));

              setState(() {
                _markers.clear();
                _markers.add(new Marker(
                  width: 80.0,
                  height: 80.0,
                  point: p,
                  builder: (ctx) => Container(
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                  ),
                ));
                point = p;
                print(p);
              });
            },
            center: LatLng(long, lat),
            zoom: 5.0,
          ),
          layers: [
            TileLayerOptions(
                urlTemplate:
                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c']),
            MarkerLayerOptions(markers: _markers),
          ],
        ),
      ],
    );
  }
}

class TodoList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new TodoListState();
}

class Ispit {
  String name;
  DateTime datum;
  LatLng location;
  Ispit(this.name, this.datum, this.location);
}

class User {
  String username;
  String password;
  List<Ispit> _ispiti = new List<Ispit>();
  List<String> _dates = new List<String>();
  User(this.username, this.password);
}

class TodoListState extends State<TodoList> {
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();
  DateTime showFor = DateTime.now();
  List<Ispit> _showIspiti = new List<Ispit>();
  String _newispit = "";
  String _newPassword = "";
  String _newLogin = "";
  String _loggedInUser = "";
  String sanitizeDateTime(DateTime dateTime) =>
      "${dateTime.year}-${dateTime.month}-${dateTime.day}";

  List<User> users = new List();

  FlutterLocalNotificationsPlugin localNotification;

  @override
  void initState() {
    super.initState();
    var androidInitialize = new AndroidInitializationSettings('ic_launcher');

    var iOSImtialize = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        android: androidInitialize, iOS: iOSImtialize);
    localNotification = new FlutterLocalNotificationsPlugin();
    localNotification.initialize(initializationSettings);
  }

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

  void _register() {
    User u = new User(_newLogin, _newPassword);
    users.add(u);
    _showNotification(
        "Успешна регистрација", "Успешно се регистрира корисник " + u.username);
  }

  void _login() {
    for (User u in users) {
      if (_newLogin == u.username) {
        if (_newPassword == u.password) {
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
            if (u.username == _loggedInUser) {
              DateTime ss = new DateTime(selectedDate.year, selectedDate.month,
                  selectedDate.day, selectedTime.hour, selectedTime.minute);
              u._dates.add(sanitizeDateTime(ss));
              u._ispiti.add(new Ispit(_newispit, ss, point));
              print("POINT:: " + point.toString());

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

  _selectTime(BuildContext context) async {
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

  _filterByDate(BuildContext context) async {
    DateTime sDate = null;
    User sU = null;
    if (_loggedInUser != "") {
      for (User u in users) {
        if (u.username == _loggedInUser) {
          //sDate = u._ispiti.values.last;
          sDate = u._ispiti.last.datum;
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

        for (Ispit ispit in sU._ispiti) {
          if (sanitizeDateTime(ispit.datum)
              .compareTo(sanitizeDateTime(selected)) ==
              0) {
            _showIspiti.add(ispit);
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

  void _setNewLoginUState(String username) {
    if (username.length > 0) {
      setState(() {
        _newLogin = username;
      });
    }
  }

  void _setNewLoginPState(String password) {
    if (password.length > 0) {
      setState(() {
        _newPassword = password;
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
            ? new Container(
          height: 0,
          width: 0,
        )
            : new IconButton(
            onPressed: _pushDodajIspit, icon: Icon(Icons.add)),

        _loggedInUser == ""
            ? new Container(
          height: 0,
          width: 0,
        )
            : new IconButton(
            onPressed: _showForCurrenMap, icon: Icon(Icons.map)),

      ],
    );
  }

  Widget _buildListaNaIspiti() {
    return new ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _showIspiti.length,
      itemBuilder: (context, index) {
        //String key = _showIspiti.keys.elementAt(index);
        String key = _showIspiti.elementAt(index).name;
        return new Card(
          child: new ListTile(
            title: Column(
              children: [
                new Text(
                  "$key",
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                new Text(
                  //"${DateFormat('dd-MM-yyyy - kk:mm').format(_showIspiti[key])}",
                  "${DateFormat('dd-MM-yyyy - kk:mm').format(_showIspiti.elementAt(index).datum)}",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                new IconButton(
                    onPressed: () => MapUtils.openMap(
                        _showIspiti.elementAt(index).location.latitude,
                        _showIspiti.elementAt(index).location.longitude),
                    icon: Icon(Icons.directions)),
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
        title: new Text('Потсетник за испити'),
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

  void _pushMap() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return _buildMap();
    }));
  }

  void _showForCurrenMap() {
    _markers.clear();
    for (Ispit i in _showIspiti) {
      Marker m = new Marker(
        width: 80.0,
        height: 80.0,
        point: i.location,
        builder: (ctx) => Container(
          child: Icon(
            Icons.location_on,
            color: Colors.green[700],
            size: 30,
          ),
        ),
      );
      _markers.add(m);
    }

    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return _buildMap();
    }));
  }

  Widget _datum() {
    User sU = null;
    for (User u in users) {
      if (_loggedInUser == u.username) {
        sU = u;
      }
    }
    if (_loggedInUser == "" || sU._ispiti.isEmpty || _loggedInUser == "") {
      return Container();
    } else {
      return FloatingActionButton(
        onPressed: () {
          _filterByDate(context);
        },
        tooltip: 'Increment',
        child: Text("датум"),
      );
    }
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
                        _register();
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
              _selectTime(context);
            },
            child: Text("Избери време"),
          ),
          ElevatedButton(
            onPressed: () {
              _pushMap();
            },
            child: Text("Избери локација"),
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

  Widget _buildMap() {
    return new MapApp();
  }
}