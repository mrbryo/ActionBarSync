--[[---------------------------------------------------------------------------
        INSERT IN ALPHABETICAL ORDER!!!
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   SetAutoResetMountFilters
    Purpose:    Set the auto reset mount filters status for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetAutoResetMountFilters(value)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        ActionBarSyncDB.profile[self.currentPlayerServer].autoResetMountFilters = value
    else
        self:Print(("Error Setting Auto Reset Mount Filters to: %s for %s!"):format(tostring(value), tostring(self.currentPlayerServer)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetAutoSyncData
    Purpose:    Set the auto scan data status for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetAutoScanData(value)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        ActionBarSyncDB.profile[self.currentPlayerServer].autoGetActionBarData = value
    else
        self:Print(("Error Setting Auto Sync Data to: %s"):format(tostring(value)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetDevMode
    Purpose:    Get the development mode status for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetDevMode(value)
    -- make sure the current player key is set
    if not self.currentPlayerServerSpec then return end

    -- set the dev mode value
    ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode = value
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
function ABSync:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        -- create index for this frame
        if not ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName] then
            ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName] = {}
        end
        
        -- Store position data
        ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName].point = point
        ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName].relativePoint = relativePoint
        ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName].xOffset = xOfs
        ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions[frameName].yOffset = yOfs

        -- return true since storage was successful
        return true
    end
end

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
    -- print("Current spec index: " .. tostring(specializationIndex))
    --@end-debug@

    -- get the name of the current spec number
    local specId, specName, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)

    --@debug@
    -- print("Current spec name: " .. tostring(specName))
    --@end-debug@

    -- finally return the special key
    if not specName then
        self.currentPlayerServerSpec = self.L["Unknown"]
    else
        self.currentPlayerServerSpec = ("%s-%s-%s"):format(unitName, unitServer, specName) or nil
        self.currentPlayerServerSpecNoHyphens = ("%s%s%s"):format(unitName, unitServer, specName) or nil
    end
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
    Function:   SetLastScan
    Purpose:    Set the last scan date/time for the action bars.
-----------------------------------------------------------------------------]]
function ABSync:SetLastScan(noscan)
    -- make sure the current player spec key is set
    if not self.currentPlayerServerSpec then return false end

    -- set language variable
    local L = self.L

    -- noscan should default to false and only set to true during db initialization
    if not noscan then noscan = false end
    
    -- make sure data structure exists
    local isSet = self:SetupCharDB()

    -- get current date/time or set to "Never" if noscan is true
    local value = noscan and ABSync.L["Never"] or date("%Y-%m-%d %H:%M:%S")

    if isSet == true then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastScan = value
        return true
    else
        self:Print(("Error Setting Last Scan to: %s for %s!"):format(tostring(value), tostring(self.currentPlayerServerSpec)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetLastSynced
    Purpose:    Set the last synced time for the action bars to update the Last Synced field in the options for the current character.
       TODO:    Format a base data value instead of a formatted value. Format it when needed later.
-----------------------------------------------------------------------------]]
function ABSync:SetLastSynced(nosync)
    -- make sure the current player spec key is set
    if not self.currentPlayerServerSpec then return false end
    
    -- set language variable
    local L = self.L

    -- nosync should default to false and only set to true during db initialization
    if not nosync then nosync = false end

    -- make sure data structure exists
    local isSet = self:SetupCharDB()
    
    -- get current date/time or set to "Never" if nosync is true
    local value = nosync and ABSync.L["Never"] or date("%Y-%m-%d %H:%M:%S")

    if isSet == true then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced = value
        return true
    else
        self:Print(("Error Setting Last Synced to: %s for %s!"):format(tostring(value), tostring(self.currentPlayerServerSpec)))
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetTab
    Purpose:    Set the current selected tab in the options.
-----------------------------------------------------------------------------]]
function ABSync:SetTab(key)
    --@debug@
    -- self:Print("(SetTab) Setting tab to: " .. tostring(key) .. " for " .. tostring(self.currentPlayerServer))
    --@end-debug@
    -- make sure the current player key is set
    if not self.currentPlayerServer then return end

    -- make sure data structure exists
    local isSet = self:SetupProfileDB()

    if isSet == true then
        ActionBarSyncDB.profile[self.currentPlayerServer].mytab = key
    else
        self:Print(("Error Setting Last tab: %s for %s!"):format(tostring(key), tostring(self.currentPlayerServer)))
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetupCharDB
    Purpose:    Ensure the character specific database structure is setup.
-----------------------------------------------------------------------------]]
function ABSync:SetupCharDB()
    -- make sure the current player spec key is set
    if not self.currentPlayerServerSpec then return false end

    -- create whole DB if missing
    if not ActionBarSyncDB then ActionBarSyncDB = {} end

    -- create char node if missing
    if not ActionBarSyncDB.char then ActionBarSyncDB.char = {} end

    -- add current character spec if missing
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec] then
        ActionBarSyncDB.char[self.currentPlayerServerSpec] = {}
    end

    -- return true if we get to here in the code
    return true
end

function ABSync:SetupGlobalDB()
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
function ABSync:SetupProfileDB()
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- create whole DB if missing
    if not ActionBarSyncDB then ActionBarSyncDB = {} end

    -- create profile node if missing
    if not ActionBarSyncDB.profile then ActionBarSyncDB.profile = {} end

    -- add current character if missing
    if not ActionBarSyncDB.profile[self.currentPlayerServer] then
        ActionBarSyncDB.profile[self.currentPlayerServer] = {}
    end

    -- initialize UI settings if they don't exist
    if not ActionBarSyncDB.profile[self.currentPlayerServer].ui then
        ActionBarSyncDB.profile[self.currentPlayerServer].ui = {}
    end
    if not ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions then
        ActionBarSyncDB.profile[self.currentPlayerServer].ui.positions = {}
    end

    -- return true if we get to here in the code
    return true
end