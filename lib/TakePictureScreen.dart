import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'DisplayPictureScreen.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String login;

  const TakePictureScreen({super.key, required this.camera, required this.login});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  // bool _loginFlag = false;
  
  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera, 
      ResolutionPreset.medium,
      enableAudio: false, 
      imageFormatGroup: ImageFormatGroup.jpeg
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${DateTime.now().toIso8601String()}.png';
      await image.saveTo(imagePath);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(image: image,),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _openPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
        if (image != null) {
          Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(image: image),
          ),
        );
      }
    } catch (e) {
      // Handle any errors
      print(e);
    }
  }

  // Future<void> _logout() async {
  //   setState(() {
  //     _loginFlag = false;
  //     Navigator.pop(context);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: Column(children: [
        FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },),
        Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1,),
              IconButton.filled(onPressed: _openPhoto, icon: const Icon(Icons.file_open), iconSize: 20,),
              const Spacer(flex: 1,),
              IconButton.filled(onPressed: _takePicture, icon: const Icon(Icons.photo_camera), iconSize: 20,),
              const Spacer(flex: 1,),
              // IconButton.filled(onPressed: _logout, icon: const Icon(Icons.logout), iconSize: 20,),
              // const Spacer(flex: 1,),
        ],),
        )
      ],),
    );
  }
}
