--[[
    QUI Group Frames - Visual Designer
    Interactive preview-based editor for group frame settings.
    Reads/writes the same DB paths as the traditional Group Frames tab.
]]

local ADDON_NAME, ns = ...
local QUI = QUI
local GUI = QUI.GUI
local C = GUI.Colors
local Shared = ns.QUI_Options
local QUICore = ns.Addon

-- Local references
local PADDING = Shared.PADDING
local CreateScrollableContent = Shared.CreateScrollableContent
local GetDB = Shared.GetDB
local GetTextureList = Shared.GetTextureList
local GetFontList = Shared.GetFontList

-- Constants
local FORM_ROW = 32
local DROP_ROW = 52
local SLIDER_HEIGHT = 65
local PAD = 10
local PREVIEW_SCALE = 2

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------
local function GetGFDB()
    local db = GetDB()
    return db and db.quiGroupFrames
end

local function RefreshGF()
    if _G.QUI_RefreshGroupFrames then
        _G.QUI_RefreshGroupFrames()
    end
end

---------------------------------------------------------------------------
-- ELEMENT DEFINITIONS
---------------------------------------------------------------------------
-- Visual elements shown on Party/Raid designer sub-tabs (preview + widget bar)
local VISUAL_ELEMENT_KEYS = {
    "frame", "health", "power", "name", "healthText",
    "buffs", "debuffs", "role", "indicators",
    "healer", "defensive", "auraIndicators", "privateAuras", "absorbs",
}

-- Configuration sections shown on the Settings sub-tab
local CONFIG_ELEMENT_KEYS = {
    "general", "layout", "dimensions", "clickCast", "misc",
}

local ELEMENT_LABELS = {
    frame = "Frame",
    health = "Health",
    power = "Power",
    name = "Name",
    healthText = "HP Text",
    buffs = "Buffs",
    debuffs = "Debuffs",
    role = "Role",
    indicators = "Indicators",
    healer = "Healer",
    defensive = "Defensive",
    auraIndicators = "Aura Ind.",
    privateAuras = "Priv. Auras",
    absorbs = "Absorbs",
    general = "General",
    layout = "Layout",
    dimensions = "Dimensions",
    clickCast = "Click-Cast",
    misc = "Misc",
}

---------------------------------------------------------------------------
-- ANCHOR MAP for text placement in preview
---------------------------------------------------------------------------
local ANCHOR_MAP = {
    LEFT   = { leftPoint = "LEFT",   rightPoint = "RIGHT",  justify = "LEFT",   justifyV = "MIDDLE" },
    RIGHT  = { leftPoint = "LEFT",   rightPoint = "RIGHT",  justify = "RIGHT",  justifyV = "MIDDLE" },
    CENTER = { leftPoint = "LEFT",   rightPoint = "RIGHT",  justify = "CENTER", justifyV = "MIDDLE" },
    TOP    = { leftPoint = "TOPLEFT", rightPoint = "TOPRIGHT", justify = "CENTER", justifyV = "TOP" },
    BOTTOM = { leftPoint = "BOTTOMLEFT", rightPoint = "BOTTOMRIGHT", justify = "CENTER", justifyV = "BOTTOM" },
    TOPLEFT     = { leftPoint = "TOPLEFT",    rightPoint = "TOPRIGHT",    justify = "LEFT",   justifyV = "TOP" },
    TOPRIGHT    = { leftPoint = "TOPLEFT",    rightPoint = "TOPRIGHT",    justify = "RIGHT",  justifyV = "TOP" },
    BOTTOMLEFT  = { leftPoint = "BOTTOMLEFT", rightPoint = "BOTTOMRIGHT", justify = "LEFT",   justifyV = "BOTTOM" },
    BOTTOMRIGHT = { leftPoint = "BOTTOMLEFT", rightPoint = "BOTTOMRIGHT", justify = "RIGHT",  justifyV = "BOTTOM" },
}

---------------------------------------------------------------------------
-- DROPDOWN OPTIONS for settings panels
---------------------------------------------------------------------------
local AURA_GROW_OPTIONS = {
    { value = "LEFT", text = "Left" },
    { value = "RIGHT", text = "Right" },
    { value = "UP", text = "Up" },
    { value = "DOWN", text = "Down" },
}

local HEALTH_DISPLAY_OPTIONS = {
    { value = "percent", text = "Percentage" },
    { value = "absolute", text = "Absolute" },
    { value = "both", text = "Both" },
    { value = "deficit", text = "Deficit" },
}

local NINE_POINT_OPTIONS = {
    { value = "TOPLEFT", text = "Top Left" },
    { value = "TOP", text = "Top" },
    { value = "TOPRIGHT", text = "Top Right" },
    { value = "LEFT", text = "Left" },
    { value = "CENTER", text = "Center" },
    { value = "RIGHT", text = "Right" },
    { value = "BOTTOMLEFT", text = "Bottom Left" },
    { value = "BOTTOM", text = "Bottom" },
    { value = "BOTTOMRIGHT", text = "Bottom Right" },
}

local FIVE_POINT_OPTIONS = {
    { value = "LEFT", text = "Left" },
    { value = "CENTER", text = "Center" },
    { value = "RIGHT", text = "Right" },
    { value = "TOP", text = "Top" },
    { value = "BOTTOM", text = "Bottom" },
}

---------------------------------------------------------------------------
-- FAKE DATA for preview
---------------------------------------------------------------------------
local FAKE_BUFF_ICONS = { 136034, 135940, 136081 }
local FAKE_DEBUFF_ICONS = { 136207, 136130 }
local FAKE_CLASS = "PALADIN"
local FAKE_NAME = "Healena"
local FAKE_HP_PCT = 65

---------------------------------------------------------------------------
-- PREVIEW FRAME BUILDER
---------------------------------------------------------------------------
local function CreateDesignerPreview(container, previewType, childRefs)
    local gfdb = GetGFDB()
    if not gfdb then return nil end

    local db = gfdb
    local general = db.general or {}
    local dims = db.dimensions or {}

    -- Determine base dimensions from preview type
    local baseW, baseH
    if previewType == "raid" then
        baseW = dims.mediumRaidWidth or 160
        baseH = dims.mediumRaidHeight or 30
    else
        baseW = dims.partyWidth or 200
        baseH = dims.partyHeight or 40
    end

    local w, h = baseW * PREVIEW_SCALE, baseH * PREVIEW_SCALE
    local fontPath = GUI.FONT_PATH or "Fonts\\FRIZQT__.TTF"
    local fontOutline = general.fontOutline or "OUTLINE"
    local classToken = FAKE_CLASS
    local healthPct = FAKE_HP_PCT

    -- Outer wrapper to center the preview
    local wrapper = CreateFrame("Frame", nil, container)
    wrapper:SetHeight(h + 20)
    wrapper:SetPoint("TOPLEFT", 0, 0)
    wrapper:SetPoint("RIGHT", container, "RIGHT", 0, 0)

    -- Main preview frame
    local frame = CreateFrame("Frame", nil, wrapper, "BackdropTemplate")
    frame:SetSize(w, h)
    frame:SetPoint("CENTER", wrapper, "CENTER", 0, 0)
    local px = QUICore.GetPixelSize and QUICore:GetPixelSize(frame) or 1
    local borderSize = (general.borderSize or 1) * px
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = borderSize,
    })

    -- Background color
    local bgR, bgG, bgB, bgA = 0.08, 0.08, 0.08, 0.9
    if general.darkMode and general.darkModeBgColor then
        local c = general.darkModeBgColor
        bgR, bgG, bgB = c[1] or c.r or bgR, c[2] or c.g or bgG, c[3] or c.b or bgB
        bgA = general.darkModeBgOpacity or 1
    elseif general.defaultBgColor then
        local c = general.defaultBgColor
        bgR, bgG, bgB = c[1] or bgR, c[2] or bgG, c[3] or bgB
        bgA = general.defaultBgOpacity or 1
    end
    frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    frame:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    childRefs.frame = frame

    -- Health bar
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetPoint("TOPLEFT", borderSize, -borderSize)
    healthBar:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)

    local LSM = LibStub("LibSharedMedia-3.0", true)
    local textureName = general.texture or "Quazii v5"
    local texturePath = LSM and LSM:Fetch("statusbar", textureName) or "Interface\\TargetingFrame\\UI-StatusBar"
    healthBar:SetStatusBarTexture(texturePath)
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(healthPct)

    -- Health bar color
    if general.darkMode then
        local dmc = general.darkModeHealthColor
        if dmc then
            healthBar:SetStatusBarColor(dmc[1] or dmc.r or 0.2, dmc[2] or dmc.g or 0.2, dmc[3] or dmc.b or 0.2, general.darkModeHealthOpacity or 1)
        else
            healthBar:SetStatusBarColor(0.2, 0.2, 0.2, 1)
        end
    elseif general.useClassColor then
        local cc = RAID_CLASS_COLORS[classToken]
        if cc then
            healthBar:SetStatusBarColor(cc.r, cc.g, cc.b, general.defaultHealthOpacity or 1)
        end
    else
        healthBar:SetStatusBarColor(0.2, 0.8, 0.2, general.defaultHealthOpacity or 1)
    end
    childRefs.healthBar = healthBar

    -- Power bar
    local powerDB = db.power or {}
    if powerDB.showPowerBar ~= false then
        local powerH = (powerDB.powerBarHeight or 4) * PREVIEW_SCALE
        local powerBar = CreateFrame("StatusBar", nil, frame)
        powerBar:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
        powerBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
        powerBar:SetHeight(powerH)
        powerBar:SetStatusBarTexture(texturePath)
        powerBar:SetMinMaxValues(0, 100)
        powerBar:SetValue(80)
        if powerDB.powerBarUsePowerColor then
            powerBar:SetStatusBarColor(0.2, 0.4, 0.8, 1)
        else
            local c = powerDB.powerBarColor or {0.2, 0.4, 0.8, 1}
            powerBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
        end
        childRefs.powerBar = powerBar

        -- Adjust health bar bottom to sit above power bar
        healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize + powerH)
    else
        childRefs.powerBar = nil
    end

    -- Text frame (above health bar for overlaid text)
    local textFrame = CreateFrame("Frame", nil, frame)
    textFrame:SetAllPoints(healthBar)
    textFrame:SetFrameLevel(healthBar:GetFrameLevel() + 2)

    -- Name text
    local nameDB = db.name or {}
    if nameDB.showName ~= false then
        local nameAnchor = nameDB.nameAnchor or "LEFT"
        local nameAnchorInfo = ANCHOR_MAP[nameAnchor] or ANCHOR_MAP.LEFT
        local nameOffsetX = (nameDB.nameOffsetX or 4) * PREVIEW_SCALE
        local nameOffsetY = (nameDB.nameOffsetY or 0) * PREVIEW_SCALE
        local namePadX = math.abs(nameOffsetX)
        local nameText = textFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(fontPath, (nameDB.nameFontSize or 12) * PREVIEW_SCALE, fontOutline)
        nameText:SetPoint(nameAnchorInfo.leftPoint, textFrame, nameAnchorInfo.leftPoint, namePadX, nameOffsetY)
        nameText:SetPoint(nameAnchorInfo.rightPoint, textFrame, nameAnchorInfo.rightPoint, -namePadX, nameOffsetY)
        nameText:SetJustifyH(nameAnchorInfo.justify)
        nameText:SetJustifyV(nameAnchorInfo.justifyV)
        nameText:SetWordWrap(false)

        local displayName = FAKE_NAME
        local maxLen = nameDB.maxNameLength or 10
        if maxLen > 0 and #displayName > maxLen then
            displayName = displayName:sub(1, maxLen)
        end
        nameText:SetText(displayName)

        if nameDB.nameTextUseClassColor then
            local cc = RAID_CLASS_COLORS[classToken]
            if cc then
                nameText:SetTextColor(cc.r, cc.g, cc.b, 1)
            else
                nameText:SetTextColor(1, 1, 1, 1)
            end
        elseif nameDB.nameTextColor then
            local tc = nameDB.nameTextColor
            nameText:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
        else
            nameText:SetTextColor(1, 1, 1, 1)
        end
        childRefs.nameText = nameText
    else
        childRefs.nameText = nil
    end

    -- Health text
    local healthDB = db.health or {}
    if healthDB.showHealthText ~= false then
        local healthAnchor = healthDB.healthAnchor or "RIGHT"
        local healthAnchorInfo = ANCHOR_MAP[healthAnchor] or ANCHOR_MAP.RIGHT
        local healthOffsetX = (healthDB.healthOffsetX or -4) * PREVIEW_SCALE
        local healthOffsetY = (healthDB.healthOffsetY or 0) * PREVIEW_SCALE
        local healthPadX = math.abs(healthOffsetX)
        local healthText = textFrame:CreateFontString(nil, "OVERLAY")
        healthText:SetFont(fontPath, (healthDB.healthFontSize or 12) * PREVIEW_SCALE, fontOutline)
        healthText:SetPoint(healthAnchorInfo.leftPoint, textFrame, healthAnchorInfo.leftPoint, healthPadX, healthOffsetY)
        healthText:SetPoint(healthAnchorInfo.rightPoint, textFrame, healthAnchorInfo.rightPoint, -healthPadX, healthOffsetY)
        healthText:SetJustifyH(healthAnchorInfo.justify)
        healthText:SetJustifyV(healthAnchorInfo.justifyV)
        healthText:SetWordWrap(false)

        local style = healthDB.healthDisplayStyle or "percent"
        local fakeHP = healthPct * 1000
        if style == "percent" then
            healthText:SetText(healthPct .. "%")
        elseif style == "absolute" then
            healthText:SetText(string.format("%.0fK", fakeHP / 1000))
        elseif style == "both" then
            healthText:SetText(string.format("%.0fK", fakeHP / 1000) .. " | " .. healthPct .. "%")
        elseif style == "deficit" then
            local deficit = 100000 - fakeHP
            if deficit > 0 then
                healthText:SetText("-" .. string.format("%.0fK", deficit / 1000))
            else
                healthText:SetText("")
            end
        else
            healthText:SetText(healthPct .. "%")
        end

        if healthDB.healthTextColor then
            local tc = healthDB.healthTextColor
            healthText:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
        else
            healthText:SetTextColor(1, 1, 1, 1)
        end
        childRefs.healthText = healthText
    else
        childRefs.healthText = nil
    end

    -- Role icon
    local indDB = db.indicators or {}
    local roleAnchor = indDB.roleIconAnchor or "TOPLEFT"
    if indDB.showRoleIcon ~= false then
        local roleSize = (indDB.roleIconSize or 12) * PREVIEW_SCALE
        local roleIcon = textFrame:CreateTexture(nil, "OVERLAY")
        roleIcon:SetSize(roleSize, roleSize)
        roleIcon:SetPoint(roleAnchor, textFrame, roleAnchor, 2, -2)
        roleIcon:SetAtlas("roleicon-tiny-healer")
        childRefs.roleIcon = roleIcon
    else
        childRefs.roleIcon = nil
    end

    -- Buff icons
    local auraDB = db.auras or {}
    if auraDB.showBuffs then
        local buffSize = (auraDB.buffIconSize or 14) * PREVIEW_SCALE
        local buffAnchor = auraDB.buffAnchor or "TOPLEFT"
        local buffGrow = auraDB.buffGrowDirection or "RIGHT"
        local buffSpacing = (auraDB.buffSpacing or 2) * PREVIEW_SCALE
        local maxBuffs = auraDB.maxBuffs or 3

        local buffContainer = CreateFrame("Frame", nil, frame)
        buffContainer:SetSize(1, buffSize)
        local offX = (auraDB.buffOffsetX or 2) * PREVIEW_SCALE
        local offY = (auraDB.buffOffsetY or 16) * PREVIEW_SCALE
        buffContainer:SetPoint(buffAnchor, frame, buffAnchor, offX, offY)

        for i = 1, math.min(maxBuffs, #FAKE_BUFF_ICONS) do
            local icon = buffContainer:CreateTexture(nil, "OVERLAY")
            icon:SetSize(buffSize, buffSize)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon:SetTexture(FAKE_BUFF_ICONS[i])
            if i == 1 then
                icon:SetPoint("LEFT", buffContainer, "LEFT", 0, 0)
            else
                local growDir = buffGrow == "LEFT" and "RIGHT" or "LEFT"
                local prevIcon = buffContainer["icon" .. (i - 1)]
                if prevIcon then
                    icon:SetPoint(growDir, prevIcon, buffGrow == "LEFT" and "LEFT" or "RIGHT", buffGrow == "LEFT" and -buffSpacing or buffSpacing, 0)
                else
                    icon:SetPoint("LEFT", buffContainer, "LEFT", (i - 1) * (buffSize + buffSpacing), 0)
                end
            end
            buffContainer["icon" .. i] = icon
        end
        childRefs.buffContainer = buffContainer
    else
        childRefs.buffContainer = nil
    end

    -- Debuff icons
    if auraDB.showDebuffs ~= false then
        local debuffSize = (auraDB.debuffIconSize or 16) * PREVIEW_SCALE
        local debuffAnchor = auraDB.debuffAnchor or "BOTTOMRIGHT"
        local debuffSpacing = (auraDB.debuffSpacing or 2) * PREVIEW_SCALE
        local maxDebuffs = auraDB.maxDebuffs or 3

        local debuffContainer = CreateFrame("Frame", nil, frame)
        debuffContainer:SetSize(1, debuffSize)
        local offX = (auraDB.debuffOffsetX or -2) * PREVIEW_SCALE
        local offY = (auraDB.debuffOffsetY or -18) * PREVIEW_SCALE
        debuffContainer:SetPoint(debuffAnchor, frame, debuffAnchor, offX, offY)

        for i = 1, math.min(maxDebuffs, #FAKE_DEBUFF_ICONS) do
            local icon = debuffContainer:CreateTexture(nil, "OVERLAY")
            icon:SetSize(debuffSize, debuffSize)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon:SetTexture(FAKE_DEBUFF_ICONS[i])
            if i == 1 then
                icon:SetPoint("RIGHT", debuffContainer, "RIGHT", 0, 0)
            else
                icon:SetPoint("RIGHT", debuffContainer, "RIGHT", -(i - 1) * (debuffSize + debuffSpacing), 0)
            end
        end
        childRefs.debuffContainer = debuffContainer
    else
        childRefs.debuffContainer = nil
    end

    -- Absorb overlay (semi-transparent bar on health)
    local absorbDB = db.absorbs or {}
    if absorbDB.enabled ~= false then
        local absorbOverlay = healthBar:CreateTexture(nil, "OVERLAY")
        absorbOverlay:SetTexture(texturePath)
        absorbOverlay:SetPoint("TOPRIGHT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        absorbOverlay:SetWidth(w * 0.12)
        local ac = absorbDB.color or {1, 1, 1, 1}
        absorbOverlay:SetVertexColor(ac[1], ac[2], ac[3], absorbDB.opacity or 0.3)
        childRefs.absorbOverlay = absorbOverlay
    else
        childRefs.absorbOverlay = nil
    end

    -- Heal prediction overlay
    local healDB = db.healPrediction or {}
    if healDB.enabled ~= false then
        local healOverlay = healthBar:CreateTexture(nil, "OVERLAY")
        healOverlay:SetTexture(texturePath)
        healOverlay:SetPoint("TOPLEFT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        healOverlay:SetPoint("BOTTOMLEFT", healthBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        healOverlay:SetWidth(w * 0.08)
        local hc = healDB.color or {0.2, 1, 0.2}
        healOverlay:SetVertexColor(hc[1], hc[2], hc[3], healDB.opacity or 0.5)
        childRefs.healOverlay = healOverlay
    else
        childRefs.healOverlay = nil
    end

    return wrapper
end

---------------------------------------------------------------------------
-- HIT OVERLAY FACTORY
---------------------------------------------------------------------------
local function CreateHitOverlay(parent, previewFrame, elementKey, anchorFrame, mode, width, height, anchorPoint, anchorRelPoint, offX, offY)
    local overlay = CreateFrame("Button", nil, parent)
    overlay:SetFrameLevel(previewFrame:GetFrameLevel() + 10)
    overlay.elementKey = elementKey

    if mode == "fill" then
        overlay:SetAllPoints(anchorFrame)
    elseif mode == "fixed" then
        overlay:SetSize(width or 30, height or 20)
        overlay:SetPoint(anchorPoint or "CENTER", anchorFrame, anchorRelPoint or anchorPoint or "CENTER", offX or 0, offY or 0)
    end

    -- Mint highlight border
    local px = QUICore.GetPixelSize and QUICore:GetPixelSize(overlay) or 1
    local highlight = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    highlight:SetAllPoints()
    highlight:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = px * 2,
    })
    highlight:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    highlight:Hide()
    overlay.highlight = highlight

    return overlay
end

---------------------------------------------------------------------------
-- ELEMENT SETTINGS BUILDERS
---------------------------------------------------------------------------

-- FRAME settings
local function BuildFrameSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Frame"})

    local general = gfdb.general
    if not general then gfdb.general = {} general = gfdb.general end

    local borderSlider = GUI:CreateFormSlider(content, "Border Size", 0, 3, 1, "borderSize", general, onChange)
    borderSlider:SetPoint("TOPLEFT", PAD, y)
    borderSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local texDrop = GUI:CreateFormDropdown(content, "Texture", GetTextureList(), "texture", general, onChange)
    texDrop:SetPoint("TOPLEFT", PAD, y)
    texDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local darkCheck = GUI:CreateFormCheckbox(content, "Dark Mode", "darkMode", general, onChange)
    darkCheck:SetPoint("TOPLEFT", PAD, y)
    darkCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local classColorCheck = GUI:CreateFormCheckbox(content, "Use Class Color", "useClassColor", general, onChange)
    classColorCheck:SetPoint("TOPLEFT", PAD, y)
    classColorCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local bgColor = GUI:CreateFormColorPicker(content, "Background Color", "defaultBgColor", general, onChange)
    bgColor:SetPoint("TOPLEFT", PAD, y)
    bgColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local bgOpacity = GUI:CreateFormSlider(content, "Background Opacity", 0, 1, 0.05, "defaultBgOpacity", general, onChange)
    bgOpacity:SetPoint("TOPLEFT", PAD, y)
    bgOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    -- Dark mode colors section
    local dmHeader = GUI:CreateSectionHeader(content, "Dark Mode Colors")
    dmHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - dmHeader.gap

    local dmHealthColor = GUI:CreateFormColorPicker(content, "Health Color", "darkModeHealthColor", general, onChange)
    dmHealthColor:SetPoint("TOPLEFT", PAD, y)
    dmHealthColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local dmHealthOpacity = GUI:CreateFormSlider(content, "Health Opacity", 0, 1, 0.05, "darkModeHealthOpacity", general, onChange)
    dmHealthOpacity:SetPoint("TOPLEFT", PAD, y)
    dmHealthOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local dmBgColor = GUI:CreateFormColorPicker(content, "Dark Mode BG Color", "darkModeBgColor", general, onChange)
    dmBgColor:SetPoint("TOPLEFT", PAD, y)
    dmBgColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local dmBgOpacity = GUI:CreateFormSlider(content, "Dark Mode BG Opacity", 0, 1, 0.05, "darkModeBgOpacity", general, onChange)
    dmBgOpacity:SetPoint("TOPLEFT", PAD, y)
    dmBgOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

-- HEALTH settings
local function BuildHealthSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Health"})

    local general = gfdb.general or {}

    local texDrop = GUI:CreateFormDropdown(content, "Health Texture", GetTextureList(), "texture", general, onChange)
    texDrop:SetPoint("TOPLEFT", PAD, y)
    texDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local healthOpacity = GUI:CreateFormSlider(content, "Health Opacity", 0, 1, 0.05, "defaultHealthOpacity", general, onChange)
    healthOpacity:SetPoint("TOPLEFT", PAD, y)
    healthOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

-- POWER settings
local function BuildPowerSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Power"})

    local power = gfdb.power
    if not power then gfdb.power = {} power = gfdb.power end

    local showCheck = GUI:CreateFormCheckbox(content, "Show Power Bar", "showPowerBar", power, onChange)
    showCheck:SetPoint("TOPLEFT", PAD, y)
    showCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local heightSlider = GUI:CreateFormSlider(content, "Height", 1, 12, 1, "powerBarHeight", power, onChange)
    heightSlider:SetPoint("TOPLEFT", PAD, y)
    heightSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local usePowerColor = GUI:CreateFormCheckbox(content, "Use Power Type Color", "powerBarUsePowerColor", power, onChange)
    usePowerColor:SetPoint("TOPLEFT", PAD, y)
    usePowerColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local barColor = GUI:CreateFormColorPicker(content, "Custom Color", "powerBarColor", power, onChange)
    barColor:SetPoint("TOPLEFT", PAD, y)
    barColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    content:SetHeight(math.abs(y) + 10)
end

-- NAME settings
local function BuildNameSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Name"})

    local name = gfdb.name
    if not name then gfdb.name = {} name = gfdb.name end

    local showCheck = GUI:CreateFormCheckbox(content, "Show Name", "showName", name, onChange)
    showCheck:SetPoint("TOPLEFT", PAD, y)
    showCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local fontSize = GUI:CreateFormSlider(content, "Font Size", 6, 24, 1, "nameFontSize", name, onChange)
    fontSize:SetPoint("TOPLEFT", PAD, y)
    fontSize:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local anchor = GUI:CreateFormDropdown(content, "Anchor", FIVE_POINT_OPTIONS, "nameAnchor", name, onChange)
    anchor:SetPoint("TOPLEFT", PAD, y)
    anchor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local maxLen = GUI:CreateFormSlider(content, "Max Name Length (0 = unlimited)", 0, 20, 1, "maxNameLength", name, onChange)
    maxLen:SetPoint("TOPLEFT", PAD, y)
    maxLen:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offsetX = GUI:CreateFormSlider(content, "X Offset", -20, 20, 1, "nameOffsetX", name, onChange)
    offsetX:SetPoint("TOPLEFT", PAD, y)
    offsetX:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offsetY = GUI:CreateFormSlider(content, "Y Offset", -20, 20, 1, "nameOffsetY", name, onChange)
    offsetY:SetPoint("TOPLEFT", PAD, y)
    offsetY:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local classColor = GUI:CreateFormCheckbox(content, "Use Class Color", "nameTextUseClassColor", name, onChange)
    classColor:SetPoint("TOPLEFT", PAD, y)
    classColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local textColor = GUI:CreateFormColorPicker(content, "Text Color", "nameTextColor", name, onChange)
    textColor:SetPoint("TOPLEFT", PAD, y)
    textColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    content:SetHeight(math.abs(y) + 10)
end

-- HEALTH TEXT settings
local function BuildHealthTextSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "HP Text"})

    local health = gfdb.health
    if not health then gfdb.health = {} health = gfdb.health end

    local showCheck = GUI:CreateFormCheckbox(content, "Show Health Text", "showHealthText", health, onChange)
    showCheck:SetPoint("TOPLEFT", PAD, y)
    showCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local styleDrop = GUI:CreateFormDropdown(content, "Display Style", HEALTH_DISPLAY_OPTIONS, "healthDisplayStyle", health, onChange)
    styleDrop:SetPoint("TOPLEFT", PAD, y)
    styleDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local fontSize = GUI:CreateFormSlider(content, "Font Size", 6, 24, 1, "healthFontSize", health, onChange)
    fontSize:SetPoint("TOPLEFT", PAD, y)
    fontSize:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local anchor = GUI:CreateFormDropdown(content, "Anchor", FIVE_POINT_OPTIONS, "healthAnchor", health, onChange)
    anchor:SetPoint("TOPLEFT", PAD, y)
    anchor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local offsetX = GUI:CreateFormSlider(content, "X Offset", -20, 20, 1, "healthOffsetX", health, onChange)
    offsetX:SetPoint("TOPLEFT", PAD, y)
    offsetX:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offsetY = GUI:CreateFormSlider(content, "Y Offset", -20, 20, 1, "healthOffsetY", health, onChange)
    offsetY:SetPoint("TOPLEFT", PAD, y)
    offsetY:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local textColor = GUI:CreateFormColorPicker(content, "Text Color", "healthTextColor", health, onChange)
    textColor:SetPoint("TOPLEFT", PAD, y)
    textColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    content:SetHeight(math.abs(y) + 10)
end

-- BUFFS settings
local function BuildBuffsSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Buffs"})

    local auras = gfdb.auras
    if not auras then gfdb.auras = {} auras = gfdb.auras end

    local showCheck = GUI:CreateFormCheckbox(content, "Show Buffs", "showBuffs", auras, onChange)
    showCheck:SetPoint("TOPLEFT", PAD, y)
    showCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local maxCount = GUI:CreateFormSlider(content, "Max Buffs", 0, 8, 1, "maxBuffs", auras, onChange)
    maxCount:SetPoint("TOPLEFT", PAD, y)
    maxCount:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local iconSize = GUI:CreateFormSlider(content, "Icon Size", 8, 32, 1, "buffIconSize", auras, onChange)
    iconSize:SetPoint("TOPLEFT", PAD, y)
    iconSize:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local anchorDrop = GUI:CreateFormDropdown(content, "Anchor", NINE_POINT_OPTIONS, "buffAnchor", auras, onChange)
    anchorDrop:SetPoint("TOPLEFT", PAD, y)
    anchorDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local growDrop = GUI:CreateFormDropdown(content, "Grow Direction", AURA_GROW_OPTIONS, "buffGrowDirection", auras, onChange)
    growDrop:SetPoint("TOPLEFT", PAD, y)
    growDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local spacing = GUI:CreateFormSlider(content, "Spacing", 0, 8, 1, "buffSpacing", auras, onChange)
    spacing:SetPoint("TOPLEFT", PAD, y)
    spacing:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offX = GUI:CreateFormSlider(content, "X Offset", -30, 30, 1, "buffOffsetX", auras, onChange)
    offX:SetPoint("TOPLEFT", PAD, y)
    offX:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offY = GUI:CreateFormSlider(content, "Y Offset", -30, 30, 1, "buffOffsetY", auras, onChange)
    offY:SetPoint("TOPLEFT", PAD, y)
    offY:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

-- DEBUFFS settings
local function BuildDebuffsSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Debuffs"})

    local auras = gfdb.auras
    if not auras then gfdb.auras = {} auras = gfdb.auras end

    local showCheck = GUI:CreateFormCheckbox(content, "Show Debuffs", "showDebuffs", auras, onChange)
    showCheck:SetPoint("TOPLEFT", PAD, y)
    showCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local maxCount = GUI:CreateFormSlider(content, "Max Debuffs", 0, 8, 1, "maxDebuffs", auras, onChange)
    maxCount:SetPoint("TOPLEFT", PAD, y)
    maxCount:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local iconSize = GUI:CreateFormSlider(content, "Icon Size", 8, 32, 1, "debuffIconSize", auras, onChange)
    iconSize:SetPoint("TOPLEFT", PAD, y)
    iconSize:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local anchorDrop = GUI:CreateFormDropdown(content, "Anchor", NINE_POINT_OPTIONS, "debuffAnchor", auras, onChange)
    anchorDrop:SetPoint("TOPLEFT", PAD, y)
    anchorDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local growDrop = GUI:CreateFormDropdown(content, "Grow Direction", AURA_GROW_OPTIONS, "debuffGrowDirection", auras, onChange)
    growDrop:SetPoint("TOPLEFT", PAD, y)
    growDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local spacing = GUI:CreateFormSlider(content, "Spacing", 0, 8, 1, "debuffSpacing", auras, onChange)
    spacing:SetPoint("TOPLEFT", PAD, y)
    spacing:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offX = GUI:CreateFormSlider(content, "X Offset", -30, 30, 1, "debuffOffsetX", auras, onChange)
    offX:SetPoint("TOPLEFT", PAD, y)
    offX:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offY = GUI:CreateFormSlider(content, "Y Offset", -30, 30, 1, "debuffOffsetY", auras, onChange)
    offY:SetPoint("TOPLEFT", PAD, y)
    offY:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

-- ROLE settings
local function BuildRoleSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Role"})

    local ind = gfdb.indicators
    if not ind then gfdb.indicators = {} ind = gfdb.indicators end

    local showCheck = GUI:CreateFormCheckbox(content, "Show Role Icon", "showRoleIcon", ind, onChange)
    showCheck:SetPoint("TOPLEFT", PAD, y)
    showCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local sizeSlider = GUI:CreateFormSlider(content, "Icon Size", 6, 24, 1, "roleIconSize", ind, onChange)
    sizeSlider:SetPoint("TOPLEFT", PAD, y)
    sizeSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local anchorDrop = GUI:CreateFormDropdown(content, "Anchor", NINE_POINT_OPTIONS, "roleIconAnchor", ind, onChange)
    anchorDrop:SetPoint("TOPLEFT", PAD, y)
    anchorDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    content:SetHeight(math.abs(y) + 10)
end

-- INDICATORS settings
local function BuildIndicatorsSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Indicators"})

    local ind = gfdb.indicators
    if not ind then gfdb.indicators = {} ind = gfdb.indicators end

    local readyCheck = GUI:CreateFormCheckbox(content, "Ready Check Icon", "showReadyCheck", ind, onChange)
    readyCheck:SetPoint("TOPLEFT", PAD, y)
    readyCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local rezIcon = GUI:CreateFormCheckbox(content, "Resurrection Icon", "showResurrection", ind, onChange)
    rezIcon:SetPoint("TOPLEFT", PAD, y)
    rezIcon:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local summonIcon = GUI:CreateFormCheckbox(content, "Summon Pending Icon", "showSummonPending", ind, onChange)
    summonIcon:SetPoint("TOPLEFT", PAD, y)
    summonIcon:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local leaderIcon = GUI:CreateFormCheckbox(content, "Leader Icon", "showLeaderIcon", ind, onChange)
    leaderIcon:SetPoint("TOPLEFT", PAD, y)
    leaderIcon:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local markerIcon = GUI:CreateFormCheckbox(content, "Target Marker", "showTargetMarker", ind, onChange)
    markerIcon:SetPoint("TOPLEFT", PAD, y)
    markerIcon:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local phaseIcon = GUI:CreateFormCheckbox(content, "Phase Icon", "showPhaseIcon", ind, onChange)
    phaseIcon:SetPoint("TOPLEFT", PAD, y)
    phaseIcon:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    -- Threat section
    local threatHeader = GUI:CreateSectionHeader(content, "Threat")
    threatHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - threatHeader.gap

    local threatCheck = GUI:CreateFormCheckbox(content, "Show Threat Border", "showThreatBorder", ind, onChange)
    threatCheck:SetPoint("TOPLEFT", PAD, y)
    threatCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local threatColor = GUI:CreateFormColorPicker(content, "Threat Color", "threatColor", ind, onChange)
    threatColor:SetPoint("TOPLEFT", PAD, y)
    threatColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local threatFill = GUI:CreateFormSlider(content, "Threat Fill Opacity", 0, 0.5, 0.05, "threatFillOpacity", ind, onChange)
    threatFill:SetPoint("TOPLEFT", PAD, y)
    threatFill:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

-- HEALER settings
local function BuildHealerSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Healer"})

    local healer = gfdb.healer
    if not healer then gfdb.healer = {} healer = gfdb.healer end

    -- Dispel overlay
    local dispelHeader = GUI:CreateSectionHeader(content, "Dispel Overlay")
    dispelHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - dispelHeader.gap

    local dispel = healer.dispelOverlay
    if not dispel then healer.dispelOverlay = {} dispel = healer.dispelOverlay end

    local dispelCheck = GUI:CreateFormCheckbox(content, "Enable Dispel Overlay", "enabled", dispel, onChange)
    dispelCheck:SetPoint("TOPLEFT", PAD, y)
    dispelCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local dispelOpacity = GUI:CreateFormSlider(content, "Border Opacity", 0.1, 1, 0.05, "opacity", dispel, onChange)
    dispelOpacity:SetPoint("TOPLEFT", PAD, y)
    dispelOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local dispelFill = GUI:CreateFormSlider(content, "Fill Opacity", 0, 0.5, 0.05, "fillOpacity", dispel, onChange)
    dispelFill:SetPoint("TOPLEFT", PAD, y)
    dispelFill:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    -- Target highlight
    local targetHeader = GUI:CreateSectionHeader(content, "Target Highlight")
    targetHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - targetHeader.gap

    local targetHL = healer.targetHighlight
    if not targetHL then healer.targetHighlight = {} targetHL = healer.targetHighlight end

    local targetCheck = GUI:CreateFormCheckbox(content, "Enable Target Highlight", "enabled", targetHL, onChange)
    targetCheck:SetPoint("TOPLEFT", PAD, y)
    targetCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local targetColor = GUI:CreateFormColorPicker(content, "Highlight Color", "color", targetHL, onChange)
    targetColor:SetPoint("TOPLEFT", PAD, y)
    targetColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local targetFill = GUI:CreateFormSlider(content, "Fill Opacity", 0, 0.5, 0.05, "fillOpacity", targetHL, onChange)
    targetFill:SetPoint("TOPLEFT", PAD, y)
    targetFill:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    -- My buff indicator
    local myBuffHeader = GUI:CreateSectionHeader(content, "My Buff Indicator")
    myBuffHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - myBuffHeader.gap

    local myBuff = healer.myBuffIndicator
    if not myBuff then healer.myBuffIndicator = {} myBuff = healer.myBuffIndicator end

    local myBuffCheck = GUI:CreateFormCheckbox(content, "Enable My Buff Indicator", "enabled", myBuff, onChange)
    myBuffCheck:SetPoint("TOPLEFT", PAD, y)
    myBuffCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local myBuffColor = GUI:CreateFormColorPicker(content, "Indicator Color", "color", myBuff, onChange)
    myBuffColor:SetPoint("TOPLEFT", PAD, y)
    myBuffColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    content:SetHeight(math.abs(y) + 10)
end

-- DEFENSIVE settings
local function BuildDefensiveSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Defensive"})

    local healer = gfdb.healer
    if not healer then gfdb.healer = {} healer = gfdb.healer end

    local def = healer.defensiveIndicator
    if not def then healer.defensiveIndicator = {} def = healer.defensiveIndicator end

    local defCheck = GUI:CreateFormCheckbox(content, "Enable Defensive Indicator", "enabled", def, onChange)
    defCheck:SetPoint("TOPLEFT", PAD, y)
    defCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local iconSize = GUI:CreateFormSlider(content, "Icon Size", 8, 32, 1, "iconSize", def, onChange)
    iconSize:SetPoint("TOPLEFT", PAD, y)
    iconSize:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local posDrop = GUI:CreateFormDropdown(content, "Position", NINE_POINT_OPTIONS, "position", def, onChange)
    posDrop:SetPoint("TOPLEFT", PAD, y)
    posDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local offX = GUI:CreateFormSlider(content, "X Offset", -30, 30, 1, "offsetX", def, onChange)
    offX:SetPoint("TOPLEFT", PAD, y)
    offX:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offY = GUI:CreateFormSlider(content, "Y Offset", -30, 30, 1, "offsetY", def, onChange)
    offY:SetPoint("TOPLEFT", PAD, y)
    offY:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

-- PRIVATE AURAS settings
local function BuildPrivateAurasSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Private Auras"})

    local pa = gfdb.privateAuras
    if not pa then gfdb.privateAuras = {} pa = gfdb.privateAuras end

    local enableCheck = GUI:CreateFormCheckbox(content, "Enable Private Auras", "enabled", pa, onChange)
    enableCheck:SetPoint("TOPLEFT", PAD, y)
    enableCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local maxSlider = GUI:CreateFormSlider(content, "Max Per Frame", 1, 5, 1, "maxPerFrame", pa, onChange)
    maxSlider:SetPoint("TOPLEFT", PAD, y)
    maxSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local sizeSlider = GUI:CreateFormSlider(content, "Icon Size", 10, 40, 1, "iconSize", pa, onChange)
    sizeSlider:SetPoint("TOPLEFT", PAD, y)
    sizeSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local growDrop = GUI:CreateFormDropdown(content, "Grow Direction", AURA_GROW_OPTIONS, "growDirection", pa, onChange)
    growDrop:SetPoint("TOPLEFT", PAD, y)
    growDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local spacingSlider = GUI:CreateFormSlider(content, "Spacing", 0, 8, 1, "spacing", pa, onChange)
    spacingSlider:SetPoint("TOPLEFT", PAD, y)
    spacingSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local anchorDrop = GUI:CreateFormDropdown(content, "Anchor", NINE_POINT_OPTIONS, "anchor", pa, onChange)
    anchorDrop:SetPoint("TOPLEFT", PAD, y)
    anchorDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local offX = GUI:CreateFormSlider(content, "X Offset", -30, 30, 1, "anchorOffsetX", pa, onChange)
    offX:SetPoint("TOPLEFT", PAD, y)
    offX:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local offY = GUI:CreateFormSlider(content, "Y Offset", -30, 30, 1, "anchorOffsetY", pa, onChange)
    offY:SetPoint("TOPLEFT", PAD, y)
    offY:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local cdCheck = GUI:CreateFormCheckbox(content, "Show Countdown", "showCountdown", pa, onChange)
    cdCheck:SetPoint("TOPLEFT", PAD, y)
    cdCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local cdNumCheck = GUI:CreateFormCheckbox(content, "Show Countdown Numbers", "showCountdownNumbers", pa, onChange)
    cdNumCheck:SetPoint("TOPLEFT", PAD, y)
    cdNumCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    content:SetHeight(math.abs(y) + 10)
end

-- AURA INDICATORS settings
local function BuildAuraIndicatorsSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Aura Indicators"})

    local ai = gfdb.auraIndicators
    if not ai then gfdb.auraIndicators = {} ai = gfdb.auraIndicators end

    local enableCheck = GUI:CreateFormCheckbox(content, "Enable Aura Indicators", "enabled", ai, onChange)
    enableCheck:SetPoint("TOPLEFT", PAD, y)
    enableCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local presetCheck = GUI:CreateFormCheckbox(content, "Use Spec Presets", "usePresets", ai, onChange)
    presetCheck:SetPoint("TOPLEFT", PAD, y)
    presetCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local hint = GUI:CreateLabel(content, "Aura indicators show spec-specific HoTs, buffs, and externals on group frames. Use the Group Frames > Aura Indicators sub-tab for full configuration.", 11, C.textMuted)
    hint:SetPoint("TOPLEFT", PAD, y)
    hint:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    hint:SetJustifyH("LEFT")
    y = y - 40

    content:SetHeight(math.abs(y) + 10)
end

-- ABSORBS settings
local function BuildAbsorbsSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Designer", subTabName = "Absorbs"})

    -- Absorb shield
    local absorbHeader = GUI:CreateSectionHeader(content, "Absorb Shield")
    absorbHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - absorbHeader.gap

    local absorbs = gfdb.absorbs
    if not absorbs then gfdb.absorbs = {} absorbs = gfdb.absorbs end

    local absorbCheck = GUI:CreateFormCheckbox(content, "Show Absorb Shield", "enabled", absorbs, onChange)
    absorbCheck:SetPoint("TOPLEFT", PAD, y)
    absorbCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local absorbColor = GUI:CreateFormColorPicker(content, "Absorb Color", "color", absorbs, onChange)
    absorbColor:SetPoint("TOPLEFT", PAD, y)
    absorbColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local absorbOpacity = GUI:CreateFormSlider(content, "Absorb Opacity", 0.1, 1, 0.05, "opacity", absorbs, onChange)
    absorbOpacity:SetPoint("TOPLEFT", PAD, y)
    absorbOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    -- Heal prediction
    local healHeader = GUI:CreateSectionHeader(content, "Heal Prediction")
    healHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - healHeader.gap

    local healPred = gfdb.healPrediction
    if not healPred then gfdb.healPrediction = {} healPred = gfdb.healPrediction end

    local healCheck = GUI:CreateFormCheckbox(content, "Show Heal Prediction", "enabled", healPred, onChange)
    healCheck:SetPoint("TOPLEFT", PAD, y)
    healCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local healOpacity = GUI:CreateFormSlider(content, "Heal Prediction Opacity", 0.1, 1, 0.05, "opacity", healPred, onChange)
    healOpacity:SetPoint("TOPLEFT", PAD, y)
    healOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- ADDITIONAL DROPDOWN OPTIONS (for non-visual settings)
---------------------------------------------------------------------------
local GROW_OPTIONS = {
    { value = "DOWN", text = "Down" },
    { value = "UP", text = "Up" },
    { value = "RIGHT", text = "Right (Horizontal)" },
    { value = "LEFT", text = "Left (Horizontal)" },
}

local GROUP_GROW_OPTIONS = {
    { value = "RIGHT", text = "Right" },
    { value = "LEFT", text = "Left" },
}

local SORT_OPTIONS = {
    { value = "INDEX", text = "Group Index" },
    { value = "NAME", text = "Name" },
}

local GROUP_BY_OPTIONS = {
    { value = "GROUP", text = "Group Number" },
    { value = "ROLE", text = "Role" },
    { value = "CLASS", text = "Class" },
}

local ANCHOR_SIDE_OPTIONS = {
    { value = "LEFT", text = "Left" },
    { value = "RIGHT", text = "Right" },
}

local PET_ANCHOR_OPTIONS = {
    { value = "BOTTOM", text = "Below Group" },
    { value = "RIGHT", text = "Right of Group" },
    { value = "LEFT", text = "Left of Group" },
}

---------------------------------------------------------------------------
-- GENERAL SETTINGS (enable, appearance, fonts)
---------------------------------------------------------------------------
local function BuildGeneralSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Group Frames", subTabName = "General"})

    -- Enable checkbox (requires reload)
    local enableCheck = GUI:CreateFormCheckbox(content, "Enable Group Frames (Req. Reload)", "enabled", gfdb, function()
        GUI:ShowConfirmation({
            title = "Reload UI?",
            message = "Enabling or disabling group frames requires a UI reload to take effect.",
            acceptText = "Reload",
            cancelText = "Later",
            onAccept = function() QUI:SafeReload() end,
        })
    end)
    enableCheck:SetPoint("TOPLEFT", PAD, y)
    enableCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local infoText = GUI:CreateDescription(content, "Custom party and raid frames. Replaces Blizzard's default group frames when enabled.")
    infoText:SetPoint("TOPLEFT", PAD, y)
    infoText:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - 40

    -- Test Mode section
    local testHeader = GUI:CreateSectionHeader(content, "Test / Preview")
    testHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - testHeader.gap

    local testDesc = GUI:CreateLabel(content, "Preview group frames when solo. Also available via /qui grouptest", 11, C.textMuted)
    testDesc:SetPoint("TOPLEFT", PAD, y)
    testDesc:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    testDesc:SetJustifyH("LEFT")
    y = y - 24

    local partyTestBtn = GUI:CreateButton(content, "Party Preview (5)", 150, 28, function()
        local editMode = ns.QUI_GroupFrameEditMode
        if editMode then editMode:ToggleTestMode("party") end
    end)
    partyTestBtn:SetPoint("TOPLEFT", PAD, y)

    local partyEditBtn = GUI:CreateButton(content, "Edit Party", 120, 28, function()
        local editMode = ns.QUI_GroupFrameEditMode
        if not editMode then return end
        if editMode:IsEditMode() and editMode._lastTestPreviewType == "party" then
            editMode:DisableEditMode()
        else
            editMode:EnableEditMode("party")
        end
    end)
    partyEditBtn:SetPoint("LEFT", partyTestBtn, "RIGHT", 10, 0)
    y = y - 36

    local raidTestBtn = GUI:CreateButton(content, "Raid Preview (25)", 150, 28, function()
        local editMode = ns.QUI_GroupFrameEditMode
        if editMode then editMode:ToggleTestMode("raid") end
    end)
    raidTestBtn:SetPoint("TOPLEFT", PAD, y)

    local raidEditBtn = GUI:CreateButton(content, "Edit Raid", 120, 28, function()
        local editMode = ns.QUI_GroupFrameEditMode
        if not editMode then return end
        if editMode:IsEditMode() and editMode._lastTestPreviewType == "raid" then
            editMode:DisableEditMode()
        else
            editMode:EnableEditMode("raid")
        end
    end)
    raidEditBtn:SetPoint("LEFT", raidTestBtn, "RIGHT", 10, 0)
    y = y - 40

    -- Appearance section
    local appearHeader = GUI:CreateSectionHeader(content, "Appearance")
    appearHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - appearHeader.gap

    local general = gfdb.general
    if not general then gfdb.general = {} general = gfdb.general end

    local classColorCheck = GUI:CreateFormCheckbox(content, "Use Class Colors", "useClassColor", general, onChange)
    classColorCheck:SetPoint("TOPLEFT", PAD, y)
    classColorCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local defBgColor = GUI:CreateFormColorPicker(content, "Default Background Color", "defaultBgColor", general, onChange, { noAlpha = true })
    defBgColor:SetPoint("TOPLEFT", PAD, y)
    defBgColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local defHealthOpacity = GUI:CreateFormSlider(content, "Health Opacity", 0.1, 1.0, 0.01, "defaultHealthOpacity", general, onChange)
    defHealthOpacity:SetPoint("TOPLEFT", PAD, y)
    defHealthOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local defBgOpacity = GUI:CreateFormSlider(content, "Background Opacity", 0.1, 1.0, 0.01, "defaultBgOpacity", general, onChange)
    defBgOpacity:SetPoint("TOPLEFT", PAD, y)
    defBgOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local darkModeCheck = GUI:CreateFormCheckbox(content, "Dark Mode", "darkMode", general, onChange)
    darkModeCheck:SetPoint("TOPLEFT", PAD, y)
    darkModeCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local dmHealthColor = GUI:CreateFormColorPicker(content, "Darkmode Health Color", "darkModeHealthColor", general, onChange, { noAlpha = true })
    dmHealthColor:SetPoint("TOPLEFT", PAD, y)
    dmHealthColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local dmBgColor = GUI:CreateFormColorPicker(content, "Darkmode Background Color", "darkModeBgColor", general, onChange, { noAlpha = true })
    dmBgColor:SetPoint("TOPLEFT", PAD, y)
    dmBgColor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local dmHealthOpacity = GUI:CreateFormSlider(content, "Darkmode Health Opacity", 0.1, 1.0, 0.01, "darkModeHealthOpacity", general, onChange)
    dmHealthOpacity:SetPoint("TOPLEFT", PAD, y)
    dmHealthOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local dmBgOpacity = GUI:CreateFormSlider(content, "Darkmode Background Opacity", 0.1, 1.0, 0.01, "darkModeBgOpacity", general, onChange)
    dmBgOpacity:SetPoint("TOPLEFT", PAD, y)
    dmBgOpacity:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local textureDrop = GUI:CreateDropdown(content, "Health Bar Texture", GetTextureList(), "texture", general, onChange)
    textureDrop:SetPoint("TOPLEFT", PAD, y)
    textureDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local borderSlider = GUI:CreateFormSlider(content, "Border Size", 0, 3, 1, "borderSize", general, onChange)
    borderSlider:SetPoint("TOPLEFT", PAD, y)
    borderSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local fontDrop = GUI:CreateDropdown(content, "Font", GetFontList(), "font", general, onChange)
    fontDrop:SetPoint("TOPLEFT", PAD, y)
    fontDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local fontSizeSlider = GUI:CreateFormSlider(content, "Font Size", 8, 20, 1, "fontSize", general, onChange)
    fontSizeSlider:SetPoint("TOPLEFT", PAD, y)
    fontSizeSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local tooltipCheck = GUI:CreateFormCheckbox(content, "Show Tooltips on Hover", "showTooltips", general, onChange)
    tooltipCheck:SetPoint("TOPLEFT", PAD, y)
    tooltipCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    content:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- LAYOUT SETTINGS
---------------------------------------------------------------------------
local function BuildLayoutSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Group Frames", subTabName = "Layout"})

    local layout = gfdb.layout
    if not layout then gfdb.layout = {} layout = gfdb.layout end
    local position = gfdb.position
    if not position then gfdb.position = {} position = gfdb.position end

    local unifiedCheck = GUI:CreateFormCheckbox(content, "Unified Party & Raid Position", "unifiedPosition", gfdb, function()
        GUI:ShowConfirmation({
            title = "Reload Required",
            message = "Changing group frame positioning mode requires a UI reload to take effect.",
            acceptText = "Reload Now",
            cancelText = "Later",
            isDestructive = false,
            onAccept = function() QUI:SafeReload() end,
        })
    end)
    unifiedCheck:SetPoint("TOPLEFT", PAD, y)
    unifiedCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local unifiedHint = GUI:CreateLabel(content,
        "When disabled, party and raid frames have separate movers and can be positioned independently.", 10, C.textMuted)
    unifiedHint:SetPoint("TOPLEFT", PAD + 4, y + 4)
    unifiedHint:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    unifiedHint:SetJustifyH("LEFT")
    y = y - 20

    local growDrop = GUI:CreateDropdown(content, "Grow Direction", GROW_OPTIONS, "growDirection", layout, onChange)
    growDrop:SetPoint("TOPLEFT", PAD, y)
    growDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local groupGrowDrop = GUI:CreateDropdown(content, "Group Grow Direction (Raid)", GROUP_GROW_OPTIONS, "groupGrowDirection", layout, onChange)
    groupGrowDrop:SetPoint("TOPLEFT", PAD, y)
    groupGrowDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local spacingSlider = GUI:CreateFormSlider(content, "Frame Spacing", 0, 10, 1, "spacing", layout, onChange)
    spacingSlider:SetPoint("TOPLEFT", PAD, y)
    spacingSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local groupSpacingSlider = GUI:CreateFormSlider(content, "Group Spacing (Raid)", 0, 30, 1, "groupSpacing", layout, onChange)
    groupSpacingSlider:SetPoint("TOPLEFT", PAD, y)
    groupSpacingSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local showPlayerCheck = GUI:CreateFormCheckbox(content, "Show Player in Group", "showPlayer", layout, onChange)
    showPlayerCheck:SetPoint("TOPLEFT", PAD, y)
    showPlayerCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local sortHeader = GUI:CreateSectionHeader(content, "Sorting")
    sortHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - sortHeader.gap

    local groupByDrop = GUI:CreateDropdown(content, "Group By", GROUP_BY_OPTIONS, "groupBy", layout, onChange)
    groupByDrop:SetPoint("TOPLEFT", PAD, y)
    groupByDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local sortDrop = GUI:CreateDropdown(content, "Sort Method", SORT_OPTIONS, "sortMethod", layout, onChange)
    sortDrop:SetPoint("TOPLEFT", PAD, y)
    sortDrop:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local roleSortCheck = GUI:CreateFormCheckbox(content, "Sort by Role (Tank > Healer > DPS)", "sortByRole", layout, onChange)
    roleSortCheck:SetPoint("TOPLEFT", PAD, y)
    roleSortCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local posHeader = GUI:CreateSectionHeader(content, "Position")
    posHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - posHeader.gap

    local xSlider = GUI:CreateFormSlider(content, "X Offset", -800, 800, 1, "offsetX", position, onChange)
    xSlider:SetPoint("TOPLEFT", PAD, y)
    xSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local ySlider = GUI:CreateFormSlider(content, "Y Offset", -500, 500, 1, "offsetY", position, onChange)
    ySlider:SetPoint("TOPLEFT", PAD, y)
    ySlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- DIMENSIONS SETTINGS
---------------------------------------------------------------------------
local function BuildDimensionsSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Group Frames", subTabName = "Dimensions"})

    local dims = gfdb.dimensions
    if not dims then gfdb.dimensions = {} dims = gfdb.dimensions end

    local partyHeader = GUI:CreateSectionHeader(content, "Party (1-5 players)")
    partyHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - partyHeader.gap

    local partyW = GUI:CreateFormSlider(content, "Width", 80, 400, 1, "partyWidth", dims, onChange)
    partyW:SetPoint("TOPLEFT", PAD, y)
    partyW:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local partyH = GUI:CreateFormSlider(content, "Height", 16, 80, 1, "partyHeight", dims, onChange)
    partyH:SetPoint("TOPLEFT", PAD, y)
    partyH:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local smallHeader = GUI:CreateSectionHeader(content, "Small Raid (6-15 players)")
    smallHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - smallHeader.gap

    local smallW = GUI:CreateFormSlider(content, "Width", 60, 400, 1, "smallRaidWidth", dims, onChange)
    smallW:SetPoint("TOPLEFT", PAD, y)
    smallW:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local smallH = GUI:CreateFormSlider(content, "Height", 14, 100, 1, "smallRaidHeight", dims, onChange)
    smallH:SetPoint("TOPLEFT", PAD, y)
    smallH:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local medHeader = GUI:CreateSectionHeader(content, "Medium Raid (16-25 players)")
    medHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - medHeader.gap

    local medW = GUI:CreateFormSlider(content, "Width", 50, 300, 1, "mediumRaidWidth", dims, onChange)
    medW:SetPoint("TOPLEFT", PAD, y)
    medW:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local medH = GUI:CreateFormSlider(content, "Height", 12, 100, 1, "mediumRaidHeight", dims, onChange)
    medH:SetPoint("TOPLEFT", PAD, y)
    medH:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local largeHeader = GUI:CreateSectionHeader(content, "Large Raid (26-40 players)")
    largeHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - largeHeader.gap

    local largeW = GUI:CreateFormSlider(content, "Width", 40, 250, 1, "largeRaidWidth", dims, onChange)
    largeW:SetPoint("TOPLEFT", PAD, y)
    largeW:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local largeH = GUI:CreateFormSlider(content, "Height", 10, 100, 1, "largeRaidHeight", dims, onChange)
    largeH:SetPoint("TOPLEFT", PAD, y)
    largeH:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- CLICK-CAST SETTINGS
---------------------------------------------------------------------------
local function BuildClickCastSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Group Frames", subTabName = "Click-Cast"})

    local cc = gfdb.clickCast
    if not cc then gfdb.clickCast = {} cc = gfdb.clickCast end

    local enableCheck = GUI:CreateFormCheckbox(content, "Enable Click-Casting", "enabled", cc, function()
        RefreshGF()
        if cc.enabled then
            print("|cFF34D399[QUI]|r Click-casting enabled. Reload recommended.")
        end
    end)
    enableCheck:SetPoint("TOPLEFT", PAD, y)
    enableCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local cliqueNote = GUI:CreateLabel(content, "Note: If Clique addon is loaded, QUI click-casting is disabled by default to avoid conflicts.", 11, C.textMuted)
    cliqueNote:SetPoint("TOPLEFT", PAD, y)
    cliqueNote:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    cliqueNote:SetJustifyH("LEFT")
    y = y - 30

    local perSpecCheck = GUI:CreateFormCheckbox(content, "Per-Spec Bindings", "perSpec", cc, RefreshGF)
    perSpecCheck:SetPoint("TOPLEFT", PAD, y)
    perSpecCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local smartResCheck = GUI:CreateFormCheckbox(content, "Smart Resurrection (auto-swap to res on dead targets)", "smartRes", cc, RefreshGF)
    smartResCheck:SetPoint("TOPLEFT", PAD, y)
    smartResCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local tooltipCheck = GUI:CreateFormCheckbox(content, "Show Binding Tooltip on Hover", "showTooltip", cc, RefreshGF)
    tooltipCheck:SetPoint("TOPLEFT", PAD, y)
    tooltipCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local GFCC = ns.QUI_GroupFrameClickCast

    local ACTION_TYPE_OPTIONS = {
        { value = "spell",  text = "Spell" },
        { value = "macro",  text = "Macro" },
        { value = "target", text = "Target Unit" },
        { value = "focus",  text = "Set Focus" },
        { value = "assist", text = "Assist" },
    }
    local BINDING_TYPE_OPTIONS = {
        { value = "mouse", text = "Mouse Button" },
        { value = "key",   text = "Keyboard Key" },
    }
    local BUTTON_OPTIONS = {
        { value = "LeftButton",   text = "Left Click" },
        { value = "RightButton",  text = "Right Click" },
        { value = "MiddleButton", text = "Middle Click" },
        { value = "Button4",      text = "Button 4" },
        { value = "Button5",      text = "Button 5" },
    }
    local MOD_OPTIONS = {
        { value = "",              text = "None" },
        { value = "shift",         text = "Shift" },
        { value = "ctrl",          text = "Ctrl" },
        { value = "alt",           text = "Alt" },
        { value = "shift-ctrl",    text = "Shift+Ctrl" },
        { value = "shift-alt",     text = "Shift+Alt" },
        { value = "ctrl-alt",      text = "Ctrl+Alt" },
        { value = "shift-ctrl-alt", text = "Shift+Ctrl+Alt" },
    }
    local ACTION_FALLBACK_ICONS = {
        target = "Interface\\Icons\\Ability_Hunter_SniperShot",
        focus  = "Interface\\Icons\\Ability_TrickShot",
        assist = "Interface\\Icons\\Ability_Hunter_MasterMarksman",
        macro  = "Interface\\Icons\\INV_Misc_Note_01",
    }

    -- Spec context label
    local specLabel = GUI:CreateLabel(content, "", 11, C.accent)
    specLabel:SetPoint("TOPLEFT", PAD, y)
    specLabel:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    specLabel:SetJustifyH("LEFT")
    specLabel:Hide()

    local function UpdateSpecLabel()
        if cc.perSpec then
            local specIndex = GetSpecialization()
            if specIndex then
                local _, specName = GetSpecializationInfo(specIndex)
                if specName then
                    specLabel:SetText("Editing bindings for: " .. specName)
                    specLabel:Show()
                    return
                end
            end
        end
        specLabel:Hide()
    end
    UpdateSpecLabel()
    if specLabel:IsShown() then y = y - 20 end

    -- Current bindings list
    local bindingsHeader = GUI:CreateSectionHeader(content, "Current Bindings")
    bindingsHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - bindingsHeader.gap

    local bindingListFrame = CreateFrame("Frame", nil, content)
    bindingListFrame:SetPoint("TOPLEFT", PAD, y)
    bindingListFrame:SetSize(400, 20)

    local RefreshBindingList

    -- Add binding form
    local addContainer = CreateFrame("Frame", nil, content)
    addContainer:SetPoint("TOPLEFT", bindingListFrame, "BOTTOMLEFT", 0, -10)
    addContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    addContainer:SetHeight(400)
    addContainer:EnableMouse(false)

    local addHeader = GUI:CreateSectionHeader(addContainer, "Add Binding")
    addHeader:SetPoint("TOPLEFT", 0, 0)
    local ay = -addHeader.gap

    -- Drop zone for spellbook drag
    local dropZone = CreateFrame("Button", nil, addContainer, "BackdropTemplate")
    dropZone:SetHeight(68)
    dropZone:SetPoint("TOPLEFT", 0, ay)
    dropZone:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)
    local pxDrop = QUICore:GetPixelSize(dropZone)
    dropZone:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = pxDrop })
    dropZone:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.8)
    dropZone:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

    local dropLabel = dropZone:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropLabel:SetPoint("CENTER", 0, 0)
    dropLabel:SetText("Drop a spell from your spellbook")
    dropLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)

    local addState = { bindingType = "mouse", button = "LeftButton", key = nil, modifiers = "", actionType = "spell", spellName = "", macroText = "" }
    local spellInput
    local mouseButtonContainer, keyCaptureContainer

    dropZone:SetScript("OnReceiveDrag", function()
        local cursorType, id1, id2, _, id4 = GetCursorInfo()
        if cursorType == "spell" then
            local slotIndex, bookType, spellID = id1, id2 or "spell", id4
            if not spellID and slotIndex then
                local spellBank = (bookType == "pet") and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
                local info = C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)
                if info then spellID = info.spellID end
            end
            if spellID then
                local overrideID = C_Spell.GetOverrideSpell(spellID)
                if overrideID and overrideID ~= spellID then spellID = overrideID end
                local name = C_Spell.GetSpellName(spellID)
                if name then
                    addState.spellName = name
                    addState.actionType = "spell"
                    if spellInput then spellInput:SetText(name) end
                end
            end
            ClearCursor()
        end
    end)
    dropZone:SetScript("OnMouseUp", function(self)
        if GetCursorInfo() == "spell" then
            local handler = self:GetScript("OnReceiveDrag")
            if handler then handler() end
        end
    end)
    dropZone:SetScript("OnEnter", function(self)
        if GetCursorInfo() == "spell" then
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            dropLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end
    end)
    dropZone:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        dropLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
    end)
    ay = ay - 78

    -- Binding type dropdown
    local bindingTypeDrop = GUI:CreateFormDropdown(addContainer, "Binding Type", BINDING_TYPE_OPTIONS, "bindingType", addState, function(val)
        addState.bindingType = val
        if mouseButtonContainer then mouseButtonContainer:SetShown(val == "mouse") end
        if keyCaptureContainer then keyCaptureContainer:SetShown(val == "key") end
    end)
    bindingTypeDrop:SetPoint("TOPLEFT", 0, ay)
    bindingTypeDrop:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)
    ay = ay - FORM_ROW

    -- Mouse button dropdown
    mouseButtonContainer = CreateFrame("Frame", nil, addContainer)
    mouseButtonContainer:SetHeight(FORM_ROW)
    mouseButtonContainer:SetPoint("TOPLEFT", 0, ay)
    mouseButtonContainer:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)

    local buttonDrop = GUI:CreateFormDropdown(mouseButtonContainer, "Mouse Button", BUTTON_OPTIONS, "button", addState)
    buttonDrop:SetPoint("TOPLEFT", 0, 0)
    buttonDrop:SetPoint("RIGHT", mouseButtonContainer, "RIGHT", 0, 0)

    -- Keyboard key capture
    keyCaptureContainer = CreateFrame("Frame", nil, addContainer)
    keyCaptureContainer:SetHeight(FORM_ROW)
    keyCaptureContainer:SetPoint("TOPLEFT", 0, ay)
    keyCaptureContainer:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)
    keyCaptureContainer:Hide()

    local keyLabel = keyCaptureContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyLabel:SetPoint("LEFT", 0, 0)
    keyLabel:SetText("Key")
    keyLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local keyCaptureBtn = CreateFrame("Button", nil, keyCaptureContainer, "BackdropTemplate")
    keyCaptureBtn:SetPoint("LEFT", keyCaptureContainer, "LEFT", 180, 0)
    keyCaptureBtn:SetPoint("RIGHT", keyCaptureContainer, "RIGHT", 0, 0)
    keyCaptureBtn:SetHeight(26)
    local pxKey = QUICore:GetPixelSize(keyCaptureBtn)
    keyCaptureBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = pxKey })
    keyCaptureBtn:SetBackdropColor(0.08, 0.08, 0.08, 1)
    keyCaptureBtn:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    local keyCaptureText = keyCaptureBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyCaptureText:SetPoint("CENTER", 0, 0)
    keyCaptureText:SetText("Click to bind a key")
    keyCaptureText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)

    local IGNORE_KEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true }

    keyCaptureBtn:SetScript("OnClick", function(self)
        self.isCapturing = true
        keyCaptureText:SetText("Press a key...")
        keyCaptureText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        self:EnableKeyboard(true)
    end)
    keyCaptureBtn:SetScript("OnKeyDown", function(self, key)
        if not self.isCapturing then self:SetPropagateKeyboardInput(true) return end
        self:SetPropagateKeyboardInput(false)
        if IGNORE_KEYS[key] then self:SetPropagateKeyboardInput(true) return end
        if key == "ESCAPE" then
            self.isCapturing = false
            self:EnableKeyboard(false)
            self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
            if addState.key then
                keyCaptureText:SetText(addState.key)
                keyCaptureText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
            else
                keyCaptureText:SetText("Click to bind a key")
                keyCaptureText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            end
            return
        end
        addState.key = key
        self.isCapturing = false
        self:EnableKeyboard(false)
        self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        keyCaptureText:SetText(key)
        keyCaptureText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end)
    keyCaptureBtn:SetScript("OnEnter", function(self)
        if not self.isCapturing then self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.7) end
    end)
    keyCaptureBtn:SetScript("OnLeave", function(self)
        if not self.isCapturing then self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1) end
    end)
    ay = ay - FORM_ROW

    -- Modifier dropdown
    local modDrop = GUI:CreateFormDropdown(addContainer, "Modifier", MOD_OPTIONS, "modifiers", addState)
    modDrop:SetPoint("TOPLEFT", 0, ay)
    modDrop:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)
    ay = ay - FORM_ROW

    -- Action type dropdown
    local spellInputContainer, macroInputContainer
    local actionDrop = GUI:CreateFormDropdown(addContainer, "Action Type", ACTION_TYPE_OPTIONS, "actionType", addState, function(val)
        addState.actionType = val
        if spellInputContainer then spellInputContainer:SetShown(val == "spell") end
        if macroInputContainer then macroInputContainer:SetShown(val == "macro") end
    end)
    actionDrop:SetPoint("TOPLEFT", 0, ay)
    actionDrop:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)
    ay = ay - FORM_ROW

    -- Spell name editbox
    spellInputContainer = CreateFrame("Frame", nil, addContainer)
    spellInputContainer:SetHeight(FORM_ROW)
    spellInputContainer:SetPoint("TOPLEFT", 0, ay)
    spellInputContainer:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)

    local spellLabel = spellInputContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellLabel:SetPoint("LEFT", 0, 0)
    spellLabel:SetText("Spell Name")
    spellLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local spellInputBg = CreateFrame("Frame", nil, spellInputContainer, "BackdropTemplate")
    spellInputBg:SetPoint("LEFT", spellInputContainer, "LEFT", 180, 0)
    spellInputBg:SetPoint("RIGHT", spellInputContainer, "RIGHT", 0, 0)
    spellInputBg:SetHeight(24)
    local pxSpell = QUICore:GetPixelSize(spellInputBg)
    spellInputBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = pxSpell })
    spellInputBg:SetBackdropColor(0.08, 0.08, 0.08, 1)
    spellInputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    spellInput = CreateFrame("EditBox", nil, spellInputBg)
    spellInput:SetPoint("LEFT", 8, 0)
    spellInput:SetPoint("RIGHT", -8, 0)
    spellInput:SetHeight(22)
    spellInput:SetAutoFocus(false)
    spellInput:SetFont(GUI.FONT_PATH, 11, "")
    spellInput:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    spellInput:SetText("")
    spellInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    spellInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    spellInput:SetScript("OnTextChanged", function(self) addState.spellName = self:GetText() end)
    spellInput:SetScript("OnEditFocusGained", function() spellInputBg:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
    spellInput:SetScript("OnEditFocusLost", function() spellInputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1) end)
    ay = ay - FORM_ROW

    -- Macro text editbox
    macroInputContainer = CreateFrame("Frame", nil, addContainer)
    macroInputContainer:SetHeight(FORM_ROW)
    macroInputContainer:SetPoint("TOPLEFT", 0, ay)
    macroInputContainer:SetPoint("RIGHT", addContainer, "RIGHT", 0, 0)
    macroInputContainer:Hide()

    local macroLabel = macroInputContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    macroLabel:SetPoint("LEFT", 0, 0)
    macroLabel:SetText("Macro Text")
    macroLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local macroInputBg = CreateFrame("Frame", nil, macroInputContainer, "BackdropTemplate")
    macroInputBg:SetPoint("LEFT", macroInputContainer, "LEFT", 180, 0)
    macroInputBg:SetPoint("RIGHT", macroInputContainer, "RIGHT", 0, 0)
    macroInputBg:SetHeight(24)
    local pxMacro = QUICore:GetPixelSize(macroInputBg)
    macroInputBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = pxMacro })
    macroInputBg:SetBackdropColor(0.08, 0.08, 0.08, 1)
    macroInputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    local macroInput = CreateFrame("EditBox", nil, macroInputBg)
    macroInput:SetPoint("LEFT", 8, 0)
    macroInput:SetPoint("RIGHT", -8, 0)
    macroInput:SetHeight(22)
    macroInput:SetAutoFocus(false)
    macroInput:SetFont(GUI.FONT_PATH, 11, "")
    macroInput:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    macroInput:SetText("")
    macroInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    macroInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    macroInput:SetScript("OnTextChanged", function(self) addState.macroText = self:GetText() end)
    macroInput:SetScript("OnEditFocusGained", function() macroInputBg:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
    macroInput:SetScript("OnEditFocusLost", function() macroInputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1) end)

    -- Add Binding button
    local addBtnY = ay - FORM_ROW
    local addBtn = GUI:CreateButton(addContainer, "Add Binding", 130, 26, function()
        local actionType = addState.actionType
        local newBinding = { modifiers = addState.modifiers, actionType = actionType }
        if addState.bindingType == "key" then
            if not addState.key or addState.key == "" then print("|cFFFF5555[QUI]|r Press a key to bind first.") return end
            newBinding.key = addState.key
        else
            newBinding.button = addState.button
        end
        if actionType == "spell" then
            local name = addState.spellName
            if not name or name == "" then print("|cFFFF5555[QUI]|r Enter a spell name.") return end
            local spellID = C_Spell.GetSpellIDForSpellIdentifier(name)
            if not spellID then print("|cFFFF5555[QUI]|r Spell not found: " .. name) return end
            newBinding.spell = C_Spell.GetSpellName(spellID) or name
        elseif actionType == "macro" then
            local text = addState.macroText
            if not text or text == "" then print("|cFFFF5555[QUI]|r Enter macro text.") return end
            newBinding.spell = "Macro"
            newBinding.macro = text
        else
            newBinding.spell = actionType
        end
        local ok, err = GFCC:AddBinding(newBinding)
        if not ok then print("|cFFFF5555[QUI]|r " .. (err or "Failed to add binding.")) return end
        addState.spellName = ""
        addState.macroText = ""
        addState.key = nil
        spellInput:SetText("")
        macroInput:SetText("")
        keyCaptureText:SetText("Click to bind a key")
        keyCaptureText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
        RefreshBindingList()
    end)
    addBtn:SetPoint("TOPLEFT", 0, addBtnY)
    addContainer:SetHeight(math.abs(addBtnY) + 36)

    -- Refresh binding list
    RefreshBindingList = function()
        for _, child in ipairs({bindingListFrame:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        UpdateSpecLabel()
        local buttonNames = GFCC:GetButtonNames()
        local modLabels  = GFCC:GetModifierLabels()
        local bindings   = GFCC:GetEditableBindings()
        local listY = 0
        if #bindings == 0 then
            local emptyLabel = CreateFrame("Frame", nil, bindingListFrame)
            emptyLabel:SetSize(300, 28)
            emptyLabel:SetPoint("TOPLEFT", 0, 0)
            local emptyText = emptyLabel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            emptyText:SetPoint("LEFT", 0, 0)
            emptyText:SetText("No bindings configured yet.")
            emptyText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            listY = -28
        else
            for i, binding in ipairs(bindings) do
                local row = CreateFrame("Frame", nil, bindingListFrame)
                row:SetSize(400, 28)
                row:SetPoint("TOPLEFT", 0, listY)
                local iconTex = row:CreateTexture(nil, "ARTWORK")
                iconTex:SetSize(24, 24)
                iconTex:SetPoint("LEFT", 0, 0)
                iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                local actionType = binding.actionType or "spell"
                if actionType == "spell" and binding.spell then
                    local spellID = C_Spell.GetSpellIDForSpellIdentifier(binding.spell)
                    if spellID then
                        local info = C_Spell.GetSpellInfo(spellID)
                        iconTex:SetTexture(info and info.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
                    else
                        iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                else
                    iconTex:SetTexture(ACTION_FALLBACK_ICONS[actionType] or "Interface\\Icons\\INV_Misc_QuestionMark")
                end
                local modLabel = modLabels[binding.modifiers or ""] or ""
                local triggerLabel = binding.key or (buttonNames[binding.button] or binding.button)
                local comboText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                comboText:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
                comboText:SetWidth(140)
                comboText:SetJustifyH("LEFT")
                comboText:SetText(modLabel .. triggerLabel)
                comboText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
                local spellText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                spellText:SetPoint("LEFT", comboText, "RIGHT", 8, 0)
                spellText:SetWidth(140)
                spellText:SetJustifyH("LEFT")
                local displayName = binding.spell or actionType
                if actionType == "macro" then displayName = "Macro" end
                spellText:SetText(displayName)
                spellText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
                local removeBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
                removeBtn:SetSize(22, 22)
                local pxRm = QUICore:GetPixelSize(removeBtn)
                removeBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = pxRm })
                removeBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                removeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                local xText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                xText:SetPoint("CENTER", 0, 0)
                xText:SetText("X")
                xText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
                removeBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) xText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
                removeBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) xText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 0.7) end)
                removeBtn:SetScript("OnClick", function() GFCC:RemoveBinding(i) RefreshBindingList() end)
                removeBtn:SetPoint("LEFT", spellText, "RIGHT", 8, 0)
                listY = listY - 30
            end
        end
        local listHeight = math.max(20, math.abs(listY))
        bindingListFrame:SetHeight(listHeight)
        local fixedTop = math.abs(y)
        local totalHeight = fixedTop + listHeight + 10 + addContainer:GetHeight() + 30
        content:SetHeight(totalHeight)
    end

    RefreshBindingList()

    perSpecCheck.track:HookScript("OnClick", function()
        C_Timer.After(0.05, function() RefreshBindingList() end)
    end)
end

---------------------------------------------------------------------------
-- MISC SETTINGS (Range, Portrait, Pets, Spotlight)
---------------------------------------------------------------------------
local function BuildMiscSettings(content, gfdb, onChange)
    local y = -10
    GUI:SetSearchContext({tabIndex = 6, tabName = "Group Frames", subTabName = "Misc"})

    -- Range check
    local rangeHeader = GUI:CreateSectionHeader(content, "Range Check")
    rangeHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - rangeHeader.gap

    local range = gfdb.range
    if not range then gfdb.range = {} range = gfdb.range end

    local rangeCheck = GUI:CreateFormCheckbox(content, "Enable Range Check (dim out-of-range members)", "enabled", range, onChange)
    rangeCheck:SetPoint("TOPLEFT", PAD, y)
    rangeCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local rangeAlpha = GUI:CreateFormSlider(content, "Out-of-Range Alpha", 0.1, 0.8, 0.05, "outOfRangeAlpha", range, onChange)
    rangeAlpha:SetPoint("TOPLEFT", PAD, y)
    rangeAlpha:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    -- Portrait
    local portraitHeader = GUI:CreateSectionHeader(content, "Portrait")
    portraitHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - portraitHeader.gap

    local portrait = gfdb.portrait
    if not portrait then gfdb.portrait = {} portrait = gfdb.portrait end

    local portraitCheck = GUI:CreateFormCheckbox(content, "Show Portrait", "showPortrait", portrait, onChange)
    portraitCheck:SetPoint("TOPLEFT", PAD, y)
    portraitCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local portraitSide = GUI:CreateDropdown(content, "Portrait Side", ANCHOR_SIDE_OPTIONS, "portraitSide", portrait, onChange)
    portraitSide:SetPoint("TOPLEFT", PAD, y)
    portraitSide:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local portraitSize = GUI:CreateFormSlider(content, "Portrait Size", 16, 60, 1, "portraitSize", portrait, onChange)
    portraitSize:SetPoint("TOPLEFT", PAD, y)
    portraitSize:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    -- Pet frames
    local petHeader = GUI:CreateSectionHeader(content, "Pet Frames")
    petHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - petHeader.gap

    local pets = gfdb.pets
    if not pets then gfdb.pets = {} pets = gfdb.pets end

    local petCheck = GUI:CreateFormCheckbox(content, "Enable Pet Frames", "enabled", pets, onChange)
    petCheck:SetPoint("TOPLEFT", PAD, y)
    petCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local petW = GUI:CreateFormSlider(content, "Pet Frame Width", 40, 200, 1, "width", pets, onChange)
    petW:SetPoint("TOPLEFT", PAD, y)
    petW:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local petH = GUI:CreateFormSlider(content, "Pet Frame Height", 10, 40, 1, "height", pets, onChange)
    petH:SetPoint("TOPLEFT", PAD, y)
    petH:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    local petAnchor = GUI:CreateDropdown(content, "Pet Anchor", PET_ANCHOR_OPTIONS, "anchorTo", pets, onChange)
    petAnchor:SetPoint("TOPLEFT", PAD, y)
    petAnchor:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    -- Spotlight
    local spotHeader = GUI:CreateSectionHeader(content, "Spotlight")
    spotHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - spotHeader.gap

    local spotDesc = GUI:CreateLabel(content, "Pin specific raid members (by role or name) to a separate highlighted group for tank-watch or healing assignment awareness.", 11, C.textMuted)
    spotDesc:SetPoint("TOPLEFT", PAD, y)
    spotDesc:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    spotDesc:SetJustifyH("LEFT")
    y = y - 30

    local spot = gfdb.spotlight
    if not spot then gfdb.spotlight = {} spot = gfdb.spotlight end

    local spotCheck = GUI:CreateFormCheckbox(content, "Enable Spotlight", "enabled", spot, onChange)
    spotCheck:SetPoint("TOPLEFT", PAD, y)
    spotCheck:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local spotGrow = GUI:CreateDropdown(content, "Spotlight Grow Direction", GROW_OPTIONS, "growDirection", spot, onChange)
    spotGrow:SetPoint("TOPLEFT", PAD, y)
    spotGrow:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - DROP_ROW

    local spotSpacing = GUI:CreateFormSlider(content, "Spotlight Spacing", 0, 10, 1, "spacing", spot, onChange)
    spotSpacing:SetPoint("TOPLEFT", PAD, y)
    spotSpacing:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - SLIDER_HEIGHT

    content:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- ELEMENT BUILDERS TABLE
---------------------------------------------------------------------------
local ELEMENT_BUILDERS = {
    frame = BuildFrameSettings,
    health = BuildHealthSettings,
    power = BuildPowerSettings,
    name = BuildNameSettings,
    healthText = BuildHealthTextSettings,
    buffs = BuildBuffsSettings,
    debuffs = BuildDebuffsSettings,
    role = BuildRoleSettings,
    indicators = BuildIndicatorsSettings,
    healer = BuildHealerSettings,
    defensive = BuildDefensiveSettings,
    auraIndicators = BuildAuraIndicatorsSettings,
    privateAuras = BuildPrivateAurasSettings,
    absorbs = BuildAbsorbsSettings,
    general = BuildGeneralSettings,
    layout = BuildLayoutSettings,
    dimensions = BuildDimensionsSettings,
    clickCast = BuildClickCastSettings,
    misc = BuildMiscSettings,
}

---------------------------------------------------------------------------
-- WIDGET BAR
---------------------------------------------------------------------------
local function CreateWidgetBar(container, selectElementFunc, state, elementKeys)
    local bar = CreateFrame("Frame", nil, container)
    bar:SetHeight(1)
    bar:SetPoint("TOPLEFT", 0, 0)
    bar:SetPoint("RIGHT", container, "RIGHT", 0, 0)

    local buttons = {}
    local fontPath = GUI.FONT_PATH or "Fonts\\FRIZQT__.TTF"
    local px = QUICore.GetPixelSize and QUICore:GetPixelSize(bar) or 1
    local btnHeight = 24
    local btnSpacing = 4
    local rowGap = 4

    local x, y = 0, 0

    for _, key in ipairs(elementKeys) do
        local label = ELEMENT_LABELS[key]
        local btn = CreateFrame("Button", nil, bar, "BackdropTemplate")
        btn:SetHeight(btnHeight)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = px,
        })
        btn:SetBackdropColor(0.12, 0.12, 0.12, 1)
        btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetFont(fontPath, 11, "")
        text:SetTextColor(C.text[1], C.text[2], C.text[3])
        text:SetText(label)
        text:SetPoint("CENTER")

        local textWidth = text:GetStringWidth() or 40
        btn:SetWidth(textWidth + 16)

        -- Wrap to next row if needed
        local barWidth = container:GetWidth() - (PADDING * 2)
        if barWidth < 100 then barWidth = 700 end
        if x + btn:GetWidth() > barWidth and x > 0 then
            x = 0
            y = y - (btnHeight + rowGap)
        end

        btn:SetPoint("TOPLEFT", bar, "TOPLEFT", x, y)
        x = x + btn:GetWidth() + btnSpacing

        btn.elementKey = key
        btn:SetScript("OnClick", function()
            selectElementFunc(key)
        end)

        btn:SetScript("OnEnter", function(self)
            if state.selectedElement ~= key then
                self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.6)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if state.selectedElement ~= key then
                self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
        end)

        buttons[key] = btn
    end

    local totalHeight = math.abs(y) + btnHeight
    bar:SetHeight(totalHeight)

    state.widgetBarButtons = buttons
    return bar, totalHeight
end

---------------------------------------------------------------------------
-- DESIGNER VIEW BUILDER (for one sub-tab: party or raid)
---------------------------------------------------------------------------
local function BuildDesignerView(tabContent, previewType)
    local gfdb = GetGFDB()
    if not gfdb then
        local info = GUI:CreateLabel(tabContent, "Group frame settings not available.", 12, C.textMuted)
        info:SetPoint("TOPLEFT", PAD, -10)
        tabContent:SetHeight(100)
        return
    end

    -- State for this view
    local state = {
        selectedElement = nil,
        previewWrapper = nil,
        childRefs = {},
        hitOverlays = {},
        widgetBarButtons = {},
        settingsPanels = {},
        settingsArea = nil,
    }

    local y = -10

    -- Description
    local desc = GUI:CreateDescription(tabContent, "Click on a part of the preview frame or use the buttons below to configure it. Changes apply immediately.")
    desc:SetPoint("TOPLEFT", PAD, y)
    desc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    y = y - 26

    ---------------------------------------------------------------------------
    -- PREVIEW FRAME
    ---------------------------------------------------------------------------
    local childRefs = {}
    state.childRefs = childRefs

    local function RebuildPreview()
        if state.previewWrapper then
            state.previewWrapper:Hide()
            state.previewWrapper:SetParent(nil)
            state.previewWrapper = nil
        end
        for _, overlay in pairs(state.hitOverlays) do
            overlay:Hide()
            overlay:SetParent(nil)
        end
        wipe(state.hitOverlays)
        wipe(childRefs)

        local wrapper = CreateDesignerPreview(tabContent, previewType, childRefs)
        if not wrapper then return end

        wrapper:SetPoint("TOPLEFT", PAD, state._previewY or y)
        state.previewWrapper = wrapper

        local frame = childRefs.frame
        if not frame then return end

        -- Helper to create overlay, wire hover/click, store in state
        local function MakeOverlay(key, anchorFrame, mode, w, h, aPoint, arPoint, oX, oY)
            local overlay = CreateHitOverlay(tabContent, frame, key, anchorFrame, mode, w, h, aPoint, arPoint, oX, oY)
            overlay:SetScript("OnEnter", function(self)
                self.highlight:Show()
            end)
            overlay:SetScript("OnLeave", function(self)
                if state.selectedElement ~= key then
                    self.highlight:Hide()
                end
            end)
            overlay:SetScript("OnClick", function()
                if state.selectElement then
                    state.selectElement(key)
                end
            end)
            state.hitOverlays[key] = overlay
        end

        -- Overlays for each element
        MakeOverlay("frame", frame, "fill")
        if childRefs.healthBar then MakeOverlay("health", childRefs.healthBar, "fill") end
        if childRefs.powerBar then MakeOverlay("power", childRefs.powerBar, "fill") end
        if childRefs.nameText then
            local nameW = childRefs.nameText:GetStringWidth() or 60
            MakeOverlay("name", childRefs.nameText, "fixed", nameW + 4, 20, "LEFT", "LEFT", -2, 0)
        end
        if childRefs.healthText then
            local htW = childRefs.healthText:GetStringWidth() or 40
            MakeOverlay("healthText", childRefs.healthText, "fixed", htW + 4, 20, "RIGHT", "RIGHT", 2, 0)
        end
        if childRefs.buffContainer then MakeOverlay("buffs", childRefs.buffContainer, "fill") end
        if childRefs.debuffContainer then MakeOverlay("debuffs", childRefs.debuffContainer, "fill") end
        if childRefs.roleIcon then MakeOverlay("role", childRefs.roleIcon, "fill") end
        if childRefs.absorbOverlay then MakeOverlay("absorbs", childRefs.absorbOverlay, "fill") end

        -- Re-highlight selected element
        if state.selectedElement and state.hitOverlays[state.selectedElement] then
            state.hitOverlays[state.selectedElement].highlight:Show()
        end
    end

    state._previewY = y
    RebuildPreview()

    local previewH = state.previewWrapper and state.previewWrapper:GetHeight() or 100
    y = y - previewH - 10

    ---------------------------------------------------------------------------
    -- WIDGET BAR
    ---------------------------------------------------------------------------
    local function SelectElement(key)
        -- Deselect previous
        if state.selectedElement then
            local prevBtn = state.widgetBarButtons[state.selectedElement]
            if prevBtn then
                prevBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                prevBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
            end
            local prevOverlay = state.hitOverlays[state.selectedElement]
            if prevOverlay then prevOverlay.highlight:Hide() end
            local prevPanel = state.settingsPanels[state.selectedElement]
            if prevPanel then prevPanel:Hide() end
        end

        state.selectedElement = key

        -- Highlight button
        local btn = state.widgetBarButtons[key]
        if btn then
            btn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            btn:SetBackdropColor(C.accent[1] * 0.2, C.accent[2] * 0.2, C.accent[3] * 0.2, 1)
        end

        -- Highlight overlay
        local overlay = state.hitOverlays[key]
        if overlay then overlay.highlight:Show() end

        -- Lazy-create or show settings panel
        local panel = state.settingsPanels[key]
        if not panel then
            local builder = ELEMENT_BUILDERS[key]
            if not builder then return end

            panel = CreateFrame("Frame", nil, state.settingsArea)
            panel:SetPoint("TOPLEFT", 0, 0)
            panel:SetPoint("RIGHT", state.settingsArea, "RIGHT", 0, 0)

            local currentGFDB = GetGFDB()
            if currentGFDB then
                local function onChangeHandler()
                    RefreshGF()
                    RebuildPreview()
                end
                builder(panel, currentGFDB, onChangeHandler)
            end

            state.settingsPanels[key] = panel
        end
        panel:Show()

        -- Resize settings area to fit panel
        local panelHeight = panel:GetHeight()
        if panelHeight and panelHeight > 0 then
            state.settingsArea:SetHeight(panelHeight)
        end

        -- Resize total content
        local totalY = math.abs(state._previewY) + previewH + 10 + (state._widgetBarHeight or 0) + 10 + (panelHeight or 300) + 20
        tabContent:SetHeight(totalY)
    end

    state.selectElement = SelectElement

    local widgetBar, widgetBarHeight = CreateWidgetBar(tabContent, SelectElement, state, VISUAL_ELEMENT_KEYS)
    widgetBar:SetPoint("TOPLEFT", PAD, y)
    state._widgetBarHeight = widgetBarHeight
    y = y - widgetBarHeight - 10

    ---------------------------------------------------------------------------
    -- SETTINGS AREA
    ---------------------------------------------------------------------------
    local settingsArea = CreateFrame("Frame", nil, tabContent)
    settingsArea:SetPoint("TOPLEFT", PAD, y)
    settingsArea:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    settingsArea:SetHeight(300)
    state.settingsArea = settingsArea

    -- Select first element by default
    SelectElement("frame")

    tabContent:SetHeight(800)
end

---------------------------------------------------------------------------
-- SETTINGS VIEW BUILDER (for the Settings sub-tab)
---------------------------------------------------------------------------
local function BuildSettingsView(tabContent)
    local gfdb = GetGFDB()
    if not gfdb then
        local info = GUI:CreateLabel(tabContent, "Group frame settings not available.", 12, C.textMuted)
        info:SetPoint("TOPLEFT", PAD, -10)
        tabContent:SetHeight(100)
        return
    end

    -- State for this view (reuse same accordion pattern as designer)
    local state = {
        selectedElement = nil,
        widgetBarButtons = {},
        settingsPanels = {},
        settingsArea = nil,
    }

    local y = -10

    -- Description
    local desc = GUI:CreateDescription(tabContent, "Global group frame settings shared across Party and Raid layouts.")
    desc:SetPoint("TOPLEFT", PAD, y)
    desc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    y = y - 26

    ---------------------------------------------------------------------------
    -- WIDGET BAR (config elements only)
    ---------------------------------------------------------------------------
    local function SelectElement(key)
        -- Deselect previous
        if state.selectedElement then
            local prevBtn = state.widgetBarButtons[state.selectedElement]
            if prevBtn then
                prevBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                prevBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
            end
            local prevPanel = state.settingsPanels[state.selectedElement]
            if prevPanel then prevPanel:Hide() end
        end

        state.selectedElement = key

        -- Highlight button
        local btn = state.widgetBarButtons[key]
        if btn then
            btn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            btn:SetBackdropColor(C.accent[1] * 0.2, C.accent[2] * 0.2, C.accent[3] * 0.2, 1)
        end

        -- Lazy-create or show settings panel
        local panel = state.settingsPanels[key]
        if not panel then
            local builder = ELEMENT_BUILDERS[key]
            if not builder then return end

            panel = CreateFrame("Frame", nil, state.settingsArea)
            panel:SetPoint("TOPLEFT", 0, 0)
            panel:SetPoint("RIGHT", state.settingsArea, "RIGHT", 0, 0)

            local currentGFDB = GetGFDB()
            if currentGFDB then
                builder(panel, currentGFDB, RefreshGF)
            end

            state.settingsPanels[key] = panel
        end
        panel:Show()

        -- Resize settings area to fit panel
        local panelHeight = panel:GetHeight()
        if panelHeight and panelHeight > 0 then
            state.settingsArea:SetHeight(panelHeight)
        end

        -- Resize total content
        local totalY = 26 + (state._widgetBarHeight or 0) + 10 + (panelHeight or 300) + 20
        tabContent:SetHeight(totalY)
    end

    local widgetBar, widgetBarHeight = CreateWidgetBar(tabContent, SelectElement, state, CONFIG_ELEMENT_KEYS)
    widgetBar:SetPoint("TOPLEFT", PAD, y)
    state._widgetBarHeight = widgetBarHeight
    y = y - widgetBarHeight - 10

    ---------------------------------------------------------------------------
    -- SETTINGS AREA
    ---------------------------------------------------------------------------
    local settingsArea = CreateFrame("Frame", nil, tabContent)
    settingsArea:SetPoint("TOPLEFT", PAD, y)
    settingsArea:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    settingsArea:SetHeight(300)
    state.settingsArea = settingsArea

    -- Select first config element by default
    SelectElement("general")

    tabContent:SetHeight(800)
end

---------------------------------------------------------------------------
-- MAIN ENTRY POINT
---------------------------------------------------------------------------
local function CreateDesignerPage(parent)
    local scroll, content = CreateScrollableContent(parent)

    GUI:CreateSubTabs(content, {
        { name = "Party",    builder = function(tc) BuildDesignerView(tc, "party") end },
        { name = "Raid",     builder = function(tc) BuildDesignerView(tc, "raid") end },
        { name = "Settings", builder = BuildSettingsView },
    })

    content:SetHeight(800)
end

---------------------------------------------------------------------------
-- EXPORT
---------------------------------------------------------------------------
ns.QUI_DesignerOptions = {
    CreateDesignerPage = CreateDesignerPage,
}
