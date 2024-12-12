const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$f5d";
const string PluginIcon = Icons::Cogs;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

/**
 * - check/download birds.zip
 * - load birds.zip fid
 * - install fids (.UiInstallFids)
 * - load GameData\Stadium\MotionEmitterFlockModel\Birds.MotionEmitterFlockModel.Gbx
 * - find all CGameCtnBlockInfos (.EDClassic.Gbx files)
 * - for each
 *   - load Nod
 *   - add refcount to avoid unloading
 *   - for each variant:
 *     - add birds
 *     - add birds refcount
 *     - ? set flock launch Loc
 */


uint GetClassId(const string &in className) {
    auto ty = Reflection::GetType(className);
    return ty.ID;
}

// If this file doesn't exist, the plugin will copy it to this location
const string BIRDS_ZIP_GD_PATH = IO::FromAppFolder("GameData/Birds.zip");

void Main() {
    try {
        RunBirdsInit();
    } catch {
        auto e = getExceptionInfo();
        UI::ShowNotification(PluginName + " Error!", "Initialization failed: " + e, vec4(.9, .4, .1, 1), 7777);
    }
    startnew(LoadSettingsJsonToArr);
}

void RunBirdsInit() {
    CheckAndInitBirdsZip();
    RegisterLoadCallback(GetClassId("CGameCtnBlockInfo"));
    RegisterLoadCallback(GetClassId("CGameCtnBlockInfoClassic"));
    // RegisterLoadCallback(GetClassId("CGameCtnBlockInfoFlat"));
    auto zipFid = Fids::GetGame("GameData\\Birds.zip");
    auto zip = cast<CPlugFileZip>(Fids::Preload(zipFid));
    zip.UiInstallFids();
    auto birdsFid = Fids::GetGame("GameData\\Stadium\\MotionEmitterFlockModel\\Birds.MotionEmitterFlockModel.Gbx");
    @_birds = cast<CPlugFlockModel>(Fids::Preload(birdsFid));
    _birds.MwAddRef();
    trace("Birds loaded");
    return;
    // auto grassFid = _GetGameFid("GameData/Stadium/GameCtnBlockInfo/GameCtnBlockInfoFlat", "Grass.EDFlat.Gbx?1021");
    // auto grass = cast<CGameCtnBlockInfo>(grassFid.Nod);
    // if (grass is null) {
    //     trace('Grass not found, loading from file');
    //     @grass = cast<CGameCtnBlockInfo>(Fids::Preload(grassFid));
    // }
    // grass.MwAddRef();
    // auto grassVBG = grass.VariantBaseGround;
    // grassVBG.MwAddRef();
    // Dev::SetOffset(grassVBG, 0xA8, _birds);
}

// CSystemFidFile@ _GetGameFid(const string &in parentDir, const string &in fileName) {
//     trace("Fids::GetGameFolder(" + parentDir + ")");
//     auto gameDriveFolder = Fids::GetGameFolder("");
//     trace("GameDrive.FullDirName: " + gameDriveFolder.FullDirName);
//     auto parent = Fids::GetFidsFolder(gameDriveFolder, parentDir);
//     trace("parent null: " + (parent is null));
//     auto gdFolder = Fids::GetFidsFolder(gameDriveFolder, "GameData");
//     trace("gdFolder null: " + (gdFolder is null));
//     auto gdStadiumFolder = Fids::GetFidsFolder(gameDriveFolder, "GameData/Stadium");
//     trace("gdStadiumFolder null: " + (gdStadiumFolder is null));
//     // auto parent = Fids::GetGameFolder(parentDir);
//     for (uint i = 0; i < parent.Leaves.Length; i++) {
//         auto fid = parent.Leaves[i];
//         if (fid.FileName == fileName) {
//             trace("Found: " + fid.FileName);
//             return fid;
//         }
//     }
//     return null;
// }

/** Called when a Nod is loaded from a file. You have to call `RegisterLoadCallback` first before this is called. This callback is meant as an early callback for a loaded nod. If you're not sure whether you need an early callback and you can avoid using this callback, then avoid using this function.
*/
void OnLoadCallback(CMwNod@ nod) {
    auto blockInfo = cast<CGameCtnBlockInfo>(nod);
    if (blockInfo is null) {
        return;
    }
    if (_birds !is null && ApplyToBlockInfo(blockInfo)) {
        trace("\\$i\\$39fApplying birds to " + blockInfo.IdName);
        ApplyBirds(blockInfo.VariantBaseGround);
        ApplyBirds(blockInfo.VariantBaseAir);
        ApplyBirds(blockInfo.VariantAir);
        ApplyBirds(blockInfo.VariantGround);
        for (uint i = 0; i < blockInfo.AdditionalVariantsAir.Length; i++) {
            ApplyBirds(blockInfo.AdditionalVariantsAir[i]);
        }
        for (uint i = 0; i < blockInfo.AdditionalVariantsGround.Length; i++) {
            ApplyBirds(blockInfo.AdditionalVariantsGround[i]);
        }
    }
}

void ApplyBirds(CGameCtnBlockInfoVariant@ variant) {
    if (variant is null) {
        return;
    }
    if (variant.FlockModel is null) {
        Dev::SetOffset(variant, 0xA8, GetBirds());
        variant.FlockModel.MwAddRef();
    }
    variant.FlockEmitterLoc = mat4::Translate(vec3(16, 2, 16));
}

CPlugFlockModel@ _birds;

CPlugFlockModel@ GetBirds() {
    if (_birds is null) {
        auto birdsFid = Fids::GetGame("GameData\\Stadium\\MotionEmitterFlockModel\\Birds.MotionEmitterFlockModel.Gbx");
        @_birds = cast<CPlugFlockModel>(Fids::Preload(birdsFid));
        if (_birds !is null) _birds.MwAddRef();
    }
    return _birds;
}

bool ApplyToBlockInfo(CGameCtnBlockInfo@ bi) {
    return _AllowedNames.Find(bi.IdName) >= 0;
}

string[] _AllowedNames = {
    "RoadWaterSpecialTurbo",
    "RoadWaterStart",
    "RoadWaterFinish",
    "RoadWaterStraight",
    "RoadTechStraight",
    "RoadTechCurve1",
    "RoadTechCurve2"
};

void LoadSettingsJsonToArr() {
    try {
        auto j = Json::Parse(S_AddBirdsTo_Json);
        if (j is null) throw("null json parse");
        if (j.GetType() != Json::Type::Array) throw("s_json not array");
        _AllowedNames.Resize(0);
        for (uint i = 0; i < j.Length; i++) {
            if (j[i].GetType() != Json::Type::String) throw("s_json["+i+"] not string");
            _AllowedNames.InsertLast(j[i]);
        }
    } catch {
        string e = getExceptionInfo();
        trace("Failed to load settings json ("+e+"), using defaults.");
        SetAllowedNamesToDefault();
    }
}

void SetAllowedNamesToDefault() {
    _AllowedNames.Resize(0);
    ExtendArr(_AllowedNames, default_starts);
    ExtendArr(_AllowedNames, default_cps);
    ExtendArr(_AllowedNames, default_multilaps);
    ExtendArr(_AllowedNames, default_finishes);
    ExtendArr(_AllowedNames, default_curve2);
    ExtendArr(_AllowedNames, default_penalty);
    ExtendArr(_AllowedNames, default_transitions);
    S_Update_AddBirdsTo();
}

void ExtendArr(string[]@ arr, const string[] &in ext) {
    for (uint i = 0; i < ext.Length; i++) {
        arr.InsertLast(ext[i]);
    }
}
