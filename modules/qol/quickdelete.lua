local addonName, ns = ...
local Helpers = ns.Helpers

local function GetSettings()
    return Helpers.GetModuleDB("general")
end

local function GetConfirmButton(popup, which)
    local name = popup and popup.GetName and popup:GetName()
    if name then
        local btn = _G[name .. "Button1"]
        if btn then return btn end
    end

    if popup then
        for i = 1, select("#", popup:GetChildren()) do
            local child = select(i, popup:GetChildren())
            if child and child.GetText and child:GetText() == OKAY then
                return child
            end
        end
    end
end

hooksecurefunc("StaticPopup_Show", function(which)
    if which ~= "DELETE_GOOD_ITEM" and which ~= "DELETE_GOOD_ITEM_WITH_NAME" then return end

    local settings = GetSettings()
    if not settings or not settings.autoDeleteConfirm then return end

    C_Timer.After(0, function()
        settings = GetSettings()
        if not settings or not settings.autoDeleteConfirm then return end

        local s = StaticPopup_FindVisible(which)
        if not s then return end

        local edit = s.EditBox or s.editBox
        local btn = GetConfirmButton(s, which)
        if not edit or not btn then
            return
        end

        local required
        if which == "DELETE_GOOD_ITEM" then
            required = DELETE_ITEM_CONFIRM_STRING
        else
            required = s.data or s.textArg1 or ""
        end

        edit:SetText(required)
        edit:Hide()

        if not s._linkFS then
            s._linkFS = s:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            s._linkFS:SetPoint("CENTER", edit, "CENTER")
            s:HookScript("OnHide", function()
                if s._linkFS then s._linkFS:Hide() end
            end)
        end
        local _, _, link = GetCursorInfo()
        s._linkFS:SetText(link or "")
        s._linkFS:Show()

        btn:Enable()
    end)
end)
