# x264 H.264 encoder for DaVinci Resolve Studio

This Apple Silicon macOS proof-of-concept plugin adapts Blackmagic Design's CodecPlugin SDK x264 example. It registers an x264 H.264 encoder for Resolve's MP4 and QuickTime/MOV writers. The output is 8-bit and CPU encoded. It exposes x264's standard presets and tunes, plus a VideoLoop encoder preset based on Aagedal Media Converter.

The build uses the newest upstream x264 `master` revision available when it runs. It compiles x264 as a static library and embeds it in the `.dvcp` binary, so the plugin does not require Homebrew at runtime. The exact revision used is saved in `dist/x264-commit.txt`.

On an Apple Silicon Mac with Xcode Command Line Tools installed:

```sh
./scripts/build.sh
```

To build from an existing checkout, including a specific pinned commit:

```sh
X264_SOURCE_DIR=/absolute/path/to/x264 ./scripts/build.sh
```

To create a macOS Installer package after building the plugin:

```sh
./scripts/package.sh
```

This creates `dist/ExpandedResolveCodecs-x264-0.2.0.pkg`. Open the package on an Apple Silicon Mac and follow the Installer prompts. It installs the plugin in Resolve's system `IOPlugins` directory. Quit and relaunch Resolve after installation. The package is unsigned by default; set `PKG_SIGNING_IDENTITY` to a Developer ID Installer identity when distributing a signed package.

Install the resulting `dist/x264_encoder_plugin.dvcp.bundle` in `/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins`, then restart Resolve Studio. In Deliver, choose MP4 or QuickTime, select `x264 H.264` in the Codec list, then `Software Encoder` as the Type. The default is medium and CRF 20.

For VideoLoop-style output, select `VideoLoop` under Plugin Settings. It applies x264 `veryslow`, CRF 23, Main profile, Level 4.0, a 9,000 kb/s VBV maximum rate, and an 18,000 kb VBV buffer. The preset uses a single pass, four reference frames, and 8-bit 4:2:0 video. Its Level 4.0 settings are intended for up to 1920 × 1080 at 30 fps. To match the converter's video-only MP4 workflow, select MP4, turn off Export Audio in Resolve's Audio tab, and set the desired resolution and sizing in Resolve. Resolve controls the container, audio, sizing, and file metadata; this encoder preset does not apply the converter's minimum-rate option, SEI removal, bitexact output, or desqueeze filter. Resolve's Network Optimization option is separate from the encoder preset.

Resolve Studio 21.1 loaded the arm64 bundle and showed `x264 H.264` in Deliver. A two-second, 24 fps QuickTime render at `medium` / `film` / CRF 20 produced 48 decodable 1920 × 1080 H.264 frames, PCM audio, and timecode. The plugin was built against upstream x264 commit `0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee` for that test.

A two-second, 24 fps MP4 render using VideoLoop with Export Audio off produced 48 decodable 1920 × 1080 H.264 frames, no audio stream, and a Resolve timecode/data stream. The H.264 stream reports Main profile, Level 4.0, and four reference frames.

Resolve Studio 21.1 sent all input frames but closed the encoder without calling the SDK's `msgCodecFlush`. The encoder path inherited from the SDK example left x264's delayed frames buffered, so a short render completed with only audio and timecode. This PoC combines the selected x264 tune with `zerolatency` internally so each frame reaches Resolve before the encoder closes. The selected preset still affects other x264 settings, but B-frames, lookahead, and MB-tree are disabled by the zero-latency tune. This also applies to VideoLoop, so its compression behavior differs from Aagedal Media Converter's original `veryslow` encode. Two-pass output has not been validated yet.

The copied SDK wrapper and encoder sources came from `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/CodecPlugin/Examples/x264_encoder_plugin`. x264 is GPL-licensed; review its terms before distributing a linked plugin.
