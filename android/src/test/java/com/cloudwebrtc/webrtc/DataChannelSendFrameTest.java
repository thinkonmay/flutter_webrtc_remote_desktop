package com.cloudwebrtc.webrtc;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import org.junit.Test;

public class DataChannelSendFrameTest {
  private static ByteBuffer frame(String pc, String dc, byte[] payload) {
    byte[] p = pc.getBytes(StandardCharsets.UTF_8);
    byte[] d = dc.getBytes(StandardCharsets.UTF_8);
    ByteBuffer b = ByteBuffer.allocate(4 + p.length + d.length + payload.length);
    b.putShort((short) p.length).put(p).putShort((short) d.length).put(d).put(payload);
    b.flip();
    return b;
  }

  @Test
  public void parsesIdsAndPayload() {
    DataChannelSendFrame f =
        DataChannelSendFrame.parse(frame("pc-1", "dc-2", new byte[] {7, 8, 9}));
    assertEquals("pc-1", f.peerConnectionId);
    assertEquals("dc-2", f.dataChannelId);
    byte[] out = new byte[f.payload.remaining()];
    f.payload.get(out);
    assertArrayEquals(new byte[] {7, 8, 9}, out);
  }

  @Test
  public void emptyPayloadIsAllowed() {
    assertEquals(0, DataChannelSendFrame.parse(frame("a", "b", new byte[0])).payload.remaining());
  }

  @Test
  public void truncatedOrOverlongFramesAreRefused() {
    assertNull(DataChannelSendFrame.parse(null));
    assertNull(DataChannelSendFrame.parse(ByteBuffer.allocate(1)));
    ByteBuffer overlong = ByteBuffer.allocate(4);
    overlong.putShort((short) 200).putShort((short) 0);
    overlong.flip();
    assertNull(DataChannelSendFrame.parse(overlong));
    ByteBuffer noDcLength = ByteBuffer.allocate(3);
    noDcLength.putShort((short) 1).put((byte) 'a');
    noDcLength.flip();
    assertNull(DataChannelSendFrame.parse(noDcLength));
    assertNull(DataChannelSendFrame.parse(frame("", "dc", new byte[] {1})));
  }
}
