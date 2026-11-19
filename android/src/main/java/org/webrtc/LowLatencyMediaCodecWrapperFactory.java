package org.webrtc;

import android.media.MediaCodec;
import java.io.IOException;

class LowLatencyMediaCodecWrapperFactory implements MediaCodecWrapperFactory {
  @Override
  public MediaCodecWrapper createByCodecName(String name) throws IOException {
    return new LowLatencyMediaCodecWrapper(MediaCodec.createByCodecName(name));
  }
}
