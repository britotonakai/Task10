import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'package:task10_call/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  runApp(const mainScreen());
}

class mainScreen extends StatefulWidget {
  const mainScreen({super.key});

  @override
  _mainScreenState createState() => _mainScreenState();
}

class _mainScreenState extends State<mainScreen> {
  late TextEditingController idController; // lấy id phòng
  late RTCPeerConnection peerConnection,
      tempPeerConnection; // tạo peer connection
  final _localStreams =
      <MediaStreamTrack>[]; // danh sách chứa media stream cho video và audio
  // final _offerCandidates = <RTCIceCandidate>[]; // danh sách chứa ICE candidate
  final _iceStream = StreamController<RTCIceCandidate>();
  // quản lý luồng của ICE candidate
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  // kết nối firebase
  var uuid = const Uuid(); //thư viện random
  String roomID = '';
  late RTCSessionDescription answer;
  late List<RTCIceCandidate> candidates;
  late MediaStream _localStream, _remoteStream;
  late final RTCVideoRenderer _localRender = RTCVideoRenderer();
  late final RTCVideoRenderer _remoteRender = RTCVideoRenderer();
  List<RTCVideoRenderer> _remoteRenderers = [];

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

  static const Map<String, dynamic> _configuration = {
    // ice server
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  @override
  dispose() {
    // hàm hủy bỏ
    super.dispose();
    idController.dispose();
    peerConnection.dispose();
    _localRender.dispose();
    _remoteRender.dispose();
    _iceStream.close();
  }

  @override
  void initState() {
    // hàm khởi tạo
    super.initState();
    idController = TextEditingController();
    _localRender.initialize();
    _remoteRender.initialize();
    _iceStream.stream
        .listen((candidate) => _sendIceCandidate(candidate, roomID));
    // lắng nghe các candidate
  }

  Map<String, dynamic> _createJsonOffer(RTCSessionDescription offer) {
    return {
      'type': 'offer',
      'sdp': offer.sdp,
    };
  }

  Future<void> _createPeerConnection() async {
    //tạo peer connection
    peerConnection = await createPeerConnection(
        _configuration); //tạo một peer connection object

    _listenForIceCandidates(peerConnection, roomID);
  }

  Future<String> _createRoom() async {
    String roomID = uuid.v4();

    await firestore.collection('rooms').doc(roomID).set({
      'id': roomID,
    });

    return roomID;
  }

  Future<void> _startVideoCall() async {
    await _createPeerConnection();

    final newRoomID = await _createRoom();
    debugPrint('createRoom : $newRoomID');

    RTCSessionDescription offer = await _createOffer(newRoomID);

    peerConnection.onIceCandidate = ((RTCIceCandidate newCandidate) async {
      await _sendIceCandidate(newCandidate, newRoomID);
    });

    await peerConnection.setLocalDescription(offer);

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localRender.srcObject = _localStream;
    _localStreams.add(_localStream.getTracks().first);
    _remoteRenderers.add(_localRender);

    // peerConnection.onAddStream = (mediaStream) {
    //   setState(() {
    //     _localStreams.add(mediaStream.getTracks().first);
    //     _localRender.srcObject = mediaStream;
    //   });
    // };

    Navigator.pushNamed(context, '/video', arguments: {
      'roomID': newRoomID,
      'listRender': _remoteRenderers,
      // 'remoteRender': _remoteRender,
      // 'localRender': _localRender,
      'localStreams': _localStreams,
    });
  }

  Future<void> _joinRoom(String roomID) async {
    final roomRef = firestore.collection('rooms').doc(roomID);
    final roomDOC = await roomRef.get();

    if (!roomDOC.exists) {
      throw Exception('Room not found!');
    }

    final offerSDP = roomDOC.data()!['sdp'];
    final offerType = roomDOC.data()!['type'];

    // debugPrint('$offerSDP - $offerType');
    await _createPeerConnection();

    _remoteStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // joinPeerConnection = await _createPeerConnection();

    if (offerSDP == null || offerType == null) {
      throw Exception('Offer not found!');
    }

    final offer = RTCSessionDescription(offerSDP, offerType);
    await peerConnection.setRemoteDescription(offer);
    _handleRemoteAnswer(peerConnection, offerSDP, offerType, roomID);

    debugPrint('roomID in JoinRoom: $roomID');

    peerConnection.onIceCandidate = ((RTCIceCandidate newCandidate) async {
      await _sendIceCandidate(newCandidate, roomID);
    });

    _remoteRender.srcObject = _remoteStream;
    _localStreams.add(_remoteStream.getTracks().first);
    _remoteRenderers.add(_remoteRender);

    peerConnection.onAddStream = (mediaStream) {
      setState(() {
        _localStreams.add(mediaStream.getTracks().first);
        _localRender.srcObject = mediaStream;
      });
    };

    await firestore.collection('rooms').doc(roomID).update(
      {'participants': _localStreams.length},
    );
    Navigator.pushNamed(context, '/video', arguments: {
      'roomID': roomID,
      'listRender': _remoteRenderers,
      // 'remoteRender': _remoteRender,
      // 'localRender': _localRender,
      'localStreams': _localStreams,
    });
  }

  Future<void> _sendIceCandidate(
      RTCIceCandidate candidate, String roomID) async {
    final Map<String, dynamic> jsonCandidate = candidate.toMap();

    final user = FirebaseAuth.instance.currentUser;
    final userID = user?.uid;

    debugPrint('roomID in _sendIceCandidate : $roomID');
    // debugPrint('Candidate data:');
    // debugPrint(jsonCandidate.toString());
    jsonCandidate['userID'] = userID;

    try {
      await firestore.collection('rooms').doc(roomID).update({
        'candidate': FieldValue.arrayUnion([jsonCandidate]),
      });
      debugPrint('Candidate sent successfully!');
    } on FirebaseException catch (e) {
      debugPrint('Error sending candidate: ${e.message}');
      // Handle Firebase error (e.g., permission denied, network issue)
    } catch (e) {
      debugPrint('Unexpected error sending candidate: $e');
      // Handle other errors
    }
  }

  void _listenForIceCandidates(
      RTCPeerConnection peerConnection, String roomID) {
    peerConnection.onIceCandidate = ((RTCIceCandidate candidate) {
      _sendIceCandidate(candidate, roomID);
    });
  }

  Future<RTCSessionDescription> _createOffer(String roomID) async {
    RTCSessionDescription offer = await peerConnection.createOffer(
      //tạo sdp offer
      {
        'iceRestart': true,
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true
      },
    );
    await peerConnection.setLocalDescription(offer);
    //gán sdp làm local description

    final Map<String, dynamic> jsonOffer = _createJsonOffer(offer);

    await firestore.collection('rooms').doc(roomID).set(jsonOffer);

    return offer; //trả về offer
  }

  void _handleRemoteAnswer(RTCPeerConnection answerPeerConnection,
      String offerSDP, String offerType, String roomID) async {
    // Reuse existing function
    await answerPeerConnection
        .setRemoteDescription(RTCSessionDescription(offerSDP, offerType));
    final answer = await answerPeerConnection.createAnswer();
    await answerPeerConnection.setLocalDescription(answer);

    await firestore.collection('rooms').doc(roomID).update({
      'answerSDP': answer.sdp,
      'answerType': 'answer',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/loginBG.jpg'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/videoCall.png',
              height: 300,
              width: 300,
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () async {
                await _startVideoCall();
              },
              child: const Text(
                'Start a video call',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.keyboard),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 300,
                  height: 48,
                  child: TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  onPressed: () async {
                    final enteredRoomID = idController.text;
                    await _joinRoom(enteredRoomID);
                  },
                  child: const Text(
                    'Join a video call',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
