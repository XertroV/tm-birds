string[] BlockNames;
string[] LowerBlockNames;

// populates BlockNames and LowerBlockNames; idempotent
void UpdateBlockNamesAsync() {
    if (BlockNames.Length > 0) {
        return;
    }
    BlockNames.Reserve(4000);
    auto gdStadium = Fids::GetGameFolder("GameData/Stadium/GameCtnBlockInfo/GameCtnBlockInfoClassic");
    FindAndAddBlocks(gdStadium);
#if DEV
    print("Found " + BlockNames.Length + " blocks");
#endif
    yield();
    BlockNames.SortAsc();
    yield();
    LowerBlockNames.Reserve(4000);
    LowerBlockNames.Resize(BlockNames.Length);
    for (uint i = 0; i < BlockNames.Length; i++) {
        LowerBlockNames[i] = BlockNames[i].ToLower();
    }
}

void FindAndAddBlocks(CSystemFidsFolder@ folder) {
    for (uint i = 0; i < folder.Trees.Length; i++) {
        FindAndAddBlocks(folder.Trees[i]);
    }
    for (uint i = 0; i < folder.Leaves.Length; i++) {
        auto fid = folder.Leaves[i];
        if (fid.FileName.EndsWith(".EDClassic.Gbx")) {
            BlockNames.InsertLast(fid.FileName.SubStr(0, fid.FileName.Length - 14));
        }
    }
}
