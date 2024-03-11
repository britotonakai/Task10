import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const videoScreen());
}

class videoScreen extends StatefulWidget {
  const videoScreen({super.key});

  @override
  _videoScreenState createState() => _videoScreenState();
}

class _videoScreenState extends State<videoScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRender = RTCVideoRenderer();
  int userCount = 0;
  late MediaStream _localStream;
  static String? videoTrackLabel, videoTrackID;
  static String facingMode = 'user';
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic> mediaConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth':
            '1280', // Provide your own width, height and frame rate here
        'minHeight': '720',
        'minFrameRate': '30',
      },
      'facingMode': facingMode,
      'optional': [],
    },
  };

  @override
  void initState() {
    initRenderers();
    _getUserMedia();
    super.initState();
  }

  @override
  dispose() {
    _localStream.dispose();
    _localRenderer.dispose();
    _remoteRender.dispose();
    super.dispose();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRender.initialize();
  }

  _getUserMedia() async {
    _localStream = await navigator.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

    final vTrack = _localStream.getVideoTracks()[0];
    videoTrackLabel = vTrack.label;

    setState(() {});
    debugPrint('$videoTrackLabel - $videoTrackID');
  }

  Future<void> _switchCamera(Map<String, dynamic> mediaConstraints) async {
    if (_localStream == '') {
      return;
    }
    await _localStream.getTracks().first.stop();
    if (facingMode == 'user') {
      facingMode = 'environment';
    } else {
      facingMode = 'user';
    }
    mediaConstraints['video']['facingMode'] = facingMode;

    try {
      _localStream = await navigator.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
    } catch (error) {}

    debugPrint(facingMode);
  }

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final roomID = (args as dynamic)['roomID'];
    // final List<MediaStreamTrack> _localStreams =
    //     (args as dynamic)['localStreams'];
    // final RTCVideoRenderer localRender = (args as dynamic)['localRender'];
    // final RTCVideoRenderer remoteRender = (args as dynamic)['remoteRender'];
    // // localRender.srcObject = _localStream;
    // remoteRender.srcObject = _localStream;

    // debugPrint("Local Streams: ${_localStreams.length}");

    // final participants = (args as dynamic)['participants'];
    // debugPrint('Participants: $participants');

    return Scaffold(
      appBar: AppBar(
        title: Text('User 1'),
        actions: [
          IconButton(
            onPressed: () async {
              await _switchCamera(mediaConstraints);
            },
            icon: const Icon(Icons.flip_camera_ios_outlined),
            iconSize: 40.0,
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          // return Center(
          //   child: Column(
          //     children: [

          //     ],
          //   ),
          // );
          // return GridView.count(
          //   crossAxisCount: 2,
          //   children: List.generate(
          //       2,
          //       (index) => Stack(
          //             children: [
          //               Container(
          //                 margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          //                 width: MediaQuery.of(context).size.width,
          //                 height: MediaQuery.of(context).size.height,
          //                 decoration: BoxDecoration(color: Colors.black54),
          //                 child: RTCVideoView(_localRenderer, mirror: true),
          //               ),
          //               Align(
          //                 alignment: Alignment.bottomCenter,
          //                 child: Text(
          //                   'Your roomID : $roomID',
          //                   style: const TextStyle(
          //                       fontSize: 25,
          //                       color: Colors.black,
          //                       fontWeight: FontWeight.w600),
          //                 ),
          //               ),
          //             ],
          //           )),
          // );
          return Center(
            child: Stack(
              children: [
                // for (final stream in _localStreams)
                //   RTCVideoView(RTCVideoRenderer(), mirror: true),
                // if (remoteRender != null) RTCVideoView(remoteRender),
                Container(
                  margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Your roomID : $roomID',
                    style: const TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
