import 'package:flutter/material.dart';
import 'package:flutter_ijk/flutter_ijk.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoPage extends StatefulWidget {
  final String url;

  VideoPage(this.url);

  @override
  State<StatefulWidget> createState() {
    return VideoPageState();
  }
}

class VideoPageState extends State<VideoPage> {
  IjkPlayerController _controller;
  bool _isPlaying;

  @override
  void initState(){
    super.initState();
    getPermission().then((_){
      _controller = IjkPlayerController.network(widget.url)
        ..addListener(() {
          final bool isPlaying = _controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        })
        ..initialize().then((_) {
          setState(() {});
        });
      _controller.setLooping(true);
    });
  }

  Future getPermission() async{
    return await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: _controller == null ? Container(): Stack(
        children: <Widget>[
          _controller.value.initialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: IjkPlayer(_controller),
                )
              : Container(),
          Container(
            alignment: AlignmentDirectional.bottomEnd,
            child: FloatingActionButton(
              onPressed: _controller.value.isPlaying
                  ? _controller.pause
                  : _controller.play,
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
