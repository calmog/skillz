---
name: usage-guard
description: Calibrate the Claude Code token usage guard. Run after checking /usage to sync the guard's limit with your actual window. Also shows current usage status.
argument-hint: "<percentage from /usage>  e.g. /usage-guard 48"
---

# Usage Guard Calibration

Reads current token usage from JSONL history and syncs the guard's limit based on the percentage shown by `/usage`.

## Steps

1. **Count current JSONL tokens** (last 5 hours):

```bash
python3 -c "
import json, glob, os
from datetime import datetime, timezone, timedelta
from pathlib import Path

HOME = Path.home()
cutoff = datetime.now(timezone.utc) - timedelta(hours=5)
total = 0
oldest_ts = None

for f in glob.glob(str(HOME / '.claude/projects/**/*.jsonl'), recursive=True):
    try:
        for line in open(f, errors='replace'):
            try:
                d = json.loads(line)
                u = d.get('message', {}).get('usage')
                ts = d.get('timestamp')
                if not u or not ts: continue
                t = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                if t <= cutoff: continue
                total += u.get('input_tokens', 0)
                total += u.get('output_tokens', 0)
                total += u.get('cache_creation_input_tokens', 0)
                if oldest_ts is None or t < oldest_ts: oldest_ts = t
            except: pass
    except: pass

if oldest_ts:
    reset_at = oldest_ts + timedelta(hours=5)
    mins = int((reset_at - datetime.now(timezone.utc)).total_seconds() / 60)
else:
    mins = None

print(f'TOKENS={total}')
print(f'RESET_MINS={mins}')
"
```

2. **Get the percentage** from the skill argument (the number the user passed after `/usage-guard`). If no argument was given, ask: "What percentage does `/usage` show right now?"

3. **Compute the implied limit**:
   - `limit = int(tokens / (percentage / 100))`

4. **Update the config**:

```bash
python3 -c "
import json
from pathlib import Path
cfg = Path.home() / '.claude' / 'usage-guard-config.json'
data = json.loads(cfg.read_text())
data['windowLimitTokens'] = LIMIT_VALUE
cfg.write_text(json.dumps(data, indent=2))
print('Updated windowLimitTokens to LIMIT_VALUE')
"
```
Replace `LIMIT_VALUE` with the computed limit integer.

5. **Clear the cache** so the next tool call re-scans with the fresh limit:

```bash
rm -f ~/.claude/usage-guard-cache.json
```

6. **Report to the user**:
   - Current usage: `{tokens:,}` tokens = `{percentage}%` of `{limit:,}` limit
   - Guard triggers at: `{int(limit * threshold):,}` tokens (`{int(threshold*100)}%`)
   - Window resets in: `{reset_mins}` minutes
   - Status: active / disabled (if limit is 0)

## Config reference

`~/.claude/usage-guard-config.json`:
```json
{
  "windowLimitTokens": 3118372,
  "alertThreshold": 0.95
}
```

- `windowLimitTokens`: set to 0 to disable the guard entirely
- `alertThreshold`: fraction at which tool calls are blocked (default 0.95)
