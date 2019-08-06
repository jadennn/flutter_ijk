package com.jaden.flutterijk;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.AudioManager;
import android.net.Uri;
import android.view.Surface;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.TextureRegistry;
import tv.danmaku.ijk.media.player.IMediaPlayer;
import tv.danmaku.ijk.media.player.IjkMediaPlayer;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created Date: 2019/1/21
 * Description: FlutterIjkPlugin
 */
public class FlutterIjkPlugin implements MethodCallHandler {

  private static class IJKPlayer {

    private IjkMediaPlayer ijkPlayer;

    private Surface surface;

    private final TextureRegistry.SurfaceTextureEntry textureEntry;

    private QueuingEventSink eventSink = new QueuingEventSink();

    private final EventChannel eventChannel;

    private boolean isInitialized = false;

    IJKPlayer(
            Context context,
            EventChannel eventChannel,
            TextureRegistry.SurfaceTextureEntry textureEntry,
            String dataSource,
            Result result) {
      this.eventChannel = eventChannel;
      this.textureEntry = textureEntry;

      ijkPlayer = new IjkMediaPlayer();
      //软解
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "videotoolbox", 0);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", 1);
      //使用tcp传输
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "rtsp_transport", "tcp");
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "rtsp_flags", "prefer_tcp");
      //加快rtsp的一些配置参数
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "allowed_media_types", "video");
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", 10*1000*1000);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "max-buffer-size", 1024);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "infbuf", 1);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "analyzemaxduration", 100L);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "probesize", 10240L);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "flush_packets", 1L);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", 0L);
      ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", 60L);

      try {
        if(dataSource != null && dataSource.startsWith("assets:///")){
          AssetManager assetManager = context.getAssets();
          AssetFileDescriptor afd = assetManager.openFd(dataSource.replaceFirst("assets:///", ""));
          RawDataSourceProvider provider = new RawDataSourceProvider(afd);
          ijkPlayer.setDataSource(provider);
        } else {
          ijkPlayer.setDataSource(dataSource);
        }

      }catch (IOException e){
        e.printStackTrace();
      }catch (IllegalArgumentException e){
        e.printStackTrace();
      }catch (SecurityException e){
        e.printStackTrace();
      }catch (IllegalStateException e){
        e.printStackTrace();
      }
      setupIJKPlayer(eventChannel, textureEntry, result);
    }

    private void setupIJKPlayer(
            EventChannel eventChannel,
            TextureRegistry.SurfaceTextureEntry textureEntry,
            Result result) {

      eventChannel.setStreamHandler(
              new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object o, EventChannel.EventSink sink) {
                  eventSink.setDelegate(sink);
                }

                @Override
                public void onCancel(Object o) {
                  eventSink.setDelegate(null);
                }
              });

      surface = new Surface(textureEntry.surfaceTexture());
      ijkPlayer.setSurface(surface);
      ijkPlayer.setOnPreparedListener(new IMediaPlayer.OnPreparedListener() {
        @Override
        public void onPrepared(IMediaPlayer iMediaPlayer) {
          isInitialized = true;
          sendInitialized();
        }
      });

      ijkPlayer.setOnBufferingUpdateListener(new IMediaPlayer.OnBufferingUpdateListener() {
        @Override
        public void onBufferingUpdate(IMediaPlayer iMediaPlayer, int i) {
          Map<String, Object> event = new HashMap<>();
          event.put("event", "bufferingUpdate");
          //percent to time
          event.put("values", i*ijkPlayer.getDuration()/100);
          eventSink.success(event);
        }
      });
      ijkPlayer.setOnErrorListener(new IMediaPlayer.OnErrorListener() {
        @Override
        public boolean onError(IMediaPlayer iMediaPlayer, int i, int i1) {
          if (eventSink != null) {
            eventSink.error("VideoError", "Video player had error " + i, null);
          }
          return true;
        }
      });
      ijkPlayer.setOnCompletionListener(new IMediaPlayer.OnCompletionListener() {
        @Override
        public void onCompletion(IMediaPlayer iMediaPlayer) {
          Map<String, Object> event = new HashMap<>();
          event.put("event", "completed");
          if (eventSink != null) {
            eventSink.success(event);
          }
        }
      });

      ijkPlayer.prepareAsync();

      Map<String, Object> reply = new HashMap<>();
      reply.put("textureId", textureEntry.id());
      result.success(reply);
    }

    private static void setAudioAttributes(IjkMediaPlayer ijkPlayer) {
        ijkPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
    }

    void play() {
      ijkPlayer.start();
    }

    void pause() {
      ijkPlayer.pause();
    }

    void setLooping(boolean value) {
      ijkPlayer.setLooping(value);
    }

    void setVolume(double value) {
      float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
      ijkPlayer.setVolume(bracketedValue, bracketedValue);
    }

    void seekTo(int location) {
      ijkPlayer.seekTo(location);
    }

    long getPosition() {
      return ijkPlayer.getCurrentPosition();
    }

    private void sendInitialized() {
      if (isInitialized) {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "initialized");
        event.put("duration", ijkPlayer.getDuration());
        event.put("width", ijkPlayer.getVideoWidth());
        event.put("height", ijkPlayer.getVideoHeight());
        eventSink.success(event);
      }
    }

    void dispose() {
      if (isInitialized) {
        ijkPlayer.stop();
      }
      textureEntry.release();
      eventChannel.setStreamHandler(null);
      if (surface != null) {
        surface.release();
      }
      if (ijkPlayer != null) {
        ijkPlayer.release();
      }
    }
  }

  public static void registerWith(Registrar registrar) {
    final FlutterIjkPlugin plugin = new FlutterIjkPlugin(registrar);
    final MethodChannel channel =
            new MethodChannel(registrar.messenger(), "jaden.com/flutterijk");
    channel.setMethodCallHandler(plugin);
    registrar.addViewDestroyListener(
            new PluginRegistry.ViewDestroyListener() {
              @Override
              public boolean onViewDestroy(FlutterNativeView view) {
                plugin.onDestroy();
                return false; // We are not interested in assuming ownership of the NativeView.
              }
            });
  }

  private FlutterIjkPlugin(Registrar registrar) {
    this.registrar = registrar;
    this.ijkPlayers = new HashMap<>();
  }

  private final Map<Long, IJKPlayer> ijkPlayers;

  private final Registrar registrar;

  void onDestroy() {
    // The whole FlutterView is being destroyed. Here we release resources acquired for all instances
    // of IJKPlayer. Once https://github.com/flutter/flutter/issues/19358 is resolved this may
    // be replaced with just asserting that ijkPlayers.isEmpty().
    // https://github.com/flutter/flutter/issues/20989 tracks this.
    for (IJKPlayer player : ijkPlayers.values()) {
      player.dispose();
    }
    ijkPlayers.clear();
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    TextureRegistry textures = registrar.textures();
    if (textures == null) {
      result.error("no_activity", "video_player plugin requires a foreground activity", null);
      return;
    }
    switch (call.method) {
      case "init":
        for (IJKPlayer player : ijkPlayers.values()) {
          player.dispose();
        }
        ijkPlayers.clear();
        break;
      case "create":
      {
        TextureRegistry.SurfaceTextureEntry handle = textures.createSurfaceTexture();
        EventChannel eventChannel =
                new EventChannel(
                        registrar.messenger(), "jaden.com/flutterijk/videoEvents" + handle.id());

        IJKPlayer player;
        if (call.argument("asset") != null) {
          String assetLookupKey;
          if (call.argument("package") != null) {
            assetLookupKey =
                    registrar.lookupKeyForAsset(
                            (String) call.argument("asset"), (String) call.argument("package"));
          } else {
            assetLookupKey = registrar.lookupKeyForAsset((String) call.argument("asset"));
          }
          player =
                  new IJKPlayer(
                          registrar.context(),
                          eventChannel,
                          handle,
                          "assets:///" + assetLookupKey,
                          result);
          ijkPlayers.put(handle.id(), player);
        } else {
          player =
                  new IJKPlayer(
                          registrar.context(),
                          eventChannel,
                          handle,
                          (String) call.argument("uri"),
                          result);
          ijkPlayers.put(handle.id(), player);
        }
        break;
      }
      default:
      {
        long textureId = ((Number) call.argument("textureId")).longValue();
        IJKPlayer player = ijkPlayers.get(textureId);
        if (player == null) {
          result.error(
                  "Unknown textureId",
                  "No video player associated with texture id " + textureId,
                  null);
          return;
        }
        onMethodCall(call, result, textureId, player);
        break;
      }
    }
  }

  private void onMethodCall(MethodCall call, Result result, long textureId, IJKPlayer player) {
    switch (call.method) {
      case "setLooping":
        player.setLooping((Boolean) call.argument("looping"));
        result.success(null);
        break;
      case "setVolume":
        player.setVolume((Double) call.argument("volume"));
        result.success(null);
        break;
      case "play":
        player.play();
        result.success(null);
        break;
      case "pause":
        player.pause();
        result.success(null);
        break;
      case "seekTo":
        int location = ((Number) call.argument("location")).intValue();
        player.seekTo(location);
        result.success(null);
        break;
      case "position":
        result.success(player.getPosition());
        break;
      case "dispose":
        player.dispose();
        ijkPlayers.remove(textureId);
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
