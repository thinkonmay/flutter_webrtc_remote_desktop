import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_remote_desktop/src/qos/qos.dart';

import 'utils/log.dart';

typedef SendFuncType = void Function(
    {String? target, Map<String, String>? data});
typedef MetricHandlerType = void Function(String target);
typedef TrackHandlerType = dynamic Function(RTCTrackEvent a);
typedef ChannelHandlerType = dynamic Function(RTCDataChannel a);

class WebRTC {
  late String state;
  late RTCPeerConnection conn;
  late Adaptive ads;

  late SendFuncType signalingSendFunc;
  late MetricHandlerType MetricHandler;
  late TrackHandlerType TrackHandler;

  WebRTC(SendFuncType sendFunc, TrackHandlerType trackerHandler,
      ChannelHandlerType channelHandler,
      MetricHandlerType metricHandler
      ) {
    state = "Not setted up";
    this.signalingSendFunc = sendFunc;
    this.MetricHandler = metricHandler;
    this.TrackHandler = trackerHandler;
  }

  SetupConnection(Map<String, dynamic> config) async {
    this.conn = await createPeerConnection(config);
    this.ads = new Adaptive(conn, this.MetricHandler);
    // this.conn.onDataChannel = this.chan
    this.conn.onTrack = this.TrackHandler;
    this.conn.onIceCandidate = this.onICECandidates;
    this.conn.onConnectionState = this.onConnectionStateChange;
    this.state = "Not connected";
  }

  onConnectionStateChange(eve) {
    print("state change to $eve");
    switch (eve) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        LogConnectionEvent(ConnectionEvent.WebRTCConnectionDoneChecking);
        Log(LogLevel.Infor, "webrtc connection established");
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        LogConnectionEvent(ConnectionEvent.WebRTCConnectionClosed);
        Log(LogLevel.Error, "webrtc connection establish failed");
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        LogConnectionEvent(ConnectionEvent.WebRTCConnectionClosed);
        Log(LogLevel.Error, "webrtc connection establish failed");
        break;
      default:
        break;
    }
  }

  /*
     * 
     * @param {*} ice 
     */
  onIncomingICE(RTCIceCandidate ice) async {
    var candidate =
        RTCIceCandidate(ice.candidate, ice.sdpMid, ice.sdpMLineIndex);
    try {
      await conn.addCandidate(candidate);
    } catch (error) {
      // Log(LogLevel.Error,error)  ;
    }
  }

  /*
     * Handles incoming SDP from signalling server.
     * Sets the remote description on the peer connection,
     * creates an answer with a local description and sends that to the peer.
     *
     * @param {RTCSessionDescriptionInit} sdp
    */
  onIncomingSDP(RTCSessionDescription sdp) async {
    if (sdp.type != "offer") {
      return;
    }

    state = "Got SDP offer";

    try {
      var Conn = conn;
      await Conn.setRemoteDescription(sdp);
      var ans = await Conn.createAnswer();
      await onLocalDescription(ans);
    } catch (error) {
      // Log(LogLevel.Error,error);
    }
    ;
  }

  /*
     * Handles local description creation from createAnswer.
     *
     * @param {RTCSessionDescriptionInit} local_sdp
     */
  onLocalDescription(RTCSessionDescription desc) async {
    var Conn = conn;
    await conn.setLocalDescription(desc);

    if (await Conn.getLocalDescription() == null) {
      return;
    }

    var init = await Conn.getLocalDescription();

    var dat = <String, String>{};
    dat["Type"] = init!.type!;
    dat["SDP"] = init.sdp!;
    signalingSendFunc(target: "SDP", data: dat);
  }

  onICECandidates(RTCIceCandidate ev) async {
    if (ev.candidate == null) {
      print("ICE Candidate was null, done");
      return;
    }

    var dat = <String, String>{};
    if (ev.candidate!.isNotEmpty) {
      dat["Candidate"] = ev.candidate!;
    }
    if (ev.sdpMid!.isNotEmpty) {
      dat["SDPMid"] = ev.sdpMid!;
    }
    if (ev.sdpMLineIndex != null) {
      dat["SDPMLineIndex"] = ev.sdpMLineIndex.toString();
    }

    await Future.delayed(const Duration(seconds: 1),
        () => {signalingSendFunc(target: "ICE", data: dat)});
  }
}
