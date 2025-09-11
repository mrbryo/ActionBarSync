--[[ ------------------------------------------------------------------------
	Title: 			ActionBarSync.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	Main program for ActionBarSync addon.
-----------------------------------------------------------------------------]]

-- initial with existing addon registration; only a pointer...not a copy
local ABSync = _G.ABSync

-- enable localization
ABSync.localeSilent = false
local L = LibStub("AceLocale-3.0"):GetLocale(ABSync.optionLocName, ABSync.localeSilent)

-- addon access to UI elements
ABSync.ui = {
    editbox = {},
    scroll = {},
    group = {},
    dropdown = {},
}

-- colors
ABSync.colors = {
    white = "|cffffffff",
    yellow = "|cffffff00",
    green = "|cff00ff00",
    blue = "|cff0000ff",
    purple = "|cffff00ff",
    red = "|cffff0000",
    orange = "|cffff7f00",
    gray = "|cff7f7f7f",
    label = "|cffffd100"
}

-- addon ui columns
ABSync.columns = {
    lookupHistory = {
        { name = "Type", key = "type", width = 0.20 },      -- 20
        { name = "ID", key = "id", width = 0.20 },          -- 40
        { name = "Name", key = "name", width = 0.50 },      -- 90
        { name = "Has", key = "has", width = 0.10 },        -- 100
    }
}

-- lookup values for action button lookup
ABSync.actionTypeLookup = {
    ["spell"] = L["spell"],
    ["item"] = L["item"],
    ["macro"] = L["macro"],
    ["summonpet"] = L["summonpet"],
    ["summonmount"] = L["summonmount"]
}

-- translate blizzard Action Bar settings names to LUA Code Names
ABSync.blizzardTranslate = {
    ["MultiBarBottomLeft"] = L["actionbar2"],
    ["MultiBarBottomRight"] = L["actionbar3"],
    ["MultiBarRight"] = L["actionbar4"],
    ["MultiBarLeft"] = L["actionbar5"],
    ["MultiBar5"] = L["actionbar6"],
    ["MultiBar6"] = L["actionbar7"],
    ["MultiBar7"] = L["actionbar8"],
    ["Action"] = L["actionbar1"]
}

-- lookup for source on sync details
ABSync.profiletype = {
    ["profile"] = "profile",
    ["global"] = "global"
}

-- lookup macro types
ABSync.MacroType = {
    general = "general",
    character = "character",
}

-- ui tabs
ABSync.uitabs = {
    ["tabs"] = {
        ["about"] = "About",
        ["instructions"] = "Instructions",
        ["share"] = "Share",
        ["sync"] = "Sync",
        ["last_sync_errors"] = "Last Sync Errors",
        ["lookup"] = "Lookup",
        ["backup"] = "Backup/Restore",
        ["developer"] = "Developer",
    },
    ["order"] = {
        "about",
        "instructions",
        "share",
        "sync",
        "last_sync_errors",
        "lookup",
        "backup",
        "developer",
    }
}

-- initialize the mount db
if not ActionBarSyncMountDB then
    ActionBarSyncMountDB = {}
end

--[[---------------------------------------------------------------------------
    Function:   ABSync:OnInitialize
    Purpose:    Initialize the addon and set up default values.
-----------------------------------------------------------------------------]]
function ABSync:OnInitialize()
    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")

    -- initialize the db
    self.db = LibStub("AceDB-3.0"):New("ActionBarSyncDB")

    -- check dev mode
    if not self.db.char then
        self.db.char = {}
    end
    if not self.db.char.isDevMode then
        self.db.char.isDevMode = false
    end

    --@debug@
    if self.db.char.isDevMode == true then self:Print(L["initializing"]) end
    --@end-debug@

    -- Instantiate Option Table
    self.ActionBarSyncOptions = {
        name = L["actionbarsynctitle"],
        handler = ABSync,
        type = "group",
        args = {}
    }
   
    -- get the ace db options for profile management
    self.ActionBarSyncOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    
    -- register the options
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ABSync.optionLocName, self.ActionBarSyncOptions)
    
    -- create a title for the addon option section
    local optionsTitle = L["actionbarsynctitle"]
    
    -- add the options to the ui
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ABSync.optionLocName, optionsTitle, nil)
    
    -- register some slash commands
    self:RegisterChatCommand("abs", "SlashCommand")
    
    --@debug@ leave at end of function
    if self.db.char.isDevMode == true then self:Print(L["initialized"]) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDB
    Purpose:    Ensure the DB has all the necessary values. Can run anytime to check and fix all data with default values.
-----------------------------------------------------------------------------]]
function ABSync:InstantiateDB(barName)
    -- get current playerID
    local playerID = self:GetPlayerNameKey()

    -- option which lets the user pick to check if they bars are out of sync after logon
    if not self.db.profile.checkOnLogon then
        self.db.profile.checkOnLogon = false
    end

    -- actionBars holds just a sorted array of action bar names; needed under global and profile
    if not self.db.profile.actionBars then
        self.db.profile.actionBars = {}
    end
    if not self.db.global.actionBars then
        self.db.global.actionBars = {}
    end

    -- auto reset mount journal filters flag
    if not self.db.profile.autoResetMountFilters then
        self.db.profile.autoResetMountFilters = false
    end

    -- currentBarData holds the last scan of data fetched from the action bars for the current character; hence stored in char
    if not self.db.char.currentBarData then
        self.db.char.currentBarData = {}
    end 

    -- character specific sync error data
    if not self.db.char.syncErrors then
        self.db.char.syncErrors = {}
    end

    -- character specific date/time of last scan, defaults to never
    if not self.db.char.lastScan then
        self.db.char.lastScan = L["never"]
    end

    -- character specific last synced date/time, defaults to never
    if not self.db.char.lastSynced then
        self.db.char.lastSynced = L["never"]
    end

    -- backup of action bar data so a user can restore
    if not self.db.char.backup then
        self.db.char.backup = {}
    end

    -- character last sync error date/time, represents the date/time of the errors captured
    if not self.db.char.lastSyncErrorDttm then
        self.db.char.lastSyncErrorDttm = L["never"]
    end

    -- character last share scan error data
    if not self.db.char.lastShareScanData then
        self.db.char.scanErrors = {}
    end

    -- character specific action lookup data
    if not self.db.char.actionLookup then
        self.db.char.actionLookup = {
            name = "",
            id = "",
            type = ""
        }
    end

    -- character specific lookup history
    if not self.db.char.lookupHistory then
        self.db.char.lookupHistory = {}
    end

    -- set default for max history lookup records
    if not self.db.char.lookupHistoryMaxRecords then
        self.db.char.lookupHistoryMaxRecords = 20
    end

    -- character last diff data
    if not self.db.char.lastDiffData then
        self.db.char.lastDiffData = {}
    end

    -- instantiate barsToSync if it doesn't exist
    if not self.db.global.barsToSync then
        self.db.global.barsToSync = {}
    end

    -- instantiate barsToSync also under the character profile
    if not self.db.profile.barsToSync then
        self.db.profile.barsToSync = {}
    end

    if barName ~= nil then
        -- if the barName is not in barsToSync then add it with default value of false
        if not self.db.global.barsToSync[barName] then
            self.db.global.barsToSync[barName] = {}
        end

        -- instantiate bar owner if it doesn't exist
        if not self.db.global.barsToSync[barName][playerID] then
            self.db.global.barsToSync[barName][playerID] = {}
        end

        -- if the barName is missing in the profile barToSync data, add it with default value of false
        if not self.db.profile.barsToSync[barName] then
            self.db.profile.barsToSync[barName] = false
        end
    end

    if not self.db.profile.mytab then
        self.db.profile.mytab = "instructions"
    end

    --@debug@
    -- if self.db.char.isDevMode == true then
    --     if barName ~= nil then
    --         self:Print(("(%s) Instantiated DB for bar: %s and Player: %s"):format("InstantiateDB", barName, playerID))
    --     else
    --         self:Print(("(%s) Instantiated DB for player: %s (bars skipped)"):format("InstantiateDB", playerID))
    --     end
    -- end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionName
    Purpose:    Get the last action name for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionName()
    return self.db.char.actionLookup.name
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionName
    Purpose:    Set the last action name for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionName(value)
    self.db.char.actionLookup.name = value
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionID
    Purpose:    Get the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionID()
    -- first get a copy of the value
    local returnme = self.db.char.actionLookup.id

    -- check for nil
    if returnme == nil or returnme == "" then
        returnme = 0
    end

    return returnme
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionID
    Purpose:    Set the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionID(value)
    self.db.char.actionLookup.id = value
end

--[[---------------------------------------------------------------------------
    Function:   GetActionTypeValues
    Purpose:    Get the action type values.
-----------------------------------------------------------------------------]]
function ABSync:GetActionTypeValues()
    return ABSync.actionTypeLookup
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionType
    Purpose:    Get the last action type for the current character. Defaults to "spell" if never set.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionType()
    return self.db.char.actionLookup.type or "spell"
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionType
    Purpose:    Set the last action type for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionType(value)
    self.db.char.actionLookup.type = value
end

--[[---------------------------------------------------------------------------
    Function:   InsertLookupHistory
    Purpose:    Insert a new entry into the lookup history and only keeping the max records set by the user.
-----------------------------------------------------------------------------]]
function ABSync:InsertLookupHistory(info)
    -- insert the record
    table.insert(self.db.char.lookupHistory, 1, info)

    -- if +1 of max records exist and the table has more then reduce the table size
    local nextRecord = self.db.char.lookupHistoryMaxRecords + 1
    if #self.db.char.lookupHistory > self.db.char.lookupHistoryMaxRecords then
        for i = nextRecord, #self.db.char.lookupHistory do
            table.remove(self.db.char.lookupHistory, i)
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetActionData
    Purpose:    Get the action data for a specific action ID and type.
-----------------------------------------------------------------------------]]
function ABSync:GetActionData(actionID, actionType)
    -- store results
    local lookupInfo = {
        name = L["unknown"],
        has = L["no"]
    }

    if actionType == "spell" then
        -- get spell details: data, name, hasSpell
        local spellInfo = self:GetSpellDetails(actionID)

        -- update details
        lookupInfo.name = spellInfo.name
        lookupInfo.has = spellInfo.hasSpell
    elseif actionType == "item" then
        -- get item details
        local itemInfo = self:GetItemDetails(actionID)

        -- update details
        lookupInfo.name = itemInfo.name
        lookupInfo.has = itemInfo.hasItem
    elseif actionType == "macro" then
        -- get macro details
        local macroInfo = self:GetMacroDetails(actionID)
        
        -- update details
        lookupInfo.name = macroInfo.blizData.name
        lookupInfo.has = macroInfo.hasMacro
    elseif actionType == "summonpet" then
        -- get pet data
        local petInfo = self:GetPetDetails(actionID)

        -- update details
        lookupInfo.name = petInfo.name
        lookupInfo.has = petInfo.hasPet
    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        local mountInfo = self:GetMountinfo(actionID)

        -- update name
        lookupInfo.name = mountInfo.name

        -- get mount journal index
        local mountJournalIndex = self:MountIDToOriginalIndex(mountInfo.mountID)

        -- has mount
        lookupInfo.has = mountJournalIndex and "Yes" or "No"
    end

    -- finally return results
    return lookupInfo
end

--[[---------------------------------------------------------------------------
    Function:   LookupAction
    Purpose:    Look up the action based on the last entered action type and ID.
-----------------------------------------------------------------------------]]
function ABSync:LookupAction()
    -- get the action type
    local actionType = self:GetLastActionType()
    
    -- get the action ID
    local actionID = self:GetLastActionID()

    --@debug@
    -- "Looking up Action - Type: %s - ID: %s"
    if self.db.char.isDevMode == true then self:Print((L["lookingupactionnotifytext"]):format(actionType, actionID)) end
    --@end-debug@

    -- instantiate lookup storage
    local lookupInfo = {
        type = actionType,
        id = actionID,
        name = L["unknown"],
        has = L["no"]
    }

    -- perform lookup based on type
    local actionData = self:GetActionData(actionID, actionType)
    if actionData then
        lookupInfo.name = actionData.name
        lookupInfo.has = actionData.has
    end

    -- insert record to lookupHistory
    self:InsertLookupHistory(lookupInfo)

    -- update scroll region for lookup history
    self:UpdateLookupHistory()
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarsCount
    Purpose:    Get the count of action bars for a specific source.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarsCount(source)
    -- initialize variable
    local count = 0
    local tmpdb = {}

    -- point to correct db branch based on source
    if source == self.profiletype["profile"] then
        tmpdb = self.db.profile

    -- always get global if source doesn't match a valid type
    else
        tmpdb = self.db.global
    end

    -- if actionBars variable exist then continue
    if tmpdb.actionBars then
        -- if actionBars is not a table then return 0
        if tostring(type(tmpdb.actionBars)) == "table" then
            count = #tmpdb.actionBars
        end
    end

    -- finally return the count
    return tonumber(count)
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarNames
    Purpose:    Return the list/table of action bar names.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarNames(source)
    -- check to make sure a data fetch has happened, if not return No Scan Completed
    local barNames = {}
    
    -- get a count of actionbars
    local count = self:GetActionBarsCount(source)

    -- if actionBars does not exist
    if count == 0 then
        -- add an entry to let user know a can has not been done; this will get overwritten once a scan is done.
        table.insert(barNames, L["noscancompleted"])

        -- finally return bar names
        return barNames
    else
        return self.db.global.actionBars
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetLastSyncedOnChar
    Purpose:    Get the last synced time for the action bars to update the Last Synced field in the options for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastSyncedOnChar()
    -- store response
    local response = ""

    -- check for nil or blank
    if not self.db.char.lastSynced or self.db.char.lastSynced == "" or self.db.char.lastSynced == nil then
        response = L["never"]

    -- return the last synced time
    else
        -- if last synced time exists then return the formatted date
        response = self.db.char.lastSynced
    end

    -- finally return data
    return response
end

--[[---------------------------------------------------------------------------
    Function:   SetLastSyncedOnChar
    Purpose:    Set the last synced time for the action bars to update the Last Synced field in the options for the current character.
       TODO:    Format a base data value instead of a formatted value. Format it when needed later.
-----------------------------------------------------------------------------]]
function ABSync:SetLastSyncedOnChar()
    self.db.char.lastSynced = date("%Y-%m-%d %H:%M:%S")
end

--[[---------------------------------------------------------------------------
    Function:   GetPlayerNameFormatted
    Purpose:    Get the owner of the specified action bar.
-----------------------------------------------------------------------------]]
function ABSync:GetPlayerNameFormatted()
    local unitName, unitServer = UnitFullName("player")
    return unitName .. " - " .. unitServer
end

--[[---------------------------------------------------------------------------
    Function:   FormatDateString
    Purpose:    Convert a date string from YYYYMMDDHHMISS format to YYYY, Mon DD HH:MI:SS format.
-----------------------------------------------------------------------------]]
function ABSync:FormatDateString(dateString)
    -- validate input
    if not dateString or type(dateString) ~= "string" or string.len(dateString) ~= 14 then
        return "Invalid Date"
    end
    
    -- extract components from YYYYMMDDHHMISS
    local year = string.sub(dateString, 1, 4)
    local month = tonumber(string.sub(dateString, 5, 6))
    local day = string.sub(dateString, 7, 8)
    local hour = string.sub(dateString, 9, 10)
    local minute = string.sub(dateString, 11, 12)
    local second = string.sub(dateString, 13, 14)
    
    -- month names
    local monthNames = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    }
    
    -- validate month
    if month < 1 or month > 12 then
        return "Invalid Date"
    end
    
    -- format and return the readable date string
    return string.format("%s, %s %s %s:%s:%s", year, monthNames[month], day, hour, minute, second)
end

--[[---------------------------------------------------------------------------
    Function:   GetPlayerNameKey
    Purpose:    Get the formatted key needed to track shared bars based on character and spec.
-----------------------------------------------------------------------------]]
function ABSync:GetPlayerNameKey()
    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- get characters current spec number
    local specializationIndex = C_SpecializationInfo.GetSpecialization()

    -- get the name of the current spec number
    local specId, name, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)

    -- finally return the special key
    return ("%s-%s-%s"):format(unitName, unitServer, name)
end

--[[---------------------------------------------------------------------------
    Function:   GetBarToShare
    Purpose:    Check if a specific action bar is set to share for a specific player.
-----------------------------------------------------------------------------]]
function ABSync:GetBarToShare(barName, playerID)
    if not self.db.global.barsToSync then
        return false
    elseif not self.db.global.barsToSync[barName] then
        return false
    elseif not self.db.global.barsToSync[barName][playerID] then
        return false
    else
        return next(self.db.global.barsToSync[barName][playerID]) ~= nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetBarToShare
    Purpose:    Set the bar to share for the current global db settings.
-----------------------------------------------------------------------------]]
function ABSync:SetBarToShare(barName, value)
    --@debug@
    -- print(("(%s) Key: %s, Value: %s"):format("SetBarToShare", tostring(barName), tostring(value)))
    --@end-debug@

    -- initialize variables
    local barName = barName or L["unknown"]
    local playerID = self:GetPlayerNameKey()

    -- check for input barName, if it doesn't exist then let user know and return false
    if not self.db.global.barsToSync[barName] then
        -- initialize missing key dialog
        StaticPopupDialogs["ACTIONBARSYNC_INVALID_KEY"] = {
            text = (L["actionbarsync_invalid_key_text"]):format(barName),
            button1 = L["ok"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 2,
        }
        StaticPopup_Show("ACTIONBARSYNC_INVALID_KEY")
        return false
    end

    -- run db initialize again but pass in barName to make sure all keys are setup for this barName
    self:InstantiateDB(barName)

    -- track if bar is found in profile.currentBarData
    local barFound = false
    
    -- make sure currentBarData exists and has button data
    local buttonCount = 0
    for _ in pairs(self.db.char.currentBarData[barName]) do
        buttonCount = buttonCount + 1
        -- only need to loop once
        break
    end
    if buttonCount > 0 then
        barFound = true
    end

    -- if currentBarData is emtpy then let user know they must trigger a sync first
    if barFound == false then
        StaticPopupDialogs["ACTIONBARSYNC_NO_SCAN"] = {
            text = (L["actionbarsync_no_scan_text"]):format(barName),
            button1 = L["ok"],
            button2 = L["cancel"],
            timeout = 0,
            hideOnEscape = true,
            preferredIndex = 2,
            OnAccept = function(self)
                StaticPopup_Hide("ACTIONBARSYNC_NO_SCAN")
                ABSync:GetActionBarData()
            end,
        }
        StaticPopup_Show("ACTIONBARSYNC_NO_SCAN")

        -- just return to cancel the rest of the function
        return false
    end

    -- if the value is true, add the bar data to the buttonsToSync table under the barsToSync[barName] table
    if value == true then
        -- add the bar data
        self.db.global.barsToSync[barName][playerID] = self.db.char.currentBarData[barName]
    else
        -- remove all the button data
        self.db.global.barsToSync[barName][playerID] = {}
    end

    --@debug@
    if self.db.char.isDevMode == true then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToShare", barName, (value and "Yes" or "No"))) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   GetBarToSync
    Purpose:    Check if a specific bar is set to sync for a specific player.
-----------------------------------------------------------------------------]]
function ABSync:GetBarToSync(barName, playerID)
    if not self.db.profile.barsToSync then
        return false
    elseif not self.db.profile.barsToSync[barName] then
        return false
    else
        return self.db.profile.barsToSync[barName] == playerID
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetBarToSync
    Purpose:    Update the db for current profile when the user changes the values in the options on which bars to sync.
-----------------------------------------------------------------------------]]
function ABSync:SetBarToSync(key, value)
    --@debug@
    print(("Key: %s, Value: %s"):format(tostring(key), tostring(value)))
    --@end-debug@

    -- initialize variables
    local barName = L["unknown"]

    -- initialize missing key dialog
    StaticPopupDialogs["ACTIONBARSYNC_INVALID_KEY"] = {
        text = (L["actionbarsync_invalid_key_text"]):format(key),
        button1 = L["ok"],
        timeout = 15,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- check profile.actionBars
    if not self.db.profile.actionBars then
        self.db.profile.actionBars = {}
    end

    -- check for input key, if it doesn't exist then let user know and return false
    if not self.db.profile.actionBars[key] then
        StaticPopup_Show("ACTIONBARSYNC_INVALID_KEY")
        return false
    end

    -- set bar name
    barName = self.db.profile.actionBars[key]
    
    -- track if bar is found in currentBarData
    local barFound = false

    -- check for profile.barsToSync
    if not self.db.profile.barsToSync then
        self.db.profile.barsToSync = {}
    end

    -- check for the barName in profile.barsToSync
    if not self.db.profile.barsToSync[barName] then
        self.db.profile.barsToSync[barName] = false
    end

    -- set the bar to sync on input value to the profile: true or false based on the value passed into this function
    self.db.profile.barsToSync[barName] = value

    --@debug@ let the user know the value is changed only when developing though
    if self.db.char.isDevMode == true then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToSync", barName, (value and "Yes" or "No"))) end
    --@end-debug@
end

-- NEXT: check BeginSync and make sure backup is what it should be. Need additional UI tab to allow user to see backup history and to be able to restore from backup.

--[[---------------------------------------------------------------------------
    Function:   BeginSync
    Purpose:    Start the sync process.
    Steps:      
        1. Check if there is any bars selected to sync.
        2. If no bars selected then show a dialog and stop processing.
        3. If bars are selected, ask the user for a note. If they click OK proceed. Or stop if they click cancel.
        4. If the backup note dialog is shown it will trigger the next step, backup process, if the user clicks ok button. Nothing happens if they click cancel.
-----------------------------------------------------------------------------]]
function ABSync:BeginSync()
    -- add dialog to ask for backup reason
    StaticPopupDialogs["ACTIONBARSYNC_BACKUP_NOTE"] = {
        text = L["actionbarsync_backup_note_text"],
        button1 = L["ok"],
        button2 = L["cancel"],
        hasEditBox = true,
        maxLetters = 64,
        OnAccept = function(self)
            -- capture the reason
            local backupReason = self.EditBox:GetText()
            -- start the actual backup passing in needed data
            local backupdttm = ABSync:TriggerBackup(backupReason)
            -- sync the bars
            ABSync:UpdateActionBars(backupdttm)
        end,
        OnCancel = function(self)
            StaticPopup_Show("ACTIONBARSYNC_SYNC_CANCELLED")
        end,
        OnShow = function(self)
            self.EditBox:SetText(L["beginsyncdefaultbackupreason"])
            self.EditBox:SetFocus()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- add dialog to let user know sync was cancelled
    StaticPopupDialogs["ACTIONBARSYNC_SYNC_CANCELLED"] = {
        text = L["actionbarsync_sync_cancelled_text"],
        button1 = L["ok"],
        timeout = 15,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- add dialog to let user know they must select bars to sync first
    StaticPopupDialogs["ACTIONBARSYNC_NO_SYNCBARS"] = {
        text = L["actionbarsync_no_syncbars_text"],
        button1 = L["ok"],
        timeout = 15,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- track testing
    local barsToSync = false
    
    -- count entries
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        if syncOn ~= false then
            barsToSync = true
            break
        end
    end

    -- if no data found, show a message and return
    if not barsToSync then
        StaticPopup_Show("ACTIONBARSYNC_NO_SYNCBARS")
    else
        -- if data found, proceed with backup; ask user for backup note
        StaticPopup_Show("ACTIONBARSYNC_BACKUP_NOTE")
    end
end

--[[---------------------------------------------------------------------------
    Function:   TriggerBackup
    Purpose:    Compare two action bar button data tables.
-----------------------------------------------------------------------------]]
function ABSync:TriggerBackup(note)
    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")

    -- set up backup timestamp
    local backupdttm = date("%Y%m%d%H%M%S")
    self:SetLastSyncedOnChar()

    -- track any errors in the data
    local errors = {}

    -- make sure data path exists
    if not self.db.char.backup then
        self.db.char.backup = {}
    end

    -- force bar refresh
    self:GetActionBarData()

    -- loop over the values and act on true's
    local backupData = {}

    -- for completeness sake, make sure records are found to be synced...this is actually done in the calling parent but if I decide to call this function elsewhere better check!
    local syncDataFound = false
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        if syncOn ~= false then
            --@debug@
            if self.db.char.isDevMode == true then self:Print((L["triggerbackup_notify"]):format(barName)) end
            --@end-debug@

            -- make sync data found
            syncDataFound = true

            -- instantiate the barName index
            backupData[barName] = {}

            -- get the current bar data for the current barName; not the profile bar data to sync
            for buttonID, buttonData in pairs(self.db.char.currentBarData[barName]) do
                backupData[barName][buttonID] = buttonData
            end
        end
    end

    -- add error if no sync data found
    if syncDataFound == false then
        table.insert(errors, L["triggerbackup_no_sync_data_found"])
    end

    -- count number of backups
    local backupCount = 0
    for _ in pairs(self.db.char.backup) do
        backupCount = backupCount + 1
    end

    -- if more than 9 then remove the oldest 1
    -- next retrieves the key of the first entry in the backup table and then sets it to nil which removes it
    while backupCount > 9 do
        local oldestBackup = next(self.db.char.backup)
        self.db.char.backup[oldestBackup] = nil
        backupCount = backupCount - 1
    end

    -- add backup to db
    local backupEntry = {
        dttm = backupdttm,
        note = note or L["triggerbackup_no_note_provided"],
        error = errors,
        data = backupData,
    }
    table.insert(self.db.char.backup, backupEntry)

    -- finally return a value
    return backupdttm
end

--[[---------------------------------------------------------------------------
    Function:   RemoveButtonAction
    Purpose:    Remove an action from a button.
-----------------------------------------------------------------------------]]
function ABSync:RemoveButtonAction(buttonID)
    PickupAction(tonumber(buttonID))
    ClearCursor()
end

--[[---------------------------------------------------------------------------
    Function:   MountJournalFilterBackup
    Purpose:    Backup the current mount journal filter settings.

    NOT USED YET
-----------------------------------------------------------------------------]]
function ABSync:MountJournalFilterBackup()
    -- backup current filter settings
    self.db.char.mountJournalFilters = {
        collected = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED),
        notCollected = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED),
        unusable = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE),
    }
end

--[[---------------------------------------------------------------------------
    Function:   MountJournalFilterReset
    Purpose:    Reset the mount journal filter settings to default.
-----------------------------------------------------------------------------]]
function ABSync:MountJournalFilterReset()
    -- reset default filter settings
    C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
    C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, false)
    C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, false)
    C_MountJournal.SetAllSourceFilters(true)
    C_MountJournal.SetSearch("")
    C_MountJournal.SetAllTypeFilters(true)

    -- notify user
    self:Print("Mount Journal filters have been set to show all collected mounts.")
end

--[[---------------------------------------------------------------------------
    Function:   MountJournalFilterRestore
    Purpose:    Restore the mount journal filter settings from backup.

    NOT USED YET
-----------------------------------------------------------------------------]]
function ABSync:MountJournalFilterRestore()
    -- restore previous filter settings
    if self.db.char.mountJournalFilters then
        C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, self.db.char.mountJournalFilters.collected)
        C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, self.db.char.mountJournalFilters.notCollected)
        C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, self.db.char.mountJournalFilters.unusable)
    end
end

--[[---------------------------------------------------------------------------
    Function:   MountIdToOriginalIndex
    Purpose:    Get the original index of a mount by its ID.
    Credit:     MountJournalEnhanced authors!

    Usage:      Should call MountJournalFilterReset() before calling this but should add code to let user know if mount is not found and ask if filter should be restored to default or our own "default".
-----------------------------------------------------------------------------]]
function ABSync:MountIDToOriginalIndex(mountID)
    -- get the current number from the journal
    local count = C_MountJournal.GetNumDisplayedMounts()
    for i = 1, count do
        local displayedMountID = select(12, C_MountJournal.GetDisplayedMountInfo(i))
        if displayedMountID == mountID then
            return i
        end
    end

    return nil
end

--[[---------------------------------------------------------------------------
    Function:   UpdateActionBars
    Purpose:    Compare the sync action bar data to the current action bar data and override current action bar buttons.
    Todo:       Streamline this fuction to use LookUp action to remove duplicated code.
-----------------------------------------------------------------------------]]
function ABSync:UpdateActionBars(backupdttm)
    -- store differences
    local differences = {}
    local differencesFound = false

    -- compare the global barsToSync data to the user's current action bar data
    -- loop over only the bars the character wants to sync
    for barName, sharedby in pairs(self.db.profile.barsToSync) do
        if sharedby ~= false then
            -- print(("Bar Name: %s, Shared By: %s, Button ID: %s"):format(barName, sharedby, tostring(buttonID)))
            -- loop over the shared data
            for buttonID, buttonData in pairs(self.db.global.barsToSync[barName][sharedby]) do
                -- define what values to check
                local checkValues = { "sourceID", "actionType", "subType" }
                
                -- loop over checkValues
                for _, testit in ipairs(checkValues) do
                    if buttonData[testit] ~= self.db.char.currentBarData[barName][buttonID][testit] then
                        differencesFound = true
                        table.insert(differences, {
                            shared = self.db.global.barsToSync[barName][sharedby][buttonID],
                            current = self.db.char.currentBarData[barName][buttonID],
                            barName = barName,
                            sharedBy = sharedby,
                        })
                        break
                    end
                end
            end
        end
    end

    -- do we have differences?
    if differencesFound == false then
        -- show popup telling user no differences found
        StaticPopupDialogs["ACTIONBARSYNC_NO_DIFFS_FOUND"] = {
            text = L["actionbarsync_no_diffs_found_text"],
            button1 = L["ok"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ACTIONBARSYNC_NO_DIFFS_FOUND")
    else
        -- capture last diff data
        self.db.char.lastDiffData = differences

        -- track any errors
        local errors = {}

        -- track if a mount issue occurred
        local mountIssue = false
        local mountIssueCount = 0
        local mountCount = 0

        -- loop over differences and apply changes
        for _, diffData in ipairs(differences) do
            -- create readable button name
            -- local buttonName = (L["updateactionbars_button_name_template"]):format(diffData.barName, diffData.position)

            -- instantiate standard error fields
            local err = {
                barName = diffData.barName,
                barPosn = diffData.shared.barPosn,
                buttonID = diffData.shared.actionID,
                type = diffData.shared.actionType,
                name = diffData.shared.name,
                id = diffData.shared.sourceID,
                sharedby = diffData.sharedBy,
                msg = ""
            }

            --@debug@
            if self.db.char.isDevMode == true then self:Print("Item Type: " .. tostring(diffData.shared.actionType)) end
            --@end-debug@

            -- track if something was updated to action bar
            local buttonUpdated = false

            --[[ process based on type ]]

            -- if unknown then shared action bar has no button there, if current char has a button in that position remove it
            if err.type == L["unknown"] and diffData.current.name ~= L["unknown"] then
                -- call function to remove a buttons action
                self:RemoveButtonAction(err.buttonID)

                -- button was updated
                buttonUpdated = true

            elseif err.type == "spell" then

                -- report error if player does not have the spell
                if diffData.shared.hasSpell == L["no"] then
                    -- update message to show character doesn't have the spell
                    err["msg"] = L["unavailable"]

                    -- insert the error record into tracking table
                    table.insert(errors, err)

                -- proceed if player has the spell
                -- make sure we have a name that isn't unknown
                elseif err.name ~= L["unknown"] then
                    -- set the action bar button to the spell
                    C_Spell.PickupSpell(err.name)
                    PlaceAction(tonumber(err.buttonID))
                    ClearCursor()

                    -- button was updated
                    buttonUpdated = true

                -- else should never trigger but set message to not found and add to tracking table
                else
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end

            elseif err.type == "item" then

                -- does player have the item
                local itemCount = self:GetItemCount(err.id)

                -- if the user has the item, then add it to their action bar as long as the name is not unknown
                if itemCount > 0 then
                    -- item exists
                    if err.name ~= L["unknown"] and diffData.shared.isToy == false then
                        -- set the action bar button to the item
                        C_Item.PickupItem(err.name)
                        PlaceAction(tonumber(err.buttonID))
                        ClearCursor()

                        -- button was updated
                        buttonUpdated = true

                    -- else should never trigger but just in case set message to not found and add to tracking table
                    else
                        err["msg"] = L["notfound"]
                        table.insert(errors, err)
                    end

                -- could be a toy
                elseif diffData.shared.isToy == true then
                    -- print("toy found: " .. checkItemName)
                    -- set the action bar button to the toy
                    C_ToyBox.PickupToyBoxItem(err.id)
                    PlaceAction(tonumber(err.buttonID))
                    ClearCursor()

                    -- button was updated
                    buttonUpdated = true

                -- if player doesn't have item then log as error
                else
                    err["msg"] = L["notinbags"]
                    table.insert(errors, err)
                end
            elseif err.type == "macro" then
                -- if the shared macro is character based then no way to get the details so don't place it as it will get this characters macro in the same position, basically wrong macro then
                if diffData.shared.macroType == ABSync.MacroType.character then
                    err["msg"] = L["charactermacro"]
                    table.insert(errors, err)
                
                -- if macro name is found proceed
                elseif err.name ~= L["unknown"] then
                    -- set the action bar button to the macro
                    PickupMacro(err.name)
                    PlaceAction(tonumber(err.buttonID))
                    ClearCursor()

                    -- button was updated
                    buttonUpdated = true

                -- if name is unknown then check the id...use the id to place the action
                elseif err.id ~= -1 then
                    PickupMacro(err.id)
                    PlaceAction(tonumber(err.buttonID))
                    ClearCursor()

                -- if macro name or id is not found then record error
                else
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end
            elseif err.type == "summonpet" then
                -- if pet name is found proceed
                if err.id ~= -1 then
                    -- set the action bar button to the pet
                    C_PetJournal.PickupPet(err.id)
                    PlaceAction(tonumber(err.buttonID))
                    ClearCursor()

                    -- button was updated
                    buttonUpdated = true
                else
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end
            elseif err.type == "summonmount" then
                -- get mount journal index
                local mountJournalIndex = self:MountIDToOriginalIndex(diffData.shared.mountID)
                if mountJournalIndex then
                    C_MountJournal.Pickup(mountJournalIndex)
                    PlaceAction(tonumber(err.buttonID))
                    ClearCursor()

                    -- button was updated
                    buttonUpdated = true
                else
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)

                    -- update mount issue flag
                    mountIssue = true
                    mountIssueCount = mountIssueCount + 1
                end

                -- count mounts
                mountCount = mountCount + 1

            -- proper response if action type is not recognized
            else
                -- add error about unknown item type
                err["msg"] = L["unknownitemtype"]
                table.insert(errors, err)
                print("Unknown Item Type: " .. tostring(err.type))
            end

            -- remove if not found and button has an action
            if diffData.current.sourceID ~= -1 and buttonUpdated == false then
                PickupAction(tonumber(err.buttonID))
                ClearCursor()
            end
        end

        -- count number of sync error records
        local syncErrorCount = 0
        for _ in pairs(self.db.char.syncErrors) do
            syncErrorCount = syncErrorCount + 1
        end

        -- if more than 9 then remove the oldest 1
        -- since we use table.insert it always adds records to the end of the table and the oldest is at the top so keep deleting until we get to 9 records
        -- because we will insert one after this step
        while syncErrorCount > 9 do
            table.remove(self.db.char.syncErrors, 1)
            syncErrorCount = syncErrorCount - 1
        end

        -- store errors
        if #errors > 0 then
            --@debug@
            if self.db.char.isDevMode == true then self:Print((L["actionbarsync_sync_errors_found"]):format(backupdttm)) end
            --@end-debug@

            -- make sure syncErrors exists
            if not self.db.char.syncErrors then
                self.db.char.syncErrors = {}
            end
            
            -- write to db
            table.insert(self.db.char.syncErrors, {
                key = backupdttm,
                errors = errors
            })

            -- make sure lastSyncErrorDttm exists
            if not self.db.char.lastSyncErrorDttm then
                self.db.char.lastSyncErrorDttm = ""
            end

            -- update lastSyncErrorDttm
            self.db.char.lastSyncErrorDttm = backupdttm

            -- trigger update for options UI
            -- LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)
        end

        -- show popup if mount issue is true
        if mountIssue == true then
            StaticPopupDialogs["ACTIONBARSYNC_MOUNT_ISSUE"] = {
                text = (L["actionbarsync_mount_issue_text"]):format(mountIssueCount, mountCount),
                button1 = L["ok"],
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("ACTIONBARSYNC_MOUNT_ISSUE")
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetItemCount
    Purpose:    Retrieve the item count for a specific button ID.
-----------------------------------------------------------------------------]]
function ABSync:GetItemCount(id)
    local itemCount = C_Item.GetItemCount(id)
    return itemCount
end

--[[---------------------------------------------------------------------------
    Function:   CharacterHasSpell
    Purpose:    Check if the current character has a specific spell.
-----------------------------------------------------------------------------]]
function ABSync:CharacterHasSpell(spellID)
    local hasSpell = C_Spell.IsCurrentSpell(spellID) and L["yes"] or L["no"]
    return hasSpell
end

--[[---------------------------------------------------------------------------
    Function:   GetSpellDetails
    Purpose:    Retrieve spell information based on the spell ID.
-----------------------------------------------------------------------------]]
function ABSync:GetSpellDetails(spellID)
    -- get spell info: name, iconID, originalIconID, castTime, minRange, maxRange, spellID
    local spellData = C_Spell.GetSpellInfo(spellID)
    local spellName = spellData and spellData.name or L["unknown"]
    local hasSpell = self:CharacterHasSpell(spellID)

    -- finally return the data collected
    return {
        blizData = {
            name = spellData and spellData.name or L["unknown"],
            iconID = spellData and spellData.iconID or -1,
            originalIconID = spellData and spellData.originalIconID or -1,
            castTime = spellData and spellData.castTime or -1,
            minRange = spellData and spellData.minRange or -1,
            maxRange = spellData and spellData.maxRange or -1,
            spellID = spellData and spellData.spellID or -1
        },
        name = spellName,
        hasSpell = hasSpell
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetItemDetails
    Purpose:    Retrieve item information based on the item ID.
-----------------------------------------------------------------------------]]
function ABSync:GetItemDetails(itemID)
    -- fetch blizzard item details
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(itemID)

    -- need a string as itemName or error occurs if the item actually doesn't exist
    local checkItemName = itemName or L["unknown"]

    -- does player have the item
    local itemCount = self:GetItemCount(itemID)

    -- if checkItemName is unknown then see if its a toy
    local isToy = false
    local toyData = {}
    local toyID, toyName, toyIcon, toyIsFavorite, toyHasFanfare, toyItemQuality = C_ToyBox.GetToyInfo(itemID)
    if toyName then
        -- print(("toy found: %s (%s)"):format(tostring(toyName or L["unknown"]), toyID))
        checkItemName = toyName or L["unknown"]
        isToy = true
        toyData = {
            id = toyID,
            name = toyName,
            icon = toyIcon,
            isFavorite = toyIsFavorite,
            hasFanfare = toyHasFanfare,
            quality = toyItemQuality
        }
    end

    -- finally return the data collected
    return {
        blizData = {
            itemName = itemName or L["unknown"],
            itemLink = itemLink or L["unknown"],
            itemQuality = itemQuality or L["unknown"],
            itemLevel = itemLevel or -1,
            itemMinLevel = itemMinLevel or -1,
            itemType = itemType or L["unknown"],
            itemSubType = itemSubType or L["unknown"],
            itemStackCount = itemStackCount or -1,
            itemEquipLoc = itemEquipLoc or L["unknown"],
            itemTexture = itemTexture or -1,
            sellPrice = sellPrice or -1,
            classID = classID or -1,
            subclassID = subclassID or -1,
            bindType = bindType or -1,
            expansionID = expansionID or -1,
            setID = setID or -1,
            isCraftingReagent = isCraftingReagent or false,
        },
        itemID = itemID,
        finalItemName = checkItemName,
        isToy = isToy,
        toyData = toyData,
        hasItem = (itemCount > 0) and L["yes"] or L["no"],
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMacroDetails
    Purpose:    Retrieve macro information based on the macro ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMacroDetails(macroID)
    -- get macro information: name, iconTexture, body
    -- isLocal removed in patch 3.0.2
    local macroName, iconTexture, body = GetMacroInfo(macroID)

    -- macro type: general or character
    local macroType = ABSync.MacroType.general
    if tonumber(macroID) > 120 then
        macroType = ABSync.MacroType.character
    end

    -- finally return the data collected
    return {
        blizData = {
            name = macroName or L["unknown"],
            icon = iconTexture or -1,
            body = body or L["unknown"]
        },
        macroType = macroType,
        id = macroID,
        hasMacro = macroName and L["yes"] or L["no"],
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetPetDetails
    Purpose:    Retrieve pet information based on the pet ID.
-----------------------------------------------------------------------------]]
function ABSync:GetPetDetails(petID)
    -- requires a pet GUID
    local allPetIDs = C_PetJournal.GetOwnedPetIDs()

    -- was a valid pet id found
    local petFound = false

    -- see if petID is in the list
    for _, ownedPetID in ipairs(allPetIDs) do
        if ownedPetID == petID then
            -- print(("Pet ID %s found!"):format(tostring(petID)))
            petFound = true
            break
        end
    end

    -- get pet information
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable
    if petFound == true then
        speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
    end

    -- finally return the data collected
    return {
        blizData = {
            speciesID = speciesID or -1,
            customName = customName or L["unknown"],
            level = level or -1,
            xp = xp or -1,
            maxXp = maxXp or -1,
            displayID = displayID or -1,
            isFavorite = isFavorite or false,
            name = name or L["unknown"],
            icon = icon or -1,
            petType = petType or L["unknown"],
            creatureID = creatureID or -1,
            sourceText = sourceText or L["unknown"],
            description = description or L["unknown"],
            isWild = isWild or false,
            canBattle = canBattle or false,
            isTradeable = isTradeable or false,
            isUnique = isUnique or false,
            obtainable = obtainable or false
        },
        petID = petID,
        name = name or L["unknown"],
        hasPet = name and L["yes"] or L["no"]
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMountinfo
    Purpose:    Retrieve mount information based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMountinfo(mountID)
    -- first call to get mount information based on the action bar action id
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, sourceMountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)

    -- make sure certain values are not nil
    name = name or L["unknown"]

    -- get more mount data looking for how to pickup a mount with the cursor correctly
    local displayIDs = C_MountJournal.GetAllCreatureDisplayIDsForMountID(mountID)

    -- get more mount data!!!
    local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)
    local extraInfo = {
        creatureDisplayInfoID = creatureDisplayInfoID or -1,
        description = description or L["unknown"],
        source = source or L["unknown"],
        isSelfMount = isSelfMount or false,
        mountTypeID = mountTypeID or -1,
        uiModelSceneID = uiModelSceneID or -1,
        animID = animID or -1,
        spellVisualKitID = spellVisualKitID or -1,
        disablePlayerMountPreview = disablePlayerMountPreview or false
    }

    -- and get more data!!!
    local mountCreatureDisplayInfoLink = L["unknown"]
    if spellID then
        mountCreatureDisplayInfoLink = C_MountJournal.GetMountLink(spellID)
    end

    -- get the mountID to displayIndex mapping
    local mountLookup = C_MountJournal.GetMountIDs()

    -- loop over the values to get the key
    local displayIndex = -1
    for journalIndex, journalMountID in pairs(mountLookup) do
        if journalMountID == mountID then
            displayIndex = journalIndex
            break
        end
    end

    --@debug@
    -- if self.db.char.isDevMode == true then self:Print(("Mount Name: %s - ID: %s - Display Index: %s"):format(name, mountID, tostring(displayIndex))) end
    --@end-debug@

    -- finally return the spell name
    return {
        blizData = {
            name = name,
            spellID = spellID or -1,
            icon = icon or -1,
            isActive = isActive or false,
            isUsable = isUsable or false,
            sourceType = sourceType or -1,
            isFavorite = isFavorite or false,
            isFactionSpecific = isFactionSpecific or false,
            faction = faction or -1,
            shouldHideOnChar = shouldHideOnChar or false,
            isCollected = isCollected or false,
            mountID = sourceMountID or -1,
            isSteadyFlight = isSteadyFlight or false
        },
        name = name or L["unknown"],
        sourceID = sourceMountID or -1,
        displayIndex = displayIndex or -1,
        mountID = mountID,
        displayIDs = displayIDs or {},
        extraInfo = extraInfo or {},
        displayInfoLink = mountCreatureDisplayInfoLink
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetActionButtonData
    Purpose:    Retrieve action button data based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetActionButtonData(actionID, btnName)
    -- get action type and ID information
    local actionType, infoID, subType = GetActionInfo(actionID)

    -- instantiate the return table
    local returnData = {
        blizData = {},
        actionType = actionType or L["unknown"],
        subType = subType or L["unknown"],
        actionID = actionID,
        infoID = infoID,
        buttonID = buttonID,
        btnName = btnName,
        name = L["unknown"],
        icon = -1,
        sourceID = -1,
        unknownActionType = false,

        -- location in the action bar: 1-12
        barPosn = tonumber(string.match(btnName, "(%d+)$")) or -1,
    }

    -- get the name of the id based on action type
    if actionType == "spell" then
        -- get spell details: data, name, hasSpell
        local spellInfo = self:GetSpellDetails(infoID)

        --@debug@
        -- for key, value in pairs(spellInfo) do
        --     self:Print(("spellInfo Key: %s - Value Type: %s"):format(key, type(value)))
        -- end
        --@end-debug@

        -- assign data
        returnData.name = spellInfo.name
        returnData.icon = spellInfo.blizData.icon
        returnData.sourceID = spellInfo.blizData.spellID
        returnData.blizData = spellInfo.blizData
        returnData.hasSpell = spellInfo.hasSpell

    -- process items
    elseif actionType == "item" then
        -- get item details
        local itemInfo = self:GetItemDetails(infoID)

        -- assign data
        returnData.name = itemInfo.finalItemName
        returnData.icon = itemInfo.blizData.itemTexture
        returnData.sourceID = itemInfo.itemID
        returnData.blizData = itemInfo.blizData
        returnData.isToy = itemInfo.isToy
        returnData.toyData = itemInfo.toyData
        returnData.hasItem = itemInfo.hasItem

    elseif actionType == "macro" then
        -- get macro details
        local macroInfo = self:GetMacroDetails(infoID)

        -- assign data
        returnData.name = macroInfo.blizData.name
        returnData.icon = macroInfo.blizData.icon
        returnData.body = macroInfo.blizData.body
        returnData.sourceID = macroInfo.id
        returnData.blizData = macroInfo.blizData
        returnData.macroType = macroInfo.macroType
        returnData.hasMacro = macroInfo.hasMacro

    elseif actionType == "summonpet" then
        -- get pet data
        local petInfo = self:GetPetDetails(infoID)

        -- assign data
        returnData.name = petInfo.name
        returnData.icon = petInfo.blizData.icon
        returnData.blizData = petInfo.blizData
        returnData.sourceID = petInfo.petID
        returnData.hasPet = petInfo.hasPet

    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        local mountInfo = self:GetMountinfo(infoID)

        -- assign data
        returnData.name = mountInfo.name
        returnData.icon = mountInfo.blizData.icon
        returnData.sourceID = mountInfo.sourceID
        returnData.blizData = mountInfo.blizData
        returnData.displayIndex = mountInfo.displayIndex
        returnData.mountID = mountInfo.mountID
        returnData.displayIDs = mountInfo.displayIDs
        returnData.extraInfo = mountInfo.extraInfo

    -- action button is empty
    elseif actionType == nil then
        -- leave as unknown since no action is assigned to the button
    else
        -- actually unknown, this addon doesn't know what to do with it!
        -- add unknown action type property
        returnData.unknownActionType = true
        -- Localized: Action Button '%s' has an unrecognized type of '%s'. Adding issue to Scan Errors and skipping...
        self:Print((L["unknown_action_type"]):format(btnName, tostring(actionType)))
    end

    -- finally return the data
    return returnData
end

--[[---------------------------------------------------------------------------
    Function:   RefreshMountDB
    Purpose:    For development purposes only! Refresh the mount database for the current player.
-----------------------------------------------------------------------------]]
function ABSync:RefreshMountDB()
    -- get playerID
    -- no need to include spec in playerID for mount db since the mounts are not spec-specific
    local playerID = self:GetPlayerNameFormatted()

    -- clear the existing mount database
    ActionBarSyncMountDB[playerID] = {}

    --[[ create sorted list of mount ID's ]]
    
    -- get all the mount id's
    local mountLookup = C_MountJournal.GetMountIDs()

    -- build table of mount ID's as keys and the index as the key's value
    local reversed = {}
    for journalIndex, journalMountID in pairs(mountLookup) do
        reversed[journalIndex] = journalMountID
    end

    -- build a table of just mount ID's for sorting them
    local keys = {}
    for journalMountID in pairs(reversed) do
        table.insert(keys, journalMountID)
    end

    -- sort the keys
    table.sort(keys)

    -- create sorted mountIDLookup table
    local mountIDLookup = {}
    for _, journalMountID in ipairs(keys) do
        table.insert(mountIDLookup, reversed[journalMountID])
    end

    -- clear unused tables
    wipe(reversed)
    wipe(keys)

    -- loop over sorted mount ID's
    for journalMountID, journalIndex in pairs(mountIDLookup) do
        -- get mount data
        local mountInfo = self:GetMountinfo(journalMountID)

        -- add index to mountInfo and the associated mount ID to confirm data from GetMountinfo aligns with the GetMountIDs function
        mountInfo.journalIndex = journalIndex
        mountInfo.journalMountID = journalMountID

        -- add to table
        table.insert(ActionBarSyncMountDB[playerID], mountInfo)
        -- ActionBarSyncMountDB[playerID][tostring(journalMountID)] = mountInfo
    end

    -- notify user its done
    self:Print("Mount DB Refreshed! Reload the UI by using this command: /reload")
end

--[[---------------------------------------------------------------------------
    Function:   ClearMountDB
    Purpose:    Clear the mount database for the current character.
-----------------------------------------------------------------------------]]
function ABSync:ClearMountDB()
    -- get playerID
    -- no need to include spec in playerID for mount db since the mounts are not spec-specific
    local playerID = self:GetPlayerNameFormatted()

    -- clear the existing mount database
    ActionBarSyncMountDB[playerID] = {}

    -- notify user its done
    self:Print("Mount DB Cleared! Reload the UI by using the button (to update data now) or wait to logout on this character.")
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarData
    Purpose:    Fetch current action bar button data.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarData()
    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")
    local WoW10 = StdFuncs:IsWoW10()

    -- reset actionBars
    self.db.global.actionBars = {}
    self.db.profile.actionBars = {}
    
    -- reset currentBarData
    self.db.char.currentBarData = {}

    -- get player unique id
    local playerID = self:GetPlayerNameKey()

    -- track scan errors
    local errs = {
        lastScan = self.db.char.lastActionBarScanDttm,
        data = {}
    }
    
    -- get action bar details
    for btnName, btnData in pairs(_G) do
        -- filter out by proper naming of the action bars done by blizzard
        -- need to know if this changes based on language!
        if string.find(btnName, "^ActionButton%d+$") or string.find(btnName, "^MultiBarBottomLeftButton%d+$") or string.find(btnName, "^MultiBarBottomRightButton%d+$") or string.find(btnName, "^MultiBarLeftButton%d+$") or string.find(btnName, "^MultiBarRightButton%d+$") or string.find(btnName, "^MultiBar%d+Button%d+$") then
            -- make up a name for each bar using the button names by removing the button number
            local barName = string.gsub(btnName, L["getactionbardata_button_name_template"], "")

            -- translate and replace barName into the blizzard visible name in settings for the bars
            local barName = ABSync.blizzardTranslate[barName] or L["unknown"]

            -- skip bar if unknown
            if barName == L["unknown"] then
                self:Print(("Action Bar Button '%s' is not recognized as a valid action bar button. Skipping..."):format(barName))

            -- continue if barname is known
            else
                -- get action ID and type information
                local actionID = btnData:GetPagedID()

                -- process more data for info based on actionType
                local buttonData = self:GetActionButtonData(actionID, btnName)

                -- check if barName is already in the global actionBars data
                local barNameInserted = false
                for _, name in ipairs(self.db.global.actionBars) do
                    if name == barName then
                        barNameInserted = true
                        break
                    end
                end

                -- add the bar name to the global actionBars table if it doesn't exist
                if barNameInserted == false then
                    table.insert(self.db.global.actionBars, barName)
                end

                -- check if barName is already in the profile actionBars data
                barNameInserted = false
                for _, name in ipairs(self.db.profile.actionBars) do
                    if name == barName then
                        barNameInserted = true
                        break
                    end
                end

                -- add the bar name to the profile actionBars table if it doesn't exist
                if barNameInserted == false then
                    table.insert(self.db.profile.actionBars, barName)
                end                

                -- check if barName is already in currentBarData
                local barNameInserted = false
                for name, _ in pairs(self.db.char.currentBarData) do
                    if name == barName then
                        barNameInserted = true
                        break
                    end
                end

                -- add the bar name to the currentBarData table if it doesn't exist
                if barNameInserted == false then
                    self.db.char.currentBarData[barName] = {}
                end

                -- insert the info table into the current action bar data
                self.db.char.currentBarData[barName][tostring(actionID)] = buttonData
            end
        end
    end

    -- sort the actionBars table
    table.sort(self.db.global.actionBars, function(a, b)
        return a < b
    end)

    -- update db
    self.db.char.lastScan = date("%Y-%m-%d %H:%M:%S")
    
    -- sync keys of actionBars to barsToSync and barOwner
    for _, barName in ipairs(self.db.global.actionBars) do
       self:InstantiateDB(barName)
    end

    -- sync the updated data into the sync settings only when the same character is triggering the update
    -- for barName, barData in pairs(self.db.global.barsToSync) do
    for barName, barData in pairs(self.db.global.barsToSync) do
        -- if the bar data table for the current player is empty set checked to false, otherwise, true; next() checks the next record of a table and if it's nil then its empty and we want a false value for empty tables; true means its populated because the use decided to share it
        local checked = next(barData[playerID]) ~= nil
        -- self:Print(("Bar Name: %s, Character: %s, is shared? %s"):format(barName, playerID, tostring(checked)))

        -- call existing function when the share check boxes are clicked; pass in existing checked value
        self:SetBarToShare(barName, checked)
    end

    -- trigger update for options UI
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)

    -- let user know its done
    --@debug@
    if self.db.char.isDevMode == true then self:Print(L["getactionbardata_final_notification"]) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   EnableDevelopment
    Purpose:    Enable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:EnableDevelopment()
    self.db.char.isDevMode = true
    self:Print("Development Mode: Enabled")
end

--[[---------------------------------------------------------------------------
    Function:   DisableDevelopment
    Purpose:    Disable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:DisableDevelopment()
    self.db.char.isDevMode = false
    self:Print("Development Mode: Disabled")
end

--[[---------------------------------------------------------------------------
    Function:   SlashCommand
    Purpose:    Respond to all slash commands.
-----------------------------------------------------------------------------]]
function ABSync:SlashCommand(text)
    -- if no text is provided, show the options dialog
    if text == nil or text == "" then
        self:ShowUI()
        -- LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
        return
    end
    -- get args
    for arg in string.gmatch(self:GetArgs(text), "%S+") do
        if arg:lower() == "options" then
            LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
        elseif arg:lower() == "sync" then
            self:BeginSync()
        elseif arg:lower() == "enablemodedeveloper" then
            if not self.db.char.isDevMode or self.db.char.isDevMode == false then
                self:EnableDevelopment()
            else
                self:DisableDevelopment()
            end
        elseif arg:lower() == "refreshmountdb" then
            if self.db.char.isDevMode == true then
                self:RefreshMountDB()
            end
        -- elseif arg:lower() == "spec" then
        --     local specializationIndex = C_SpecializationInfo.GetSpecialization()
        --     self:Print(("Current Specialization Index: %s"):format(tostring(specializationIndex)))
        --     local specId, name, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)
        --     self:Print(("Specialization ID: %d, Name: %s"):format(specId, name or L["unknown"]))
        -- elseif arg:lower() == "test" then
            -- local mountIDs = C_MountJournal.GetMountIDs()
            -- for midx, mountID in ipairs(mountIDs) do
            --     -- local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, sourceMountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
            --     -- self:Print(("(Test) Mount - Name: %s - ID: %d - Source ID: %d"):format(name, mountID, sourceMountID))
            --     print(("<Test> Mount - ID: %d (%d)"):format(mountID, midx))
            -- end
        end
    end

    -- self:Print(L["slashcommand_none_setup_yet"])
    -- if msg:lower() == "options" then
    --     self:Print("Opening Options...")
    --     LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
    -- else
    --     -- self:Print("Get Action Bar Data!")
    --     -- ABSync:ActionBarData()
    --     -- self:Print("Action Bar Sync - Slash Command does nothing currently!")
    --     ABSync:ShowSpreadsheetFrame()
    -- end
end

--[[---------------------------------------------------------------------------
    Function:   EventPlayerLogin
    Purpose:    Handle functionality which is best or must wait for the PLAYER_LOGIN event.
-----------------------------------------------------------------------------]]
function ABSync:EventPlayerLogin() 
    -- check for initial db setup
    self:InstantiateDB(nil)
end

--[[---------------------------------------------------------------------------
    Function:   EventPlayerLogout
    Purpose:    Handle functionality which is best or must wait for the PLAYER_LOGOUT event.
-----------------------------------------------------------------------------]]
function ABSync:EventPlayerLogout()
    --@debug@
    if self.db.char.isDevMode == true then self:Print(L["registerevents_player_logout"]) end
    --@end-debug@

    -- clear currentBarData and actionBars when not in developer mode
    if self.db.char.isDevMode == false then
        ABSync.db.profile.currentBarData = {}
        ABSync:ClearMountDB()
    end
end

--[[---------------------------------------------------------------------------
    Function:   RegisterEvents
    Purpose:    Register all events for the addon.
-----------------------------------------------------------------------------]]
function ABSync:RegisterEvents()
    if self.db.char.isDevMode == true then self:Print(L["registerevents_starting"]) end
	-- Hook to Action Bar On Load Calls
	-- self:Hook("ActionBarController_OnLoad", true)
	-- Hook to Action Bar On Event Calls
	-- self:Hook("ActionBarController_OnEvent", true)
    -- Register Events
    self:RegisterEvent("ADDON_LOADED", function()
        --@debug@
        if self.db.char.isDevMode == true then self:Print(L["registerevents_addon_loaded"]) end
        --@end-debug@
    end)

    self:RegisterEvent("PLAYER_LOGIN", function()
        --@debug@
        if self.db.char.isDevMode == true then self:Print(L["registerevents_player_login"]) end
        --@end-debug@

        self:EventPlayerLogin()
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReload)
        print(("Event - %s, isInitialLogin: %s, isReload: %s"):format(event,tostring(isInitialLogin), tostring(isReload)))
        -- only run these commands if this is the initial login
        if isInitialLogin == true then
            --@debug@
            if self.db.char.isDevMode == true then ABSync:Print(L["registerevents_player_entering_world"]) end
            --@end-debug@

            -- run db initialize again but pass in barName to make sure all keys are setup for this barName
            ABSync:InstantiateDB(nil)

            -- get action bar data automatically if user has opted in through the settings checkbox
            if ABSync.db.profile.autoGetActionBarData or ABSync.db.char.lastScan == L["never"] then
                ABSync:GetActionBarData()
            end
        end
    end)

    self:RegisterEvent("PLAYER_LOGOUT", function()
        ABSync:EventPlayerLogout()
    end)

    self:RegisterEvent("VARIABLES_LOADED", function()
        --@debug@
        if self.db.char.isDevMode == true then self:Print(L["registerevents_variables_loaded"]) end
        --@end-debug@
    end)

    --[[ trying to process cursor changed is CRAZY...giving up for now... ]]
    -- self:RegisterEvent("CURSOR_CHANGED", function(isDefault, newCursorType, oldCursorType, oldCursorVirtualID)
    --     self:Print("Event - CURSOR_CHANGED")
    --     --@debug@
    --     if ABSync.isDevMode == false then
    --         ABSync:PrintMountInfo(isDefault, newCursorType, oldCursorType, oldCursorVirtualID)
    --     end
    --     --@end-debug@
    -- end)

	-- self:RegisterEvent("ACTIONBAR_UPDATE_STATE", function()
	-- 	self:Print("Event - ACTIONBAR_UPDATE_STATE")
	-- end)
end

--[[---------------------------------------------------------------------------
    Function:   OnEnable
    Purpose:    Trigger functionality when addon is enabled.
-----------------------------------------------------------------------------]]
function ABSync:OnEnable()
    -- Check the DB
    if not self.db then
        self:Print(L["onenable_db_not_found"])
    end

    -- Register Events
    self:RegisterEvents()

    -- leave at end of function
    self:Print(L["enabled"])
end

--[[---------------------------------------------------------------------------
    Function:   OnDisable
    Purpose:    Trigger code when addon is disabled.
-----------------------------------------------------------------------------]]
function ABSync:OnDisable()
    -- TODO: Unregister Events?
    self:Print(L["disabled"])

    -- same clean up should occur when disabled
    ABSync:EventPlayerLogout()
end

--[[---------------------------------------------------------------------------
    Function:   GetCharacterList
    Purpose:    Get a list of all characters in the database.

    NOT USED
-----------------------------------------------------------------------------]]
-- function ABSync:GetCharacterList()
--     -- Get the list of characters from the database
--     local characterList = {}

--     -- loop over the bar characters
--     for charName, charData in pairs(self.db.profiles) do
--         table.insert(characterList, charName)
--     end

--     -- sort the character list
--     table.sort(characterList)

--     -- finally return it
--     return characterList
-- end

--[[---------------------------------------------------------------------------
    Function:   AddSyncRow
    Purpose:    Add a row to the sync table.

    NOT USED
-----------------------------------------------------------------------------]]
-- function ABSync:AddSyncRow(scroll, columnWidth, syncFrom, syncBarName)
--     -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
--     local AceGUI = LibStub("AceGUI-3.0")

--     -- create the row group
--     local rowGroup = AceGUI:Create("SimpleGroup")
--     rowGroup:SetLayout("Flow")
--     rowGroup:SetFullWidth(true)

--     -- create delete checkbox column
--     local deleteCell = AceGUI:Create("CheckBox")
--     deleteCell:SetValue(false)
--     deleteCell:SetCallback("OnValueChanged", function(_, _, value)
--         -- handle delete checkbox logic
--         self:Print(("Delete checkbox for character '%s' for bar '%s' was clicked!"):format(syncFrom, syncBarName))
--     end)
--     deleteCell:SetWidth(columnWidth[1])
--     rowGroup:AddChild(deleteCell)

--     -- add label to show character to sync from
--     local characterCell = AceGUI:Create("Label")
--     characterCell:SetText(syncFrom)
--     characterCell:SetRelativeWidth(columnWidth[2])
--     rowGroup:AddChild(characterCell)

--     -- add label to show action bar name to sync
--     local barCell = AceGUI:Create("Label")
--     barCell:SetText(syncBarName)
--     barCell:SetRelativeWidth(columnWidth[3])
--     rowGroup:AddChild(barCell)

--     -- add the row to the scroll region
--     scroll:AddChild(rowGroup)
-- end

--[[---------------------------------------------------------------------------
    Function:   AddAboutLeftHandLine
    Purpose:    Add a line to the left hand side of the About frame.
-----------------------------------------------------------------------------]]
function ABSync:AddAboutLeftHandLine(parent, data)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- standards for left hand side
    local labelWidth = 0.25
    local infoWidth = 0.75
    local offset = 0.02

    -- create the row group
    local rowFrame = AceGUI:Create("SimpleGroup")
    rowFrame:SetLayout("Flow")
    rowFrame:SetFullWidth(true)
    parent:AddChild(rowFrame)

    -- create the label and add it
    local labelFrame = AceGUI:Create("InteractiveLabel")
    labelFrame:SetText(("%s:"):format(data.label))
    labelFrame:SetRelativeWidth(labelWidth)
    
    -- add the label
    rowFrame:AddChild(labelFrame)

    -- create the edit box and add it
    local infoFrame = AceGUI:Create("EditBox")
    infoFrame:SetText(data.text)
    infoFrame:SetRelativeWidth(infoWidth)
    rowFrame:AddChild(infoFrame)

    -- create info box and add it
    if data.tip.disable == false then
        -- create row grouping
        local infoRow = AceGUI:Create("SimpleGroup")
        infoRow:SetLayout("Flow")
        infoRow:SetFullWidth(true)
        rowFrame:AddChild(infoRow)

        -- create empty label
        local emptyLabel = AceGUI:Create("Label")
        emptyLabel:SetText("")
        emptyLabel:SetRelativeWidth(labelWidth + offset)
        infoRow:AddChild(emptyLabel)

        -- create info label
        local infoBox = AceGUI:Create("Label")
        infoBox:SetText(data.tip.text)
        infoBox:SetRelativeWidth(infoWidth - offset)
        infoRow:AddChild(infoBox)
    end

    -- disable edit box
    infoFrame:SetDisabled(data.disable)
end

--[[---------------------------------------------------------------------------
    Function:   CreateAboutFrame
    Purpose:    Create the About frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateAboutFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- tooltip text
    data = {
        order = {
            "author",
            "version",
            "patreon",
            "coffee",
            "issues",
            "localization",
        },
        text = {
            ["author"] = {
                label = "Author",
                text = C_AddOns.GetAddOnMetadata("ActionBarSync", "Author"),
                disable = true,
                tip = {
                    disable = true,
                    text = "",
                },
            },
            ["version"] = {
                label = "Version",
                text = C_AddOns.GetAddOnMetadata("ActionBarSync", "Version"),
                disable = true,
                tip = {
                    disable = true,
                    text = ""
                },
            },
            ["patreon"] = {
                label = "Patreon",
                text = "https://www.patreon.com/Bryo",
                disable = false,
                tip = {
                    disable = false,
                    text = "If you like this addon and want to support me, please consider becoming a patron."
                }
            },
            ["coffee"] = {
                label = "Buy Me a Coffee",
                text = "https://www.buymeacoffee.com/mrbryo",
                disable = false,
                tip = {
                    disable = false,
                    text = "For an alternate support option, please consider buying me a beverage.",
                },
            },
            ["issues"] = {
                label = "Issues",
                text = "https://github.com/mrbryo/ActionBarSync/issues",
                disable = false,
                tip = {
                    disable = false,
                    text = "Please report any issues or bugs here.",
                },
            },
            ["localization"] = {
                label = "Localization",
                text = "https://legacy.curseforge.com/wow/addons/action-bar-sync/localization",
                disable = false,
                tip = {
                    disable = false,
                    text = "Help translate this addon into your language.",
                },
            }
        }
    }

    -- create the main about frame
    local aboutFrame = AceGUI:Create("SimpleGroup")
    aboutFrame:SetLayout("Flow")
    parent:AddChild(aboutFrame)

    -- left hand side
    local aboutLeftFrame = AceGUI:Create("SimpleGroup")
    aboutLeftFrame:SetLayout("Flow")
    aboutLeftFrame:SetRelativeWidth(0.6)
    aboutLeftFrame:SetFullHeight(true)
    aboutFrame:AddChild(aboutLeftFrame)

    -- add frame for padding left hand
    local aboutLeftFramePadding = AceGUI:Create("SimpleGroup")
    aboutLeftFramePadding:SetLayout("Flow")
    aboutLeftFramePadding:SetRelativeWidth(0.95)
    aboutLeftFrame:AddChild(aboutLeftFramePadding)

    -- loop over the ABSync.dataRows.text table and call the function for each iteration
    for _, id in pairs(data.order) do
        self:AddAboutLeftHandLine(aboutLeftFramePadding, data.text[id])
    end

    -- TODO: look at CurseForge to see if they have a variable for translators
    -- right hand side
    local aboutRightFrame = AceGUI:Create("InlineGroup")
    aboutRightFrame:SetLayout("List")
    aboutRightFrame:SetTitle("Translators")
    aboutRightFrame:SetRelativeWidth(0.4)
    aboutRightFrame:SetFullHeight(true)
    aboutFrame:AddChild(aboutRightFrame)
end

--[[---------------------------------------------------------------------------
    Function:   AddInstruction
    Purpose:    Add an instruction step to the instructions frame.
-----------------------------------------------------------------------------]]
function ABSync:AddInstruction(parent, i, instruct, addSpacer)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- check addSpacer
    if not addSpacer or addSpacer == nil then
        addSpacer = false
    end

    -- instantiate label
    local step = AceGUI:Create("Label")

    -- add the index as the instruction number and then the text
    step:SetText(("%d. %s"):format(i, instruct))
    step:SetFullWidth(true)
    parent:AddChild(step)

    -- add the spacer after the text
    if addSpacer == true then
        local spacer = AceGUI:Create("Label")
        spacer:SetText(" ")
        spacer:SetFullWidth(true)
        parent:AddChild(spacer)
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateInstructionsFrame
    Purpose:    Create the Instructions frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateInstructionsFrame()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- get instructions
    local instructions = {
        "Open the options and set the correct profile. I suggest to leave the default which is for your current character.",
        "On the 'Share' tab, click the 'Scan Now' button. An initial scan is required for the addon to function.",
        "Optional, on the 'Share' tab, select which action bars to share.",
        "On the 'Sync' tab, select the shared action bars from other characters to update this character's action bars.",
        "On the 'Sync' tab, once the previous step is done, click the 'Sync Now' button to sync your action bars. If you want your bars auto synced, enable the 'Auto Sync on Login' option.",
        "Done!",
    }

    -- FAQ
    -- Example:
    -- "Q: What does this addon do?\nA: This addon syncs action bars between characters."
    local faq = {
        "New addon so nothing yet. This is a placeholder.",
    }

    -- create instructions frame
    local instructionsFrame = AceGUI:Create("SimpleGroup")
    instructionsFrame:SetLayout("Fill")

    -- add scroll frame for instructions
    local instructionsScroll = AceGUI:Create("ScrollFrame")
    instructionsScroll:SetLayout("List")
    instructionsScroll:SetFullWidth(true)
    instructionsFrame:AddChild(instructionsScroll)

    -- loop over instructions
    for i, instruct in ipairs(instructions) do
        self:AddInstruction(instructionsScroll, i, instruct, true)

        -- add other interface widgets as needed based on index
        if i == 1 then
            -- add button to open options for this addon
            local step1Button = AceGUI:Create("Button")
            step1Button:SetText("Open Options")
            step1Button:SetWidth(150)
            step1Button:SetCallback("OnClick", function()
                LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
            end)
            instructionsScroll:AddChild(step1Button)
            local step1spacer = AceGUI:Create("Label")
            step1spacer:SetText(" ")
            step1spacer:SetFullWidth(true)
            instructionsScroll:AddChild(step1spacer)
        end
    end

    -- FAQ Frame
    local faqFrame = AceGUI:Create("InlineGroup")
    faqFrame:SetTitle("FAQ")
    faqFrame:SetLayout("List")
    faqFrame:SetFullWidth(true)

    -- add FAQ content
    local faqLabel = AceGUI:Create("Label")
    faqLabel:SetText("New addon and no common questions yet. This is a placeholder.")
    -- faqLabel:SetText("Q: What does this addon do?\nA: This addon syncs action bars between characters.")
    faqLabel:SetFullWidth(true)
    faqFrame:AddChild(faqLabel)

    -- add the FAQ frame to the instructions scroll
    instructionsScroll:AddChild(faqFrame)

    -- finally return the frame
    return instructionsFrame
end

--[[---------------------------------------------------------------------------
    Function:   CreateScanFrame
    Purpose:    Create the Scan frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateScanFrame()
    -- debugging
    local funcName = "CreateScanFrame"

    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create group
    local scanFrame = AceGUI:Create("InlineGroup")
    scanFrame:SetTitle("Scan Bars")
    scanFrame:SetLayout("List")

    -- add label
    local label = AceGUI:Create("Label")
    label:SetText("Last Scan on this Character")
    label:SetFullWidth(true)
    scanFrame:AddChild(label)

    -- add disabled edit box
    self.ui.editbox.lastScan = AceGUI:Create("EditBox")
    self.ui.editbox.lastScan:SetFullWidth(true)
    self.ui.editbox.lastScan:SetDisabled(true) -- make it read-only
    scanFrame:AddChild(self.ui.editbox.lastScan)

    -- add scan button
    local button = AceGUI:Create("Button")
    button:SetText("Scan Now")
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        -- refresh of the shared data is done in this function too
        ABSync:GetActionBarData()
        local playerID = ABSync:GetPlayerNameKey()
        ABSync:UpdateShareTab(playerID, "OnClick")
    end)
    scanFrame:AddChild(button)

    -- return the frame
    return scanFrame
end

--[[---------------------------------------------------------------------------
    Function:   AddErrorCell
    Purpose:    Add a cell of error information to the error display.
-----------------------------------------------------------------------------]]
function ABSync:AddErrorCell(data, width)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- print("here4")
    local cell = AceGUI:Create("Label")
    cell:SetText(tostring(data or "-"))
    cell:SetRelativeWidth(width)
    
    -- finally return the cell
    return cell
end

--[[---------------------------------------------------------------------------
    Function:   AddErrorRow
    Purpose:    Add a row of error information to the error display.
-----------------------------------------------------------------------------]]
function ABSync:AddErrorRow(data, columns)
    -- print("here3")
    
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- set up row group of columns
    local rowGroup = AceGUI:Create("SimpleGroup")
    rowGroup:SetLayout("Flow")
    rowGroup:SetFullWidth(true)
    -- parentScrollArea:AddChild(rowGroup)

    -- loop over the column definitions
    for _, colDef in ipairs(columns) do
        -- translate data if necessary
        local colVal = data[colDef.key]
        if colDef.key == "type" then
            colVal = ABSync.actionTypeLookup[data[colDef.key]]
        end
        rowGroup:AddChild(self:AddErrorCell(colVal, colDef.width))
        -- print(("Key: %s, Width: %f, Data: %s"):format(colDef.key, colDef.width, tostring(data[colDef.key])))
    end

    -- finally return the grouping
    return rowGroup
end

--[[---------------------------------------------------------------------------
    Function:   CreateLastSyncErrorFrame
    Purpose:    Create the Last Sync Error frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateLastSyncErrorFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create main frame
    local lastErrorGroup = AceGUI:Create("SimpleGroup")
    lastErrorGroup:SetLayout("Flow")
    lastErrorGroup:SetFullWidth(true)
    lastErrorGroup:SetFullHeight(true)
    parent:AddChild(lastErrorGroup)

    -- columns
    local columns = {
        { name = "Bar Name", key = "barName", width = 0.10},        -- 10
        { name = "Bar Pos", key = "barPosn", width = 0.05},         -- 15
        { name = "Button ID", key = "buttonID", width = 0.05},      -- 20
        { name = "Action Type", key = "type", width = 0.10},        -- 30
        { name = "Action Name", key = "name", width = 0.25},        -- 55
        { name = "Action ID", key = "id", width = 0.05},            -- 60
        { name = "Shared By", key = "sharedby", width = 0.15},      -- 75
        { name = "Message", key = "msg", width = 0.25}              -- 100
    }

    -- determine column width
    -- 5px for spacing
    -- local columnWidth = ((frameWidth - 5) / #columns) - 5
    -- local columnWidth = 1/(#columns+1)
    -- columnWidth = tonumber(string.format("%.2f", columnWidth))
    -- print("Column Width: " .. tostring(columnWidth))

    -- Create header row; important to add the header group to the parent group to maintain a proper layout
    local errHeader = AceGUI:Create("SimpleGroup")
    errHeader:SetLayout("Flow")
    errHeader:SetFullWidth(true)
    lastErrorGroup:AddChild(errHeader)
    for _, colDefn in ipairs(columns) do
        local label = AceGUI:Create("Label")
        label:SetText("|cff00ff00" .. colDefn.name .. "|r")
        label:SetRelativeWidth(colDefn.width)
        errHeader:AddChild(label)
    end

    -- create a container for the scroll region
    local errScrollContainer = AceGUI:Create("SimpleGroup")
    errScrollContainer:SetLayout("Fill")
    errScrollContainer:SetFullWidth(true)
    errScrollContainer:SetFullHeight(true)
    lastErrorGroup:AddChild(errScrollContainer)

    -- Create a scroll container for the spreadsheet
    local errScroll = AceGUI:Create("ScrollFrame")
    errScroll:SetLayout("List")
    errScrollContainer:AddChild(errScroll)

    --@debug@
    -- if self.db.char.isDevMode == true then
    --     local testdttmpretty = date("%Y-%m-%d %H:%M:%S")
    --     local testdttmkey = date("%Y%m%d%H%M%S")
    --     self.db.char.lastSyncErrorDttm = testdttmkey
    --     local testerrors = {}
    --     for i = 1, 10 do
    --         table.insert(testerrors, {barName = "Test Bar", barPos = i, buttonID = i, actionType = "spell", name = "Test Spell", id = 12345, msg = "Test Error Message"})
    --     end
    --     table.insert(self.db.char.syncErrors, {
    --         key = testdttmkey,
    --         errors = testerrors
    --     })
    -- end
    --@end-debug@

    -- verify if we a last sync error
    local errorsExist = false
    if not self.db.char then
        errorsExist = false
    else
        local lastDateTime = self.db.char.lastSyncErrorDttm or L["never"]
        if lastDateTime ~= nil and lastDateTime ~= L["never"] then
            errorsExist = true
        end
    end
    --@debug@
    if self.db.char.isDevMode == true then self:Print(("Errors Exist: %s"):format(tostring(errorsExist))) end
    --@end-debug@
    
    -- loop over sync errors
    --[[ 
        errorRcd contains the following properties:
            property        description
            --------------- --------------------------------------------------------
            key             has a value of a date and time string
            errors          is a table containing error records

        errors contains the following:
            property        description
            --------------- --------------------------------------------------------
            barPos          the action is in which button in the action bars; action bars have buttons 1 to 12
            type            the action type
            name            the name of the action
            barName         the name of the action bar it resides
            id              the ID of the action
            msg             the error message
            sharedby        the player who shared the action
            buttonID        the blizzard designation for the button; all buttons are stored in a single array so 1 to N where N is the number of action bars times 12
    ]]
    if errorsExist == true then
        for _, errorRcd in ipairs(self.db.char.syncErrors) do
            -- print("here1")
            -- continue to next row if key doesn't match
            if errorRcd.key == self.db.char.lastSyncErrorDttm then
                -- print("here2")
                -- loop over the rows
                for _, errorRow in ipairs(errorRcd.errors) do
                    errScroll:AddChild(self:AddErrorRow(errorRow, columns))
                end
            end
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareCheckboxes
    Purpose:    Create checkboxes for each action bar to select which action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareCheckboxes(playerID, funcName)
    -- for debugging
    local funcName = "CreateShareCheckboxes"

    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- get action bar names
    local actionBars = ABSync:GetActionBarNames(ABSync.profiletype["global"])
    
    -- loop over the action bars and create a checkbox for each one
    for _, checkboxName in pairs(actionBars) do
        -- create a checkbox for each action bar
        local checkBox = AceGUI:Create("CheckBox")
        checkBox:SetLabel(checkboxName)

        -- determine checkbox value; checkboxName is the name of the action bar
        local checkboxValue = self:GetBarToShare(checkboxName, playerID)
        -- self:Print(("(%s) Checkbox '%s' initial value is %s..."):format(funcName, checkboxName, tostring(checkboxValue)))

        -- set the checkbox initial value
        checkBox:SetValue(checkboxValue)
        -- checkBox:SetFullWidth(true)

        -- set callback for when checkbox is clicked, only need value
        checkBox:SetCallback("OnValueChanged", function(data)
            -- keep for looking at data table values
            -- for k, v in pairs(data) do
            --     print(("Checkbox Data Key: %s - Value: %s"):format(k, tostring(v)))
            -- end
            -- self:Print(("(%s) Checkbox '%s' now %s..."):format("OnValueChanged", checkboxName, tostring(data.checked)))
            -- update the profile barsToSync value
            self:SetBarToShare(checkboxName, data.checked)
        end)

        -- add the checkbox to the share frame
        self.ui.group.shareFrame:AddChild(checkBox)
    end
end

--[[---------------------------------------------------------------------------
    Function:   UpdateShareTab
    Purpose:    Update the share tab last scan edit box with the latest scan date and time.
-----------------------------------------------------------------------------]]
function ABSync:UpdateShareTab(playerID, funcName)
    -- update the data in the lastScan edit box
    self.ui.editbox.lastScan:SetText(self.db.char.lastScan or L["noscancompleted"])

    -- update the action bar list
    self.ui.group.shareFrame:ReleaseChildren()
    self:CreateShareCheckboxes(playerID, funcName)
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareFrame
    Purpose:    Create the share frame for selecting action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareFrame(playerID)
    -- for debugging
    local funcName = "CreateShareFrame"

    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create main frame
    local mainShareFrame = AceGUI:Create("SimpleGroup")
    mainShareFrame:SetLayout("List")
    mainShareFrame:SetFullWidth(true)

    -- create the scan frame
    local triggerScanFrame = self:CreateScanFrame()
    mainShareFrame:AddChild(triggerScanFrame)

    -- create share frame
    self.ui.group.shareFrame = AceGUI:Create("InlineGroup")
    -- local shareFrame = AceGUI:Create("InlineGroup")
    self.ui.group.shareFrame:SetTitle("Share")
    self.ui.group.shareFrame:SetLayout("Flow")
    mainShareFrame:AddChild(self.ui.group.shareFrame)

    -- add a multiselect for sharing which action bars to share
    -- self:CreateShareCheckboxes(playerID)

    -- update data
    self:UpdateShareTab(playerID, funcName)

    -- if dataChanged == true then
    --     -- trigger update for options UI
    --     LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)
    -- end

    -- finally return the frame
    return mainShareFrame
end

--[[---------------------------------------------------------------------------
    Function:   SyncOnValueChanged
    Purpose:    Sync the action bar state when the checkbox value changes.
-----------------------------------------------------------------------------]]
function ABSync:SyncOnValueChanged(value, barName, playerID)
    if value == true then
        self.db.profile.barsToSync[barName] = playerID
    else
        self.db.profile.barsToSync[barName] = false
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateSyncCheckbox
    Purpose:    Create a checkbox for syncing action bars.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncCheckbox(barName, playerID, currentPlayerID)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create a checkbox
    local checkBox = AceGUI:Create("CheckBox")
    
    -- set barName to green and playerID to orange
    local label = "|cff00ff00" .. barName .. "|r from |cffffa500" .. playerID .. "|r"
    if playerID == currentPlayerID then
        label = ("%s from %s"):format(barName, playerID)
    end
    checkBox:SetLabel(label)
    checkBox:SetFullWidth(true)
    
    -- if they equal then it sets the value to true, otherwise, false
    checkBox:SetValue(self:GetBarToSync(barName, playerID))
    checkBox:SetCallback("OnValueChanged", function(_, _, value)
        local playerID = playerID
        local barName = barName
        ABSync:SyncOnValueChanged(value, barName, playerID)
    end)
    checkBox:SetDisabled(playerID == currentPlayerID)

    -- finally return a new checkbox
    return checkBox
end

--[[---------------------------------------------------------------------------
    Function:   CreateSyncFrame
    Purpose:    Create the sync frame for selecting action bars to sync.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- current player ID
    local currentPlayerID = self:GetPlayerNameKey()

    -- create main frame
    local syncFrame = AceGUI:Create("SimpleGroup")
    syncFrame:SetLayout("Flow")
    syncFrame:SetFullWidth(true)
    parent:AddChild(syncFrame)

    -- create frame for check sync on login
    local loginCheckFrame = AceGUI:Create("InlineGroup")
    loginCheckFrame:SetTitle("Sync on Login")   -- Sync on Login
    loginCheckFrame:SetLayout("Flow")
    loginCheckFrame:SetRelativeWidth(0.5)
    -- loginCheckFrame:SetFullHeight(true)
    syncFrame:AddChild(loginCheckFrame)

    -- create checkbox for auto mount journal filter reset; must create prior to loginCheckBox so it can be called in the OnValueChanged
    local autoMountFilterReset = AceGUI:Create("CheckBox")
    autoMountFilterReset:SetLabel("Automatically Reset Mount Journal Filters")
    autoMountFilterReset:SetValue(self.db.profile.autoResetMountFilters)
    autoMountFilterReset:SetWidth(275)
    autoMountFilterReset:SetDisabled(self.db.profile.checkOnLogon == false)
    autoMountFilterReset:SetCallback("OnValueChanged", function(_, _, value)
        self.db.profile.autoResetMountFilters = value
    end)

    -- create checkbox for sync on login
    local loginCheckBox = AceGUI:Create("CheckBox")
    loginCheckBox:SetLabel("Enable Sync on Login")  -- Enable Sync on Login
    loginCheckBox:SetValue(false)
    loginCheckBox:SetCallback("OnValueChanged", function(_, _, value)
        self.db.profile.checkOnLogon = value
        if value == true then
            autoMountFilterReset:SetDisabled(false)
        else
            autoMountFilterReset:SetDisabled(true)
        end
    end)

    -- add checkbox to login check frame
    loginCheckFrame:AddChild(loginCheckBox)

    -- add checkbox to login check frame; want it to follow loginCheckBox even through its made first
    loginCheckFrame:AddChild(autoMountFilterReset)

    -- create frame for manual sync
    local manualSyncFrame = AceGUI:Create("InlineGroup")
    manualSyncFrame:SetTitle("Manual Sync")  -- Manual Sync
    manualSyncFrame:SetLayout("Flow")
    manualSyncFrame:SetRelativeWidth(0.5)
    -- manualSyncFrame:SetFullHeight(true)
    syncFrame:AddChild(manualSyncFrame)

    -- create button for manual sync
    local manualSyncButton = AceGUI:Create("Button")
    manualSyncButton:SetText("Sync Now")
    manualSyncButton:SetWidth(100)
    manualSyncButton:SetCallback("OnClick", function()
        self:BeginSync()
    end)
    manualSyncFrame:AddChild(manualSyncButton)

    -- create button for manual mount filter reset
    local manualMountFilterResetButton = AceGUI:Create("Button")
    manualMountFilterResetButton:SetText("Reset Mount Filters")
    manualMountFilterResetButton:SetWidth(160)
    manualMountFilterResetButton:SetCallback("OnClick", function()
        self:MountJournalFilterReset()
    end)
    manualSyncFrame:AddChild(manualMountFilterResetButton)

    -- create frame for listing who can be synced from and their bars
    local scrollContainer = AceGUI:Create("InlineGroup")
    scrollContainer:SetTitle("Sync From?")
    scrollContainer:SetLayout("Fill")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    syncFrame:AddChild(scrollContainer)
    
    -- create scroll frame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    scrollContainer:AddChild(scrollFrame)

    -- loop over data and add checkboxes per character and action bar combo where they are enabled
    -- track if anything was added or not
    local sharedActionBarsAdded = false

    -- primary loop is actionBars as it's sorted
    for _, barName in ipairs(self.db.global.actionBars) do
        
        -- verify bar exists in global.barsToSync
        if self.db.global.barsToSync[barName] ~= nil then
            
            -- loop over the barName in global.barsToSync
            for playerID, buttonData in pairs(self.db.global.barsToSync[barName]) do
                -- to see if enabled the buttonData must be a table and have at least 1 record
                -- count variable
                local foundData = false
                
                -- make sure buttonData is a table
                if type(buttonData) == "table" then
                    -- next returns the first key in the table or nill if the table is empty
                    if next(buttonData) then
                        foundData = true
                    end
                end

                -- create a checkbox if data is found
                if foundData == true then
                    scrollFrame:AddChild(self:CreateSyncCheckbox(barName, playerID, currentPlayerID))
                    sharedActionBarsAdded = true
                end
            end
        end
    end

    -- if no shared action bars were added, then add a label to indicate that
    if sharedActionBarsAdded == false then
        local noDataLabel = AceGUI:Create("Label")
        noDataLabel:SetText("No Shared Action Bars Found")
        noDataLabel:SetFullWidth(true)
        scrollFrame:AddChild(noDataLabel)
    end

    -- set values from db
    loginCheckBox:SetValue(self.db.profile.checkOnLogon)

    -- --@debug@
    -- -- for adding 20 rows of fake data
    -- for i = 1, 20 do
    --     scrollFrame:AddChild(self:CreateSyncCheckbox(("Test Bar %d"):format(i), "Test Player"))
    -- end
    -- --@end-debug@

    -- finally return frame
    -- return syncFrame
end

--[[---------------------------------------------------------------------------
    Function:   CreateDeveloperFrame
    Purpose:    Create the developer frame for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:CreateDeveloperFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create main frame
    local devFrame = AceGUI:Create("SimpleGroup")
    devFrame:SetLayout("Flow")
    devFrame:SetFullWidth(true)
    parent:AddChild(devFrame)

    --[[ warning! ]]

    -- create frame for warning
    local warningFrame = AceGUI:Create("InlineGroup")
    warningFrame:SetTitle("|cffff0000Warning!|r")
    warningFrame:SetLayout("List")
    warningFrame:SetFullWidth(true)
    devFrame:AddChild(warningFrame)

    -- add developer tab warning
    local devWarningLabel = AceGUI:Create("Label")
    devWarningLabel:SetText("This tab is used for development purposes only. If you are a user and using anything on this tab, then please use at your own risk. Please do not open tickets about this tab.")
    devWarningLabel:SetFullWidth(true)
    warningFrame:AddChild(devWarningLabel)

    --[[ mount db refresh ]]

    -- create frame for mount db
    local mountDBFrame = AceGUI:Create("InlineGroup")
    mountDBFrame:SetTitle("Mount Database")
    mountDBFrame:SetLayout("Flow")
    mountDBFrame:SetRelativeWidth(0.5)
    devFrame:AddChild(mountDBFrame)

    -- add label explaining the purpose of the button
    local mountDBRefreshInfoLabel = AceGUI:Create("Label")
    mountDBRefreshInfoLabel:SetText("Click the button below to refresh the mount database for this character. DB stores mount data by character for, currently, manual data comparison. Then click the 'Reload UI' button so the data is available in the saved variables file.")
    mountDBRefreshInfoLabel:SetFullWidth(true)
    mountDBFrame:AddChild(mountDBRefreshInfoLabel)

    -- add space between text and button; terrible way to add space...need to figure out how to add bottom padding or switch to standard UI design outside of AceGUI
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    mountDBFrame:AddChild(spacer)

    -- create button to refresh mount db
    local mountDBRefreshButton = AceGUI:Create("Button")
    mountDBRefreshButton:SetText("Refresh Mount DB")
    mountDBRefreshButton:SetWidth(150)
    mountDBRefreshButton:SetCallback("OnClick", function()
        ABSync:RefreshMountDB()
    end)
    mountDBFrame:AddChild(mountDBRefreshButton)

    -- create button to reload the ui
    local mountDBReloadButton = AceGUI:Create("Button")
    mountDBReloadButton:SetText("Reload UI")
    mountDBReloadButton:SetWidth(150)
    mountDBReloadButton:SetCallback("OnClick", function()
        C_UI.Reload()
    end)
    mountDBFrame:AddChild(mountDBReloadButton)

    -- create button to clear db for this char
    local mountDBClearButton = AceGUI:Create("Button")
    mountDBClearButton:SetText("Clear Character Mount DB")
    mountDBClearButton:SetWidth(200)
    mountDBClearButton:SetCallback("OnClick", function()
        ABSync:ClearMountDB()
    end)
    mountDBFrame:AddChild(mountDBClearButton)
end

--[[---------------------------------------------------------------------------
    Function:   UpdateLookupHistory
    Purpose:    Update the lookup history display.
-----------------------------------------------------------------------------]]
function ABSync:UpdateLookupHistory()
    -- clear the scroll area
    ABSync.ui.scroll.lookupHistory:ReleaseChildren()

    -- add the updated records
    self:InsertLookupHistoryRows(ABSync.ui.scroll.lookupHistory, ABSync.columns.lookupHistory)
end

--[[---------------------------------------------------------------------------
    Function:   InsertLookupHistoryRows
    Purpose:    Insert rows into the lookup history display.
    Arguments:  parent  - The parent frame to attach this frame to
                columns - The columns to display
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:InsertLookupHistoryRows(parent, columns)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create row group
    local rowGroup = AceGUI:Create("SimpleGroup")
    rowGroup:SetLayout("Flow")
    rowGroup:SetFullWidth(true)
    parent:AddChild(rowGroup)

    -- add lookup history rows
    if #self.db.char.lookupHistory > 0 then
        for _, histRow in ipairs(self.db.char.lookupHistory) do
            -- print("here1")
            for _, colDef in ipairs(columns) do
                local label = AceGUI:Create("Label")
                local colVal = histRow[colDef.key]
                if colDef.key == "type" then
                    colVal = ABSync.actionTypeLookup[colVal]
                end
                label:SetText(colVal)
                label:SetRelativeWidth(colDef.width)
                rowGroup:AddChild(label)
            end
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateLookupQueryFrame
    Purpose:    Create the lookup query frame for performing action lookups.
    Arguments:  parent  - The parent frame to attach this frame to
    Returns:    None
]]
function ABSync:CreateLookupQueryFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    local labelWidth = 75
    local controlWidth = 200
    local padding = 15
    
    -- create top section group with label named "Perform a Lookup"
    local searchFrame = AceGUI:Create("InlineGroup")
    searchFrame:SetTitle("Perform a Lookup")
    searchFrame:SetLayout("List")
    searchFrame:SetRelativeWidth(1)
    parent:AddChild(searchFrame)
    
    -- create a top row
    local topRow = AceGUI:Create("SimpleGroup")
    topRow:SetLayout("Flow")
    topRow:SetRelativeWidth(1)
    searchFrame:AddChild(topRow)

    -- intro at top of top section
    local introLabel = AceGUI:Create("Label")
    introLabel:SetText(L["actionlookupintro"])
    introLabel:SetRelativeWidth(1)
    topRow:AddChild(introLabel)

    -- second row for action id label, edit box and the submit button
    local secondRow = AceGUI:Create("SimpleGroup")
    secondRow:SetLayout("Flow")
    secondRow:SetRelativeWidth(1)
    secondRow:SetFullHeight(true)
    searchFrame:AddChild(secondRow)

    -- second row column 1 (column 1 is labels)
    local secondRowCol1 = AceGUI:Create("Label")
    secondRowCol1:SetText(("%sAction ID:|r"):format(ABSync.colors.label))
    secondRowCol1:SetWidth(labelWidth)
    secondRow:AddChild(secondRowCol1)

    -- second row column 2 (column 2 for controls)
    local secondRowCol2Padding = AceGUI:Create("SimpleGroup")
    secondRowCol2Padding:SetWidth(controlWidth + padding)
    secondRow:AddChild(secondRowCol2Padding)
    local secondRowCol2 = AceGUI:Create("EditBox")
    secondRowCol2:SetText(ABSync:GetLastActionID())
    secondRowCol2:SetWidth(controlWidth)
    secondRowCol2:SetCallback("OnEnterPressed", function(_, _, value)
        ABSync:SetLastActionID(value)
    end)
    secondRowCol2Padding:AddChild(secondRowCol2)

    -- second row column 3 (column 3 for the button)
    local secondRowCol3 = AceGUI:Create("Button")
    secondRowCol3:SetText(L["lookupbuttonname"])
    secondRowCol3:SetWidth(75)
    secondRowCol3:SetCallback("OnClick", function()
        ABSync:LookupAction()
    end)
    secondRow:AddChild(secondRowCol3)

    -- third row for action type
    local thirdRow = AceGUI:Create("SimpleGroup")
    thirdRow:SetLayout("Flow")
    thirdRow:SetRelativeWidth(1)
    searchFrame:AddChild(thirdRow)

    -- third row column 1 for action type label
    local thirdRowCol1 = AceGUI:Create("Label")
    thirdRowCol1:SetText(("%sAction Type:|r"):format(ABSync.colors.label))
    thirdRowCol1:SetWidth(labelWidth)
    thirdRow:AddChild(thirdRowCol1)

    -- third row column 2 for drop down
    local thirdRowCol2 = AceGUI:Create("Dropdown")
    thirdRowCol2:SetWidth(controlWidth)
    thirdRowCol2:SetList(ABSync:GetActionTypeValues())
    thirdRowCol2:SetValue(ABSync:GetLastActionType())
    thirdRowCol2:SetCallback("OnValueChanged", function(_, _, value)
        ABSync:SetLastActionType(value)
    end)
    thirdRow:AddChild(thirdRowCol2)
end

--[[---------------------------------------------------------------------------
    Function:   CreateLookupFrame
    Purpose:    Create the lookup frame for displaying action lookups.
    Arguments:  parent  - The parent frame to attach this frame to
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:CreateLookupFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create main frame which fills the parent with type fill
    local lookupFrame = AceGUI:Create("SimpleGroup")
    lookupFrame:SetLayout("Flow")
    parent:AddChild(lookupFrame)

    -- add query frame
    self:CreateLookupQueryFrame(lookupFrame)

    --[[ create section to show last 'user defined count' of lookups ]]

    -- create lower section group with label named "Lookup History"
    local lookupHistoryFrame = AceGUI:Create("InlineGroup")
    lookupHistoryFrame:SetTitle("Lookup History")
    lookupHistoryFrame:SetLayout("Fill")
    lookupHistoryFrame:SetRelativeWidth(1)
    lookupHistoryFrame:SetFullHeight(true)
    lookupFrame:AddChild(lookupHistoryFrame)
    local lookupHistoryGroup = AceGUI:Create("SimpleGroup")
    lookupHistoryGroup:SetLayout("Flow")
    lookupHistoryFrame:AddChild(lookupHistoryGroup)

    --[[ lower section to show lookup history ]]

    -- add header
    local historyHeader = AceGUI:Create("SimpleGroup")
    historyHeader:SetLayout("Flow")
    historyHeader:SetFullWidth(true)
    lookupHistoryGroup:AddChild(historyHeader)
    for _, colDefn in ipairs(ABSync.columns.lookupHistory) do
        local label = AceGUI:Create("Label")
        label:SetText("|cff00ff00" .. colDefn.name .. "|r")
        label:SetRelativeWidth(colDefn.width)
        historyHeader:AddChild(label)
    end

    -- create a scroll frame to hold the history
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetLayout("Fill")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    lookupHistoryGroup:AddChild(scrollContainer)

    -- add scroll frame to container
    ABSync.ui.scroll.lookupHistory = AceGUI:Create("ScrollFrame")
    ABSync.ui.scroll.lookupHistory:SetLayout("List")
    scrollContainer:AddChild(ABSync.ui.scroll.lookupHistory)

    -- populate the scroll frame
    self:InsertLookupHistoryRows(ABSync.ui.scroll.lookupHistory, ABSync.columns.lookupHistory)

    -- fixes layout sometimes...
    lookupFrame:DoLayout()
end

--[[---------------------------------------------------------------------------
    Function:   ClearBackupActionBarDropdown
    Purpose:    Clear the action bar selection dropdown.
-----------------------------------------------------------------------------]]
function ABSync:ClearBackupActionBarDropdown()
    if ABSync.ui.dropdown.currentBackupActionBars then
        local data = {}
        data["none"] = "None"
        ABSync.ui.dropdown.currentBackupActionBars:SetList(data)
        ABSync.ui.dropdown.currentBackupActionBars:SetValue("none")
    end
end

--[[---------------------------------------------------------------------------
    Function:   LoadBackupActionBars
    Purpose:    Load the action bars from a selected backup into the action bar selection dropdown.
-----------------------------------------------------------------------------]]
function ABSync:LoadBackupActionBars(backupKey)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- find the backup record
    local found = false
    for _, backupRow in ipairs(self.db.char.backup) do
        if backupRow.dttm == backupKey then
            -- loop over the action bars in the backup record and create a checkbox for each one
            local newData = {}
            for actionBarName, _ in pairs(backupRow.data) do
                newData[actionBarName] = actionBarName
            end
            -- update list
            ABSync.ui.dropdown.currentBackupActionBars:SetList(newData)
            ABSync.ui.dropdown.currentBackupActionBars:SetValue("")
            -- mark found
            found = true
            -- exit loop
            break
        end
    end
    -- if no records found then reset table with a single "None" value
    if found == false then
        self:ClearBackupActionBarDropdow()
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateRestoreFrame
    Purpose:    Create the restore frame for selecting which action bars to restore and a button to trigger it.
-----------------------------------------------------------------------------]]
function ABSync:CreateRestoreFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create drop down based on selected backup, initially it will have a fake value
    local actionBarSelection = AceGUI:Create("Dropdown")
    actionBarSelection:SetLabel("Select an Action Bar to Restore")
    actionBarSelection:AddItem("none", "None")
    actionBarSelection:SetValue("none")
    parent:AddChild(actionBarSelection)
    ABSync.ui.dropdown.currentBackupActionBars = actionBarSelection
end

--[[---------------------------------------------------------------------------
    Function:   CreateBackupListFrame
    Purpose:    Create the backup list frame for displaying available backups.
-----------------------------------------------------------------------------]]
function ABSync:CreateBackupListFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- Create a scroll container for the spreadsheet
    local backupScroll = AceGUI:Create("ScrollFrame")
    backupScroll:SetLayout("List")
    parent:AddChild(backupScroll)

    -- add the available backups
    local trackInserts = 0
    for _, backupRow in ipairs(self.db.char.backup) do
        local checkbox = AceGUI:Create("CheckBox")
        checkbox:SetLabel(self:FormatDateString(backupRow.dttm))
        checkbox:SetValue(false)
        checkbox:SetDescription(backupRow.note)
        checkbox:SetFullWidth(true)
        checkbox:SetCallback("OnValueChanged", function(_, _, value)
            -- clear all other checkboxes
            for _, child in ipairs(backupScroll.children) do
                if child ~= checkbox and child.type == "CheckBox" then
                    child:SetValue(false)
                end
            end
            -- if checked, load the action bars for this backup into the action bar selection scroll region
            if value == true then
                ABSync:LoadBackupActionBars(backupRow.dttm)
            else
                ABSync:ClearBackupActionBarDropdow()
            end
        end)
        backupScroll:AddChild(checkbox)
        trackInserts = trackInserts + 1
    end

    -- insert empty records if no records inserted
    if trackInserts == 0 then
        local noDataLabel = AceGUI:Create("Label")
        noDataLabel:SetText("No Backups Found")
        noDataLabel:SetFullWidth(true)
        backupScroll:AddChild(noDataLabel)
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateBackupFrame
    Purpose:    Create the backup frame for displaying and restoring backups.
-----------------------------------------------------------------------------]]
function ABSync:CreateBackupFrame(parent)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create backup top level frame, child to the tab
    local backupFrame = AceGUI:Create("SimpleGroup")
    backupFrame:SetLayout("Flow")
    parent:AddChild(backupFrame)

    -- add info label
    local infoFrame = AceGUI:Create("InlineGroup")
    infoFrame:SetTitle("Directions")
    infoFrame:SetLayout("Fill")
    infoFrame:SetFullWidth(true)
    local infoLabel = AceGUI:Create("Label")
    infoLabel:SetText("Backups are stored per character. Select which backup by date and time and then which action bars to restore. Then click the 'Restore Selected Backup' button.")
    infoFrame:AddChild(infoLabel)
    backupFrame:AddChild(infoFrame)

    -- group for the backup list group and the restore group
    local backupAndRestoreGroup = AceGUI:Create("SimpleGroup")
    backupAndRestoreGroup:SetLayout("Flow")
    backupAndRestoreGroup:SetRelativeWidth(1)
    backupAndRestoreGroup:SetFullHeight(true)
    backupFrame:AddChild(backupAndRestoreGroup)

    -- create a container for the scroll region
    local backupScrollContainer = AceGUI:Create("InlineGroup")
    backupScrollContainer:SetTitle("Backups")
    backupScrollContainer:SetLayout("Fill")
    backupScrollContainer:SetRelativeWidth(0.5)
    backupScrollContainer:SetFullHeight(true)
    backupAndRestoreGroup:AddChild(backupScrollContainer)

    -- create listing of backups; scrollable area with columns: Date/Time, Note
    self:CreateBackupListFrame(backupScrollContainer)

    -- create a container for the action bar selection
    local actionBarSelectContainer = AceGUI:Create("InlineGroup")
    actionBarSelectContainer:SetTitle("Restore")
    actionBarSelectContainer:SetLayout("List")
    actionBarSelectContainer:SetRelativeWidth(0.5)
    actionBarSelectContainer:SetFullHeight(true)
    backupAndRestoreGroup:AddChild(actionBarSelectContainer)

    -- create frame for selecting which action bars to restore
    self:CreateRestoreFrame(actionBarSelectContainer)
    backupAndRestoreGroup:DoLayout()
end

--[[---------------------------------------------------------------------------
    Function:   ShowErrorLog
    Purpose:    Open custom UI to show last sync errors to user.
-----------------------------------------------------------------------------]]
function ABSync:ShowUI()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- get player
    local playerID = self:GetPlayerNameKey()

    -- Get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    -- print(("Screen Size: %d x %d"):format(screenWidth, screenHeight))

    -- set initial sizes
    local frameWidth = screenWidth * 0.6
    local frameHeight = screenHeight * 0.6
    
    --[[ Create the main frame]]

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Action Bar Sync")
    -- TODO: format the dttm or store a formatted value instead...
    frame:SetStatusText(("Last Synced to UI: %s"):format(self.db.char.lastSynced or "-"))
    frame:SetLayout("Fill")
    frame:SetWidth(frameWidth)
    frame:SetHeight(frameHeight)
    local dialogFrame = frame.frame
    dialogFrame:SetFrameStrata("DIALOG")
    dialogFrame:SetFrameLevel(1)

    -- create tab table
    local tabs = {}
    for _, tabkey in ipairs(ABSync.uitabs.order) do
        local tabname = ABSync.uitabs.tabs[tabkey]
        -- print(("Tab: %s, Key: %s"):format(tabname, tabkey))

        -- if developer mode disabled, skip the developer tab, otherwise add the tab
        if tabkey ~= "developer" or (tabkey == "developer" and self.db.char.isDevMode == true) then
            table.insert(tabs, { text = tabname, value = tabkey })
        end
    end

    -- create tab group
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs(tabs)

    -- adjust content based on selected tab
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
        -- clear all children
        tabGroup:ReleaseChildren()

        -- check which tab is selected
        if group == "about" then
            local aboutFrame = self:CreateAboutFrame(tabGroup)
            self.db.profile.mytab = "about"
        elseif group == "instructions" then
            local instructionsFrame = self:CreateInstructionsFrame()
            tabGroup:AddChild(instructionsFrame)
            self.db.profile.mytab = "instructions"
        elseif group == "share" then
            local shareFrame = self:CreateShareFrame(playerID)
            tabGroup:AddChild(shareFrame)
            self.db.profile.mytab = "share"
        elseif group == "sync" then
            local syncFrame = self:CreateSyncFrame(tabGroup)
            self.db.profile.mytab = "sync"
        elseif group == "last_sync_errors" then
            local lastSyncErrorFrame = self:CreateLastSyncErrorFrame(tabGroup)
            self.db.profile.mytab = "last_sync_errors"
        elseif group == "developer" then
            local developerFrame = self:CreateDeveloperFrame(tabGroup)
            self.db.profile.mytab = "developer"
        elseif group == "lookup" then
            local lookupFrame = self:CreateLookupFrame(tabGroup)
            self.db.profile.mytab = "lookup"
        elseif group == "backup" then
            local backupFrame = self:CreateBackupFrame(tabGroup)
            self.db.profile.mytab = "backup"
        end
    end)

    -- set the tab
    tabGroup:SelectTab(self.db.profile.mytab or "instructions")

    -- finally add the tab group
    frame:AddChild(tabGroup)

    -- display the frame
    frame:Show()
end

-- [[ Replace all AceGUI Code with Standard UI Code ]]

-- Replace AceGUI:Create("Frame") with:
local function CreateMainFrame()
    local frame = CreateFrame("Frame", "ActionBarSyncMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Set title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Action Bar Sync")
    
    return frame
end

-- Replace AceGUI TabGroup with standard tab buttons.
local function CreateTabSystem(parent)
    local tabFrame = CreateFrame("Frame", nil, parent)
    tabFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -30)
    tabFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -30)
    tabFrame:SetHeight(30)
    
    local tabs = {}
    local tabButtons = {}
    
    -- Create tab data
    local tabData = {
        {name = "About", key = "about"},
        {name = "Instructions", key = "instructions"},
        {name = "Share", key = "share"},
        {name = "Sync", key = "sync"},
        {name = "Lookup", key = "lookup"},
        {name = "Backup", key = "backup"}
    }
    
    -- Create tab buttons
    for i, tab in ipairs(tabData) do
        local button = CreateFrame("Button", nil, tabFrame, "CharacterFrameTabButtonTemplate")
        button:SetID(i)
        button:SetText(tab.name)
        button:SetScript("OnClick", function(self)
            PanelTemplates_SetTab(tabFrame, self:GetID())
            ShowTabContent(tab.key)
        end)
        
        if i == 1 then
            button:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 0, 0)
        else
            button:SetPoint("LEFT", tabButtons[i-1], "RIGHT", -15, 0)
        end
        
        tabButtons[i] = button
    end
    
    -- Initialize first tab
    PanelTemplates_SetNumTabs(tabFrame, #tabData)
    PanelTemplates_SetTab(tabFrame, 1)
    
    return tabFrame, tabButtons
end

--[[---------------------------------------------------------------------------
    Function:   CreateContentFrame
    Purpose:    Create a scrollable content frame for tab content.
    Arguments:  parent - The parent frame to attach this frame to
    Returns:    The created ScrollFrame and its child Frame for content.
-----------------------------------------------------------------------------]]
local function CreateContentFrame(parent)
    local contentFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    contentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -70)
    contentFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, contentFrame)
    content:SetSize(contentFrame:GetWidth(), 1) -- Height will be calculated
    contentFrame:SetScrollChild(content)
    
    return contentFrame, content
end

--[[---------------------------------------------------------------------------
    Function:   CreateStandardButton
    Purpose:    Replace AceGUI buttons with standard buttons.
    Arguments:  parent   - The parent frame to attach this frame to
                text     - The button text
                width    - The width of the button
                onClick  - Callback function when the button is clicked
    Returns:    The created Button frame.

Usage example:

    local scanButton = CreateStandardButton(shareFrame, "Scan Now", 100, function()
        ABSync:GetActionBarData()
        -- Update UI
    end)
    scanButton:SetPoint("TOPLEFT", shareFrame, "TOPLEFT", 10, -10)
-----------------------------------------------------------------------------]]
local function CreateStandardButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    button:SetSize(width or 120, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

--[[---------------------------------------------------------------------------
    Function:   CreateEditBox
    Purpose:    Replace AceGUI edit boxes with standard edit boxes.
    Arguments:  parent   - The parent frame to attach this frame to
                width    - The width of the edit box
                height   - The height of the edit box
                readOnly - Boolean to set if the edit box is read-only
    Returns:    The created EditBox frame.

Usage example:

    local lastScanBox = CreateEditBox(scanFrame, 250, 20, true)
    lastScanBox:SetPoint("TOPLEFT", scanFrame, "TOPLEFT", 10, -40)
    lastScanBox:SetText(self.db.char.lastScan or "Never")
-----------------------------------------------------------------------------]]
local function CreateEditBox(parent, width, height, readOnly)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(width or 200, height or 20)
    editBox:SetAutoFocus(false)
    
    if readOnly then
        editBox:SetEnabled(false)
    end
    
    return editBox
end

--[[---------------------------------------------------------------------------
    Function:   CreateCheckBox
    Purpose:    Replace AceGUI checkboxes with standard check buttons.
    Arguments:  parent       - The parent frame to attach this frame to
                text         - The label text for the checkbox
                initialValue - The initial checked state (true/false)
                onChanged    - Callback function when the checkbox state changes
    Returns:    The created CheckButton frame.

Usage example:

----------------------------------------------------------------------------]]
local function CreateCheckBox(parent, text, initialValue, onChanged)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox.Text:SetText(text)
    checkbox:SetChecked(initialValue)
    
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if onChanged then
            onChanged(checked)
        end
    end)
    
    return checkbox
end

--[[---------------------------------------------------------------------------
    Function:   CreateDropdown
    Purpose:    Replace AceGUI dropdowns with standard dropdown menus.
    Arguments:  parent          - The parent frame to attach this frame to
                items           - A table of items for the dropdown (key-value pairs)
                initialValue    - The initial selected value
                onSelectionChanged - Callback function when the selection changes
    Returns:    The created Dropdown frame.
    
Usage example:

    local actionTypeDropdown = CreateDropdown(lookupFrame, 
        ABSync:GetActionTypeValues(),
        ABSync:GetLastActionType(),
        function(value)
            ABSync:SetLastActionType(value)
        end
    )
-----------------------------------------------------------------------------]]
local function CreateDropdown(parent, items, initialValue, onSelectionChanged)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    
    local function DropdownInitialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for key, value in pairs(items) do
            info.text = value
            info.value = key
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                if onSelectionChanged then
                    onSelectionChanged(self.value)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, DropdownInitialize)
    UIDropDownMenu_SetSelectedValue(dropdown, initialValue)
    
    return dropdown
end

--[[---------------------------------------------------------------------------
    Function:   CreateInlineGroup
    Purpose:    Replace AceGUI inline groups with standard frames with a title.
    Arguments:  parent - The parent frame to attach this frame to
                title  - The title text for the group
                width  - The width of the group
                height - The height of the group
    Returns:    The created Frame.
-----------------------------------------------------------------------------]]
local function CreateInlineGroup(parent, title, width, height)
    local frame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    frame:SetSize(width or 200, height or 100)
    
    -- Add title
    if title then
        local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
        titleText:SetText(title)
        titleText:SetTextColor(1, 0.82, 0) -- Gold color
    end
    
    return frame
end