package com.cloudwebrtc.webrtc;

import androidx.annotation.Nullable;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * One binary send on the background data-channel lane: a big-endian u16 length and the peer
 * connection id, a u16 length and the data channel id, then the payload.
 */
final class DataChannelSendFrame {
  final String peerConnectionId;
  final String dataChannelId;
  final ByteBuffer payload;

  private DataChannelSendFrame(String peerConnectionId, String dataChannelId, ByteBuffer payload) {
    this.peerConnectionId = peerConnectionId;
    this.dataChannelId = dataChannelId;
    this.payload = payload;
  }

  @Nullable
  static DataChannelSendFrame parse(@Nullable ByteBuffer message) {
    if (message == null) return null;
    ByteBuffer b = message.duplicate();
    String pc = readId(b);
    if (pc == null) return null;
    String dc = readId(b);
    if (dc == null) return null;
    return new DataChannelSendFrame(pc, dc, b.slice());
  }

  @Nullable
  private static String readId(ByteBuffer b) {
    if (b.remaining() < 2) return null;
    int len = b.getShort() & 0xFFFF;
    if (len == 0 || b.remaining() < len) return null;
    byte[] id = new byte[len];
    b.get(id);
    return new String(id, StandardCharsets.UTF_8);
  }
}
