package com.cloudwebrtc.webrtc;

import java.util.ArrayDeque;

/**
 * The images handed to a Flutter image texture, newest last. Flutter's engine takes an image
 * and never closes it, so the slot closes each one once {@code keep} newer ones followed it:
 * one waiting for the engine, and the ones the GPU may still be reading.
 */
final class LatestFrameSlot<T> {
  interface Closer<T> {
    void close(T item);
  }

  interface Match<T> {
    boolean test(T item);
  }

  private final int keep;
  private final Closer<T> closer;
  private final ArrayDeque<T> handed = new ArrayDeque<>();

  LatestFrameSlot(int keep, Closer<T> closer) {
    if (keep < 1) {
      throw new IllegalArgumentException("keep must be at least 1");
    }
    this.keep = keep;
    this.closer = closer;
  }

  synchronized void push(T item) {
    handed.addLast(item);
    while (handed.size() > keep) {
      closer.close(handed.removeFirst());
    }
  }

  synchronized void clear() {
    while (!handed.isEmpty()) {
      closer.close(handed.removeFirst());
    }
  }

  synchronized boolean holds(Match<T> match) {
    for (T item : handed) {
      if (match.test(item)) {
        return true;
      }
    }
    return false;
  }

  synchronized int size() {
    return handed.size();
  }
}
