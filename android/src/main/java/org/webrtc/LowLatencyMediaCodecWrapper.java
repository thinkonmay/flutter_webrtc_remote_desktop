package org.webrtc;

import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaCodecInfo.CodecCapabilities;
import android.media.MediaCrypto;
import android.media.MediaFormat;
import android.os.Build;
import android.os.Bundle;
import android.view.Surface;
import java.nio.ByteBuffer;
import java.util.Map;

/** A MediaCodec whose configure asks for low-latency decode, stepping down on refusal. */
class LowLatencyMediaCodecWrapper implements MediaCodecWrapper {
  private static final String TAG = "LowLatencyDecoder";
  private final MediaCodec codec;

  LowLatencyMediaCodecWrapper(MediaCodec codec) {
    this.codec = codec;
  }

  @Override
  public void configure(MediaFormat format, Surface surface, MediaCrypto crypto, int flags) {
    String mime = format.getString(MediaFormat.KEY_MIME);
    Map<String, Integer> used = LowLatencyConfigure.run(
        LowLatencyDecoderKeys.ladder(codec.getName(), advertisesLowLatency(mime), Build.VERSION.SDK_INT),
        keys -> {
          MediaFormat f = copyOf(format);
          for (Map.Entry<String, Integer> key : keys.entrySet()) {
            f.setInteger(key.getKey(), key.getValue());
          }
          codec.configure(f, surface, crypto, flags);
        },
        codec::reset);
    Logging.d(TAG, codec.getName() + " configured with " + used.keySet());
  }

  private boolean advertisesLowLatency(String mime) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R || mime == null) return false;
    try {
      return codec.getCodecInfo().getCapabilitiesForType(mime)
          .isFeatureSupported(CodecCapabilities.FEATURE_LowLatency);
    } catch (RuntimeException e) {
      return false;
    }
  }

  // MediaFormat can drop a key only from API 29, so older phones get a rebuilt copy of the
  // keys libwebrtc sets: the type, the size and, without a surface, the colour format.
  private static MediaFormat copyOf(MediaFormat format) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) return new MediaFormat(format);
    MediaFormat f = MediaFormat.createVideoFormat(format.getString(MediaFormat.KEY_MIME),
        format.getInteger(MediaFormat.KEY_WIDTH), format.getInteger(MediaFormat.KEY_HEIGHT));
    if (format.containsKey(MediaFormat.KEY_COLOR_FORMAT)) {
      f.setInteger(MediaFormat.KEY_COLOR_FORMAT, format.getInteger(MediaFormat.KEY_COLOR_FORMAT));
    }
    return f;
  }

  @Override public void start() { codec.start(); }
  @Override public void flush() { codec.flush(); }
  @Override public void stop() { codec.stop(); }
  @Override public void release() { codec.release(); }
  @Override public int dequeueInputBuffer(long timeoutUs) { return codec.dequeueInputBuffer(timeoutUs); }

  @Override
  public void queueInputBuffer(int index, int offset, int size, long presentationTimeUs, int flags) {
    codec.queueInputBuffer(index, offset, size, presentationTimeUs, flags);
  }

  @Override
  public int dequeueOutputBuffer(MediaCodec.BufferInfo info, long timeoutUs) {
    return codec.dequeueOutputBuffer(info, timeoutUs);
  }

  @Override public void releaseOutputBuffer(int index, boolean render) { codec.releaseOutputBuffer(index, render); }
  @Override public MediaFormat getInputFormat() { return codec.getInputFormat(); }
  @Override public MediaFormat getOutputFormat() { return codec.getOutputFormat(); }
  @Override public MediaFormat getOutputFormat(int index) { return codec.getOutputFormat(index); }
  @Override public ByteBuffer getInputBuffer(int index) { return codec.getInputBuffer(index); }
  @Override public ByteBuffer getOutputBuffer(int index) { return codec.getOutputBuffer(index); }
  @Override public Surface createInputSurface() { return codec.createInputSurface(); }
  @Override public void setParameters(Bundle params) { codec.setParameters(params); }
  @Override public MediaCodecInfo getCodecInfo() { return codec.getCodecInfo(); }
}
