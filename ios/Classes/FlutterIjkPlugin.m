#import "FlutterIjkPlugin.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <libkern/OSAtomic.h>

int64_t FLTIJKCMTimeToMillis(CMTime time) { return time.value * 1000 / time.timescale; }

@interface FLTIJKFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, readonly) NSObject<FlutterTextureRegistry>* registry;
- (void)onDisplayLink:(CADisplayLink*)link;
@end


@implementation FLTIJKFrameUpdater
- (FLTIJKFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry {
    NSAssert(self, @"super init cannot be nil");
    if (self == nil) return nil;
    _registry = registry;
    return self;
}

- (void)onDisplayLink:(CADisplayLink*)link {
    [_registry textureFrameAvailable:_textureId];
}
@end

@interface FLTIJKVideoPlayer : NSObject <FlutterTexture, FlutterStreamHandler>
@property(readonly, strong) id<IJKMediaPlayback> player;
@property(readonly, nonatomic) CADisplayLink* displayLink;
@property(nonatomic) FlutterEventChannel* eventChannel;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic, readonly) bool disposed;
@property(nonatomic, readonly) bool isPlaying;
@property(nonatomic, readonly) bool isLooping;
@property(nonatomic, readonly) bool isInitialized;
- (instancetype)initWithURL:(NSURL*)url frameUpdater:(FLTIJKFrameUpdater*)frameUpdater;
- (void)play;
- (void)pause;
- (void)setIsLooping:(bool)isLooping;
- (void)updatePlayingState;
@end

@implementation FLTIJKVideoPlayer
- (instancetype)initWithAsset:(NSString*)asset frameUpdater:(FLTIJKFrameUpdater*)frameUpdater {
    NSString* path = [[NSBundle mainBundle] pathForResource:asset ofType:nil];
    return [self initWithURL:[NSURL fileURLWithPath:path] frameUpdater:frameUpdater];
}

- (instancetype)initWithURL:(NSURL*)url frameUpdater:(FLTIJKFrameUpdater*)frameUpdater {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _isInitialized = false;
    _isPlaying = false;
    _disposed = false;
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"]; //硬解
    [options setPlayerOptionIntValue:0 forKey:@"mediacodec-hevc"]; //h265硬解
    [options setFormatOptionValue:@"tcp" forKey:@"rtsp_transport"];
    [options setFormatOptionValue:@"prefer_tcp" forKey:@"rtsp_flags"];
    [options setFormatOptionValue:@"video" forKey:@"allowed_media_types"];
    [options setFormatOptionIntValue:10*1000*1000 forKey:@"timeout"];
    [options setFormatOptionIntValue:1024 forKey:@"max-buffer-size"];
    [options setPlayerOptionIntValue:1 forKey:@"infbuf"];
    [options setFormatOptionIntValue:100 forKey:@"analyzemaxduration"];
    [options setFormatOptionIntValue:10240 forKey:@"probesize"];
    [options setFormatOptionIntValue:1 forKey:@"flush_packets"];
    [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
    [options setPlayerOptionIntValue:60 forKey:@"framedrop"];
    
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options];
    
    [self removeMovieNotificationObservers];
    [self installMovieNotificationObservers];

    if(![_player isPlaying]){
        [_player prepareToPlay];
    }
    
    _displayLink = [CADisplayLink displayLinkWithTarget:frameUpdater
                                               selector:@selector(onDisplayLink:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
    
    return self;
}

- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.player];
    
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:self.player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:self.player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:self.player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:self.player];
    
}

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        [self updatePlayingState];
        if (_eventSink != nil) {
            _eventSink(@{@"event" : @"bufferingEnd"});
        }
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        if (_eventSink != nil) {
            _eventSink(@{@"event" : @"bufferingStart"});
        }
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}


- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            if(_isLooping){
                [_player setCurrentPlaybackTime:0];
                [_player play];
            }else{
                if(_eventSink){
                    _eventSink(@{@"event" : @"completed"});
                }
            }
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            if(_eventSink){
                _eventSink(@{@"event" : @"user quit"});
            }
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            if(_eventSink){
                _eventSink([FlutterError
                            errorWithCode:@"VideoError"
                            message:@"Video finished with error"
                            details:nil]);
            }
            break;
            
        default:
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    _isInitialized = true;
    [self sendInitialized];
    [self updatePlayingState];
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    switch (_player.playbackState) {
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}


- (void)updatePlayingState {
    if (!_isInitialized) {
        return;
    }
    if (_isPlaying) {
        [_player play];
    } else {
        [_player pause];
    }
    _displayLink.paused = !_isPlaying;
}

- (void)sendInitialized {
    if (_eventSink && _isInitialized) {
        CGSize size = [_player naturalSize];
        _eventSink(@{
                     @"event" : @"initialized",
                     @"duration" : @([self duration]),
                     @"width" : @(size.width),
                     @"height" : @(size.height),
                     });
    }
}

- (void)play {
    _isPlaying = true;
    [self updatePlayingState];
}

- (void)pause {
    _isPlaying = false;
    [self updatePlayingState];
}

- (int64_t)position {
    //update buffer here
    _eventSink(@{@"event" : @"bufferingUpdate", @"values" : @((int64_t)([_player playableDuration] * 1000))}); //to msec ;
    return (int64_t)([_player currentPlaybackTime] * 1000); //to msec ;
}

- (int64_t)duration {
    return [_player duration] * 1000; //to msec
}

- (void)seekTo:(int)location {
    _player.currentPlaybackTime = location/1000; //to sec
}

- (void)setIsLooping:(bool)isLooping {
    _isLooping = isLooping;
}

- (void)setVolume:(double)volume {
    [_player setPlaybackVolume:(volume < 0.0) ? 0.0 : ((volume > 1.0) ? 1.0 : volume)];
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = [_player framePixelbuffer];
    if(pixelBuffer != nil){
        CFRetain(pixelBuffer);
    }
    return pixelBuffer;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
    _eventSink = events;
    [self sendInitialized];
    return nil;
}

- (void)dispose {
    _disposed = true;
    [_displayLink invalidate];
    [self removeMovieNotificationObservers];
    if(_player != nil){
        [_player stop];
        [_player shutdown];
        _player = nil;
    }
    //[_eventChannel setStreamHandler:nil];
}

@end

@interface FlutterIjkPlugin ()
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
@property(readonly, nonatomic) NSMutableDictionary* players;
@property(readonly, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;

@end

@implementation FlutterIjkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel =
    [FlutterMethodChannel methodChannelWithName:@"jaden.com/flutterijk"
                                binaryMessenger:[registrar messenger]];
    FlutterIjkPlugin* instance = [[FlutterIjkPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
    _messenger = [registrar messenger];
    _registrar = registrar;
    _players = [NSMutableDictionary dictionaryWithCapacity:1];
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        // Allow audio playback when the Ring/Silent switch is set to silent
        for (NSNumber* textureId in _players) {
            [_registry unregisterTexture:[textureId unsignedIntegerValue]];
            [[_players objectForKey:textureId] dispose];
        }
        [_players removeAllObjects];
        result(nil);
    } else if ([@"create" isEqualToString:call.method]) {
        NSDictionary* argsMap = call.arguments;
        FLTIJKFrameUpdater* frameUpdater = [[FLTIJKFrameUpdater alloc] initWithRegistry:_registry];
        NSString* dataSource = argsMap[@"asset"];
        FLTIJKVideoPlayer* player;
        if (dataSource) {
            NSString* assetPath;
            NSString* package = argsMap[@"package"];
            if (![package isEqual:[NSNull null]]) {
                assetPath = [_registrar lookupKeyForAsset:dataSource fromPackage:package];
            } else {
                assetPath = [_registrar lookupKeyForAsset:dataSource];
            }
            player = [[FLTIJKVideoPlayer alloc] initWithAsset:assetPath frameUpdater:frameUpdater];
        } else {
            dataSource = argsMap[@"uri"];
            player = [[FLTIJKVideoPlayer alloc] initWithURL:[NSURL URLWithString:dataSource]
                                            frameUpdater:frameUpdater];
        }
        int64_t textureId = [_registry registerTexture:player];
        frameUpdater.textureId = textureId;
        FlutterEventChannel* eventChannel = [FlutterEventChannel
                                             eventChannelWithName:[NSString stringWithFormat:@"jaden.com/flutterijk/videoEvents%lld",
                                                                   textureId]
                                             binaryMessenger:_messenger];
        [eventChannel setStreamHandler:player];
        player.eventChannel = eventChannel;
        _players[@(textureId)] = player;
        result(@{@"textureId" : @(textureId)});
    } else {
        NSDictionary* argsMap = call.arguments;
        int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
        FLTIJKVideoPlayer* player = _players[@(textureId)];
        if ([@"dispose" isEqualToString:call.method]) {
            [_registry unregisterTexture:textureId];
            [_players removeObjectForKey:@(textureId)];
            [player dispose];
            result(nil);
        } else if ([@"setLooping" isEqualToString:call.method]) {
            [player setIsLooping:[[argsMap objectForKey:@"looping"] boolValue]];
            result(nil);
        } else if ([@"setVolume" isEqualToString:call.method]) {
            [player setVolume:[[argsMap objectForKey:@"volume"] doubleValue]];
            result(nil);
        } else if ([@"play" isEqualToString:call.method]) {
            [player play];
            result(nil);
        } else if ([@"position" isEqualToString:call.method]) {
            result(@([player position]));
        } else if ([@"seekTo" isEqualToString:call.method]) {
            [player seekTo:[[argsMap objectForKey:@"location"] intValue]];
            result(nil);
        } else if ([@"pause" isEqualToString:call.method]) {
            [player pause];
            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
}

@end
