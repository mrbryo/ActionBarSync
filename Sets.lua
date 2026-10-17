--[[ ------------------------------------------------------------------------
	Title: 			Sets.lua
	Author: 		mrbryo
	Description: 	Functions for Blizzards Addon Compartment system, which provides a minimap dropdown button without needing LibDataBroker or custom minimap handling.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

--[[---------------------------------------------------------------------------
    Function:   SetAutoResetMountFilters
    Purpose:    Set the auto reset mount filters status for the current character.
-----------------------------------------------------------------------------]]
function ns:SetAutoResetMountFilters(value)
    local funcName = "SetAutoResetMountFilters"

    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = ns:SetupProfileDB()

    --@debug@
    if self:GetDevMode() == true then
        ns:Print(("(%s) Set Auto Reset Mount Filters: %s; Profile DB Set: %s"):format(funcName, tostring(value), tostring(isSet)))
    end
    --@end-debug@

    -- trigger update
    if isSet == true then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].autoResetMountFilters = value
    else
        ns:Print((ns.L["Error Setting Auto Reset Mount Filters to: %s for %s!"]):format(tostring(value), tostring(ns.data.currentPlayerServer)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetDevMode
    Purpose:    Set the development mode status for the current character.
-----------------------------------------------------------------------------]]
function ns:SetDevMode(value)
    -- make sure the current player key is set
    if not ns.data.currentPlayerServerSpec then return end

    -- set the dev mode value
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].isDevMode = value
end

--[[---------------------------------------------------------------------------
    Function:   ToggleDevMode
    Purpose:    Toggle the development mode status for the current character.
-----------------------------------------------------------------------------]]
function ns:ToggleDevMode()
    if not ns.data.currentPlayerServerSpec then return end

    -- get current dev mode value
    local previousValue = self:GetDevMode()

    -- set the dev mode value
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].isDevMode = not previousValue
end

--[[---------------------------------------------------------------------------
    Function:   SetMinimapButtonVisible
    Purpose:    Set whether the minimap button should be visible.
-----------------------------------------------------------------------------]]
function ns:SetMinimapButtonVisible(visible)
    if not ActionBarSyncDB or not ActionBarSyncDB.global then
        return
    end

    -- Initialize minimap settings if they don't exist
    if not ActionBarSyncDB.global.minimap then
        ActionBarSyncDB.global.minimap = {}
    end

    -- LibDBIcon uses 'hide' property, so we invert our 'visible' boolean
    ActionBarSyncDB.global.minimap.hide = not visible
end

--[[---------------------------------------------------------------------------
    Function:   SetFramePosition
    Purpose:    Store the position of a frame in the profile database.
    Parameters: frameName - the name of the frame
                point - the point on the frame being set (e.g., "TOPLEFT")
                relativePoint - the point on the relative frame (e.g., "BOTTOMRIGHT")
                xOfs - the x offset from the relative point
                yOfs - the y offset from the relative point
-----------------------------------------------------------------------------]]
function ns:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return false end

    -- ensure profile DB structure exists
    local isSet = ns:SetupProfileDB()

    if isSet == true then
        -- create index for this frame
        if ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions[frameName] == nil then
            ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions[frameName] = {}
        end

        -- Store position data
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].point = point
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].relativePoint = relativePoint
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].xOffset = xOfs
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].yOffset = yOfs

        -- return true since storage was successful
        return true
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServer
    Purpose:    Get a formatted value with player and server name.
-----------------------------------------------------------------------------]]
function ns:SetKeyPlayerServer()
    -- verify variable's are setup
    if not ns.data.currentPlayerServer then
        ns.data.currentPlayerServer = ""
    end
    if not ns.data.currentPlayerServerWithSpace then
        ns.data.currentPlayerServerWithSpace = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- set values
    ns.data.currentPlayerServer = ("%s-%s"):format(unitName, unitServer)
    ns.data.currentPlayerServerWithSpace = ("%s - %s"):format(unitName, unitServer)
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServerSpec
    Purpose:    Get a formatted value with player, server and current spec names.
-----------------------------------------------------------------------------]]
function ns:SetKeyPlayerServerSpec()
    -- verify variable is setup
    if not ns.data.currentPlayerServerSpec then
        ns.data.currentPlayerServerSpec = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- get characters current spec number
    local specializationIndex = C_SpecializationInfo.GetSpecialization()

    --@debug@
    -- print("Current spec index: " .. tostring(specializationIndex))
    --@end-debug@

    -- get the name of the current spec number
    local specId, specName, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)

    --@debug@
    -- print("Current spec name: " .. tostring(specName))
    --@end-debug@

    -- finally return the special key
    if not specName then
        ns.data.currentPlayerServerSpec = self.L["Unknown"]
    else
        ns.data.currentPlayerServerSpec = ("%s-%s-%s"):format(unitName, unitServer, specName) or nil
        ns.data.currentPlayerServerSpecNoHyphens = ("%s%s%s"):format(unitName, unitServer, specName) or nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionBar
    Purpose:    Set the last action bar for the current character.
-----------------------------------------------------------------------------]]
function ns:SetLastActionBar(value)
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].actionLookup.bar = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionBarUtilities
    Purpose:    Set the last action bar for the Utilities tab for the current character.
-----------------------------------------------------------------------------]]
function ns:SetLastActionBarUtilities(value)
    --@debug@
    -- if self:GetDevMode() == true then
        -- ns:Print(("(SetLastActionBarUtilities) Setting last action bar to: %s for %s"):format(tostring(value), tostring(ns.data.currentPlayerServerSpec)))
    -- end
    --@end-debug@
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities = {}
    end
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities.removeButtons then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities.removeButtons = {}
    end
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities.removeButtons.bar then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities.removeButtons.bar = "actionbar1"
    end
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].utilities.removeButtons.bar = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionButton
    Purpose:    Set the last action button for the current character.
-----------------------------------------------------------------------------]]
function ns:SetLastActionButton(value)
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].actionLookup.btn = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionID
    Purpose:    Set the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ns:SetLastActionID(value)
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].actionLookup.id = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionName
    Purpose:    Set the last action name for the current character.
-----------------------------------------------------------------------------]]
function ns:SetLastActionName(value)
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].actionLookup.name = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionType
    Purpose:    Set the last action type for the current character.
-----------------------------------------------------------------------------]]
function ns:SetLastActionType(value)
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].actionLookup.type = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastScan
    Purpose:    Set the last scan date/time for the action bars.
-----------------------------------------------------------------------------]]
function ns:SetLastScan(dttm)
    -- make sure the current player spec key is set
    if not ns.data.currentPlayerServerSpec then return false end

    -- make sure data structure exists
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].lastScan then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].lastScan = self.L["Never"]
    end

    -- check inputs
    if not dttm then
        dttm = ns.L["Never"]
    end

    -- update db
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].lastScan = dttm
    return true
end

--[[---------------------------------------------------------------------------
    Function:   SetLastSynced
    Purpose:    Set the last synced time for the action bars to update the Last Synced field in the options for the current character.
       TODO:    Format a base data value instead of a formatted value. Format it when needed later.
-----------------------------------------------------------------------------]]
function ns:SetLastSynced(dttm)
    -- make sure the current player spec key is set
    if not ns.data.currentPlayerServerSpec then return false end

    -- make sure data structure exists
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].lastSynced then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].lastSynced = self.L["Never"]
    end

    -- check inputs
    if not dttm then
        dttm = ns.L["Never"]
    end

    -- update db
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].lastSynced = dttm
    return true
end

--[[---------------------------------------------------------------------------
    Function:   SetPlacementErrorClearButton
    Purpose:    Set the placement error clear button status for the current character.
-----------------------------------------------------------------------------]]
function ns:SetPlacementErrorClearButton(value)
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = ns:SetupProfileDB()

    if isSet == true then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].placementErrorClearButton = value
        --@debug@
        if self:GetDevMode() == true then
            ns:Print(("Set Placement Error Clear Button for %s to %s"):format(tostring(ns.data.currentPlayerServer), tostring(value)))
        end
        --@end-debug@
    else
        ns:Print((ns.L["Error Setting Placement Error Clear Button to: %s for %s!"]):format(tostring(value), tostring(ns.data.currentPlayerServer)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetRestoreChoiceActionBar
    Purpose:    Set the last selected action bar for the current character.
-----------------------------------------------------------------------------]]
function ns:SetRestoreChoiceActionBar(value)
    if not value then
        value = self.L["None"]
    end
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore = {}
    end
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore.choice then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore.choice = {}
    end
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore.choice.actionBar = value
end

--[[---------------------------------------------------------------------------
    Function:   SetRestoreChoiceDateTime
    Purpose:    Set the last selected backup date/time for the current character.
-----------------------------------------------------------------------------]]
function ns:SetRestoreChoiceDateTime(value)
    if not value then
        value = self.L["None"]
    end
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore = {}
    end
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore.choice then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore.choice = {}
    end
    ActionBarSyncDB.char[ns.data.currentPlayerServerSpec].restore.choice.backupDttm = value
end

--[[---------------------------------------------------------------------------
    Function:   SetSyncOnLogon
    Purpose:    Set the sync on logon status for the current character.
-----------------------------------------------------------------------------]]
function ns:SetSyncOnLogon(value)
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = ns:SetupProfileDB()

    if isSet == true then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].syncOnLogon = value
    else
        ns:Print((ns.L["Error Setting Sync On Logon to: %s for %s!"]):format(tostring(value), tostring(ns.data.currentPlayerServer)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetTab
    Purpose:    Set the current selected tab in the options.
-----------------------------------------------------------------------------]]
function ns:SetTab(key)
    --@debug@
    -- ns:Print("(SetTab) Setting tab to: " .. tostring(key) .. " for " .. tostring(ns.data.currentPlayerServer))
    --@end-debug@
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = ns:SetupProfileDB()

    if isSet == true then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].mytab = key
    else
        ns:Print((ns.L["Error Setting Last tab: %s for %s!"]):format(tostring(key), tostring(ns.data.currentPlayerServer)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetupCharDB
    Purpose:    Ensure the character specific database structure is setup.
-----------------------------------------------------------------------------]]
function ns:SetupCharDB()
    -- make sure the current player spec key is set
    if not ns.data.currentPlayerServerSpec then return false end

    -- create whole DB if missing
    if not ActionBarSyncDB then ActionBarSyncDB = {} end

    -- create char node if missing
    if not ActionBarSyncDB.char then ActionBarSyncDB.char = {} end

    -- add current character spec if missing
    if not ActionBarSyncDB.char[ns.data.currentPlayerServerSpec] then
        ActionBarSyncDB.char[ns.data.currentPlayerServerSpec] = {}
    end

    -- return true if we get to here in the code
    return true
end

function ns:SetupGlobalDB()
    -- create whole DB if missing
    if not ActionBarSyncDB then ActionBarSyncDB = {} end

    -- actionBars holds just a sorted array of action bar names; needed under global and profile
    if not ActionBarSyncDB.global then
        ActionBarSyncDB.global = {}
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetupProfileDB
    Purpose:    Ensure the profile specific database structure is setup.
-----------------------------------------------------------------------------]]
function ns:SetupProfileDB()
    -- make sure the current player key is set
    if ns.data.currentPlayerServer == nil then return false end

    -- create whole DB if missing
    if ActionBarSyncDB == nil then ActionBarSyncDB = {} end

    -- create profile node if missing
    if ActionBarSyncDB.profile == nil then ActionBarSyncDB.profile = {} end

    -- add current character if missing
    if ActionBarSyncDB.profile[ns.data.currentPlayerServer] == nil then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer] = {}
    end

    -- initialize UI settings if they don't exist
    if ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui == nil then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui = {}
    end
    if ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions == nil then
        ActionBarSyncDB.profile[ns.data.currentPlayerServer].ui.positions = {}
    end

    -- return true if we get to here in the code
    return true
end