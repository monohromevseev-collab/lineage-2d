# HF ingest (Talking Island slice)

Converts a **High Five** L2J datapack into `data/runtime/*.json` for the Godot server.

## Requirements

- Python 3.10+
- A checkout of an HF L2J datapack (see `docs/hf-data-sources.md`)

## Regenerate

```bash
git clone https://github.com/Shagooh/l2j-server-datapack.git /tmp/hf-dp/shagooh
cd /tmp/hf-dp/shagooh && git checkout 03897cc4ee42361304fb5a96e59bb7fba174c0a8

python3 tools/hf_ingest/ingest_ti.py \
  --datapack /tmp/hf-dp/shagooh \
  --out data/runtime
```

Commit the regenerated `data/runtime/` JSON with any ingest changes.

## Outputs

| File | Contents |
|------|----------|
| `meta.json` | Datapack URL/commit, filters, unconfirmed list |
| `items.json` | TI starter + drop gear |
| `npcs.json` | TI monsters + filtered drop groups |
| `drops.json` | Drop groups only |
| `spawns.json` | Projected 2D spawn points from `Talking_Island` spawnlist |
| `exp.json` | HF cumulative + to_next XP table |
| `classes.json` | Human Fighter base + level HP/MP/CP gains |
| `ingest_report.json` | Counts / missing ids |
