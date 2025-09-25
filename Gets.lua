--[[---------------------------------------------------------------------------
        INSERT IN ALPHABETICAL ORDER!!!
-----------------------------------------------------------------------------]]

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
    Function:   GetBarNames
    Purpose:    Return list of action bar names from the global storage.
-----------------------------------------------------------------------------]]
function ABSync:GetBarNames()
    -- track if we looped or not
    local barCount = #ActionBarSyncDB.global.actionBars or 0

    -- what we do if we didn't loop; over ride final return statement
    if barCount == 0 then
        return {L["No Scan Completed"]}
    end

    -- finally return the list of bar names
    return ActionBarSyncDB.global.actionBars
end

--[[---------------------------------------------------------------------------
    Function:   GetBarValues
    Purpose:    Get the action bar values.
-----------------------------------------------------------------------------]]
function ABSync:GetBarValues()
    return ActionBarSyncDB.global.actionBars
end

--[[---------------------------------------------------------------------------
    Function:   GetButtonValues
    Purpose:    Get the action button values.
-----------------------------------------------------------------------------]]
function ABSync:GetButtonValues()
    return ActionBarSyncDB.global.actionButtons
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
function ABSync:GetBarToShare(barName, playerID)
    if not ActionBarSyncDB.global.barsToSync then
        return false
    elseif not ActionBarSyncDB.global.barsToSync[barName] then
        return false
    elseif not ActionBarSyncDB.global.barsToSync[barName][playerID] then
        return false
    else
        return next(ActionBarSyncDB.global.barsToSync[barName][playerID]) ~= nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetBarToSync
    Purpose:    Check if a specific bar is set to sync for a specific player.
-----------------------------------------------------------------------------]]
function ABSync:GetBarToSync(barName, playerID)
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync then
        return false
    elseif not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barName] then
        return false
    else
        return ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barName] == playerID
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetDevMode
    Purpose:    Get the developer mode for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetDevMode()
    -- set language variable
    local L = self.L

    -- get player unique key; if not already set
    if not self.currentPlayerServerSpec and self.currentPlayerServerSpec ~= L["Unknown"] then
        return false
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
    ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode = true
    --@end-debug@

    -- finally return the dev mode value
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode
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
function ABSync:GetKeyPlayerServerSpec()
    -- verify variable is setup
    self:SetKeyPlayerServerSpec()

    -- finally return the special key
    return self.currentPlayerServerSpec
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionBar
    Purpose:    Get the last action bar for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionBar()
    return ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.bar or ""
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
    Function:   GetLastSyncedOnChar
    Purpose:    Get the last synced time for the action bars to update the Last Synced field in the options for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastSyncedOnChar()
    -- store response
    local response = ""

    -- check for nil or blank
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced or ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced == "" or ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced == nil then
        response = L["Never"]

    -- return the last synced time
    else
        -- if last synced time exists then return the formatted date
        response = ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced
    end

    -- finally return data
    return response
end

--[[---------------------------------------------------------------------------
    Function:   GetTab
    Purpose:    Get the current selected tab in the options.
-----------------------------------------------------------------------------]]
function ABSync:GetTab()
    return ActionBarSyncDB.profile[self.currentPlayerServer].mytab or "introduction"
end