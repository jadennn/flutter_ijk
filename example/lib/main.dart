import 'package:flutter/material.dart';
import 'package:flutter_ijk_example/video.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VideoPage("rtsp://admin:!QAZ2wsx@172.21.90.3/h264/ch1/main/av_stream"),
      //home: VideoPage("http://172.21.113.146:7080/big_buck_bunny.mp4"),
      //home: VideoPage("assets/flutter_assets/video/big_buck_bunny.mp4"),
    );
  }
}

