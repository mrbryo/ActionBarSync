--[[ ------------------------------------------------------------------------
	Title: 			Minimap.lua
	Author: 		mrbryo
	Create Date : 	2026-Sep-26
	Description: 	Functions for Blizzards Addon Compartment system, which provides a minimap dropdown button without needing LibDataBroker or custom minimap handling.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

--[[---------------------------------------------------------------------------
    Function:   ToysByFunctionAddon_OpenOptions
    Purpose:    Open the addon's options panel in the Blizzard Interface Options.
-----------------------------------------------------------------------------]]
local function ActionBarSyncAddon_OpenOptions()
    if ns.data.optionID and Settings then
        Settings.OpenToCategory(ns.data.optionID)
    else
        -- let user know there was an issue, then open the options panel normally
        ns:Print(ns.L["Issue with addon options panel, cannot open settings. If persists please open a ticket."])
    end
end

-- ---------------------------------------------------------------------------
-- ADDON COMPARTMENT HANDLERS
-- These MUST be global functions (not local, not on a table).
-- The function names MUST exactly match the TOC field values.
-- ---------------------------------------------------------------------------

-- Called when the user LEFT-clicks or RIGHT-clicks the compartment entry.
-- name: the addon name string (e.g. "CompartmentDemo")
-- mouseButton: "LeftButton" or "RightButton"
function ActionBarSyncAddon_OnClick(name, mouseButton)
    --@debug@
    -- functions for dev mode
    local function IsDevModeSelected()
        return ns:GetDevMode()
    end
    local function SetDevMode()
        ns:ToggleDevMode()
    end
    --@end-debug@

    -- process menu clicks
    if mouseButton == "LeftButton" then
        -- open main window
        ns:ShowUI()
    elseif mouseButton == "RightButton" then
        -- open functions window
        -- owner populated by the Compartment system, used as the anchor for the dropdown menu
        MenuUtil.CreateContextMenu(owner, function(owner, rootDescription)
            rootDescription:CreateButton(ns.L["Open Addon"], function() ns:ShowUI() end)
            rootDescription:CreateDivider()
            rootDescription:CreateButton("Open Addon Options", ActionBarSyncAddon_OpenOptions)
            -- rootDescription:CreateButton("(Re)Scan Toys", ToysByFunctionAddon_ScanToys)
            --@debug@
            rootDescription:CreateDivider()
            rootDescription:CreateCheckbox(ns.L["Dev Mode"], IsDevModeSelected, SetDevMode)
            --@end-debug@
        end)
        -- ns:Print("Minimap button right-clicked. No options menu yet, but this is where it would go.")
    end
end

-- Called when the mouse cursor enters the compartment entry.
-- Used to show a tooltip. menuButtonFrame is the anchor for the tooltip.
function ActionBarSyncAddon_OnEnter(name, menuButtonFrame)
    -- GameTooltip is the global shared tooltip frame used by most UI elements.
    -- SetOwner tells it where to appear and how to anchor.
    -- "ANCHOR_LEFT" positions the tooltip to the left of the anchor frame. 
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")

    -- SetText sets the title line (bold, larger font).
    GameTooltip:SetText(ns.L["Action Bar Sync"], 1, 1, 1)

    -- AddLine adds a body line. Args: text, r, g, b (0-1 color values).
    -- White text for primary instructions.
    GameTooltip:AddLine(ns.L["Left-click open main config window."], 0.7, 0.7, 0.7)
    -- Gray text for secondary instructions.
    GameTooltip:AddLine(ns.L["Right-click for function window."], 0.7, 0.7, 0.7)

    -- Show() makes the tooltip visible with all the lines we've added.
    GameTooltip:Show()
end

-- Called when the mouse cursor leaves the compartment entry.
-- Always hide the tooltip here to prevent it from lingering on screen.
function ActionBarSyncAddon_OnLeave(name, menuButtonFrame)
    GameTooltip:Hide()
end

--[[---------------------------------------------------------------------------
    Function:   CreateMinimapButton
    Purpose:    Create minimap button using LibDBIcon-1.0.
-----------------------------------------------------------------------------]]
function ns:CreateMinimapButton()
    -- check if LibStub and LibDBIcon are available
    if not LibStub then
        ns.data.minimap.libstubStatus = false
        return
    end

    local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not LibDBIcon then
        ns.data.minimap.libdbiconStatus = false
        return
    end

    local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
    if not LDB then
        ns.data.minimap.libdbStatus = false
        return
    end

    -- Create the data broker object
    local minimapLDB = LDB:NewDataObject("ActionBarSync", {
        type = "launcher",
        text = "ActionBarSync",
        icon = "Interface\\Icons\\inv_misc_coinbag_special",
        OnClick = function(clickedframe, button)
            if button == "LeftButton" then
                ns:ShowUI()
            elseif button == "RightButton" then
                -- open to addon options pane if it was created successfully, if not just open the panel normally
                -- ns.optionsPanel is the actual frame built for the addon options
                -- ns.data.optionID is the static string value assigned to the addons options pane
                if ns.optionsPanel and Settings then
                    Settings.OpenToCategory(ns.data.optionID)
                else
                    -- let user know there was an issue, then open the options panel normally
                    ns:Print(ns.L["Issue with addon options panel, cannot open settings."])
                    SettingsPanel:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(ns.L["Action Bar Sync"] or "Action Bar Sync")
            tooltip:AddLine(ns.L["Click to open Action Bar Sync"] or "Click to open Action Bar Sync", 1, 1, 1)
            tooltip:AddLine(ns.L["Right-click for Options"] or "Right-click for Options", 1, 1, 1)
        end,
    })

    -- Initialize database for minimap settings if needed
    if not ActionBarSyncDB.global.minimap then
        ActionBarSyncDB.global.minimap = {
            hide = false,
        }
    end

    -- Register with LibDBIcon
    LibDBIcon:Register("ActionBarSync", minimapLDB, ActionBarSyncDB.global.minimap)

    -- Store reference
    self.minimapLDB = minimapLDB
end

--[[---------------------------------------------------------------------------
    Function:   UpdateMinimapButtonVisibility
    Purpose:    Update the minimap button visibility using LibDBIcon.
-----------------------------------------------------------------------------]]
function ns:UpdateMinimapButtonVisibility()
    local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not LibDBIcon or not self.minimapLDB then
        return
    end

    local shouldShow = self:GetMinimapButtonVisible()
    if shouldShow then
        LibDBIcon:Show("ActionBarSync")
    else
        LibDBIcon:Hide("ActionBarSync")
    end
end