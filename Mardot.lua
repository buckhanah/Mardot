-- Mardot.lua
-- Addon to track DoT/Debuff durations in a movable window for Turtle WoW
-- Version: 3.1 - SuperWoW UNIT_CASTEVENT support with dynamic haste
-- Lua 5.0.2 compatible

Mardot = {}
Mardot.debuffs = {}
Mardot.targetDebuffs = {}
Mardot.playerBuffs = {}
Mardot.lastScan = 0
Mardot.mainFrame = nil
Mardot.hasSuperwow = false
Mardot.pendingCast = {}
Mardot.darkHarvest = {
    active = false,
    targetGuid = nil,
    targetName = nil,
    startTime = nil,
    spellID = nil,
}

-- Dark Harvest spell IDs
Mardot.darkHarvestSpellIds = {
    [52550] = true, -- Rank 1
    [52551] = true, -- Rank 2
    [52552] = true, -- Rank 3
}

-- Default configuration
Mardot.defaults = {
    enabled = true,
    iconSize = 32,
    updateInterval = 0.1,
    maxIcons = 8,
    iconSpacing = 4,
    locked = false,
    posX = nil,
    posY = nil,
}

-- Initialize config
Mardot.config = {}

-- Spell ID to name mapping for SuperWoW UNIT_CASTEVENT
Mardot.spellIdToName = {
    -- Warlock Curses
    [980] = "Curse of Agony",
    [1014] = "Curse of Agony",
    [6217] = "Curse of Agony",
    [11711] = "Curse of Agony",
    [11712] = "Curse of Agony",
    [11713] = "Curse of Agony",
    [27218] = "Curse of Agony",
    
    [17862] = "Curse of Shadows",
    [17937] = "Curse of Shadows",
    
    [704] = "Curse of Recklessness",
    [7658] = "Curse of Recklessness",
    [7659] = "Curse of Recklessness",
    [11717] = "Curse of Recklessness",
    [27226] = "Curse of Recklessness",
    
    [603] = "Curse of Doom",
    [30910] = "Curse of Doom",
    
    [702] = "Curse of Weakness",
    [1108] = "Curse of Weakness",
    [6205] = "Curse of Weakness",
    [7646] = "Curse of Weakness",
    [11707] = "Curse of Weakness",
    [11708] = "Curse of Weakness",
    [27224] = "Curse of Weakness",
    
    [1714] = "Curse of Tongues",
    [11719] = "Curse of Tongues",
    
    [1490] = "Curse of Elements",
    [11721] = "Curse of Elements",
    [11722] = "Curse of Elements",
    [27228] = "Curse of Elements",
    
    -- Corruption
    [172] = "Corruption",
    [6222] = "Corruption",
    [6223] = "Corruption",
    [7648] = "Corruption",
    [11671] = "Corruption",
    [11672] = "Corruption",
    [25311] = "Corruption",
    [27216] = "Corruption",
    
    -- Immolate
    [348] = "Immolate",
    [707] = "Immolate",
    [1094] = "Immolate",
    [2941] = "Immolate",
    [11665] = "Immolate",
    [11667] = "Immolate",
    [11668] = "Immolate",
    [25309] = "Immolate",
    [27215] = "Immolate",
    
    -- Siphon Life
    [18265] = "Siphon Life",
    [18879] = "Siphon Life",
    [18880] = "Siphon Life",
    [18881] = "Siphon Life",
    [27264] = "Siphon Life",
    [30911] = "Siphon Life",
    
    -- Paladin Judgements
    [20185] = "Judgement of Light",
    [20344] = "Judgement of Light",
    [20345] = "Judgement of Light",
    [20346] = "Judgement of Light",
    [27162] = "Judgement of Light",
    
    [20186] = "Judgement of Wisdom",
    [20354] = "Judgement of Wisdom",
    [20355] = "Judgement of Wisdom",
    [27163] = "Judgement of Wisdom",
    
    [20184] = "Judgement of Justice",
    
    [21183] = "Judgement of the Crusader",
    [20188] = "Judgement of the Crusader",
    [20300] = "Judgement of the Crusader",
    [20301] = "Judgement of the Crusader",
    [20302] = "Judgement of the Crusader",
    [20303] = "Judgement of the Crusader",
    [27159] = "Judgement of the Crusader",
}

-- Base debuff durations, icons, and priorities
Mardot.baseDebuffData = {
    -- Warlock Curses (Priority 1-7)
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
    ["Curse of Elements"] = { 
        duration = 300, 
        tickRate = 300, 
        icon = "Interface\\Icons\\Spell_Shadow_ChillTouch",
        color = {0.2, 0.4, 0.6},
        priority = 7,
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
    
    -- Paladin Judgements (Priority 60+)
    ["Judgement of Light"] = { 
        duration = 10, 
        tickRate = 10, 
        icon = "Interface\\Icons\\Spell_Holy_RighteousFury",
        color = {1.0, 0.9, 0.2},
        priority = 60,
        enabled = true,
    },
    ["Judgement of Wisdom"] = { 
        duration = 10, 
        tickRate = 10, 
        icon = "Interface\\Icons\\Spell_Holy_RighteousFury",
        color = {0.2, 0.6, 1.0},
        priority = 61,
        enabled = true,
    },
    ["Judgement of Justice"] = { 
        duration = 10, 
        tickRate = 10, 
        icon = "Interface\\Icons\\Spell_Holy_RighteousFury",
        color = {0.9, 0.5, 0.1},
        priority = 62,
        enabled = true,
    },
    ["Judgement of the Crusader"] = { 
        duration = 10, 
        tickRate = 10, 
        icon = "Interface\\Icons\\Spell_Holy_RighteousFury",
        color = {1.0, 0.2, 0.2},
        priority = 63,
        enabled = true,
    },
}

-- Paladin Seals (tracked as player buffs)
Mardot.paladinSeals = {
    ["Seal of Righteousness"] = {
        icon = "Interface\\Icons\\Ability_ThunderBolt",
        color = {1.0, 0.9, 0.2},
    },
    ["Seal of the Crusader"] = {
        icon = "Interface\\Icons\\Spell_Holy_HolySmite",
        color = {1.0, 0.2, 0.2},
    },
    ["Seal of Command"] = {
        icon = "Interface\\Icons\\Ability_Warrior_InnerRage",
        color = {1.0, 0.5, 0.0},
    },
    ["Seal of Light"] = {
        icon = "Interface\\Icons\\Spell_Holy_HealingAura",
        color = {1.0, 1.0, 0.5},
    },
    ["Seal of Wisdom"] = {
        icon = "Interface\\Icons\\Spell_Holy_RighteousnessAura",
        color = {0.3, 0.6, 1.0},
    },
    ["Seal of Justice"] = {
        icon = "Interface\\Icons\\Spell_Holy_SealOfWrath",
        color = {0.9, 0.7, 0.3},
    },
}

-- Initialize saved variables
function Mardot:InitializeSavedVars()
    if not MardotDB then
        MardotDB = {}
    end
    
    for k, v in pairs(self.defaults) do
        if MardotDB[k] == nil then
            MardotDB[k] = v
        end
    end
    
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
    
    -- Check for SuperWoW
    if GetWoWVersion then
        local major, minor, patch, client = GetWoWVersion()
        if client and client >= 12340 then
            self.hasSuperwow = true
            self:Print("SuperWoW detected! Using UNIT_CASTEVENT for accurate tracking")
        end
    end
    
    if not self.hasSuperwow then
        self:Print("v3.1 loaded! Using scan-based tracking")
    else
        self:Print("v3.1 loaded! Type /mardot for commands")
    end
    
    -- Create main display window
    self:CreateMainWindow()
    
    -- Create update frame
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame.elapsed = 0
    self.updateFrame:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + arg1
        if this.elapsed >= Mardot.config.updateInterval then
            Mardot:ScanTargetDebuffs()
            Mardot:UpdateDisplay()
            this.elapsed = 0
        end
    end)
    
    -- Register events
    self:RegisterEvents()
end

-- Register events
function Mardot:RegisterEvents()
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("VARIABLES_LOADED")
    self.eventFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
    self.eventFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
    self.eventFrame:RegisterEvent("SPELLCAST_INTERRUPTED")
    
    if self.hasSuperwow then
        self.eventFrame:RegisterEvent("UNIT_CASTEVENT")
    end
    
    self.eventFrame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "VARIABLES_LOADED" then
            Mardot:InitializeSavedVars()
            if Mardot.config.posX and Mardot.config.posY then
                Mardot.mainFrame:ClearAllPoints()
                Mardot.mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", Mardot.config.posX, Mardot.config.posY)
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            Mardot:ScanTargetDebuffs()
        elseif event == "SPELLCAST_CHANNEL_START" then
            Mardot:OnChannelStart()
        elseif event == "SPELLCAST_CHANNEL_STOP" or event == "SPELLCAST_INTERRUPTED" then
            Mardot:OnChannelStop()
        elseif event == "UNIT_CASTEVENT" then
            -- arg1 = casterGuid, arg2 = targetGuid, arg3 = event, arg4 = spellID, arg5 = castDuration
            Mardot:OnUnitCastEvent(arg1, arg2, arg3, arg4, arg5)
        elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
            Mardot:OnDebuffFaded(arg1)
        end
    end)
end

-- Track Dark Harvest channeling
function Mardot:OnChannelStart()
    local spell = CastingBarFrame.channeling
    if not spell then return end
    
    -- Check if it's Dark Harvest
    -- We need to scan tooltip to get spell ID or check spell name
    -- For now, check name
    if spell == "Dark Harvest" then
        local targetName = UnitExists("target") and UnitName("target")
        local _, targetGuid = UnitExists("target")
        
        if targetName and targetGuid then
            self.darkHarvest.active = true
            self.darkHarvest.targetGuid = targetGuid
            self.darkHarvest.targetName = targetName
            self.darkHarvest.startTime = GetTime()
            
            -- Mark all DoTs on this target with DH start time
            for key, debuff in pairs(self.debuffs) do
                if debuff.target == targetName then
                    debuff.dhStartTime = GetTime()
                    debuff.dhLastTick = GetTime()
                end
            end
            
            self:Print("Dark Harvest started on " .. targetName)
        end
    end
end

function Mardot:OnChannelStop()
    if self.darkHarvest.active then
        local targetName = self.darkHarvest.targetName
        
        -- Mark all DoTs on this target with DH end time
        for key, debuff in pairs(self.debuffs) do
            if debuff.target == targetName and debuff.dhStartTime then
                debuff.dhEndTime = GetTime()
            end
        end
        
        self:Print("Dark Harvest ended")
        
        self.darkHarvest.active = false
        self.darkHarvest.targetGuid = nil
        self.darkHarvest.targetName = nil
        self.darkHarvest.startTime = nil
    end
end

-- Handle UNIT_CASTEVENT for spell tracking (SuperWoW)
function Mardot:OnUnitCastEvent(casterGuid, targetGuid, eventType, spellID, castDuration)
    if eventType ~= "CAST" then return end
    
    local _, playerGuid = UnitExists("player")
    if casterGuid ~= playerGuid then return end
    
    -- Get spell name from ID
    local spellName = self.spellIdToName[spellID]
    if not spellName then return end
    
    -- Check if we're tracking this spell
    local baseData = self.baseDebuffData[spellName]
    if not baseData or not self.config.debuffStates[spellName] then return end
    
    -- Check if target is current target
    local _, targetPlayerGuid = UnitExists("target")
    if targetGuid ~= targetPlayerGuid then return end
    
    local targetName = UnitName("target")
    if not targetName then return end
    
    -- Get current haste for duration calculation
    local currentHaste = self:GetCurrentHaste()
    local duration = baseData.duration / (1 + currentHaste / 100)
    
    -- Store pending cast
    self.pendingCast = {
        spellID = spellID,
        spellName = spellName,
        targetGuid = targetGuid,
        targetName = targetName,
        castTime = GetTime(),
    }
    
    -- Add delay for latency/resist detection
    local _, _, ping = GetNetStats()
    local delay = 0.2
    if ping and ping > 0 and ping < 500 then
        delay = 0.05 + (ping / 1000)
    end
    
    -- Schedule debuff application
    Mardot:ScheduleDebuffApplication(spellName, targetName, GetTime(), duration, delay)
end

-- Schedule debuff application with latency compensation
function Mardot:ScheduleDebuffApplication(spellName, targetName, startTime, duration, delay)
    local key = targetName .. "-" .. spellName
    
    -- Cancel existing timer if any
    if self.scheduledDebuffs and self.scheduledDebuffs[key] then
        self.scheduledDebuffs[key] = nil
    end
    
    -- Create delayed application
    if not self.scheduledDebuffs then
        self.scheduledDebuffs = {}
    end
    
    self.scheduledDebuffs[key] = {
        spellName = spellName,
        targetName = targetName,
        startTime = startTime,
        duration = duration,
        applyTime = GetTime() + delay,
    }
end

-- Check scheduled debuff applications
function Mardot:CheckScheduledDebuffs()
    if not self.scheduledDebuffs then return end
    
    local currentTime = GetTime()
    for key, data in pairs(self.scheduledDebuffs) do
        if currentTime >= data.applyTime then
            -- Apply the debuff
            self:ApplyDebuff(data.spellName, data.targetName, data.startTime, data.duration)
            self.scheduledDebuffs[key] = nil
        end
    end
end

-- Apply debuff
function Mardot:ApplyDebuff(spellName, targetName, startTime, duration)
    -- Clear pending cast
    self.pendingCast = {}
    
    local key = targetName .. "-" .. spellName
    local baseData = self.baseDebuffData[spellName]
    
    if not self.debuffs[key] then
        self.debuffs[key] = {}
    end
    
    self.debuffs[key] = {
        spell = spellName,
        target = targetName,
        applied = startTime,
        duration = duration,
        baseDuration = baseData.duration,
        stacks = 1,
    }
    
    self:Print("Applied: " .. spellName .. " on " .. targetName .. " (" .. string.format("%.1f", duration) .. "s)")
end

-- Handle debuff fade events
function Mardot:OnDebuffFaded(message)
    -- Pattern: "(.+) fades from (.+)."
    local spellName, target = string.match(message, "(.+) fades from (.+)%.")
    
    if spellName and target then
        local targetName = UnitExists("target") and UnitName("target")
        if target == targetName then
            -- Check if we're tracking this spell
            if self.baseDebuffData[spellName] then
                local key = target .. "-" .. spellName
                if self.debuffs[key] then
                    self.debuffs[key] = nil
                    self:Print("Faded: " .. spellName .. " from " .. target)
                end
            end
            
            -- Rescan to be sure
            self:ScanTargetDebuffs()
        end
    end
end

-- Get current haste percentage (for dynamic duration calculation)
function Mardot:GetCurrentHaste()
    local totalHaste = 0
    
    -- Scan player buffs for haste effects
    for i = 1, 32 do
        local texture = UnitBuff("player", i)
        if not texture then break end
        
        -- Get buff name via tooltip
        MardotTooltip = MardotTooltip or CreateFrame("GameTooltip", "MardotTooltip", nil, "GameTooltipTemplate")
        MardotTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        MardotTooltip:ClearLines()
        MardotTooltip:SetUnitBuff("player", i)
        
        local buffName = MardotTooltipTextLeft1:GetText()
        
        -- Check for known haste buffs
        if buffName == "Bloodlust" or buffName == "Heroism" then
            totalHaste = totalHaste + 30
        elseif buffName == "Berserking" then
            local healthPercent = UnitHealth("player") / UnitHealthMax("player")
            local berserkingHaste = 10 + (1 - healthPercent) * 20
            totalHaste = totalHaste + berserkingHaste
        end
    end
    
    return totalHaste
end

-- Create main display window
function Mardot:CreateMainWindow()
    local frame = CreateFrame("Frame", "MardotMainFrame", UIParent)
    
    local iconSize = self.config.iconSize
    local spacing = self.config.iconSpacing
    local maxIcons = self.config.maxIcons
    
    frame:SetWidth(maxIcons * (iconSize + spacing) + 20)
    frame:SetHeight(iconSize + 30)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    -- Make it movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if not Mardot.config.locked then
            this:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local point, _, _, x, y = this:GetPoint()
        Mardot.config.posX = x
        Mardot.config.posY = y
    end)
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
    frame.title:SetText("Mardot - Target DoTs")
    frame.title:SetTextColor(1, 0.82, 0)
    
    -- Icon container
    frame.icons = {}
    for i = 1, maxIcons do
        local icon = CreateFrame("Frame", nil, frame)
        icon:SetWidth(iconSize)
        icon:SetHeight(iconSize)
        icon:SetPoint("LEFT", frame, "LEFT", 10 + (i-1) * (iconSize + spacing), -5)
        
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        icon.texture:SetAllPoints(icon)
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
        icon.border = icon:CreateTexture(nil, "BORDER")
        icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        icon.border:SetBlendMode("ADD")
        icon.border:SetAllPoints(icon)
        
        icon.text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon.text:SetPoint("CENTER", icon, "CENTER", 0, 0)
        
        icon.name = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        icon.name:SetPoint("BOTTOM", icon, "TOP", 0, 2)
        
        icon:Hide()
        frame.icons[i] = icon
    end
    
    self.mainFrame = frame
    
    -- Create Seal tracker frame for Paladins
    self:CreateSealFrame()
end

-- Create Seal display frame (under player character in 3D world)
function Mardot:CreateSealFrame()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "PALADIN" then return end
    
    local frame = CreateFrame("Frame", "MardotSealFrame", UIParent)
    
    local iconSize = 48
    frame:SetWidth(iconSize + 10)
    frame:SetHeight(iconSize + 10)
    -- Position in center-bottom of screen, below character feet
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    
    -- Icon
    frame.icon = CreateFrame("Frame", nil, frame)
    frame.icon:SetWidth(iconSize)
    frame.icon:SetHeight(iconSize)
    frame.icon:SetPoint("CENTER", frame, "CENTER", 0, 0)
    
    frame.icon.texture = frame.icon:CreateTexture(nil, "BACKGROUND")
    frame.icon.texture:SetAllPoints(frame.icon)
    frame.icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    frame.icon.border = frame.icon:CreateTexture(nil, "BORDER")
    frame.icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.icon.border:SetBlendMode("ADD")
    frame.icon.border:SetAllPoints(frame.icon)
    
    frame:Hide()
    self.sealFrame = frame
end

-- Scan target for debuffs (fallback method, still used for verification)
function Mardot:ScanTargetDebuffs()
    if not UnitExists("target") or UnitIsFriend("player", "target") then
        -- Clear debuffs for old target
        local targetName = self.lastTargetName
        if targetName then
            for key, info in pairs(self.debuffs) do
                if info.target == targetName then
                    self.debuffs[key] = nil
                end
            end
        end
        self.lastTargetName = nil
        return
    end
    
    local targetName = UnitName("target")
    self.lastTargetName = targetName
    local foundDebuffs = {}
    
    -- Scan debuffs on target
    for i = 1, 16 do
        local texture, stacks = UnitDebuff("target", i)
        if not texture then break end
        
        -- Get debuff name via tooltip
        MardotTooltip = MardotTooltip or CreateFrame("GameTooltip", "MardotTooltip", nil, "GameTooltipTemplate")
        MardotTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        MardotTooltip:ClearLines()
        MardotTooltip:SetUnitDebuff("target", i)
        
        local debuffName = MardotTooltipTextLeft1:GetText()
        
        if debuffName and self.baseDebuffData[debuffName] and self.config.debuffStates[debuffName] then
            local key = targetName .. "-" .. debuffName
            foundDebuffs[key] = true
            
            -- If not already tracked via UNIT_CASTEVENT, add it via scan
            if not self.debuffs[key] then
                local baseData = self.baseDebuffData[debuffName]
                self.debuffs[key] = {
                    applied = GetTime(),
                    duration = baseData.duration,
                    spell = debuffName,
                    target = targetName,
                    stacks = stacks or 1,
                    scanned = true,
                }
            else
                -- Update stacks
                self.debuffs[key].stacks = stacks or 1
            end
        end
    end
    
    -- Remove debuffs no longer on target
    for key, info in pairs(self.debuffs) do
        if info.target == targetName and not foundDebuffs[key] then
            self.debuffs[key] = nil
        end
    end
    
    -- Check scheduled debuffs
    self:CheckScheduledDebuffs()
    
    -- Scan for active seal (Paladin only)
    self:ScanPlayerSeal()
end

-- Scan player buffs for active Paladin seal
function Mardot:ScanPlayerSeal()
    if not self.sealFrame then return end
    
    local activeSeal = nil
    
    -- Scan player buffs
    for i = 1, 32 do
        local texture = UnitBuff("player", i)
        if not texture then break end
        
        -- Get buff name via tooltip
        MardotTooltip = MardotTooltip or CreateFrame("GameTooltip", "MardotTooltip", nil, "GameTooltipTemplate")
        MardotTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        MardotTooltip:ClearLines()
        MardotTooltip:SetUnitBuff("player", i)
        
        local buffName = MardotTooltipTextLeft1:GetText()
        
        if buffName and self.paladinSeals[buffName] then
            activeSeal = buffName
            break
        end
    end
    
    -- Update seal frame
    if activeSeal then
        local sealData = self.paladinSeals[activeSeal]
        self.sealFrame.icon.texture:SetTexture(sealData.icon)
        self.sealFrame.icon.border:SetVertexColor(unpack(sealData.color))
        self.sealFrame:Show()
    else
        self.sealFrame:Hide()
    end
end

-- Calculate time remaining with Dark Harvest acceleration
function Mardot:CalculateTimeRemaining(debuff)
    local currentTime = GetTime()
    local elapsed = currentTime - debuff.applied
    
    -- Calculate Dark Harvest reduction
    local dhReduction = 0
    if debuff.dhStartTime then
        local dhEndTime = debuff.dhEndTime or currentTime
        local dhDuration = dhEndTime - debuff.dhStartTime
        
        -- Dark Harvest causes DoTs to tick 30% faster
        -- This means the DoT consumes duration 30% faster
        dhReduction = dhDuration * 0.3
    end
    
    local remaining = debuff.duration - elapsed - dhReduction
    
    return remaining
end

-- Update display
function Mardot:UpdateDisplay()
    if not self.mainFrame then return end
    
    -- Collect active debuffs for current target
    local targetName = UnitExists("target") and UnitName("target") or nil
    local activeDebuffs = {}
    local currentTime = GetTime()
    
    for key, debuff in pairs(self.debuffs) do
        if debuff.target == targetName then
            local remaining = self:CalculateTimeRemaining(debuff)
            
            if remaining > 0 then
                local baseData = self.baseDebuffData[debuff.spell]
                table.insert(activeDebuffs, {
                    spell = debuff.spell,
                    remaining = remaining,
                    icon = baseData.icon,
                    color = baseData.color,
                    priority = baseData.priority,
                    stacks = debuff.stacks,
                    dhActive = debuff.dhStartTime and not debuff.dhEndTime, -- Is DH currently active?
                })
            else
                self.debuffs[key] = nil
            end
        end
    end
    
    -- Sort by priority
    table.sort(activeDebuffs, function(a, b) return a.priority < b.priority end)
    
    -- Update icons
    for i = 1, self.config.maxIcons do
        local icon = self.mainFrame.icons[i]
        local debuff = activeDebuffs[i]
        
        if debuff then
            icon.texture:SetTexture(debuff.icon)
            
            -- Change border color if Dark Harvest is active on this DoT
            if debuff.dhActive then
                icon.border:SetVertexColor(0.3, 1.0, 0.3) -- Bright green for DH active
            else
                icon.border:SetVertexColor(unpack(debuff.color))
            end
            
            -- Format time
            local timeText
            if debuff.remaining >= 60 then
                timeText = string.format("%.0fm", debuff.remaining / 60)
            elseif debuff.remaining >= 10 then
                timeText = string.format("%.0f", debuff.remaining)
            else
                timeText = string.format("%.1f", debuff.remaining)
            end
            
            icon.text:SetText(timeText)
            
            -- Color based on time remaining
            if debuff.remaining > 5 then
                icon.text:SetTextColor(0, 1, 0)
            elseif debuff.remaining > 3 then
                icon.text:SetTextColor(1, 1, 0)
            else
                icon.text:SetTextColor(1, 0, 0)
            end
            
            -- Show stacks if > 1
            if debuff.stacks and debuff.stacks > 1 then
                icon.name:SetText(debuff.stacks)
                icon.name:Show()
            else
                icon.name:Hide()
            end
            
            icon:Show()
        else
            icon:Hide()
        end
    end
    
    -- Show/hide frame based on active debuffs
    if table.getn(activeDebuffs) > 0 and self.config.enabled then
        self.mainFrame:Show()
    else
        self.mainFrame:Hide()
    end
end

-- Slash commands
SLASH_MARDOT1 = "/mardot"
SLASH_MARDOT2 = "/md"
SlashCmdList["MARDOT"] = function(msg)
    if msg == "toggle" then
        Mardot.config.enabled = not Mardot.config.enabled
        Mardot:Print("Mardot " .. (Mardot.config.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
        Mardot:UpdateDisplay()
    elseif msg == "lock" then
        Mardot.config.locked = not Mardot.config.locked
        Mardot:Print("Frame " .. (Mardot.config.locked and "|cffff0000locked|r" or "|cff00ff00unlocked|r"))
    elseif msg == "show" then
        Mardot.mainFrame:Show()
        Mardot:Print("Frame shown (drag to move when unlocked)")
    elseif msg == "hide" then
        Mardot.mainFrame:Hide()
    elseif msg == "reset" then
        Mardot.mainFrame:ClearAllPoints()
        Mardot.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        Mardot.config.posX = nil
        Mardot.config.posY = nil
        Mardot:Print("Frame position reset")
    elseif msg == "size" then
        local size = string.match(msg, "size%s+(%d+)")
        if size then
            size = tonumber(size)
            if size >= 16 and size <= 64 then
                Mardot.config.iconSize = size
                Mardot:Print("Icon size set to " .. size .. " (reload UI to apply)")
            else
                Mardot:Print("Size must be between 16 and 64")
            end
        else
            Mardot:Print("Current icon size: " .. Mardot.config.iconSize)
            Mardot:Print("Usage: /mardot size <16-64>")
        end
    elseif msg == "reload" then
        Mardot.mainFrame:Hide()
        Mardot.mainFrame = nil
        Mardot:CreateMainWindow()
        Mardot:Print("Frame reloaded with new settings")
    elseif msg == "debug" then
        Mardot:Print("Active DoTs tracked:")
        local count = 0
        for key, info in pairs(Mardot.debuffs) do
            count = count + 1
            local remaining = info.duration - (GetTime() - info.applied)
            Mardot:Print(string.format("  %s: %.1fs", key, remaining))
        end
        if count == 0 then
            Mardot:Print("  None")
        end
        Mardot:Print("Target: " .. (UnitExists("target") and UnitName("target") or "None"))
        Mardot:Print("Lua version: " .. (_VERSION or "Unknown"))
    elseif string.sub(msg, 1, 4) == "test" then
        local spell = string.match(msg, "test%s+(.+)")
        if spell and Mardot.baseDebuffData[spell] then
            local targetName = UnitExists("target") and UnitName("target") or "TestTarget"
            local key = targetName.."-"..spell
            local baseData = Mardot.baseDebuffData[spell]
            Mardot.debuffs[key] = {
                applied = GetTime(),
                duration = baseData.duration,
                spell = spell,
                target = targetName,
                stacks = 1,
            }
            Mardot:Print("Test DoT added: " .. spell .. " on " .. targetName)
            Mardot:UpdateDisplay()
        else
            Mardot:Print("Usage: /mardot test SpellName")
            Mardot:Print("Example: /mardot test Corruption")
        end
    else
        Mardot:Print("Commands:")
        Mardot:Print("  /mardot toggle - Enable/disable addon")
        Mardot:Print("  /mardot lock - Lock/unlock frame")
        Mardot:Print("  /mardot show - Show frame")
        Mardot:Print("  /mardot reset - Reset position")
        Mardot:Print("  /mardot size <16-64> - Set icon size")
        Mardot:Print("  /mardot reload - Reload frame")
        Mardot:Print("  /mardot debug - Show debug info")
        Mardot:Print("  /mardot test <spell> - Test DoT")
    end
end

-- Helper print function
function Mardot:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6600Mardot:|r " .. msg)
end

-- Initialize on load
Mardot:Initialize()
