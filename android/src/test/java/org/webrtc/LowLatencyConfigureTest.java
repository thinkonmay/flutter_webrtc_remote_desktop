package org.webrtc;

import static org.junit.Assert.assertEquals;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

public class LowLatencyConfigureTest {
  private static Map<String, Integer> set(String... keys) {
    Map<String, Integer> m = new HashMap<>();
    for (String k : keys) m.put(k, 1);
    return m;
  }

  @Test
  public void aRefusedSetIsResetAndTheNextIsTried() {
    List<Map<String, Integer>> ladder = Arrays.asList(set("a", "b"), set("a"), set());
    List<String> log = new ArrayList<>();
    Map<String, Integer> used = LowLatencyConfigure.run(ladder,
        keys -> {
          log.add("configure " + keys.keySet());
          if (keys.containsKey("b")) throw new IllegalArgumentException("unsupported key");
        },
        () -> log.add("reset"));
    assertEquals(set("a"), used);
    assertEquals(Arrays.asList("configure [a, b]", "reset", "configure [a]"), log);
  }

  @Test
  public void theBareFormatIsTheLastTryAndItsFailureIsThrown() {
    List<Map<String, Integer>> ladder = Arrays.asList(set("a"), Collections.emptyMap());
    try {
      LowLatencyConfigure.run(ladder,
          keys -> { throw new IllegalStateException("codec broken"); },
          () -> {});
      throw new AssertionError("expected the last failure");
    } catch (IllegalStateException e) {
      assertEquals("codec broken", e.getMessage());
    }
  }
}
