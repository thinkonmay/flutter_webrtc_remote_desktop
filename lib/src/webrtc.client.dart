import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as LibWebRTC;
import 'package:flutter_webrtc_remote_desktop/src/model/devices.model.dart'
    as Device;
import 'package:flutter_webrtc/flutter_webrtc.dart' as LibWebRTC;
import 'package:flutter_webrtc_remote_desktop/src/signaling/websocket.dart';
import 'package:flutter_webrtc_remote_desktop/src/webrtc.dart';

import 'datachannel/datachannel.dart';
import 'gui/hid.dart';
import 'utils/log.dart';

typedef AlertType = void Function(String input);
typedef DeviceSelectionType = Future<Device.DeviceSelectionResult> Function(
    Device.DeviceSelection input);

class WebRTCClient {
  late dynamic audio;
  late dynamic video;
  late WebRTC webrtc;
  // final HID hid;
  late SignallingClient signaling;
  late Map<String, DataChannel> datachannels;

  late DeviceSelectionType DeviceSelection;
  late AlertType alert;

  late bool started;

  late HID hid;

  WebRTCClient(
    String signallingURL,
    dynamic audio,
    dynamic vid,
    String token,
    DeviceSelectionType deviceSelection,
  ) {
    Log(LogLevel.Infor, "Started oneplay app with token $signallingURL");
    Log(LogLevel.Infor, "Session token: $token");
    LogConnectionEvent(ConnectionEvent.ApplicationStarted);
    this.started = false;
    this.audio = audio;
    this.video = vid;
    this.DeviceSelection = deviceSelection;
    this.datachannels = new Map<String, DataChannel>();

    this.hid = HID(({data}) {
      var channel = this.datachannels["hid"];
      if (channel == null) {
        return;
      }
      if (data != null) channel.HID.send(LibWebRTC.RTCDataChannelMessage(data));
    });

    signaling = SignallingClient(signallingURL, token,
        ({Map<String, String>? Data}) => handleIncomingPacket(Data!));

    webrtc = WebRTC(({data, target}) {
      SignallingClient signaling = this.signaling;
      signaling.SignallingSend(target!, data!);
    }, (ev) {
      handleIncomingTrack(ev);
    }, (ev) {
      handleIncomingDataChannel(ev);
    }, (ev) {
      handleWebRTCMetric(ev);
    });
  }

  handleIncomingTrack(LibWebRTC.RTCTrackEvent evt) {
    started = true;
    Log(LogLevel.Infor, "Incoming ${evt.track.kind} stream");
    onRemoteStream?.call(evt);
  }

  handleWebRTCMetric(String a) {
    Log(LogLevel.Infor, 'metric : $a');

    const dcName = "adaptive";
    // var channel = this.datachannels.get(dcName);
    // if (channel == null) {
    //     Log(LogLevel.Warning, 'attempting to send message while data channel $dcName is ready');
    //     return;
    // }

    // channel.sendMessage(a);
  }

  handleIncomingDataChannel(LibWebRTC.RTCDataChannel a) {
    LogConnectionEvent(ConnectionEvent.ReceivedDatachannel);
    Log(LogLevel.Infor, "incoming data channel: ${a.label}");
    if (a != LibWebRTC.RTCDataChannel) {
      return;
    }

    this.datachannels[a.label!] = DataChannel(
        a,
        (data) => {
              Log(LogLevel.Debug,
                  "message from data channel ${a.label}: ${data}")
            });
  }

  handleIncomingPacket(Map<String, String> pkt) async {
    var target = pkt["Target"];
    if (target == "SDP") {
      var sdp = pkt["SDP"];
      if (sdp == null) {
        Log(LogLevel.Error, "missing sdp");
        return;
      }
      var type = pkt["Type"];
      if (type == null) {
        Log(LogLevel.Error, "missing sdp type");
        return;
      }

      webrtc.onIncomingSDP(LibWebRTC.RTCSessionDescription(
          sdp, (type == "offer") ? "offer" : "answer"));
    } else if (target == "ICE") {
      var sdpmid = pkt["SDPMid"];
      if (sdpmid == null) {
        Log(LogLevel.Error, "Missing sdp mid field");
      }
      var lineidx = pkt["SDPMLineIndex"];
      if (lineidx == null) {
        Log(LogLevel.Error, "Missing sdp line index field");
        return;
      }
      var can = pkt["Candidate"];
      if (can == null) {
        Log(LogLevel.Error, "Missing sdp candidate field");
        return;
      }

      webrtc.onIncomingICE(
          LibWebRTC.RTCIceCandidate(can, sdpmid, int.parse(lineidx)));
    } else if (target == "PREFLIGHT") {
      //TODO
      var preverro = pkt["Error"];
      if (preverro != null) {
        Log(LogLevel.Error, preverro);
        alert(preverro);
      }

      var webrtcConf = pkt["WebRTCConfig"];
      if (webrtcConf != null) {
        var config = jsonDecode(webrtcConf);
        this.webrtc.SetupConnection(config);
      }

      var i = Device.DeviceSelection(pkt["Devices"]!);
      var result = await DeviceSelection(i);
      var dat = <String, String>{};
      dat["type"] = "answer";
      dat["value"] = result.toString();
      signaling.SignallingSend("PREFLIGHT", dat);
    } else if (target == "START") {
      var dat = <String, String>{};
      signaling.SignallingSend("START", dat);
    }
  }

  WebRTCClient Notifier(void Function(String message) notifier) {
    AddNotifier(notifier);
    return this;
  }

  WebRTCClient Alert(void Function(String message) notifier) {
    alert = notifier;
    return this;
  }

  ChangeFramerate(int framerate) {
    const dcName = "manual";
    var channel = this.datachannels[dcName];
    if (channel == null) {
      Log(LogLevel.Warning,
          'asendMessagettempting to send message while data channel $dcName is ready');
      return;
    }
    channel.HID.send(LibWebRTC.RTCDataChannelMessage(
        jsonEncode({"type": "framerate", "framerate": framerate})));
  }

  ChangeBitrate(int bitrate) {
    const dcName = "manual";
    var channel = this.datachannels["dcName"];
    if (channel == null) {
      Log(LogLevel.Warning,
          'attempting to send message while data channel $dcName is ready');
      return;
    }
    channel.HID.send(LibWebRTC.RTCDataChannelMessage(
        jsonEncode({"type": "bitrate", "bitrate": bitrate})));
  }

  Function(LibWebRTC.RTCTrackEvent stream)? onRemoteStream;
}
