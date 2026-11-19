package org.webrtc;

import java.util.List;
import java.util.Map;

/** Runs a key ladder against a decoder's configure, resetting it after each refusal. */
final class LowLatencyConfigure {
  interface Attempt {
    void configure(Map<String, Integer> keys);
  }

  private LowLatencyConfigure() {}

  /** The key set that configured; the last rung's failure is rethrown. */
  static Map<String, Integer> run(List<Map<String, Integer>> ladder, Attempt attempt,
      Runnable reset) {
    RuntimeException last = null;
    for (int i = 0; i < ladder.size(); i++) {
      Map<String, Integer> keys = ladder.get(i);
      try {
        attempt.configure(keys);
        return keys;
      } catch (RuntimeException e) {
        last = e;
        if (i < ladder.size() - 1) reset.run();
      }
    }
    if (last != null) throw last;
    throw new IllegalArgumentException("empty ladder");
  }
}
