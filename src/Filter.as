string[] FilteredBlockNames;

string f_Term = "";


void Draw_FilterSearchBox() {
    bool changed = false;
    UI::SetNextItemWidth(200);
    f_Term = UI::InputText("Filter Blocks", f_Term, changed, UI::InputTextFlags::EnterReturnsTrue);
    if (changed) {
        startnew(Run_FilterBlockNames);
    }

    UI::SameLine();
    if (UI::Button("Reset##flt")) {
        f_Term = "";
        startnew(Run_FilterBlockNames);
    }

    UI::TextWrapped("\\$i\\$999Case insensitive, space = wildcard, <Enter> to update filter.");
}


void Run_FilterBlockNames() {
    FilteredBlockNames.Resize(0);

    auto parts = GetSearchParts(f_Term);
    if (parts.Length == 0) return;

    for (uint i = 0; i < LowerBlockNames.Length; i++) {
        if (MatchesParts(LowerBlockNames[i], parts)) {
            FilteredBlockNames.InsertLast(BlockNames[i]);
        }
    }

    if (FilteredBlockNames.Length == 0) {
        FilteredBlockNames.InsertLast("No blocks found");
    }
}

bool MatchesParts(const string &in name, string[]@ parts) {
    int minIx = 0;
    for (uint i = 0; i < parts.Length; i++) {
        auto ix = name.IndexOf(parts[i]);
        if (ix < minIx) {
            return false;
        }
        minIx = ix + parts[i].Length;
    }
    return true;
}


string[]@ GetSearchParts(const string &in term) {
    if (term.Length == 0) {
        return {};
    }
    auto parts = term.Split(" ");
    for (uint i = 0; i < parts.Length; i++) {
        if (parts[i].Length == 0) {
            parts.RemoveAt(i);
            i--;
            continue;
        }
        parts[i] = parts[i].ToLower();
    }
    return parts;
}
