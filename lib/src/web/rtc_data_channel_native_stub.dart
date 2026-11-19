import 'dart:typed_data';

import 'package:webrtc_interface/webrtc_interface.dart';

/// The web has no native channel; this keeps the shared export compiling.
abstract class RTCDataChannelNative extends RTCDataChannel {
  void sendBinaryNoWait(Uint8List bytes);
}
