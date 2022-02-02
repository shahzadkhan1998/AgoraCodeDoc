// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
// ignore: library_prefixes
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
// ignore: library_prefixes
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:permission_handler/permission_handler.dart';
import 'package:videocall/Audio/audio.dart';
import 'package:videocall/component/config.dart';
import 'package:videocall/secondScreen/secondscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _joined = false;
  int _remoteUid = 0;
  bool _switch = false;
  bool _isMute = false;
  // ignore: prefer_typing_uninitialized_variables
  late final RtcEngine engine;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // destroy sdk

    engine.destroy();
    super.dispose();
  }

  // its a function that will be called when the App is Started
  Future<void> initPlatformState() async {
    await [Permission.camera, Permission.microphone].request();

    // Create RTC client instance
    RtcEngineContext context = RtcEngineContext(Config.APP_ID);
    engine = await RtcEngine.createWithContext(context);
    engine.setChannelProfile(ChannelProfile.Communication);
    engine.enableAudio();

    // Define event handling logic
    engine.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
          print('joinChannelSuccess ${channel} ${uid}');
          setState(() {
            _joined = true;
          });
        },
        userJoined: (int uid, int elapsed) {
          print('userJoined ${uid}');
          setState(() {
            _remoteUid = uid;
          });
        },
        userOffline: (int uid, UserOfflineReason reason) {
          print('userOffline ${uid}');
          setState(
            () {
              _remoteUid = 0;
            },
          );
        },
        leaveChannel: (RtcStats stats) {
          print('leaveChannel ${stats}');
          setState(() {
            _joined = false;
            if (_joined == false) {
           
            }
          });
        },
      ),
    );
    // Enable video
    await engine.enableVideo();

    // Join channel with channel name as 123
    await engine.joinChannel(Config.Token, 'chat', null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter videocall app'),
        ),
        body: Stack(
          children: [
            Center(
              child: _switch ? _renderRemoteVideo() : _renderLocalPreview(),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _switch = !_switch;
                    });
                  },
                  child: Center(
                    child:
                        _switch ? _renderLocalPreview() : _renderRemoteVideo(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Local preview
  Widget _renderLocalPreview() {
    if (_joined) {
      return RtcLocalView.SurfaceView();
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => {
               initPlatformState(),
            
            },
            child: const Text(
              'Please join channel first video call',
              textAlign: TextAlign.center,
            ),
          )
        ,
        SizedBox(
          height: 20,
        ),

        InkWell(
          onTap: () => {
            JoinChannelAudio(),
            
          },
          
          child: const Text(
                'Please join channel first  audio call',
                textAlign: TextAlign.center,
              ),
        ),
        
        ],
      );
    }
  }

  // Remote preview
  Widget _renderRemoteVideo() {
    if (_remoteUid != 0) {
      return Container(
        child: Column(
          children: [
            Expanded(
              flex: 10,
              child: RtcRemoteView.SurfaceView(
                uid: _remoteUid,
                channelId: "chat",
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      child: _switchCamera(),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: _mute(),
                    ),
                  ),
                  Expanded(child: _hangup(context)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const Text(
        'Please wait remote user join',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _switchCamera() {
    return IconButton(
      icon: Icon(Icons.switch_camera),
      onPressed: () {
        engine.switchCamera();
      },
    );
  }

  Widget _mute() {
    return IconButton(
      icon: _isMute ? const Icon(Icons.mic_off) : const Icon(Icons.mic),
      onPressed: () {
        engine.muteLocalAudioStream(
          !_isMute,
        );
        setState(() {
          _isMute = !_isMute;
        });
      },
    );
  }

  Widget _hangup(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.call_end),
      onPressed: () {
        engine.leaveChannel();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SecondScreen()),
        );
      },
    );
  }
}
