# flutter_ijk

## 由于工作重心变动，已经不做应用了，该项目不再维护

A FLUTTER PLAYER SUPPORT RTSP PROTOCOLS

  flutter_ijk 是flutter端的ijkplayer播放器，在IOS和Android native端都使用的是bilibili的ijkplayer，由于GitHub大小限制，本项目的ijkplayer源码放在码云，已经定制过编译脚本和部分的功能代码，可以参考以下步骤来获取：
https://gitee.com/jadennn/flutter_ijkplayer_source.git

![](https://github.com/jadennn/flutter_ijk/blob/master/publish.png)

## 使用

1 . 在pubspec.yaml增加以下引用

```
  flutter_ijk:
    git:
      url: https://github.com/jadennn/flutter_ijk

```

2. api参考的是video_player，使用方法相同

例子:

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
  
 ///一定要记得释放资源，否则会造成内存泄漏
 void _stop() async{
    if (_controller != null) {
      await _controller.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _stop();
  }
}
```

3. 参考文档

感谢以下项目：

[ijkplayer](https://github.com/bilibili/ijkplayer)     
[video_player](https://github.com/flutter/plugins/tree/master/packages/video_player)     
[camera](https://github.com/flutter/plugins/tree/master/packages/camera)  


4. 如果出现类似下面的错误
```
 === BUILD TARGET Runner OF PROJECT Runner WITH CONFIGURATION Debug ===
    ld: warning: ignoring file /Users/bkillian/repos/flutter_ijk/ios/IJKMediaFramework.framework/IJKMediaFramework,
    file was built for unsupported file format ( 0x76 0x65 0x72 0x73 0x69 0x6F 0x6E 0x20 0x68 0x74 0x74 0x70 0x73
    0x3A 0x2F 0x2F ) which is not the architecture being linked (x86_64):
    /Users/bkillian/repos/flutter_ijk/ios/IJKMediaFramework.framework/IJKMediaFramework
    Undefined symbols for architecture x86_64:
      "_OBJC_CLASS_$_IJKFFOptions", referenced from:
          objc-class-ref in libflutter_ijk.a(FlutterIjkPlugin.o)
      "_IJKMPMoviePlayerPlaybackDidFinishNotification", referenced from:
          -[FLTVideoPlayer installMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
          -[FLTVideoPlayer removeMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
      "_IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey", referenced from:
          -[FLTVideoPlayer moviePlayBackFinish:] in libflutter_ijk.a(FlutterIjkPlugin.o)
      "_OBJC_CLASS_$_IJKFFMoviePlayerController", referenced from:
          objc-class-ref in libflutter_ijk.a(FlutterIjkPlugin.o)
      "_IJKMPMoviePlayerLoadStateDidChangeNotification", referenced from:
          -[FLTVideoPlayer installMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
          -[FLTVideoPlayer removeMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
      "_IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification", referenced from:
          -[FLTVideoPlayer installMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
          -[FLTVideoPlayer removeMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
      "_IJKMPMoviePlayerPlaybackStateDidChangeNotification", referenced from:
          -[FLTVideoPlayer installMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
          -[FLTVideoPlayer removeMovieNotificationObservers] in libflutter_ijk.a(FlutterIjkPlugin.o)
    ld: symbol(s) not found for architecture x86_64
    clang: error: linker command failed with exit code 1 (use -v to see invocation)
```
 这是因为IOS的framework太大，上传git的时候使用了git lfs功能，但是pod仓库在处理git lfs可能会有bug，导致文件缺失，为了解决这个问题，强烈建议将本仓库的代码下载到本地，直接在本地引用到项目中，引用方法：
 将本项目复制到你的项目的根目录的plugins下(如果没有，新建一个plugins)，在pubspec.yaml中新增
 ```
 flutter_ijk:
   path:plugins/flutter_ijk
 ```
 然后就可以正常引用了
 
 5. 强烈建议自己编译IJKPlayer，IJKPlayer的源代码已经经过了我的定制，只用配置好环境，IOS和Android共用同一个仓库，源代码和编译方法见：https://gitee.com/jadennn/flutter_ijkplayer_source.git
