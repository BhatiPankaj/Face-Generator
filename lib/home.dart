import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'drawingArea.dart';
import 'package:face_generator/drawingArea.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<DrawingArea> points = [];
  Widget imageOutput;

  void saveToImage(List<DrawingArea> points) async {
    final recorder = ui.PictureRecorder();
    final canvas =
    Canvas(recorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(200, 200)));
    Paint paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    canvas.drawRect(Rect.fromLTWH(0, 0, 256, 256), paint2);
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
            points[i].point, points[i + 1].point, points[i].areaPaint);
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final listBytes = Uint8List.view(pngBytes.buffer);

    String base64 = base64Encode(listBytes);
    fetchResponse(base64);
  }

  void fetchResponse(var base64Image) async {
    var data = {"Image": base64Image};

    print("Starting request");

    var url = 'http://127.0.0.1:5000/predict';
    Map<String, String> headers = {
      'Content-type': 'application/json',
      // 'Access-Control-Allow-Origin': "*",
      'Accept': 'application/json',
      'Connection': 'Keep-Alive',
    };
    var body = json.encode(data);
    try {
      print('0');
      var response = await http.post(url, body: body, headers: headers);
      print('1');
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('2');
      String outputBytes = responseData['Image'];
      print(outputBytes.substring(2, outputBytes.length - 1));
      displayResponseImage(outputBytes.substring(2, outputBytes.length - 1));
    } catch (e) {
      print("* ERROR HAS OCCURRED $e");
      return null;
    }
  }

  void displayResponseImage(String bytes) async {
    Uint8List convertedBytes = base64Decode(bytes);
    setState(() {
      imageOutput = Container(
        width: 256,
        height: 256,
        child: Image.memory(
          convertedBytes,
          fit: BoxFit.cover,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(138, 35, 135, 1.0),
                    Color.fromRGBO(255, 64, 87, 1.0),
                    Color.fromRGBO(243, 113, 33, 1.0)
                  ]),
            ),
          ),
          Center(child: Text("Face Generator", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),), heightFactor: 12,),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.all(Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 5.0,
                                    spreadRadius: 1)
                              ]),
                          child: GestureDetector(
                            onPanDown: (details) {
                              this.setState(() {
                                points.add(
                                  DrawingArea(
                                      point: details.localPosition,
                                      areaPaint: Paint()
                                        ..strokeCap = StrokeCap.round
                                        ..isAntiAlias = true
                                        ..color = Colors.white
                                        ..strokeWidth = 2.0),
                                );
                              });
                            },
                            onPanUpdate: (details) {
                              this.setState(() {
                                points.add(
                                  DrawingArea(
                                      point: details.localPosition,
                                      areaPaint: Paint()
                                        ..strokeCap = StrokeCap.round
                                        ..isAntiAlias = true
                                        ..color = Colors.white
                                        ..strokeWidth = 2.0),
                                );
                              });
                            },
                            onPanEnd: (details) {
                              saveToImage(points);
                              this.setState(() {
                                points.add(null);
                              });
                            },
                            child: SizedBox.expand(
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius.all(Radius.circular(20)),
                                child: CustomPaint(
                                  painter: MyCustomPainter(points: points),
                                ),
                              ),
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Container(
                          child: Center(
                            child: Container(
                              height: 256,
                              width: 256,
                              child: imageOutput,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.14,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(2),
                        iconSize: 34,
                        icon: Text(
                          "Clear",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          this.setState(() {
                            points.clear();
                          });
                        },
                      )
                    ],
                  ),
                ),

              ],
            ),
          )
        ],
      ),
    );
  }
}
