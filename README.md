# Fading Echo — Full Game Load Remover / Autosplitter (LiveSplit)

A LiveSplit auto-splitter and load remover for the **full game** of
[Fading Echo](https://store.steampowered.com/) (*Project Ygro*), built with the
[Uhara](https://github.com/ru-mii/uhara) library.

Based on and grateful to **streetbackguy**'s Fading Echo *demo* autosplitter —
this is the full-game counterpart.

**File:** [`Fading Echo/LiveSplit.FadingEcho.FullGame.asl`](Fading%20Echo/LiveSplit.FadingEcho.FullGame.asl)

> ## ✅ Now on the official LiveSplit autosplitter list
>
> You don't need to download anything manually. In LiveSplit, open
> **Edit Splits**, set **Game Name** to **`Fading Echo`**, and click
> **Activate** — LiveSplit downloads this script for you.
>
> **Running the demo instead?** Set the Game Name to **`Fading Echo Demo`** to
> get streetbackguy's demo autosplitter.

---

## Features

- **Load removal** — pauses the timer during zone loads, engine blocking loads
  and cutscenes.
- **Auto start** — starts on entering the Tutorial zone (new game).
- **Zone splits** — one split each time you reach a gameplay zone (Bastion,
  Big Tree, Volcano, Quarry, Wonder).
- **Source splits** — one split each time you activate an Aetheric source, in
  whatever order you do them. Driven by MissionFlow node state, so a split can
  neither be missed nor fired twice by a Bastion reload. You can switch to
  splitting on the Bastion *connection* instead, in the component settings.
- **Auto reset** — optional, on returning to the main menu.

## Install

1. Right-click LiveSplit → **Edit Splits**.
2. **Game Name:** type **`Fading Echo`** → click **Activate**.
   (For the demo, use **`Fading Echo Demo`** instead.)
3. Right-click LiveSplit → **Compare Against** → **Game Time** (required for
   load removal to be visible).

That's it — LiveSplit downloads the script and the `uhara10` component itself,
and updates automatically whenever the script is changed. Nothing to download by
hand.

## What your splits should look like

Just build these segments in LiveSplit (**Edit Splits**). A ready-made file is
also in this repo if you'd rather not type them:
[`Fading Echo/Fading Echo - Sources.lss`](Fading%20Echo/Fading%20Echo%20-%20Sources.lss).

### Default layout — 14 segments

This matches the script's default settings (12 sources + final boss + credits):

| # | Segment name | Splits when… |
|---|---|---|
| 1 | `Source 1` | you activate your **1st** Aetheric source |
| 2 | `Source 2` | you activate your 2nd source |
| 3 | `Source 3` | 3rd source |
| 4 | `Source 4` | 4th source |
| 5 | `Source 5` | 5th source |
| 6 | `Source 6` | 6th source |
| 7 | `Source 7` | 7th source |
| 8 | `Source 8` | 8th source |
| 9 | `Source 9` | 9th source |
| 10 | `Source 10` | 10th source |
| 11 | `Source 11` | 11th source |
| 12 | `Source 12` | your **12th / last** source |
| 13 | `Final Boss` | all 12 sources connected → the final fight opens |
| 14 | `Credits` | the end credits start |

In LiveSplit it looks like this:

```
┌──────────────────────────────┐
│  Fading Echo                 │
│  Any% (Sources)              │
├──────────────────────────────┤
│  Source 1              1:24  │
│  Source 2              3:07  │
│  Source 3              4:52  │
│      …                       │
│  Source 12            22:41  │
│  Final Boss           24:18  │
│  Credits              26:03  │
├──────────────────────────────┤
│                   26:03.55   │
└──────────────────────────────┘
```

> `Source 1` means **the first source you activate**, not one specific source in
> the world. So activate them in the **same order every run** and your segment
> times stay comparable.

### Alternative — zone layout

If you'd rather split per region, untick the source boxes and tick the zone
ones instead. Then your segments should be, **in your own route order**:

| # | Segment name |
|---|---|
| 1 | `Bastion` |
| 2 | *1st outer zone you visit* |
| 3 | *2nd outer zone* |
| 4 | *3rd outer zone* |
| 5 | *4th outer zone* |
| 6 | `Credits` |

### The one rule

**Number of ticked milestones = number of segments in your `.lss`**, in the
order the game fires them. Each ticked milestone advances LiveSplit by exactly
one segment. Tick / untick them in the component settings (every box has a
tooltip explaining it).

## Requirements

- LiveSplit.
- Compare against **Game Time**.

(The script and the [Uhara](https://github.com/ru-mii/uhara) `uhara10` component
are downloaded by LiveSplit automatically when you Activate the game — you don't
install anything by hand.)

## Credits

- Full-game script: this repo.
- Original demo autosplitter and reverse-engineering groundwork:
  **streetbackguy**.
- [Uhara](https://github.com/ru-mii/uhara) and
  [Unreal Logger](https://github.com/ru-mii/Unreal-Logger) by **ru-mii**.

## License

MIT — see [LICENSE](LICENSE).
