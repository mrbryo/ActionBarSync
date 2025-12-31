--[[---------------------------------------------------------------------------
        INSERT IN ALPHABETICAL ORDER!!!
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   GetArgs
    Purpose:    Parse a string by spaces and return all the values as a table.
    Arguments:  text - The input string to parse
    Returns:    Table of parsed arguments
-----------------------------------------------------------------------------]]
function ABSync:GetArgs(text)
    -- set language variable
    local L = self.L
    
    -- initialize return table
    local args = {}
    
    -- check if text is valid
    if not text or text == "" then
        return args
    end
    
    -- trim leading and trailing whitespace
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    
    -- if still empty after trim, return empty table
    if text == "" then
        return args
    end
    
    -- parse the string by spaces
    for arg in string.gmatch(text, "%S+") do
        table.insert(args, arg)
    end
    
    --@debug@
    if self:GetDevMode() == true then 
        self:Print((ABSync.L["Parsed %d arguments from: '%s'"]):format(#args, text))
    end
    --@end-debug@
    
    -- finally return the parsed arguments
    return args
end

--[[---------------------------------------------------------------------------
    Function:   GetAutoResetMountFilters
    Purpose:    Get the auto reset mount filters status for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetAutoResetMountFilters()
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        return ActionBarSyncDB.profile[self.currentPlayerServer].autoResetMountFilters
    else
        self:Print((ABSync.L["Error Getting Auto Reset Mount Filters for %s!"]):format(tostring(self.currentPlayerServer)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetBarCountCurrentScan
    Purpose:    Get the count of action bars from player last scan.
-----------------------------------------------------------------------------]]
function ABSync:GetBarCountCurrentScan()
    -- track if we looped or not
    local barCount = 0
    
    -- loop over current scan data and get the bar names
    if ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData then
        for barName, _ in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData) do
            -- count bars as well loop
            barCount = barCount + 1
        end
    end

    -- finally return the count
    return tonumber(barCount)
end

--[[---------------------------------------------------------------------------
    Function:   GetMinimapButtonVisible
    Purpose:    Get whether the minimap button should be visible (defaults to true).
-----------------------------------------------------------------------------]]
function ABSync:GetMinimapButtonVisible()
    if not ActionBarSyncDB or not ActionBarSyncDB.global then
        return true -- default to showing the button
    end
    
    if ActionBarSyncDB.global.minimap and ActionBarSyncDB.global.minimap.hide ~= nil then
        return not ActionBarSyncDB.global.minimap.hide -- LibDBIcon uses 'hide' property, we want 'show'
    end
    
    return true -- default to showing the button
end

--[[---------------------------------------------------------------------------
    Function:   GetBarNames
    Purpose:    Return list of action bar names from the global storage.
-----------------------------------------------------------------------------]]
function ABSync:GetBarNames()
    -- track if we looped or not
    local barCount = #ActionBarSyncDB.global.actionBars or 0

    -- what we do if we didn't loop; over ride final return statement
    if barCount == 0 then
        return {ABSync.L["No Scan Completed"]}
    end

    -- finally return the list of bar names
    return ActionBarSyncDB.global.actionBars
end

--[[---------------------------------------------------------------------------
    Function:   GetBarValues
    Purpose:    Get the action bar values.
-----------------------------------------------------------------------------]]
function ABSync:GetBarValues()
    -- initialize temporary table
    -- local lookups = {}
    -- return ActionBarSyncDB.global.actionBars
    return {
        order = ABSync.actionBarOrder,
        data = ABSync.barNameLanguageTranslate,
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetButtonValues
    Purpose:    Get the action button values.
-----------------------------------------------------------------------------]]
function ABSync:GetButtonValues()
    return ABSync.constants.actionButtons
end

--[[---------------------------------------------------------------------------
    Function:   GetActionTypeValues
    Purpose:    Get the action type values.
-----------------------------------------------------------------------------]]
function ABSync:GetActionTypeValues()
    return ABSync.actionTypeLookup
end

--[[---------------------------------------------------------------------------
    Function:   GetBarToShare
    Purpose:    Check if a specific action bar is set to share for a specific player.
-----------------------------------------------------------------------------]]
function ABSync:GetBarToShare(barID, playerID)
    if not ActionBarSyncDB.global.barsToSync then
        return false
    elseif not ActionBarSyncDB.global.barsToSync[barID] then
        return false
    elseif not ActionBarSyncDB.global.barsToSync[barID][playerID] then
        return false
    else
        return next(ActionBarSyncDB.global.barsToSync[barID][playerID]) ~= nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetCurrentDateTime
    Purpose:    Get the current date and time in YYYYMMDDHHMMSS format.
-----------------------------------------------------------------------------]]
function ABSync:GetCurrentDateTime()
    return date("%Y%m%d%H%M%S")
end

--[[---------------------------------------------------------------------------
    Function:   GetDevMode
    Purpose:    Get the developer mode for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetDevMode()
    local defaultValue = false
    defaultValue = false
    --@debug@
    -- for development purposes, uncomment next line to always enable dev mode
    -- defaultValue = true
    --@end-debug@

    -- get player unique key; if not already set
    if not self.currentPlayerServerSpec and self.currentPlayerServerSpec ~= ABSync.L["Unknown"] then
        return defaultValue
    end

    -- check dev mode exists, if not set it to false
    if not ActionBarSyncDB.char then
        ActionBarSyncDB.char = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec] then
        ActionBarSyncDB.char[self.currentPlayerServerSpec] = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode = false
    end

    --@debug@
    -- ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode = defaultValue
    --@end-debug@

    -- finally return the dev mode value
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode
end

--[[---------------------------------------------------------------------------
    Function:   GetFramePosition
    Purpose:    Retrieve the position of a frame from the profile database.
    Parameters: frameName - the name of the frame
-----------------------------------------------------------------------------]]
function ABSync:GetFramePosition(frameName)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end
    
    -- set language variable
    local L = self.L

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        -- retrieve position data
        return ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName] or L["Unknown"]
    else
        return L["Unknown"]
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServer
    Purpose:    Get a formatted value with player and server name.
-----------------------------------------------------------------------------]]
function ABSync:GetKeyPlayerServer(nospace)
    -- verify variable's are setup
    self:SetKeyPlayerServer()

    if not nospace then nospace = true end

    if nospace == true then
        return self.currentPlayerServer
    else
        return self.currentPlayerServerWithSpace
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServerSpec
    Purpose:    Get a formatted value with player, server and current spec names.
-----------------------------------------------------------------------------]]
function ABSync:GetKeyPlayerServerSpec(nohyphen)
    -- check inputs
    if not nohyphen then nohyphen = false end

    -- verify variable is setup
    self:SetKeyPlayerServerSpec()

    -- finally return the special key
    if nohyphen then
        return self.currentPlayerServerSpecNoHyphens
    else
        return self.currentPlayerServerSpec
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetText
    Purpose:    Get localized text for a given key.

    Not used yet!
-----------------------------------------------------------------------------]]
function ABSync:GetText(key)
    local L = self.L
    return L[key] or key
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionBar
    Purpose:    Get the last action bar for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionBar()
    local returnVal = nil
    if ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.bar then
        returnVal = ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.bar
    end
    if returnVal == nil or returnVal == "" then
        returnVal = "actionbar1"
    end
    return returnVal
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionBarUtilities
    Purpose:    Get the last action bar for the Utilities tab for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionBarUtilities()
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities.removeButtons then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities.removeButtons = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities.removeButtons.bar then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities.removeButtons.bar = "actionbar1"
    end
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].utilities.removeButtons.bar or false
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionButton
    Purpose:    Get the last action button for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionButton()
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.btn or ""
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionID
    Purpose:    Get the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionID()
    -- first get a copy of the value
    local returnme = ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.id

    -- check for nil
    if returnme == nil or returnme == "" then
        returnme = 0
    end

    return returnme
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionName
    Purpose:    Get the last action name for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionName()
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.name
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionType
    Purpose:    Get the last action type for the current character. Defaults to "spell" if never set.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionType()
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.type or "spell"
end

--[[---------------------------------------------------------------------------
    Function:   GetLastScan
    Purpose:    Get the last scan date/time for the action bars.
-----------------------------------------------------------------------------]]
function ABSync:GetLastScan()
    -- make sure the current player spec key is set
    if not self.currentPlayerServerSpec then return false end
    
    -- set language variable
    local L = self.L

    -- make sure data structure exists
    local isSet = self:SetupCharDB()

    if isSet == true then
        return ActionBarSyncDB.char[self.currentPlayerServerSpec].lastScan or L["Never"]
    else
        self:Print((ABSync.L["Error Getting Last Scan for %s!"]):format(tostring(self.currentPlayerServerSpec)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetLastSynced
    Purpose:    Get the last synced time for the action bars to update the Last Synced field in the options for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastSynced()
    -- make sure the current player spec key is set
    if not self.currentPlayerServerSpec then return false end
    
    -- set language variable
    local L = self.L

    -- make sure data structure exists
    local isSet = self:SetupCharDB()

    if isSet == true then
        return ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced or L["Never"]
    else
        self:Print((ABSync.L["Error Getting Last Synced for %s!"]):format(tostring(self.currentPlayerServerSpec)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetObjectName
    Purpose:    Create frame object name with addon prefix.
-----------------------------------------------------------------------------]]
function ABSync:GetObjectName(postfix)
    if not postfix then postfix = "UnknownObjectName" end
    return ("%s%s"):format(ABSync.prefix, postfix)
end

--[[---------------------------------------------------------------------------
    Function:   GetRemoveActionFrame
    Purpose:    Create the remove action bar frame in the Utilities tab.
-----------------------------------------------------------------------------]]
function ABSync:GetPlacementErrorClearButton()
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        -- set default
        if not ActionBarSyncDB.profile[self.currentPlayerServer].placementErrorClearButton then
            ActionBarSyncDB.profile[self.currentPlayerServer].placementErrorClearButton = false
        end
        --@debug@
        -- if self:GetDevMode() == true then
        --     self:Print(("Get Placement Error Clear Button for %s is %s"):format(tostring(self.currentPlayerServer), tostring(ActionBarSyncDB.profile[self.currentPlayerServer].placementErrorClearButton)))
        -- end
        --@end-debug@

        -- return the current value
        return ActionBarSyncDB.profile[self.currentPlayerServer].placementErrorClearButton
    else
        self:Print((ABSync.L["Error Getting Placement Error Clear Button for %s!"]):format(tostring(self.currentPlayerServer)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetRandom6DigitNumber
    Purpose:    Generate a random 6-digit number.
    Returns:    A random number between 100000 and 999999
-----------------------------------------------------------------------------]]
function ABSync:GetRandom6DigitNumber()
    -- set language variable
    local L = self.L
    
    -- generate random 6-digit number (100000 to 999999)
    local randomNumber = math.random(100000, 999999)
    
    --@debug@
    -- if self:GetDevMode() == true then
    --     self:Print(("Generated random 6-digit number: %d"):format(randomNumber))
    -- end
    --@end-debug@
    
    return randomNumber
end

--[[---------------------------------------------------------------------------
    Function:   GetRestoreChoiceActionBar
    Purpose:    Get the last selected action bar for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetRestoreChoiceActionBar()
    -- basic char initialization
    self:InstantiateDBChar()

    -- make sure restore structure exists
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice = {}
    end
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.actionBar or ABSync.L["None"]
end

--[[---------------------------------------------------------------------------
    Function:   GetRestoreChoiceDateTime
    Purpose:    Get the last selected backup date/time for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetRestoreChoiceDateTime()
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice = {}
    end
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.backupDttm or ABSync.L["None"]
end

--[[---------------------------------------------------------------------------
    Function:   GetSyncOnLogon
    Purpose:    Get the sync on logon status for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetSyncOnLogon()
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        -- set default if not set
        if not ActionBarSyncDB.profile[self.currentPlayerServer].syncOnLogon then
            ActionBarSyncDB.profile[self.currentPlayerServer].syncOnLogon = false
        end

        -- return the value
        return ActionBarSyncDB.profile[self.currentPlayerServer].syncOnLogon
    else
        self:Print((ABSync.L["Error Getting Sync on Logon for %s!"]):format(tostring(self.currentPlayerServer)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetTab
    Purpose:    Get the current selected tab in the options.
-----------------------------------------------------------------------------]]
function ABSync:GetTab()
    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        local tabValue = ActionBarSyncDB.profile[self.currentPlayerServer].mytab or "introduction"
        --@debug@
        -- print("(GetTab) ID: " .. tostring(tabValue) .. " for " .. tostring(self.currentPlayerServer))
        --@end-debug@
        return tabValue
    else
        self:Print((ABSync.L["Error Getting Tab for %s!"]):format(tostring(self.currentPlayerServer)))
        return "introduction"
    end
end

--[[---------------------------------------------------------------------------
    Function:   IsSyncSet
    Purpose:    Check if a specific bar is set to sync for a specific player.
-----------------------------------------------------------------------------]]
function ABSync:IsSyncSet(barID, playerID)
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec] then
        return false
    elseif not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync then
        return false
    elseif not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] then
        return false
    else
        return ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] == playerID
    end
end