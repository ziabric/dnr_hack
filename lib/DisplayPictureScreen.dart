import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

class DisplayPictureScreen extends StatefulWidget {
  final XFile image;

  const DisplayPictureScreen({super.key, required this.image});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Uint8List? _imageBytes;
  Image? _image;
  String _price = "";
  String _category = "";
  bool _localModelUseFlg = false;


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

  void _changeStateCheckbox(bool? flag) {
    setState(() {
      _localModelUseFlg = flag!;
    });
  }

  void _getInfoFromModel() {

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
          Checkbox(value: _localModelUseFlg, onChanged: _changeStateCheckbox,), 
          const Text("Use local model"),
        ],
      ),
      TextButton.icon(onPressed: _getInfoFromModel, icon: const Icon(Icons.cloud_download), label: const Text("Get Info")),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Price: $_price"),
          Text("Category: $_category"),],
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
