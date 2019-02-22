# flutter_ijk

A FLUTTER PLAYER SUPPORT RTSP PROTOCOLS


由于最近比较忙，没空维护该项目，但是GitHub上面有些同学在提issue，所以公开改项目的ijkplayer的源码，如果有大神能够解决bug的话，欢迎在GitHub或者CSDN私聊，将你拉入到项目中来进行flutter_ijk的开发维护。

   参入开发步骤：

 1. ijkplayer的源码如下，支持ios和Android编译：

     编译步骤请查看源码根目录的readme.txt

     默认使用的是module-rtsp.sh，如果要增加配置，请修改此文件。

     ijkplayer源代码：

      https://pan.baidu.com/s/1EqGvGy8yvKbWCKgKPHLOaA

 2. 对于Android ijk的编译，参考如下链接，请注意，使用上面的ijkplayer代码，不用再通过脚本重复下载ijkplayer了：

     a.配置jdk，sdk，ndk环境

     b.查看ijkplayer下的readme.txt，参考编译Android so库

     c.拷贝修复bug后的编译完成的so库替换flutter_ijk Android目录下的so库，注意的是多平台支持

     https://blog.csdn.net/coder_pig/article/details/79134625

3. 对于IOS ijk的编译，参考如下链接，请注意，使用上面的ijkplayer代码，不用再通过脚本重复下载ijkplayer了：

    a. 配置环境

    b.查看ijkplayer下的readme.txt，编译ios代码

    c.制作framework（需要注意的是我的IJKMediaPlayer里面有一些关于CVPixelBufferRef的定制，都加了//add for flutter的注释，这些修改不能去掉）

    d.拷贝修复bug后的编译完成的IJKMediaFramework.framework替换flutter_ijk IOS目录下的IJKMediaFramework.framework库

    https://www.jianshu.com/p/3108c8a047ee

4. 以上步骤是修改ijkplayer的bug，如果是flutter_ijk中的代码bug，直接修改即可

5. 如果修改后本地测试通过，欢迎通过GitHub或者CSDN留言来申请代码提交权限

 

再次感谢大家理解支持。

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
