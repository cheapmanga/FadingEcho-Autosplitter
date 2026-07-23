# Fading Echo — Full Game Load Remover / Autosplitter (LiveSplit)

A LiveSplit auto-splitter and load remover for the **full game** of
[Fading Echo](https://store.steampowered.com/) (*Project Ygro*), built with the
[Uhara](https://github.com/ru-mii/uhara) library.

Based on and grateful to **streetbackguy**'s Fading Echo *demo* autosplitter —
this is the full-game counterpart.

**File:** [`Fading Echo/LiveSplit.FadingEcho.FullGame.asl`](Fading%20Echo/LiveSplit.FadingEcho.FullGame.asl)

---

## Features

- **Load removal** — pauses the timer during zone loads, engine blocking loads
  and cutscenes.
- **Auto start** — starts on entering the Tutorial zone (new game).
- **Zone splits** — one split each time you reach a gameplay zone (Bastion,
  Big Tree, Volcano, Quarry, Wonder).
- **Source splits** — one split each time you activate an Aetheric source
  (driven by the `MFSourceConnected` gameplay event).
- **Auto reset** — optional, on returning to the main menu.

## Install

1. Put **`uhara10`** (from the [Uhara releases](https://github.com/ru-mii/uhara/tree/main/bin))
   into LiveSplit's `Components` folder (exact name `uhara10`, no extension).
2. Download `LiveSplit.FadingEcho.FullGame.asl` from this repo.
3. In LiveSplit: right-click → **Edit Layout** → `+` → **Control** →
   **Scriptable Auto Splitter** → **Browse** to the `.asl`.
4. Right-click LiveSplit → **Compare Against** → **Game Time** (required for
   load removal to be visible).

## How the splits work (important)

Each ticked milestone advances LiveSplit by **one segment**, in the order the
game fires them. So:

- Zone splits fire **in the order you visit the zones**, not in a fixed zone
  order. Enable only the zones your route goes through, and lay out your splits
  file (`.lss`) segments **in your route order**.
- The number of ticked milestones must equal the number of segments in your
  `.lss`.

Tick / untick milestones in the component settings (each has a tooltip).

## Requirements

- LiveSplit with the Scriptable Auto Splitter component.
- The [Uhara](https://github.com/ru-mii/uhara) `uhara10` component.
- Compare against **Game Time**.

## Credits

- Full-game script: this repo.
- Original demo autosplitter and reverse-engineering groundwork:
  **streetbackguy**.
- [Uhara](https://github.com/ru-mii/uhara) and
  [Unreal Logger](https://github.com/ru-mii/Unreal-Logger) by **ru-mii**.

## License

MIT — see [LICENSE](LICENSE).
