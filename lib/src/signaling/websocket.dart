import 'dart:convert';

import 'package:flutter_webrtc_remote_desktop/src/model/signaling.model.dart';
import 'package:flutter_webrtc_remote_desktop/src/utils/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef PacketHandlerType = void Function({Map<String, String> Data});

class SignallingClient {
  late WebSocketChannel WebSocketConnection;
  var PacketHandler;
  // Function()? onOpen;
  Function(dynamic msg)? onMessage;
  Function(int? code, String? reaso)? onClose;

  SignallingClient(String url, String token, PacketHandlerType PacketHandler) {
    this.PacketHandler = PacketHandler;
    LogConnectionEvent(ConnectionEvent.WebSocketConnecting);
    setup(url, token);
  }

  setup(url, token) async {
        WebSocketChannel.connect(Uri.parse("$url?token=$token"));
    // onOpen?.call();
    WebSocketConnection.stream.listen((data) {  
      onServerMessage(data);
    }, onDone: () {
      onClose?.call(
          WebSocketConnection.closeCode, WebSocketConnection.closeReason);
    });
    // WebSocketConnection.onOpen.listen((e) => onServerOpen(e));
  }

  SignallingSend(String Target, Map<String, String> Data) {
    var dat = UserRequest(0, Target, <String, String>{}, Data).toString();
    Log(LogLevel.Debug, "sending message : $dat");
    WebSocketConnection.sink.add(dat);
  }

  /*
     * Fired whenever the signalling websocket emits and error.
     * Reconnects after 3 seconds.
     */
  onServerError() {
    Log(LogLevel.Warning, "websocket connection disconnected");
    LogConnectionEvent(ConnectionEvent.WebSocketDisconnected);
  }

  /*
     * handle message from signalling server during connection handshake
     * @param {Event} event 
     * @returns 
     */
  onServerMessage(event) {
    var msg = jsonDecode(event);
    var response = UserResponse(
        msg['id'], msg['error'], Map<String, String>.from(msg['data']));
    Log(LogLevel.Debug, "received signaling message: ${response.toString()}");
    PacketHandler(Data: response.Data);
  }

  Future<WebSocketChannel> _connectForSelfSignedCert(url) async {
    final WebSocketChannel channel = WebSocketChannel.connect(Uri.parse(url));
    return channel;
  }
}
