// =============================================================================
//  Fading Echo (Project Ygro) - Load Remover / Autosplitter - FULL GAME
//  Minimal, null-safe (no casts), debug -> OutputDebugString (TraceSpy).
//  Splits: zones (LevelZone) + each SOURCE activated + credits.
//  Requires Uhara (Components/uhara10) + LiveSplit comparing against Game Time.
//
//  SOURCE DETECTION: we hook every function that could fire when you activate a
//  Bastion source and LOG each one ("SOURCE EVENT: <name>") so the moment you
//  activate a source, TraceSpy shows exactly which fired. The split is fired on
//  any of them, debounced so several hooks for one activation = one split.
// =============================================================================

state("UE_YGRO_Steam-Win64-Shipping")
{
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
    vars.Uhara.AlertLoadless();
    vars.Uhara.EnableDebug();

    dynamic[,] _settings =
    {
        { "FE", true, "Fading Echo - Full Game", null },
            { "ZONES", true, "Zone splits", "FE" },
                { "Reach_Bastion", true, "Reach Bastion", "ZONES" },
                { "Reach_Tree",    true, "Reach Big Tree", "ZONES" },
                { "Reach_Volcano", true, "Reach Volcano", "ZONES" },
                { "Reach_Quarry",  true, "Reach Quarry", "ZONES" },
                { "Reach_Wonder",  true, "Reach Wonder", "ZONES" },
            { "SOURCES", true, "Source splits (one per source activated)", "FE" },
                { "Src1",  true, "Source 1 activated",  "SOURCES" },
                { "Src2",  true, "Source 2 activated",  "SOURCES" },
                { "Src3",  true, "Source 3 activated",  "SOURCES" },
                { "Src4",  true, "Source 4 activated",  "SOURCES" },
                { "Src5",  true, "Source 5 activated",  "SOURCES" },
                { "Src6",  true, "Source 6 activated",  "SOURCES" },
                { "Src7",  true, "Source 7 activated",  "SOURCES" },
                { "Src8",  true, "Source 8 activated",  "SOURCES" },
                { "Src9",  true, "Source 9 activated",  "SOURCES" },
                { "Src10", true, "Source 10 activated", "SOURCES" },
                { "Src11", true, "Source 11 activated", "SOURCES" },
                { "Src12", true, "Source 12 activated", "SOURCES" },
            { "Credits",         true,  "End of run (credits)", "FE" },
            { "ResetOnMainMenu", false, "Reset when returning to the main menu", "FE" }
    };
    vars.Uhara.Settings.Create(_settings);
    vars.Splits = new HashSet<string>();
}

init
{
    vars.Utils  = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Events = vars.Uhara.CreateTool("UnrealEngine", "Events");

    vars.Resolver.Watch<bool>("GSync", vars.Utils.GSync);
    vars.Resolver.Watch<uint>("LoadingStep", vars.Utils.GEngine, 0x1248, 0x38, 0x0, 0x30, 0x830, 0x578);
    vars.Resolver.Watch<uint>("LevelZone",   vars.Utils.GEngine, 0x1248, 0x38, 0x0, 0x30, 0x830, 0x4B1);
    vars.Resolver.Watch<uint>("CutsceneIndex", vars.Utils.GWorld, 0x1A8, 0x4C0, 0x380);
    vars.Uhara["CutsceneIndex"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;

    // End of game.
    vars.Events.FunctionFlag("Credits", "WBP_CreditsScreen_C", "*WBP_CreditsScreen_C*", "StartCredits");

    // Source-activation candidates - hook them all, we log whichever fires.
    vars.Events.FunctionFlag("Src_Active",  "BP_BastionCenter_C",     "*BP_BastionCenter_C*",     "ActiveSourceCrystal");
    vars.Events.FunctionFlag("Src_One",     "YGRO_Global_Gameplay_C", "*YGRO_Global_Gameplay_C*", "OneSourceConnected");
    vars.Events.FunctionFlag("Src_MF",      "YGRO_Global_Gameplay_C", "*YGRO_Global_Gameplay_C*", "MFSourceConnected");
    vars.Events.FunctionFlag("Src_Add",     "BP_FinalSourceCrystal_C","*BP_FinalSourceCrystal_C*","AddConnectedSource");
    vars.Events.FunctionFlag("Src_Graph",   "BP_BastionCenter_C",     "*BP_BastionCenter_C*",     "OnSourcesGraphChanged");
    vars.Events.FunctionFlag("Src_Connect", "YGRO_Global_Gameplay_C", "*YGRO_Global_Gameplay_C*", "RE_ConnectSourceTuto");

    // All candidates are LOGGED. The split is driven by MFSourceConnected ONLY:
    // the 2-source test proved it fires exactly once per source activated, in
    // the zone where you activate it (Src_Graph was a Bastion graph-update that
    // double-counted). Reload copies of it are still filtered by the 5 s
    // post-zone-change guard below.
    vars.SrcFlags      = new string[] { "Src_Active", "Src_One", "Src_MF", "Src_Add", "Src_Graph", "Src_Connect" };
    vars.SrcSplitFlags = new string[] { "Src_MF" };
    vars.SourceCount = 0;
    vars.LastSourceTick = 0;
    vars.LastZoneChangeTick = 0;
}

update
{
    vars.Uhara.Update();

    if (old.LevelZone != current.LevelZone)
    {
        vars.Uhara.Log("LevelZone: " + old.LevelZone + " -> " + current.LevelZone);
        vars.LastZoneChangeTick = Environment.TickCount;  // for source-noise filter
    }
    if (old.LoadingStep != current.LoadingStep)
        vars.Uhara.Log("LoadingStep: " + current.LoadingStep);
    if (old.CutsceneIndex != current.CutsceneIndex)
        vars.Uhara.Log("CutsceneIndex: " + current.CutsceneIndex);

    // Log every source-candidate hook as it fires (works even before the run
    // starts, so you can confirm detection just by activating a source).
    foreach (var f in vars.SrcFlags)
        if (vars.Resolver.CheckFlag(f)) vars.Uhara.Log("SOURCE EVENT: " + f);
}

start
{
    // Start when entering the Tutorial zone (LevelZone becomes 5).
    return current.LevelZone == 5 && old.LevelZone != 5;
}

onStart
{
    vars.Splits.Clear();
    vars.SourceCount = 0;
    timer.IsGameTimePaused = true;
}

split
{
    // ---- Zone reached (LevelZone) -----------------------------------------
    if (old.LevelZone != current.LevelZone)
    {
        string zkey = null;
        if (current.LevelZone == 0) zkey = "Reach_Bastion";
        else if (current.LevelZone == 1) zkey = "Reach_Tree";
        else if (current.LevelZone == 2) zkey = "Reach_Volcano";
        else if (current.LevelZone == 3) zkey = "Reach_Quarry";
        else if (current.LevelZone == 4) zkey = "Reach_Wonder";

        if (zkey != null && !vars.Splits.Contains(zkey))
        {
            vars.Splits.Add(zkey);
            vars.Uhara.Log(">>> SPLIT " + zkey);
            return settings[zkey];
        }
    }

    // ---- Source activated -------------------------------------------------
    //   Fire on a source hook, but only when settled in a zone (>5 s since the
    //   last zone change, which filters Bastion-reload noise) and debounced
    //   (1.5 s, collapses the burst of hooks from one activation into 1 split).
    bool srcFired = false;
    foreach (var f in vars.SrcSplitFlags)
        if (vars.Resolver.CheckFlag(f)) { srcFired = true; break; }

    if (srcFired)
    {
        int now = Environment.TickCount;
        if (now - (int)vars.LastZoneChangeTick > 5000
            && now - (int)vars.LastSourceTick > 1500)
        {
            vars.LastSourceTick = now;
            vars.SourceCount = (int)vars.SourceCount + 1;
            string key = "Src" + vars.SourceCount;
            vars.Uhara.Log(">>> SPLIT " + key + " (source activated)");
            if (settings.ContainsKey(key)) return settings[key];
        }
    }

    // ---- End of game ------------------------------------------------------
    if (vars.Resolver.CheckFlag("Credits") && !vars.Splits.Contains("Credits"))
    {
        vars.Splits.Add("Credits");
        vars.Uhara.Log(">>> SPLIT Credits");
        return settings["Credits"];
    }
}

reset
{
    return settings["ResetOnMainMenu"] && current.LevelZone == 6 && old.LevelZone != 6;
}

isLoading
{
    return current.GSync || current.LoadingStep < 4 || current.CutsceneIndex > 0;
}

exit
{
    timer.IsGameTimePaused = true;
}
