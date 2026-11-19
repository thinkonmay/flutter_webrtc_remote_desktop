package org.webrtc;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.util.List;
import java.util.Map;
import org.junit.Test;

public class LowLatencyDecoderKeysTest {
  private static final int R = 30;
  private static final int Q = 29;

  private static boolean neverBoth(List<Map<String, Integer>> ladder) {
    for (Map<String, Integer> set : ladder) {
      if (set.containsKey("priority") && set.containsKey("operating-rate")) return false;
    }
    return true;
  }

  @Test
  public void mediatekGetsItsKeyAndRealtimePriority() {
    List<Map<String, Integer>> ladder = LowLatencyDecoderKeys.ladder("c2.mtk.hevc.decoder", false, R);
    Map<String, Integer> first = ladder.get(0);
    assertEquals(Integer.valueOf(1), first.get("vdec-lowlatency"));
    assertEquals(Integer.valueOf(1), first.get("low-latency"));
    assertEquals(Integer.valueOf(0), first.get("priority"));
    assertFalse(first.containsKey("operating-rate"));
    assertTrue(ladder.get(ladder.size() - 1).isEmpty());
    assertTrue(neverBoth(ladder));
  }

  @Test
  public void qualcommGetsOperatingRateNotPriority() {
    for (String name : new String[] {"c2.qti.avc.decoder", "OMX.qcom.video.decoder.hevc"}) {
      Map<String, Integer> first = LowLatencyDecoderKeys.ladder(name, false, R).get(0);
      assertEquals(name, Integer.valueOf(1), first.get("vendor.qti-ext-dec-low-latency.enable"));
      assertEquals(name, Integer.valueOf(1), first.get("vendor.qti-ext-dec-picture-order.enable"));
      assertEquals(name, Integer.valueOf(Short.MAX_VALUE), first.get("operating-rate"));
      assertFalse(name, first.containsKey("priority"));
      assertTrue(neverBoth(LowLatencyDecoderKeys.ladder(name, false, R)));
    }
  }

  @Test
  public void eachVendorGetsItsOwnKey() {
    assertEquals(Integer.valueOf(1), LowLatencyDecoderKeys.ladder("c2.exynos.hevc.decoder", false, R)
        .get(0).get("vendor.rtc-ext-dec-low-latency.enable"));
    assertEquals(Integer.valueOf(1), LowLatencyDecoderKeys.ladder("c2.amlogic.avc.decoder", false, R)
        .get(0).get("vendor.low-latency.enable"));
    Map<String, Integer> kirin = LowLatencyDecoderKeys.ladder("OMX.hisi.video.decoder.avc", false, R).get(0);
    assertEquals(Integer.valueOf(1),
        kirin.get("vendor.hisi-ext-low-latency-video-dec.video-scene-for-low-latency-req"));
    assertEquals(Integer.valueOf(-1),
        kirin.get("vendor.hisi-ext-low-latency-video-dec.video-scene-for-low-latency-rdy"));
  }

  @Test
  public void aDecoderAdvertisingLowLatencyIsTriedWithThatKeyAlone() {
    List<Map<String, Integer>> ladder = LowLatencyDecoderKeys.ladder("c2.qti.hevc.decoder", true, R);
    assertEquals(1, ladder.get(0).size());
    assertEquals(Integer.valueOf(1), ladder.get(0).get("low-latency"));
  }

  @Test
  public void beforeAndroid11ThereIsNoLowLatencyKey() {
    for (Map<String, Integer> set : LowLatencyDecoderKeys.ladder("c2.mtk.avc.decoder", true, Q)) {
      assertFalse(set.containsKey("low-latency"));
    }
  }

  @Test
  public void anUnknownVendorStillGetsPriorityAndEndsBare() {
    List<Map<String, Integer>> ladder = LowLatencyDecoderKeys.ladder("c2.unisoc.hevc.decoder", false, R);
    assertEquals(Integer.valueOf(0), ladder.get(0).get("priority"));
    assertTrue(ladder.get(ladder.size() - 1).isEmpty());
    for (int i = 1; i < ladder.size(); i++) {
      assertFalse("no repeated rung", ladder.get(i).equals(ladder.get(i - 1)));
    }
  }
}
