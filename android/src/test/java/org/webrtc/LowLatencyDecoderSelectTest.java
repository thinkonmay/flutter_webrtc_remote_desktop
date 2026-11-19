package org.webrtc;

import static org.junit.Assert.assertEquals;

import java.util.Arrays;
import org.junit.Test;

public class LowLatencyDecoderSelectTest {
  @Test
  public void theTwinAdvertisingLowLatencyWins() {
    assertEquals(1, LowLatencyDecoderSelect.pick(Arrays.asList(
        new LowLatencyDecoderSelect.Candidate("c2.qti.hevc.decoder", false),
        new LowLatencyDecoderSelect.Candidate("c2.qti.hevc.decoder.low_latency", true))));
  }

  @Test
  public void withNoLowLatencyTwinTheFirstIsKept() {
    assertEquals(0, LowLatencyDecoderSelect.pick(Arrays.asList(
        new LowLatencyDecoderSelect.Candidate("c2.mtk.hevc.decoder", false),
        new LowLatencyDecoderSelect.Candidate("OMX.MTK.VIDEO.DECODER.HEVC", false))));
    assertEquals(-1, LowLatencyDecoderSelect.pick(Arrays.asList()));
  }
}
