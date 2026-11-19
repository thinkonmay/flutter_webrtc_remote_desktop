import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/src/native/rtc_data_channel_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const lane = 'FlutterWebRTC/dataChannelSend';
  final frames = <Uint8List>[];

  setUp(() {
    frames.clear();
    RTCDataChannelNative.useSendLane = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(lane, (ByteData? message) async {
      frames.add(message!.buffer.asUint8List(
          message.offsetInBytes, message.lengthInBytes));
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(lane, null);
  });

  ({String pc, String dc, List<int> payload}) decode(Uint8List f) {
    final b = ByteData.sublistView(f);
    final pcLen = b.getUint16(0);
    final pc = utf8.decode(f.sublist(2, 2 + pcLen));
    final dcLen = b.getUint16(2 + pcLen);
    final dcStart = 4 + pcLen;
    final dc = utf8.decode(f.sublist(dcStart, dcStart + dcLen));
    return (pc: pc, dc: dc, payload: f.sublist(dcStart + dcLen));
  }

  test('binary sends go out framed, in order, without waiting on native',
      () async {
    final dc = RTCDataChannelNative('pc-1', 'motion', 1, 'dc-7');
    for (var i = 0; i < 1000; i++) {
      dc.sendBinaryNoWait(Uint8List.fromList([i & 0xFF, i >> 8]));
    }
    await pumpEventQueue();
    expect(frames, hasLength(1000));
    for (var i = 0; i < 1000; i++) {
      final f = decode(frames[i]);
      expect(f.pc, 'pc-1');
      expect(f.dc, 'dc-7');
      expect(f.payload, [i & 0xFF, i >> 8]);
    }
  });
}
