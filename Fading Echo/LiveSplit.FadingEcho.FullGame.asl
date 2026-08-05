// =============================================================================
//  Fading Echo (Project Ygro) - Load Remover / Autosplitter - FULL GAME
//  v4 - source splits are driven by MissionFlow NODE STATE, not by function hooks.
//  Verified against the UE4SS CXXHeaderDump of build 1.0.28121.
//  Requires Uhara (Components/uhara10) + LiveSplit comparing against Game Time.
//
//  WHY v4 EXISTS
//  -------------
//  v3 hooked gameplay functions and split on "MFSourceConnected". That hook is
//  unreliable by construction: Uhara hooks UObject::ProcessEvent, which only
//  sees events and delegate broadcasts - never direct Blueprint function calls.
//  MFSourceConnected is not "a source was connected" at all: its signature is
//  (NewState, PreviousState, Node, bDebug), i.e. it is a MissionFlow node
//  state-change callback bound to ONE node. That is why it fired for the first
//  source of a region and never again, and never at all for Wonder.
//
//  v4 reads the ground truth instead. Every source owns two MissionFlow nodes:
//      MF_S_<Region>_<0..2>_U  -> source UNLOCKED (activated out in the world)
//      MF_S_<Region>_<0..2>_C  -> source CONNECTED (Bastion connection sequence)
//  A node is done when its CurrentState == 1 (Validated).
//
//  The 12 "_C" nodes are listed, in a fixed order, in
//      PH_BP_PerkSystemInteraction::NodesConnection  (TArray<UMF_Node_C*> @0x378)
//  as a Blueprint default value:
//      Quarry 0/1/2, Tree 0/1/2, Volcano 0/1/2, Wonder 0/1/2.
//  So we know both WHICH source each entry is and what state it is in.
//  Each matching "_U" node is the sibling of its "_C" node (same parent).
//
//  State is read from ABP_QuestManager_C::NodesStates, not from the node asset:
//  MF_Node_C::CurrentState is session-local and reads 0 for work already done
//  when a save is loaded. The quest manager's copy is the save-restored one.
//
//  Consequences: splits no longer care about the order you do the sources in,
//  cannot be duplicated by a Bastion reload, and cannot be missed.
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
            // Default run = 12 sources + final boss + credits.
            // Splits are CHRONOLOGICAL: "Source 1" is the first source you do,
            // whichever one it is. The log names the actual source.
            { "SOURCES", true, "Source splits (one per source, in the order you do them)", "FE" },
                { "Src1",  true, "Source 1",  "SOURCES" },
                { "Src2",  true, "Source 2",  "SOURCES" },
                { "Src3",  true, "Source 3",  "SOURCES" },
                { "Src4",  true, "Source 4",  "SOURCES" },
                { "Src5",  true, "Source 5",  "SOURCES" },
                { "Src6",  true, "Source 6",  "SOURCES" },
                { "Src7",  true, "Source 7",  "SOURCES" },
                { "Src8",  true, "Source 8",  "SOURCES" },
                { "Src9",  true, "Source 9",  "SOURCES" },
                { "Src10", true, "Source 10", "SOURCES" },
                { "Src11", true, "Source 11", "SOURCES" },
                { "Src12", true, "Source 12", "SOURCES" },
                // Which moment counts as "doing" a source. Default: the moment
                // you activate it out in the world. Tick the other one to split
                // on the Bastion connection sequence instead.
                { "OnConnected", false, "...split on CONNECTION instead (Bastion connection sequence)", "SOURCES" },
            { "FinalBoss", true, "Final boss (12/12 sources connected)", "FE" },
            { "Credits",   true, "End of run (credits screen)", "FE" },
            // Zone splits: OFF by default (enable if you want a per-zone run).
            { "ZONES", false, "Zone splits (optional)", "FE" },
                { "Reach_Bastion", false, "Reach Bastion", "ZONES" },
                { "Reach_Tree",    false, "Reach Big Tree", "ZONES" },
                { "Reach_Volcano", false, "Reach Volcano", "ZONES" },
                { "Reach_Quarry",  false, "Reach Quarry", "ZONES" },
                { "Reach_Wonder",  false, "Reach Wonder", "ZONES" },
            { "ResetOnMainMenu", false, "Reset when returning to the main menu", "FE" }
    };
    vars.Uhara.Settings.Create(_settings);

    // Fixed order of PH_BP_PerkSystemInteraction::NodesConnection (BP default).
    vars.SourceNames = new string[] {
        "Quarry 1", "Quarry 2", "Quarry 3",
        "Tree 1",   "Tree 2",   "Tree 3",
        "Volcano 1","Volcano 2","Volcano 3",
        "Wonder 1", "Wonder 2", "Wonder 3"
    };

    // ---- offsets, build 1.0.28121 (all re-checked against the UE4SS dump) ----
    vars.O_NodesConnection = 0x378;  // PH_BP_PerkSystemInteraction, TArray data ptr
    vars.O_NodesConnNum    = 0x380;  // ...and its element count
    vars.O_NodeParent      = 0x38;   // MF_Node_C::Parent
    vars.O_NodeChildren    = 0x40;   // MF_Node_C::Children (TSet data ptr)
    vars.O_NodeChildrenNum = 0x48;   // ...and its element count
    vars.O_NodeState       = 0x128;  // MF_Node_C::CurrentState (E_MF_State, 1 byte)
    vars.STATE_VALIDATED   = 1;      // E_MF_State: 0=Validable 1=Validated 2=Waiting
                                     //             3=Disabled  4=Failed    5=Asleep
    vars.STATE_MAX         = 5;      // anything above this is not a state at all,
                                     // it is memory that no longer belongs to us

    // Where node state is actually read from. MF_Node_C::CurrentState is
    // SESSION-LOCAL: it starts at the asset default and only moves for nodes
    // that change during the current session, so a loaded save reads 0 for work
    // already done. The persistent, save-restored copy lives in
    // ABP_QuestManager_C::NodesStates, reached from the game mode - a path that
    // exists at all times and needs no creation hook. CurrentState is kept only
    // as a fallback for when the quest manager cannot be found.
    vars.O_World_GameMode  = 0x1A8;  // UWorld -> AuthorityGameMode
    vars.O_GM_QuestCpt     = 0x408;  // BP_YgroGameMode::MF_QuestCpt
    vars.O_QC_Managers     = 0x110;  // MF_QuestCpt::Managers (TMap data ptr)
    vars.O_QM_NodesStates  = 0x308;  // BP_QuestManager::NodesStates (TMap data ptr)
    // TMap element stride: TPair(8+8, or 8+1 padded to 16) + HashNextId + HashIndex.
    vars.MAP_STRIDE        = 24;
    vars.MAP_VALUE         = 8;      // value sits right after the 8-byte key
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

    // The Bastion perk system owns the ordered list of the 12 "_C" nodes.
    vars.PerkSlot = vars.Events.InstancePtr("PH_BP_PerkSystemInteraction_C", "*PH_BP_PerkSystemInteraction*");

    // End of run. The credits widget being CREATED is a far more dependable
    // signal than hooking StartCredits (a plain BP call, invisible to a
    // ProcessEvent hook), so watch the instance-creation counter as well.
    vars.Resolver.Watch<ulong>("CreditsSpawn", vars.Events.InstanceFlag("WBP_CreditsScreen_C", "*WBP_CreditsScreen*"));
    vars.Events.FunctionFlag("CreditsFunc", "WBP_CreditsScreen_C", "*WBP_CreditsScreen_C*", "StartCredits");

    vars.NodesC   = new IntPtr[12];   // the 12 "_C" nodes, in NodesConnection order
    vars.NodesU   = new IntPtr[12];   // their "_U" siblings, same order
    vars.Done     = new bool[12];     // already split this run
    vars.NodesReady = false;
    vars.Splits   = new HashSet<string>();
    vars.SourceCount = 0;
    vars.Pending  = new List<string>(); // sources validated but not yet split

    // Resolve the 12 "_C" nodes (and their "_U" siblings) from the perk system.
    // Returns false until the Bastion - and therefore the perk system - exists.
    Func<bool> resolveNodes = () =>
    {
        try
        {
            IntPtr perk = game.ReadPointer((IntPtr)vars.PerkSlot);
            if (perk == IntPtr.Zero) return false;

            IntPtr arr = game.ReadPointer(perk + (int)vars.O_NodesConnection);
            int num    = game.ReadValue<int>(perk + (int)vars.O_NodesConnNum);
            if (arr == IntPtr.Zero || num != 12) return false;

            for (int i = 0; i < 12; i++)
            {
                IntPtr nodeC = game.ReadPointer(arr + 0x8 * i);
                if (nodeC == IntPtr.Zero) return false;
                vars.NodesC[i] = nodeC;

                // The "_U" node is the other child of this node's parent.
                vars.NodesU[i] = IntPtr.Zero;
                IntPtr parent = game.ReadPointer(nodeC + (int)vars.O_NodeParent);
                if (parent != IntPtr.Zero)
                {
                    IntPtr kids  = game.ReadPointer(parent + (int)vars.O_NodeChildren);
                    int kidCount = game.ReadValue<int>(parent + (int)vars.O_NodeChildrenNum);
                    if (kids != IntPtr.Zero && kidCount > 0 && kidCount <= 8)
                    {
                        // TSet element stride: value(8) + HashNextId(4) + HashIndex(4).
                        // Each MF_S_<Zone>_<n> has exactly two children, "_U"
                        // and "_C", so the sibling that is not our "_C" is the
                        // "_U". Cross-check its Parent before trusting it, in
                        // case we walked into a hole in the sparse array.
                        for (int k = 0; k < kidCount; k++)
                        {
                            IntPtr kid = game.ReadPointer(kids + 0x10 * k);
                            if (kid == IntPtr.Zero || kid == nodeC) continue;
                            if (game.ReadPointer(kid + (int)vars.O_NodeParent) != parent) continue;
                            vars.NodesU[i] = kid;
                            break;
                        }
                    }
                }
            }
            return true;
        }
        catch { return false; }
    };
    vars.ResolveNodes = resolveNodes;

    // State byte of an arbitrary node. -1 means "not readable right now" and is
    // never treated as progress.
    Func<IntPtr, int> nodeState = (node) =>
    {
        try
        {
            if (node == IntPtr.Zero) return -1;
            int s = game.ReadValue<byte>(node + (int)vars.O_NodeState);
            return (s <= (int)vars.STATE_MAX) ? s : -1;   // anything else is not a state
        }
        catch { return -1; }
    };
    vars.NodeState = nodeState;

    // Locate the quest manager that owns our 12 sources and remember, for each
    // node, its slot index in that manager's NodesStates map. We keep the index
    // rather than the address so a map reallocation cannot leave us reading a
    // stale slot.
    vars.QMgr    = IntPtr.Zero;
    vars.IdxC    = new int[12];
    vars.IdxU    = new int[12];
    vars.QMReady = false;
    vars.QMStale = false;
    vars.LastQMTry = 0;
    vars.PrevU   = new int[12];   // last logged node states, for change tracking
    vars.PrevC   = new int[12];

    Func<bool> resolveQuestStates = () =>
    {
        try
        {
            if (!vars.NodesReady) return false;

            IntPtr world = game.ReadPointer((IntPtr)vars.Utils.GWorld);
            if (world == IntPtr.Zero) return false;
            IntPtr gm = game.ReadPointer(world + (int)vars.O_World_GameMode);
            if (gm == IntPtr.Zero) return false;
            IntPtr qc = game.ReadPointer(gm + (int)vars.O_GM_QuestCpt);
            if (qc == IntPtr.Zero) return false;

            IntPtr mgrData = game.ReadPointer(qc + (int)vars.O_QC_Managers);
            int mgrNum     = game.ReadValue<int>(qc + (int)vars.O_QC_Managers + 0x8);
            if (mgrData == IntPtr.Zero || mgrNum <= 0 || mgrNum > 16) return false;

            for (int i = 0; i < 12; i++) { vars.IdxC[i] = -1; vars.IdxU[i] = -1; }

            int stride = (int)vars.MAP_STRIDE;
            for (int m = 0; m < mgrNum; m++)
            {
                IntPtr mgr = game.ReadPointer(mgrData + stride * m + 0x8);
                if (mgr == IntPtr.Zero) continue;

                IntPtr ns = game.ReadPointer(mgr + (int)vars.O_QM_NodesStates);
                int nsNum = game.ReadValue<int>(mgr + (int)vars.O_QM_NodesStates + 0x8);
                if (ns == IntPtr.Zero || nsNum <= 0 || nsNum > 512) continue;

                int hits = 0;
                for (int e = 0; e < nsNum; e++)
                {
                    // Free slots in the sparse array hold link data, which can
                    // never equal one of our node pointers, so they are harmless.
                    IntPtr key = game.ReadPointer(ns + stride * e);
                    if (key == IntPtr.Zero) continue;
                    for (int i = 0; i < 12; i++)
                    {
                        if (key == (IntPtr)vars.NodesC[i]) { vars.IdxC[i] = e; hits++; }
                        else if (key == (IntPtr)vars.NodesU[i]) { vars.IdxU[i] = e; hits++; }
                    }
                }
                if (hits >= 12) { vars.QMgr = mgr; return true; }
            }
            return false;
        }
        catch { return false; }
    };
    vars.ResolveQuestStates = resolveQuestStates;

    // Read the state stored at a slot, but ONLY if that slot still holds the
    // node we indexed. The quest manager is an actor: a level load can replace
    // it, or rebuild its map, and the cached address then points at reused
    // memory. Without this check we read arbitrary bytes, and any byte that
    // happens to equal 1 looks exactly like "source validated".
    Func<int, IntPtr, int> stateAtIdx = (idx, node) =>
    {
        try
        {
            if (idx < 0 || node == IntPtr.Zero || (IntPtr)vars.QMgr == IntPtr.Zero) return -1;
            IntPtr ns = game.ReadPointer((IntPtr)vars.QMgr + (int)vars.O_QM_NodesStates);
            if (ns == IntPtr.Zero) return -1;

            int stride = (int)vars.MAP_STRIDE;
            if (game.ReadPointer(ns + stride * idx) != node) return -1;   // stale

            int s = game.ReadValue<byte>(ns + stride * idx + (int)vars.MAP_VALUE);
            return (s <= (int)vars.STATE_MAX) ? s : -1;                   // out of range
        }
        catch { return -1; }
    };
    vars.StateAtIdx = stateAtIdx;

    // State of source i for the moment the user picked. Default is "_U"
    // (activated in the world); "_C" is the Bastion connection. If a "_U" node
    // could not be resolved we fall back to its "_C" so the split is late
    // rather than missing entirely - the resolve log says when that happens.
    // State of either node of source i. The quest manager's copy is the one
    // that survives a save load; the node asset is only a fallback.
    Func<int, bool, int> stateOf = (i, useConnected) =>
    {
        IntPtr node = useConnected ? (IntPtr)vars.NodesC[i] : (IntPtr)vars.NodesU[i];

        if ((bool)vars.QMReady)
        {
            int s = (int)vars.StateAtIdx(useConnected ? (int)vars.IdxC[i] : (int)vars.IdxU[i], node);
            if (s >= 0) return s;

            // Slot no longer ours. Ask for a re-resolve and report "unknown"
            // rather than falling back: the node asset's own CurrentState is
            // session-local, so using it here would silently rebuild the
            // baseline from wrong values.
            vars.QMStale = true;
            return -1;
        }

        return (int)vars.NodeState(node);
    };
    vars.StateOf = stateOf;

    Func<int, int> sourceState = (i) =>
    {
        bool useConnected = (bool)settings["OnConnected"]
                         || (IntPtr)vars.NodesU[i] == IntPtr.Zero;
        return (int)vars.StateOf(i, useConnected);
    };
    vars.SourceState = sourceState;

    // The final fight opens on 12 CONNECTED sources, whatever the split mode is.
    Func<int> connectedCount = () =>
    {
        int n = 0;
        for (int i = 0; i < 12; i++)
            if ((int)vars.StateOf(i, true) == (int)vars.STATE_VALIDATED) n++;
        return n;
    };
    vars.ConnectedCount = connectedCount;

    // Mark every already-done source as consumed, without splitting. Used at
    // run start so loading a mid-game save does not fire a burst of splits.
    Action rebase = () =>
    {
        int already = 0;
        for (int i = 0; i < 12; i++)
        {
            bool done = (vars.SourceState(i) == (int)vars.STATE_VALIDATED);
            vars.Done[i] = done;
            if (done) already++;
        }
        vars.SourceCount = already;
        vars.Pending.Clear();
        vars.Uhara.Log("Baseline: " + already + "/12 sources already done at run start.");

        // Same idea for the final fight: if the run starts from a save where the
        // 12 sources are already connected, the fight is long since open, so the
        // moment has passed - do not fire the split on the spot.
        int connected = vars.ConnectedCount();
        if (connected >= 12)
        {
            vars.Splits.Add("FinalBoss");
            vars.Uhara.Log("Baseline: 12/12 already connected, FinalBoss split consumed.");
        }
    };
    vars.Rebase = rebase;

    // Seed the change tracker so the states just printed are not logged again.
    Action seedPrev = () =>
    {
        for (int i = 0; i < 12; i++)
        {
            vars.PrevU[i] = (int)vars.StateOf(i, false);
            vars.PrevC[i] = (int)vars.StateOf(i, true);
        }
    };
    vars.SeedPrev = seedPrev;

    vars.Uhara.Log("=== Fading Echo autosplitter v4 (build 1.0.28121 offsets) ===");
}

update
{
    vars.Uhara.Update();

    // A read found a slot that no longer holds its node: the manager was
    // replaced or its map rebuilt. Drop the cache and resolve again rather
    // than keep reading dead memory.
    if ((bool)vars.QMStale)
    {
        vars.QMStale = false;
        if ((bool)vars.QMReady)
        {
            vars.QMReady = false;
            vars.QMgr = IntPtr.Zero;
            vars.Uhara.Log("QuestManager went stale (slot no longer holds its node) - re-resolving.");
        }
    }

    if (!vars.NodesReady)
    {
        if (vars.ResolveNodes())
        {
            vars.NodesReady = true;
            // Must run BEFORE the states are read or baselined below, or a
            // loaded save gets baselined from session-local values.
            vars.QMReady = vars.ResolveQuestStates();
            vars.Uhara.Log(((bool)vars.QMReady)
                ? "QuestManager found - reading save-restored node states."
                : "!! QuestManager NOT found - falling back to session-local states.");
            int missingU = 0;
            vars.Uhara.Log("MissionFlow nodes resolved (12 sources). Splitting on "
                + ((bool)settings["OnConnected"] ? "CONNECTION (_C)" : "ACTIVATION (_U)") + ".");
            for (int i = 0; i < 12; i++)
            {
                if ((IntPtr)vars.NodesU[i] == IntPtr.Zero) missingU++;
                vars.Uhara.Log("  [" + i + "] " + vars.SourceNames[i]
                    + "  _C=0x" + ((IntPtr)vars.NodesC[i]).ToString("X")
                    + "  _U=0x" + ((IntPtr)vars.NodesU[i]).ToString("X")
                    + "  state=" + vars.SourceState(i));
            }
            if (missingU > 0)
                vars.Uhara.Log("!! " + missingU + "/12 _U nodes unresolved - those sources "
                    + "fall back to splitting on connection. Report this log.");
            vars.SeedPrev();
            // Only meaningful if a run is already under way.
            if (timer.CurrentPhase == TimerPhase.Running) vars.Rebase();
        }
    }
    // The quest manager may spawn after the perk system; keep trying, but at
    // most once a second - a full scan is thousands of reads.
    else if (!(bool)vars.QMReady && Environment.TickCount - (int)vars.LastQMTry > 1000)
    {
        vars.LastQMTry = Environment.TickCount;
        if (vars.ResolveQuestStates())
        {
            vars.QMReady = true;
            vars.Uhara.Log("QuestManager found (late) - reading save-restored node states.");
            for (int i = 0; i < 12; i++)
                vars.Uhara.Log("  [" + i + "] " + vars.SourceNames[i] + "  state=" + vars.SourceState(i));

            // The states we are about to read are not the ones the baseline was
            // computed from: until now we were on the session-local copy, which
            // reads 0 for work already done. Without re-baselining here, every
            // source already done in the save looks like it was just activated
            // and fires a burst of splits.
            vars.SeedPrev();
            if (timer.CurrentPhase == TimerPhase.Running)
            {
                vars.Uhara.Log("Re-baselining on the save-restored states.");
                vars.Rebase();
            }
        }
    }

    if (old.LevelZone != current.LevelZone)
        vars.Uhara.Log("LevelZone: " + old.LevelZone + " -> " + current.LevelZone);
    if (old.LoadingStep != current.LoadingStep)
        vars.Uhara.Log("LoadingStep: " + current.LoadingStep);
    if (old.CutsceneIndex != current.CutsceneIndex)
        vars.Uhara.Log("CutsceneIndex: " + current.CutsceneIndex);

    // Log every node state change, split or not. Without this a source that
    // fails to split is undiagnosable: you cannot tell "the game never
    // validated the node" from "it did and the split logic missed it".
    if (vars.NodesReady)
    {
        for (int i = 0; i < 12; i++)
        {
            int su = (int)vars.StateOf(i, false);
            int sc = (int)vars.StateOf(i, true);
            if (su != (int)vars.PrevU[i])
            {
                vars.Uhara.Log("NODE " + vars.SourceNames[i] + " _U: " + vars.PrevU[i] + " -> " + su);
                vars.PrevU[i] = su;
            }
            if (sc != (int)vars.PrevC[i])
            {
                vars.Uhara.Log("NODE " + vars.SourceNames[i] + " _C: " + vars.PrevC[i] + " -> " + sc);
                vars.PrevC[i] = sc;
            }
        }
    }

    // Detect newly validated sources. Queued rather than split immediately so
    // two sources validating on the same tick still produce two splits.
    if (vars.NodesReady && timer.CurrentPhase == TimerPhase.Running)
    {
        for (int i = 0; i < 12; i++)
        {
            if (vars.Done[i]) continue;
            if (vars.SourceState(i) != (int)vars.STATE_VALIDATED) continue;

            vars.Done[i] = true;
            vars.SourceCount = (int)vars.SourceCount + 1;
            string label = "Source " + vars.SourceCount + " = " + vars.SourceNames[i]
                         + ((bool)settings["OnConnected"] ? " (connected)" : " (activated)");
            vars.Uhara.Log(">>> " + label);
            vars.Pending.Add("Src" + vars.SourceCount);
        }
    }
}

start
{
    // Start when entering the Tutorial zone (LevelZone becomes 5).
    return current.LevelZone == 5 && old.LevelZone != 5;
}

onStart
{
    vars.Splits.Clear();
    if (vars.NodesReady) vars.Rebase();
    else { vars.SourceCount = 0; vars.Pending.Clear(); }
    timer.IsGameTimePaused = true;
}

split
{
    // ---- Source done ------------------------------------------------------
    if (vars.Pending.Count > 0)
    {
        string key = vars.Pending[0];
        vars.Pending.RemoveAt(0);
        if (settings.ContainsKey(key) && settings[key])
        {
            vars.Uhara.Log(">>> SPLIT " + key);
            return true;
        }
    }

    // ---- Final boss: 12/12 CONNECTED (that is what opens the fight, whatever
    //      moment the source splits are set to) --------------------------------
    if (vars.NodesReady && !vars.Splits.Contains("FinalBoss") && vars.ConnectedCount() >= 12)
    {
        vars.Splits.Add("FinalBoss");
        if (settings["FinalBoss"])
        {
            vars.Uhara.Log(">>> SPLIT FinalBoss");
            return true;
        }
    }

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
            if (settings.ContainsKey(zkey) && settings[zkey])
            {
                vars.Uhara.Log(">>> SPLIT " + zkey);
                return true;
            }
        }
    }

    // ---- End of run: credits ----------------------------------------------
    bool creditsUp = vars.Resolver.CheckFlag("CreditsSpawn") || vars.Resolver.CheckFlag("CreditsFunc");
    if (creditsUp && !vars.Splits.Contains("Credits"))
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
