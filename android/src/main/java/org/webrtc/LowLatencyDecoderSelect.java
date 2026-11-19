package org.webrtc;

import java.util.List;

/** Which hardware decoder to use when a chip lists more than one. */
final class LowLatencyDecoderSelect {
  static final class Candidate {
    final String name;
    final boolean advertisesLowLatency;

    Candidate(String name, boolean advertisesLowLatency) {
      this.name = name;
      this.advertisesLowLatency = advertisesLowLatency;
    }
  }

  private LowLatencyDecoderSelect() {}

  /**
   * Some phones list a low-latency instance of a decoder after the standard one; libwebrtc takes
   * the first, so the twin advertising low latency is preferred. -1 when there is none.
   */
  static int pick(List<Candidate> candidates) {
    for (int i = 0; i < candidates.size(); i++) {
      if (candidates.get(i).advertisesLowLatency) return i;
    }
    return candidates.isEmpty() ? -1 : 0;
  }
}
