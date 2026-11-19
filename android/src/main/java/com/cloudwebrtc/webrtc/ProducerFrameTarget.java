package com.cloudwebrtc.webrtc;

import android.view.Surface;

import io.flutter.view.TextureRegistry;

final class ProducerFrameTarget implements VideoFrameTarget {
  private final TextureRegistry.SurfaceProducer producer;

  ProducerFrameTarget(TextureRegistry.SurfaceProducer producer) {
    this.producer = producer;
  }

  @Override
  public long id() {
    return producer.id();
  }

  @Override
  public void setSize(int width, int height) {
    producer.setSize(width, height);
  }

  @Override
  public Surface getSurface() {
    return producer.getSurface();
  }

  @Override
  public void surfaceReleased(Surface surface) {}

  @Override
  public void setOnCleanup(Runnable onCleanup) {
    producer.setCallback(
        new TextureRegistry.SurfaceProducer.Callback() {
          @Override
          public void onSurfaceAvailable() {}

          @Override
          public void onSurfaceCleanup() {
            onCleanup.run();
          }
        });
  }

  @Override
  public void release() {
    producer.release();
  }
}
