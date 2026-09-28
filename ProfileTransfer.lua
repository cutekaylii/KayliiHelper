local ADDON_NAME, BW = ...

local PREFIX = "KH1:"
local OBFUSCATION_KEY = "KayliiHelperProfile"
local MAX_INPUT = 2 * 1024 * 1024
local MAX_DEPTH = 64
local MAX_ITEMS = 100000

local BASE64_CHARS =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Adler32(text)
    local a, b = 1, 0
    for index = 1, #text do
        a = (a + string.byte(text, index)) % 65521
        b = (b + a) % 65521
    end
    return b * 65536 + a
end

local function Obfuscate(text, decode)
    local output = {}
    local keyLength = #OBFUSCATION_KEY
    for index = 1, #text do
        local byte = string.byte(text, index)
        local keyByte = string.byte(OBFUSCATION_KEY, ((index - 1) % keyLength) + 1)
        output[index] = string.char(
            decode and ((byte - keyByte) % 256) or ((byte + keyByte) % 256)
        )
    end
    return table.concat(output)
end

local function Base64Encode(text)
    local output = {}
    local index = 1
    while index <= #text do
        local a = string.byte(text, index) or 0
        local b = string.byte(text, index + 1) or 0
        local c = string.byte(text, index + 2) or 0
        local value = a * 65536 + b * 256 + c
        local remaining = #text - index + 1
        output[#output + 1] = BASE64_CHARS:sub(math.floor(value / 262144) % 64 + 1, math.floor(value / 262144) % 64 + 1)
        output[#output + 1] = BASE64_CHARS:sub(math.floor(value / 4096) % 64 + 1, math.floor(value / 4096) % 64 + 1)
        output[#output + 1] = remaining >= 2 and BASE64_CHARS:sub(math.floor(value / 64) % 64 + 1, math.floor(value / 64) % 64 + 1) or "="
        output[#output + 1] = remaining >= 3 and BASE64_CHARS:sub(value % 64 + 1, value % 64 + 1) or "="
        index = index + 3
    end
    return table.concat(output)
end

local function Base64Decode(text)
    if #text % 4 ~= 0 or text:find("[^A-Za-z0-9+/=]") then
        return nil, "Profile contains invalid encoded data."
    end
    local lookup = {}
    for index = 1, #BASE64_CHARS do
        lookup[BASE64_CHARS:sub(index, index)] = index - 1
    end
    local output = {}
    for index = 1, #text, 4 do
        local c1, c2 = text:sub(index, index), text:sub(index + 1, index + 1)
        local c3, c4 = text:sub(index + 2, index + 2), text:sub(index + 3, index + 3)
        if not lookup[c1] or not lookup[c2]
            or (c3 ~= "=" and not lookup[c3])
            or (c4 ~= "=" and not lookup[c4]) then
            return nil, "Profile contains invalid encoded data."
        end
        local value = lookup[c1] * 262144 + lookup[c2] * 4096
            + (lookup[c3] or 0) * 64 + (lookup[c4] or 0)
        output[#output + 1] = string.char(math.floor(value / 65536) % 256)
        if c3 ~= "=" then output[#output + 1] = string.char(math.floor(value / 256) % 256) end
        if c4 ~= "=" then output[#output + 1] = string.char(value % 256) end
    end
    return table.concat(output)
end

local function SortedKeys(value)
    local keys = {}
    for key in pairs(value) do
        local kind = type(key)
        if kind ~= "string" and kind ~= "number" then
            error("Unsupported profile key type: " .. kind)
        end
        keys[#keys + 1] = key
    end
    table.sort(keys, function(left, right)
        if type(left) == type(right) then return left < right end
        return type(left) < type(right)
    end)
    return keys
end

local function Serialize(value, output, seen, depth)
    if depth > MAX_DEPTH then error("Profile nesting is too deep.") end
    local kind = type(value)
    if kind == "boolean" then
        output[#output + 1] = value and "t" or "f"
    elseif kind == "number" then
        local text = tostring(value)
        output[#output + 1] = "n" .. #text .. ":" .. text
    elseif kind == "string" then
        output[#output + 1] = "s" .. #value .. ":" .. value
    elseif kind == "table" then
        if seen[value] then error("Profile contains a circular table.") end
        seen[value] = true
        local keys = SortedKeys(value)
        output[#output + 1] = "d" .. #keys .. ":"
        for _, key in ipairs(keys) do
            Serialize(key, output, seen, depth + 1)
            Serialize(value[key], output, seen, depth + 1)
        end
        seen[value] = nil
    else
        error("Unsupported profile value type: " .. kind)
    end
end

local function Deserialize(text)
    local position, items = 1, 0
    local function ReadValue(depth)
        if depth > MAX_DEPTH then error("Profile nesting is too deep.") end
        items = items + 1
        if items > MAX_ITEMS then error("Profile contains too many values.") end
        local marker = text:sub(position, position)
        position = position + 1
        if marker == "t" then return true end
        if marker == "f" then return false end
        if marker ~= "n" and marker ~= "s" and marker ~= "d" then
            error("Profile contains an invalid value.")
        end
        local colon = text:find(":", position, true)
        if not colon then error("Profile value is incomplete.") end
        local length = tonumber(text:sub(position, colon - 1))
        if not length or length < 0 or length ~= math.floor(length) then
            error("Profile contains an invalid length.")
        end
        position = colon + 1
        if marker == "n" or marker == "s" then
            local last = position + length - 1
            if last > #text then error("Profile value is incomplete.") end
            local value = text:sub(position, last)
            position = last + 1
            if marker == "n" then
                value = tonumber(value)
                if not value then error("Profile contains an invalid number.") end
            end
            return value
        end
        local result = {}
        for _ = 1, length do
            local key = ReadValue(depth + 1)
            if type(key) ~= "string" and type(key) ~= "number" then
                error("Profile contains an invalid table key.")
            end
            result[key] = ReadValue(depth + 1)
        end
        return result
    end
    local value = ReadValue(0)
    if position ~= #text + 1 then error("Profile contains trailing data.") end
    return value
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[DeepCopy(key, seen)] = DeepCopy(child, seen)
    end
    return copy
end

local function ApplyTopLevel(target, source)
    for key, value in pairs(source) do
        target[key] = DeepCopy(value)
    end
end

function BW:ExportProfileString()
    local profile = {
        format = 1,
        account = DeepCopy(KayliiHelperDB or self.db or {}),
        character = DeepCopy(KayliiHelperCharacterDB or self.characterDB or {}),
    }
    local output = {}
    local ok, message = pcall(Serialize, profile, output, {}, 0)
    if not ok then return nil, tostring(message) end
    local serialized = table.concat(output)
    local checksum = string.format("%08X", Adler32(serialized))
    return PREFIX .. checksum .. ":" .. Base64Encode(Obfuscate(serialized, false))
end

function BW:ImportProfileString(value)
    local text = tostring(value or ""):gsub("%s+", "")
    if #text > MAX_INPUT then return false, "Profile is too large." end
    if text:sub(1, #PREFIX) ~= PREFIX then
        return false, "This is not a Kaylii Helper profile."
    end
    local checksum, encoded = text:match("^KH1:([0-9A-Fa-f]+):(.+)$")
    if not checksum or #checksum ~= 8 then return false, "Profile header is invalid." end
    local decoded, decodeError = Base64Decode(encoded)
    if not decoded then return false, decodeError end
    local serialized = Obfuscate(decoded, true)
    if string.format("%08X", Adler32(serialized)) ~= checksum:upper() then
        return false, "Profile checksum failed. The text may be incomplete."
    end
    local ok, profile = pcall(Deserialize, serialized)
    if not ok then return false, tostring(profile) end
    if type(profile) ~= "table" or profile.format ~= 1
        or type(profile.account) ~= "table"
        or type(profile.character) ~= "table" then
        return false, "Profile data is incomplete or unsupported."
    end

    KayliiHelperProfileBackupDB = DeepCopy(KayliiHelperDB or self.db or {})
    KayliiHelperProfileBackupCharacterDB = DeepCopy(
        KayliiHelperCharacterDB or self.characterDB or {}
    )
    KayliiHelperDB = KayliiHelperDB or {}
    KayliiHelperCharacterDB = KayliiHelperCharacterDB or {}
    ApplyTopLevel(KayliiHelperDB, profile.account)
    ApplyTopLevel(KayliiHelperCharacterDB, profile.character)
    BuffWhitelistDB = KayliiHelperDB
    self.db = KayliiHelperDB
    self.characterDB = KayliiHelperCharacterDB
    return true, "Profile imported. Reloading the UI applies every setting."
end

