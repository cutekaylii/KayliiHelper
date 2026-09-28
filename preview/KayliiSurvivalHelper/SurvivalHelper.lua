local ADDON_NAME, BW = ...

local HEALTHSTONE_ITEMS = {
    224464, -- Demonic Healthstone
    5512,   -- Healthstone
}

local HEALING_POTION_ITEMS = {
    -- Midnight
    271884,
    271883,
    241304,
    241305,
    258138,

    -- The War Within fallbacks
    244849,
    244839,
    244838,
    244835,
    212944,
    211880,
    211879,
    211878,
}

-- Built-in personal defensives.  Only spells the current character actually
-- knows are considered available.  The user can add arbitrary future spells
-- and items from the options page without changing this table.
local PERSONAL_DEFENSIVES = {
    DEATHKNIGHT = { 48792, 55233 },       -- Icebound Fortitude, Vampiric Blood
    DEMONHUNTER = { 198589 },             -- Blur
    DRUID       = { 22812, 61336 },       -- Barkskin, Survival Instincts
    EVOKER      = { 363916 },             -- Obsidian Scales
    HUNTER      = { 264735, 109304 },     -- Survival of the Fittest, Exhilaration
    MAGE        = { 45438, 110959 },      -- Ice Block, Greater Invisibility
    MONK        = { 115203, 122783 },     -- Fortifying Brew, Diffuse Magic
    PALADIN     = { 498, 642 },           -- Divine Protection, Divine Shield
    PRIEST      = { 47585, 19236 },       -- Dispersion, Desperate Prayer
    ROGUE       = { 1966, 31224, 5277 },  -- Feint, Cloak of Shadows, Evasion
    SHAMAN      = { 108271 },             -- Astral Shift
    WARLOCK     = { 104773, 108416 },     -- Unending Resolve, Dark Pact
    WARRIOR     = { 118038, 12975 },      -- Die by the Sword, Last Stand
}

local ACTION_COLORS = {
    personal = { 0.32, 0.68, 1.00, 1 },
    healthstone = { 0.72, 0.42, 1.00, 1 },
    potion = { 0.36, 0.90, 0.48, 1 },
    custom = { 1.00, 0.72, 0.28, 1 },
}


-- Death-sound library mirrored from the LowHealthHelper archive supplied by
-- the user.  The source archive defines one extra entry (Cartoon Hop) whose
-- referenced audio file is not present in that archive, so only working
-- entries are included here.
BW.SurvivalDeathSounds = {
    { key = "Acoustic Guitar", label = "Acoustic Guitar", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\AcousticGuitar.ogg" },
    { key = "Aggro", label = "Aggro", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\aggro.ogg" },
    { key = "Air Horn", label = "Air Horn", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\AirHorn.ogg" },
    { key = "Applause", label = "Applause", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Applause.ogg" },
    { key = "Arrow Swoosh", label = "Arrow Swoosh", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\Arrow_Swoosh.ogg" },
    { key = "Bam", label = "Bam", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\bam.ogg" },
    { key = "Banana Peel Slip", label = "Banana Peel Slip", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\BananaPeelSlip.ogg" },
    { key = "Bass Drop", label = "Bass Drop", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\bassdrop2.mp3" },
    { key = "Batman Punch", label = "Batman Punch", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\BatmanPunch.ogg" },
    { key = "Big Kiss", label = "Big Kiss", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\bigkiss.ogg" },
    { key = "Bike Horn", label = "Bike Horn", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\BikeHorn.ogg" },
    { key = "Bite", label = "Bite", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\BITE.ogg" },
    { key = "Blast", label = "Blast", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Blast.ogg" },
    { key = "Bleat", label = "Bleat", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Bleat.ogg" },
    { key = "Boxing Arena Gong", label = "Boxing Arena Gong", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\BoxingArenaSound.ogg" },
    { key = "Brass", label = "Brass", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Brass.mp3" },
    { key = "Burp", label = "Burp", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\burp4.ogg" },
    { key = "Cartoon Voice Baritone", label = "Cartoon Voice Baritone", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\CartoonVoiceBaritone.ogg" },
    { key = "Cartoon Walking", label = "Cartoon Walking", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\CartoonWalking.ogg" },
    { key = "Cat", label = "Cat", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\cat2.ogg" },
    { key = "Cat Meow", label = "Cat Meow", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\CatMeow2.ogg" },
    { key = "Chant Major 2nd", label = "Chant Major 2nd", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\chant2.ogg" },
    { key = "Chant Minor 3rd", label = "Chant Minor 3rd", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\chant4.ogg" },
    { key = "Chicken Alarm", label = "Chicken Alarm", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\ChickenAlarm.ogg" },
    { key = "Chimes", label = "Chimes", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\chimes.ogg" },
    { key = "Cookie Monster", label = "Cookie Monster", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\cookie.ogg" },
    { key = "Cow Mooing", label = "Cow Mooing", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\CowMooing.ogg" },
    { key = "Double Whoosh", label = "Double Whoosh", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\DoubleWhoosh.ogg" },
    { key = "Drums", label = "Drums", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Drums.ogg" },
    { key = "Electrical Spark", label = "Electrical Spark", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\ESPARK1.ogg" },
    { key = "Error Beep", label = "Error Beep", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\ErrorBeep.ogg" },
    { key = "Fireball", label = "Fireball", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\Fireball.ogg" },
    { key = "Gasp", label = "Gasp", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\Gasp.ogg" },
    { key = "Glass", label = "Glass", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Glass.mp3" },
    { key = "Goat Bleeting", label = "Goat Bleeting", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\GoatBleating.ogg" },
    { key = "Gun 2", label = "Gun 2", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\sound_gun2.ogg" },
    { key = "Gun 3", label = "Gun 3", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\sound_gun3.ogg" },
    { key = "Gunshot", label = "Gunshot", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\shot.ogg" },
    { key = "Heartbeat", label = "Heartbeat", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\heartbeat.ogg" },
    { key = "Heartbeat Single", label = "Heartbeat Single", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\HeartbeatSingle.ogg" },
    { key = "Hiccup", label = "Hiccup", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\hic3.ogg" },
    { key = "Horn", label = "Horn", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\Details Horn.ogg" },
    { key = "Huh?", label = "Huh?", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\huh_1.ogg" },
    { key = "Hurricane", label = "Hurricane", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\hurricane.ogg" },
    { key = "Hyena", label = "Hyena", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\hyena.ogg" },
    { key = "Jedi", label = "Jedi", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\sound_jedi1.ogg" },
    { key = "Kaching", label = "Kaching", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\kaching.ogg" },
    { key = "Kitten Meow", label = "Kitten Meow", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\KittenMeow.ogg" },
    { key = "Lich King Apocalypse", label = "Lich King Apocalypse", soundID = 554003 },
    { key = "Moan", label = "Moan", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\moan.ogg" },
    { key = "Oh No", label = "Oh No", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\OhNo.ogg" },
    { key = "Panther", label = "Panther", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\panther1.ogg" },
    { key = "Phone", label = "Phone", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\phone.ogg" },
    { key = "Polar Bear", label = "Polar Bear", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\bear_polar.ogg" },
    { key = "Punch", label = "Punch", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\PUNCH.ogg" },
    { key = "Quest Failed", label = "Quest Failed", soundID = 847 },
    { key = "Rain", label = "Rain", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\rainroof.ogg" },
    { key = "Ringing Phone", label = "Ringing Phone", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\RingingPhone.ogg" },
    { key = "Roaring Lion", label = "Roaring Lion", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\RoaringLion.ogg" },
    { key = "Robot Blip", label = "Robot Blip", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\RobotBlip.ogg" },
    { key = "Rocket", label = "Rocket", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\rocket.ogg" },
    { key = "Rooster Chicken Call", label = "Rooster Chicken Call", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\RoosterChickenCalls.ogg" },
    { key = "Sharp Punch", label = "Sharp Punch", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\SharpPunch.ogg" },
    { key = "Sheep Blerping", label = "Sheep Blerping", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\SheepBleat.ogg" },
    { key = "Ship's Whistle", label = "Ship's Whistle", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\shipswhistle.ogg" },
    { key = "Shotgun", label = "Shotgun", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Shotgun.ogg" },
    { key = "Snake Attack", label = "Snake Attack", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\snakeatt.ogg" },
    { key = "Sneeze", label = "Sneeze", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\sneeze.ogg" },
    { key = "Sonar", label = "Sonar", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\sonar.ogg" },
    { key = "Splash", label = "Splash", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\splash.ogg" },
    { key = "Squeaky Toy", label = "Squeaky Toy", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\Squeakypig.ogg" },
    { key = "Squeaky Toy Short", label = "Squeaky Toy Short", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\SqueakyToyShort.ogg" },
    { key = "Squish Fart", label = "Squish Fart", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\SquishFart.ogg" },
    { key = "Sword Ring", label = "Sword Ring", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\swordecho.ogg" },
    { key = "Synth Chord", label = "Synth Chord", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\SynthChord.ogg" },
    { key = "Tada Fanfare", label = "Tada Fanfare", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\TadaFanfare.ogg" },
    { key = "Temple Bell", label = "Temple Bell", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\TempleBellHuge.ogg" },
    { key = "Throwing Knife", label = "Throwing Knife", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\throwknife.ogg" },
    { key = "Thunder", label = "Thunder", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\thunder.ogg" },
    { key = "Torch", label = "Torch", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Torch.ogg" },
    { key = "Truck", label = "Truck", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\Details Truck.ogg" },
    { key = "Voice: Adds", label = "Voice: Adds", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Adds.ogg" },
    { key = "Voice: Boss", label = "Voice: Boss", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Boss.ogg" },
    { key = "Voice: Circle", label = "Voice: Circle", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Circle.ogg" },
    { key = "Voice: Cross", label = "Voice: Cross", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Cross.ogg" },
    { key = "Voice: Diamond", label = "Voice: Diamond", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Diamond.ogg" },
    { key = "Voice: Don't Release", label = "Voice: Don't Release", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\DontRelease.ogg" },
    { key = "Voice: Empowered", label = "Voice: Empowered", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Empowered.ogg" },
    { key = "Voice: Focus", label = "Voice: Focus", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Focus.ogg" },
    { key = "Voice: Idiot", label = "Voice: Idiot", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Idiot.ogg" },
    { key = "Voice: Left", label = "Voice: Left", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Left.ogg" },
    { key = "Voice: Moon", label = "Voice: Moon", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Moon.ogg" },
    { key = "Voice: Next", label = "Voice: Next", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Next.ogg" },
    { key = "Voice: Portal", label = "Voice: Portal", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Portal.ogg" },
    { key = "Voice: Protected", label = "Voice: Protected", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Protected.ogg" },
    { key = "Voice: Release", label = "Voice: Release", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Release.ogg" },
    { key = "Voice: Right", label = "Voice: Right", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Right.ogg" },
    { key = "Voice: Run Away", label = "Voice: Run Away", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\RunAway.ogg" },
    { key = "Voice: Skull", label = "Voice: Skull", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Skull.ogg" },
    { key = "Voice: Spread", label = "Voice: Spread", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Spread.ogg" },
    { key = "Voice: Square", label = "Voice: Square", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Square.ogg" },
    { key = "Voice: Stack", label = "Voice: Stack", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Stack.ogg" },
    { key = "Voice: Star", label = "Voice: Star", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Star.ogg" },
    { key = "Voice: Switch", label = "Voice: Switch", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Switch.ogg" },
    { key = "Voice: Taunt", label = "Voice: Taunt", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Taunt.ogg" },
    { key = "Voice: Triangle", label = "Voice: Triangle", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Triangle.ogg" },
    { key = "Warning 100", label = "Warning 100", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\Details Warning 100.ogg" },
    { key = "Warning Siren", label = "Warning Siren", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\WarningSiren.ogg" },
    { key = "Water Drop", label = "Water Drop", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\WaterDrop.ogg" },
    { key = "Whip", label = "Whip", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\DetailsSounds\\sound_whip1.ogg" },
    { key = "Wicked Female Laugh", label = "Wicked Female Laugh", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\wlaugh.ogg" },
    { key = "Wicked Male Laugh", label = "Wicked Male Laugh", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\wickedmalelaugh1.ogg" },
    { key = "Wilhelm Scream", label = "Wilhelm Scream", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\wilhelm.ogg" },
    { key = "Wolf Howl", label = "Wolf Howl", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\wolf5.ogg" },
    { key = "Xylophone", label = "Xylophone", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\Sounds\\Xylophone.ogg" },
    { key = "Yeehaw", label = "Yeehaw", path = "Interface\\AddOns\\KayliiSurvivalHelper\\Media\\SurvivalSounds\\PowerAurasMedia\\Sounds\\yeehaw.ogg" },
}

-- The threshold alert has its own sound selector and saved key. Choices may
-- use the same bundled audio files as the death selector, but selection is
-- fully independent.
BW.SurvivalAlertSounds = {
    { key = "off", label = "Off" },
    { key = "blizzardPulse", label = "Blizzard health pulse" },
}
for _, option in ipairs(BW.SurvivalDeathSounds) do
    BW.SurvivalAlertSounds[#BW.SurvivalAlertSounds + 1] = {
        key = option.key,
        label = option.label,
        soundID = option.soundID,
        path = option.path,
    }
end

local function Clamp(value, low, high)
    value = tonumber(value) or low

    if value < low then
        return low
    elseif value > high then
        return high
    end

    return value
end

local function IsSecret(value)
    if type(issecretvalue) ~= "function" then
        return false
    end

    local ok, result = pcall(issecretvalue, value)
    return ok and result and true or false
end

-- Midnight can return secret booleans from spell/item APIs in combat.
-- Branching on one directly throws a taint error, so prove booleans first.
local function NormalBoolean(value)
    if IsSecret(value) then return nil end
    if type(value) == "boolean" then return value end
    return nil
end

-- Midnight exposes UnitHealthPercent specifically so addons can make normal
-- percentage-based decisions without touching secret UnitHealth values.  Do
-- not pass a display curve here: the plain return is what we need for the
-- global Survival trigger and for TTS transition detection.
local function GetPlayerHealthPercent()
    if type(UnitHealthPercent) == "function" then
        -- UnitHealthPercent's native domain is 0..1.  Blizzard's ScaleTo100
        -- curve is the supported way to obtain a branchable 0..100 value.
        if CurveConstants and CurveConstants.ScaleTo100 then
            local ok, value = pcall(
                UnitHealthPercent,
                "player",
                true,
                CurveConstants.ScaleTo100
            )

            if ok and value ~= nil and not IsSecret(value) then
                value = tonumber(value)
                if value then
                    return Clamp(value, 0, 100)
                end
            end
        end

        -- Fallback for builds where the scale constant is missing.
        local ok, value = pcall(UnitHealthPercent, "player", true)
        if ok and value ~= nil and not IsSecret(value) then
            value = tonumber(value)
            if value then
                if value <= 1 then
                    value = value * 100
                end
                return Clamp(value, 0, 100)
            end
        end
    end

    -- Compatibility fallback for clients where UnitHealthPercent is absent.
    local health = UnitHealth and UnitHealth("player")
    local maximum = UnitHealthMax and UnitHealthMax("player")

    if health == nil
        or maximum == nil
        or IsSecret(health)
        or IsSecret(maximum) then

        return nil
    end

    health = tonumber(health)
    maximum = tonumber(maximum)

    if not health or not maximum or maximum <= 0 then
        return nil
    end

    return Clamp((health / maximum) * 100, 0, 100)
end

-- Midnight-safe branchable threshold gate. The game evaluates the health
-- percentage against a curve internally; Lua only asks whether the resulting
-- value is zero/non-zero. This lets us detect one configured threshold without
-- reading or reconstructing the protected HP value.
local survivalThresholdCurves = {}
local survivalZeroScratch
local survivalZeroCheckScratch
local survivalZeroCanClear
local survivalZeroProbeValue

local function NewHiddenFontString()
    local okFrame, holder = pcall(CreateFrame, "Frame")
    if not okFrame or not holder then return nil end
    holder:Hide()

    local okText, fs = pcall(
        holder.CreateFontString,
        holder,
        nil,
        "BACKGROUND",
        "GameFontNormal"
    )
    if not okText or not fs then return nil end
    return fs
end

local function SecretZeroProbe()
    if survivalZeroCanClear and survivalZeroScratch.ClearText then
        survivalZeroScratch:ClearText()
    end
    survivalZeroScratch:SetText(
        C_StringUtil.TruncateWhenZero(survivalZeroProbeValue) or ""
    )
    return survivalZeroScratch:GetText()
end

local function TextReadbackWorks()
    if survivalZeroCheckScratch == nil then
        survivalZeroCheckScratch = NewHiddenFontString() or false
    end
    if not survivalZeroCheckScratch then return false end

    local ok, value = pcall(function()
        if survivalZeroCheckScratch.ClearText then
            survivalZeroCheckScratch:ClearText()
        end
        survivalZeroCheckScratch:SetText("1")
        return survivalZeroCheckScratch:GetText()
    end)

    return ok and value == "1"
end

local function IsZeroWithoutReadingSecret(value)
    if value == nil then return true end

    if not IsSecret(value) then
        return type(value) == "number" and value == 0 or nil
    end

    if not (C_StringUtil and C_StringUtil.TruncateWhenZero) then
        return nil
    end

    if survivalZeroScratch == nil then
        survivalZeroScratch = NewHiddenFontString() or false
        if survivalZeroScratch then
            survivalZeroCanClear = survivalZeroScratch.ClearText
                and pcall(survivalZeroScratch.ClearText, survivalZeroScratch)
                or false
        end
    end
    if not survivalZeroScratch then return nil end

    survivalZeroProbeValue = value
    local ok, textValue = pcall(SecretZeroProbe)
    survivalZeroProbeValue = nil
    if not ok then return nil end

    if textValue then
        return false
    end

    if not TextReadbackWorks() then
        return nil
    end

    return true
end

local function GetSurvivalThresholdCurve(percent)
    percent = math.floor(Clamp(percent or 30, 5, 95) * 10 + 0.5) / 10
    if survivalThresholdCurves[percent] ~= nil then
        return survivalThresholdCurves[percent] or nil
    end

    local curveUtil = C_CurveUtil
    local linear = Enum and Enum.LuaCurveType and Enum.LuaCurveType.Linear
    if not (curveUtil and curveUtil.CreateCurve and linear) then
        survivalThresholdCurves[percent] = false
        return nil
    end

    local ok, curve = pcall(curveUtil.CreateCurve)
    if not ok or not curve then
        survivalThresholdCurves[percent] = false
        return nil
    end

    local threshold = percent / 100
    local epsilon = 0.001
    local built = pcall(function()
        curve:SetType(linear)
        curve:AddPoint(0, 100)
        curve:AddPoint(math.max(0, threshold - epsilon), 100)
        curve:AddPoint(math.min(1, threshold + epsilon), 0)
        curve:AddPoint(1, 0)
    end)

    if not built then
        survivalThresholdCurves[percent] = false
        return nil
    end

    -- Plain-value self-test so a changed curve API fails closed.
    local okLow, lowValue = pcall(curve.Evaluate, curve, math.max(0, threshold - 0.01))
    local okHigh, highValue = pcall(curve.Evaluate, curve, math.min(1, threshold + 0.01))
    if not (
        okLow
        and okHigh
        and type(lowValue) == "number"
        and type(highValue) == "number"
        and lowValue >= 1
        and highValue < 1
    ) then
        survivalThresholdCurves[percent] = false
        return nil
    end

    survivalThresholdCurves[percent] = curve
    return curve
end

local function IsPlayerBelowSurvivalThreshold(percent)
    if type(UnitHealthPercent) ~= "function" then return nil end

    local curve = GetSurvivalThresholdCurve(percent)
    if not curve then return nil end

    local ok, result = pcall(UnitHealthPercent, "player", false, curve)
    if not ok or result == nil then return nil end

    local isZero = IsZeroWithoutReadingSecret(result)
    if isZero == nil then return nil end
    return not isZero
end

local function SpellKnown(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end

    if type(IsPlayerSpell) == "function" then
        local ok, result = pcall(IsPlayerSpell, spellID)
        if ok then
            local known = NormalBoolean(result)
            if known == true then return true end
        end
    end

    if type(IsSpellKnown) == "function" then
        local ok, result = pcall(IsSpellKnown, spellID)
        if ok then
            local known = NormalBoolean(result)
            if known == true then return true end
        end
    end

    return false
end
local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and name then return name end
    end

    if type(GetSpellInfo) == "function" then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and name then return name end
    end

    return "Spell " .. tostring(spellID or "?")
end

local function SpellIcon(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end

    if type(GetSpellTexture) == "function" then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and texture then return texture end
    end

    return 134400
end

local function ItemCount(itemID)
    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false, false)
        if ok and not IsSecret(count) then
            return tonumber(count) or 0
        end
    end

    if type(GetItemCount) == "function" then
        local ok, count = pcall(GetItemCount, itemID, false, false, false)
        if ok and not IsSecret(count) then
            return tonumber(count) or 0
        end
    end

    return 0
end

local function ItemName(itemID, fallback)
    if C_Item and C_Item.GetItemName then
        local ok, name = pcall(C_Item.GetItemName, itemID)
        if ok and name then return name end
    end

    if C_Item and C_Item.GetItemInfo then
        local ok, name = pcall(C_Item.GetItemInfo, itemID)
        if ok and name then return name end
    end

    return fallback or "Item"
end

local function ItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        local ok, texture = pcall(C_Item.GetItemIconByID, itemID)
        if ok and texture then return texture end
    end

    if C_Item and C_Item.GetItemInfo then
        local ok, _, _, _, _, _, _, _, _, _, texture = pcall(C_Item.GetItemInfo, itemID)
        if ok and texture then return texture end
    end

    return 134400
end

local function SpellLink(spellID)
    spellID = tonumber(spellID)
    if not spellID then return "[Unknown spell]" end

    if C_Spell and C_Spell.GetSpellLink then
        local ok, link = pcall(C_Spell.GetSpellLink, spellID)
        if ok and link then return link end
    end

    if type(GetSpellLink) == "function" then
        local ok, link = pcall(GetSpellLink, spellID)
        if ok and link then return link end
    end

    return string.format(
        "|cff71d5ff|Hspell:%d|h[%s]|h|r",
        spellID,
        SpellName(spellID)
    )
end

local function ItemLink(itemID, fallback)
    itemID = tonumber(itemID)
    if not itemID then return "[Unknown item]" end

    if C_Item and C_Item.GetItemInfo then
        local ok, _, link = pcall(C_Item.GetItemInfo, itemID)
        if ok and link then return link end
    end

    if type(GetItemInfo) == "function" then
        local ok, _, link = pcall(GetItemInfo, itemID)
        if ok and link then return link end
    end

    return string.format(
        "|cffffffff|Hitem:%d|h[%s]|h|r",
        itemID,
        ItemName(itemID, fallback or ("Item " .. tostring(itemID)))
    )
end

-- Cooldown readiness is deliberately independent from the HP threshold.
-- 12.0.5+ exposes a DurationObject with ignoreGCD=true; IsZero() gives us a
-- safe boolean even when the underlying cooldown timing is restricted.  This
-- is the preferred path because a normal GCD must NOT make Kaylii skip a
-- perfectly available defensive.
local function SpellCooldownReady(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end

    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
        if ok and type(info) == "table" then
            local enabled = NormalBoolean(info.isEnabled)
            local active = NormalBoolean(info.isActive)
            local onGCD = NormalBoolean(info.isOnGCD)

            if enabled == false then return false end
            if active == false then return true end

            if active == true then
                if onGCD == true then return true end
                if onGCD == false then return false end

                if C_Spell.GetSpellCooldownDuration then
                    local okDuration, duration = pcall(C_Spell.GetSpellCooldownDuration, spellID, true)
                    if okDuration and duration and duration.IsZero then
                        local okZero, isZero = pcall(duration.IsZero, duration)
                        if okZero then
                            local normalZero = NormalBoolean(isZero)
                            if normalZero ~= nil then return normalZero end
                        end
                    end
                end
                return false
            end

            local startTime = info.startTime
            local duration = info.duration
            if not IsSecret(startTime) and not IsSecret(duration) then
                startTime = tonumber(startTime) or 0
                duration = tonumber(duration) or 0
                if startTime <= 0 or duration <= 0 or duration <= 1.6 then return true end
                return (startTime + duration) <= (GetTime() + 0.05)
            end
        end
    end

    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local ok, duration = pcall(C_Spell.GetSpellCooldownDuration, spellID, true)
        if ok and duration and duration.IsZero then
            local okZero, isZero = pcall(duration.IsZero, duration)
            if okZero then
                local normalZero = NormalBoolean(isZero)
                if normalZero ~= nil then return normalZero end
            end
        end
    end

    if C_Spell and C_Spell.IsSpellUsable then
        local ok, usable = pcall(C_Spell.IsSpellUsable, spellID)
        if ok then
            local normalUsable = NormalBoolean(usable)
            if normalUsable ~= nil then return normalUsable end
        end
    end

    return false
end
local function ItemCooldownReady(itemID)
    if not itemID then return false end

    -- IsUsableItem returns a normal boolean and is the best first check on
    -- current Retail.  It catches shared potion/Healthstone lockouts even when
    -- raw cooldown times are secret.
    if C_Item and C_Item.IsUsableItem then
        local ok, usable = pcall(C_Item.IsUsableItem, itemID)
        if ok then
            local normalUsable = NormalBoolean(usable)
            if normalUsable == false then
                return false
            end
        end
    end

    if C_Item and C_Item.GetItemCooldown then
        local ok, startTime, duration, enabled = pcall(C_Item.GetItemCooldown, itemID)

        if ok then
            if not IsSecret(enabled) and (enabled == false or enabled == 0) then
                return false
            end

            if not IsSecret(startTime) and not IsSecret(duration) then
                startTime = tonumber(startTime) or 0
                duration = tonumber(duration) or 0

                if startTime <= 0 or duration <= 0 then
                    return true
                end

                return (startTime + duration) <= (GetTime() + 0.05)
            end
        end
    end

    return true
end

local function ResolveHealthstone()
    for _, itemID in ipairs(HEALTHSTONE_ITEMS) do
        if ItemCount(itemID) > 0 then
            return itemID
        end
    end

    return nil
end

local function ResolveHealingPotion()
    if not BW.db then return nil end

    local custom = tonumber(BW.db.survivalPotionItemID) or 0
    if custom > 0 and ItemCount(custom) > 0 then
        return custom
    end

    for _, itemID in ipairs(HEALING_POTION_ITEMS) do
        if ItemCount(itemID) > 0 then
            return itemID
        end
    end

    return nil
end

-- Always resolve Survival's character data from the SavedVariables global.
-- Keeping a cached table here can make the UI read an older/default table if
-- the SavedVariables table is rebound during recovery or migration.
local function SurvivalCharacterDB()
    if type(KayliiSurvivalCharacterDB) ~= "table" then
        KayliiSurvivalCharacterDB = {}
    end
    BW.characterDB = KayliiSurvivalCharacterDB
    return KayliiSurvivalCharacterDB
end

local function CharacterSurvivalCustomActions()
    if not BW.db then return {} end
    local characterDB = SurvivalCharacterDB()
    if type(characterDB.survivalCustomActions) ~= "table" then
        -- Do not import the old account-wide list: it did not record which
        -- character added each entry, so importing it would keep leaking
        -- Hunter-only additions onto other characters.
        characterDB.survivalCustomActions = {}
    end
    characterDB.survivalNextActionID = math.max(
        1,
        math.floor(tonumber(characterDB.survivalNextActionID) or 1)
    )
    return characterDB.survivalCustomActions
end

local function CustomActionByKey(key)
    if not BW.db or type(key) ~= "string" then return nil end

    local uid = tonumber(key:match("^custom:(%d+)$"))
    if not uid then return nil end

    for _, action in ipairs(CharacterSurvivalCustomActions()) do
        if tonumber(action.uid) == uid then
            return action
        end
    end

    return nil
end

local function HasCustomAction(actionType, actionID)
    actionType = tostring(actionType or "")
    actionID = tonumber(actionID)

    for _, action in ipairs(CharacterSurvivalCustomActions()) do
        if tostring(action.type) == actionType
            and tonumber(action.id) == actionID then

            return true
        end
    end

    return false
end

local function EnsureActionStorage()
    if not BW.db then return end

    if type(BW.db.survivalActionSettings) ~= "table" then
        BW.db.survivalActionSettings = {}
    end

    local customActions = CharacterSurvivalCustomActions()
    local characterDB = SurvivalCharacterDB()

    BW.db.survivalTriggerThreshold = Clamp(
        BW.db.survivalTriggerThreshold or 30,
        5,
        95
    )

    if BW.db.survivalTTSEnabled == nil then
        BW.db.survivalTTSEnabled = true
    else
        BW.db.survivalTTSEnabled = BW.db.survivalTTSEnabled and true or false
    end

    if BW.db.survivalTTSContinuous == nil then
        BW.db.survivalTTSContinuous = false
    else
        BW.db.survivalTTSContinuous = BW.db.survivalTTSContinuous and true or false
    end

    if type(BW.db.survivalTTSText) ~= "string" then
        BW.db.survivalTTSText = "Use a defensive"
    end

    if BW.db.survivalGlowEnabled == nil then
        BW.db.survivalGlowEnabled = true
    else
        BW.db.survivalGlowEnabled = BW.db.survivalGlowEnabled and true or false
    end

    if BW.db.survivalDeathSoundEnabled == nil then
        BW.db.survivalDeathSoundEnabled = true
    else
        BW.db.survivalDeathSoundEnabled = BW.db.survivalDeathSoundEnabled and true or false
    end

    if type(BW.db.survivalDeathSound) ~= "string" then
        BW.db.survivalDeathSound = "Quest Failed"
    end

    if not BW.db.survivalThresholdAlertMigrated then
        local oldMode = BW.db.survivalThresholdSoundMode
        if oldMode == "tts" then
            BW.db.survivalThresholdAlertType = "tts"
        elseif oldMode == "off" then
            BW.db.survivalThresholdAlertType = "sound"
            BW.db.survivalAlertSound = "off"
        elseif oldMode == "blizzardPulse" then
            BW.db.survivalThresholdAlertType = "sound"
            BW.db.survivalAlertSound = "blizzardPulse"
        elseif oldMode == "selectedSound" then
            BW.db.survivalThresholdAlertType = "sound"
            BW.db.survivalAlertSound = tostring(BW.db.survivalDeathSound or "Air Horn")
        elseif type(oldMode) == "string" and oldMode:match("^sound:") then
            BW.db.survivalThresholdAlertType = "sound"
            BW.db.survivalAlertSound = oldMode:sub(7)
        end
        BW.db.survivalThresholdAlertMigrated = true
        BW.db.survivalThresholdSoundMode = nil
    end
    if BW.db.survivalThresholdAlertType ~= "sound" then
        BW.db.survivalThresholdAlertType = "tts"
    end
    if type(BW.db.survivalAlertSound) ~= "string" then
        BW.db.survivalAlertSound = "Air Horn"
    end

    -- 1.19.40 replaces the temporary short built-in list with the actual
    -- LowHealthHelper sound library.  Old short-list keys fall back cleanly.
    if BW.db.survivalDeathSound == "raid_warning"
        or BW.db.survivalDeathSound == "ready_check"
        or BW.db.survivalDeathSound == "boss_warning"
        or BW.db.survivalDeathSound == "role_check"
        or BW.db.survivalDeathSound == "whisper"
        or BW.db.survivalDeathSound == "map_ping"
        or BW.db.survivalDeathSound == "lfg_reward" then

        BW.db.survivalDeathSound = "Quest Failed"
    end

    BW.db.survivalDeathSoundThrottleSeconds = math.max(
        0,
        tonumber(BW.db.survivalDeathSoundThrottleSeconds) or 0.5
    )

    -- 1.19.37: Survival sound is popup TTS only.  Older builds enabled
    -- Blizzard's separate low-health pulse, which could sound independently
    -- of the recommendation icon and feel random.  Disable that legacy path
    -- once and restore the player's original CVar through ApplyPulseSoundSetting.
    if not BW.db.survivalPopupTTSMigrated then
        BW.db.survivalPulseSoundEnabled = false
        BW.db.survivalPopupTTSMigrated = true
    end

    for _, action in ipairs(customActions) do
        if not tonumber(action.uid) then
            action.uid = characterDB.survivalNextActionID
            characterDB.survivalNextActionID = characterDB.survivalNextActionID + 1
        elseif tonumber(action.uid) >= characterDB.survivalNextActionID then
            characterDB.survivalNextActionID = tonumber(action.uid) + 1
        end

        if action.enabled == nil then
            action.enabled = true
        end
    end

    -- Migrate the old per-action system only once.  Enabled/disabled choices
    -- are preserved; the old individual HP thresholds are intentionally not
    -- used anymore because 1.19.31 has one global trigger threshold.
    if not BW.db.survivalActionSettingsMigrated then
        local personalEnabled = BW.db.survivalPersonalEnabled ~= false
        local stoneEnabled = BW.db.survivalHealthstoneEnabled ~= false
        local potionEnabled = BW.db.survivalPotionEnabled ~= false
        local _, classFile = UnitClass("player")

        for _, spellID in ipairs(PERSONAL_DEFENSIVES[classFile] or {}) do
            local key = "spell:" .. tostring(spellID)
            if type(BW.db.survivalActionSettings[key]) ~= "table" then
                BW.db.survivalActionSettings[key] = {
                    enabled = personalEnabled,
                }
            end
        end

        if type(BW.db.survivalActionSettings.healthstone) ~= "table" then
            BW.db.survivalActionSettings.healthstone = {
                enabled = stoneEnabled,
            }
        end

        if type(BW.db.survivalActionSettings.potion) ~= "table" then
            BW.db.survivalActionSettings.potion = {
                enabled = potionEnabled,
            }
        end

        local legacySpellID = tonumber(BW.db.survivalPersonalSpellID) or 0
        local isBuiltin = false

        for _, spellID in ipairs(PERSONAL_DEFENSIVES[classFile] or {}) do
            if spellID == legacySpellID then
                isBuiltin = true
                break
            end
        end

        if legacySpellID > 0
            and not isBuiltin
            and not HasCustomAction("spell", legacySpellID) then

            customActions[#customActions + 1] = {
                uid = characterDB.survivalNextActionID,
                type = "spell",
                id = legacySpellID,
                enabled = personalEnabled,
            }
            characterDB.survivalNextActionID = characterDB.survivalNextActionID + 1
        end

        BW.db.survivalActionSettingsMigrated = true
    end
end

local function ExpectedPriorityKeys()
    local keys = {}
    local _, classFile = UnitClass("player")

    for _, spellID in ipairs(PERSONAL_DEFENSIVES[classFile] or {}) do
        keys[#keys + 1] = "spell:" .. tostring(spellID)
    end

    keys[#keys + 1] = "healthstone"
    keys[#keys + 1] = "potion"

    for _, action in ipairs(CharacterSurvivalCustomActions()) do
        if tonumber(action.uid) then
            keys[#keys + 1] = "custom:" .. tostring(action.uid)
        end
    end

    return keys
end

local function EnsurePriorityOrder()
    EnsureActionStorage()

    local characterDB = SurvivalCharacterDB()

    -- Read the character order first. Older account-wide data remains a
    -- recovery fallback. Reading the page must never replace either table.
    local savedOrder = characterDB.survivalPriorityOrder
    if type(savedOrder) ~= "table" then
        savedOrder = BW.db.survivalPriorityOrder or {}
    end

    local expected = ExpectedPriorityKeys()
    local valid = {}
    for _, key in ipairs(expected) do
        valid[key] = true
    end

    local cleaned = {}
    local seen = {}
    for _, key in ipairs(savedOrder) do
        if valid[key] and not seen[key] then
            cleaned[#cleaned + 1] = key
            seen[key] = true
        end
    end

    for _, key in ipairs(expected) do
        if not seen[key] then
            cleaned[#cleaned + 1] = key
            seen[key] = true
        end
    end

    return cleaned
end

local function PriorityIndex(key)
    local order = EnsurePriorityOrder()
    for index, orderedKey in ipairs(order) do
        if orderedKey == key then
            return index
        end
    end

    return #order + 1
end

local function BuiltinSetting(key, defaultEnabled)
    EnsureActionStorage()

    local settings = BW.db.survivalActionSettings
    local value = settings[key]

    if type(value) ~= "table" then
        value = {}
        settings[key] = value
    end

    if value.enabled == nil then
        value.enabled = defaultEnabled ~= false
    end

    return value
end

local function MakeSpellAction(key, spellID, settings, priority, custom)
    local known = SpellKnown(spellID)
    local ready = known and SpellCooldownReady(spellID) or false

    return {
        key = key,
        kind = custom and "custom" or "personal",
        actionType = "spell",
        id = spellID,
        enabled = settings.enabled ~= false,
        name = SpellName(spellID),
        link = SpellLink(spellID),
        icon = SpellIcon(spellID),
        available = known,
        ready = ready,
        status = known and (ready and "Ready" or "Cooldown") or "Not known",
        priority = priority or 50,
        custom = custom and true or false,
    }
end

local function MakeItemAction(key, itemID, settings, priority, kind, fallback, custom)
    local count = itemID and ItemCount(itemID) or 0
    local available = count > 0
    local ready = available and ItemCooldownReady(itemID) or false

    return {
        key = key,
        kind = kind or (custom and "custom" or "potion"),
        actionType = "item",
        id = itemID,
        enabled = settings.enabled ~= false,
        name = ItemName(itemID, fallback or "Item"),
        link = ItemLink(itemID, fallback or "Item"),
        icon = ItemIcon(itemID),
        available = available,
        ready = ready,
        status = available
            and ((ready and "Ready" or "Cooldown") .. "  x" .. tostring(count))
            or "Not in bags",
        priority = priority or 50,
        custom = custom and true or false,
    }
end

local function BuildSurvivalActions()
    EnsureActionStorage()

    local actions = {}
    local _, classFile = UnitClass("player")
    local personalEnabled = BW.db.survivalPersonalEnabled ~= false

    for _, spellID in ipairs(PERSONAL_DEFENSIVES[classFile] or {}) do
        local key = "spell:" .. tostring(spellID)
        local settings = BuiltinSetting(key, personalEnabled)
        actions[#actions + 1] = MakeSpellAction(
            key,
            spellID,
            settings,
            PriorityIndex(key),
            false
        )
    end

    local stoneID = ResolveHealthstone() or HEALTHSTONE_ITEMS[1]
    local stoneSettings = BuiltinSetting(
        "healthstone",
        BW.db.survivalHealthstoneEnabled ~= false
    )
    actions[#actions + 1] = MakeItemAction(
        "healthstone",
        stoneID,
        stoneSettings,
        PriorityIndex("healthstone"),
        "healthstone",
        "Healthstone",
        false
    )

    local fallbackPotionID = tonumber(BW.db.survivalPotionItemID) or 0
    if fallbackPotionID <= 0 then
        fallbackPotionID = HEALING_POTION_ITEMS[1]
    end

    local potionID = ResolveHealingPotion() or fallbackPotionID
    local potionSettings = BuiltinSetting(
        "potion",
        BW.db.survivalPotionEnabled ~= false
    )
    actions[#actions + 1] = MakeItemAction(
        "potion",
        potionID,
        potionSettings,
        PriorityIndex("potion"),
        "potion",
        "Healing Potion",
        false
    )

    for _, custom in ipairs(CharacterSurvivalCustomActions()) do
        local actionType = tostring(custom.type or "")
        local actionID = tonumber(custom.id)

        custom.enabled = custom.enabled ~= false

        if actionID and actionID > 0 then
            local key = "custom:" .. tostring(custom.uid)
            local descriptor

            if actionType == "spell" then
                descriptor = MakeSpellAction(
                    key,
                    actionID,
                    custom,
                    PriorityIndex(key),
                    true
                )
            elseif actionType == "item" then
                descriptor = MakeItemAction(
                    key,
                    actionID,
                    custom,
                    PriorityIndex(key),
                    "custom",
                    "Item " .. tostring(actionID),
                    true
                )
            end

            if descriptor then
                actions[#actions + 1] = descriptor
            end
        end
    end

    table.sort(actions, function(a, b)
        return (a.priority or 999) < (b.priority or 999)
    end)

    return actions
end

-- There is exactly one trigger threshold now.  Once HP is at/below it, walk
-- the priority list from top to bottom and return the first enabled action that
-- both exists and is off cooldown.  There is deliberately no "show the first
-- cooldown action anyway" fallback: if Desperate Prayer is unavailable we
-- immediately proceed to Healthstone, potion, or the next user action.
local function FirstReadyAction()
    for _, action in ipairs(BuildSurvivalActions()) do
        if action.enabled and action.available and action.ready then
            return action
        end
    end

    return nil
end

local function ReadyActions()
    local ready = {}
    for _, action in ipairs(BuildSurvivalActions()) do
        if action.enabled and action.available and action.ready then
            ready[#ready + 1] = action
        end
    end
    return ready
end

function BW:GetSurvivalRecommendedAction()
    if not self.db then return nil, nil end

    local hp = GetPlayerHealthPercent()
    local threshold = Clamp(self.db.survivalTriggerThreshold or 30, 5, 95)

    if hp ~= nil and hp <= threshold then
        return FirstReadyAction(), hp
    end

    return nil, hp
end

local function PreviewCandidate()
    local firstEnabled

    for _, action in ipairs(BuildSurvivalActions()) do
        if action.enabled then
            firstEnabled = firstEnabled or action
            if action.available and action.ready then
                return action
            end
        end
    end

    return firstEnabled or {
        key = "__preview",
        kind = "personal",
        name = "Survival Helper",
        icon = 134400,
        ready = true,
    }
end

function BW:GetSurvivalActions()
    if not self.db then return {} end
    return BuildSurvivalActions()
end

local function CharacterSurvivalPhraseStorage()
    local characterDB = SurvivalCharacterDB()
    if type(characterDB.survivalTTSPhrases) ~= "table" then
        characterDB.survivalTTSPhrases = {}
    end
    return characterDB.survivalTTSPhrases
end

function BW:GetSurvivalTTSPhrase(key, defaultText)
    if type(key) ~= "string" then return tostring(defaultText or "") end
    local phrases = CharacterSurvivalPhraseStorage()
    if phrases[key] ~= nil then
        return tostring(phrases[key] or "")
    end

    -- Recover older account-wide per-action phrases without copying defaults
    -- into the character save simply because the options page was viewed.
    local legacy = self.db and self.db.survivalTTSPhrases
    if type(legacy) == "table" and legacy[key] ~= nil then
        return tostring(legacy[key] or "")
    end
    return tostring(defaultText or "")
end

function BW:SetSurvivalTTSPhrase(key, text)
    if type(key) ~= "string" or key == "" then return false end
    local phrases = CharacterSurvivalPhraseStorage()
    phrases[key] = tostring(text or "")
    return true
end

function BW:SetSurvivalActionEnabled(key, value)
    if not self.db then return false end
    EnsureActionStorage()

    local custom = CustomActionByKey(key)
    if custom then
        custom.enabled = value and true or false
    else
        local settings = self.db.survivalActionSettings[key]
        if type(settings) ~= "table" then return false end
        settings.enabled = value and true or false
    end

    self.survivalLastRecommendationKey = nil
    self:UpdateSurvivalHelper()
    return true
end

local ApplyPulseSoundSetting

-- Compatibility shim for old UI/saved code.  Individual thresholds were
-- removed in 1.19.31; any call here changes the one global trigger instead.
function BW:SetSurvivalActionThreshold(_, value)
    return self:SetSurvivalTriggerThreshold(value)
end

function BW:SetSurvivalTriggerThreshold(value)
    if not self.db then return false end

    self.db.survivalTriggerThreshold = Clamp(value, 5, 95)
    self.survivalLastRecommendationKey = nil
    ApplyPulseSoundSetting()
    self:UpdateSurvivalHelper()
    return true
end

function BW:MoveSurvivalAction(key, direction)
    if not self.db or type(key) ~= "string" then return false end

    local order = EnsurePriorityOrder()
    local current
    for index, orderedKey in ipairs(order) do
        if orderedKey == key then
            current = index
            break
        end
    end

    if not current then return false end

    local delta = direction == "up" and -1 or direction == "down" and 1 or 0
    local target = current + delta
    if delta == 0 or target < 1 or target > #order then
        return false
    end

    order[current], order[target] = order[target], order[current]
    SurvivalCharacterDB().survivalPriorityOrder = order
    self.survivalLastRecommendationKey = nil
    self:UpdateSurvivalHelper()
    return true
end

local function ParseActionID(value, actionType)
    local text = tostring(value or "")
    local id

    if actionType == "spell" then
        id = text:match("spell:(%d+)")
    elseif actionType == "item" then
        id = text:match("item:(%d+)")
    end

    id = tonumber(id or text:match("(%d+)"))
    if not id or id <= 0 then return nil end
    return math.floor(id)
end

function BW:AddSurvivalAction(actionType, value)
    if not self.db then return false, "Survival Helper is not initialized." end
    EnsureActionStorage()

    actionType = tostring(actionType or ""):lower()
    if actionType ~= "spell" and actionType ~= "item" then
        return false, "Choose Spell or Item."
    end

    local actionID = ParseActionID(value, actionType)
    if not actionID then
        return false, "Enter a spell/item ID or paste its link."
    end

    if HasCustomAction(actionType, actionID) then
        return false, "That action is already in the list."
    end

    if actionType == "spell" then
        local _, classFile = UnitClass("player")
        for _, spellID in ipairs(PERSONAL_DEFENSIVES[classFile] or {}) do
            if spellID == actionID then
                local setting = BuiltinSetting("spell:" .. tostring(spellID), true)
                setting.enabled = true
                return false, "That defensive is already listed above."
            end
        end
    end

    local customActions = CharacterSurvivalCustomActions()
    local characterDB = SurvivalCharacterDB()
    local uid = characterDB.survivalNextActionID
    characterDB.survivalNextActionID = uid + 1
    customActions[#customActions + 1] = {
        uid = uid,
        type = actionType,
        id = actionID,
        enabled = true,
    }

    EnsurePriorityOrder()
    self.survivalLastRecommendationKey = nil
    self:UpdateSurvivalHelper()

    return true, actionType == "spell"
        and ("Added " .. SpellName(actionID) .. ".")
        or ("Added " .. ItemName(actionID, "Item " .. tostring(actionID)) .. ".")
end

function BW:RemoveSurvivalAction(key)
    if not self.db then return false end
    EnsureActionStorage()

    local uid = type(key) == "string" and tonumber(key:match("^custom:(%d+)$")) or nil
    if not uid then return false end

    local customActions = CharacterSurvivalCustomActions()
    for index, action in ipairs(customActions) do
        if tonumber(action.uid) == uid then
            table.remove(customActions, index)
            local characterDB = SurvivalCharacterDB()
            if characterDB.survivalTTSPhrases then
                characterDB.survivalTTSPhrases[key] = nil
            end
            EnsurePriorityOrder()
            self.survivalLastRecommendationKey = nil
            self:UpdateSurvivalHelper()
            return true
        end
    end

    return false
end

function BW:OpenSurvivalActionLink(key)
    if not self.db then return end

    for _, action in ipairs(BuildSurvivalActions()) do
        if action.key == key and action.id then
            local ref = (action.actionType == "spell" and "spell:" or "item:")
                .. tostring(action.id)

            if type(SetItemRef) == "function" then
                SetItemRef(ref, action.link or action.name or ref, "LeftButton")
            end
            return
        end
    end
end

local function SpeakWithWoWTTS(text, allowOverlap)
    text = tostring(text or "")
    if text == "" then
        return false
    end

    -- LustUp.lua is loaded before this module.  Use the exact same function,
    -- not a second implementation that can drift from Lust Up later.
    if BW.SpeakKayliiTTS then
        return BW:SpeakKayliiTTS(text, allowOverlap)
    end

    -- Compatibility fallback only for unusual load-order situations.
    -- VoiceChat TTS is the primary
    -- route because it respects the player-selected WoW TTS voice/rate/volume
    -- and is already proven by the Lust Up module.
    if C_VoiceChat
        and C_VoiceChat.SpeakText
        and C_VoiceChat.GetTtsVoices then

        local voiceID

        if C_TTSSettings
            and C_TTSSettings.GetVoiceOptionID
            and Enum
            and Enum.TtsVoiceType then

            local ok, value = pcall(
                C_TTSSettings.GetVoiceOptionID,
                Enum.TtsVoiceType.Standard
            )

            if ok then
                voiceID = value
            end
        end

        if not voiceID then
            local ok, voices = pcall(C_VoiceChat.GetTtsVoices)

            if ok and type(voices) == "table" and voices[1] then
                voiceID = voices[1].voiceID
            end
        end

        if voiceID then
            local rate = 0
            local volume = 100

            if C_TTSSettings and C_TTSSettings.GetSpeechRate then
                local ok, value = pcall(C_TTSSettings.GetSpeechRate)
                if ok and tonumber(value) then
                    rate = tonumber(value)
                end
            end

            if C_TTSSettings and C_TTSSettings.GetSpeechVolume then
                local ok, value = pcall(C_TTSSettings.GetSpeechVolume)
                if ok and tonumber(value) then
                    volume = tonumber(value)
                end
            end

            local ok = pcall(
                C_VoiceChat.SpeakText,
                voiceID,
                text,
                rate,
                volume,
                allowOverlap and true or false
            )

            if ok then
                return true
            end
        end
    end

    -- Same fallback used by Lust Up.
    if C_CombatAudioAlert
        and C_CombatAudioAlert.SpeakText
        and Enum
        and Enum.CombatAudioAlertCategory then

        local ok = pcall(
            C_CombatAudioAlert.SpeakText,
            text,
            Enum.CombatAudioAlertCategory.General,
            allowOverlap and true or false
        )

        if ok then
            return true
        end
    end

    return false
end

local function GetCVarValue(name)
    if C_CVar and C_CVar.GetCVar then
        local ok, value = pcall(C_CVar.GetCVar, name)
        if ok then return value end
    end

    if type(GetCVar) == "function" then
        local ok, value = pcall(GetCVar, name)
        if ok then return value end
    end

    return nil
end

local function SetCVarValue(name, value)
    if C_CVar and C_CVar.SetCVar then
        local ok, success = pcall(C_CVar.SetCVar, name, tostring(value))
        if ok and success then return true end
    end

    if type(SetCVar) == "function" then
        local ok, success = pcall(SetCVar, name, tostring(value))
        if ok and success then return true end
    end

    return false
end

-- Midnight protects the player's actual HP value in combat, so addon Lua
-- cannot reliably fire a custom TTS exactly when the secret threshold is
-- crossed.  Blizzard 12.1.5 provides "Pulse Your Health", which is evaluated
-- internally by the game and therefore remains reliable in restricted combat.
-- Keep that pulse synced to Kaylii's one Survival threshold as the guaranteed
-- automatic sound path; custom TTS still fires whenever HP is branchable and
-- is always available through the Test voice button.
ApplyPulseSoundSetting = function()
    if not BW.db then return false end

    local cvar = "CAAPulsePlayerHealthPercent"
    local shouldEnable = BW.db.survivalModuleEnabled
        and BW.db.survivalThresholdAlertType == "sound"
        and BW.db.survivalAlertSound == "blizzardPulse"

    if shouldEnable then
        if BW.db.survivalPulseOriginalPercent == nil then
            local original = GetCVarValue(cvar)
            if original ~= nil then
                BW.db.survivalPulseOriginalPercent = tostring(original)
            end
        end

        return SetCVarValue(
            cvar,
            math.floor(Clamp(BW.db.survivalTriggerThreshold or 30, 5, 95) + 0.5)
        )
    end

    if BW.db.survivalPulseOriginalPercent ~= nil then
        local restored = SetCVarValue(cvar, BW.db.survivalPulseOriginalPercent)
        if restored then
            BW.db.survivalPulseOriginalPercent = nil
        end
        return restored
    end

    return false
end

function BW:SetSurvivalTTSText(text)
    if not self.db then return end
    self.db.survivalTTSText = tostring(text or "")
end

function BW:SetSurvivalTTSEnabled(value)
    if not self.db then return false end
    self.db.survivalTTSEnabled = value and true or false

    if not self.db.survivalTTSEnabled then
        self.survivalTriggerActive = false
        self:StopSurvivalTicker()
    elseif self.db.survivalTTSContinuous and self.survivalTriggerActive then
        self:StartSurvivalTicker()
    end

    return true
end

function BW:SetSurvivalTTSContinuous(value)
    if not self.db then return false end
    self.db.survivalTTSContinuous = value and true or false

    if self.db.survivalTTSContinuous
        and self.db.survivalTTSEnabled ~= false
        and self.survivalTriggerActive then

        self:StartSurvivalTicker()
    else
        self:StopSurvivalTicker()
    end

    return true
end

function BW:SetSurvivalGlowEnabled(value)
    if not self.db then return false end
    EnsureActionStorage()
    self.db.survivalGlowEnabled = value and true or false
    self:ApplySurvivalSettings()
    return true
end

function BW:TestSurvivalTTS()
    if not self.db then return false end
    return SpeakWithWoWTTS(self.db.survivalTTSText or "Use a defensive")
end

function BW:SetSurvivalPulseSoundEnabled(value)
    if not self.db then return false end
    self.db.survivalPulseSoundEnabled = value and true or false
    self.db.survivalThresholdAlertType = "sound"
    self.db.survivalAlertSound = value and "blizzardPulse" or "off"
    return ApplyPulseSoundSetting()
end

function BW:GetSurvivalAlertSoundChoices()
    return self.SurvivalAlertSounds or {}
end

function BW:SetSurvivalThresholdAlertType(value)
    if not self.db or (value ~= "tts" and value ~= "sound") then return false end
    self.db.survivalThresholdAlertType = value
    ApplyPulseSoundSetting()
    if value ~= "tts" then
        if C_VoiceChat and C_VoiceChat.StopSpeakingText then pcall(C_VoiceChat.StopSpeakingText) end
        self:StopSurvivalTicker()
    end
    self:UpdateSurvivalHelper()
    if self.RefreshSurvivalOptions then self:RefreshSurvivalOptions() end
    return true
end

function BW:SetSurvivalAlertSound(key)
    if not self.db then return false end
    key = tostring(key or "")
    for _, option in ipairs(self:GetSurvivalAlertSoundChoices()) do
        if option.key == key then
            self.db.survivalAlertSound = key
            ApplyPulseSoundSetting()
            self:UpdateSurvivalHelper()
            if self.RefreshSurvivalOptions then self:RefreshSurvivalOptions() end
            return true
        end
    end
    return false
end

function BW:PlaySurvivalAlertSound(force)
    if not self.db then return false end
    if not force and (not self.db.survivalModuleEnabled or self.db.survivalThresholdAlertType ~= "sound") then return false end
    local key = tostring(self.db.survivalAlertSound or "Air Horn")
    if key == "off" or key == "blizzardPulse" then return false end
    for _, option in ipairs(self:GetSurvivalAlertSoundChoices()) do
        if option.key == key then
            if option.soundID and type(PlaySound) == "function" then
                local ok, played = pcall(PlaySound, option.soundID, "Master")
                return ok and played ~= false
            elseif option.path and type(PlaySoundFile) == "function" then
                local ok, played = pcall(PlaySoundFile, option.path, "Master")
                return ok and played ~= false
            end
            return false
        end
    end
    return false
end

function BW:TestSurvivalAlertSound()
    return self:PlaySurvivalAlertSound(true)
end

local function SpeakSurvivalPopup(candidate)
    if not BW.db
        or BW.db.survivalThresholdAlertType ~= "tts" then
        return false
    end

    -- Survival alerts are time-sensitive. Drop an older queued reminder so
    -- repeated threshold crossings never make the next call wait in the TTS
    -- queue behind stale advice.
    if C_VoiceChat and C_VoiceChat.StopSpeakingText then
        pcall(C_VoiceChat.StopSpeakingText)
    end

    local text
    if candidate and candidate.name and BW.db.survivalSpeakActionName ~= false then
        local defaultPhrase = "Use " .. tostring(candidate.name)
        text = BW.GetSurvivalTTSPhrase
            and BW:GetSurvivalTTSPhrase(candidate.key, defaultPhrase)
            or defaultPhrase
    else
        text = tostring(BW.db.survivalTTSText or "")
    end
    if text == "" then
        return false
    end

    return SpeakWithWoWTTS(text, true)
end

local function SpeakSurvivalPopupAfterDisplay(candidate)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if BW.db
                and BW.db.survivalModuleEnabled ~= false
                and BW.survivalTriggerActive then

                SpeakSurvivalPopup(candidate)
            end
        end)
    else
        SpeakSurvivalPopup(candidate)
    end
end

local function VisibilityAllowed()
    if not BW.db or not BW.db.survivalModuleEnabled then
        return false
    end

    if BW.db.survivalUnlocked then
        return true
    end

    if UnitIsDeadOrGhost then
        local dead = NormalBoolean(UnitIsDeadOrGhost("player"))
        if dead == true then
            return false
        end
    end

    if BW.db.survivalOnlyInCombat
        and not UnitAffectingCombat("player") then

        return false
    end

    if BW.db.survivalOnlyInInstance then
        local inInstance = IsInInstance()
        if not inInstance then return false end
    end

    return true
end

local function CreateDisplay()
    if BW.survivalFrame then
        return BW.survivalFrame
    end

    local frame = CreateFrame(
        "Button",
        "KayliiHelperSurvivalDisplay",
        UIParent
    )

    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    if frame.SetClipsChildren then frame:SetClipsChildren(false) end
    frame:RegisterForDrag("LeftButton")
    frame:SetSize(72, 90)

    -- Visual layer only.  Do not put a backdrop behind the icon: it creates
    -- the dark/black square around the recommendation when the icon is shown.
    local layer = CreateFrame("Frame", nil, frame)
    layer:SetAllPoints(frame)
    if layer.SetClipsChildren then layer:SetClipsChildren(false) end
    layer:Hide()
    frame.layer = layer

    local icon = layer:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOP", layer, "TOP", 0, -16)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    layer.icon = icon
    layer.additionalIcons = {}

    -- Dedicated icon-sized host for Blizzard's native spell-activation alert.
    -- Keeping the host separate from the taller label container makes the
    -- stock WoW proc glow stay centered on the spell icon itself.
    local glowHost = CreateFrame("Frame", nil, layer)
    glowHost:SetPoint("CENTER", icon, "CENTER", 0, 0)
    glowHost:SetFrameLevel(layer:GetFrameLevel() + 2)
    layer.glowHost = glowHost

    local label = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -4)
    label:SetWidth(190)
    label:SetJustifyH("CENTER")
    label:SetTextColor(1, 1, 1, 1)
    layer.label = label

    local moveBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    -- The parent frame has extra room for Blizzard's proc glow.  The mover
    -- outline should describe the icon itself, not that invisible padding.
    moveBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -4, 4)
    moveBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 4, -4)
    moveBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    moveBorder:SetBackdropBorderColor(0.30, 0.62, 1.00, 1)
    moveBorder:Hide()
    frame.moveBorder = moveBorder

    local moveText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    moveText:SetPoint("TOP", moveBorder, "BOTTOM", 0, -3)
    moveText:SetText("MOVE")
    moveText:SetTextColor(0.30, 0.62, 1.00, 1)
    moveText:Hide()
    frame.moveText = moveText

    -- Runtime display is intentionally visual-only.  No tooltip, no click
    -- action, and no click-triggered speech: TTS fires only on the transition
    -- where the low-HP recommendation icon itself appears.  Mouse input is
    -- enabled only while the mover is unlocked so it can still be dragged.
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
    frame:SetScript("OnClick", nil)

    frame:SetScript("OnDragStart", function(self)
        if BW.db
            and BW.db.survivalModuleEnabled
            and BW.db.survivalUnlocked then

            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        if not BW.db then return end

        local x, y = self:GetCenter()
        local ux, uy = UIParent:GetCenter()

        if x and y and ux and uy then
            BW.db.survivalPoint = "CENTER"
            BW.db.survivalX = math.floor((x - ux) + 0.5)
            BW.db.survivalY = math.floor((y - uy) + 0.5)
        end

        if BW.RefreshSurvivalOptions then
            BW:RefreshSurvivalOptions()
        end
    end)

    BW.survivalFrame = frame
    return frame
end

-- Keep Blizzard's native spell-alert frame synchronized with our icon host.
-- Blizzard sizes SpellActivationAlert to 1.4x the action button only when the
-- alert frame is first created.  Our icon can be resized later, so explicitly
-- update that same Blizzard-created frame whenever the host size changes.
local function SyncNativeSurvivalGlowSize(host)
    if not host or not host.SpellActivationAlert then return end

    local width, height = host:GetSize()
    width = tonumber(width) or 0
    height = tonumber(height) or 0

    if width <= 0 or height <= 0 then return end

    local alert = host.SpellActivationAlert
    alert:SetSize(width * 1.4, height * 1.4)
    alert:ClearAllPoints()
    alert:SetPoint("CENTER", host, "CENTER", 0, 0)
end

-- Use Blizzard's native action-button proc glow.  No custom textures or
-- animations are used here: this is the same ActionButtonSpellAlertManager
-- and ActionButtonSpellAlertTemplate used by Blizzard action buttons.
local function SetNativeSurvivalGlow(frame, shown)
    if not frame or not frame.layer or not frame.layer.glowHost then return end

    local host = frame.layer.glowHost
    shown = shown
        and BW.db
        and BW.db.survivalGlowEnabled ~= false
        and true
        or false

    local width = math.floor((host:GetWidth() or 0) + 0.5)
    local height = math.floor((host:GetHeight() or 0) + 0.5)
    local sizeChanged = host.survivalNativeGlowWidth ~= width
        or host.survivalNativeGlowHeight ~= height

    host.survivalNativeGlowWidth = width
    host.survivalNativeGlowHeight = height

    if shown == (host.survivalNativeGlowShown == true)
        and (not shown or not sizeChanged) then

        return
    end

    local manager = ActionButtonSpellAlertManager
    if not manager then
        -- Do not draw a made-up fallback. If Blizzard's action-bar alert
        -- manager is unavailable, leave the glow off until the next refresh.
        host.survivalNativeGlowShown = false
        return
    end

    if host.survivalNativeGlowShown and sizeChanged and manager.HideAlert then
        pcall(manager.HideAlert, manager, host)
        host.survivalNativeGlowShown = false
    end

    -- If Blizzard already created the alert on an earlier icon size, resize
    -- it before showing. ShowAlert reuses that frame and does not resize it.
    if sizeChanged then
        SyncNativeSurvivalGlowSize(host)
    end

    if shown and manager.ShowAlert then
        local ok = pcall(manager.ShowAlert, manager, host, false)
        host.survivalNativeGlowShown = ok and true or false

        -- On the first show, Blizzard creates SpellActivationAlert here.
        -- Resize it immediately so both first-show and later resizes match.
        if ok then
            SyncNativeSurvivalGlowSize(host)
        end
    elseif manager.HideAlert then
        pcall(manager.HideAlert, manager, host)
        host.survivalNativeGlowShown = false
    else
        host.survivalNativeGlowShown = false
    end
end

local function ApplyPosition()
    local frame = CreateDisplay()

    frame:ClearAllPoints()
    frame:SetPoint(
        BW.db.survivalPoint or "CENTER",
        UIParent,
        BW.db.survivalPoint or "CENTER",
        tonumber(BW.db.survivalX) or 0,
        tonumber(BW.db.survivalY) or -80
    )
end

local function ApplyCandidate(frame, candidate)
    local size = Clamp(BW.db.survivalIconSize or 58, 32, 100)
    local glowPadding = 32
    local showActionLabel = BW.db.survivalShowLabel
    local labelExtra = showActionLabel and 34 or 0

    -- Native WoW proc glow extends outside the icon bounds, especially at
    -- larger icon sizes. Keep generous padding around the preview/runtime
    -- frame so the stock glow is never clipped or pushed off-screen.
    frame:SetSize(size + glowPadding, size + glowPadding + labelExtra)
    frame.layer.icon:SetSize(size, size)
    frame.layer.glowHost:SetSize(size, size)
    frame.layer.icon:SetTexture(candidate.icon or 134400)
    for _, extra in ipairs(frame.layer.additionalIcons) do
        extra:Hide()
    end
    if BW.db.survivalShowAllReadyActions then
        local ready = ReadyActions()
        local growth = tostring(BW.db.survivalReadyActionsGrowth or "right")
        if growth ~= "left" and growth ~= "right" and growth ~= "up" and growth ~= "down" then
            growth = "right"
        end
        for index = 2, #ready do
            local extra = frame.layer.additionalIcons[index - 1]
            if not extra then
                extra = frame.layer:CreateTexture(nil, "ARTWORK")
                extra:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                frame.layer.additionalIcons[index - 1] = extra
            end
            extra:ClearAllPoints()
            extra:SetSize(size, size)
            local distance = (index - 1) * (size + 4)
            local offsetX = growth == "right" and distance or growth == "left" and -distance or 0
            local offsetY = growth == "up" and distance or growth == "down" and -distance or 0
            extra:SetPoint("CENTER", frame.layer.icon, "CENTER", offsetX, offsetY)
            extra:SetTexture(ready[index].icon or 134400)
            extra:Show()
        end
    end
    SetNativeSurvivalGlow(frame, true)

    frame.currentCandidate = candidate

    if showActionLabel then
        frame.layer.label:SetWidth(190)
        frame.layer.label:SetText(candidate.name or "Survival")
        frame.layer.label:Show()
    else
        frame.layer.label:Hide()
    end

    frame.layer:Show()
end

local function CreateTriggerCurve(threshold)
    if not C_CurveUtil or not C_CurveUtil.CreateCurve then
        return nil
    end

    local curve = C_CurveUtil.CreateCurve()
    if curve.SetType and Enum and Enum.LuaCurveType then
        curve:SetType(Enum.LuaCurveType.Step)
    end

    threshold = Clamp(threshold or 30, 5, 95) / 100
    local epsilon = 0.0001

    -- Curves passed into UnitHealthPercent receive the normalized 0..1 health
    -- fraction.  This fallback keeps only the visual trigger working if a
    -- client build refuses to expose ScaleTo100 as a branchable value.
    curve:AddPoint(0, 1)
    curve:AddPoint(threshold, 1)
    curve:AddPoint(math.min(1, threshold + epsilon), 0)
    curve:AddPoint(1, 0)
    return curve
end

local function ShowUnlockedPreview(frame)
    local candidate = PreviewCandidate()
    if not candidate then return false end

    ApplyCandidate(frame, candidate)
    frame.layer:SetAlpha(1)
    frame.moveBorder:Show()
    frame.moveText:Show()
    return true
end

local function HideRuntime(frame, resetTrigger)
    SetNativeSurvivalGlow(frame, false)
    frame.layer:Hide()
    frame.layer:SetAlpha(0)
    frame.currentCandidate = nil
    frame:Hide()

    if resetTrigger then
        BW.survivalTriggerActive = false
        if BW.StopSurvivalTicker then
            BW:StopSurvivalTicker()
        end
    end
end

function BW:UpdateSurvivalHelper()
    if not self.db then return end

    EnsureActionStorage()
    local frame = CreateDisplay()

    if not VisibilityAllowed() then
        HideRuntime(frame, true)
        return
    end

    frame:EnableMouse(self.db.survivalUnlocked and true or false)

    if self.db.survivalUnlocked then
        self.survivalTriggerActive = false
        if ShowUnlockedPreview(frame) then
            frame:Show()
        else
            frame:Hide()
        end
        return
    end

    frame.moveBorder:Hide()
    frame.moveText:Hide()

    local threshold = Clamp(self.db.survivalTriggerThreshold or 30, 5, 95)
    local belowThreshold = IsPlayerBelowSurvivalThreshold(threshold)

    if belowThreshold ~= nil then
        if belowThreshold then
            local wasActive = self.survivalTriggerActive == true

            -- The HP threshold owns the TTS trigger. A usable spell/item is
            -- only required for showing the recommendation icon, not for
            -- warning the player that health has reached the configured HP.
            self.survivalTriggerActive = true

            local candidate = FirstReadyAction()

            if self.db.survivalThresholdAlertType == "tts"
                and self.db.survivalTTSContinuous then

                self:StartSurvivalTicker()
            else
                self:StopSurvivalTicker()
            end

            if candidate then
                ApplyCandidate(frame, candidate)
                frame.layer:SetAlpha(1)
                frame:EnableMouse(false)
                frame:Show()
            else
                -- Stay silent visually when there is nothing to press, while
                -- leaving survivalTriggerActive/ticker running for HP TTS.
                HideRuntime(frame, false)
            end

            if not wasActive and self.db.survivalThresholdAlertType == "sound" then
                self:PlaySurvivalAlertSound(false)
            end

            -- Put the icon on screen before invoking TTS so speech setup can
            -- never delay the visual recommendation.
            if not wasActive then
                SpeakSurvivalPopupAfterDisplay(candidate)
            end
        else
            HideRuntime(frame, true)
        end
        return
    end

    -- Compatibility fallback: keep the icon's visual threshold working on a
    -- client where the branchable zero-gate is unavailable. TTS cannot safely
    -- branch on protected HP in that fallback path, so only show a candidate.
    local candidate = FirstReadyAction()
    if candidate then
        ApplyCandidate(frame, candidate)

        local curve = CreateTriggerCurve(threshold)
        if curve and type(UnitHealthPercent) == "function" then
            local ok, alpha = pcall(UnitHealthPercent, "player", true, curve)
            if ok and alpha ~= nil then
                frame.layer:SetAlpha(alpha)
                frame:EnableMouse(false)
                frame:Show()
                return
            end
        end
    end

    HideRuntime(frame, false)
end

-- Optional repeated TTS while the low-health threshold remains active.
-- This is intentionally independent of whether an action is currently ready.
-- The first phrase plays on the threshold transition; the ticker handles
-- subsequent reminders.
function BW:StartSurvivalTicker()
    if self.survivalTicker then return end
    if not self.db
        or self.db.survivalModuleEnabled == false
        or self.db.survivalThresholdAlertType ~= "tts"
        or not self.db.survivalTTSContinuous
        or not self.survivalTriggerActive
        or not C_Timer
        or not C_Timer.NewTicker then

        return
    end

    self.survivalTicker = C_Timer.NewTicker(3.0, function()
        if not BW.db
            or BW.db.survivalModuleEnabled == false
            or BW.db.survivalThresholdAlertType ~= "tts"
            or not BW.db.survivalTTSContinuous
            or not BW.survivalTriggerActive then

            BW:StopSurvivalTicker()
            return
        end

        SpeakSurvivalPopup(FirstReadyAction())
    end)
end

function BW:StopSurvivalTicker()
    if self.survivalTicker then
        self.survivalTicker:Cancel()
        self.survivalTicker = nil
    end
end

function BW:ApplySurvivalSettings()
    if not self.db then return end

    EnsureActionStorage()
    local frame = CreateDisplay()
    ApplyPosition()
    ApplyPulseSoundSetting()

    if self.db.survivalModuleEnabled then
        self:UpdateSurvivalHelper()
    else
        self:StopSurvivalTicker()
        HideRuntime(frame, true)
    end
end

function BW:SetSurvivalModuleEnabled(value)
    if not self.db then return end

    self.db.survivalModuleEnabled = value and true or false
    self:ApplySurvivalSettings()

    if self.RefreshSurvivalOptions then
        self:RefreshSurvivalOptions()
    end
end

function BW:SetSurvivalUnlocked(value)
    if not self.db then return end

    self.db.survivalUnlocked = value and true or false
    if self.db.survivalUnlocked then
        self.survivalTriggerActive = false
    end
    self:UpdateSurvivalHelper()
end

function BW:ResetSurvivalPosition()
    if not self.db then return end

    self.db.survivalPoint = "CENTER"
    self.db.survivalX = 0
    self.db.survivalY = -80

    ApplyPosition()
    self:UpdateSurvivalHelper()
end

function BW:GetSurvivalDetectedText()
    if not self.db then return "" end

    local enabled = 0
    local available = 0
    local ready = 0

    for _, action in ipairs(BuildSurvivalActions()) do
        if action.enabled then
            enabled = enabled + 1
            if action.available then
                available = available + 1
                if action.ready then
                    ready = ready + 1
                end
            end
        end
    end

    return string.format(
        "%d enabled • %d available • %d ready",
        enabled,
        available,
        ready
    )
end

function BW:GetSurvivalStatusText()
    if not self.db then return "" end

    if not self.db.survivalModuleEnabled then
        return "Module disabled"
    end

    local threshold = Clamp(self.db.survivalTriggerThreshold or 30, 5, 95)
    local hp = GetPlayerHealthPercent()
    local candidate = FirstReadyAction()

    if hp then
        if hp <= threshold then
            return candidate
                and string.format("%.0f%% HP • recommending %s", hp, candidate.name or "survival action")
                or string.format("%.0f%% HP • no enabled action is ready", hp)
        end

        return string.format("%.0f%% HP • triggers at %d%%", hp, threshold)
    end

    return string.format("Triggers at %d%% HP", threshold)
end

local function RefreshOptionsIfOpen()
    if BW.RefreshSurvivalOptions then
        BW:RefreshSurvivalOptions()
    end
end

function BW:GetSurvivalDeathSoundChoices()
    return self.SurvivalDeathSounds or {}
end

function BW:GetSurvivalDeathSoundLabel(key)
    key = tostring(key or (self.db and self.db.survivalDeathSound) or "Quest Failed")

    for _, option in ipairs(self:GetSurvivalDeathSoundChoices()) do
        if option.key == key then
            return option.label
        end
    end

    return "Quest Failed"
end

function BW:SetSurvivalDeathSound(key)
    if not self.db then return end

    key = tostring(key or "")
    for _, option in ipairs(self:GetSurvivalDeathSoundChoices()) do
        if option.key == key then
            self.db.survivalDeathSound = key
            if self.RefreshSurvivalOptions then
                self:RefreshSurvivalOptions()
            end
            return true
        end
    end

    return false
end

function BW:PlaySurvivalDeathSound(force)
    if not self.db then return false end

    if not force then
        if not self.db.survivalModuleEnabled
            or self.db.survivalDeathSoundEnabled == false then

            return false
        end
    end

    local selected = tostring(self.db.survivalDeathSound or "Quest Failed")
    local chosen

    for _, option in ipairs(self:GetSurvivalDeathSoundChoices()) do
        if option.key == selected then
            chosen = option
            break
        end
    end

    if not chosen then
        for _, option in ipairs(self:GetSurvivalDeathSoundChoices()) do
            if option.key == "Quest Failed" then
                chosen = option
                break
            end
        end
    end

    if not chosen then return false end

    if chosen.soundID and type(PlaySound) == "function" then
        local ok, played = pcall(PlaySound, chosen.soundID, "Master")
        return ok and played ~= false
    end

    if chosen.path and type(PlaySoundFile) == "function" then
        local ok, played = pcall(PlaySoundFile, chosen.path, "Master")
        return ok and played ~= false
    end

    return false
end

function BW:SetSurvivalDeathSoundEnabled(value)
    if not self.db then return end
    self.db.survivalDeathSoundEnabled = value and true or false
    self:RefreshSurvivalDeathRoster()
end

function BW:TestSurvivalDeathSound()
    return self:PlaySurvivalDeathSound(true)
end

function BW:IsSurvivalDeathTrackedUnit(unit)
    if not unit or not IsInGroup() then return false end

    if IsInRaid() then
        return string.match(unit, "^raid%d+$") ~= nil
    end

    if unit == "player" then
        return true
    end

    return string.match(unit, "^party%d+$") ~= nil
end

function BW:RefreshSurvivalDeathRoster()
    self.survivalDeathCache = self.survivalDeathCache or {}
    wipe(self.survivalDeathCache)

    if not IsInGroup() then return end

    if IsInRaid() then
        local count = GetNumGroupMembers() or 0
        for i = 1, count do
            local unit = "raid" .. i
            if UnitExists(unit) then
                self.survivalDeathCache[unit] = UnitIsDeadOrGhost(unit) and true or false
            end
        end
    else
        self.survivalDeathCache.player = UnitIsDeadOrGhost("player") and true or false

        local count = GetNumSubgroupMembers() or 0
        for i = 1, count do
            local unit = "party" .. i
            if UnitExists(unit) then
                self.survivalDeathCache[unit] = UnitIsDeadOrGhost(unit) and true or false
            end
        end
    end
end

function BW:UpdateSurvivalDeathUnit(unit)
    if not self:IsSurvivalDeathTrackedUnit(unit) then return end

    self.survivalDeathCache = self.survivalDeathCache or {}

    local isDead = UnitIsDeadOrGhost(unit) and true or false
    local wasDead = self.survivalDeathCache[unit]

    if wasDead == nil then
        self.survivalDeathCache[unit] = isDead
        return
    end

    if not wasDead and isDead
        and self.db
        and self.db.survivalModuleEnabled
        and self.db.survivalDeathSoundEnabled ~= false then

        local now = (GetTimePreciseSec and GetTimePreciseSec()) or GetTime()
        local nextAllowed = tonumber(self.survivalNextDeathSoundAt) or 0

        if now >= nextAllowed then
            if self:PlaySurvivalDeathSound(false) then
                local throttle = math.max(
                    0,
                    tonumber(self.db.survivalDeathSoundThrottleSeconds) or 0.5
                )
                self.survivalNextDeathSoundAt = now + throttle
            end
        end
    end

    self.survivalDeathCache[unit] = isDead
end

function BW:EnsureSurvivalDeathEvents()
    if self.survivalDeathEventFrame then return end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_FLAGS")

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_HEALTH" or event == "UNIT_FLAGS" then
            BW:UpdateSurvivalDeathUnit(unit)
        else
            BW:RefreshSurvivalDeathRoster()
        end
    end)

    self.survivalDeathEventFrame = frame
    self:RefreshSurvivalDeathRoster()
end

local function EnsureEvents()
    if BW.survivalEventFrame then return end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    pcall(frame.RegisterEvent, frame, "BAG_UPDATE_COOLDOWN")
    local frequentHealthOK = pcall(
        frame.RegisterUnitEvent,
        frame,
        "UNIT_HEALTH_FREQUENT",
        "player"
    )
    if not frequentHealthOK then
        frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    end
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")

    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            BW.survivalWorldReady = true
            BW:ApplySurvivalSettings()
        else
            BW:UpdateSurvivalHelper()
        end

        if event == "BAG_UPDATE_DELAYED"
            or event == "BAG_UPDATE_COOLDOWN"
            or event == "SPELLS_CHANGED"
            or event == "SPELL_UPDATE_COOLDOWN"
            or event == "SPELL_UPDATE_CHARGES"
            or event == "PLAYER_SPECIALIZATION_CHANGED" then

            RefreshOptionsIfOpen()
        end
    end)

    BW.survivalEventFrame = frame
end

function BW:InitializeSurvivalHelper()
    EnsureEvents()
    EnsureActionStorage()
    self:EnsureSurvivalDeathEvents()

    local frame = CreateDisplay()
    frame:Hide()

    -- Keep login work minimal.  PLAYER_ENTERING_WORLD performs the first live
    -- recommendation update after the loading screen is complete.
    if self.survivalWorldReady then
        self:ApplySurvivalSettings()
    end
end
