package com.cloudwebrtc.webrtc;

import android.view.Surface;

/** Where the EGL renderer draws a video track for Flutter to compose. */
interface VideoFrameTarget {
  long id();

  void setSize(int width, int height);

  Surface getSurface();

  /** Called once the EGL surface drawn into {@code surface} is gone, on any thread. */
  void surfaceReleased(Surface surface);

  /** Runs on the main thread when Flutter takes the surface away. */
  void setOnCleanup(Runnable onCleanup);

  void release();
}
