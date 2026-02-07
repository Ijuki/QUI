local addonName, ns = ...
local Helpers = ns.Helpers

local overlay
local hooksInstalled = false

local function GetSettings()
    return Helpers.GetModuleDB("general")
end

local function IsAddonLoadedByName(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    if IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

local function IsEnabled()
    local settings = GetSettings()
    return settings and settings.hideGuildChat == true
end

local function HideOverlay()
    if overlay then
        overlay:Hide()
    end
end

local function EnsureOverlay()
    if overlay then return overlay end

    local frame = CreateFrame("Button", "QUI_GuildCommunityOverlay", UIParent)
    frame:SetFrameStrata("HIGH")

    frame.tex = frame:CreateTexture(nil, "BACKGROUND")
    frame.tex:SetAllPoints()
    frame.tex:SetColorTexture(0, 0, 0, 1)

    frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
    frame.text:SetPoint("CENTER")
    frame.text:SetText("Chat Hidden. Click to show.")
    frame.text:SetTextColor(1, 1, 1, 1)

    frame:EnableMouse(true)
    frame:RegisterForClicks("AnyUp")
    frame:SetScript("OnClick", function(self)
        self:Hide()
    end)
    frame:Hide()

    overlay = frame
    return overlay
end

local function GetOverlayAnchor()
    if not CommunitiesFrame then return nil end
    if not CommunitiesFrame.GetDisplayMode then return nil end

    local mode = CommunitiesFrame:GetDisplayMode()
    if mode == COMMUNITIES_FRAME_DISPLAY_MODES.CHAT then
        return CommunitiesFrame.Chat and CommunitiesFrame.Chat.InsetFrame
    end
    if mode == COMMUNITIES_FRAME_DISPLAY_MODES.MINIMIZED then
        return _G.CommunitiesFrameInset
    end
    return nil
end

local function UpdateOverlay()
    if not IsEnabled() then
        HideOverlay()
        return
    end

    if not CommunitiesFrame or not CommunitiesFrame:IsShown() then
        HideOverlay()
        return
    end

    local anchor = GetOverlayAnchor()
    if not anchor then
        HideOverlay()
        return
    end

    local frame = EnsureOverlay()
    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:SetAllPoints(anchor)
    frame:Show()
end

local function InstallHooks()
    if hooksInstalled then return end
    if not CommunitiesFrame then return end

    hooksInstalled = true
    hooksecurefunc(CommunitiesFrame, "SetDisplayMode", UpdateOverlay)
    hooksecurefunc(CommunitiesFrame, "Show", UpdateOverlay)
    hooksecurefunc(CommunitiesFrame, "Hide", HideOverlay)
    if type(CommunitiesFrame.OnClubSelected) == "function" then
        hooksecurefunc(CommunitiesFrame, "OnClubSelected", UpdateOverlay)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "Blizzard_Communities" then return end
        InstallHooks()
        UpdateOverlay()
        return
    end

    if event == "PLAYER_LOGIN" then
        if IsAddonLoadedByName("Blizzard_Communities") then
            InstallHooks()
            UpdateOverlay()
        end
    end
end)

_G.QUI_RefreshHideGuildChat = function()
    InstallHooks()
    UpdateOverlay()
end
