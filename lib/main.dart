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
    _localRenderer.initialize().then((_) {
      // Initialize local stream immediately upon app start
      signaling.openUserMedia(_localRenderer, _remoteRenderer).then((_) {
        // Trigger a state change to rebuild the UI with the local video stream
        setState(() {});
      });
    });
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
    signaling.dispose();
    super.dispose();
  }

  // --- New Widget for the Bottom Control Bar ---
  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Toggle Video
          FloatingActionButton(
            heroTag: "toggleVideo",
            mini: true,
            onPressed: () {
              setState(() {
                signaling.toggleVideo();
              });
            },
            child: Icon(
              signaling.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            ),
            backgroundColor: signaling.isVideoEnabled
                ? Colors.blue
                : Colors.grey,
          ),
          SizedBox(width: 10),

          // Toggle Audio
          FloatingActionButton(
            heroTag: "toggleAudio",
            mini: true,
            onPressed: () {
              setState(() {
                signaling.toggleAudio();
              });
            },
            child: Icon(signaling.isAudioEnabled ? Icons.mic : Icons.mic_off),
            backgroundColor: signaling.isAudioEnabled
                ? Colors.blue
                : Colors.grey,
          ),
          SizedBox(width: 20),

          // Hang up (Call End)
          FloatingActionButton(
            heroTag: "hangUp",
            onPressed: () {
              signaling.hangUp(_localRenderer);
            },
            child: Icon(Icons.call_end),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WebRTC Demo"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Create Room Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton.icon(
              onPressed: () async {
                roomId = await signaling.createRoom(_remoteRenderer);
                textEditingController.text = roomId!;
                setState(() {});
              },
              icon: Icon(Icons.video_call, color: Colors.green),
              label: Text(
                "Create New Meeting",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ---

          // Video Views (Expanded to take up remaining space)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: RTCVideoView(_localRenderer, mirror: true),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: RTCVideoView(_remoteRenderer),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---

          // Room ID Input and Join Button
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16.0,
              8.0,
              16.0,
              8.0,
            ), // Reduced vertical padding here
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      labelText: "Enter Room ID to Join",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    signaling.joinRoom(
                      textEditingController.text.trim(),
                      _remoteRenderer,
                    );
                  },
                  child: Text("Join"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Bar (Now integrated into the body Column)
          _buildControlBar(),
        ],
      ),
      // floatingActionButton is now null/removed
      floatingActionButton: null,
    );
  }
}
