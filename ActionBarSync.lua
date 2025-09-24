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
ABSync.localeData = L

-- addon access to UI elements
ABSync.ui = {
    label = {},
    editbox = {},
    scroll = {},
    group = {},
    dropdown = {},
    frame = {},
    checkbox = {},
}

-- colors
ABSync.constants = {
    colors = {
        white = "|cffffffff",
        yellow = "|cffffff00",
        green = "|cff00ff00",
        blue = "|cff0000ff",
        purple = "|cffff00ff",
        red = "|cffff0000",
        orange = "|cffff7f00",
        gray = "|cff7f7f7f",
        label = "|cffffd100"
    },
    ui = {
        checkbox = {
            size = 16,
            padding = 5
        },
        generic = {
            padding = 10
        }
    }
}

-- addon ui columns
ABSync.columns = {
    lookupHistory = {
        { name = "Type", key = "type", width = 0.20 },      -- 20
        { name = "ID", key = "id", width = 0.20 },          -- 40
        { name = "Name", key = "name", width = 0.50 },      -- 90
        { name = "Has", key = "has", width = 0.5 },         -- 95
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
        ["introduction"] = "Introduction",
        ["sharesync"] = "Share/Sync",
        ["last_sync_errors"] = "Last Sync Errors",
        ["lookup"] = "Lookup & Assign",
        ["backup"] = "Backup/Restore",
        ["developer"] = "Developer",
    },
    ["order"] = {
        "about",
        "introduction",
        "sharesync",
        "last_sync_errors",
        "lookup",
        "backup",
        "developer",
    },
    ["buttons"] = {},
    ["buttonref"] = {},
    ["tabframe"] = {},
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

    -- action buttons
    self.db.global.actionButtons = {}
    for i = 1, 12 do
        table.insert(self.db.global.actionButtons, i, tostring(i))
    end

    -- action button translation
    if not self.db.global.actionButtonTranslation then
        self.db.global.actionButtonTranslation = {}
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
            type = "",
            bar = "",
            btn = "",
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

    -- character restore data
    if not self.db.char.restore then
        self.db.char.restore = {}
    end
    if not self.db.char.restore.choice then
        self.db.char.restore.choice = {}
    end
    if not self.db.char.restore.choice.backupDttm then
        self.db.char.restore.choice.backupDttm = L["none"]
    end
    if not self.db.char.restore.choice.actionBar then
        self.db.char.restore.choice.actionBar = L["none"]
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
        self.db.profile.mytab = "introduction"
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
    Function:   GetActionBarValues
    Purpose:    Get the action bar values.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarValues()
    return self.db.global.actionBars
end

--[[---------------------------------------------------------------------------
    Function:   GetActionButtonValues
    Purpose:    Get the action button values.
-----------------------------------------------------------------------------]]
function ABSync:GetActionButtonValues()
    return self.db.global.actionButtons
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionBar
    Purpose:    Get the last action bar for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionBar()
    return self.db.char.actionLookup.bar or ""
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionBar
    Purpose:    Set the last action bar for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionBar(value)
    self.db.char.actionLookup.bar = value
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionButton
    Purpose:    Get the last action button for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionButton()
    return self.db.char.actionLookup.btn or ""
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionButton
    Purpose:    Set the last action button for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionButton(value)
    self.db.char.actionLookup.btn = value
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
        data = {},
        name = L["Unknown"],
        has = L["no"]
    }

    if actionType == "spell" then
        -- get spell details: data, name, hasSpell
        lookupInfo.data = self:GetSpellDetails(actionID)

        -- update details
        lookupInfo.name = lookupInfo.data.name
        lookupInfo.has = lookupInfo.data.hasSpell
    elseif actionType == "item" then
        -- get item details
        lookupInfo.data = self:GetItemDetails(actionID)

        -- update details
        lookupInfo.name = lookupInfo.data.finalItemName
        lookupInfo.has = lookupInfo.data.hasItem
    elseif actionType == "macro" then
        -- get macro details
        lookupInfo.data = self:GetMacroDetails(actionID)
        
        -- update details
        lookupInfo.name = lookupInfo.data.blizData.name
        lookupInfo.has = lookupInfo.data.hasMacro
    elseif actionType == "summonpet" then
        -- get pet data
        lookupInfo.data = self:GetPetDetails(actionID)

        -- update details
        lookupInfo.name = lookupInfo.data.name
        lookupInfo.has = lookupInfo.data.hasPet
    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        lookupInfo.data = self:GetMountinfo(actionID)

        -- update name
        lookupInfo.name = lookupInfo.data.name

        -- get mount journal index
        -- local mountJournalIndex = self:MountIDToOriginalIndex(mountInfo.mountID)

        -- has mount
        lookupInfo.has = lookupInfo.data.mountJournalIndex and "Yes" or "No"
    end

    -- finally return results
    return lookupInfo
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
function ABSync:GetPlayerNameFormatted(nospace)
    if not nospace then nospace = false end

    local unitName, unitServer = UnitFullName("player")

    if nospace == false then
        return unitName .. " - " .. unitServer
    else
        return unitName .. "-" .. unitServer
    end
end

--[[---------------------------------------------------------------------------
    Function:   FormatDateString
    Purpose:    Convert a date string from YYYYMMDDHHMISS or YYYY-MM-DD HH:MI:SS format to YYYY, Mon DD HH:MI:SS format.
-----------------------------------------------------------------------------]]
function ABSync:FormatDateString(dateString)
    -- validate input
    if dateString == L["never"] then
        return L["never"]
    elseif not dateString or type(dateString) ~= "string" then
        return "Invalid Date"
    end
    
    local year, month, day, hour, minute, second
    
    -- Check for YYYY-MM-DD HH:MI:SS format (19 characters with spaces and dashes)
    if string.len(dateString) == 19 and string.match(dateString, "^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$") then
        -- Extract components from YYYY-MM-DD HH:MI:SS
        year = string.sub(dateString, 1, 4)
        month = tonumber(string.sub(dateString, 6, 7))
        day = string.sub(dateString, 9, 10)
        hour = string.sub(dateString, 12, 13)
        minute = string.sub(dateString, 15, 16)
        second = string.sub(dateString, 18, 19)
        
    -- Check for YYYYMMDDHHMISS format (14 characters, all digits)
    elseif string.len(dateString) == 14 and string.match(dateString, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
        -- Extract components from YYYYMMDDHHMISS
        year = string.sub(dateString, 1, 4)
        month = tonumber(string.sub(dateString, 5, 6))
        day = string.sub(dateString, 7, 8)
        hour = string.sub(dateString, 9, 10)
        minute = string.sub(dateString, 11, 12)
        second = string.sub(dateString, 13, 14)
        
    else
        return "Invalid Date"
    end
    
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
    Function:   RemoveFrameChildren
    Purpose:    Remove all children from a frame.
-----------------------------------------------------------------------------]]
function ABSync:RemoveFrameChildren(parent)
    -- if no scroll region, nothing to do
    if not parent then return end

    -- loop over children and remove them
    for i, child in ipairs({ parent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
        child = nil
    end

    -- remove all font strings and textures (regions)
    for _, region in ipairs({ parent:GetRegions() }) do
        region:Hide()
        region:SetParent(nil)
        region = nil
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
    local barName = barName or L["Unknown"]
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
    -- self:InstantiateDB(barName)

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

    -- update the check boxes in the share area
    ABSync:UpdateShareRegion()

    --@debug@
    -- if self.db.char.isDevMode == true then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToShare", barName, (value and "Yes" or "No"))) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   GetBarToSync
    Purpose:    Check if a specific bar is set to sync for a specific player.
-----------------------------------------------------------------------------]]
-- TODO: change from profile db to name-server-spec db
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
    local barName = L["Unknown"]

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

--[[---------------------------------------------------------------------------
    Function:   PlaceActionOnBar
    Purpose:    Place a specific action on a specific action bar and button.
-----------------------------------------------------------------------------]]
function ABSync:PlaceActionOnBar(actionID, actionType, actionBar, actionButton)
    -- translate action bar number into action bar name
    actionBar = self.db.global.actionBars[actionBar]
    --@debug@
    -- if self.db.char.isDevMode == true then self:Print(("(%s) ActionID: %s, ActionType: %s, ActionBar: %s, ActionButton: %s"):format("PlaceActionOnBar", tostring(actionID), tostring(actionType), tostring(actionBar), tostring(actionButton))) end
    --@end-debug@

    -- translate action bar and button into button assignments; for example Action Bar 4 & Button 9 is Action Button 33.
    local buttonID = self.db.global.actionButtonTranslation[actionBar][actionButton]

    -- get action details
    local actionDetails = self:GetActionData(actionID, actionType)

    -- something picked up?
    local pickedUp = false

    -- response
    local response = {
        msg = "Not Picked Up - Unknown"
    }

    -- place action on bar based on type
    if actionType == "spell" then
        C_Spell.PickupSpell(actionID)
        pickedUp = true
    elseif actionType == "item" then
        if actionDetails.data.userItemCount > 0 and actionDetails.data.isToy == false then
            C_Item.PickupItem(actionID)
            pickedUp = true
            response.msg = "Picked Up"
        elseif actionDetails.data.isToy == true then
            C_ToyBox.PickupToyBoxItem(actionID)
            pickedUp = true
            response.msg = "Picked Up"
        elseif actionDetails.data.userItemCount == 0 and actionDetails.data.isToy == false then
            response.msg = "Not Picked Up - Item not in inventory!"
        end
    elseif actionType == "macro" then
        PickupMacro(actionDetails.name)
        pickedUp = true
    elseif actionType == "summonpet" then
        C_PetJournal.PickupPet(actionID)
        pickedUp = true
    elseif actionType == "summonmount" then
        C_MountJournal.Pickup(actionDetails.mountJournalIndex)
        pickedUp = true
    end

    -- place action and clear the cursor
    PlaceAction(tonumber(buttonID))
    ClearCursor()
end

--[[---------------------------------------------------------------------------
    Function:   BeginRestore
    Purpose:    Start the restore process for a single backup and action bar combination.
-----------------------------------------------------------------------------]]
function ABSync:BeginRestore(button)
    -- disable button
    button:Disable()

    -- refresh current bar data
    self:GetActionBarData()

    -- trigger message
    self:Print(("Restore Triggered for Backup \"%s\" for Action Bar \"%s\""):format(self:FormatDateString(self.db.char.restore.choice.backupDttm), self.db.char.restore.choice.actionBar))

    -- trigger the update with the backup date time and a true value for isRestore
    self:UpdateActionBars(self.db.char.restore.choice.backupDttm, true)

    -- enable button
    button:Enable()
end

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
    StaticPopupDialogs["ACTIONBARSYNC_BACKUP_NAME"] = {
        text = L["Enter a name for this backup:"],
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
            self.EditBox:SetText(L["Default Name"])
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
        StaticPopup_Show("ACTIONBARSYNC_BACKUP_NAME")
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
    Function:   GetSharedByWithOutSpec
    Purpose:    Split a player-server-spec string into player and server components. Used for macro comparison.
-----------------------------------------------------------------------------]]
function ABSync:GetSharedByWithOutSpec(str)
    -- Find the position of the last hyphen
    local lastHyphen = str:match(".*()%-")
    if lastHyphen then
        local before = str:sub(1, lastHyphen - 1)
        local after = str:sub(lastHyphen + 1)
        return before, after
    else
        -- No hyphen found, return the whole string and nil
        return str, nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarDifferences
    Purpose:    Compare two action bar button data tables.
                If isRestore is true then compare the backup data to the current data.
                If isRestore is false then compare the shared data to the current data.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarDifferences(backupdttm, isRestore)
    -- check parameters
    if not isRestore or isRestore == nil then isRestore = false end

    -- instantiate variables
    local differences = {}
    local differencesFound = false

    -- define what values to check
    local checkValues = { "sourceID", "actionType", "subType" }

    -- determine differences
    if isRestore == false then
        -- compare the global barsToSync data to the user's current action bar data
        -- loop over only the bars the character wants to sync
        for barName, sharedby in pairs(self.db.profile.barsToSync) do
            if sharedby ~= false then
                -- print(("Bar Name: %s, Shared By: %s, Button ID: %s"):format(barName, sharedby, tostring(buttonID)))
                -- loop over the shared data
                for buttonID, buttonData in pairs(self.db.global.barsToSync[barName][sharedby]) do
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
    else
        -- loop over the backup data looking for the specific entry
        for _, backupRow in ipairs(self.db.char.backup) do
            -- print("here1")
            -- verify the row has the matching date/time
            if backupRow.dttm == backupdttm then
                -- print("here2")
                -- loop over the action bars
                for barName, barData in pairs(backupRow.data) do
                    -- print("here3")
                    -- loop over the buttons
                    for buttonID, buttonData in pairs(barData) do
                        -- loop over checkValues
                        for _, testit in ipairs(checkValues) do
                            --@debug@
                            -- print(("Test It: %s, Button Data: %s, Current Data: %s"):format(testit, tostring(buttonData[testit]), tostring(self.db.char.currentBarData[barName][buttonID][testit])))
                            --@end-debug@
                            -- compare values
                            if buttonData[testit] ~= self.db.char.currentBarData[barName][buttonID][testit] then
                                -- print("here6")
                                differencesFound = true
                                table.insert(differences, {
                                    shared = buttonData,
                                    current = self.db.char.currentBarData[barName][buttonID],
                                    barName = barName,
                                    sharedBy = L["restore"],
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    -- capture last diff data
    if isRestore == true then
        self.db.char.lastDiffDataRestore = differences
    else
        self.db.char.lastDiffData = differences
    end

    return differences, differencesFound
end

--[[---------------------------------------------------------------------------
    Function:   UpdateActionBars
    Purpose:    Compare the sync action bar data to the current action bar data and override current action bar buttons.
    Todo:       Streamline this fuction to use LookUp action to remove duplicated code.
-----------------------------------------------------------------------------]]
function ABSync:UpdateActionBars(backupdttm, isRestore)
    -- check parameters
    if not isRestore or isRestore == nil then isRestore = false end

    --@debug@
    if self.db.char.isDevMode == true then self:Print(("(%s) Starting update process. Is Restore? %s"):format("UpdateActionBars", isRestore and "Yes" or "No")) end
    --@end-debug@

    -- store differences
    local differences, differencesFound = self:GetActionBarDifferences(backupdttm, isRestore)

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
                link = diffData.shared.blizData.link or L["Unknown"],
                sharedby = diffData.sharedBy,
                msg = ""
            }

            --@debug@
            -- if self.db.char.isDevMode == true then self:Print("Item Type: " .. tostring(diffData.shared.actionType)) end
            --@end-debug@

            -- track if something was updated to action bar
            local buttonUpdated = false

            --[[ process based on type ]]

            -- if unknown then shared action bar has no button there, if current char has a button in that position remove it
            if err.type == L["Unknown"] and diffData.current.name ~= L["Unknown"] then
                -- call function to remove a buttons action
                self:RemoveButtonAction(err.buttonID)

                -- button was updated
                buttonUpdated = true

            elseif err.type == "spell" then
                -- review base ID vs source ID and override with base ID
                if diffData.shared.blizData.baseID and diffData.shared.blizData.baseID ~= diffData.shared.sourceID then
                    err.id = diffData.shared.blizData.baseID
                    --@debug@
                    if self.db.char.isDevMode == true then self:Print(("(%s) Overriding SourceID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"):format("UpdateActionBars", tostring(err.name), tostring(diffData.shared.sourceID), tostring(diffData.shared.blizData.baseID))) end
                    --@end-debug@
                end

                -- verify if user has spell
                local hasSpell = self:CharacterHasSpell(err.id)

                -- report error if player does not have the spell
                --@debug@
                -- print("Does player have spell? " .. tostring(hasSpell) .. ", Spell Name: " .. tostring(err.name) .. ", Spell ID: " .. tostring(err.id))
                --@end-debug@
                if hasSpell == L["no"] then
                    -- update message to show character doesn't have the spell
                    err["msg"] = L["unavailable"]

                    -- insert the error record into tracking table
                    table.insert(errors, err)

                -- proceed if player has the spell
                -- make sure we have a name that isn't unknown
                elseif err.name ~= L["Unknown"] then
                    -- set the action bar button to the spell
                    C_Spell.PickupSpell(err.id)
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

                --@debug@
                -- print(("Item Name: %s, Item ID: %s, Item Count: %s, Is Toy? %s"):format(tostring(err.name), tostring(err.id), tostring(itemCount), tostring(diffData.shared.isToy and "Yes" or "No")))
                --@end-debug@

                -- if the user has the item, then add it to their action bar as long as the name is not unknown
                if itemCount > 0 then
                    -- item exists
                    if err.name ~= L["Unknown"] and diffData.shared.isToy == false then
                        -- set the action bar button to the item
                        C_Item.PickupItem(err.id)
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
                    --@debug@
                    -- print("toy found: " .. err.name)
                    --@end-debug@
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
                -- parse out character and server
                local sharedByWithOutSpec = self:GetSharedByWithOutSpec(diffData.sharedBy)
                -- print("Char and Server: " .. tostring(sharedByWithOutSpec) .. ", Player Name Formatted: " .. tostring(self:GetPlayerNameFormatted(true)))

                -- if the shared macro is character based then no way to get the details so don't place it as it will get this characters macro in the same position, basically wrong macro then
                if diffData.shared.macroType == ABSync.MacroType.character and sharedByWithOutSpec ~= self:GetPlayerNameFormatted(true) then
                    err["msg"] = L["charactermacro"]
                    table.insert(errors, err)
                
                -- if macro name is found proceed
                elseif err.name ~= L["Unknown"] then
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
                -- get mount location in journal
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
            if self.db.char.isDevMode == true then self:Print((L["Action Bar Sync encountered errors during a sync; key: '%s':"]):format(backupdttm)) end
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
    Function:   GetActionButtonData
    Purpose:    Retrieve action button data based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetActionButtonData(actionID, btnName)
    -- get action type and ID information
    local actionType, infoID, subType = GetActionInfo(actionID)

    -- instantiate the return table
    local returnData = {
        blizData = {},
        actionType = actionType or L["Unknown"],
        subType = subType or L["Unknown"],
        actionID = actionID,
        originalSourceID = infoID,
        buttonID = buttonID,
        btnName = btnName,
        name = L["Unknown"],
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
        returnData.isTalent = spellInfo.isTalent
        returnData.isPvp = spellInfo.isPvp
        returnData.link = spellInfo.blizData.link

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
        self:Print((L["Action Button '%s' has an unrecognized type of '%s'. Adding issue to Scan Errors and skipping...lots more text."]):format(btnName, tostring(actionType)))

        -- add to scan errors
        self.db.char.scanErrors = {
            actionID = actionID,
            btnName = btnName,
            actionType = actionType,
            infoID = infoID,
            subType = subType
        }
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
            local barName = string.gsub(btnName, L["Button%d+$"], "")

            -- translate and replace barName into the blizzard visible name in settings for the bars
            local barName = ABSync.blizzardTranslate[barName] or L["Unknown"]

            -- skip bar if unknown
            if barName == L["Unknown"] then
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

                -- insert details into button translation table
                if not self.db.global.actionButtonTranslation[barName] then
                    self.db.global.actionButtonTranslation[barName] = {}
                end
                self.db.global.actionButtonTranslation[barName][buttonData.barPosn] = buttonData.actionID
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
    -- enable development mode
    self.db.char.isDevMode = true

    -- force close the window
    self.ui.frame.mainFrame:Hide()

    -- give user status
    self:Print("Development Mode: Enabled")
end

--[[---------------------------------------------------------------------------
    Function:   DisableDevelopment
    Purpose:    Disable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:DisableDevelopment()
    if self.db.profile.mytab == "developer" then
        -- switch to default tab if the user is on the developer tab
        self.db.profile.mytab = "introduction"
    end

    -- disable development mode
    self.db.char.isDevMode = false

    -- force close the window
    self.ui.frame.mainFrame:Hide()

    -- give user status
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
        elseif arg:lower() == "fonts" then
            ABSync:CreateFontStringExamplesFrame():Show()
        else

        -- elseif arg:lower() == "spec" then
        --     local specializationIndex = C_SpecializationInfo.GetSpecialization()
        --     self:Print(("Current Specialization Index: %s"):format(tostring(specializationIndex)))
        --     local specId, name, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)
        --     self:Print(("Specialization ID: %d, Name: %s"):format(specId, name or L["Unknown"]))
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
    -- self:InstantiateDB(nil)
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

    --[[ trying to process cursor changed is CRAZY...giving up for now...

        2025Sep18 Further Research to try and fix spell Switch Flight Style
        -----
        When picking up the spell from the spellbook:
        - the CURSOR_CHANGED event fires once with newCursorType = 3 (spell cursor)
        - the GetCursorInfo for type 3 cursor type shows a spell ID of 436854
        Not important but when placing the spell on the action bar, the CURSOR_CHANGED event fires again with newCursorType = 0 (default cursor).
        When removing the spell from the action bar:
        - the CURSOR_CHANGED event fires again with newCursorType = 3 (spell cursor)
        - the GetCursorInfo for type 3 cursor type shows a spell ID of 460003 and the baseSpellID of 436854! 
          Expectation was the same spell ID of 436854 with baseSpellID of 0 since those were the values when it was placed.
        - the button icon changes based on what flight mode the character is curently in but the spell ID's do not change
    ]]
    -- self:RegisterEvent("CURSOR_CHANGED", function(event, isDefault, newCursorType, oldCursorType, oldCursorVirtualID)
    --     self:Print("Event - CURSOR_CHANGED")
    --     self:Print(("Event: %s, isDefault: %s, newCursorType: %s, oldCursorType: %s, oldCursorVirtualID: %s"):format(event, tostring(isDefault), tostring(newCursorType), tostring(oldCursorType), tostring(oldCursorVirtualID)))

    --     if newCursorType == 3 then -- 3 is the spell cursor type
    --         local spell, spellIndex, booktype, spellID, baseSpellID = GetCursorInfo()
    --         self:Print(("Spell on Cursor: %s, Spell Index: %s, Book Type: %s, SpellID: %s, BaseSpellID: %s"):format(tostring(spell or L["Unknown"]), tostring(spellIndex or L["Unknown"]), tostring(booktype or L["Unknown"]), tostring(spellID or L["Unknown"]), tostring(baseSpellID or L["Unknown"])))
    --     end
    --     --@debug@
    --     -- if ABSync.isDevMode == false then
    --     --     ABSync:PrintMountInfo(isDefault, newCursorType, oldCursorType, oldCursorVirtualID)
    --     -- end
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
    Function:   UpdateShareTab
    Purpose:    Update the share tab last scan edit box with the latest scan date and time.
-----------------------------------------------------------------------------]]
-- function ABSync:UpdateShareTab(playerID, funcName)
--     -- update the data in the lastScan edit box
--     self.ui.editbox.lastScan:SetText(self.db.char.lastScan or L["noscancompleted"])

--     -- update the action bar list
--     self.ui.group.shareFrame:ReleaseChildren()
--     self:CreateShareCheckboxes(playerID, funcName)
-- end

function ABSync:GetCheckboxOffsetY(checkbox)
    return ABSync.constants.ui.checkbox.size + ABSync.constants.ui.checkbox.padding + checkbox.Text:GetStringWidth()
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
    Function:   UncheckAllChildCheckboxes
    Purpose:    Uncheck all child checkboxes, except the one just clicked, in the given frame.
    Inputs:     frame       - parent frame containing the checkboxes
                checkbox    - checkbox that was just clicked; don't uncheck it
-----------------------------------------------------------------------------]]
function ABSync:UncheckAllChildCheckboxes(frame, checkbox)
    if frame:GetNumChildren() > 0 then
        for idx, child in ipairs({frame:GetChildren()}) do
            if child:IsObjectType("CheckButton") == true then
                if child ~= checkbox then
                    child:SetChecked(false)
                end
            end
        end
    end
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
    Function:   ShowErrorLog
    Purpose:    Open custom UI to show last sync errors to user.
-----------------------------------------------------------------------------]]
function ABSync:ShowUI()
    -- create main frame
    self.ui.frame.mainFrame = ABSync:CreateMainFrame()

    -- create tab group
    ABSync:CreateTabSystem(self.ui.frame.mainFrame)

    -- create content area
    local contentFrame = ABSync:CreateContentFrame(self.ui.frame.mainFrame)
    ABSync.ui.contentFrame = contentFrame

    -- show initial tab
    local tabkey = self.db.profile.mytab or "introduction"
    self:ShowTabContent(tabkey)
    local buttonID = ABSync.uitabs["buttonref"][tabkey]
    PanelTemplates_SetTab(ABSync.uitabs["tabframe"], buttonID)

    -- display the frame
    self.ui.frame.mainFrame:Show()
end

--[[---------------------------------------------------------------------------
    Function:   ShowTabContent
    Purpose:    Show the content for the selected tab.
-----------------------------------------------------------------------------]]
function ABSync:ShowTabContent(tabKey)
    -- Clear content frame
    for i = 1, ABSync.ui.contentFrame:GetNumChildren() do
        local child = select(i, ABSync.ui.contentFrame:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    -- switch to the selected tab
    if tabKey == "about" then
        self.db.profile.mytab = "about"
        -- tabs\About.lua
        self:CreateAboutFrame(ABSync.ui.contentFrame)
    elseif tabKey == "introduction" then
        self.db.profile.mytab = "introduction"
        -- tabs\Introduction.lua
        self:CreateIntroductionFrame(ABSync.ui.contentFrame)
    elseif tabKey == "sharesync" then
        self.db.profile.mytab = "sharesync"
        -- tabs\ShareSync.lua
        self:CreateShareSyncFrame(ABSync.ui.contentFrame)
    elseif tabKey == "last_sync_errors" then
        self.db.profile.mytab = "last_sync_errors"
        -- tabs\LastSyncErrors.lua
        self:CreateLastSyncErrorFrame(ABSync.ui.contentFrame)
    elseif tabKey == "lookup" then
        self.db.profile.mytab = "lookup"
        -- tabs\Lookup.lua
        self:CreateLookupFrame(ABSync.ui.contentFrame)
    elseif tabKey == "backup" then
        self.db.profile.mytab = "backup"
        -- tabs\Restore.lua
        self:CreateBackupFrame(ABSync.ui.contentFrame)
    elseif tabKey == "developer" then
        self.db.profile.mytab = "developer"
        -- tabs\Developer.lua
        self:CreateDeveloperFrame(ABSync.ui.contentFrame)
    end
end

-- [[ Replace all AceGUI Code with Standard UI Code ]]

--[[---------------------------------------------------------------------------
    Function:   CreateMainFrame
    Purpose:    Create the main frame for the addon UI.
-----------------------------------------------------------------------------]]
function ABSync:CreateMainFrame()   
    -- Get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    -- set initial sizes
    local frameWidth = screenWidth * 0.4
    local frameHeight = screenHeight * 0.4
    
    -- Use PortraitFrameTemplate which is more reliable in modern WoW
    local frame = CreateFrame("Frame", "ActionBarSyncMainFrame", UIParent, "PortraitFrameTemplate")
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetTitle("Action Bar Sync")
    frame:SetPortraitToAsset("Interface\\Icons\\inv_misc_coinbag_special")
    
    -- Enable escape key functionality following WoW addon patterns
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    
    -- Register frame for escape key handling using WoW's standard system
    tinsert(UISpecialFrames, "ActionBarSyncMainFrame")
    
    -- finally return the frame
    return frame
end

--[[---------------------------------------------------------------------------
    Function:   CreateTabSystem
    Purpose:    Create a tab system at the bottom of the main frame.
-----------------------------------------------------------------------------]]
function ABSync:CreateTabSystem(parent)
    -- create a frame to hold the tabs
    local tabFrame = CreateFrame("Frame", nil, parent)
    -- Position tabs at the bottom of the frame like Collections Journal
    tabFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, -5)
    tabFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, -5)
    tabFrame:SetHeight(30)
    
    local tabs = {}
    local tabButtons = {}
    
    -- create tab data
    local tabData = {}
    for _, tabkey in ipairs(ABSync.uitabs.order) do
        local tabname = ABSync.uitabs.tabs[tabkey]
        
        -- if developer mode disabled, skip the developer tab, otherwise add the tab
        if tabkey ~= "developer" or (tabkey == "developer" and self.db.char.isDevMode == true) then
            table.insert(tabData, { name = tabname, key = tabkey })
        end
    end
    
    -- Create tab buttons using PanelTabButtonTemplate like Collections addon
    for i, tab in ipairs(tabData) do
        -- Use PanelTabButtonTemplate for authentic Collections UI styling
        local button = CreateFrame("Button", nil, tabFrame, "PanelTabButtonTemplate")
        button:SetID(i)
        button:SetText(tab.name)
        
        -- Use PanelTemplates functions for proper tab behavior
        PanelTemplates_TabResize(button, 0)
        
        button:SetScript("OnClick", function(self)
            -- Use PanelTemplates to handle tab selection properly
            PanelTemplates_SetTab(tabFrame, self:GetID())
            
            -- Update visual states for all tabs
            for j, btn in ipairs(tabButtons) do
                if j == self:GetID() then
                    -- Active tab
                    PanelTemplates_SelectTab(btn)
                else
                    -- Inactive tab
                    PanelTemplates_DeselectTab(btn)
                end
            end
            
            ABSync:ShowTabContent(tab.key)
        end)
        
        -- Position tabs horizontally with proper spacing for Collections style
        if i == 1 then
            button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 11, 2)
        else
            button:SetPoint("LEFT", tabButtons[i-1], "RIGHT", -15, 0)
        end
        
        -- add button to table
        tabButtons[i] = button

        -- add translation keys to addon global
        ABSync.uitabs["buttonref"][tab.key] = i
    end
    
    -- Set up the tab frame with PanelTemplates
    PanelTemplates_SetNumTabs(tabFrame, #tabData)
    PanelTemplates_SetTab(tabFrame, 1)
    
    -- initialize first tab to users last, if not set to introduction
    local initialTab = ABSync.uitabs["buttonref"][self.db.profile.mytab or "introduction"]
    if tabButtons[initialTab] then
        PanelTemplates_SelectTab(tabButtons[1])
        for j = 2, #tabButtons do
            PanelTemplates_DeselectTab(tabButtons[j])
        end
    end
    
    -- assign tab frame to addon global
    ABSync.uitabs["tabframe"] = tabFrame

    -- assign buttons to addon global
    ABSync.uitabs["buttons"] = tabButtons
end

--EOF