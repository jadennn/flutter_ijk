# flutter_ijk

A FLUTTER PLAYER SUPPORT RTSP PROTOCOLS

![](https://github.com/jadennn/flutter_ijk/blob/master/publish.png)

## Getting Started

1 . add in pubspec.yaml

```
  flutter_ijk:
    git:
      url: https://github.com/jadennn/flutter_ijk

```

2. how to use

API is refer to video_player

example:

```
class VideoPageState extends State<VideoPage> {
  IjkPlayerController _controller;

  @override
  void initState(){
    super.initState();
      _controller = IjkPlayerController.network("rtsp://admin:!QAZ2wsx@172.21.90.3/h264/ch1/main/av_stream")
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
```

3. Reference 

[ijkplayer](https://github.com/bilibili/ijkplayer) 
[video_player](https://github.com/flutter/plugins/tree/master/packages/video_player) 
[camera](https://github.com/flutter/plugins/tree/master/packages/camera) 