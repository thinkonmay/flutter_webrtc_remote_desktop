import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoMetrics {
  late String type;

  VideoMetrics() {
    type = "video";
  }

  double? frameWidth;
  double? frameHeight;
  String? codecId;
  String? decoderImplementation;

  double? totalSquaredInterFrameDelay;
  double? totalInterFrameDelay;

  double? totalProcessingDelay;
  double? totalDecodeTime;

  double? keyFramesDecoded;
  double? framesDecoded;
  double? framesReceived;

  double? headerBytesReceived;
  double? bytesReceived;
  double? packetsReceived;

  double? framesDropped;
  double? packetsLost;

  double? jitterBufferEmittedCount;
  double? jitterBufferDelay;
  double? jitter;

  double? timestamp;
}

class AudioMetrics {
  late String type;
  AudioMetrics() {
    type = "audio";
  }

  double? audioLevel;
  double? totalAudioEnergy;

  double? totalSamplesReceived;
  double? headerBytesReceived;

  double? bytesReceived;
  double? packetsReceived;

  double? packetsLost;

  double? timestamp;
}

class NetworkMetrics {
  late String type;
  NetworkMetrics() {
    type = "network";
  }

  double? packetsReceived;
  double? packetsSent;
  double? bytesSent;
  double? bytesReceived;
  double? availableIncomingBitrate;
  double? availableOutgoingBitrate;
  double? currentRoundTripTime;
  double? totalRoundTripTime;
  String? localIP;
  double? localPort;
  String? remoteIP;
  double? remotePort;
  double? priority;
  double? timestamp;
}

class Adaptive {
  Adaptive(RTCPeerConnection conn, void Function(String data) metricCallback) {
    this.conn = conn;
    this.running = true;
    this.metricCallback = metricCallback;
    this.startCollectingStat(this.conn);
  }

  late void Function(String data) metricCallback;
  late RTCPeerConnection conn;
  late bool running;

  NetworkMetrics? filterNetwork(List<StatsReport> reports) {
    var remoteCandidate = "";
    var localCandidate = "";
    var CandidatePair = "";

    reports.map((report) {
      var value = report.values["value"];
      var key = report.values["key"];

      if (value["type"] == "candidate-pair" &&
          value["state"] == "succeeded" &&
          value["writable"] == true) {
        remoteCandidate = value["remoteCandidateId"];
        localCandidate = value["localCandidateId"];
        CandidatePair = key;
      }
    });

    if (CandidatePair == "") {
      return null;
    }

    var val = reports[0].values[CandidatePair];

    var ret = NetworkMetrics();

    ret.localIP = reports[0].values[localCandidate]!["ip"];
    ret.remoteIP = reports[0].values[remoteCandidate]!["ip"];

    ret.localPort = reports[0].values[localCandidate]!["port"];
    ret.remotePort = reports[0].values[remoteCandidate]!["port"];

    ret.packetsReceived = val!["packetsReceived"];
    ret.packetsSent = val["packetsSent"];
    ret.bytesSent = val["bytesSent"];
    ret.bytesReceived = val["bytesReceived"];
    ret.availableIncomingBitrate = val["availableIncomingBitrate"];
    ret.availableOutgoingBitrate = val["availableOutgoingBitrate"];
    ret.currentRoundTripTime = val["currentRoundTripTime"];
    ret.totalRoundTripTime = val["totalRoundTripTime"];
    ret.priority = val["priority"];
    ret.timestamp = val["timestamp"];

    return ret;
  }

  VideoMetrics filterVideo(List<StatsReport> reports) {
    var ret = null;
    // reports.forEach((report) {
    //   var val = report.values["value"];
    //   var key = report.values["key"];
    //   if (val["type"] == "inbound-rtp" && val["kind"] == "video") {
    //     ret = VideoMetrics();
    //     ret.frameWidth = val["frameWidth"];
    //     ret.frameHeight = val["frameHeight"];
    //     ret.codecId = val["codecId"];
    //     ret.decoderImplementation = val["decoderImplementation"];
    //     ret.totalSquaredInterFrameDelay = val["totalSquaredInterFrameDelay"];
    //     ret.totalInterFrameDelay = val["totalInterFrameDelay"];
    //     ret.totalProcessingDelay = val["totalProcessingDelay"];
    //     ret.totalDecodeTime = val["totalDecodeTime"];
    //     ret.keyFramesDecoded = val["keyFramesDecoded"];
    //     ret.framesDecoded = val["framesDecoded"];
    //     ret.framesReceived = val["framesReceived"];
    //     ret.headerBytesReceived = val["headerBytesReceived"];
    //     ret.bytesReceived = val["bytesReceived"];
    //     ret.packetsReceived = val["packetsReceived"];
    //     ret.framesDropped = val["framesDropped"];
    //     ret.packetsLost = val["packetsLost"];
    //     ret.jitterBufferEmittedCount = val["jitterBufferEmittedCount"];
    //     ret.jitterBufferDelay = val["jitterBufferDelay"];
    //     ret.jitter = val["jitter"];
    //     ret.timestamp = val["timestamp"];
    //   }
    // });

    return ret;
  }

  AudioMetrics filterAudio(List<StatsReport> reports) {
    var ret = null;
    // reports.forEach((report) {
    //   var val = report.values["value"];
    //   var key = report.values["key"];
    //   if (  ["type"] == "inbound-rtp" && val["kind"] == "audio") {
    //     ret = AudioMetrics();
    //     ret.totalAudioEnergy = val["totalAudioEnergy"];
    //     ret.totalSamplesReceived = val["totalSamplesReceived"];
    //     ret.headerBytesReceived = val["headerBytesReceived"];
    //     ret.bytesReceived = val["bytesReceived"];
    //     ret.packetsReceived = val["packetsReceived"];
    //     ret.packetsLost = val["packetsLost"];
    //     ret.timestamp = val["timestamp"];
    //   }
    // });

    return ret;
  }

  getConnectionStats(RTCPeerConnection conn) async {
    // var result = await conn.getStats();

    // var network = filterNetwork(result);
    // if (network != null) {
    //   metricCallback(jsonEncode(network));
    // }

    // var audio = filterAudio(result);
    // if (audio != null) {
    //   metricCallback(jsonEncode(audio));
    // }

    // var video = filterVideo(result);
    // if (video != null) {
    //   metricCallback(jsonEncode(video));
    // }
  }

  /**
     * 
     */
  startCollectingStat(RTCPeerConnection conn) {
    statsLoop() async {
      await getConnectionStats(conn);
      var timer = Timer(const Duration(milliseconds: 1000), () => statsLoop);
      timer;
    }

    statsLoop();
  }
}
