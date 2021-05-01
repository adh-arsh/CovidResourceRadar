import 'dart:async';

import 'package:covidresourceconsole/Constants/constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_pin_picker/map_pin_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:location/location.dart' as loc;

class ProviderRegistration extends StatefulWidget{

  final LatLng center;
  const ProviderRegistration({Key key, this.center}) : super(key: key);

  @override
  _ProviderRegistrationState createState() => _ProviderRegistrationState(center);

}

class _ProviderRegistrationState extends State<ProviderRegistration>{

  final LatLng center;

  _ProviderRegistrationState(this.center);
  LatLng _center;




  TextEditingController nameController = TextEditingController();
  TextEditingController phNumberController = TextEditingController();

  TextEditingController oxygenQtyController = TextEditingController();
  TextEditingController bloodTypeController = TextEditingController();
  TextEditingController otherDetailsController = TextEditingController();
  TextEditingController medicineNameController = TextEditingController();
  TextEditingController foodTypeController = TextEditingController();
  TextEditingController bedQtyController = TextEditingController();

  ///textfield validator
  bool _validateName = false;
  bool _validateMob = false;


  ///for service type drop down menu thingy
  String selectedType;
  List<String> serviceTypeList = ["Oxygen","Plasma/Blood","Medicine","Bed","Food","Others"];





  ///map picker
  Completer<GoogleMapController> _controller = Completer();
  MapPickerController mapPickerController = MapPickerController();

  Position _currentPosition;
  CameraPosition cameraPosition;

  @override
  void initState() {
    super.initState();
    Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        _center = LatLng(_currentPosition.latitude,_currentPosition.longitude);
      });
    }).catchError((e) {
      print(e);
    });

    fetchCurrentLocation();
    getPhoneNumber();
  }

  @override
  void dispose() {
    nameController.dispose();
    phNumberController.dispose();
    oxygenQtyController.dispose();
    bloodTypeController.dispose();
    otherDetailsController.dispose();
    medicineNameController.dispose();
    foodTypeController.dispose();
    bedQtyController.dispose();
    otherDetailsController.dispose();
    super.dispose();
  }

  fetchCurrentLocation() async {
    var location = loc.Location();
    location.changeSettings(accuracy: loc.LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 500);
    if (location.hasPermission() != null) {
      await location.requestPermission();
    }

    try {
      await location.onLocationChanged.listen((
          loc.LocationData currentLocation) {
        print(currentLocation.latitude);
        print(currentLocation.longitude);
        var latitude = currentLocation.latitude;
        var longitude = currentLocation.longitude;
        setState(() {
          _center = LatLng(latitude,longitude);
        });
      });
    } on PlatformException {
      location = null;
    }
  }

  Address address;
  var textController = TextEditingController();


  String add;

  savePhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phNumber', phNumberController.text);
  }

  getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString('phNumber') ?? '';
    phNumberController.text = phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
          iconTheme: IconThemeData(
            color: Colors.blue,
         ),
          backgroundColor: Colors.white,
          title: Text('Provider\'s Form',style: TextStyle(color: Colors.blue),),
      ),
      body: ListView(
        children: <Widget> [

          Container(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
            child: Text('For your privacy, please provide information which is comfortable for you to make public.',style: TextStyle(fontSize: 17),),
          ),

          //name
          Container(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
            child: TextField(
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              controller: nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
                errorText: _validateName ? 'We would need your name so that the contacting person know\'s who they are talking to' : null,

              ),
            ),
          ),

          //phone number
          Container(
            padding: EdgeInsets.fromLTRB(20, 30, 20,0),
            child: TextField(

              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              controller: phNumberController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone Number',
                errorText: _validateMob ? 'We would need a phone number to contact you' : null,
              ),
            ),
          ),

          //dropdown selection
          Container(
            padding: EdgeInsets.fromLTRB(20, 30, 20,0),
            child: DropdownButtonFormField<String>(
              hint: Text('Which item can you provide ?'),
              value: selectedType,
              items: serviceTypeList.map((label) => DropdownMenuItem(
                child: Text(label,style: TextStyle(color: Colors.blue,fontSize: 20)),
                value: label,
              )).toList(),
              onChanged: (value) {
                selectedType = value;
                setState(() => selectedType = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),

          //dynamic items as per dropdown selection
          selectedType == 'Oxygen'? _oxygen():
          selectedType == 'Plasma/Blood' ? _bloodOrPlasma():
          selectedType == 'Medicine' ? _medicine():
          selectedType == 'Bed' ? _bed():
          selectedType == 'Food' ? _food():
          selectedType == 'Others' ? _others():
          Container(),

          //map
          Container(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Text('Please select a place',style: TextStyle(fontSize: 19),)
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text('which would be convenient for you and others.'),
          ),
          center != null || _center != null ? Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20,0),
            child: SizedBox(
              height: MediaQuery.of(context).size.width-50,
              width: MediaQuery.of(context).size.width-50,
              child: MapPicker(
                // pass icon widget
                iconWidget: Icon(
                  Icons.location_pin,
                  size: 50,
                ),
                //add map picker controller
                mapPickerController: mapPickerController,
                child: GoogleMap(
                gestureRecognizers:
                <Factory<OneSequenceGestureRecognizer>>[new Factory<OneSequenceGestureRecognizer>(() => new EagerGestureRecognizer(),),
                ].toSet(),
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target:_center == null ? center : _center,
                    zoom: 14.4746,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onCameraMoveStarted: () {
                    // notify map is moving
                    mapPickerController.mapMoving();
                  },
                  onCameraMove: (cameraPosition) {
                    this.cameraPosition = cameraPosition;
                  },
                  onCameraIdle: () async {
                    // notify map stopped moving
                    mapPickerController.mapFinishedMoving();
                    //get address name from camera position
                    List<Address> addresses = await Geocoder.local
                        .findAddressesFromCoordinates(Coordinates(
                        cameraPosition.target.latitude,
                        cameraPosition.target.longitude));
                    // update the ui with the address
                    add = '${addresses.first.addressLine ?? ''}';
                  },
                ),
              ),
            )
          ) : Container(
              padding: EdgeInsets.fromLTRB(20, 30, 20,0),
              child: SizedBox(
                height: MediaQuery.of(context).size.width-40,
                width: MediaQuery.of(context).size.width-50,
                child: Container(
                  padding: EdgeInsets.all(150),
                  child: CircularProgressIndicator(
                    strokeWidth: 15,
                  ),
                )
              )
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text('The location would be publicly available therefore it\'s recommended to select a public place.'),
          ),

          //submit button
          Container(
            padding: EdgeInsets.fromLTRB(20, 30, 20,0),
            child: ElevatedButton(onPressed: () {
              setState(() {
                nameController.text.isEmpty ? _validateName = true : _validateName = false;
                phNumberController.text.isEmpty ? _validateMob = true : _validateMob = false;
              });
              selectedType != null ? _submit() : AlertDialog(
                  content: new Container(
                    child: Text('Please Select an item'),
                  )
              );
              print('submit button pressed');
            },
              child: Text('Submit',style: TextStyle(fontSize: 22),),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oxygen(){
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.number,
            textCapitalization: TextCapitalization.words,
            controller: oxygenQtyController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Number of cylinders',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: otherDetailsController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Any additional detail',
            ),
          ),
        )
      ],
    );
  }
  Widget _bloodOrPlasma(){
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: bloodTypeController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Blood Group',
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: otherDetailsController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Any additional detail',
            ),
          ),
        )
      ],
    );
  }
  Widget _medicine(){
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            controller: medicineNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Which Medicine ?',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: otherDetailsController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Any additional detail',
            ),
          ),
        )
      ],
    );
  }
  Widget _food(){
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            controller: foodTypeController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Which type of food ?',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: otherDetailsController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Any additional detail',
            ),
          ),
        )
      ],
    );
  }
  Widget _bed(){
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.number,
            textCapitalization: TextCapitalization.words,
            controller: bedQtyController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Number of bed(s)',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: otherDetailsController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Any additional detail',
            ),
          ),
        )
      ],
    );
  }
  Widget _others(){
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: otherDetailsController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Anything else ?',
            ),
          ),
        )
      ],
    );
  }


  //SEND THE DATA TO FIREBASE
  _submit() async {
    print('textController');
    print('${cameraPosition.target.latitude},${cameraPosition.target.longitude}');
    print(add);

    savePhoneNumber();
    var now = new DateTime.now();
    String time = now.toString().replaceAll('-', '_');
    time = time.replaceAll(':', '_');
    time = time.replaceAll(' ' , '_');
    time = time.replaceAll('.' , '_');

    phoneNumber = phNumberController.text;
    try {
      var databaseReference = FirebaseDatabase.instance.reference();
      databaseReference = databaseReference.child("providers").child(time);
      databaseReference.child("key").set(time);
      databaseReference.child("name").set(nameController.text);
      databaseReference.child("phNumber").set(phNumberController.text);

      databaseReference.child("address").set(add);

      var databaseReferenceNew = FirebaseDatabase.instance.reference();
      databaseReferenceNew = databaseReferenceNew.child("providers").child(time);
      databaseReferenceNew.child('lat').set(cameraPosition.target.latitude);
      databaseReferenceNew.child('lng').set(cameraPosition.target.longitude);

      if(selectedType == 'Oxygen') {
        databaseReference.child("item").set('Oxygen');
        databaseReference.child("oxyQty").set(oxygenQtyController.text);
        databaseReference.child('additionalInfo').set(otherDetailsController.text);
      }
      else if(selectedType == 'Plasma/Blood'){
        databaseReference.child("item").set('Plasma/Blood');
        databaseReference.child('PlasmaOrBloodGroup').set(bloodTypeController.text);
        databaseReference.child('additionalInfo').set(otherDetailsController.text);
      }

      else if(selectedType == 'Medicine'){
        databaseReference.child("item").set('Medicine');
        databaseReference.child('medicineName').set(medicineNameController.text);
        databaseReference.child('additionalInfo').set(otherDetailsController.text);
      }

      else if(selectedType == 'Bed'){
        databaseReference.child("item").set('Bed');
        databaseReference.child('bedQty').set(bedQtyController.text);
        databaseReference.child('additionalInfo').set(otherDetailsController.text);
      }

      else if(selectedType == 'Food'){
        databaseReference.child("item").set('Food');
        databaseReference.child('typeOfFood').set(foodTypeController.text);
        databaseReference.child('additionalInfo').set(otherDetailsController.text);
      }
      else if(selectedType == 'Others'){
        databaseReference.child("item").set('Others');
        databaseReference.child('additionalInfo').set(otherDetailsController.text);
      }

      Navigator.pop(context);

    }catch (e) {
      print(e);
    }
  }

}