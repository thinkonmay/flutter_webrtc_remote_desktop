package org.webrtc;

import android.media.MediaCodecInfo;
import android.media.MediaCodecInfo.CodecCapabilities;
import android.media.MediaCodecList;
import android.os.Build;
import androidx.annotation.Nullable;
import java.util.ArrayList;
import java.util.List;

/**
 * libwebrtc's hardware decoder factory with three changes for a game stream: the decoder is asked
 * for low-latency output, a low-latency twin is preferred, and OMX.qcom/OMX.hisi decoders render
 * to a texture instead of being copied through the CPU.
 */
public class LowLatencyVideoDecoderFactory implements VideoDecoderFactory {
  private final @Nullable EglBase.Context sharedContext;
  private final HardwareVideoDecoderFactory advertised;

  public LowLatencyVideoDecoderFactory(@Nullable EglBase.Context sharedContext) {
    this.sharedContext = sharedContext;
    this.advertised = new HardwareVideoDecoderFactory(sharedContext);
  }

  @Override
  public VideoCodecInfo[] getSupportedCodecs() {
    return advertised.getSupportedCodecs();
  }

  @Nullable
  @Override
  public VideoDecoder createDecoder(VideoCodecInfo codecInfo) {
    VideoCodecMimeType type = VideoCodecMimeType.valueOf(codecInfo.getName());
    List<MediaCodecInfo> infos = new ArrayList<>();
    List<LowLatencyDecoderSelect.Candidate> candidates = new ArrayList<>();
    for (MediaCodecInfo info : new MediaCodecList(MediaCodecList.ALL_CODECS).getCodecInfos()) {
      if (info == null || info.isEncoder() || !MediaCodecUtils.codecSupportsType(info, type)
          || !MediaCodecUtils.isHardwareAccelerated(info)) {
        continue;
      }
      CodecCapabilities caps = info.getCapabilitiesForType(type.mimeType());
      if (MediaCodecUtils.selectColorFormat(MediaCodecUtils.DECODER_COLOR_FORMATS, caps) == null) {
        continue;
      }
      infos.add(info);
      candidates.add(new LowLatencyDecoderSelect.Candidate(info.getName(),
          Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
              && caps.isFeatureSupported(CodecCapabilities.FEATURE_LowLatency)));
    }
    int i = LowLatencyDecoderSelect.pick(candidates);
    if (i < 0) return null;
    MediaCodecInfo info = infos.get(i);
    Integer colorFormat = MediaCodecUtils.selectColorFormat(
        MediaCodecUtils.DECODER_COLOR_FORMATS, info.getCapabilitiesForType(type.mimeType()));
    return new AndroidVideoDecoder(new LowLatencyMediaCodecWrapperFactory(), info.getName(), type,
        colorFormat, sharedContext);
  }
}
