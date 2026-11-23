# HF Talking Island quests (Newbie Helper + Letters of Love)

Chronicle: **High Five** · Datapack: Shagooh `l2j-server-datapack` @ `03897cc4ee42361304fb5a96e59bb7fba174c0a8`

## Implemented

### Q255 Tutorial — Human Fighter path
| Field | Value |
|-------|--------|
| Source | `quests/Q00255_Tutorial` |
| NPCs | Newbie Helper **30009**, Grand Master Roien **30008** |
| Mob | Tutorial Gremlin **18342** |
| Items | Blue Gemstone **6353**, Recommendation **1067**, Soulshot Beginner **5789**, Tutorial Guide **5588** |

Flow (simplified for 2D Cedric library):
1. Spawn in **Cedric's Training Hall** → talk to Newbie Helper → accept Blue Gemstone mission  
2. Kill **passive** Gremlins in the hall courtyard (~50% gem drop while quest active — **unconfirmed** vs L2J `getRandom(2)` helper)  
3. Turn in gem → Recommendation + 200 Soulshots  
4. Deliver Recommendation to Roien → +200 Soulshots, Tutorial Guide, +50 XP (**SP→XP stand-in, unconfirmed**)

Omitted: full client tutorial windows, radar, voice cues, Kamael Village teleport.

### Q1 Letters of Love
| Field | Value |
|-------|--------|
| Source | `quests/Q00001_LettersOfLove` |
| NPCs | Darin **30048**, Roxxy **30006**, Baulro **30033** |
| Min level | 2 (**confirmed**) |
| Rewards | Necklace of Knowledge **906**, **5672** XP, **446** SP (logged only), **2466** Adena — **confirmed** from `onTalk` cond 4 |

## Runtime files

- `data/runtime/quests.json`
- `data/runtime/friendly_npcs.json`
- `data/runtime/dialogs.json` (HTML dialogs stripped to plain text; some lines **adapted**)

## Unconfirmed / gaps

- Friendly NPC **2D positions** (Cedric hall / village path vs exact HF spawnlist)
- Soulshots in bag **without** SS damage formula
- Roien’s `addExpAndSp(0,50)` mapped as **+50 XP**
- Letters of Love **SP** stored in `quests.sp_bank` only (no SP character sheet)
- Dialog HTML image tags / bypass links replaced with button choices
- Tutorial Gremlin hall spawns are **hand-placed** (see `spawns.json` / [`cedric-library.md`](cedric-library.md))
- Wolves / orcs relocated far west of the library (not HF-accurate distances)

## How to play

1. Spawn in **Cedric's library** → click **Newbie Helper** → accept mission  
2. Attack passive green **Gremlin**s in the courtyard → return with Blue Gemstone  
3. Talk to **Roien**  
4. Walk west toward the village path (wolves, then orcs farther) or level via Gremlins → **Darin** → Roxxy → Baulro → Darin  
