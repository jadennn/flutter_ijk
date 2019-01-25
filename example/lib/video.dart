import 'package:flutter/material.dart';
import 'package:flutter_ijk/flutter_ijk.dart';

class VideoPage extends StatefulWidget {

  VideoPage();

  @override
  State<StatefulWidget> createState() {
    return VideoPageState();
  }
}

class VideoPageState extends State<VideoPage> {
  IjkPlayerController _controller;

  @override
  void initState(){
    super.initState();
//      _controller = IjkPlayerController.network("rtsp://admin:!QAZ2wsx@172.21.90.3/h264/ch1/main/av_stream")
      _controller = IjkPlayerController.asset("video/big_buck_bunny.mp4")
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
        });
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      child: _controller == null ? Container(): Center(
        child:
          _controller.value.initialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: IjkPlayer(_controller),
                )
              : Container(),
      ),
    );
  }
}
