-- Mardot.lua
-- Addon to track DoT/Debuff durations on enemy nameplates for Turtle WoW
-- Version: 2.1 - Custom priority ordering and configuration UI

Mardot = {}
Mardot.frames = {}
Mardot.debuffs = {}
Mardot.playerBuffs = {}
Mardot.lastScan = 0
Mardot.channeling = nil

-- Default configuration
Mardot.defaults = {
    enabled = true,
    iconSize = 24,
    offsetX = 0,
    offsetY = -30,
    updateInterval = 0.05,
    maxIcons = 6,
    iconSpacing = 2,
}

-- Initialize config
Mardot.config = {}

-- Base debuff durations, icons, and priorities
Mardot.baseDebuffData = {
    -- Warlock Curses (Priority 1-3)
    ["Curse of Agony"] = { 
        duration = 24, 
        tickRate = 2, 
        icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
        color = {0.8, 0.2, 0.2},
        priority = 1,
        enabled = true,
    },
    ["Curse of Shadows"] = { 
        duration = 300, 
        tickRate = 300, 
        icon = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
        color = {0.3, 0.0, 0.5},
        priority = 2,
        enabled = true,
    },
    ["Curse of Recklessness"] = { 
        duration = 120, 
        tickRate = 120, 
        icon = "Interface\\Icons\\Spell_Shadow_UnholyStrength",
        color = {0.6, 0.0, 0.0},
        priority = 3,
        enabled = true,
    },
    ["Curse of Doom"] = { 
        duration = 60, 
        tickRate = 60, 
        icon = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness",
        color = {0.2, 0.2, 0.2},
        priority = 4,
        enabled = true,
    },
    ["Curse of Weakness"] = { 
        duration = 120, 
        tickRate = 120, 
        icon = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth",
        color = {0.4, 0.2, 0.0},
        priority = 5,
        enabled = true,
    },
    ["Curse of Tongues"] = { 
        duration = 30, 
        tickRate = 30, 
        icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
        color = {0.5, 0.0, 0.3},
        priority = 6,
        enabled = true,
    },
    
    -- Corruption (Priority 10)
    ["Corruption"] = { 
        duration = 18, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion",
        color = {0.5, 0.2, 0.8},
        priority = 10,
        enabled = true,
    },
    
    -- Other Warlock DoTs (Priority 20+)
    ["Immolate"] = { 
        duration = 15, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Fire_Immolation",
        color = {1.0, 0.5, 0.0},
        priority = 20,
        enabled = true,
    },
    ["Siphon Life"] = { 
        duration = 30, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Shadow_Requiem",
        color = {0.0, 0.8, 0.4},
        priority = 21,
        enabled = true,
    },
    ["Unstable Affliction"] = { 
        duration = 18, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Shadow_UnstableAffliction_3",
        color = {0.6, 0.2, 0.6},
        priority = 22,
        enabled = true,
    },
    
    -- Priest (Priority 100+)
    ["Shadow Word: Pain"] = { 
        duration = 18, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
        color = {0.4, 0.0, 0.4},
        priority = 100,
        enabled = true,
    },
    ["Vampiric Embrace"] = { 
        duration = 60, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Shadow_UnsummonBuilding",
        color = {0.6, 0.0, 0.0},
        priority = 101,
        enabled = true,
    },
    ["Devouring Plague"] = { 
        duration = 24, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Shadow_BlackPlague",
        color = {0.3, 0.6, 0.3},
        priority = 102,
        enabled = true,
    },
    
    -- Druid (Priority 200+)
    ["Moonfire"] = { 
        duration = 12, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Spell_Nature_StarFall",
        color = {0.4, 0.6, 1.0},
        priority = 200,
        enabled = true,
    },
    ["Insect Swarm"] = { 
        duration = 12, 
        tickRate = 2, 
        icon = "Interface\\Icons\\Spell_Nature_InsectSwarm",
        color = {0.6, 0.8, 0.2},
        priority = 201,
        enabled = true,
    },
    ["Rake"] = { 
        duration = 9, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Ability_Druid_Disembowel",
        color = {0.8, 0.4, 0.0},
        priority = 202,
        enabled = true,
    },
    ["Rip"] = { 
        duration = 12, 
        tickRate = 2, 
        icon = "Interface\\Icons\\Ability_GhoulFrenzy",
        color = {0.8, 0.0, 0.0},
        priority = 203,
        enabled = true,
    },
    
    -- Rogue (Priority 300+)
    ["Rupture"] = { 
        duration = 16, 
        tickRate = 2, 
        icon = "Interface\\Icons\\Ability_Rogue_Rupture",
        color = {0.8, 0.0, 0.0},
        priority = 300,
        enabled = true,
    },
    ["Garrote"] = { 
        duration = 18, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Ability_Rogue_Garrote",
        color = {0.6, 0.0, 0.0},
        priority = 301,
        enabled = true,
    },
    
    -- Hunter (Priority 400+)
    ["Serpent Sting"] = { 
        duration = 15, 
        tickRate = 3, 
        icon = "Interface\\Icons\\Ability_Hunter_Quickshot",
        color = {0.0, 0.8, 0.0},
        priority = 400,
        enabled = true,
    },
}

-- Initialize saved variables
function Mardot:InitializeSavedVars()
    if not MardotDB then
        MardotDB = {}
    end
    
    -- Copy defaults
    for k, v in pairs(self.defaults) do
        if MardotDB[k] == nil then
            MardotDB[k] = v
        end
    end
    
    -- Initialize debuff enabled states
    if not MardotDB.debuffStates then
        MardotDB.debuffStates = {}
    end
    
    for spell, data in pairs(self.baseDebuffData) do
        if MardotDB.debuffStates[spell] == nil then
            MardotDB.debuffStates[spell] = data.enabled
        end
    end
    
    self.config = MardotDB
end

-- Initialize the addon
function Mardot:Initialize()
    self:InitializeSavedVars()
    self:Print("Mardot v2.1 loaded! Type /mardot config for settings")
    
    -- Create update frame
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame.elapsed = 0
    self.updateFrame:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + arg1
        if this.elapsed >= Mardot.config.updateInterval then
            Mardot:UpdateAllPlates()
            Mardot:ScanPlayerBuffs()
            this.elapsed = 0
        end
    end)
    
    -- Register combat log events
    self:RegisterCombatLogEvents()
    
    -- Hook nameplate creation
    self:HookNameplates()
end

-- Register combat log events
function Mardot:RegisterCombatLogEvents()
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
    self.eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.eventFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
    self.eventFrame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
    self.eventFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    self.eventFrame:RegisterEvent("VARIABLES_LOADED")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "VARIABLES_LOADED" then
            Mardot:InitializeSavedVars()
        elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" or 
           event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" then
            Mardot:OnDebuffApplied(arg1)
        elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
            Mardot:OnDebuffFaded(arg1)
        elseif event == "PLAYER_AURAS_CHANGED" then
            Mardot:ScanPlayerBuffs()
        elseif event == "SPELLCAST_CHANNEL_START" then
            Mardot:OnChannelStart()
        elseif event == "SPELLCAST_CHANNEL_STOP" or event == "SPELLCAST_CHANNEL_UPDATE" then
            Mardot:OnChannelStop()
        elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
            Mardot:OnDarkHarvestTick(arg1)
        end
    end)
end

-- Track when player starts channeling (like Dark Harvest)
function Mardot:OnChannelStart()
    local spell = CastingBarFrame.channeling
    if spell and spell == "Dark Harvest" then
        self.channeling = {
            spell = "Dark Harvest",
            startTime = GetTime(),
            target = UnitName("target"),
        }
    end
end

function Mardot:OnChannelStop()
    if self.channeling and self.channeling.spell == "Dark Harvest" then
        if self.channeling.target then
            self:UpdateDoTsAfterDarkHarvest(self.channeling.target)
        end
        self.channeling = nil
    end
end

-- Track Dark Harvest ticks to update DoT durations dynamically
function Mardot:OnDarkHarvestTick(message)
    if not self.channeling or self.channeling.spell ~= "Dark Harvest" then return end
    
    if self.channeling.target then
        local target = self.channeling.target
        
        for spell, data in pairs(self.baseDebuffData) do
            local key = target.."-"..spell
            local debuffInfo = self.debuffs[key]
            
            if debuffInfo and debuffInfo.tickRate then
                debuffInfo.lastTick = GetTime()
                local tickReduction = debuffInfo.tickRate
                debuffInfo.duration = debuffInfo.duration - tickReduction
                debuffInfo.darkHarvestTicks = (debuffInfo.darkHarvestTicks or 0) + 1
            end
        end
    end
end

-- Update DoTs after Dark Harvest channeling ends
function Mardot:UpdateDoTsAfterDarkHarvest(target)
    for spell, data in pairs(self.baseDebuffData) do
        local key = target.."-"..spell
        local debuffInfo = self.debuffs[key]
        
        if debuffInfo and debuffInfo.darkHarvestTicks then
            local elapsed = GetTime() - debuffInfo.applied
            if elapsed >= debuffInfo.duration then
                self.debuffs[key] = nil
            end
        end
    end
end

-- Parse combat log for debuff application
function Mardot:OnDebuffApplied(message)
    local target, spell = string.match(message, "(.+) is afflicted by (.+)%.")
    if not target or not spell then
        target, spell = string.match(message, "(.+) suffers? .- from (.+)%.")
    end
    
    if target and spell and self.baseDebuffData[spell] then
        local key = target.."-"..spell
        local currentHaste = self:GetCurrentHaste()
        local baseData = self.baseDebuffData[spell]
        
        local actualDuration = baseData.duration / (1 + currentHaste / 100)
        
        self.debuffs[key] = {
            applied = GetTime(),
            duration = actualDuration,
            baseDuration = baseData.duration,
            tickRate = baseData.tickRate / (1 + currentHaste / 100),
            hasteAtCast = currentHaste,
            lastTick = GetTime(),
            spell = spell,
            darkHarvestTicks = 0,
        }
    end
end

-- Parse combat log for debuff fade
function Mardot:OnDebuffFaded(message)
    local spell, target = string.match(message, "(.+) fades from (.+)%.")
    
    if target and spell and self.baseDebuffData[spell] then
        local key = target.."-"..spell
        self.debuffs[key] = nil
    end
end

-- Scan player buffs for haste effects
function Mardot:ScanPlayerBuffs()
    local currentTime = GetTime()
    if currentTime - self.lastScan < 0.5 then return end
    self.lastScan = currentTime
    
    self.playerBuffs = {}
    
    for i = 1, 32 do
        local texture, applications = UnitBuff("player", i)
        if not texture then break end
        
        DoTTrackerTooltip = DoTTrackerTooltip or CreateFrame("GameTooltip", "DoTTrackerTooltip", nil, "GameTooltipTemplate")
        DoTTrackerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        DoTTrackerTooltip:SetUnitBuff("player", i)
        
        local buffName = DoTTrackerTooltipTextLeft1:GetText()
        if buffName then
            self.playerBuffs[buffName] = true
        end
    end
end

-- Calculate current haste percentage
function Mardot:GetCurrentHaste()
    local totalHaste = 0
    
    if self.playerBuffs["Bloodlust"] then
        totalHaste = totalHaste + 30
    end
    
    if self.playerBuffs["Berserking"] then
        local healthPercent = UnitHealth("player") / UnitHealthMax("player")
        local berserkingHaste = 10 + (1 - healthPercent) * 20
        totalHaste = totalHaste + berserkingHaste
    end
    
    totalHaste = totalHaste + self:GetGearHaste()
    
    return totalHaste
end

-- Scan equipped gear for haste
function Mardot:GetGearHaste()
    local gearHaste = 0
    local scanTooltip = CreateFrame("GameTooltip", "MardotScanTooltip", nil, "GameTooltipTemplate")
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    for slot = 1, 19 do
        scanTooltip:ClearLines()
        scanTooltip:SetInventoryItem("player", slot)
        
        for i = 1, scanTooltip:NumLines() do
            local line = getglobal("MardotScanTooltipTextLeft"..i)
            if line then
                local text = line:GetText()
                if text then
                    local haste = string.match(text, "spell haste rating by (%d+)")
                    if not haste then
                        haste = string.match(text, "%+(%d+) Spell Haste")
                    end
                    if not haste then
                        haste = string.match(text, "Increases spell haste rating by (%d+)")
                    end
                    
                    if haste then
                        gearHaste = gearHaste + tonumber(haste)
                    end
                end
            end
        end
    end
    
    return gearHaste * 0.1
end

-- Hook into nameplate system
function Mardot:HookNameplates()
    local function ScanNameplates()
        for i = 1, WorldFrame:GetNumChildren() do
            local frame = select(i, WorldFrame:GetChildren())
            local region = select(2, frame:GetRegions())
            
            if region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" then
                if not Mardot.frames[frame] then
                    Mardot:SetupNameplate(frame)
                end
            end
        end
    end
    
    self.scanFrame = CreateFrame("Frame")
    self.scanFrame.timer = 0
    self.scanFrame:SetScript("OnUpdate", function()
        this.timer = this.timer - arg1
        if this.timer <= 0 then
            this.timer = 0.5
            ScanNameplates()
        end
    end)
end

-- Setup DoT display on a nameplate
function Mardot:SetupNameplate(plate)
    if self.frames[plate] then return end
    
    local iconSize = self.config.iconSize
    local maxIcons = self.config.maxIcons
    local spacing = self.config.iconSpacing
    
    local dotFrame = CreateFrame("Frame", nil, plate)
    dotFrame:SetWidth(maxIcons * (iconSize + spacing))
    dotFrame:SetHeight(iconSize)
    dotFrame:SetPoint("TOP", plate, "BOTTOM", self.config.offsetX, self.config.offsetY)
    
    dotFrame.icons = {}
    dotFrame.plate = plate
    
    for i = 1, maxIcons do
        local icon = CreateFrame("Frame", nil, dotFrame)
        icon:SetWidth(iconSize)
        icon:SetHeight(iconSize)
        icon:SetPoint("LEFT", dotFrame, "LEFT", (i-1) * (iconSize + spacing), 0)
        
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        icon.texture:SetAllPoints(icon)
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
        icon.border = icon:CreateTexture(nil, "BORDER")
        icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        icon.border:SetBlendMode("ADD")
        icon.border:SetAllPoints(icon)
        
        icon.cooldown = CreateFrame("Cooldown", nil, icon)
        icon.cooldown:SetAllPoints(icon)
        
        icon.text = icon:CreateFontString(nil, "OVERLAY")
        icon.text:SetFont("Fonts\\FRIZQT__.TTF", math.max(10, iconSize * 0.5), "OUTLINE")
        icon.text:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
        
        icon:Hide()
        dotFrame.icons[i] = icon
    end
    
    self.frames[plate] = dotFrame
end

-- Update all nameplates
function Mardot:UpdateAllPlates()
    for plate, dotFrame in pairs(self.frames) do
        if plate:IsVisible() then
            self:UpdatePlate(plate, dotFrame)
        end
    end
end

-- Get target name from nameplate
function Mardot:GetTargetNameFromPlate(plate)
    local children = {plate:GetChildren()}
    for _, child in ipairs(children) do
        local regions = {child:GetRegions()}
        for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" then
                    return text
                end
            end
        end
    end
    return nil
end

-- Update a single nameplate's DoT display
function Mardot:UpdatePlate(plate, dotFrame)
    local targetName = self:GetTargetNameFromPlate(plate)
    
    if not targetName then
        for _, icon in ipairs(dotFrame.icons) do
            icon:Hide()
        end
        return
    end
    
    -- Collect active DoTs
    local activeDots = {}
    local currentTime = GetTime()
    
    for spell, data in pairs(self.baseDebuffData) do
        -- Check if this debuff is enabled
        if self.config.debuffStates[spell] then
            local key = targetName.."-"..spell
            local debuffInfo = self.debuffs[key]
            
            if debuffInfo then
                local elapsed = currentTime - debuffInfo.applied
                local remaining = debuffInfo.duration - elapsed
                
                if remaining > 0 then
                    table.insert(activeDots, {
                        spell = spell,
                        remaining = remaining,
                        icon = data.icon,
                        color = data.color,
                        duration = debuffInfo.duration,
                        priority = data.priority,
                    })
                else
                    self.debuffs[key] = nil
                end
            end
        end
    end
    
    -- Sort by PRIORITY (lower number = higher priority)
    table.sort(activeDots, function(a, b) return a.priority < b.priority end)
    
    -- Update icons
    for i = 1, self.config.maxIcons do
        local icon = dotFrame.icons[i]
        local dot = activeDots[i]
        
        if dot then
            icon.texture:SetTexture(dot.icon)
            icon.border:SetVertexColor(unpack(dot.color))
            icon.text:SetText(string.format("%.0f", dot.remaining))
            
            if dot.remaining > 5 then
                icon.text:SetTextColor(0, 1, 0)
            elseif dot.remaining > 3 then
                icon.text:SetTextColor(1, 1, 0)
            else
                icon.text:SetTextColor(1, 0, 0)
            end
            
            icon:Show()
        else
            icon:Hide()
        end
    end
end

-- Create configuration UI
function Mardot:CreateConfigUI()
    if self.configFrame then
        self.configFrame:Show()
        return
    end
    
    local frame = CreateFrame("Frame", "MardotConfigFrame", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(500)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("Mardot Configuration")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Icon Size Slider
    local sizeSlider = CreateFrame("Slider", "MardotSizeSlider", frame, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -60)
    sizeSlider:SetMinMaxValues(16, 48)
    sizeSlider:SetValue(self.config.iconSize)
    sizeSlider:SetValueStep(2)
    sizeSlider:SetObeyStepOnDrag(true)
    getglobal(sizeSlider:GetName() .. 'Low'):SetText('16')
    getglobal(sizeSlider:GetName() .. 'High'):SetText('48')
    getglobal(sizeSlider:GetName() .. 'Text'):SetText('Icon Size: ' .. self.config.iconSize)
    sizeSlider:SetScript("OnValueChanged", function()
        local val = this:GetValue()
        getglobal(this:GetName() .. 'Text'):SetText('Icon Size: ' .. val)
        Mardot.config.iconSize = val
        Mardot:ReloadNameplates()
    end)
    
    -- Max Icons Slider
    local maxIconsSlider = CreateFrame("Slider", "MardotMaxIconsSlider", frame, "OptionsSliderTemplate")
    maxIconsSlider:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -40)
    maxIconsSlider:SetMinMaxValues(3, 10)
    maxIconsSlider:SetValue(self.config.maxIcons)
    maxIconsSlider:SetValueStep(1)
    maxIconsSlider:SetObeyStepOnDrag(true)
    getglobal(maxIconsSlider:GetName() .. 'Low'):SetText('3')
    getglobal(maxIconsSlider:GetName() .. 'High'):SetText('10')
    getglobal(maxIconsSlider:GetName() .. 'Text'):SetText('Max Icons: ' .. self.config.maxIcons)
    maxIconsSlider:SetScript("OnValueChanged", function()
        local val = this:GetValue()
        getglobal(this:GetName() .. 'Text'):SetText('Max Icons: ' .. val)
        Mardot.config.maxIcons = val
        Mardot:ReloadNameplates()
    end)
    
    -- Debuff toggles section
    local debuffLabel = frame:CreateFontString(nil, "OVERLAY")
    debuffLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    debuffLabel:SetPoint("TOPLEFT", maxIconsSlider, "BOTTOMLEFT", -10, -30)
    debuffLabel:SetText("Enabled Debuffs:")
    
    -- Scrollable debuff list
    local scrollFrame = CreateFrame("ScrollFrame", "MardotScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", debuffLabel, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 15)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(320)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Create checkboxes for each debuff (sorted by priority)
    local sortedDebuffs = {}
    for spell, data in pairs(self.baseDebuffData) do
        table.insert(sortedDebuffs, {spell = spell, priority = data.priority})
    end
    table.sort(sortedDebuffs, function(a, b) return a.priority < b.priority end)
    
    local yOffset = 0
    for _, entry in ipairs(sortedDebuffs) do
        local spell = entry.spell
        local data = self.baseDebuffData[spell]
        
        local checkbox = CreateFrame("CheckButton", "MardotCheck"..spell, scrollChild, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        checkbox:SetChecked(self.config.debuffStates[spell])
        
        local label = checkbox:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11)
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(spell)
        
        checkbox:SetScript("OnClick", function()
            Mardot.config.debuffStates[spell] = this:GetChecked()
        end)
        
        yOffset = yOffset - 25
    end
    
    scrollChild:SetHeight(math.abs(yOffset))
    
    self.configFrame = frame
    frame:Show()
end

-- Reload all nameplates (for config changes)
function Mardot:ReloadNameplates()
    for plate, dotFrame in pairs(self.frames) do
        dotFrame:Hide()
        self.frames[plate] = nil
    end
    
    -- They'll be recreated on next scan
end

-- Slash commands
SLASH_MARDOT1 = "/mardot"
SLASH_MARDOT2 = "/md"
SlashCmdList["MARDOT"] = function(msg)
    if msg == "toggle" then
        Mardot.config.enabled = not Mardot.config.enabled
        Mardot:Print("Mardot " .. (Mardot.config.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
    elseif msg == "config" or msg == "cfg" then
        Mardot:CreateConfigUI()
    elseif msg == "haste" then
        local currentHaste = Mardot:GetCurrentHaste()
        Mardot:Print("Current spell haste: |cff00ff00" .. string.format("%.1f%%", currentHaste) .. "|r")
    elseif msg == "debug" then
        Mardot:Print("Active DoTs tracked:")
        for key, info in pairs(Mardot.debuffs) do
            local remaining = info.duration - (GetTime() - info.applied)
            local dhInfo = ""
            if info.darkHarvestTicks and info.darkHarvestTicks > 0 then
                dhInfo = string.format(" [DH: %d ticks]", info.darkHarvestTicks)
            end
            Mardot:Print(string.format("  %s: %.1fs%s", key, remaining, dhInfo))
        end
    else
        Mardot:Print("Commands:")
        Mardot:Print("  /mardot toggle - Enable/disable addon")
        Mardot:Print("  /mardot config - Open configuration")
        Mardot:Print("  /mardot haste - Show current haste %")
        Mardot:Print("  /mardot debug - Show active DoTs")
    end
end

-- Helper print function
function Mardot:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6600Mardot:|r " .. msg)
end

-- Initialize on load
Mardot:Initialize()
