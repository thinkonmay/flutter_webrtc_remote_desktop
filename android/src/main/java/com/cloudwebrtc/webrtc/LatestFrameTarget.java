package com.cloudwebrtc.webrtc;

import android.graphics.ImageFormat;
import android.hardware.HardwareBuffer;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.List;

import io.flutter.view.TextureRegistry;

/**
 * An ImageReader feeding Flutter's single-slot image texture, so the newest decoded frame is
 * the one composed. Flutter's surface producer shows the oldest of two queued frames and leaves
 * acquired images to the garbage collector.
 */
@RequiresApi(29)
final class LatestFrameTarget implements VideoFrameTarget {
  private static final String TAG = "LatestFrameTarget";
  // One image waiting for the engine and two the GPU may still read, as Flutter's producer keeps.
  static final int KEEP = 3;
  // acquireLatestImage needs one free image beyond those held.
  private static final int MAX_IMAGES = KEEP + 2;

  private static final class Held {
    final Image image;
    final ImageReader from;

    Held(Image image, ImageReader from) {
      this.image = image;
      this.from = from;
    }
  }

  private static final class Retired {
    final ImageReader reader;
    boolean surfaceGone;

    Retired(ImageReader reader) {
      this.reader = reader;
    }
  }

  private final TextureRegistry.ImageTextureEntry entry;
  private final Handler main = new Handler(Looper.getMainLooper());
  private final LatestFrameSlot<Held> slot = new LatestFrameSlot<>(KEEP, h -> h.image.close());
  private final Object lock = new Object();
  private final List<Retired> retired = new ArrayList<>();
  private ImageReader reader;
  private int width = 1;
  private int height = 1;
  private boolean released;

  LatestFrameTarget(TextureRegistry.ImageTextureEntry entry) {
    this.entry = entry;
  }

  @Override
  public long id() {
    return entry.id();
  }

  @Override
  public void setSize(int width, int height) {
    synchronized (lock) {
      width = Math.max(1, width);
      height = Math.max(1, height);
      if (width == this.width && height == this.height) {
        return;
      }
      this.width = width;
      this.height = height;
      if (reader != null) {
        retired.add(new Retired(reader));
        reader = null;
      }
    }
  }

  @Override
  public Surface getSurface() {
    synchronized (lock) {
      if (released) {
        throw new IllegalStateException("target released");
      }
      if (reader == null) {
        reader =
            ImageReader.newInstance(
                width, height, ImageFormat.PRIVATE, MAX_IMAGES,
                HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE);
        reader.setOnImageAvailableListener(this::onImageAvailable, main);
      }
      return reader.getSurface();
    }
  }

  private void onImageAvailable(ImageReader from) {
    synchronized (lock) {
      if (released || from != reader) {
        return;
      }
    }
    Image image;
    try {
      image = from.acquireLatestImage();
    } catch (IllegalStateException e) {
      Log.w(TAG, "acquireLatestImage: " + e.getMessage());
      return;
    }
    if (image == null) {
      return;
    }
    entry.pushImage(image);
    slot.push(new Held(image, from));
    closeIdleRetired();
  }

  @Override
  public void surfaceReleased(Surface surface) {
    main.post(
        () -> {
          synchronized (lock) {
            for (Retired r : retired) {
              if (r.reader.getSurface() == surface) {
                r.surfaceGone = true;
              }
            }
          }
          closeIdleRetired();
        });
  }

  // A retired reader closes once nothing draws into it and none of its images is waiting for,
  // or may still be read by, the engine; closing a reader closes its images.
  private void closeIdleRetired() {
    List<ImageReader> done = new ArrayList<>();
    synchronized (lock) {
      for (int i = retired.size() - 1; i >= 0; i--) {
        Retired r = retired.get(i);
        if (r.surfaceGone && !slot.holds(h -> h.from == r.reader)) {
          done.add(r.reader);
          retired.remove(i);
        }
      }
    }
    for (ImageReader r : done) {
      r.close();
    }
  }

  @Override
  public void setOnCleanup(Runnable onCleanup) {}

  @Override
  public void release() {
    Runnable close =
        () -> {
          List<ImageReader> all = new ArrayList<>();
          synchronized (lock) {
            released = true;
            for (Retired r : retired) {
              all.add(r.reader);
            }
            retired.clear();
            if (reader != null) {
              all.add(reader);
              reader = null;
            }
          }
          entry.pushImage(null);
          slot.clear();
          for (ImageReader r : all) {
            r.close();
          }
          entry.release();
        };
    if (Looper.myLooper() == Looper.getMainLooper()) {
      close.run();
    } else {
      main.post(close);
    }
  }
}
