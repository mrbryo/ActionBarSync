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
ABSync.MacroType = {}
ABSync.MacroType.general = "general"
ABSync.MacroType.character = "character"

-- ui tabs
ABSync.uitabs = {
    ["tabs"] = {
        ["about"] = "About",
        ["instructions"] = "Instructions",
        ["share"] = "Share",
        ["sync"] = "Sync",
        ["last_sync_errors"] = "Last Sync Errors"
    },
    ["order"] = {
        "about",
        "instructions",
        "share",
        "sync",
        "last_sync_errors"
    }
}

--[[---------------------------------------------------------------------------
    Function:   ABSync:OnInitialize
    Purpose:    Initialize the addon and set up default values.
-----------------------------------------------------------------------------]]
function ABSync:OnInitialize()
    --@debug@
    if self.isLive == false then self:Print(L["initializing"]) end
    --@end-debug@

    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")

    -- initialize the db
    self.db = LibStub("AceDB-3.0"):New("ActionBarSyncDB")

    -- Instantiate Option Table
    self.ActionBarSyncOptions = {
        name = L["actionbarsynctitle"],
        handler = ABSync,
        type = "group",
        args = {
            actionlookup = {
                name = L["actionlookupname"],
                desc = L["actionlookupdesc"],
                type = "group",
                order = 5,
                args = {
                    intro = {
                        name = L["actionlookupintro"],
                        type = "description",
                        order = 0,
                        width = "full",
                    },
                    objectname = {
                        name = L["objectname"],
                        desc = L["objectnamedesc"],
                        type = "input",
                        width = "full",
                        order = 1,
                        get = function(info)
                            return ABSync:GetLastActionName()
                        end,
                        set = function(info, value)
                            ABSync:SetLastActionName(value)
                        end
                    },
                    actionID = {
                        name = L["actionidname"],
                        desc = L["actioniddesc"],
                        type = "input",
                        order = 2,
                        get = function(info)
                            return ABSync:GetLastActionID()
                        end,
                        set = function(info, value)
                            ABSync:SetLastActionID(value)
                        end
                    },
                    actionType = {
                        name = L["actiontypename"],
                        desc = L["actiontypedesc"],
                        type = "select",
                        order = 3,
                        values = function()
                            return ABSync:GetActionTypeValues()
                        end,
                        get = function(info)
                            return ABSync:GetLastActionType()
                        end,
                        set = function(info, value)
                            ABSync:SetLastActionType(value)
                        end
                    },
                    lookupButton = {
                        name = L["lookupbuttonname"],
                        desc = L["lookupbuttondesc"],
                        type = "execute",
                        order = 4,
                        func = function()
                            ABSync:LookupAction()
                        end
                    }
                }
            }
        }
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
    if self.isLive == false then self:Print(L["initialized"]) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDB
    Purpose:    Ensure the DB has all the necessary values. Can run anytime to check and fix all data with default values.
-----------------------------------------------------------------------------]]
function ABSync:InstantiateDB(barName)
    -- get current playerID
    local playerID = self:GetPlayerNameFormatted()

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

    -- character specific action lookup data
    if not self.db.char.actionLookup then
        self.db.char.actionLookup = {
            name = "",
            id = "",
            type = ""
        }
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
    -- if self.isLive == false then
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
    if not self.db.char.actionLookup.name then
        self.db.char.actionLookup = {}
        self.db.char.actionLookup.name = ""
    end
    return self.db.char.actionLookup.name
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionName
    Purpose:    Set the last action name for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionName(value)
    if not self.db.char.actionLookup then
        self.db.char.actionLookup = {}
    end
    self.db.char.actionLookup.name = value
end

--[[---------------------------------------------------------------------------
    Function:   GetLastActionID
    Purpose:    Get the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ABSync:GetLastActionID()
    if not self.db.char.actionLookup.id then
        self.db.char.actionLookup.id = ""
    end
    return self.db.char.actionLookup.id
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionID
    Purpose:    Set the last action ID for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionID(value)
    if not self.db.char.actionLookup then
        self.db.char.actionLookup = {}
    end
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
    if not self.db.char.actionLookup then
        self.db.char.actionLookup = {}
    end
    if not self.db.char.actionLookup.type then
        self.db.char.actionLookup.type = "spell"
    end
    return self.db.char.actionLookup.type or ""
end

--[[---------------------------------------------------------------------------
    Function:   SetLastActionType
    Purpose:    Set the last action type for the current character.
-----------------------------------------------------------------------------]]
function ABSync:SetLastActionType(value)
    if not self.db.char.actionLookup then
        self.db.char.actionLookup = {}
    end
    self.db.char.actionLookup.type = value
end

--[[---------------------------------------------------------------------------
    Function:   LookupAction
    Purpose:    Look up the action based on the last entered action type and ID.
-----------------------------------------------------------------------------]]
function ABSync:LookupAction()
    -- dialog to show results
    StaticPopupDialogs["ACTIONBARSYNC_LOOKUP_RESULT"] = {
        text = "",
        button1 = L["ok"],
        timeout = 0,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- get the action type
    local actionType = self:GetLastActionType()
    
    -- get the action ID
    local actionID = self:GetLastActionID()

    --@debug@
    -- "Looking up Action - Type: %s - ID: %s"
    if self.isLive == false then self:Print((L["lookingupactionnotifytext"]):format(actionType, actionID)) end
    --@end-debug@

    -- check for valid action type
    if not self.actionTypeLookup[actionType] then
        StaticPopupDialogs["ACTIONBARSYNC_INVALID_ACTION_TYPE"] = {
            text = L["invalidactiontype"],
            button1 = L["ok"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ACTIONBARSYNC_INVALID_ACTION_TYPE")
        return
    end

    -- instantiate variable to store final message
    local dialogMessage = ""

    -- perform lookup based on type
    if actionType == "spell" then
        -- get spell info
        local spellData = C_Spell.GetSpellInfo(actionID)
        local spellName = spellData and spellData.name or L["unknown"]

        -- assign to field
        self:SetLastActionName(spellName)

        -- determine if player has the spell, if not report error
        local hasSpell = C_Spell.IsCurrentSpell(actionID) and L["yes"] or L["no"]

        -- generate message
        dialogMessage = (L["spelllookupresult"]):format(actionID, spellName, hasSpell)
    elseif actionType == "item" then
        -- get item info
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(actionID)

        -- does player have the item
        local itemCount = C_Item.GetItemCount(actionID)

        -- assign results
        self:SetLastActionName(itemName)

        -- generate message
        local hasItem = (itemCount > 0) and L["yes"] or L["no"]
        dialogMessage = (L["itemlookupresult"]):format(actionID, itemName, hasItem)
    elseif actionType == "macro" then
        -- get macro information: name, iconTexture, body, isLocal
        local macroName, macroIcon, macroBody = GetMacroInfo(actionID)

        -- does player have this macro?
        local hasMacro = macroName and L["yes"] or L["no"]

        -- fix macroName for output
        macroName = macroName or L["unknown"]

        -- assign to field
        self:SetLastActionName(macroName)

        -- generate message
        dialogMessage = (L["macrolookupresult"]):format(actionID, macroName, hasMacro)
    elseif actionType == "summonpet" then
        -- get pet information
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(actionID)

        -- check if has pet
        local hasPet = name and L["yes"] or L["no"]

        -- assign to field
        self:SetLastActionName(name)        

        -- generate message
        dialogMessage = (L["petlookupresult"]):format(actionID, name, hasPet)
    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        local mountInfo = self:GetMountinfo(actionID)

        -- has mount
        local hasMount = mountInfo.name and "Yes" or "No"

        -- assign to field
        self:SetLastActionName(mountInfo.name)

        -- generate message
        dialogMessage = (L["mountlookupresult"]):format(actionID, mountInfo.name, hasMount)
    end

    -- show results in dialog
    StaticPopupDialogs["ACTIONBARSYNC_LOOKUP_RESULT"].text = dialogMessage
    StaticPopup_Show("ACTIONBARSYNC_LOOKUP_RESULT")
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
        -- print("Using profile database")
        tmpdb = self.db.profile

    -- always get global if source doesn't match a valid type
    else
        -- print("Using global database")
        tmpdb = self.db.global
    end

    -- if actionBars variable exist then continue
    if tmpdb.actionBars then
        -- print("here1")
        -- if actionBars is not a table then return 0
        if tostring(type(tmpdb.actionBars)) == "table" then
            -- print("here2")
            count = #tmpdb.actionBars
        end
    end

    -- finally return the count
    -- print("here3")
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

        -- finally return bar name
        return barNames
    else
        -- loop over actionBars and rebuild table to figure this out
        -- for k, v in pairs(self.db.global.actionBars) do
        --     table.insert(barNames, v)
        -- end
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
       TODO:    Accept a timestamp parameter, parse it into the format show in the date command in this function.
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
    local playerID = self:GetPlayerNameFormatted()

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
    if self.isLive == false then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToShare", barName, (value and "Yes" or "No"))) end
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
    if self.isLive == false then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToSync", barName, (value and "Yes" or "No"))) end
    --@end-debug@
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
            if self.isLive == false then self:Print((L["triggerbackup_notify"]):format(barName)) end
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

function ABSync:RemoveButtonAction(buttonID)
    PickupAction(tonumber(buttonID))
    ClearCursor()
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
                            -- buttonID = buttonID,
                            -- actionType = buttonData.actionType,
                            -- id = buttonData.sourceID,
                            -- name = buttonData.name,
                            -- position = buttonData.barPosn,
                            -- currentButton = self.db.char.currentBarData[barName][buttonID],
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

        -- loop over differences and apply changes
        for _, diffData in ipairs(differences) do
            -- create readable button name
            -- local buttonName = (L["updateactionbars_button_name_template"]):format(diffData.barName, diffData.position)

            -- instantiate standard error fields
            local err = {
                barName = diffData.barName,
                barPos = diffData.shared.barPosn,
                buttonID = diffData.shared.actionID,
                type = diffData.shared.actionType,
                name = diffData.shared.name,
                id = diffData.shared.sourceID,
                sharedby = diffData.sharedBy,
                msg = ""
            }

            -- if the button position is populated, remove the item
            -- the button currently being processed should always be in currentBarData because a sync is required to update action bars...
            -- check to make sure the buttonID exists in the barName table
            -- if self.db.char.currentBarData[diffData.barName][diffData.buttonID] then
            --     -- remove the action bar button
            --     PickupAction(tonumber(diffData.buttonID))
            --     ClearCursor()
            -- end

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
                -- see if character has spell
                local hasSpell = self:CharacterHasSpell(err.id)

                -- report error if player does not have the spell
                if hasSpell == false then
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
                --@debug@
                if self.isLive == false then self:Print((L["updateactionbars_debug_item_name"]):format(err.id, err.name)) end
                --@end-debug@

                -- does player have the item
                local itemCount = self:GetItemCount(err.id)

                -- if the user has the item, then add it to their action bar as long as the name is not unknown
                if itemCount > 0 then
                    -- item exists
                    if err.name ~= L["unknown"] then
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
                elseif isToy == true then
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
            elseif actionType == "summonmount" then
                -- get the mount spell name; see function details for why we get its spell name
                -- local mountInfo = self:GetMountinfo(diffData.id)

                -- if mount name is found proceed
                if mountInfo.name then
                    C_MountJournal.Pickup(tonumber(mountInfo.displayID))
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()

                    -- button was updated
                    buttonUpdated = true
                else
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end

            -- proper response if action type is not recognized
            else
                -- TODO: unknown type response
            end

            -- remove if not found and button has an action
            if err.current.sourceID ~= -1 and buttonUpdated == false then
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
            if self.isLive == false then self:Print((L["actionbarsync_sync_errors_found"]):format(backupdttm)) end
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
            LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)
        end
    end
end

function ABSync:GetItemCount(buttonID)
    local itemCount = C_Item.GetItemCount(buttonID)
    return itemCount
end

function ABSync:CharacterHasSpell(spellID)
    local hasSpell = C_Spell.IsCurrentSpell(spellID) or false
    return hasSpell
end

--[[---------------------------------------------------------------------------
    Function:   GetSpellDetails
    Purpose:    Retrieve spell information based on the spell ID.
-----------------------------------------------------------------------------]]
function ABSync:GetSpellDetails(spellID, buttonID)
    -- get spell info: name, iconID, originalIconID, castTime, minRange, maxRange, spellID
    local spellData = C_Spell.GetSpellInfo(spellID)
    local spellName = spellData and spellData.name or L["unknown"]

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

    -- if checkItemName is unknown then see if its a toy
    local isToy = false
    local toyData = {}
    -- if checkItemName == L["unknown"] then
    local toyID, toyName, toyIcon, toyIsFavorite, toyHasFanfare, toyItemQuality = C_ToyBox.GetToyInfo(itemID)
    if toyName then
        print(("toy found: %s (%s)"):format(tostring(toyName or L["unknown"]), toyID))
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
    -- end

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
        toyData = toyData
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
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetPetDetails
    Purpose:    Retrieve pet information based on the pet ID.
-----------------------------------------------------------------------------]]
function ABSync:GetPetDetails(petID)
    -- get pet information
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)

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
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMountinfo
    Purpose:    Retrieve mount information based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMountinfo(mountID)
    -- defaults
    -- showDialog = showDialog or false

    -- dialog to show all mount data
    -- StaticPopupDialogs["ACTIONBARSYNC_MOUNT_INFO"] = {
    --     text = "",
    --     button1 = "OK",
    --     timeout = 0,
    --     whileDead = true,
    --     hideOnEscape = true,
    -- }
    
    -- first call to get mount information based on the action bar action id
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, sourceMountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)

    -- make sure certain values are not nil
    name = name or L["unknown"]

    -- then get additional details on the mount: createDisplayID, isVisible
    local mountInfo = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)

    -- instantiate a variable for the mount display id
    local mountDisplayID = L["unknown"]

    -- loop over mount data and get display ID
    local mountFound = false
    if type(mountInfo) == "table" then
        for _, mountData in ipairs(mountInfo) do
            for key, value in pairs(mountData) do
                if key == "creatureDisplayID" then
                    mountDisplayID = value
                    mountFound = true
                    break
                end
            end

            -- break loop if mount found
            if mountFound then
                break
            end
        end
    end

    --@debug@
    if self.isLive == false then self:Print((L["getmountinfolookup"]):format(name, mountID, tostring(mountDisplayID))) end
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
        displayID = mountDisplayID or -1,
        mountID = mountID
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

        -- location in the action bar: 1-12
        barPosn = tonumber(string.match(btnName, "(%d+)$")) or -1,
    }

    -- get the name of the id based on action type
    if actionType == "spell" then
        -- get spell details: data, name, hasSpell
        local spellInfo = self:GetSpellDetails(infoID, buttonID)

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

    -- process items
    elseif actionType == "item" then
        -- get item details
        local itemInfo = self:GetItemDetails(infoID, buttonID)

        -- assign data
        returnData.name = itemInfo.finalItemName
        returnData.icon = itemInfo.blizData.itemTexture
        returnData.sourceID = itemInfo.itemID
        returnData.blizData = itemInfo.blizData
        returnData.isToy = itemInfo.isToy
        returnData.toyData = itemInfo.toyData

    elseif actionType == "macro" then
        -- get macro details
        local macroInfo = self:GetMacroDetails(infoID)

        -- assign data
        returnData.name = macroInfo.blizData.name
        returnData.icon = macroInfo.blizData.icon
        returnData.body = macroInfo.blizData.body
        returnData.sourceID = macroInfo.id
        returnData.blizData = macroInfo.blizData

    elseif actionType == "summonpet" then
        -- get pet data
        local petInfo = self:GetPetDetails(infoID)

        -- assign data
        returnData.name = petInfo.name
        returnData.icon = petInfo.blizData.icon
        returnData.blizData = petInfo.blizData
        returnData.sourceID = petInfo.petID

    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        local mountInfo = self:GetMountinfo(infoID)

        -- assign data
        returnData.name = mountInfo.name
        returnData.icon = mountInfo.blizData.icon
        returnData.sourceID = mountInfo.sourceID
        returnData.blizData = mountInfo.blizData
        returnData.displayID = mountInfo.displayID
        returnData.mountID = mountInfo.mountID
    end

    -- finally return the data
    return returnData
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
    local playerID = self:GetPlayerNameFormatted()
    
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
    if self.isLive == false then self:Print(L["getactionbardata_final_notification"]) end
    --@end-debug@
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
        -- elseif arg:lower() == "test" then
        --     self:NewUI()
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
    Function:   RegisterEvents
    Purpose:    Register all events for the addon.
-----------------------------------------------------------------------------]]
function ABSync:RegisterEvents()
    if ABSync.isLive == false then self:Print(L["registerevents_starting"]) end
	-- Hook to Action Bar On Load Calls
	-- self:Hook("ActionBarController_OnLoad", true)
	-- Hook to Action Bar On Event Calls
	-- self:Hook("ActionBarController_OnEvent", true)
    -- Register Events
    self:RegisterEvent("ADDON_LOADED", function()
        --@debug@
        if ABSync.isLive == false then self:Print(L["registerevents_addon_loaded"]) end
        --@end-debug@
    end)

    self:RegisterEvent("PLAYER_LOGIN", function()
        --@debug@
        if ABSync.isLive == false then self:Print(L["registerevents_player_login"]) end
        --@end-debug@

        self:EventPlayerLogin()
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self, event, isInitialLogin, isReload)
        -- only run these commands if this is the initial login
        if isInitialLogin == true then
            --@debug@
            if ABSync.isLive == false then ABSync:Print(L["registerevents_player_entering_world"]) end
            --@end-debug@

            -- run db initialize again but pass in barName to make sure all keys are setup for this barName
            ABSync:InstantiateDB(nil)

            -- get action bar data automatically if user has opted in through the settings checkbox
            if ABSync.db.profile.autoGetActionBarData then
                ABSync:GetActionBarData()
            end
        end
    end)

    self:RegisterEvent("PLAYER_LOGOUT", function()
        --@debug@
        if ABSync.isLive == false then self:Print(L["registerevents_player_logout"]) end
        --@end-debug@

        -- clear currentBarData and actionBars when the code is live
        if ABSync.isLive == true then
            ABSync.db.profile.currentBarData = {}
        end
    end)

    self:RegisterEvent("VARIABLES_LOADED", function()
        --@debug@
        if ABSync.isLive == false then self:Print(L["registerevents_variables_loaded"]) end
        --@end-debug@
    end)

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

-- Trigger code when addon is disabled.
function ABSync:OnDisable()
    -- TODO: Unregister Events?
    self:Print(L["disabled"])
end

function ABSync:GetCharacterList()
    -- Get the list of characters from the database
    local characterList = {}

    -- loop over the bar characters
    for charName, charData in pairs(self.db.profiles) do
        table.insert(characterList, charName)
    end

    -- sort the character list
    table.sort(characterList)

    -- finally return it
    return characterList
end

function ABSync:AddSyncRow(scroll, columnWidth, syncFrom, syncBarName)
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create the row group
    local rowGroup = AceGUI:Create("SimpleGroup")
    rowGroup:SetLayout("Flow")
    rowGroup:SetFullWidth(true)

    -- create delete checkbox column
    local deleteCell = AceGUI:Create("CheckBox")
    deleteCell:SetValue(false)
    deleteCell:SetCallback("OnValueChanged", function(_, _, value)
        -- handle delete checkbox logic
        self:Print(("Delete checkbox for character '%s' for bar '%s' was clicked!"):format(syncFrom, syncBarName))
    end)
    deleteCell:SetWidth(columnWidth[1])
    rowGroup:AddChild(deleteCell)

    -- add label to show character to sync from
    local characterCell = AceGUI:Create("Label")
    characterCell:SetText(syncFrom)
    characterCell:SetRelativeWidth(columnWidth[2])
    rowGroup:AddChild(characterCell)

    -- add label to show action bar name to sync
    local barCell = AceGUI:Create("Label")
    barCell:SetText(syncBarName)
    barCell:SetRelativeWidth(columnWidth[3])
    rowGroup:AddChild(barCell)

    -- add the row to the scroll region
    scroll:AddChild(rowGroup)
end

--[[---------------------------------------------------------------------------
    Function:   CreateAboutFrame
    Purpose:    Create the About frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateAboutFrame()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create the main about frame
    local aboutFrame = AceGUI:Create("SimpleGroup")
    aboutFrame:SetLayout("List")

    -- author
    local authorFrame = AceGUI:Create("SimpleGroup")
    authorFrame:SetLayout("Flow")
    authorFrame:SetFullWidth(true)
    aboutFrame:AddChild(authorFrame)
    local authorLabel = AceGUI:Create("Label")
    authorLabel:SetText(("Author: %s"):format(C_AddOns.GetAddOnMetadata("ActionBarSync", "Author")))
    authorLabel:SetFullWidth(true)
    authorFrame:AddChild(authorLabel)

    -- add note about resizing
    local resizeNote = AceGUI:Create("Label")
    resizeNote:SetText("|cffff0000Note:|r Even though window resize functions it doesn't work well. Resize slowly since it seems to redraw it as the cursor moves. I recommend using the default size. Reload the UI to restore it. I don't think its an issue with AceGUI but just a side effect of the WoW UI.")
    resizeNote:SetFullWidth(true)
    aboutFrame:AddChild(resizeNote)

    -- return the frame
    return aboutFrame
end

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
    local input = AceGUI:Create("EditBox")
    input:SetText(self.db.char.lastScan or L["noscancompleted"])
    input:SetFullWidth(true)
    input:SetDisabled(true) -- make it read-only
    scanFrame:AddChild(input)

    -- add scan button
    local button = AceGUI:Create("Button")
    button:SetText("Scan Now")
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        -- refresh of the shared data is done in this function too
        ABSync:GetActionBarData()
    end)
    scanFrame:AddChild(button)

    -- return the frame
    return scanFrame
end

--[[---------------------------------------------------------------------------
    Function:   CreateTriggerSyncFrame
    Purpose:    Create the Trigger Sync frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateTriggerSyncFrame()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create main frame
    local triggerSyncFrame = AceGUI:Create("InlineGroup")
    triggerSyncFrame:SetTitle("Trigger Sync")
    triggerSyncFrame:SetLayout("List")

    -- add last synced label
    local lastSyncedLabel = AceGUI:Create("Label")
    lastSyncedLabel:SetText("Last Synced on this Character")
    lastSyncedLabel:SetFullWidth(true)
    triggerSyncFrame:AddChild(lastSyncedLabel)

    -- add disabled edit box
    local lastSyncedInput = AceGUI:Create("EditBox")
    lastSyncedInput:SetText(self.db.char.lastSyncDttm or L["never"])
    lastSyncedInput:SetFullWidth(true)
    lastSyncedInput:SetDisabled(true) -- make it read-only
    triggerSyncFrame:AddChild(lastSyncedInput)

    -- add button to trigger sync
    local syncButton = AceGUI:Create("Button")
    syncButton:SetText("Sync Now")
    syncButton:SetFullWidth(true)
    syncButton:SetCallback("OnClick", function()
        self:BeginSync()
    end)
    triggerSyncFrame:AddChild(syncButton)

    -- return the frame
    return triggerSyncFrame
end

--[[---------------------------------------------------------------------------
    Function:   CreateLastSyncErrorFrame
    Purpose:    Create the Last Sync Error frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateLastSyncErrorFrame()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- create a group for the error scroll frame
    local lastErrorGroup = AceGUI:Create("InlineGroup")
    lastErrorGroup:SetTitle("Last Sync Errors")
    lastErrorGroup:SetLayout("Fill")
    lastErrorGroup:SetAutoAdjustHeight(false)
    lastErrorGroup:SetFullWidth(true)
    lastErrorGroup:SetHeight(300)

    -- columns
    local columns = {"Bar Name", "Bar Pos", "Button ID", "Action Type", "Action Name", "Action ID", "Message"}
    local columnLoop = {"barName", "barPos", "buttonID", "actionType", "name", "id", "msg"}

    -- Create a scroll container for the spreadsheet
    local errScroll = AceGUI:Create("ScrollFrame")
    errScroll:SetLayout("List")
    lastErrorGroup:AddChild(errScroll)

    -- determine column width
    -- 5px for spacing
    -- local columnWidth = ((frameWidth - 5) / #columns) - 5
    local columnWidth = 1/#columns

    -- Create header row
    local errHeader = AceGUI:Create("SimpleGroup")
    errHeader:SetLayout("Flow")
    errHeader:SetFullWidth(true)
    for _, colName in ipairs(columns) do
        local label = AceGUI:Create("Label")
        label:SetText("|cff00ff00" .. colName .. "|r")
        -- label:SetWidth(columnWidth)
        label:SetRelativeWidth(columnWidth)
        errHeader:AddChild(label)
    end
    errScroll:AddChild(errHeader)

    --@debug@
    -- if self.isLive == false then
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

    -- get count of syncErrors
    local syncErrorCount = 0
    for _ in ipairs(self.db.char.syncErrors) do
        syncErrorCount = syncErrorCount + 1
    end
    print("Sync Error Count: " .. tostring(syncErrorCount))

    -- loop over sync errors
    if syncErrorCount > 0 then
        for _, errorRcd in ipairs(self.db.char.syncErrors) do
            -- print("here1")
            -- continue to next row if key doesn't match
            if errorRcd.key == self.db.char.lastSyncErrorDttm then
                -- print("here2")
                -- loop over the rows
                for _, errorRow in ipairs(errorRcd.errors) do
                    -- print("here3")
                    -- set up row group of columns
                    local rowGroup = AceGUI:Create("SimpleGroup")
                    rowGroup:SetLayout("Flow")
                    rowGroup:SetFullWidth(true)

                    -- loop over the column defintions
                    for _, colDef in ipairs(columnLoop) do
                        -- print("here4")
                        local cell = AceGUI:Create("Label")
                        cell:SetText(tostring(errorRow[colDef] or "-"))
                        cell:SetWidth(columnWidth)
                        rowGroup:AddChild(cell)
                    end
                    errScroll:AddChild(rowGroup)
                end
            end
        end
    end

    -- finally return the frame
    return lastErrorGroup
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareFrame
    Purpose:    Create the share frame for selecting action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareFrame(playerID)
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
    local shareFrame = AceGUI:Create("InlineGroup")
    shareFrame:SetTitle("Share")
    shareFrame:SetLayout("Flow")
    mainShareFrame:AddChild(shareFrame)

    -- add a multiselect for sharing which action bars to share
    local actionBars = ABSync:GetActionBarNames(ABSync.profiletype["global"])
    local dataChanged = false
    for _, checkboxName in pairs(actionBars) do
        -- create a checkbox for each action bar
        local checkBox = AceGUI:Create("CheckBox")
        checkBox:SetLabel(checkboxName)

        -- determine checkbox value
        local checkboxValue = self:GetBarToShare(checkboxName, playerID)

        -- set the checkbox initial value
        checkBox:SetValue(checkboxValue)
        -- checkBox:SetFullWidth(true)

        -- set callback for when checkbox is clicked, only need value
        checkBox:SetCallback("OnValueChanged", function(data)
            -- keep for looking at data table values
            -- for k, v in pairs(data) do
            --     print(("Checkbox Data Key: %s - Value: %s"):format(k, tostring(v)))
            -- end

            -- update the profile barsToSync value
            self:SetBarToShare(checkboxName, data.checked)

            -- data has changed so update tracking variable
            dataChanged = true
        end)

        -- add the checkbox to the share frame
        shareFrame:AddChild(checkBox)
    end

    if dataChanged == true then
        -- trigger update for options UI
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)
    end

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
    local currentPlayerID = self:GetPlayerNameFormatted()

    -- create main frame
    local syncFrame = AceGUI:Create("SimpleGroup")
    syncFrame:SetLayout("Flow")
    syncFrame:SetFullWidth(true)
    parent:AddChild(syncFrame)

    -- create frame for check sync on login
    local loginCheckFrame = AceGUI:Create("InlineGroup")
    loginCheckFrame:SetTitle("Sync on Login")
    loginCheckFrame:SetLayout("List")
    loginCheckFrame:SetRelativeWidth(0.5)
    syncFrame:AddChild(loginCheckFrame)

    -- create checkbox for sync on login
    local loginCheckBox = AceGUI:Create("CheckBox")
    loginCheckBox:SetLabel("Enable Sync on Login")
    loginCheckBox:SetValue(self.db.profile.checkOnLogon)
    loginCheckBox:SetCallback("OnValueChanged", function(_, _, value)
        self.db.profile.checkOnLogon = value
    end)

    -- add checkbox to login check frame
    loginCheckFrame:AddChild(loginCheckBox)

    -- create frame for manual sync
    local manualSyncFrame = AceGUI:Create("InlineGroup")
    manualSyncFrame:SetTitle("Manual Sync")
    manualSyncFrame:SetLayout("List")
    manualSyncFrame:SetRelativeWidth(0.5)
    syncFrame:AddChild(manualSyncFrame)

    -- create button for manual sync
    local manualSyncButton = AceGUI:Create("Button")
    manualSyncButton:SetText("Sync Now")
    manualSyncButton:SetCallback("OnClick", function()
        self:BeginSync()
    end)
    manualSyncFrame:AddChild(manualSyncButton)

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
                end
            end
        end
    end

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
    Function:   ShowErrorLog
    Purpose:    Open custom UI to show last sync errors to user.
-----------------------------------------------------------------------------]]
function ABSync:ShowUI()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- get player
    local playerID = self:GetPlayerNameFormatted()

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
        table.insert(tabs, { text = tabname, value = tabkey })
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
            local aboutFrame = self:CreateAboutFrame()
            tabGroup:AddChild(aboutFrame)
        elseif group == "instructions" then
            local instructionsFrame = self:CreateInstructionsFrame()
            tabGroup:AddChild(instructionsFrame)
        elseif group == "share" then
            local shareFrame = self:CreateShareFrame(playerID)
            tabGroup:AddChild(shareFrame)
        elseif group == "sync" then
            -- local scrollWidth = tabGroup.frame:GetWidth()
            -- local scrollHeight = tabGroup.frame:GetHeight()
            -- print(("Scroll Container Size: %d x %d"):format(scrollWidth, scrollHeight))
            local syncFrame = self:CreateSyncFrame(tabGroup)
        elseif group == "last_sync_errors" then
            local lastSyncErrorFrame = self:CreateLastSyncErrorFrame()
            tabGroup:AddChild(lastSyncErrorFrame)
        end
    end)

    -- set the tab
    tabGroup:SelectTab(self.db.profile.mytab)

    -- finally add the tab group
    frame:AddChild(tabGroup)

    -- display the frame
    frame:Show()
end