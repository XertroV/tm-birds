[Setting hidden]
string S_AddBirdsTo_Json = "null";

void S_Update_AddBirdsTo() {
    S_AddBirdsTo_Json = Json::Write(_AllowedNames.ToJson());
    Meta::SaveSettings();
}

[SettingsTab name="Block Selection" icon="Cube" order=1]
void RS_BlockSelection() {
    UI::Text("Which blocks should birds be added to?");
    UI::Indent();
    UI::TextWrapped("\\$i\\$fa7Warning: adding too many blocks can impact FPS, especially if a map uses hundreds or thousands of that block type.");
    UI::TextWrapped("\\$i\\$af7FYI: If the selected blocks have already been loaded, birds may not appear until a new map is loaded or a game restart.");
    UI::Unindent();
    UI::Separator();
    if (UI::Button("Add New")) {
        _AllowedNames.InsertLast("");
    }
    UI::SameLine();
    if (UI::Button("Remove Last")) {
        if (_AllowedNames.Length > 0) {
            _AllowedNames.RemoveAt(_AllowedNames.Length - 1);
            startnew(S_Update_AddBirdsTo);
        }
    }
    UI::SameLine();
    UI::Text("Total: " + _AllowedNames.Length);
    UI::SameLine();
    if (UI::Button("Reset to Defaults")) {
        SetAllowedNamesToDefault();
    }
    UI::Separator();
    if (UI::BeginChild("blkselch", vec2(0, 0))) {
        for (uint i = 0; i < _AllowedNames.Length; i++) {
            UI::PushID(i);
            bool changed = false;
            UI::SetNextItemWidth(300);
            _AllowedNames[i] = UI::InputText("##blknm" + tostring(i), _AllowedNames[i], changed);
            UI::SameLine();
            if (UI::Button(Icons::Trash + "##" + tostring(i))) {
                _AllowedNames.RemoveAt(i);
                i--;
                startnew(S_Update_AddBirdsTo);
            }
            UI::PopID();
            if (changed) {
                startnew(S_Update_AddBirdsTo);
            }
        }
    }
    UI::EndChild();
}

bool IsBlockSelected(const string &in bn) {
    return _AllowedNames.Find(bn) >= 0;
}

void AddBlock(const string &in bn, bool save_settings = true) {
    if (!IsBlockSelected(bn)) {
        _AllowedNames.InsertLast(bn);
        if (save_settings) {
            S_Update_AddBirdsTo();
        }
    }
}

void RemoveBlock(const string &in bn, bool save_settings = true) {
    int ix = _AllowedNames.Find(bn);
    if (ix >= 0) {
        _AllowedNames.RemoveAt(ix);
        if (save_settings) {
            S_Update_AddBirdsTo();
        }
    }
}


[SettingsTab name="Block List" icon="ListAlt" order=5]
void RS_BlockList() {
    startnew(UpdateBlockNamesAsync);

    Draw_FilterSearchBox();

    if (UI::BeginTable("blklist", 2, UI::TableFlags::SizingStretchSame)) {
        UI::TableSetupColumn("Block Name", UI::TableColumnFlags::DefaultSort | UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("Add/Rem Birds", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoResize);
        // UI::TableSetupColumn("Remove Birds", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoResize);

        auto @arr = FilteredBlockNames.Length > 0 ? FilteredBlockNames : BlockNames;


        UI::ListClipper clip(arr.Length);
        string bn;
        bool isSelected;
        while (clip.Step()) {
            for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                bn = arr[i];
                UI::PushID(bn);

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(bn);
                UI::TableNextColumn();

                isSelected = _AllowedNames.Find(bn) >= 0;
                if (isSelected) {
                    if (UI::ButtonColored(Icons::Minus, .1)) {
                        RemoveBlock(bn);
                    }
                } else {
                    if (UI::Button(Icons::Plus)) {
                        AddBlock(bn);
                    }
                }

                UI::PopID();
            }
        }
        UI::EndTable();
    }
}
