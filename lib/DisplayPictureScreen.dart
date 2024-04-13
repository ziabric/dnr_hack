import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
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

  TextEditingController _city = TextEditingController();
  TextEditingController _address = TextEditingController();
  TextEditingController _building = TextEditingController();
  TextEditingController _postCode = TextEditingController();

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

  Future<void> _openAddressDialog() async {
    showDialog(context: context, builder: (context) {
      return Dialog(
        child: ListView(
          padding: const EdgeInsets.all(20),
          
          children: [
          TextFormField(
            controller: _city,
            decoration: const InputDecoration(labelText: "City"),
          ),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: "Address"),
          ),
          TextFormField(
            controller: _building,
            decoration: const InputDecoration(labelText: "Building"),
          ),
          TextFormField(
            controller: _postCode,
            decoration: const InputDecoration(labelText: "Post code"),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _location = "${_city.text}, ${_address.text}, ${_building.text}, ${_postCode.text}";
                Navigator.pop(context);
              });
            }, 
            icon: const Icon(Icons.save), 
            label: const Text("Save")
          )
        ],
        ),
      );
    });
  }

  Future<void> _selectFromList() async {

    final List<String> list = <String>[
      "Москва, улица Тверская, дом 7, 125009",
      "Санкт-Петербург, Невский проспект, дом 22, 191186",
      "Новосибирск, улица Ленина, дом 12, 630099",
      "Екатеринбург, проспект Ленина, дом 50, 620075",
      "Казань, улица Баумана, дом 34, 420111",
      "Нижний Новгород, улица Рождественская, дом 17, 603001",
      "Челябинск, улица Свободы, дом 64, 454091",
      "Омск, проспект Мира, дом 55, 644042",
      "Ростов-на-Дону, проспект Буденновский, дом 1, 344002",
      "Уфа, улица Ленина, дом 102, 450000"
    ];


    showDialog(context: context, builder: (context) {
      return Dialog(
        child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.topLeft,
            child: TextButton.icon(
            onPressed: (){
              setState(() {
                _location = list[index];
              });
              Navigator.pop(context);
            }, 
            icon: const Icon(Icons.location_on), 
            label: Text(list[index])
          ),
          );
        },
      ),
      );
    });
  }

  Future<void> _sendReport() async {

    Uri url = Uri.parse('http://46.34.144.174:8000/image-to-text/');

    final body = base64Encode(_imageBytes!);
    
    String bodyTmp = "{loc:\"$_location\", image_base64:\"$body\"}";

    try {
      var response = await http.post(url, headers: {'Content-Type': 'application/json; charset=utf-8',}, body: bodyTmp);
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');

        showDialog(context: context, builder: 
            (context) {
              return Dialog(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thumb_up),
                      Text(utf8.decode(response.bodyBytes)),
                      TextButton(onPressed: (){
                        Navigator.pop(context);
                      }, 
                      child: const Text("Close"))
                    ],
                  ),
                )
              );
            }
        );

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
    
    try {
      
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  Future<void> _updateLocation() async {

    if (_city.text == "" || _address.text == "" || _building.text == "")
    {
      return;
    }

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
        _location = "${place.locality}, ${place.thoroughfare}, ${place.name}, ${place.postalCode}";
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
    final double height = screenSize.height * 0.5;
    _image = Image.memory(_imageBytes!, width: width, height: height,);

    List<Widget> listViewArray = [
      _image!,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        TextButton.icon(onPressed: _sendReport, icon: const Icon(Icons.email), label: const Text("Send report")),
        TextButton.icon(onPressed: _sendReportLater, icon: const Icon(Icons.hourglass_full), label: const Text("Send report later")),
      ],),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(onPressed: _updateLocation, icon: const Icon(Icons.location_on), label: const Text("Update")),
          TextButton.icon(onPressed: _openAddressDialog, icon: const Icon(Icons.mode_edit), label: const Text("Edit")),
          TextButton.icon(onPressed: _selectFromList, icon: const Icon(Icons.format_list_bulleted), label: const Text("From list")),
        ],
      ),
      Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text(_location),
      )
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
