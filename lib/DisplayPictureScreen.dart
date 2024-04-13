import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class DisplayPictureScreen extends StatefulWidget {
  final XFile image;

  const DisplayPictureScreen({super.key, required this.image});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Uint8List? _imageBytes;
  Image? _image;
  bool _localModelUseFlag = false;
  String _location = "";


  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    _imageBytes = await widget.image.readAsBytes();
    setState(() {

    });
  }

  Future<void> _sendReport() async {
    
    await _updateLocation();

    Uri url = Uri.parse('http://127.0.0.1:8080/path');

    final body = base64Encode(_imageBytes!);
    
    try {
      var response = await http.post(url, body: body);
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        setState(() {

        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  Future<void> _sendReportLater() async {
    
    await _updateLocation();
    
    try {
      
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  Future<void> _updateLocation() async {
    try {
      // Запрашиваем разрешение на использование геолокации
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _location = 'Location permission denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Права на использование геолокации навсегда отклонены
        setState(() {
          _location = 'Location permissions are permanently denied, we cannot request permissions.';
        });
      } 

      // Получаем текущее местоположение пользователя
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Преобразуем координаты в адрес
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      
      // Формируем строку адреса
      setState(() {
        _location = "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
      
    } catch (e) {
      // Обработка возможных исключений
      print('Failed to get location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height * 0.6;
    _image = Image.memory(_imageBytes!, width: width, height: height,);

    List<Widget> listViewArray = [
      _image!,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        TextButton.icon(onPressed: _sendReport, icon: const Icon(Icons.email), label: const Text("Send report")),
        TextButton.icon(onPressed: _sendReportLater, icon: const Icon(Icons.hourglass_full), label: const Text("Send report later")),
      ],),
      TextButton.icon(onPressed: _updateLocation, icon: const Icon(Icons.location_on), label: const Text("Update address")),
      Text(_location)
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: listViewArray,
      ),
    );
  }
}
