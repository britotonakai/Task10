import 'package:firebase_auth/firebase_auth.dart';
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
      'facingMode': 'user',
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

  // Widget participant(List<RTCVideoRenderer> listRender) {
  //   switch (listRender.length) {
  //     case 2:
  //       return Stack(children: [
  //         Align(
  //           alignment: Alignment.topCenter,
  //           child: Text(
  //             '$userName',
  //             style: const TextStyle(
  //                 fontSize: 25,
  //                 color: Colors.black,
  //                 fontWeight: FontWeight.w600),
  //           ),
  //         ),
  //         Container(
  //           margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
  //           width: MediaQuery.of(context).size.width,
  //           height: MediaQuery.of(context).size.height,
  //           decoration: const BoxDecoration(color: Colors.black54),
  //           child: RTCVideoView(listRender[0], mirror: true),
  //         ),
  //         Positioned(
  //           top: 0.0,
  //           left: 0.0,
  //           child: RTCVideoView(listRender[1], mirror: true),
  //         ),
  //       ]);
  //     case 3 || 5:
  //       return Column(
  //         children: [
  //           Container(
  //             margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
  //             width: MediaQuery.of(context).size.width,
  //             height: MediaQuery.of(context).size.height,
  //             decoration: const BoxDecoration(color: Colors.black54),
  //             child: RTCVideoView(listRender[0], mirror: true),
  //           ),
  //           Row(
  //             children: [
  //               GridView.builder(
  //                 itemCount: listRender.length,
  //                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                   crossAxisCount: 2,
  //                 ),
  //                 itemBuilder: (context, index) {
  //                   index == 1;
  //                   return Container(
  //                     margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
  //                     width: MediaQuery.of(context).size.width,
  //                     height: MediaQuery.of(context).size.height,
  //                     child: RTCVideoView(listRender[index], mirror: true),
  //                   );
  //                 },
  //               ),
  //             ],
  //           ),
  //         ],
  //       );
  //     case 6:
  //       return GridView.builder(
  //         itemCount: listRender.length,
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 2,
  //         ),
  //         itemBuilder: (context, index) {
  //           return Container(
  //             margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
  //             width: MediaQuery.of(context).size.width,
  //             height: MediaQuery.of(context).size.height,
  //             child: RTCVideoView(listRender[index], mirror: true),
  //           );
  //         },
  //       );
  //     default:
  //       return GridView.builder(
  //         itemCount: listRender.length,
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 2,
  //         ),
  //         itemBuilder: (context, index) {
  //           return Container(
  //             margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
  //             width: MediaQuery.of(context).size.width,
  //             height: MediaQuery.of(context).size.height,
  //             child: RTCVideoView(listRender[index], mirror: true),
  //           );
  //         },
  //       );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final roomID = (args as dynamic)['roomID'];
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName;
    final userURL = user?.photoURL;

    List<RTCVideoRenderer> listRender = (args as dynamic)['listRender'];
    // RTCVideoRenderer localRender = (args as dynamic)['localRender'];
    // RTCVideoRenderer remoteRender = (args as dynamic)['remoteRender'];

    // if (remoteRender.isNull) {
    //   remoteRender = RTCVideoRenderer();
    // }

    // debugPrint("Local Streams: ${_localStreams.length}");

    // final participants = (args as dynamic)['participants'];
    // debugPrint('Participants: $participants');
    switch (listRender.length) {
      case 2:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '$userName',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            backgroundColor: Colors.white10,
            actions: [
              IconButton(
                onPressed: () {
                  _switchCamera(mediaConstraints);
                },
                icon: const Icon(Icons.cameraswitch_outlined),
              ),
            ],
          ),
          body: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(0.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(color: Colors.black54),
                child: RTCVideoView(listRender[0], mirror: true),
              ),
              Positioned(
                top: 0.0,
                right: 0.0,
                child: Container(
                  margin: const EdgeInsets.all(0.0),
                  width: 300,
                  height: 150,
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(listRender[1], mirror: true),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Your roomID : $roomID',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        );
      case 3 || 5:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Your room ID: $roomID",
              style: const TextStyle(fontSize: 20, color: Colors.black),
            ),
            backgroundColor: Colors.white10,
          ),
          // body: GridView.builder(
          //   itemCount: listRender.length,
          //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 2,
          //   ),
          //   itemBuilder: (context, index) {
          //     return Stack(
          //       children: [
          //         Container(
          //           margin: const EdgeInsets.all(0.0),
          //           width: MediaQuery.of(context).size.width,
          //           height: MediaQuery.of(context).size.height,
          //           decoration: const BoxDecoration(color: Colors.black54),
          //           child: RTCVideoView(listRender[index], mirror: true),
          //         ),
          //         Align(
          //           alignment: Alignment.bottomCenter,
          //           child: Text(
          //             '$userName',
          //             style: const TextStyle(
          //                 fontSize: 14,
          //                 color: Colors.black,
          //                 fontWeight: FontWeight.w500),
          //           ),
          //         ),
          //       ],
          //     );
          //   },
          // ),
          body: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(0.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(color: Colors.black54),
                child: RTCVideoView(listRender[0], mirror: true),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                height: MediaQuery.of(context).size.height / 2,
                child: (listRender.length > 1)
                    ? Row(
                        // Two smaller videos for participants > 1
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(0.0),
                            width: MediaQuery.of(context).size.width / 2,
                            height: MediaQuery.of(context).size.height /
                                4, // Quarter of screen height
                            decoration:
                                const BoxDecoration(color: Colors.black54),
                            child: RTCVideoView(listRender[1], mirror: true),
                          ),
                          Container(
                            margin: const EdgeInsets.all(0.0),
                            width: MediaQuery.of(context).size.width / 2,
                            height: MediaQuery.of(context).size.height / 4,
                            decoration:
                                const BoxDecoration(color: Colors.black54),
                            child: RTCVideoView(listRender[2], mirror: true),
                          ),
                        ],
                      )
                    : Container(),
              ),
            ],
          ),
        );
      case 4 || 6:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Your room ID: $roomID",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            backgroundColor: Colors.white10,
          ),
          body: GridView.builder(
            itemCount: listRender.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(0.0),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: RTCVideoView(listRender[index], mirror: true),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      '$userName',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      case > 6:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Your room ID: $roomID",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            backgroundColor: Colors.white10,
          ),
          body: GridView.builder(
            itemCount: listRender.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(0.0),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: RTCVideoView(listRender[index], mirror: true),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      '$userName',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      default:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '$userName',
              style: const TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.normal),
            ),
            backgroundColor: Colors.white10,
          ),
          body: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(0.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(color: Colors.black54),
                child: RTCVideoView(listRender[0], mirror: true),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Your roomID : $roomID',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
    }
  }
}
