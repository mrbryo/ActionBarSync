--[[---------------------------------------------------------------------------
        INSERT IN ALPHABETICAL ORDER!!!
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServer
    Purpose:    Get a formatted value with player and server name.
-----------------------------------------------------------------------------]]
function ABSync:SetKeyPlayerServer()
    -- verify variable's are setup
    if not self.currentPlayerServer then
        self.currentPlayerServer = ""
    end
    if not self.currentPlayerServerWithSpace then
        self.currentPlayerServerWithSpace = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- set values
    self.currentPlayerServer = ("%s-%s"):format(unitName, unitServer)
    self.currentPlayerServerWithSpace = ("%s - %s"):format(unitName, unitServer)
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServerSpec
    Purpose:    Get a formatted value with player, server and current spec names.
-----------------------------------------------------------------------------]]
function ABSync:SetKeyPlayerServerSpec()
    -- verify variable is setup
    if not self.currentPlayerServerSpec then
        self.currentPlayerServerSpec = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- get characters current spec number
    local specializationIndex = C_SpecializationInfo.GetSpecialization()
    
    --@debug@
    print("Current spec index: " .. tostring(specializationIndex))
    --@end-debug@

    -- get the name of the current spec number
    local specId, specName, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)

    --@debug@
    print("Current spec name: " .. tostring(specName))
    --@end-debug@

    -- finally return the special key
    self.currentPlayerServerSpec = ("%s-%s-%s"):format(unitName, unitServer, specName)
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionBar
    Purpose:    Set the last action bar for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionBar(value)
    ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.bar = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionButton
    Purpose:    Set the last action button for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionButton(value)
    ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.btn = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionID
    Purpose:    Set the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionID(value)
    ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.id = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionName
    Purpose:    Set the last action name for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionName(value)
    ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.name = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionType
    Purpose:    Set the last action type for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionType(value)
    ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup.type = value
end

--[[---------------------------------------------------------------------------
    Function:   SetLastSyncedOnChar
    Purpose:    Set the last synced time for the action bars to update the Last Synced field in the options for the current character.
       TODO:    Format a base data value instead of a formatted value. Format it when needed later.
-----------------------------------------------------------------------------]]
function ABSync:SetLastSyncedOnChar()
    ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced = date("%Y-%m-%d %H:%M:%S")
end

