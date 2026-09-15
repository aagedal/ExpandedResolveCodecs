# x264 encoder for DaVinci Resolve Studio (proof of concept)

This Apple Silicon macOS plugin adapts Blackmagic Design's CodecPlugin SDK x264 example. It registers an x264 H.264 encoder for Resolve's MP4 and QuickTime/MOV writers. The output is 8-bit and CPU encoded. It exposes x264's standard presets and tunes; custom presets are a later step.

The build uses the newest upstream x264 `master` revision available when it runs. It compiles x264 as a static library and embeds it in the `.dvcp` binary, so the plugin does not require Homebrew at runtime. The exact revision used is saved in `dist/x264-commit.txt`.

On an Apple Silicon Mac with Xcode Command Line Tools installed:

```sh
./scripts/build.sh
```

To build from an existing checkout, including a specific pinned commit:

```sh
X264_SOURCE_DIR=/absolute/path/to/x264 ./scripts/build.sh
```

Install the resulting `dist/x264_encoder_plugin.dvcp.bundle` in `/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins`, then restart Resolve Studio. In Deliver, choose MP4 or QuickTime, then look for `Plugin AVC` in the Codec list and select `x264 (upstream PoC)`. Start with a short render at the default medium preset and CRF 20.

Resolve Studio 21.1 loaded the arm64 bundle and showed `Plugin AVC` in Deliver. A two-second, 24 fps QuickTime render at `medium` / `film` / CRF 20 produced 48 decodable 1920 × 1080 H.264 frames, PCM audio, and timecode. The plugin was built against upstream x264 commit `0480cb05fa188d37ae87e8f4fd8f1aea3711f7ee` for that test.

Resolve Studio 21.1 sent all input frames but closed the encoder without calling the SDK's `msgCodecFlush`. The encoder path inherited from the SDK example left x264's delayed frames buffered, so a short render completed with only audio and timecode. This PoC combines the selected x264 tune with `zerolatency` internally so each frame reaches Resolve before the encoder closes. The selected preset still affects other x264 settings, but B-frames, lookahead, and MB-tree are disabled by the zero-latency tune. Two-pass output and MP4 output have not been validated yet.

The copied SDK wrapper and encoder sources came from `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/CodecPlugin/Examples/x264_encoder_plugin`. x264 is GPL-licensed; review its terms before distributing a linked plugin.
