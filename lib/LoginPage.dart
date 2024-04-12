import 'package:flutter/material.dart';

import 'TakePictureScreen.dart';
import 'package:camera/camera.dart';

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({super.key, required this.camera, });

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  TextEditingController _login = TextEditingController();
  TextEditingController _password = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                controller: _login,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                controller: _password,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: (){if (_login.text == "user" && _password.text == "user") {Navigator.push(context,MaterialPageRoute(builder: (context) => TakePictureScreen(camera: widget.camera, login: _login.text)));}},
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
