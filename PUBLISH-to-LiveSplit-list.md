# Getting this autosplitter into LiveSplit's official list

LiveSplit fetches its autosplitter suggestions from one file:
`LiveSplit/LiveSplit.AutoSplitters` → `LiveSplit.AutoSplitters.xml`.

## Key facts (checked against the live list)

- The list has **2580 entries / 4330 game names, with zero duplicate game
  names** — so there can only be **one entry per game**. "Fading Echo" already
  exists (streetbackguy's demo autosplitter).
- **But one entry can hold several `.asl` scripts.** 3 entries already do this,
  and one of them is the exact analogue of our case — two autosplitters by two
  different authors under a single entry:

```xml
<AutoSplitter>
    <Games>
        <Game>Shady Knight</Game>
        <Game>Shady Knight Demo</Game>
    </Games>
    <URLs>
        <URL>...Supahsemmie/SK_LoadlessSplitter.asl</URL>
        <URL>...10-days-till-xmas/SK_splitter.asl</URL>
        <URL>...asl-help</URL>
    </URLs>
    <Type>Script</Type>
    <Description>Two autosplitters available: RT without loads (non-demo only) (by Supahsemmie) and IGT-only (by 10_days_till_xmas).</Description>
</AutoSplitter>
```

So the demo script and this full-game script can coexist in the single
"Fading Echo" entry, with the description telling runners which is which.

## The entry to use

Replace the existing "Fading Echo" block with this (demo script kept first,
full-game script added, `uhara10` component last):

```xml
<AutoSplitter>
    <Games>
        <Game>Fading Echo</Game>
    </Games>
    <URLs>
        <URL>https://raw.githubusercontent.com/streetbackguy/Autosplitter-Projects/refs/heads/main/Fading%20Echo/LiveSplit.FadingEcho.asl</URL>
        <URL>https://raw.githubusercontent.com/cheapmanga/FadingEcho-Autosplitter/refs/heads/main/Fading%20Echo/LiveSplit.FadingEcho.FullGame.asl</URL>
        <URL>https://github.com/ru-mii/uhara/raw/refs/heads/main/bin/uhara10</URL>
    </URLs>
    <Type>Script</Type>
    <Description>Two autosplitters available: Demo (by Streetbackguy) and Full Game (by cheapmanga). Load Remover, Autosplitting, Autostart and Autoreset.</Description>
</AutoSplitter>
```

Both raw-URL forms work (`/refs/heads/main/` and `/main/`); the `refs/heads`
form matches the style already used in the list.

## How to submit

1. Fork `https://github.com/LiveSplit/LiveSplit.AutoSplitters`.
2. Edit `LiveSplit.AutoSplitters.xml`, replacing the `Fading Echo` block.
3. Open a Pull Request.

## After it's merged

You never touch the list again. The entry points at this repo's raw URL, so
**any update you push here is picked up automatically** by LiveSplit — no new
PR needed. The only thing that would require another PR is **renaming or moving
the `.asl`** (that changes the URL), so keep the path
`Fading Echo/LiveSplit.FadingEcho.FullGame.asl` on `main` stable.

## Not required for personal use

None of this is needed to simply *use* the script: add a **Scriptable Auto
Splitter** component in your LiveSplit layout and point it at the local `.asl`.
