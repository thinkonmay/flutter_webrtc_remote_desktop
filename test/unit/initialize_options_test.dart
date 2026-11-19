import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/src/native/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('FlutterWebRTC.Method');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    WebRTC.initialized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Map<dynamic, dynamic> sentOptions() =>
      (calls.single.arguments as Map)['options'] as Map;

  test('a well-formed fieldTrials string reaches the native factory as is',
      () async {
    const trials =
        'WebRTC-JitterEstimatorConfig/nack_limit:1000/WebRTC-ForcePlayoutDelay/min_ms:10,max_ms:60/';
    await WebRTC.initialize(options: {'fieldTrials': trials});
    expect(sentOptions()['fieldTrials'], trials);
  });

  test('a malformed fieldTrials string is dropped, and the rest still goes',
      () async {
    for (final bad in ['nack_limit:1000', 'WebRTC-A/x', '/x/', 'A/x/B']) {
      calls.clear();
      WebRTC.initialized = false;
      await WebRTC.initialize(
          options: {'fieldTrials': bad, 'bypassVoiceProcessing': true});
      expect(sentOptions().containsKey('fieldTrials'), isFalse, reason: bad);
      expect(sentOptions()['bypassVoiceProcessing'], isTrue, reason: bad);
    }
  });

  test('no fieldTrials sends no key', () async {
    await WebRTC.initialize(options: {'bypassVoiceProcessing': false});
    expect(sentOptions().containsKey('fieldTrials'), isFalse);
  });
}
