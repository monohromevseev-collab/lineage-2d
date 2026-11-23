#!/usr/bin/env python3
"""High Five Talking Island slice ingest: L2J datapack → data/runtime JSON.

Usage:
  python3 tools/hf_ingest/ingest_ti.py --datapack /path/to/l2j-server-datapack \\
      --out data/runtime [--commit SHA]

Only High Five sources. Does not mix Interlude/Essence packs.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET

# TI slice NPC ids confirmed present on Talking_Island in HF spawnlist.
NPC_IDS = [20481, 20432, 20544, 20120, 20130, 20006]

# Starter + drop + upgrade gear for Human Fighter TI slice.
ITEM_IDS = [
    1,  # Short Sword (starter)
    4,  # Club
    11,  # Bone Dagger
    13,  # Short Bow
    14,  # Bow
    21,  # Shirt
    22,  # Leather Shirt
    23,  # Wooden Breastplate
    28,  # Pants
    44,  # Leather Helmet
    50,  # Leather Gloves
    57,  # Adena
    426,  # Tunic
    462,  # Stockings
    1060,  # Lesser Healing Potion
    1119,  # Short Leather Gloves
    1122,  # Cotton Shoes
    1129,  # Crude Leather Shoes
    1146,  # Squire's Shirt (starter)
    1147,  # Squire's Pants (starter)
    1148,  # Hard Leather Helmet
]

# Herb / vitality ids skipped (no herb system in 6a).
HERB_MIN, HERB_MAX = 8600, 8615
EXTRA_HERBS = {10655, 10656, 10657, 13028}

# Materials / recipes we do not model yet (etc without gameplay).
SKIP_ETC_WITHOUT_USE = {
    17, 1786, 1787, 1788, 1666, 1864, 1865, 1866, 1868, 1869, 1870, 1871, 1872, 1873, 1874,
    2005, 2006, 2007, 2136, 112, 116, 118, 113,  # jewelry (no mDef combat yet)
}

BODYPART_TO_SLOT = {
    "rhand": "weapon",
    "lrhand": "weapon",
    "lhand": "shield",
    "chest": "chest",
    "legs": "legs",
    "head": "head",
    "gloves": "gloves",
    "feet": "feet",
    "underwear": "underwear",
    "neck": "neck",
    "rear": "earring",
    "lear": "earring",
    "rfinger": "ring",
    "lfinger": "ring",
    "rear;lear": "earring",
    "rfinger;lfinger": "ring",
}

# Procedural visual tiers for layered character art (not from datapack).
VISUAL_BY_ITEM: dict[int, dict[str, Any]] = {
    1: {"tier": 0, "weapon": "wood_blade"},
    4: {"tier": 0, "weapon": "wood_blade"},
    11: {"tier": 0, "weapon": "wood_blade"},
    13: {"tier": 1, "weapon": "bronze_blade"},
    14: {"tier": 2, "weapon": "steel_blade"},
    21: {"tier": 0, "chest": "linen"},
    22: {"tier": 1, "chest": "bronze"},
    23: {"tier": 1, "chest": "bronze"},
    28: {"tier": 0, "legs": "linen"},
    44: {"tier": 1, "head": "bronze"},
    50: {"tier": 1},
    426: {"tier": 0, "chest": "linen"},
    462: {"tier": 0, "legs": "linen"},
    1146: {"tier": 0, "chest": "linen"},
    1147: {"tier": 0, "legs": "linen"},
    1148: {"tier": 2, "head": "steel"},
    1119: {"tier": 1},
    1122: {"tier": 0},
    1129: {"tier": 1},
}

SILHOUETTE = {
    20481: ("fox", [0.72, 0.48, 0.28]),
    20432: ("fox", [0.85, 0.78, 0.45]),
    20544: ("fox", [0.55, 0.38, 0.22]),
    20120: ("wolf", [0.45, 0.48, 0.55]),
    20130: ("orc", [0.35, 0.55, 0.32]),
    20006: ("orc", [0.42, 0.48, 0.28]),
}

# 2D projection of L2 TI coords → meadow around talking stone (−40, 70).
# UNCONFIRMED: scale/origin chosen for playable density, not geo-accurate map.
PROJ = {
    "origin_l2_x": -84000,
    "origin_l2_y": 245000,
    "scale": 0.035,
    "offset_2d_x": -40.0,
    "offset_2d_y": 70.0,
    "status": "unconfirmed",
    "note": "Hand-tuned projection so HF Talking_Island spawnlist samples fit WORLD_HALF meadow.",
}

MAX_SPAWNS_PER_NPC = 3
WORLD_HALF = (1350.0, 950.0)


def _git_commit(path: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "HEAD"], text=True
        ).strip()
    except Exception:
        return "unknown"


def _git_remote(path: Path) -> str:
    try:
        url = subprocess.check_output(
            ["git", "-C", str(path), "remote", "get-url", "origin"], text=True
        ).strip()
        # scrub tokens
        if "@github.com" in url:
            url = "https://github.com/" + url.split("github.com/")[-1]
        return url
    except Exception:
        return "unknown"


def _data_root(datapack: Path) -> Path:
    candidates = [
        datapack / "src" / "main" / "resources" / "data",
        datapack / "data",
    ]
    for c in candidates:
        if c.is_dir():
            return c
    raise SystemExit(f"Cannot find data/ under {datapack}")


def _set_map(item_el: ET.Element) -> dict[str, str]:
    out: dict[str, str] = {}
    for s in item_el.findall("set"):
        name = s.get("name")
        val = s.get("val")
        if name and val is not None:
            out[name] = val
    return out


def _stat_from_for(item_el: ET.Element, stat: str) -> float | None:
    for_el = item_el.find("for")
    if for_el is None:
        return None
    for child in for_el:
        if child.get("stat") == stat:
            try:
                return float(child.get("val", "0"))
            except ValueError:
                return None
    return None


def parse_items(data: Path, ids: set[int]) -> dict[str, Any]:
    items: dict[str, Any] = {}
    items_dir = data / "stats" / "items"
    remaining = set(ids)
    for xml in sorted(items_dir.glob("*.xml")):
        text = xml.read_text(encoding="utf-8", errors="ignore")
        for iid in list(remaining):
            m = re.search(rf'<item id="{iid}"[\s\S]*?</item>', text)
            if not m:
                continue
            el = ET.fromstring(m.group(0))
            sets = _set_map(el)
            bodypart = sets.get("bodypart", "")
            slot = BODYPART_TO_SLOT.get(bodypart, "")
            itype = el.get("type", "EtcItem")
            if itype == "EtcItem" and not slot:
                slot = "etc"
            patk = _stat_from_for(el, "pAtk")
            pdef = _stat_from_for(el, "pDef")
            entry: dict[str, Any] = {
                "id": iid,
                "name": el.get("name", f"Item {iid}"),
                "type": itype,
                "bodypart": bodypart,
                "slot": slot,
                "weight": int(float(sets.get("weight", "0"))),
                "price": int(float(sets.get("price", "0"))),
                "icon": sets.get("icon", ""),
                "armor_type": sets.get("armor_type", ""),
                "weapon_type": sets.get("weapon_type", ""),
                "p_atk": int(patk) if patk is not None else 0,
                "p_def": int(pdef) if pdef is not None else 0,
                "visual": VISUAL_BY_ITEM.get(iid, {"tier": 0}),
                "source": "hf_datapack",
                "status": "confirmed",
            }
            items[str(iid)] = entry
            remaining.discard(iid)
        if not remaining:
            break
    if remaining:
        print(f"WARN missing items: {sorted(remaining)}", file=sys.stderr)
    return items


def _attr_float(el: ET.Element | None, name: str, default: float = 0.0) -> float:
    if el is None:
        return default
    try:
        return float(el.get(name, default))
    except ValueError:
        return default


def _should_keep_drop_item(iid: int, items: dict[str, Any]) -> bool:
    if iid in EXTRA_HERBS or HERB_MIN <= iid <= HERB_MAX:
        return False
    if iid in SKIP_ETC_WITHOUT_USE:
        return False
    key = str(iid)
    if key not in items:
        return False
    slot = items[key].get("slot", "")
    if slot in ("weapon", "chest", "legs", "head", "gloves", "feet", "etc"):
        return True
    return False


def parse_npc(data: Path, npc_id: int, items: dict[str, Any]) -> dict[str, Any] | None:
    npcs_dir = data / "stats" / "npcs"
    block = None
    for xml in npcs_dir.glob("*.xml"):
        text = xml.read_text(encoding="utf-8", errors="ignore")
        m = re.search(rf'<npc id="{npc_id}"[\s\S]*?</npc>', text)
        if m:
            block = m.group(0)
            break
    if not block:
        return None
    el = ET.fromstring(block)
    name = el.get("name") or f"NPC {npc_id}"
    level = int(el.get("level", "1"))
    acquire = el.find("acquire")
    exp_rate = _attr_float(acquire, "expRate", 1.0)
    sp = int(_attr_float(acquire, "sp", 0))
    stats = el.find("stats")
    vitals = stats.find("vitals") if stats is not None else None
    attack = stats.find("attack") if stats is not None else None
    defence = stats.find("defence") if stats is not None else None
    hp = _attr_float(vitals, "hp", 40.0)
    p_atk = _attr_float(attack, "physical", 5.0)
    p_def = _attr_float(defence, "physical", 10.0)
    atk_spd = _attr_float(attack, "attackSpeed", 253.0)
    atk_range_l2 = _attr_float(attack, "range", 40.0)

    # Absolute XP per kill: L2J uses expRate against internal formulas.
    # UNCONFIRMED approximation for our simplified loop: round(expRate).
    xp_reward = max(1, int(round(exp_rate)))

    sil, color = SILHOUETTE.get(npc_id, ("fox", [0.6, 0.6, 0.6]))
    # Attack interval from HF attackSpeed (base ~300). Unconfirmed mapping.
    attack_interval = max(0.7, min(2.0, 300.0 / max(atk_spd, 1.0) * 1.15))
    # Pixel attack range from L2 range. Unconfirmed.
    attack_range_px = max(40.0, atk_range_l2 * 1.05)

    drop_groups: list[dict[str, Any]] = []
    drop_lists = el.find("dropLists")
    if drop_lists is not None:
        death = drop_lists.find("death")
        if death is not None:
            for group in death.findall("group"):
                g_chance = float(group.get("chance", "0"))
                kept: list[dict[str, Any]] = []
                for it in group.findall("item"):
                    iid = int(it.get("id", "0"))
                    if not _should_keep_drop_item(iid, items):
                        continue
                    kept.append(
                        {
                            "item_id": str(iid),
                            "min": int(float(it.get("min", "1"))),
                            "max": int(float(it.get("max", "1"))),
                            "chance": float(it.get("chance", "0")),
                        }
                    )
                if kept:
                    drop_groups.append({"chance": g_chance, "items": kept})

    return {
        "id": npc_id,
        "name": name,
        "level": level,
        "type": el.get("type", "L2Monster"),
        "max_hp": max(1, int(round(hp))),
        "p_atk": max(1, int(round(p_atk))),
        "p_def": max(1, int(round(p_def))),
        "exp_rate": exp_rate,
        "sp": sp,
        "xp_reward": xp_reward,
        "xp_reward_status": "unconfirmed",
        "xp_reward_note": "approx max(1, round(expRate)); full L2J Exp.getExpForLevel not ported",
        "speed": 70.0 if sil != "wolf" else 95.0,
        "speed_status": "unconfirmed",
        "aggro_range": 0.0 if level <= 3 else 110.0,
        "aggro_range_status": "unconfirmed",
        "attack_range": attack_range_px,
        "attack_range_status": "unconfirmed",
        "attack_interval": round(attack_interval, 3),
        "attack_interval_status": "unconfirmed",
        "silhouette": sil,
        "color": color,
        "drop_groups": drop_groups,
        "source": "hf_datapack",
        "status": "confirmed",
    }


def parse_spawns(datapack: Path, npc_ids: list[int]) -> list[dict[str, Any]]:
    sql = datapack / "src" / "main" / "resources" / "sql" / "spawnlist.sql"
    if not sql.exists():
        sql = datapack / "sql" / "spawnlist.sql"
    text = sql.read_text(encoding="utf-8", errors="ignore")
    pat = re.compile(
        r'\("Talking_Island",\s*1,\s*(\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)'
    )
    by_npc: dict[int, list[tuple[int, int, int]]] = {i: [] for i in npc_ids}
    for m in pat.finditer(text):
        nid, x, y, z = map(int, m.groups())
        if nid in by_npc:
            by_npc[nid].append((x, y, z))

    ox = PROJ["origin_l2_x"]
    oy = PROJ["origin_l2_y"]
    scale = PROJ["scale"]
    offx = PROJ["offset_2d_x"]
    offy = PROJ["offset_2d_y"]
    hx, hy = WORLD_HALF

    spawns: list[dict[str, Any]] = []
    for nid in npc_ids:
        pts = by_npc.get(nid, [])
        # Evenly sample across list for spatial spread.
        if not pts:
            print(f"WARN no TI spawns for npc {nid}", file=sys.stderr)
            continue
        step = max(1, len(pts) // MAX_SPAWNS_PER_NPC)
        picked = pts[::step][:MAX_SPAWNS_PER_NPC]
        for lx, ly, lz in picked:
            x2 = (lx - ox) * scale + offx
            y2 = (ly - oy) * scale + offy
            # Soft clamp into meadow
            x2 = max(-hx, min(hx, x2))
            y2 = max(-hy, min(hy, y2))
            spawns.append(
                {
                    "npc_id": str(nid),
                    "pos": {"x": round(x2, 1), "y": round(y2, 1)},
                    "l2": {"x": lx, "y": ly, "z": lz},
                    "projection_status": "unconfirmed",
                }
            )
    return spawns


def parse_exp(data: Path) -> dict[str, Any]:
    path = data / "stats" / "expData.json"
    raw = json.loads(path.read_text(encoding="utf-8"))
    # cumulative XP required to *be* at level N (L2J / HF)
    levels = {int(k): int(v) for k, v in raw.items()}
    max_lvl = max(levels)
    to_next: dict[str, int] = {}
    for lv in range(1, max_lvl):
        to_next[str(lv)] = max(0, levels.get(lv + 1, 0) - levels.get(lv, 0))
    return {
        "cumulative": {str(k): v for k, v in sorted(levels.items())},
        "to_next": to_next,
        "source": "hf_datapack stats/expData.json",
        "status": "confirmed",
    }


def parse_class(data: Path) -> dict[str, Any]:
    path = data / "stats" / "chars" / "baseStats" / "HumanFighter.xml"
    root = ET.parse(path).getroot()
    static = root.find("staticData")
    assert static is not None
    def _i(tag: str) -> int:
        return int(float(static.findtext(tag, "0")))

    base_pdef = static.find("basePDef")
    pdef_parts = {
        child.tag: int(float(child.text or "0"))
        for child in (base_pdef if base_pdef is not None else [])
    }
    move = static.find("baseMoveSpd")
    run = float(move.findtext("run", "115")) if move is not None else 115.0

    lvl_gains: dict[str, Any] = {}
    gain = root.find("lvlUpgainData")
    if gain is not None:
        for level_el in gain.findall("level"):
            lv = level_el.get("val", "1")
            lvl_gains[lv] = {
                "hp": float(level_el.findtext("hp", "80")),
                "mp": float(level_el.findtext("mp", "30")),
                "cp": float(level_el.findtext("cp", "32")),
            }

    return {
        "class_id": 0,
        "name": "Human Fighter",
        "race": "human",
        "str": _i("baseSTR"),
        "dex": _i("baseDEX"),
        "con": _i("baseCON"),
        "int": _i("baseINT"),
        "wit": _i("baseWIT"),
        "men": _i("baseMEN"),
        "base_p_atk": _i("basePAtk"),
        "base_p_def_parts": pdef_parts,
        "base_move_run": run,
        # Pixel speed for our 2D meadow — unconfirmed mapping from L2 run 115.
        "base_speed_px": 180.0,
        "base_speed_px_status": "unconfirmed",
        "level_gains": lvl_gains,
        "starter_loadout": {
            "weapon": "1",
            "chest": "1146",
            "legs": "1147",
            "head": "",
        },
        "starter_loadout_note": "HF Human Fighter starter: Short Sword + Squire shirt/pants (no cloth cap in this pack)",
        "source": "hf_datapack HumanFighter.xml",
        "status": "confirmed",
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--datapack", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=Path("data/runtime"))
    ap.add_argument("--commit", default="")
    args = ap.parse_args()

    datapack: Path = args.datapack.resolve()
    data = _data_root(datapack)
    commit = args.commit or _git_commit(datapack)
    remote = _git_remote(datapack)
    out: Path = args.out
    out.mkdir(parents=True, exist_ok=True)

    items = parse_items(data, set(ITEM_IDS))
    npcs: dict[str, Any] = {}
    unknown_fields: list[str] = []
    for nid in NPC_IDS:
        parsed = parse_npc(data, nid, items)
        if parsed:
            npcs[str(nid)] = parsed
        else:
            unknown_fields.append(f"missing_npc:{nid}")

    spawns = parse_spawns(datapack, NPC_IDS)
    exp = parse_exp(data)
    classes = {"0": parse_class(data)}

    # Alias map for transitional toy ids → HF
    aliases = {
        "keltir": "20481",
        "wolf": "20120",
        "orc_grunt": "20130",
        "training_sword": "1",
        "linen_tunic": "1146",
        "linen_pants": "1147",
    }

    meta = {
        "chronicle": "High Five",
        "datapack_url": remote,
        "datapack_commit": commit,
        "slice": "talking_island_6a",
        "npc_ids": NPC_IDS,
        "item_ids": ITEM_IDS,
        "projection": PROJ,
        "aliases": aliases,
        "filters": {
            "skipped_herbs": True,
            "skipped_materials_recipes_jewelry": True,
            "note": "Death drop groups kept only for items present in items.json (equippables + Adena + Lesser Healing Potion).",
        },
        "unconfirmed": [
            "npc.xp_reward (approx from expRate)",
            "npc.speed / aggro_range / attack_range_px / attack_interval",
            "spawn 2D projection scale/origin",
            "Human Fighter base_speed_px",
            "combat.phys_damage HF-lite formula (70*pAtk/pDef) — not full L2J Formulas.calcPhysDam",
        ],
        "unknown_fields": unknown_fields,
    }

    def dump(name: str, payload: Any) -> None:
        path = out / name
        path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"wrote {path}")

    dump("meta.json", meta)
    dump("items.json", items)
    dump("npcs.json", npcs)
    dump("spawns.json", {"spawns": spawns, "projection": PROJ})
    dump("exp.json", exp)
    dump("classes.json", classes)
    dump(
        "drops.json",
        {
            nid: {"groups": n["drop_groups"]}
            for nid, n in npcs.items()
        },
    )

    report = {
        "items": len(items),
        "npcs": len(npcs),
        "spawns": len(spawns),
        "exp_levels": len(exp.get("cumulative", {})),
        "unknown_fields": unknown_fields,
    }
    dump("ingest_report.json", report)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
