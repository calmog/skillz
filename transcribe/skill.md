---
name: transcribe
description: "Transcribe audio/video to SRT subtitles or plain text using local Whisper (faster-whisper). Runs on-device, no API key. Use for: transcription, subtitles, captions, SRT generation."
author: calmog
---

# Transcribe

Generate SRT subtitle files (or plain text) from audio/video using **local
Whisper** via `faster-whisper`. Runs 100% on-device — no API, no key, no network,
no per-use cost. The model is cached in `~/.cache/huggingface` after first run.

Requires `ffmpeg` and `uvx` on the machine (both already installed here). No
manual `npm install` / dependency setup — `uvx` pulls `faster-whisper` on demand.

## Quick Start

```bash
cd ~/.claude/skills/transcribe/scripts

# Basic transcription (auto-detect language)
uvx --with faster-whisper python transcribe.py -i /path/to/video.mp4 -o /path/to/output.srt

# Specify language
uvx --with faster-whisper python transcribe.py -i /path/to/video.mp4 -o /path/to/output.srt -l en

# Larger model for accuracy (slower)
uvx --with faster-whisper python transcribe.py -i /path/to/audio.mp3 -o /path/to/output.srt --model small

# Custom subtitle length
uvx --with faster-whisper python transcribe.py -i /path/to/video.mp4 -o /path/to/output.srt --max-words 6
```

## Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--input` | `-i` | (required) | Input audio/video file |
| `--output` | `-o` | (required) | Output SRT file path |
| `--language` | `-l` | auto | Language code (en, he, ar, etc.) |
| `--model` | | base | Whisper model: tiny / base / small / medium / large-v3 |
| `--max-words` | | 5 | Max words per subtitle entry |
| `--max-duration` | | 3.0 | Max seconds per subtitle entry |
| `--max-chars` | | 70 | Max characters per subtitle entry |
| `--timing-offset` | | 0.0 | Timing offset in seconds |
| `--json` | | false | Also output raw transcript JSON |

## Model tradeoff

- `tiny` / `base` — fast, good for clear speech (base is the default).
- `small` / `medium` — slower, better for accents, noise, or non-English.
- `large-v3` — best accuracy, slowest. First use of any model downloads it once.

## Language Codes

`en` English · `he` Hebrew · `ar` Arabic · `es` Spanish · `fr` French ·
`de` German · `ru` Russian · `zh` Chinese · `ja` Japanese · (omit for auto-detect)

## Output

1. `.srt` file — standard subtitle file with timestamps.
2. `.json` file (optional, `--json`) — detected language + plain transcript.
