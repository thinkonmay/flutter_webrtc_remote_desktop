package org.webrtc;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * The MediaFormat keys that ask a hardware decoder to emit each frame as soon as it can, as a
 * ladder of sets to try in order: a decoder refuses a set it does not know, so each rung drops
 * keys until the bare format, which every decoder takes.
 */
final class LowLatencyDecoderKeys {
  static final String LOW_LATENCY = "low-latency";
  static final String PRIORITY = "priority";
  static final String OPERATING_RATE = "operating-rate";
  private static final int ANDROID_R = 30;

  private LowLatencyDecoderKeys() {}

  static List<Map<String, Integer>> ladder(String codecName, boolean advertisesLowLatency,
      int sdkInt) {
    String name = codecName.toLowerCase(Locale.ROOT);
    boolean qualcomm = name.startsWith("omx.qcom.") || name.startsWith("c2.qti.");
    boolean lowLatencyKey = sdkInt >= ANDROID_R;

    Map<String, Integer> vendor = new LinkedHashMap<>();
    if (qualcomm) {
      vendor.put("vendor.qti-ext-dec-low-latency.enable", 1);
      vendor.put("vendor.qti-ext-dec-picture-order.enable", 1);
    } else if (name.startsWith("omx.hisi.") || name.startsWith("c2.hisi.")) {
      vendor.put("vendor.hisi-ext-low-latency-video-dec.video-scene-for-low-latency-req", 1);
      vendor.put("vendor.hisi-ext-low-latency-video-dec.video-scene-for-low-latency-rdy", -1);
    } else if (name.startsWith("omx.exynos.") || name.startsWith("c2.exynos.")) {
      vendor.put("vendor.rtc-ext-dec-low-latency.enable", 1);
    } else if (name.startsWith("omx.mtk.") || name.startsWith("c2.mtk.")) {
      vendor.put("vdec-lowlatency", 1);
    } else if (name.startsWith("omx.amlogic.") || name.startsWith("c2.amlogic.")) {
      vendor.put("vendor.low-latency.enable", 1);
    }

    // Some Xiaomi Qualcomm phones crash with priority and operating-rate together, so a
    // Qualcomm decoder gets the operating rate and everything else the realtime priority.
    Map<String, Integer> pace = new HashMap<>();
    if (qualcomm) {
      pace.put(OPERATING_RATE, (int) Short.MAX_VALUE);
    } else {
      pace.put(PRIORITY, 0);
    }

    List<Map<String, Integer>> ladder = new ArrayList<>();
    if (advertisesLowLatency && lowLatencyKey) {
      add(ladder, single(LOW_LATENCY, 1));
    }
    Map<String, Integer> full = new LinkedHashMap<>();
    if (lowLatencyKey) full.put(LOW_LATENCY, 1);
    full.putAll(vendor);
    full.putAll(pace);
    add(ladder, full);

    Map<String, Integer> noVendor = new LinkedHashMap<>(full);
    noVendor.keySet().removeAll(vendor.keySet());
    add(ladder, noVendor);

    add(ladder, new LinkedHashMap<>(pace));
    add(ladder, new LinkedHashMap<>());
    return ladder;
  }

  private static Map<String, Integer> single(String key, int value) {
    Map<String, Integer> m = new LinkedHashMap<>();
    m.put(key, value);
    return m;
  }

  private static void add(List<Map<String, Integer>> ladder, Map<String, Integer> rung) {
    if (ladder.isEmpty() || !ladder.get(ladder.size() - 1).equals(rung)) ladder.add(rung);
  }
}
