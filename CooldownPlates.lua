-- CooldownPlates.lua
-- Enemy cooldown tracking addon for WoW 1.12

------------------------------------------------
--[[ Section 1: Namespace and Constants ]]
------------------------------------------------
local CooldownPlates = {}

------------------------------------------------
--[[ Section 2: API Function Aliases ]]
------------------------------------------------
local GetTime            = GetTime
local SpellInfo          = SpellInfo
local UnitIsFriend       = UnitIsFriend
local CreateFrame        = CreateFrame
local pairs              = pairs
local ipairs             = ipairs
local table_getn         = table.getn
local tostring           = tostring
local math_mod           = math.mod
local string_format      = string.format

------------------------------------------------
--[[ Section 3: Configuration Constants ]]
------------------------------------------------
-- These constants will be overridden by saved variables if available
local DEFAULT_MAX_ICONS           = 5     -- Maximum number of cooldown icons displayed per nameplate
local DEFAULT_ICON_SPACING        = 33    -- Horizontal spacing between cooldown icons
local DEFAULT_ICON_SIZE           = 33    -- Width and height of each cooldown icon in pixels
local DEFAULT_ICON_VERTICAL_OFFSET = 35   -- Vertical offset of the icons above the top edge of the nameplate

-- These constants are fixed and not user-configurable
local UPDATE_INTERVAL             = 0.5   -- Time interval in seconds for updating cooldown displays and nameplate detection
local ICON_TEXTURE_COORD_LEFT     = 0.1   -- Left texture coordinate for icon textures
local ICON_TEXTURE_COORD_RIGHT    = 0.9   -- Right texture coordinate for icon textures
local ICON_TEXTURE_COORD_TOP      = 0.1   -- Top texture coordinate for icon textures
local ICON_TEXTURE_COORD_BOTTOM   = 0.9   -- Bottom texture coordinate for icon textures

-- Runtime variables that will be initialized from saved variables
local MAX_ICONS
local ICON_SPACING
local ICON_SIZE
local ICON_VERTICAL_OFFSET

------------------------------------------------
--[[ Section 4: Cooldown Frame Settings ]]
------------------------------------------------
local COOLDOWN_FRAME_SCALE         -- Will be calculated based on ICON_SIZE
local COOLDOWN_FRAME_ADJUST_RIGHT  -- Will be calculated based on ICON_SIZE
local COOLDOWN_FRAME_ADJUST_BOTTOM -- Will be calculated based on ICON_SIZE

------------------------------------------------
--[[ Section 5: Cooldown Text Settings ]]
------------------------------------------------
local COOLDOWN_TEXT_ENABLED      = true                  -- Enables or disables the display of cooldown text
local COOLDOWN_TEXT_FONT         = "Fonts\\FRIZQT__.TTF" -- Font to be used for cooldown text
local COOLDOWN_TEXT_SIZE         = 12                    -- Font size for cooldown text
local COOLDOWN_TEXT_FLAGS        = "OUTLINE"             -- Font flags for cooldown text (e.g., "OUTLINE", "THICKOUTLINE")
local COOLDOWN_TEXT_MIN_DURATION = 2                     -- Minimum cooldown duration in seconds for text to be displayed

------------------------------------------------
--[[ Section 6: Debug Colors ]]
------------------------------------------------
local DEBUG_COLOR_TABLE = "|cff00ff00"                   -- Green color code for table pool debug messages
local DEBUG_COLOR_FRAME = "|cff00ffff"                   -- Cyan color code for frame debug messages

------------------------------------------------
--[[ Section 7: Tables and Caches ]]
------------------------------------------------
local ICON_POSITION_CACHE = {}     -- Cache for icon position calculations

------------------------------------------------
--[[ Section 8: Tracked Spells ]]
------------------------------------------------
local trackedSpells = {
    -- Trinkets & Racials
    ["Will of the Forsaken"] = {120, nil},
    ["Perception"] = {180, nil},
    ["War Stomp"] = {120, nil},
    ["Escape Artist"] = {60, nil},
    ["Stoneform"] = {180, nil},
	
	["Insignia"] = {180, "inv_jewelry_trinketpvp_02"},
	["Immune Charm/Fear/Stun"] = {180, "inv_jewelry_trinketpvp_02"},
	["Immune Fear/Polymorph/Snare"] = {180, "inv_jewelry_trinketpvp_02"},
	["Immune Fear/Polymorph/Stun"] = {180, "inv_jewelry_trinketpvp_02"},
	["Immune Charm/Fear/Polymorph"] = {180, "inv_jewelry_trinketpvp_02"},
	["Immune Root/Snare/Stun"] = {180, "inv_jewelry_trinketpvp_02"},

    ["Frost Reflector"] = {300, "Spell_Frost_FrostWard"},
    ["Shadow Reflector"] = {300, "Spell_Shadow_AntiShadow"},
    ["Fire Reflector"] = {300, "Spell_Fire_SealOfFire"},

    -- Warrior
    ["Charge"] = {15, nil},
    ["Intercept"] = {30, nil},
    ["Intimidating Shout"] = {180, nil},
    ["Pummel"] = {10, nil},
    ["Disarm"] = {60, nil},
    ["Shield Bash"] = {12, nil},
    ["Sweeping Strikes"] = {30, nil},
    ["Death Wish"] = {180, nil},

    -- Paladin
    ["Blessing of Freedom"] = {20, nil},
    ["Hand of Freedom"] = {20, nil},
    ["Blessing of Protection"] = {300, nil},
    ["Hand of Protection"] = {300, nil},
    ["Divine Protection"] = {300, nil},
    ["Divine Shield"] = {300, nil},
    ["Hammer of Justice"] = {60, nil},
    ["Repentance"] = {60, nil},

    -- Mage
    ["Blink"] = {15, nil},
    ["Blast Wave"] = {45, nil},
    ["Fire Ward"] = {30, nil},
    ["Cone of Cold"] = {10, nil},
    ["Frost Nova"] = {25, nil},
    ["Frost Ward"] = {30, nil},
    ["Ice Barrier"] = {30, nil},
    ["Counterspell"] = {30, nil},
    ["Presence of Mind"] = {180, nil},
    ["Combustion"] = {180, nil},
    ["Cold Snap"] = {600, nil},
    ["Ice Block"] = {300, nil},

    -- Rogue
    ["Kidney Shot"] = {20, nil},
    ["Evasion"] = {300, nil},
    ["Gouge"] = {10, nil},
    ["Kick"] = {10, nil},
    ["Sprint"] = {300, nil},
    ["Blind"] = {300, nil},
    ["Vanish"] = {300, nil},
    ["Adrenaline Rush"] = {360, nil},
    ["Preparation"] = {600, nil},

    -- Shaman
    ["Earth Shock"] = {6, nil},
    ["Earthbind Totem"] = {15, nil},
    ["Fire Nova Totem"] = {15, nil},
    ["Flame Shock"] = {6, nil},
    ["Frost Shock"] = {6, nil},
    ["Grounding Totem"] = {15, nil},
    ["Elemental Mastery"] = {180, nil},
    ["Nature's Swiftness"] = {180, nil},

    -- Hunter
    ["Scare Beast"] = {30, nil},
    ["Concussive Shot"] = {12, nil},
    ["Flare"] = {15, nil},
    ["Rapid Fire"] = {300, nil},
    ["Volley"] = {60, nil},
    ["Counterattack"] = {5, nil},
    ["Explosive Trap"] = {15, nil},
    ["Feign Death"] = {30, nil},
    ["Freezing Trap"] = {15, nil},
    ["Frost Trap"] = {15, nil},
    ["Immolation Trap"] = {15, nil},
    ["Wyvern Sting"] = {120, nil},
    ["Bestial Wrath"] = {120, nil},
    ["Intimidation"] = {60, nil},
    ["Deterrence"] = {300, nil},
    ["Scatter Shot"] = {30, nil},

    -- Warlock
    ["Death Coil"] = {120, nil},
    ["Howl of Terror"] = {40, nil},
    ["Shadow Ward"] = {30, nil},
    ["Conflagrate"] = {10, nil},
    ["Shadowburn"] = {15, nil},
    ["Fel Domination"] = {900, nil},
	["Spell Lock"] = {30, nil},
	["Devour Magic"] = {30, nil},

    -- Priest
    ["Elune's Grace"] = {300, nil},
    ["Feedback"] = {180, nil},
    ["Desperate Prayer"] = {600, nil},
    ["Fear Ward"] = {30, nil},
    ["Devouring Plague"] = {180, nil},
    ["Psychic Scream"] = {30, nil},
    ["Inner Focus"] = {180, nil},
    ["Power Infusion"] = {180, nil},
    ["Silence"] = {45, nil},

    -- Druid
    ["Barkskin"] = {60, nil},
    ["Hurricane"] = {60, nil},
    ["Nature's Grasp"] = {60, nil},
    ["Bash"] = {60, nil},
    ["Dash"] = {300, nil},
    ["Enrage"] = {60, nil},
    ["Frenzied Regeneration"] = {180, nil},
    ["Prowl"] = {10, nil},
    ["Tranquility"] = {300, nil},
    ["Innervate"] = {360, nil},
    ["Feral Charge"] = {15, nil},
    ["Swiftmend"] = {15, nil},
	["Nature's Swiftness"] = {180, nil},
}

local preparationResets = {
    ["Kidney Shot"]     = true,
    ["Blind"]           = true,
    ["Gouge"]           = true,
    ["Vanish"]          = true,
    ["Blade Flurry"]    = true,
    ["Adrenaline Rush"] = true,
	["Sprint"]          = true,
	["Evasion"]         = true,
	["Premeditation"]   = true,
	["Distract"]        = true,
	["Stealth"]         = true,
}

local coldSnapResets = {
    ["Frost Nova"]    = true,
    ["Ice Block"]     = true,
    ["Cone of Cold"]  = true,
    ["Frost Ward"]    = true,
    ["Ice Barrier"]   = true,
    ["Icicles"]       = true,
}

local readinessResets = {
    ["Aimed Shot"]      = true,
    ["Multi-Shot"]      = true,
    ["Volley"]          = true,
    ["Bestial Wrath"]   = true,
    ["Intimidation"]    = true,
    ["Freezing Trap"]   = true,
    ["Ice Trap"]        = true,
    ["Immolation Trap"] = true,
    ["Explosive Trap"]  = true,
}

-- Add icon path prefix to all spell icons
local ICON_PATH_PREFIX = "Interface\\Icons\\"
for spellName, data in pairs(trackedSpells) do
    if data[2] then  -- Check if an icon is defined
        trackedSpells[spellName][2] = ICON_PATH_PREFIX .. data[2]
    end
end

------------------------------------------------
--[[ Section 9: Initialization and Global Variables ]]
------------------------------------------------
local Compost = AceLibrary("Compost-2.0")               -- Compost library instance for object pooling
local CooldownPlatesFrame = CreateFrame("Frame", "CooldownPlates_MainFrame")

CooldownPlatesFrame:RegisterEvent("VARIABLES_LOADED")
CooldownPlatesFrame:RegisterEvent("UNIT_CASTEVENT")

CooldownPlates.trackedNameplateFrames = {}              -- Table to store tracked nameplate frames
CooldownPlates.unitCooldowns = {}                      -- Table to store unit cooldowns, indexed by unit GUID
CooldownPlates.trackedNameplateCount = 0               -- Counter for the number of tracked nameplates

CooldownPlatesFrame.previousChildrenCount      = 0      -- Stores the previous number of WorldFrame children for nameplate detection
CooldownPlatesFrame.currentChildrenCount       = 0      -- Stores the current number of WorldFrame children for nameplate detection
CooldownPlatesFrame.lastDetectNameplatesUpdate = 0      -- Timestamp of the last nameplate detection update

------------------------------------------------
--[[ Section 10: Helper Functions ]]
------------------------------------------------

--- Updates calculated values based on icon size
local function updateDerivedValues()
    -- Update cooldown frame calculations based on current ICON_SIZE
    COOLDOWN_FRAME_SCALE = (1 / 32) * ICON_SIZE
    COOLDOWN_FRAME_ADJUST_RIGHT = ICON_SIZE * 0.02
    COOLDOWN_FRAME_ADJUST_BOTTOM = ICON_SIZE * 0.027
end

--- Updates the cached icon positions based on current settings
local function updateIconPositionCache()
    ICON_POSITION_CACHE = {}
    for count = 1, MAX_ICONS do
        ICON_POSITION_CACHE[count] = {}
        for i = 1, count do
            local offsetX = (i - (count + 1) / 2) * ICON_SPACING
            ICON_POSITION_CACHE[count][i] = offsetX
        end
    end
    
    -- Update other derived values
    updateDerivedValues()
end

--- Formats cooldown time in seconds into a human-readable string
local function formatCooldownTime(seconds)
    if seconds <= 0 then
        return ""
    end
    
    local color = "|cffffffff"
    
    if seconds < 5 then
        color = "|cffff5555"  -- red
    elseif seconds < 10 then
        color = "|cffffff55"  -- yellow
    end
    
    if seconds < 60 then
        return color .. ceil(seconds)
    elseif seconds < 3600 then
        return color .. ceil(seconds/60) .. "m"
    else
        return color .. ceil(seconds/60/60) .. "h"
    end
end

--- Checks if a given frame is a Blizzard nameplate
local function isBlizzardNameplate(frame)
    if frame:GetObjectType() ~= "Button" then return nil end

	-- Check for ShaguTweaks modified nameplates
    if frame.new and frame.new.plate then
        return true
    end

    local regions = frame:GetRegions()
    if not regions then return nil end
    if not regions.GetObjectType then return nil end
    if not regions.GetTexture then return nil end
    if regions:GetObjectType() ~= "Texture" then return nil end
    return regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" or nil
end

--- Gets the appropriate parent frame for a nameplate (handles ShaguTweaks compatibility)
local function getNameplateParent(frame)
    if frame.new then
        return frame.new
    end
    return frame
end

--- Arranges visible cooldown icons around a parent frame
local function arrangeIcons(icons, parent, offsetY)
    local visibleIcons = Compost:GetTable()
    local visibleCount = 0

    for i = 1, table_getn(icons) do
        if icons[i]:IsVisible() then
            visibleCount = visibleCount + 1
            visibleIcons[visibleCount] = icons[i]
        end
    end

    if visibleCount == 0 then
        Compost:Reclaim(visibleIcons)
        return
    end

    -- Get appropriate parent for positioning
    local targetParent = getNameplateParent(parent)

    local positions = ICON_POSITION_CACHE[visibleCount]
    for i = 1, visibleCount do
        visibleIcons[i]:ClearAllPoints()
        visibleIcons[i]:SetPoint("TOP", targetParent, "TOP", positions[i], offsetY)
    end

    Compost:Reclaim(visibleIcons)
end

--- Creates a cooldown icon and its cooldown frame
local function createCooldownIcon(container, index, nameplateFrame)
    local iconName = "CooldownPlates_Icon_" .. tostring(nameplateFrame) .. "_" .. index
    local cooldownIcon = container:CreateTexture(iconName, "OVERLAY")
    cooldownIcon:SetWidth(ICON_SIZE)
    cooldownIcon:SetHeight(ICON_SIZE)
    cooldownIcon:SetTexCoord(ICON_TEXTURE_COORD_LEFT, ICON_TEXTURE_COORD_RIGHT, 
                             ICON_TEXTURE_COORD_TOP, ICON_TEXTURE_COORD_BOTTOM)
    cooldownIcon:Hide()

    local cooldownFrameName = "CooldownPlates_CooldownFrame_" .. tostring(nameplateFrame) .. "_" .. index
    local cooldownFrame = CreateFrame("Model", cooldownFrameName, container, "CooldownFrameTemplate")
    cooldownFrame:SetScale(COOLDOWN_FRAME_SCALE)
    cooldownFrame:Hide()

    cooldownFrame:ClearAllPoints()
    cooldownFrame:SetPoint("TOPLEFT", cooldownIcon, "TOPLEFT")
    cooldownFrame:SetPoint("BOTTOMRIGHT", cooldownIcon, "BOTTOMRIGHT", 
                          COOLDOWN_FRAME_ADJUST_RIGHT, -COOLDOWN_FRAME_ADJUST_BOTTOM)

    return cooldownIcon, cooldownFrame
end

--- Creates cooldown text display for a cooldown frame
local function createCooldownText(cooldown)
    if not COOLDOWN_TEXT_ENABLED then return end
    
    local parent = cooldown:GetParent()
    if not parent or not parent:GetParent() or not parent:GetParent().cooldownPlatesData then
        return -- Skip if not part of the addon
    end
    
    local frameName = "CooldownPlates_CooldownText_" .. tostring(cooldown)
    local textFrame = CreateFrame("Frame", frameName, cooldown)
    textFrame:SetAllPoints(cooldown)
    textFrame:SetFrameLevel(cooldown:GetFrameLevel() + 5)

    local fontString = textFrame:CreateFontString(frameName .. "_FontString", "OVERLAY")
    fontString:SetFont(COOLDOWN_TEXT_FONT, COOLDOWN_TEXT_SIZE, COOLDOWN_TEXT_FLAGS)
    fontString:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
    
    textFrame.text = fontString
    textFrame:Hide()
    
    -- Set up the OnUpdate script for dynamic text updates
    textFrame:SetScript("OnUpdate", function()
        if not this.tick then this.tick = GetTime() + 0.1 end
        if this.tick > GetTime() then return end
        this.tick = GetTime() + 0.1

        if this.start < GetTime() then
            -- Normal time calculation (no rollover)
            local remaining = this.duration - (GetTime() - this.start)
            if remaining > 0 then
                this.text:SetText(formatCooldownTime(remaining))
            else
                this:Hide()
            end
        else
            -- Handle 32-bit timestamp rollover issue
            local currentTime = time()
            local startupTime = currentTime - GetTime()
            -- Calculate the "wrapped" time: ((2^32) - (start * 1000)) / 1000
            local cdTime = (2^32) / 1000 - this.start
            local cdStartTime = startupTime - cdTime
            local cdEndTime = cdStartTime + this.duration
            local remaining = cdEndTime - currentTime

            if remaining > 0 then
                this.text:SetText(formatCooldownTime(remaining))
            else
                this:Hide()
            end
        end
    end)
    
    return textFrame
end

--- Updates cooldown text display
local function updateCooldownText(cooldown, start, duration, enable)
    if not COOLDOWN_TEXT_ENABLED then return end
    
    if not cooldown.cooldownText then
        cooldown.cooldownText = createCooldownText(cooldown)
        if not cooldown.cooldownText then return end
    end
    
    if not duration or duration < COOLDOWN_TEXT_MIN_DURATION then
        if cooldown.cooldownText then
            cooldown.cooldownText:Hide()
        end
        return
    end
    
    if start > 0 and duration > 0 and (not enable or enable > 0) then
        cooldown.cooldownText:Show()
        cooldown.cooldownText.start = start
        cooldown.cooldownText.duration = duration
    else
        cooldown.cooldownText:Hide()
    end
end

--- Handles cooldown resets based on spell cast
local function handleCooldownReset(casterGUID, spellName)
    local resetTable = nil

    if spellName == "Preparation" then
        resetTable = preparationResets
    elseif spellName == "Cold Snap" then
        resetTable = coldSnapResets
    elseif spellName == "Readiness" then
        resetTable = readinessResets
    else
        return -- Not a cooldown reset spell
    end

    if CooldownPlates.unitCooldowns[casterGUID] and resetTable then
        for resetSpellName in pairs(resetTable) do
            if CooldownPlates.unitCooldowns[casterGUID] then
                for trackedSpellId, trackedSpellData in pairs(CooldownPlates.unitCooldowns[casterGUID]) do
                    local currentTrackedSpellName = SpellInfo(trackedSpellId)
                    if currentTrackedSpellName == resetSpellName then
                        Compost:Reclaim(CooldownPlates.unitCooldowns[casterGUID][trackedSpellId])
                        CooldownPlates.unitCooldowns[casterGUID][trackedSpellId] = nil
                    end
                end
            end
        end
        updateCooldowns() -- Refresh UI after reset
    end
end

--- Cleans up expired cooldowns
local function cleanupExpiredCooldowns()
    local now = GetTime()
    
    for guid, cooldowns in pairs(CooldownPlates.unitCooldowns) do
        local anyActive = false
        local cooldowns_to_remove = Compost:GetTable()
        local remove_count = 0

        for spellID, spellData in pairs(cooldowns) do
            if now >= spellData.endTime then
                remove_count = remove_count + 1
                cooldowns_to_remove[remove_count] = spellID
            else
                anyActive = true
            end
        end

        for i = 1, remove_count do
            local spellID = cooldowns_to_remove[i]
            Compost:Reclaim(cooldowns[spellID])
            cooldowns[spellID] = nil
        end
        Compost:Reclaim(cooldowns_to_remove)

        if not anyActive then
            Compost:Reclaim(cooldowns)
            CooldownPlates.unitCooldowns[guid] = nil
        end
    end
end

------------------------------------------------
--[[ Section 11: Frame Creation and Management Functions ]]
------------------------------------------------

--- Detects and caches new Blizzard nameplates
local function detectNameplates()
    CooldownPlatesFrame.currentChildrenCount = WorldFrame:GetNumChildren()

    if CooldownPlatesFrame.previousChildrenCount < CooldownPlatesFrame.currentChildrenCount then
        local worldFrameChildren = Compost:GetTable()
        for i, childFrame in ipairs({WorldFrame:GetChildren()}) do
            worldFrameChildren[i] = childFrame
        end

        for i = CooldownPlatesFrame.previousChildrenCount + 1, CooldownPlatesFrame.currentChildrenCount do
            local frame = worldFrameChildren[i]
            if isBlizzardNameplate(frame) then
                if not frame.cooldownPlatesData then
                    CooldownPlates.trackedNameplateCount = CooldownPlates.trackedNameplateCount + 1
                    CooldownPlates.trackedNameplateFrames[CooldownPlates.trackedNameplateCount] = frame
                    createPlateElements(frame)
                end
            end
        end

        CooldownPlatesFrame.previousChildrenCount = CooldownPlatesFrame.currentChildrenCount
        Compost:Reclaim(worldFrameChildren)
    end
end

--- Creates UI elements for a nameplate to display cooldown icons
function createPlateElements(nameplateFrame)
    -- Create the icon container frame that will hold all cooldown icons for this nameplate
    local iconContainerName = "CooldownPlates_IconContainer_" .. tostring(nameplateFrame)
    local iconContainer = CreateFrame("Frame", iconContainerName, nameplateFrame)
    iconContainer:SetPoint("TOPLEFT", nameplateFrame, "TOPLEFT", 0, 0)
    iconContainer:SetFrameStrata("HIGH")
    iconContainer:SetToplevel(true)
    iconContainer:EnableMouse(false)
    iconContainer:Hide()

    local icons = {}
    local cooldownFrames = {}

    -- Create icon textures and cooldown frames
    for i = 1, MAX_ICONS do
        local icon, cooldownFrame = createCooldownIcon(iconContainer, i, nameplateFrame)
        icons[i] = icon
        cooldownFrames[i] = cooldownFrame
    end

    -- Store all data on the nameplate for easy access
    nameplateFrame.cooldownPlatesData = {
        visible = false,
        GUID = nil,
        iconContainer = iconContainer,
        textureObjects = icons,
        cooldownObjects = cooldownFrames,
        iconVisible = {},
    }

    -- Initialize iconVisible array
    for i = 1, MAX_ICONS do
        nameplateFrame.cooldownPlatesData.iconVisible[i] = false
    end

    -- OnShow script for nameplate
    nameplateFrame:SetScript("OnShow", function()
        local data = this.cooldownPlatesData
        if data and data.iconContainer then
            local unitGUID = this:GetName(1)
            data.GUID = unitGUID
            data.visible = true
            data.iconContainer:Show()
            updateCooldowns()
        end
    end)

    -- OnHide script for nameplate
    nameplateFrame:SetScript("OnHide", function()
        local data = this.cooldownPlatesData
        if data and data.iconContainer then
            data.iconContainer:Hide()
            data.visible = false
        end
    end)

    -- If the nameplate is already visible, trigger OnShow logic immediately
    if nameplateFrame:IsVisible() then
        local data = nameplateFrame.cooldownPlatesData
        local unitGUID = nameplateFrame:GetName(1)
        data.GUID = unitGUID
        data.visible = true
        data.iconContainer:Show()
    end
end

--- Updates frame elements when settings are changed
function updateFrameSettings()
    -- Update runtime variables from saved settings
    MAX_ICONS = CooldownPlatesDB.maxIcons
    ICON_SPACING = CooldownPlatesDB.iconSpacing
    ICON_SIZE = CooldownPlatesDB.iconSize
    ICON_VERTICAL_OFFSET = CooldownPlatesDB.iconVerticalOffset

    -- Recalculate derived values
    updateIconPositionCache()

    -- Update all existing nameplates
    for i = 1, CooldownPlates.trackedNameplateCount do
        local nameplateFrame = CooldownPlates.trackedNameplateFrames[i]
        local data = nameplateFrame.cooldownPlatesData

        if data then
            local currentIconCount = table_getn(data.textureObjects)

            -- Handle icon count changes
            if currentIconCount < MAX_ICONS then
                -- Add more icons if needed
                for j = currentIconCount + 1, MAX_ICONS do
                    local icon, cooldownFrame = createCooldownIcon(data.iconContainer, j, nameplateFrame)
                    data.textureObjects[j] = icon
                    data.cooldownObjects[j] = cooldownFrame
                    data.iconVisible[j] = false
                end
            elseif currentIconCount > MAX_ICONS then
                -- Hide excess icons
                for j = MAX_ICONS + 1, currentIconCount do
                    if data.textureObjects[j] then
                        data.textureObjects[j]:Hide()
                    end
                    if data.cooldownObjects[j] then
                        data.cooldownObjects[j]:Hide()
                    end
                    data.iconVisible[j] = false
                end
            end

            -- Update size and position of all visible icons
            for j = 1, math.min(currentIconCount, MAX_ICONS) do
                data.textureObjects[j]:SetWidth(ICON_SIZE)
                data.textureObjects[j]:SetHeight(ICON_SIZE)

                data.cooldownObjects[j]:SetScale(COOLDOWN_FRAME_SCALE)
                data.cooldownObjects[j]:ClearAllPoints()
                data.cooldownObjects[j]:SetPoint("TOPLEFT", data.textureObjects[j], "TOPLEFT")
                data.cooldownObjects[j]:SetPoint("BOTTOMRIGHT", data.textureObjects[j], "BOTTOMRIGHT", 
                                               COOLDOWN_FRAME_ADJUST_RIGHT, -COOLDOWN_FRAME_ADJUST_BOTTOM)
            end

            -- Arrange icons with new settings
            arrangeIcons(data.textureObjects, nameplateFrame, ICON_VERTICAL_OFFSET)
        end
    end

    -- Force cooldown update to apply new settings
    updateCooldowns()
end

------------------------------------------------
--[[ Section 12: Cooldown Update Logic Functions ]]
------------------------------------------------

--- Updates cooldown displays for visible nameplates
function updateCooldowns()
    local now = GetTime()

    -- Clean up expired cooldowns
    cleanupExpiredCooldowns()

    -- Process visible nameplates to update their cooldown icons
    for i = 1, CooldownPlates.trackedNameplateCount do
        local nameplateFrame = CooldownPlates.trackedNameplateFrames[i]
        local data = nameplateFrame.cooldownPlatesData

        if data and data.visible then
            local unitGUID = data.GUID
            if unitGUID and unitGUID ~= "0x0000000000000000" then -- Ignore invalid GUIDs
                local cooldowns = CooldownPlates.unitCooldowns[unitGUID]
                local visibilityChanged = false -- Track if icon visibility changed

                if cooldowns then
                    local iconIndex = 1
                    for spellID, spellData in pairs(cooldowns) do
                        if iconIndex <= MAX_ICONS then
                            local wasVisible = data.iconVisible[iconIndex]
                            data.textureObjects[iconIndex]:SetTexture(spellData.texture)
                            data.textureObjects[iconIndex]:Show()
                            data.iconVisible[iconIndex] = true
                            
                            if not wasVisible then
                                visibilityChanged = true
                            end

                            local timeLeft = spellData.endTime - now
                            if timeLeft > 0 then
                                CooldownFrame_SetTimer(data.cooldownObjects[iconIndex], 
                                                      spellData.startTime, spellData.duration, 1)
                                data.cooldownObjects[iconIndex]:Show()
                            else
                                data.cooldownObjects[iconIndex]:Hide()
                            end
                            iconIndex = iconIndex + 1
                        end
                    end

                    -- Hide any unused icons
                    for j = iconIndex, MAX_ICONS do
                        if data.iconVisible[j] then
                            data.textureObjects[j]:Hide()
                            data.cooldownObjects[j]:Hide()
                            data.iconVisible[j] = false
                            visibilityChanged = true
                        end
                    end
                else
                    -- No cooldowns for this unit, hide all icons
                    for j = 1, MAX_ICONS do
                        if data.iconVisible[j] then
                            data.textureObjects[j]:Hide()
                            data.cooldownObjects[j]:Hide()
                            data.iconVisible[j] = false
                            visibilityChanged = true
                        end
                    end
                end

                -- Only rearrange icons if visibility changed (optimization)
                if visibilityChanged then
                    arrangeIcons(data.textureObjects, nameplateFrame, ICON_VERTICAL_OFFSET)
                end
            end
        end
    end
end

--- Adds a new spell cooldown to track
local function trackSpellCooldown(casterGUID, spellID, spellName)
    if not trackedSpells[spellName] then return end
    
    -- Don't track friendly unit cooldowns
    if UnitIsFriend("player", casterGUID) then
        return
    end
    
    -- Check for cooldown reset spells
    if spellName == "Preparation" or spellName == "Cold Snap" or spellName == "Readiness" then
        handleCooldownReset(casterGUID, spellName)
    end
    
    -- Avoid duplicate cooldowns
    if CooldownPlates.unitCooldowns[casterGUID] then
        for existingSpellID, existingSpellData in pairs(CooldownPlates.unitCooldowns[casterGUID]) do
            if existingSpellData.spellName == spellName and existingSpellData.endTime > GetTime() then
                return
            end
        end
    end
    
    -- Get spell data
    local cooldownDuration = trackedSpells[spellName][1]
    local customIconTexture = trackedSpells[spellName][2]
    local _, _, iconTexture = SpellInfo(spellID)
    
    -- Create new cooldown entry
    local spellData = Compost:GetTable()
    spellData.startTime = GetTime()
    spellData.endTime = spellData.startTime + cooldownDuration
    spellData.texture = customIconTexture or iconTexture
    spellData.duration = cooldownDuration
    spellData.spellName = spellName
    
    -- Add to tracking table
    if not CooldownPlates.unitCooldowns[casterGUID] then
        CooldownPlates.unitCooldowns[casterGUID] = Compost:GetTable()
    end
    
    CooldownPlates.unitCooldowns[casterGUID][spellID] = spellData
end

------------------------------------------------
--[[ Section 13: Hooks ]]
------------------------------------------------

--- Custom CooldownFrame_SetTimer hook for adding text display
local function cooldownPlates_CooldownFrame_SetTimer(cooldown, start, duration, enable)
    -- Only apply text to our own cooldown frames
    local parent = cooldown:GetParent()
    if not parent or not parent:GetParent() or not parent:GetParent().cooldownPlatesData then
        return
    end
    
    updateCooldownText(cooldown, start, duration, enable)
end

-- Hook the original CooldownFrame_SetTimer function
local originalCooldownFrame_SetTimer = CooldownFrame_SetTimer
CooldownFrame_SetTimer = function(cooldown, start, duration, enable)
    originalCooldownFrame_SetTimer(cooldown, start, duration, enable)
    if CooldownPlatesDB.hookCooldownFrame_SetTimer then
        cooldownPlates_CooldownFrame_SetTimer(cooldown, start, duration, enable)
    end
end

------------------------------------------------
--[[ Section 14: Event Handlers and Main Update Loop ]]
------------------------------------------------

--- Handles addon events
CooldownPlatesFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        -- Initialize addon
        DEFAULT_CHAT_FRAME:AddMessage(DEBUG_COLOR_TABLE .. "[CooldownPlates]|r loaded.")
        DEFAULT_CHAT_FRAME:AddMessage("Type " .. DEBUG_COLOR_TABLE .. "/cooldownplates|r to see available options.")

        -- Initialize or migrate settings
        if not CooldownPlatesDB then
            CooldownPlatesDB = {}
        end

        -- Set defaults for any missing settings
        if CooldownPlatesDB.hookCooldownFrame_SetTimer == nil then
            CooldownPlatesDB.hookCooldownFrame_SetTimer = false
        end
        if CooldownPlatesDB.maxIcons == nil then
            CooldownPlatesDB.maxIcons = DEFAULT_MAX_ICONS
        end
        if CooldownPlatesDB.iconSpacing == nil then
            CooldownPlatesDB.iconSpacing = DEFAULT_ICON_SPACING
        end
        if CooldownPlatesDB.iconSize == nil then
            CooldownPlatesDB.iconSize = DEFAULT_ICON_SIZE
        end
        if CooldownPlatesDB.iconVerticalOffset == nil then
            CooldownPlatesDB.iconVerticalOffset = DEFAULT_ICON_VERTICAL_OFFSET
        end
        if CooldownPlatesDB.debugMode == nil then
            CooldownPlatesDB.debugMode = false
        end

        -- Apply settings to runtime variables
        MAX_ICONS = CooldownPlatesDB.maxIcons
        ICON_SPACING = CooldownPlatesDB.iconSpacing
        ICON_SIZE = CooldownPlatesDB.iconSize
        ICON_VERTICAL_OFFSET = CooldownPlatesDB.iconVerticalOffset

        -- Initialize tracking tables
        CooldownPlates.unitCooldowns = {}
        CooldownPlates.trackedNameplateFrames = {}
        CooldownPlates.trackedNameplateCount = 0

        -- Pre-calculate icon positions and other derived values
        updateIconPositionCache()

    elseif event == "UNIT_CASTEVENT" then
        local casterGUID = arg1
        -- local targetGUID = arg2
        local eventType  = arg3
        local spellID    = arg4

        if eventType == "CAST" then
            local spellName = SpellInfo(spellID)
            
            if CooldownPlatesDB.debugMode then
                local casterName = UnitName(casterGUID)
                DEFAULT_CHAT_FRAME:AddMessage(DEBUG_COLOR_TABLE .. "[CooldownPlates Debug]|r Caster: " .. 
                                           casterName .. " Spell: " .. spellName)
            end
            
            if trackedSpells[spellName] then
                trackSpellCooldown(casterGUID, spellID, spellName)
                updateCooldowns()
            end
        end
    end
end)

--- Main update loop
CooldownPlatesFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now - this.lastDetectNameplatesUpdate >= UPDATE_INTERVAL then
        this.lastDetectNameplatesUpdate = now
        detectNameplates()
        updateCooldowns()
    end
end)

------------------------------------------------
--[[ Section 15: Slash Command Handler ]]
------------------------------------------------
SLASH_COOLDOWNPLATES1 = "/cooldownplates"

SlashCmdList["COOLDOWNPLATES"] = function(msg)
    local args = {}
    if msg and msg ~= "" then
        for word in string.gfind(msg, "%S+") do
            table.insert(args, word)
        end
    end

    -- Print help message
    local function printHelpMessage()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates debug|r - Toggle debug mode")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates timer|r - Toggle timer display on/off")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates icons [1-7]|r - Set maximum number of icons")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates spacing [20-60]|r - Set spacing between icons")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates size [20-50]|r - Set icon size")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates offset [20-70]|r - Set vertical offset above nameplates")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/cooldownplates reset|r - Reset to default settings")
    end

    if table_getn(args) == 0 then
        printHelpMessage()
        return
    end

    local cmd = args[1]
    local value = tonumber(args[2])
    local settingsChanged = false

    if cmd == "timer" then
        CooldownPlatesDB.hookCooldownFrame_SetTimer = not CooldownPlatesDB.hookCooldownFrame_SetTimer
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Timer hook " .. 
                                    (CooldownPlatesDB.hookCooldownFrame_SetTimer and 
                                    "|cff00ff00enabled" or "|cffff0000disabled"))

    elseif cmd == "icons" and value ~= nil then
        if value >= 1 and value <= 7 then
            CooldownPlatesDB.maxIcons = value
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Max icons set to " .. value)
            settingsChanged = true
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[CooldownPlates]|r Invalid icon count. " ..
                                        "Please choose a value between 1 and 7.")
        end

    elseif cmd == "spacing" and value ~= nil then
        if value >= 20 and value <= 60 then
            CooldownPlatesDB.iconSpacing = value
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Icon spacing set to " .. value)
            settingsChanged = true
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[CooldownPlates]|r Invalid icon spacing. " ..
                                        "Please choose a value between 20 and 60.")
        end

    elseif cmd == "size" and value ~= nil then
        if value >= 20 and value <= 50 then
            CooldownPlatesDB.iconSize = value
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Icon size set to " .. value)
            settingsChanged = true
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[CooldownPlates]|r Invalid icon size. " ..
                                        "Please choose a value between 20 and 50.")
        end

    elseif cmd == "offset" and value ~= nil then
        if value >= 20 and value <= 70 then
            CooldownPlatesDB.iconVerticalOffset = value
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Vertical offset set to " .. value)
            settingsChanged = true
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[CooldownPlates]|r Invalid vertical offset. " ..
                                        "Please choose a value between 20 and 70.")
        end

    elseif cmd == "reset" then
        CooldownPlatesDB.hookCooldownFrame_SetTimer = false
        CooldownPlatesDB.maxIcons = DEFAULT_MAX_ICONS
        CooldownPlatesDB.iconSpacing = DEFAULT_ICON_SPACING
        CooldownPlatesDB.iconSize = DEFAULT_ICON_SIZE
        CooldownPlatesDB.iconVerticalOffset = DEFAULT_ICON_VERTICAL_OFFSET
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Settings reset to defaults.")
        settingsChanged = true
        
    elseif cmd == "debug" then
        CooldownPlatesDB.debugMode = not CooldownPlatesDB.debugMode
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CooldownPlates]|r Debug mode " .. 
                                    (CooldownPlatesDB.debugMode and 
                                    "|cff00ff00enabled" or "|cffff0000disabled"))
    else
        printHelpMessage()
    end

    if settingsChanged then
        updateFrameSettings()
    end
end