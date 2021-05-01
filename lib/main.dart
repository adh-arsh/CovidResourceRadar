import 'dart:async';
import 'dart:ui';

import 'package:covidresourceconsole/registration/registrationToGet.dart';
import 'package:covidresourceconsole/registration/registrationToGive.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Constants/constants.dart';
import 'helpPage/helpPage.dart';

import 'package:location/location.dart' as loc;

LatLng _center;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true)
        .then((Position position) {
        _center = LatLng(position.latitude,position.longitude);

    });
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{
  Completer<GoogleMapController> _controller = Completer();

  //markers to show on the map
  final Set<Marker> _providerMarkers = {};
  final Set<Marker> _seekerMarkers = {};

  //database references
  final databaseReference = FirebaseDatabase.instance.reference();
  final providerRf = FirebaseDatabase.instance.reference().child("providers");
  final seekerRf = FirebaseDatabase.instance.reference().child("seekers");


  @override
  void initState(){
    fetchCurrentLocation();
    //this part here is used to set the markers on map as per the checkboxes
    if(!userIsProvider){
      _seekerMarkers.clear();
      //get providers details to add on map
      if(!typeOxygen && !typeBlood && !typeMedicine&&!typeBed&&!typeFood&&!typeOthers&&!typeMixed){
        providerRf.once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {

            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = title== 'Oxygen'?values["oxyQty"]:
              title== 'Plasma/Blood'?values["PlasmaOrBloodGroup"]:
              title== 'Medicine'?values["medicineName"]:
              title== 'Bed'?values["bedQty"]:
              title== 'Food'?values["typeOfFood"]:
              title== 'Others'?values["detail"]:
              title== 'Mixed'?values["additionalInfo"]:
              values["additionalInfo"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            title== 'Oxygen'?values["oxyQty"]:
                            title== 'PlasmaOrBlood'? '':
                            title== 'Medicine'?'':
                            title== 'Bed'?values["bedQty"]:
                            title== 'Food'?'':
                            title== 'Others'?'':
                            title== 'Mixed'?'':
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeOxygen){
        providerRf.orderByChild('item').equalTo('Oxygen').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //providers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["oxyQty"];
              String itemType = values["item"];

              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            values["oxyQty"],
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeBlood){
        providerRf.orderByChild('item').equalTo('Plasma/Blood').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["PlasmaOrBloodGroup"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['providerName'],
                            values['name'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeMedicine){
        providerRf.orderByChild('item').equalTo('Medicine').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["medicineName"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeBed){
        providerRf.orderByChild('item').equalTo('Bed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["bedQty"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            values["bedQty"],
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeFood){
        providerRf.orderByChild('item').equalTo('Food').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["typeOfFood"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeOthers){
        providerRf.orderByChild('item').equalTo('Others').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["detail"];
              String itemType = values["item"];

              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeMixed){
        providerRf.orderByChild('item').equalTo('Mixed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["additionalInfo"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
    }
    else{
      _providerMarkers.clear();
      //set seekers marker on map
      if(!typeOxygen && !typeBlood && !typeMedicine&&!typeBed&&!typeFood&&!typeOthers&&!typeMixed){
        seekerRf.once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = title== 'Oxygen'?values["oxyQty"]:
              title== 'Plasma/Blood'?values["PlasmaOrBloodGroup"]:
              title== 'Medicine'?values["medicineName"]:
              title== 'Bed'?values["bedQty"]:
              title== 'Food'?values["typeOfFood"]:
              title== 'Others'?values["detail"]:
              title== 'Mixed'?values["additionalInfo"]:
              values["additionalInfo"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _buildAboutDialog(
                                context,
                                values['phNumber'],
                                values['item'],
                                title== 'Oxygen'?values["oxyQty"]:
                                title== 'PlasmaOrBlood'? '':
                                title== 'Medicine'?'':
                                title== 'Bed'?values["bedQty"]:
                                title== 'Food'?'':
                                title== 'Others'?'':
                                title== 'Mixed'?'':
                                '',
                                values['name'],
                                values['patientName'],
                                values['patientAge'],
                                values['attendant'],
                                values['relation'],
                                values['additionalInfo'],
                                values['PlasmaOrBloodGroup'],
                                values['medicineName'],
                                values['typeOfFood'],
                              ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeOxygen){
        seekerRf.orderByChild('item').equalTo('Oxygen').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["oxyQty"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _buildAboutDialog(
                                context,
                                values['phNumber'],
                                values['item'],
                                values["oxyQty"],
                                values['name'],
                                values['patientName'],
                                values['patientAge'],
                                values['attendant'],
                                values['relation'],
                                values['additionalInfo'],
                                values['PlasmaOrBloodGroup'],
                                values['medicineName'],
                                values['typeOfFood'],
                              ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeBlood){
        seekerRf.orderByChild('item').equalTo('Plasma/Blood').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["PlasmaOrBloodGroup"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeMedicine){
        seekerRf.orderByChild('item').equalTo('Medicine').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["medicineName"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeBed){
        seekerRf.orderByChild('item').equalTo('Bed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["bedQty"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            values["bedQty"],
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeFood){
        seekerRf.orderByChild('item').equalTo('Food').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["typeOfFood"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'PlasmaOrBlood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeOthers){
        seekerRf.orderByChild('item').equalTo('Others').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["detail"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeMixed){
        seekerRf.orderByChild('item').equalTo('Mixed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["additionalInfo"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'PlasmaOrBlood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
    }
    super.initState();
  }


  @override
  void dispose() {
    mapController.dispose();
    _seekerMarkers.clear();
    _providerMarkers.clear();
    super.dispose();
  }

  //using this function to get location and mainly for permission set up
  fetchCurrentLocation() async {
    var location = loc.Location();
    loc.LocationData _locationData;
    var currentLocation = await location.getLocation();
    setState(() {
      _center = LatLng(currentLocation.latitude,currentLocation.longitude);
    }); //rebuild the widget after getting the current location of the user


    location.changeSettings(accuracy: loc.LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 500);
    if (location.hasPermission() != null) {
      await location.requestPermission();
    }

    try {
      location.onLocationChanged.listen((
          loc.LocationData currentLocation) {
        setState(() {
          //_currentPosition = currentLocation;
          _center = LatLng(currentLocation.latitude,currentLocation.longitude);
        });

      });
    } on PlatformException {
    }
    _locationData = await location.getLocation();
    setState(() {
      _center = LatLng(_locationData.latitude,_locationData.longitude);
    });

  }


  GoogleMapController mapController;
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }



  //checkboxes state
  bool filterState = false;
  bool typeOxygen = false;
  bool typeBlood = false;
  bool typeMedicine = false;
  bool typeBed = false;
  bool typeFood = false;
  bool typeOthers = false;
  bool typeMixed = false;

  //function to retrieve phone number from shared preferences
  getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString('phNumber') ?? '';
    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    //get any existing phone number used
    getPhoneNumber();
    fetchCurrentLocation();
    //user database reference as per the existing stored phonenumber
    DatabaseReference userDb = databaseReference.child(userType);

   //this part here is used to set the markers on map as per the checkboxes
    if(!userIsProvider){
      _seekerMarkers.clear();
      //get providers details to add on map
      if(!typeOxygen && !typeBlood && !typeMedicine&&!typeBed&&!typeFood&&!typeOthers&&!typeMixed){
        providerRf.once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {

            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = title== 'Oxygen'?values["oxyQty"]:
              title== 'Plasma/Blood'?values["PlasmaOrBloodGroup"]:
              title== 'Medicine'?values["medicineName"]:
              title== 'Bed'?values["bedQty"]:
              title== 'Food'?values["typeOfFood"]:
              title== 'Others'?values["detail"]:
              title== 'Mixed'?values["additionalInfo"]:
              values["additionalInfo"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            title== 'Oxygen'?values["oxyQty"]:
                            title== 'PlasmaOrBlood'? '':
                            title== 'Medicine'?'':
                            title== 'Bed'?values["bedQty"]:
                            title== 'Food'?'':
                            title== 'Others'?'':
                            title== 'Mixed'?'':
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeOxygen){
        providerRf.orderByChild('item').equalTo('Oxygen').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //providers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["oxyQty"];
              String itemType = values["item"];

              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            values["oxyQty"],
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeBlood){
        providerRf.orderByChild('item').equalTo('Plasma/Blood').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["PlasmaOrBloodGroup"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['providerName'],
                            values['name'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeMedicine){
        providerRf.orderByChild('item').equalTo('Medicine').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["medicineName"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeBed){
        providerRf.orderByChild('item').equalTo('Bed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["bedQty"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            values["bedQty"],
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeFood){
        providerRf.orderByChild('item').equalTo('Food').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["typeOfFood"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeOthers){
        providerRf.orderByChild('item').equalTo('Others').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["detail"];
              String itemType = values["item"];

              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>  _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeMixed){
        providerRf.orderByChild('item').equalTo('Mixed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["additionalInfo"];
              String itemType = values["item"];
              _providerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
    }
    else{
      _providerMarkers.clear();
      //set seekers marker on map
      if(!typeOxygen && !typeBlood && !typeMedicine&&!typeBed&&!typeFood&&!typeOthers&&!typeMixed){
        seekerRf.once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = title== 'Oxygen'?values["oxyQty"]:
              title== 'Plasma/Blood'?values["PlasmaOrBloodGroup"]:
              title== 'Medicine'?values["medicineName"]:
              title== 'Bed'?values["bedQty"]:
              title== 'Food'?values["typeOfFood"]:
              title== 'Others'?values["detail"]:
              title== 'Mixed'?values["additionalInfo"]:
              values["additionalInfo"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _buildAboutDialog(
                              context,
                            values['phNumber'],
                            values['item'],
                                title== 'Oxygen'?values["oxyQty"]:
                                title== 'PlasmaOrBlood'? '':
                                title== 'Medicine'?'':
                                title== 'Bed'?values["bedQty"]:
                                title== 'Food'?'':
                                title== 'Others'?'':
                                title== 'Mixed'?'':
                                '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                                values['PlasmaOrBloodGroup'],
                                values['medicineName'],
                                values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )
              );
            }
          });
        });
      }
      if(typeOxygen){
        seekerRf.orderByChild('item').equalTo('Oxygen').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["oxyQty"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _buildAboutDialog(
                                context,
                                values['phNumber'],
                                values['item'],
                                values["oxyQty"],
                                values['name'],
                                values['patientName'],
                                values['patientAge'],
                                values['attendant'],
                                values['relation'],
                                values['additionalInfo'],
                                values['PlasmaOrBloodGroup'],
                                values['medicineName'],
                                values['typeOfFood'],
                              ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeBlood){
        seekerRf.orderByChild('item').equalTo('Plasma/Blood').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["PlasmaOrBloodGroup"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeMedicine){
        seekerRf.orderByChild('item').equalTo('Medicine').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["medicineName"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeBed){
        seekerRf.orderByChild('item').equalTo('Bed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["bedQty"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            values["bedQty"],
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeFood){
        seekerRf.orderByChild('item').equalTo('Food').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["typeOfFood"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'PlasmaOrBlood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeOthers){
        seekerRf.orderByChild('item').equalTo('Others').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["detail"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'Plasma/Blood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
      if(typeMixed){
        seekerRf.orderByChild('item').equalTo('Mixed').once().then((DataSnapshot snapshot){
          Map<dynamic, dynamic> values = snapshot.value;
          values.forEach((key,values) {
            if(_center != null){
              //seekers in your area contents
              LatLng _loc = LatLng(values["lat"],values["lng"]);
              String title = values["item"];
              String snippet = values["additionalInfo"];
              String itemType = values["item"];
              _seekerMarkers.add(
                  Marker(
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        itemType == 'Oxygen' ? BitmapDescriptor.hueCyan :
                        itemType == 'PlasmaOrBlood' ? BitmapDescriptor.hueRed :
                        itemType == 'Medicine' ? BitmapDescriptor.hueAzure :
                        itemType == 'Bed' ? BitmapDescriptor.hueGreen :
                        itemType == 'Food' ? BitmapDescriptor.hueOrange :
                        itemType == 'Others' ? BitmapDescriptor.hueYellow:
                        itemType == 'Mixed' ? BitmapDescriptor.hueMagenta :
                        BitmapDescriptor.hueRose
                    ),
                    markerId: MarkerId(_loc.toString()),
                    position: _loc,
                    infoWindow: InfoWindow(
                      title: title,
                      snippet: snippet,
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => _buildAboutDialog(
                            context,
                            values['phNumber'],
                            values['item'],
                            '',
                            values['name'],
                            values['patientName'],
                            values['patientAge'],
                            values['attendant'],
                            values['relation'],
                            values['additionalInfo'],
                            values['PlasmaOrBloodGroup'],
                            values['medicineName'],
                            values['typeOfFood'],
                          ),
                        );
                      },
                    ),
                  )

              );
            }
          });
        });
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 10,
        title: Text(userIsProvider?'Requirements':'Available Resources',style: TextStyle(color: Colors.blue),),
        actions: [
          IconButton(
            icon: Icon(Icons.help,size: 35,color: Colors.blue,),
            tooltip: 'Open shopping cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  Help()),
              );
            },
          ),
        ],

      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              //body section
              Container(
                    height: MediaQuery.of(context).size.height-150,
                    child: Stack(
                      children: <Widget>[

                        //map
                        GoogleMap(
                          gestureRecognizers:
                          <Factory<OneSequenceGestureRecognizer>>[new Factory<OneSequenceGestureRecognizer>(() => new EagerGestureRecognizer(),),
                          ].toSet(),
                          zoomControlsEnabled: false,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          compassEnabled: true,

                          initialCameraPosition: CameraPosition(
                            target: _center != null ? _center : LatLng(20.5937,78.9629),
                            zoom: _center != null? 14 : 5,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          markers: userIsProvider ? _seekerMarkers : _providerMarkers,
                        ),

                        //announced / requested dashboard
                        Positioned(
                          top: 1,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height:80,
                            child: StreamBuilder(
                              stream: databaseReference.child(userIsProvider?'providers':'seekers').orderByChild('phNumber').equalTo(phoneNumber).onValue,
                              builder: (context, snap) {
                                if (snap.hasData && !snap.hasError && snap.data.snapshot.value != null) {
                                  Map data = snap.data.snapshot.value;
                                  List item = [];
                                  data.forEach((index, data) => item.add(data));
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.only(left: 10),
                                    itemCount: item.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                          child: Container(
                                            width: MediaQuery.of(context).size.width-100,
                                              padding: EdgeInsets.all(20),
                                              child:
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: <Widget>[
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      //item name
                                                      Container(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(item[index]['item'],style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                                      ),
                                                      //itemQty if relevant
                                                      item[index]['item'] == 'Oxygen' && item[index]['oxyQty'] != null || item[index]['item'] == 'Bed' && item[index]['bedQty'] != null?
                                                      Container(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(
                                                          item[index]['item'] == 'Oxygen' ? '${item[index]['oxyQty']}' : '${item[index]['bedQty']}'
                                                          ,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                                      ) :
                                                      Container(),
                                                    ],
                                                  ),
                                                  //delete the announcment/request
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: <Widget>[
                                                      //delete card button
                                                      Container(
                                                          alignment: Alignment.centerRight,
                                                          child: InkWell(
                                                            onTap: (){
                                                              userDb.child(item[index]['key']).remove();
                                                            },
                                                            child:  Icon(Icons.delete,size: 30,color: Colors.red),
                                                          )

                                                      ),
                                                    ],
                                                  )
                                                ],
                                              )
                                          )
                                      );
                                    },
                                  );

                                }
                                else
                                  return Container();
                              },
                            ),
                          ),
                        ),

                        //filter button
                        Positioned(
                          left: 25,
                          bottom: 12,
                          child: Container(
                            child: filterState ?
                            Container(
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[

                                    //checkboxes to filter
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: <Widget>[
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Checkbox(value: typeOxygen, onChanged: (bool value) {
                                                setState(() {
                                                  _seekerMarkers.clear();
                                                  _providerMarkers.clear();
                                                  typeOxygen = value;
                                                });
                                              },),
                                              Icon(Icons.location_on,color: Colors.cyan,),
                                              Text('Oxygen'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Checkbox(value: typeBlood, onChanged: (bool value) {
                                                setState(() {
                                                  _seekerMarkers.clear();
                                                  _providerMarkers.clear();
                                                  typeBlood = value;
                                                });
                                              },),
                                              Icon(Icons.location_on,color: Colors.red,),
                                              Text('Plasma/Blood'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Checkbox(value: typeMedicine, onChanged: (bool value) {
                                                setState(() {
                                                  _seekerMarkers.clear();
                                                  _providerMarkers.clear();
                                                  typeMedicine = value;
                                                });
                                              },),
                                              Icon(Icons.location_on,color: Colors.blueAccent,),
                                              Text('Medicine'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Checkbox(value: typeBed, onChanged: (bool value) {
                                                setState(() {
                                                  _seekerMarkers.clear();
                                                  _providerMarkers.clear();
                                                  typeBed = value;
                                                });
                                              },),
                                              Icon(Icons.location_on,color: Colors.green,),
                                              Text('Beds'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Checkbox(value: typeFood, onChanged: (bool value) {
                                                setState(() {
                                                  _seekerMarkers.clear();
                                                  _providerMarkers.clear();
                                                  typeFood = value;
                                                });

                                              },),
                                              Icon(Icons.location_on,color: Colors.orange,),
                                              Text('Food'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Checkbox(value: typeOthers, onChanged: (bool value) {
                                                setState(() {
                                                  _seekerMarkers.clear();
                                                  _providerMarkers.clear();
                                                  typeOthers = value;
                                                });
                                              },),
                                              Icon(Icons.location_on,color: Colors.yellow,),
                                              Text('Others'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    //button to close filter
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 10,
                                      ),
                                        onPressed: (){
                                      setState(() {
                                        filterState = false;
                                      });
                                    },
                                        child: Icon(Icons.close)
                                    )

                                  ],
                                ),
                              )
                            ) : Container(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 10,
                                      ),
                                      onPressed: (){
                                        setState(() {
                                          filterState = true;
                                        });
                                        },
                                      child: Center(
                                        child: Icon(Icons.filter_list_alt),
                                      )
                                  ),
                                )
                            ,
                          )


                        ),

                        //request/announce button
                        Positioned(
                            left: 100,
                            right: 100,
                            bottom: 12,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 10,
                                ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>  userIsProvider? ProviderRegistration(center: _center,) :SeekerRegistration(center: _center,)),
                                );
                              }, child: userIsProvider? Text('Announce',style: TextStyle(fontSize: 21),) : Text('Request',style: TextStyle(fontSize: 21),)
                            ),


                        ),
                      ],
                    )
                  ),
              //bottom section
              Container(
                padding: EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0),topRight: Radius.circular(20.0)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        offset: Offset(0, -2.0), //(x,y)
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: [
                          Text('Seeker',style:
                          userIsProvider ?  TextStyle(color: Colors.blue,fontWeight: FontWeight.normal,fontSize: 20):
                          TextStyle(color: Colors.blue,fontWeight: FontWeight.bold,fontSize: 30),

                            textAlign: TextAlign.center,),
                          Text( userIsProvider ?'':'Mode' ,style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                      Container(
                          child: Column(
                            children: <Widget>[
                              Container(
                                  child : Transform.scale( scale: 2.3,
                                    child: new
                                    Switch(value: userIsProvider, onChanged:(value){
                                      setState(() {
                                        _seekerMarkers.clear();
                                        _providerMarkers.clear();
                                        userIsProvider = value;
                                      }
                                      );
                                    }),
                                  )
                              ),
                            ],
                          )
                      ),
                      Container(
                        alignment: Alignment.center,
                        child:  Column(
                          children: <Widget>[
                            Text('Provider',style:
                            userIsProvider ? TextStyle(color: Colors.blue,fontWeight: FontWeight.bold,fontSize: 30) :
                            TextStyle(color: Colors.blue,fontWeight: FontWeight.normal,fontSize: 20),

                              textAlign: TextAlign.center,),
                            Text( userIsProvider ? 'Mode' :'',style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        )
                    ],
                  )
              ),
            ],
          ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }



  //pop up display
  Widget _buildAboutDialog(BuildContext context,
      phoneNumber,
      item,
      itemQty,
      providerName,
      patientName,
      patientAge,
      attenderName,
      relation,
      additionalInfo,
      bloodGroup,
      medicineName,
      food
      )
  {
    TextEditingController patientNameController = TextEditingController();
    TextEditingController patientAgeController = TextEditingController();
    TextEditingController attendantNameController = TextEditingController();
    TextEditingController relationController = TextEditingController();
    TextEditingController phNumberController = TextEditingController();

    TextEditingController oxygenQtyController = TextEditingController();
    TextEditingController bloodTypeController = TextEditingController();
    TextEditingController otherDetailsController = TextEditingController();
    TextEditingController medicineNameController = TextEditingController();
    TextEditingController foodTypeController = TextEditingController();
    TextEditingController bedQtyController = TextEditingController();



    TextEditingController nameController = TextEditingController();

    patientNameController.text=patientName;
    patientAgeController.text=patientAge;
    attendantNameController.text=attenderName;
    relationController.text=relation;
    phNumberController.text=phoneNumber;
    bloodTypeController.text=bloodGroup;
    otherDetailsController.text='$additionalInfo';


    oxygenQtyController.text=itemQty;
    bedQtyController.text=itemQty;
    medicineNameController.text=medicineName;
    foodTypeController.text=food;


    nameController.text=providerName;
    return new AlertDialog(
        content: new  SingleChildScrollView(
          child: userIsProvider ? //show contents of seeker pop
          Column(
            children: [
              Container(
                  width: MediaQuery.of(context).size.width - 10,
                  height: MediaQuery.of(context).size.height - 250,
                  child: ListView(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          controller: patientNameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Patient Name',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          controller: patientAgeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Patient\'s Age',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          controller: attendantNameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Attendant\'s Name',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          controller: relationController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Relation',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20,0),
                        child: TextField(
                          readOnly: true,
                          controller: phNumberController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Phone Number',
                          ),
                        ),
                      ),
                      item!='Others'? Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          readOnly: true,
                          controller: item == 'Oxygen'? oxygenQtyController:
                          item == 'Bed'? bedQtyController:
                          item == 'Plasma/Blood'? bloodTypeController:
                          item == 'Food'? foodTypeController:
                          medicineNameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '$item',
                          ),
                        ),
                      ):Container(),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20,20),
                        child: TextField(
                          readOnly: true,
                          minLines: 5,
                          maxLines: 15,
                          controller: otherDetailsController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Additional Information',
                          ),
                        ),
                      ),
                    ],
                  )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  //whatsapp button
                  new ElevatedButton(
                    onPressed: ()=>{launch('https://wa.me/$phoneNumber')},
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        )
                    ),
                    child: Container(
                        height: 50,
                        width: 50,
                        child: Image.asset('assets/logos/icons8-whatsapp-144.png')
                    ),
                  ),
                  //call button
                  new ElevatedButton(
                    onPressed: ()=>{launch('tel: $phoneNumber')},
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        )
                    ),
                    child: Container(
                        height: 50,
                        width: 50,
                        child:  Icon(Icons.call,size: 30,)
                    ),
                  )
                ],
              )
            ],
          )
              :
          Column(
            children: [
              Container(
                  width: MediaQuery.of(context).size.width - 10,
                  height: MediaQuery.of(context).size.height - 250,
                  child: ListView(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          controller: nameController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Name',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          controller: phNumberController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Phone Number',
                          ),
                        ),
                      ),
                      item!='Others'? Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: TextField(
                          readOnly: true,
                          controller: item == 'Oxygen'? oxygenQtyController:
                          item == 'Bed'? bedQtyController:
                          item == 'Plasma/Blood'? bloodTypeController:
                          item == 'Food'? foodTypeController:
                          medicineNameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '$item',
                          ),
                        ),
                      ):Container(),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 30, 20,20),
                        child: TextField(
                          readOnly: true,
                          minLines: 5,
                          maxLines: 15,
                          controller: otherDetailsController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Additional Information',
                          ),
                        ),
                      ),
                    ],
                  )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  //whatsapp button
                  new ElevatedButton(
                    onPressed: ()=>{launch('https://wa.me/$phoneNumber')},
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        )
                    ),
                    child: Container(
                        height: 50,
                        width: 50,
                        child: Image.asset('assets/logos/icons8-whatsapp-144.png')
                    ),
                  ),
                  //call button
                  new ElevatedButton(
                    onPressed: ()=>{launch('tel: $phoneNumber')},
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        )
                    ),
                    child: Container(
                        height: 50,
                        width: 50,
                        child:  Icon(Icons.call,size: 30,)
                    ),
                  )
                ],
              )
            ],
          )
        ),
    );
  }

}
