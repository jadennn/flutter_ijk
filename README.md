# flutter_ijk

A FLUTTER PLAYER SUPPORT RTSP PROTOCOLS

  flutter_ijk 是flutter端的ijkplayer播放器，在IOS和Android native端都使用的是bilibili的ijkplayer，由于GitHub大小限制，本项目的ijkplayer源码放在百度网盘，已经定制过编译脚本和部分的功能代码，可以参考以下步骤来获取：

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

4. 以上步骤可以得到ijkplayer在Android端的so库和IOS的framework文件，dart层见本GitHub仓库。

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
}
```

3. 参考文档

感谢以下项目：

[ijkplayer](https://github.com/bilibili/ijkplayer)     
[video_player](https://github.com/flutter/plugins/tree/master/packages/video_player)     
[camera](https://github.com/flutter/plugins/tree/master/packages/camera)  
