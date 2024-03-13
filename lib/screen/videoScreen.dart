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

  Widget roomIDDisplay(String roomID) {
    return Text(
      'Your roomID : $roomID',
      style: const TextStyle(
          fontSize: 15, color: Colors.black, fontWeight: FontWeight.w600),
    );
  }

  Widget usernameDisplay(String? userName) {
    return Text(
      '$userName',
      style: const TextStyle(fontSize: 20, color: Colors.white),
    );
  }

  Widget actionBar(userURL, userName) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(20.0),
        ),
        width: 220,
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.mic_off_outlined,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white,
              ),
            ),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.red[400],
              child: const Icon(
                Icons.call_outlined,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.volume_up_outlined,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.black54,
                      title: const Text(
                        'Invite more friend',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      content: SizedBox(
                        height: 500,
                        width: 250,
                        child: ListView.builder(
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                const Divider(
                                  color: Colors.white,
                                ),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: NetworkImage(userURL!),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '$userName',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.left,
                                        ),
                                        const Text(
                                          'Online now',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 80,
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(Icons.circle),
                                      color: Colors.green[400],
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            title: roomIDDisplay(roomID),
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
                child: Stack(
                  children: [
                    RTCVideoView(listRender[0], mirror: true),
                    Align(
                      alignment: Alignment.topLeft,
                      child: usernameDisplay(userName),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: actionBar(userURL, userName),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0.0,
                right: 0.0,
                child: Container(
                  margin: const EdgeInsets.all(0.0),
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 4,
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: Stack(
                    children: [
                      RTCVideoView(listRender[1], mirror: true),
                      Align(
                        alignment: Alignment.topRight,
                        child: usernameDisplay(userName),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 3:
        return Scaffold(
          appBar: AppBar(
            title: roomIDDisplay(roomID),
            backgroundColor: Colors.white10,
          ),
          body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(color: Colors.black54),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(0.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 1.5,
                      child: Stack(
                        children: [
                          RTCVideoView(listRender[0], mirror: true),
                          Align(
                            alignment: Alignment.topLeft,
                            child: usernameDisplay(userName),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[1], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[2], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    actionBar(userURL, userName),
                  ],
                ),
              );
            },
          ),
        );
      case 5:
        return Scaffold(
          appBar: AppBar(
            title: roomIDDisplay(roomID),
            backgroundColor: Colors.white10,
          ),
          body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(color: Colors.black54),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(0.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 1.5,
                      child: Stack(
                        children: [
                          RTCVideoView(listRender[0], mirror: true),
                          Align(
                            alignment: Alignment.topLeft,
                            child: usernameDisplay(userName),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[1], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[2], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[3], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[4], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    actionBar(userURL, userName),
                  ],
                ),
              );
            },
          ),
        );
      case 4 || 6:
        return Scaffold(
          appBar: AppBar(
            title: roomIDDisplay(roomID),
            backgroundColor: Colors.white10,
          ),
          body: Container(
            decoration: const BoxDecoration(color: Colors.black54),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                GridView.builder(
                  itemCount: listRender.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(0.0),
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height / 4,
                      child: Stack(
                        children: [
                          RTCVideoView(listRender[index], mirror: true),
                          Align(
                            alignment: Alignment.topLeft,
                            child: usernameDisplay(userName),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: actionBar(userURL, userName),
                ),
              ],
            ),
          ),
        );
      case > 6:
        return Scaffold(
          appBar: AppBar(
            title: roomIDDisplay(roomID),
            backgroundColor: Colors.white10,
          ),
          body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(color: Colors.black54),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[0], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[1], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[3], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[4], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: Stack(
                            children: [
                              RTCVideoView(listRender[5], mirror: true),
                              Align(
                                alignment: Alignment.topLeft,
                                child: usernameDisplay(userName),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(0.0),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration:
                              const BoxDecoration(color: Colors.black54),
                          child: GridView.builder(
                            scrollDirection: Axis.vertical,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                            ),
                            itemCount: (listRender.length - 5),
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundImage: NetworkImage(userURL!),
                                  ),
                                  Text(
                                    '$userName',
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    actionBar(userURL, userName),
                  ],
                ),
              );
            },
          ),
        );
      default:
        return Scaffold(
          appBar: AppBar(
            title: roomIDDisplay(roomID),
            backgroundColor: Colors.white10,
          ),
          body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(color: Colors.black54),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(0.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Stack(
                        children: [
                          RTCVideoView(listRender[0], mirror: true),
                          Align(
                            alignment: Alignment.topLeft,
                            child: usernameDisplay(userName),
                          ),
                        ],
                      ),
                    ),
                    actionBar(userURL, userName),
                  ],
                ),
              );
            },
          ),
        );
    }
  }
}
