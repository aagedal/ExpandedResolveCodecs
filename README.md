# x264 encoder for DaVinci Resolve Studio (proof of concept)

This Apple Silicon macOS plugin adapts Blackmagic Design's CodecPlugin SDK x264 example. It registers an x264 H.264 encoder for Resolve's MP4 and QuickTime/MOV writers. The output is 8-bit, CPU encoded, and uses x264's standard presets and tunes. Custom presets are a later step.

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

This has been built and checked as an arm64 bundle. Resolve Studio 21.1 loaded it and showed `Plugin AVC` in Deliver. An in-Resolve render still needs to be validated. The SDK example includes two-pass controls, but this proof of concept has not validated two-pass output.

The copied SDK wrapper and encoder sources came from `/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/CodecPlugin/Examples/x264_encoder_plugin`. x264 is GPL-licensed; review its terms before distributing a linked plugin.
