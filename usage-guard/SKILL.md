---
name: usage-guard
description: Show or control the Claude Code usage guard — real 5-hour and weekly utilization from the OAuth usage endpoint, block thresholds, bypass, and the JSONL fallback calibration. No manual calibration needed anymore.
author: calmog
argument-hint: "(no args — shows status)"
---

# Usage Guard — status & control

The guard (`~/.claude/scripts/check-usage.py`, PreToolUse hook on all tools) blocks tool calls when real usage nears a limit. Since 2026-08-05 it reads **exact utilization** from the OAuth usage endpoint (the same data `/usage` shows) — the 5-hour session window, the weekly limits, and the org monthly spend cap on extra-usage credits (the `spend` / `extra_usage` blocks; source of "you've hit your monthly spend limit" — admin-set on the ask-y org, only visible when extra usage is enabled) — so no token counting or calibration is needed on the primary path.

## Show current status

```bash
TOK=$(security find-generic-password -s "Claude Code-credentials" -w | python3 -c "import json,sys;print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])")
curl -s https://api.anthropic.com/api/oauth/usage \
  -H "Authorization: Bearer $TOK" -H "anthropic-beta: oauth-2025-04-20" \
  | python3 -c "
import json,sys
from datetime import datetime,timezone
d=json.load(sys.stdin)
for l in d.get('limits',[]):
    r=l.get('resets_at')
    if r:
        mins=int((datetime.fromisoformat(r)-datetime.now(timezone.utc)).total_seconds()//60)
        r=f'resets in {mins//60}h{mins%60:02d}m'
    print(f\"{l['kind']:14s} {l.get('percent')}%  {r or ''}\")
"
```

Report each limit's percentage and reset time (convert to Asia/Jerusalem when stating clock times). The guard blocks when any limit ≥ its threshold.

## Config — `~/.claude/usage-guard-config.json`

- `alertThreshold` — session (5h) block fraction, default 0.95
- `weeklyAlertThreshold` — weekly block fraction, default 0.95
- `windowLimitTokens` — **fallback only** (JSONL counting when Keychain/network fails); `0` disables the guard entirely
- `autoCalibrate` — `false` stops the daily fallback recalibration

After config changes: `rm -f ~/.claude/usage-guard-cache.json` so the next tool call re-reads.

## Bypassing a block (Almog's explicit say-so only)

`touch ~/.claude/usage-guard-bypass` — the guard whitelists exactly that command while blocking, so a blocked session can run it. Valid 60 minutes; auto-deleted once usage drops below threshold. Almog can also type `! touch ~/.claude/usage-guard-bypass`. Never create the bypass without him explicitly saying to continue.

## Fallback auto-calibration (no action needed)

Only relevant when the endpoint is unreachable. `scripts/usage-guard-calibrate.py` runs detached once a day (spawned by the hook via the `~/.claude/usage-guard-last-calib` stamp): it finds real "You've hit your session limit" deaths in transcripts, computes local 5h JSONL sums at each, and sets `windowLimitTokens` just under the lowest non-outlier. Log: `~/.claude/usage-guard-calibrate.log`.
