package com.cloudwebrtc.webrtc;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.Test;

public class LatestFrameSlotTest {
  private final List<Integer> closed = new ArrayList<>();
  private final LatestFrameSlot<Integer> slot = new LatestFrameSlot<>(3, closed::add);

  @Test
  public void keepsTheNewestThreeOpen() {
    for (int i = 1; i <= 3; i++) {
      slot.push(i);
    }
    assertTrue(closed.isEmpty());
    assertEquals(3, slot.size());
  }

  @Test
  public void closesTheOldestOnceThreeNewerFollowedIt() {
    for (int i = 1; i <= 5; i++) {
      slot.push(i);
    }
    assertEquals(Arrays.asList(1, 2), closed);
    assertEquals(3, slot.size());
  }

  @Test
  public void clearClosesEverythingOldestFirst() {
    slot.push(1);
    slot.push(2);
    slot.clear();
    assertEquals(Arrays.asList(1, 2), closed);
    assertEquals(0, slot.size());
  }

  @Test
  public void holdsAnswersForItemsStillOpenOnly() {
    for (int i = 1; i <= 4; i++) {
      slot.push(i);
    }
    assertFalse(slot.holds(i -> i == 1));
    assertTrue(slot.holds(i -> i == 2));
  }

  @Test(expected = IllegalArgumentException.class)
  public void refusesAnEmptyWindow() {
    new LatestFrameSlot<Integer>(0, i -> {});
  }
}
