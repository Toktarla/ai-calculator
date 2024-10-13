import 'dart:convert';
import 'dart:ui' as ui;
import 'package:ai_calc_app/stroke.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'drawing_painter.dart';

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<Stroke> strokes = [];
  Stroke currentStroke = Stroke(color: Colors.white, points: []);
  Color selectedColor = Colors.white;
  double strokeWidth = 5.0;
  final GlobalKey _globalKey = GlobalKey();

  String processedResult = '';

  void resetDrawing() {
    setState(() {
      strokes.clear();
      currentStroke = Stroke(color: selectedColor, points: []);
      processedResult = '';
    });
  }

  void selectColor(BuildContext context) async {
    Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                  currentStroke.color = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );

    if (color != null) {
      setState(() {
        selectedColor = color;
        currentStroke.color = color;
      });
    }
  }

  Future<void> _uploadImage(String base64Image) async {
    final response = await http.post(
      Uri.parse('http://localhost:8900/calculate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {
            "image": base64Image,
            "dict_of_vars": {}
          }
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Response from server: ${data}');

      // Extract expression and result from the response
      if (data['status'] == 'success') {
        final List<dynamic> results = data['data'];
        String exprResult = results.map((item) {
          return '${item['expr']} = ${item['result']}';
        }).join('\n'); // Join results with a newline if there are multiple expressions

        setState(() {
          processedResult = exprResult; // Update processed result
        });
      }
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
    }
  }

  Future<void> _captureAndUpload() async {
    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    String base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
    _uploadImage(base64Image);
  }

  void calculateDrawing() {
    _captureAndUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: FittedBox(
          child: TextButton(
            onPressed: resetDrawing,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 4,
            child: Slider(
              value: strokeWidth,
              min: 1.0,
              max: 20.0,
              onChanged: (value) {
                setState(() {
                  strokeWidth = value;
                });
              },
              label: 'Pen Size: ${strokeWidth.toStringAsFixed(0)} px',
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.color_lens,
              size: 35,
              color: Colors.pink,
            ),
            onPressed: () => selectColor(context),
          ),
          TextButton(
            onPressed: calculateDrawing,
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              elevation: 0,
            ),
            child: const Text(
              'Calculate',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: Container(
          color: Colors.black,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                currentStroke = Stroke(color: selectedColor, points: [localPosition]);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                currentStroke.points.add(localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                strokes.add(currentStroke);
                currentStroke = Stroke(color: selectedColor, points: []);
              });
            },
            child: SizedBox.expand(
              child: CustomPaint(
                painter: DrawingPainter(strokes: strokes, currentStroke: currentStroke, strokeWidth: strokeWidth),
                child: Container(),
              ),
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Text(
          processedResult.isEmpty ? '' : processedResult,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

