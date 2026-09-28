"""Build five standalone 2.0 preview folders from the stable 1.19.63 code."""
from pathlib import Path
import shutil
import re

root = Path(__file__).resolve().parents[1]
preview = root / "preview"

modules = [
    dict(addon="KayliiTargetAuras", id="buff", title="Buff White List", runtime="Core.lua",
         db="KayliiTargetAurasDB", char="KayliiTargetAurasCharacterDB", prefix="buff", init="", apply="RebuildManagedContainers",
         pages=[("Auras", [
             ("Enable target auras", "buffWhitelistModuleEnabled", "toggle", "SetBuffWhitelistModuleEnabled"),
             ("Also show on focus", "applyToFocus", "toggle", "RebuildManagedContainers"),
             ("Show only my buffs", "onlyMyBuffs", "toggle", "RebuildManagedContainers"),
             ("Show only my debuffs", "onlyMyDebuffs", "toggle", "RebuildManagedContainers"),
             ("Use buff filter", "useBuffFilter", "toggle", "RebuildManagedContainers"),
             ("Use debuff filter", "useDebuffFilter", "toggle", "RebuildManagedContainers"),
             ("Important boss buffs", "showImportantBossBuffs", "toggle", "RebuildManagedContainers"),
         ]), ("Layout", [
             ("Icon size", "iconSize", "number", "RebuildManagedContainers"),
             ("Buff columns", "buffColumns", "number", "RebuildManagedContainers"),
             ("Buff rows", "buffRows", "number", "RebuildManagedContainers"),
             ("Debuff columns", "debuffColumns", "number", "RebuildManagedContainers"),
             ("Debuff rows", "debuffRows", "number", "RebuildManagedContainers"),
             ("Show duration", "showBuffDuration", "toggle", "RebuildManagedContainers"),
             ("Show stacks", "showBuffStacks", "toggle", "RebuildManagedContainers"),
         ]), ("Spell lists", [("Buff whitelist", "buffs", "spells", "buff"),
                               ("Debuff whitelist", "debuffs", "spells", "debuff"),
                               ("Buff blacklist", "buffBlacklist", "blacklist", "buff"),
                               ("Debuff blacklist", "debuffBlacklist", "blacklist", "debuff")])],
         extra_defaults={"buffWhitelistModuleEnabled": True}),
    dict(addon="KayliiLustUp", id="lust", title="Lust Up", runtime="LustUp.lua",
         db="KayliiLustDB", char="KayliiLustCharacterDB", prefix="lustUp", init="InitializeLustUp", apply="ApplyLustUpSettings",
         pages=[("Readiness", [
             ("Enable Lust Up", "lustUpEnabled", "toggle", "ApplyLustUpSettings"),
             ("Require a Lust ability", "lustUpRequireLustAbility", "toggle", "ApplyLustUpSettings"),
             ("Allow drums", "lustUpAllowDrums", "toggle", "ApplyLustUpSettings"),
             ("Show in dungeons", "lustUpShowInDungeons", "toggle", "ApplyLustUpSettings"),
             ("Show in raids", "lustUpShowInRaids", "toggle", "ApplyLustUpSettings"),
             ("Only in combat", "lustUpOnlyInCombat", "toggle", "ApplyLustUpSettings"),
             ("Only in instances", "lustUpOnlyInInstance", "toggle", "ApplyLustUpSettings"),
         ]), ("Voice", [
             ("Voice alerts", "lustUpVoiceEnabled", "toggle", "ApplyLustUpSettings"),
             ("Ready announcement", "lustUpReadyVoiceText", "text", "ApplyLustUpSettings"),
             ("Boss pull alert", "lustUpBossPullVoiceEnabled", "toggle", "ApplyLustUpSettings"),
             ("Boss pull text", "lustUpBossPullVoiceText", "text", "ApplyLustUpSettings"),
             ("Test ready speech", "SpeakLustUp", "action", ""),
         ]), ("Appearance", [
             ("Unlock indicator", "lustUpUnlocked", "toggle", "SetLustUpUnlocked"),
             ("Indicator size", "lustUpSize", "number", "ApplyLustUpSettings"),
             ("Clickable indicator", "lustUpIndicatorClickable", "toggle", "SetLustUpIndicatorClickable"),
             ("Glow when ready", "lustUpReadyGlow", "toggle", "ApplyLustUpSettings"),
             ("Reset position", "ResetLustUpPosition", "action", ""),
         ])], extra_defaults={"lustUpEnabled": True,"lustUpCustomLockouts":{},"lustUpCustomDrumItems":{}}),
    dict(addon="KayliiStatsDisplay", id="stats", title="My Stats", runtime="StatsDisplay.lua",
         db="KayliiStatsDB", char="KayliiStatsCharacterDB", prefix="stats", init="InitializeStatsModule", apply="ApplyStatsSettings",
         pages=[("Display", [
             ("Enable My Stats", "statsModuleEnabled", "toggle", "SetStatsModuleEnabled"),
             ("Critical strike", "statsShowCrit", "toggle", "ApplyStatsSettings"),
             ("Haste", "statsShowHaste", "toggle", "ApplyStatsSettings"),
             ("Mastery", "statsShowMastery", "toggle", "ApplyStatsSettings"),
             ("Versatility", "statsShowVersatility", "toggle", "ApplyStatsSettings"),
             ("Show background", "statsShowBackground", "toggle", "ApplyStatsSettings"),
             ("Font size", "statsFontSize", "number", "ApplyStatsSettings"),
         ]), ("Placement", [
             ("Unlock position", "statsUnlocked", "toggle", "SetStatsUnlocked"),
             ("Only in combat", "statsOnlyInCombat", "toggle", "ApplyStatsSettings"),
             ("Only outside combat", "statsOnlyOutOfCombat", "toggle", "ApplyStatsSettings"),
             ("Only in instances", "statsOnlyInInstance", "toggle", "ApplyStatsSettings"),
             ("Reset position", "ResetStatsPosition", "action", ""),
         ])], extra_defaults={"statsModuleEnabled": False,"statsFontSize":14,"statsShowCrit":True,"statsShowHaste":True,"statsShowMastery":True,"statsShowVersatility":True}),
    dict(addon="KayliiTalentLoadout", id="talent", title="Talent Loadout", runtime="TalentLoadout.lua",
         db="KayliiTalentDB", char="KayliiTalentCharacterDB", prefix="talentLoadout", init="InitializeTalentLoadout", apply="ApplyTalentLoadoutSettings",
         pages=[("Display", [
             ("Enable Talent Loadout", "talentLoadoutEnabled", "toggle", "SetTalentLoadoutEnabled"),
             ("Show specialization", "talentLoadoutShowSpec", "toggle", "ApplyTalentLoadoutSettings"),
             ("Show loadout name", "talentLoadoutShowName", "toggle", "ApplyTalentLoadoutSettings"),
             ("Show Hero Talent", "talentLoadoutShowHero", "toggle", "ApplyTalentLoadoutSettings"),
             ("Show background", "talentLoadoutShowBackground", "toggle", "ApplyTalentLoadoutSettings"),
             ("Font size", "talentLoadoutFontSize", "number", "ApplyTalentLoadoutSettings"),
         ]), ("Placement", [
             ("Unlock position", "talentLoadoutUnlocked", "toggle", "SetTalentLoadoutUnlocked"),
             ("Reset position", "ResetTalentLoadoutPosition", "action", ""),
         ])], extra_defaults={"talentLoadoutEnabled":False,"talentLoadoutFontSize":14,"talentLoadoutShowSpec":True,"talentLoadoutShowName":True,"talentLoadoutShowHero":True}),
    dict(addon="KayliiRaidFrameSpec", id="raidspec", title="Raid Frame Spec", runtime="RaidFrameSpec.lua",
         db="KayliiRaidSpecDB", char="KayliiRaidSpecCharacterDB", prefix="raidFrameSpec", init="InitializeRaidFrameSpec", apply="QueueRaidFrameSpecApply",
         pages=[("Raid & party", [
             ("Enable per-spec layouts", "raidFrameSpecEnabled", "toggle", "SetRaidFrameSpecEnabled"),
             ("Manage raid frames", "raidFrameSpecManageRaid", "toggle", "QueueRaidFrameSpecApply"),
             ("Manage party frames", "raidFrameSpecManageParty", "toggle", "QueueRaidFrameSpecApply"),
             ("Show raid mover", "ShowRaidFrameSpecMover", "action", ""),
             ("Save raid position", "SaveRaidFrameSpecMoverPosition", "action", ""),
             ("Show party mover", "ShowPartyFrameSpecMover", "action", ""),
             ("Save party position", "SavePartyFrameSpecMoverPosition", "action", ""),
         ]), ("Saved specs", [
             ("Apply current spec", "QueueRaidFrameSpecApply", "action", ""),
             ("Hide movers", "HideRaidFrameSpecMovers", "action", ""),
         ])], extra_defaults={"raidFrameSpecEnabled":False,"raidFrameSpecManageRaid":True,"raidFrameSpecManageParty":True,"raidFrameSpecPositions":{},"partyFrameSpecPositions":{},"partyFrameSpecOrientations":{},"partyFrameSpecCustomEnabled":{},"raidFrameSpecScaleEnabled":{},"raidFrameSpecScaleValues":{},"partyFrameSpecScaleEnabled":{},"partyFrameSpecScaleValues":{},"raidFrameSpecEllesmereDefaults":{}}),
]

def literal(value):
    if isinstance(value, bool): return "true" if value else "false"
    if isinstance(value, dict): return "{}"
    if isinstance(value, str): return '"' + value.replace('"','\\"') + '"'
    return str(value)

for m in modules:
    directory = preview / m["addon"]
    directory.mkdir(exist_ok=True)
    source = (root / m["runtime"]).read_text()
    if m["id"] == "buff":
        start = source.index("function BW:InitializeDB()")
        end = source.index("\nend", start) + 4
        old = source[start:end]
        # Only the standalone copy uses a private table. The original stable file stays intact.
        new = old.replace("KayliiHelperDB", "privateDB").replace("BuffWhitelistDB", "privateDB")
        new = new.replace("KayliiHelperCharacterDB", "privateCharacterDB")
        new = new.replace("    privateDB = privateDB or privateDB or {}\nprivateDB = privateDB\n    privateCharacterDB = privateCharacterDB or {}", "    local privateDB = self.db or {}\n    local privateCharacterDB = self.characterDB or {}")
        assert "local privateDB = self.db" in new and "KayliiHelperDB" not in new
        source = source[:start] + new + source[end:]
    (directory / m["runtime"]).write_text(source)
    prefix = m["prefix"]
    matching = (f'type(key) == "string" and key:sub(1, {len(prefix)}) == "{prefix}"')
    aura_keys = set()
    core_source = (root / "Core.lua").read_text()
    defaults_source = core_source.split("local defaults = {", 1)[1].split("\n}\n\nlocal function CopyDefaults", 1)[0]
    full_defaults = {}
    for line in defaults_source.splitlines():
        match = re.match(r"^    (\w+) = (.+),$", line)
        if match:
            full_defaults[match[1]] = match[2]
    if m["id"] == "buff":
        aura_keys = {key for key in full_defaults if key.startswith((
            "buff", "debuff", "onlyMy", "useBuff", "useDebuff", "showBuff",
            "showDebuff", "hideBuff", "hideDebuff", "hidePermanent", "applyToFocus",
            "iconSize", "showImportantBoss", "showLayoutPreview"))}
        aura_keys.update(("buffs", "debuffs", "buffBlacklist", "debuffBlacklist"))
        matching = 'type(key) == "string" and migrationKeys[key] == true'
    elif m["id"] == "raidspec":
        matching = '(type(key) == "string" and (key:match("^raidFrameSpec") or key:match("^partyFrameSpec")))'
    if m["id"] == "buff":
        selected = aura_keys
    elif m["id"] == "raidspec":
        selected = {key for key in full_defaults if key.startswith(("raidFrameSpec", "partyFrameSpec"))}
    else:
        selected = {key for key in full_defaults if key.startswith(prefix)}
    selected.update(m["extra_defaults"])
    defaults = '\n'.join(f'    {key} = {full_defaults.get(key, literal(m["extra_defaults"].get(key)))},'
                         for key in sorted(selected))
    migration_keys = ('local migrationKeys = {\n' +
                      '\n'.join(f'    {key} = true,' for key in sorted(aura_keys)) +
                      '\n}\n') if aura_keys else ''
    pages = '\n'.join('    { title = '+literal(name)+', rows = {\n' +
                      '\n'.join('        { '+', '.join(literal(value) for value in row)+' },' for row in rows) +
                      '\n    } },' for name, rows in m["pages"])
    bootstrap = f'''local ADDON_NAME, module = ...
local defaults = {{
{defaults}
}}
{migration_keys}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copied = {{}}
    for key, child in pairs(value) do copied[Copy(key)] = Copy(child) end
    return copied
end

local function Initialize()
    _G.{m['db']} = type(_G.{m['db']}) == "table" and _G.{m['db']} or {{}}
    _G.{m['char']} = type(_G.{m['char']}) == "table" and _G.{m['char']} or {{}}
    module.db = _G.{m['db']}
    module.characterDB = _G.{m['char']}
    -- Never write to the legacy 1.x tables. Existing 2.x values win.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if ({matching}) and module.db[key] == nil then module.db[key] = Copy(value) end
        end
    end
    for key, value in pairs(defaults) do
        if module.db[key] == nil then module.db[key] = Copy(value) end
    end
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("{m['id']}", {{
            title = "{m['title']}", open = function() module:OpenWindow() end,
        }})
    end
end

module.title = "{m['title']}"
module.pages = {{
{pages}
}}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == ADDON_NAME then
        Initialize()
    elseif event == "PLAYER_LOGIN" then
        if not module.db then Initialize() end
        {'module:InitializeDB()' if m['id'] == 'buff' else 'module:'+m['init']+'()'}
    end
end)

SLASH_KAYLII_{m['id'].upper()}1 = "/kay{m['id']}"
SlashCmdList["KAYLII_{m['id'].upper()}"] = function() module:OpenWindow() end
'''
    (directory / "Bootstrap.lua").write_text(bootstrap)
    dependencies = "## OptionalDeps: KayliiHelper, EllesmereUIRaidFrames\n" if m["id"] == "raidspec" else "## OptionalDeps: KayliiHelper\n"
    toc = f'''## Interface: 120100
## Title: Kaylii {m['title']}
## Notes: Independent Kaylii Helper 2.0 module preview.
## Author: Kaylii
## IconTexture: Interface\\AddOns\\{m['addon']}\\Media\\KayliiIcon
## Version: 2.0.0-alpha.2
{dependencies}## SavedVariables: {m['db']}

Bootstrap.lua
{m['runtime']}
Window.lua
'''
    (directory / (m["addon"] + ".toc")).write_text(toc)
    shutil.copy(preview / "ModuleWindow.lua", directory / "Window.lua")

print("Generated", ", ".join(m["addon"] for m in modules))
