import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webrtc/signaling.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await requestPermissions();
  runApp(MyApp());
}

Future<void> requestPermissions() async {
  await Permission.camera.request();
  await Permission.microphone.request();
}


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Flutter Explained - WebRTC"),
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Open camera
              IconButton(
                onPressed: () {
                  signaling.openUserMedia(_localRenderer, _remoteRenderer);
                },
                icon: Icon(Icons.camera_alt),
                tooltip: "Open Camera",
                color: Colors.blue,
                iconSize: 32,
              ),

              // Create room
              IconButton(
                onPressed: () async {
                  roomId = await signaling.createRoom(_remoteRenderer);
                  textEditingController.text = roomId!;
                  setState(() {});
                },
                icon: Icon(Icons.add_box),
                tooltip: "Create Room",
                color: Colors.green,
                iconSize: 32,
              ),

              // Join room
              IconButton(
                onPressed: () {
                  signaling.joinRoom(
                    textEditingController.text.trim(),
                    _remoteRenderer,
                  );
                },
                icon: Icon(Icons.meeting_room),
                tooltip: "Join Room",
                color: Colors.orange,
                iconSize: 32,
              ),

              // Hang up
              IconButton(
                onPressed: () {
                  signaling.hangUp(_localRenderer);
                },
                icon: Icon(Icons.call_end),
                tooltip: "Hang Up",
                color: Colors.red,
                iconSize: 32,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Toggle audio
              IconButton(
                onPressed: () {
                  setState(() {
                    signaling.toggleAudio();
                  });
                },
                icon: Icon(
                  signaling.isAudioEnabled ? Icons.mic : Icons.mic_off,
                ),
                color: signaling.isAudioEnabled ? Colors.blue : Colors.grey,
                iconSize: 32,
              ),

              SizedBox(width: 20),

              // Toggle video
              IconButton(
                onPressed: () {
                  setState(() {
                    signaling.toggleVideo();
                  });
                },
                icon: Icon(
                  signaling.isVideoEnabled
                      ? Icons.videocam
                      : Icons.videocam_off,
                ),
                color: signaling.isVideoEnabled ? Colors.blue : Colors.grey,
                iconSize: 32,
              ),
            ],
          ),


          SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                  Expanded(child: RTCVideoView(_remoteRenderer)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Join the following Room: "),
                Flexible(
                  child: TextFormField(
                    controller: textEditingController,
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 8)
        ],
      ),
    );
  }
}
