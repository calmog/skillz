#!/usr/bin/env python3
"""
Transcribe audio/video to SRT subtitles using LOCAL faster-whisper (Whisper).

Runs 100% on-device — no API, no key, no network, no cost. The model is cached
in ~/.cache/huggingface after first use and reused; nothing stays resident.

Run via uvx (no manual install needed):
    uvx --with faster-whisper python transcribe.py -i in.mp4 -o out.srt
    uvx --with faster-whisper python transcribe.py -i in.mp3 -o out.srt -l he
    uvx --with faster-whisper python transcribe.py -i in.wav -o out.srt --model small

Requires ffmpeg on PATH (used by faster-whisper to decode non-WAV inputs).
"""
import argparse
import sys


def fmt_ts(seconds: float) -> str:
    if seconds < 0:
        seconds = 0.0
    ms = int(round(seconds * 1000))
    h, ms = divmod(ms, 3600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def chunk_words(words, max_words, max_duration, max_chars):
    """Group word-level timestamps into subtitle cues."""
    cue, cues = [], []
    for w in words:
        cue.append(w)
        text = "".join(x.word for x in cue).strip()
        dur = cue[-1].end - cue[0].start
        if len(cue) >= max_words or dur >= max_duration or len(text) >= max_chars:
            cues.append(cue)
            cue = []
    if cue:
        cues.append(cue)
    return cues


def main():
    p = argparse.ArgumentParser(description="Local Whisper -> SRT subtitles")
    p.add_argument("-i", "--input", required=True)
    p.add_argument("-o", "--output", required=True)
    p.add_argument("-l", "--language", default=None, help="e.g. en, he, ar (default: auto)")
    p.add_argument("--model", default="base", help="tiny|base|small|medium|large-v3 (default: base)")
    p.add_argument("--max-words", type=int, default=5)
    p.add_argument("--max-duration", type=float, default=3.0)
    p.add_argument("--max-chars", type=int, default=70)
    p.add_argument("--timing-offset", type=float, default=0.0)
    p.add_argument("--json", action="store_true", help="also write raw transcript JSON")
    args = p.parse_args()

    from faster_whisper import WhisperModel

    model = WhisperModel(args.model, device="cpu", compute_type="int8")
    segments, info = model.transcribe(
        audio=args.input, language=args.language, word_timestamps=True
    )

    words = []
    plain = []
    for seg in segments:
        plain.append(seg.text)
        if seg.words:
            words.extend(seg.words)

    off = args.timing_offset
    lines = []
    idx = 1
    if words:
        for cue in chunk_words(words, args.max_words, args.max_duration, args.max_chars):
            start = fmt_ts(cue[0].start + off)
            end = fmt_ts(cue[-1].end + off)
            text = "".join(w.word for w in cue).strip()
            lines += [str(idx), f"{start} --> {end}", text, ""]
            idx += 1

    with open(args.output, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    if args.json:
        import json
        jpath = args.output.rsplit(".", 1)[0] + ".json"
        with open(jpath, "w", encoding="utf-8") as f:
            json.dump({"language": info.language, "text": "".join(plain).strip()}, f,
                      ensure_ascii=False, indent=2)

    print(f"Detected language: {info.language}", file=sys.stderr)
    print(f"Wrote {idx - 1} subtitle cues -> {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
