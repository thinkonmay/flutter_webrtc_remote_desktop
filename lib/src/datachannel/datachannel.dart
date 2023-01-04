import 'package:flutter_webrtc/flutter_webrtc.dart';

class DataChannel {
  late RTCDataChannel HID;

  DataChannel(RTCDataChannel chan, void Function(String? data) handler) {
    this.HID = chan;

    this.HID.onMessage = (ev) {
      if (ev.text == "ping") {
        this.HID.send(RTCDataChannelMessage("ping"));
        return;
      }
      handler(ev.text);
    };

    sendMessage(String message) {
      if (this.HID == null) {
        return;
      }

      this.HID.send(RTCDataChannelMessage(message));
    }
  }
}
