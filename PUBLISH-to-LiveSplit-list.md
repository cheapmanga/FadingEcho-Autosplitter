# Getting this autosplitter into LiveSplit's official list

LiveSplit fetches its autosplitter suggestions from one file:
`LiveSplit/LiveSplit.AutoSplitters` → `LiveSplit.AutoSplitters.xml`.
To make **this** full-game script appear (and be downloadable) for the game
"Fading Echo", add an entry that points at this repo's raw `.asl` URL.

## The entry to add

There is already a "Fading Echo" entry (streetbackguy's demo). Two options:

### Option A — a separate entry (keeps the demo one too)

Add a new `<AutoSplitter>` block, e.g. under a distinct game name so both show
up:

```xml
<AutoSplitter>
    <Games>
        <Game>Fading Echo</Game>
    </Games>
    <URLs>
        <URL>https://raw.githubusercontent.com/cheapmanga/FadingEcho-Autosplitter/main/Fading%20Echo/LiveSplit.FadingEcho.FullGame.asl</URL>
        <URL>https://github.com/ru-mii/uhara/raw/refs/heads/main/bin/uhara10</URL>
    </URLs>
    <Type>Script</Type>
    <Description>Full-game Load Remover, Autosplitting, Autostart and Autoreset</Description>
</AutoSplitter>
```

> Note: LiveSplit keys entries by `<Game>` name. Two entries with the same
> `<Game>` value will conflict in the picker, so if you want BOTH the demo and
> full-game splitters listed, coordinate with streetbackguy — the cleanest is a
> single entry pointing at whichever script should be the default, or a combined
> script. For your own use you do NOT need this list at all (the Layout
> component works directly with the local file).

### Option B — replace / update the existing entry

If it should simply become the maintained Fading Echo autosplitter, edit the
existing `<Game>Fading Echo</Game>` block's first `<URL>` to the raw URL above,
keeping the `uhara10` URL.

## How to submit

1. Fork `https://github.com/LiveSplit/LiveSplit.AutoSplitters`.
2. Edit `LiveSplit.AutoSplitters.xml` with the block above.
3. Open a Pull Request describing it as the full-game Fading Echo autosplitter.

Until (or instead of) that PR is merged, anyone can use the script by adding a
**Scriptable Auto Splitter** component in their LiveSplit layout and pointing it
at the raw URL or a downloaded copy — no list entry required.
