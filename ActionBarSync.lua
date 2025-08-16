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

    -- default db data
    local dbDefaults = {
        profile = {
            actionBars = {},
            checkOnLogon = false,
            barData = {},
            barOwner = {},
            barsToSync = {},
        },
        char = {
            backup = {},
            lastSynced = "",
            syncErrors = {},
            lastSyncErrorDttm = "",
            lastScan = L["never"],
            actionLookup = {
                type = "spell",         -- language independent
                id = "",
                name = ""
            }
        }
    }
    -- initialize the db
    self.db = LibStub("AceDB-3.0"):New("ActionBarSyncDB", dbDefaults)

    -- Instantiate Option Table
    self.ActionBarSyncOptions = {
        name = L["actionbarsynctitle"],
        handler = ABSync,
        type = "group",
        args = {
            syncsettings = {
                name = L["syncsettings"],
                desc = L["syncsettingsdesc"],
                type = "group",
                order = 1,
                args = {
                    hdr1 = {
                        name = L["introduction"],
                        type = "header",
                        order = 10
                    },
                    intro = {
                        name = L["introname"],
                        type = "description",
                        order = 11
                    },
                    step1hdr = {
                        name = L["step1hdr"],
                        type = "header",
                        order = 20
                    },
                    step1 = {
                        name = L["step1desc"],
                        type = "description",
                        order = 21,
                    },
                    step2hdr = {
                        name = L["step2hdr"],
                        type = "header",
                        order = 30
                    },
                    step2 = {
                        name = L["step2desc"],
                        type = "description",
                        order = 31,
                    },
                    scan = {
                        name = L["scan"],
                        type = "execute",
                        order = 32,
                        func = function()
                            ABSync:GetActionBarData()
                        end
                    },
                    lastscan = {
                        name = L["lastscanname"],
                        desc = L["lastscandescr"],
                        type = "input",
                        order = 33,
                        disabled = true,
                        get = function(info)
                            return ABSync.db.char.lastScan or L["never"]
                        end,
                    },
                    step3hdr = {
                        name = L["step3hdr"],
                        type = "header",
                        order = 40
                    },
                    step3 = {
                        name = L["step3desc"],
                        type = "description",
                        order = 41,
                    },
                    bars2sync = {
                        name = L["bars2sync"],
                        values = function(info, value)
                            return ABSync:GetActionBarNames()
                        end,
                        type = "multiselect",
                        order = 100,
                        get = function(info, key)
                            return ABSync:GetBarsToSync(key)
                        end,
                        set = function(info, key, value)
                            ABSync:SetBarToSync(key, value)
                        end
                    },
                    finalhdr = {
                        name = L["finalhdr"],
                        type = "header",
                        order = 110
                    },
                    finaldescr = {
                        name = L["finaldescr"],
                        type = "description",
                        order = 111,
                    },
                    finalstep = {
                        name = L["finalstep"],
                        width = "full",
                        type = "toggle",
                        order = 112,
                        get = function(info, key)
                            -- if the value doesn't exist set a default value
                            if not ABSync.db.profile.checkOnLogon then
                                ABSync.db.profile.checkOnLogon = false
                            end
                            return ABSync.db.profile.checkOnLogon
                        end,
                        set = function(info, key, value)
                            ABSync.db.profile.checkOnLogon = value
                        end
                    }
                }
            },
            sync = {
                name = L["synctitle"],
                desc = L["synctitledesc"],
                type = "group",
                order = 2,
                args = {
                    triggerhdr = {
                        name = L["triggerhdr"],
                        type = "header",
                        order = 1
                    },
                    lastupdated = {
                        name = L["lastupdatedname"],
                        width = "full",
                        desc = L["lastupdateddesc"],
                        type = "input",
                        order = 2,
                        get = function(info)
                            return ABSync:GetLastSyncedOnChar() or "Never"
                        end,
                        disabled = true
                    },
                    trigger = {
                        name = L["triggername"],
                        desc = L["triggerdesc"],
                        type = "execute",
                        order = 3,
                        func = function()
                            self:BeginSync()
                        end
                    }
                }
            },
            -- lastSyncErrors = {
            --     name = L["lastsyncerrorsname"],
            --     desc = L["lastsyncerrorsdesc"],
            --     type = "group",
            --     order = 4,
            --     args = {
            --         errors = {
            --             name = function(info)
            --                return ABSync:GetErrorText(info)
            --             end,
            --             type = "description",
            --             order = 20,
            --             width = "full",
            --         }
            --     }
            -- },
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
    Function:   GetMountinfo
    Purpose:    Retrieve mount information based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMountinfo(actionID)
    -- defaults
    showDialog = showDialog or false

    -- dialog to show all mount data
    StaticPopupDialogs["ACTIONBARSYNC_MOUNT_INFO"] = {
        text = "",
        button1 = "OK",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    
    -- first call to get mount information based on the action bar action id
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(actionID)

    -- then get additional details on the mount
    local mountInfo = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)

    -- instantiate a variable for the mount display id
    local mountDisplayID = ""

    -- loop over mount data and get display ID
    for _, mountData in ipairs(mountInfo) do
        for key, value in pairs(mountData) do
            if key == "creatureDisplayID" then
                mountDisplayID = value
            end
        end
    end

    --@debug@
    if self.isLive == false then self:Print((L["getmountinfolookup"]):format(name, mountID, tostring(mountDisplayID))) end
    --@end-debug@

    -- finally return the spell name
    return {name = name, mountID = mountID, displayID = mountDisplayID}
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarNames
    Purpose:    Return the list/table of action bar names.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarNames()
    -- check to make sure a data fetch has happened, if not return No Scan Completed
    local barNames = {}
    if not self.db.profile.actionBars or #self.db.profile.actionBars == 0 then
        -- debug
        -- self:Print("No action bars found")
        -- add an entry to let user know a can has not been done; this will get overwritten once a scan is done.
        table.insert(barNames, L["noscancompleted"])
        return barNames
    end

    -- if we get to here just return the list of bar names from the scan
    return self.db.profile.actionBars
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
    Function:   GetBarsToSync
    Purpose:    Get the bars set to be synced for the current profile.
-----------------------------------------------------------------------------]]
function ABSync:GetBarsToSync(key)
    -- check that actionBars variable exists
    if not self.db.profile.actionBars then
        self.db.profile.actionBars = {}
    end
    -- check if the key exists in actionBars, if so fetch it, if not set to "Unknown"
    local barName = L["unknown"]
    if self.db.profile.actionBars[key] then
        barName = self.db.profile.actionBars[key]
    end
    -- check for barsToSync
    if not self.db.profile.barsToSync then
        self.db.profile.barsToSync = {}
    end
    -- check for the barName in barsToSync
    local returnVal = self.db.profile.barsToSync[barName] or false

    -- finally return a value
    return returnVal
end

--[[---------------------------------------------------------------------------
    Function:   GetPlayerNameFormatted
    Purpose:    Get the owner of the specified action bar.
-----------------------------------------------------------------------------]]
function ABSync:GetPlayerNameFormatted()
    local unitName, unitServer = UnitFullName("player")
    return unitName .. "-" .. unitServer
end

--[[---------------------------------------------------------------------------
    Function:   SetBarToSync
    Purpose:    Update the db for current profile when the user changes the values in the options on which bars to sync.
-----------------------------------------------------------------------------]]
function ABSync:SetBarToSync(key, value)
    -- set the bars to sync
    local barName = self.db.profile.actionBars[key]

    -- only the bar owner can uncheck an action bar, prevent other users
    local playerID = self:GetPlayerNameFormatted()

    -- make sure barOwner exists
    if not self.db.profile.barOwner then
        self.db.profile.barOwner = {}
    end

    -- get the bar owner or set to Unknown if not found
    local barOwner = self.db.profile.barOwner[barName] or "Unknown"

    -- if the player and the bar owner do not match or the bar owner is not unknown then let user know they can't uncheck this bar from syncing
    if playerID ~= barOwner and barOwner ~= "Unknown" then
        -- show popup
        StaticPopupDialogs["ACTIONBARSYNC_NOT_BAR_OWNER"] = {
            text = (L["actionbarsync_not_bar_owner_text"]):format(barName, barOwner),
            button1 = "OK",
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ACTIONBARSYNC_NOT_BAR_OWNER")
        return
    end

    -- get count of records in currentBarData
    local currentBarDataCount = 0
    for _ in pairs(self.db.profile.currentBarData) do
        currentBarDataCount = currentBarDataCount + 1
    end

    -- if currentBarData is emtpy then let user know they must trigger a sync first
    if currentBarDataCount == 0 then
        StaticPopupDialogs["ACTIONBARSYNC_NO_SCAN"] = {
            text = L["actionbarsync_no_scan_text"],
            button1 = L["ok"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ACTIONBARSYNC_NO_SCAN")
        return
    end

    --@debug@
    -- if self.isLive == false then self:Print("Set Bar '" .. tostring(barName) .. "' to sync? " .. (value and "Yes" or "No") .. " - Starting...") end
    --@end-debug@

    -- instantiate barsToSync if it doesn't exist
    if not self.db.profile.barsToSync then
        self.db.profile.barsToSync = {}
    end

    -- set the bar to sync values: true or false based on the value passed into this function
    self.db.profile.barsToSync[barName] = value
    
    -- if the value is true, add the bar data to the barData table
    if value == true then
        -- set the bar owner
        self.db.profile.barOwner[barName] = playerID

        -- based on value add or remove the bar data
        for buttonID, buttonData in pairs(self.db.profile.currentBarData[barName]) do
            -- make sure barData exists
            if not self.db.profile.barData then
                self.db.profile.barData = {}
            end

            -- make sure the barName entry exists in barData
            if not self.db.profile.barData[barName] then
                self.db.profile.barData[barName] = {}
            end

            -- add the button data to the barData table
            self.db.profile.barData[barName][buttonID] = {
                actionType = buttonData.actionType,
                id = buttonData.id,
                subType = buttonData.subType,
                name = buttonData.name
            }
        end
    else
        -- if the bar is not set to sync, remove it from the bar data
        self.db.profile.barData[barName] = {}
        -- remove bar owner
        self.db.profile.barOwner[barName] = nil
    end

    --@debug@ let the user know the value is changed only when developing though
    if self.isLive == false then self:Print((L["setbartosync_final_notification"]):format("SetBarToSync", barName, (value and "Yes" or "No"))) end
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
    
    -- make certain the variable exists to hold bars to sync info
    if self.db.profile.barsToSync then
        -- count entries
        for barName, syncOn in pairs(self.db.profile.barsToSync) do
            if syncOn == true then
                barsToSync = true
                break
            end
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
    self.db.char.lastSynced = date("%Y-%m-%d %H:%M:%S")

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
        if syncOn == true then
            --@debug@
            if self.isLive == false then self:Print((L["triggerbackup_notify"]):format(barName)) end
            --@end-debug@

            -- make sync data found
            syncDataFound = true

            -- instantiate the barName index
            backupData[barName] = {}

            -- get the current bar data for the current barName; not the profile bar data to sync
            for buttonID, buttonData in pairs(self.db.profile.currentBarData[barName]) do
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
    Function:   UpdateActionBars
    Purpose:    Compare the sync action bar data to the current action bar data and override current action bar buttons.
    Todo:       Streamline this fuction to use LookUp action to remove duplicated code.
-----------------------------------------------------------------------------]]
function ABSync:UpdateActionBars(backupdttm)
    -- store differences
    local differences = {}
    local differencesFound = false

    -- compare the profile barData data to the user's current action bar data
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        if syncOn == true then
            for buttonID, buttonData in pairs(self.db.profile.barData[barName]) do
                -- define what values to check
                local checkValues = { "id", "actionType", "subType" }
                
                -- loop over checkValues
                for _, testit in ipairs(checkValues) do
                    if buttonData[testit] ~= self.db.profile.currentBarData[barName][buttonID][testit] then
                        differencesFound = true
                        table.insert(differences, {
                            buttonID = buttonID,
                            actionType = buttonData.actionType,
                            id = buttonData.id,
                            name = buttonData.name,
                            barName = barName,
                            position = string.match(buttonData.name, "(%d+)$") or L["unknown"],
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
        -- track any errors
        local errors = {}

        -- loop over differences an apply changes
        for _, diffData in ipairs(differences) do
            -- create readable button name
            local buttonName = (L["updateactionbars_button_name_template"]):format(diffData.barName, diffData.position)

            -- instantiate standard error fields
            local err = {
                barName = diffData.barName,
                barPos = diffData.position,
                buttonID = diffData.buttonID,
                actionType = diffData.actionType,
                id = diffData.id,
            }

            -- get the name of the id based on action type
            if diffData.actionType == "spell" then
                -- get spell info
                local spellData = C_Spell.GetSpellInfo(diffData.id)
                local spellName = spellData and spellData.name or L["unknown"]

                -- determine if player has the spell, if not report error
                local hasSpell = C_Spell.IsCurrentSpell(diffData.id) or false

                -- report error if player does not have the spell
                if hasSpell == false then
                    -- table.insert(errors, {
                    --     buttonID = diffData.buttonID,
                    --     actionType = diffData.actionType,
                    --     id = diffData.id,
                    --     name = diffData.name,
                    --     descr = (L["updateactionbars_player_doesnot_have_spell"]):format(buttonName, spellName, diffData.id)
                    -- })
                    err["name"] = spellName
                    err["msg"] = "Unavailable"
                    table.insert(errors, err)

                -- proceed if player has the spell
                else                    
                    if spellName then
                        -- set the action bar button to the spell
                        C_Spell.PickupSpell(spellName)
                        PlaceAction(tonumber(diffData.buttonID))
                        ClearCursor()
                    else
                        -- if spell name not found then log error
                        -- table.insert(errors, {
                        --     buttonID = diffData.buttonID,
                        --     actionType = diffData.actionType,
                        --     id = diffData.id,
                        --     name = diffData.name,
                        --     descr = (L["updateactionbars_spell_not_found"]):format(buttonName, diffData.id, diffData.buttonID)
                        -- })
                        err["name"] = diffData.name
                        err["msg"] = L["notfound"]
                        table.insert(errors, err)
                    end
                end
            elseif diffData.actionType == "item" then
                local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(diffData.id)

                -- need a string as itemName or error occurs if the item actually doesn't exist
                local checkItemName = itemName or L["unknown"]

                --@debug@
                if self.isLive == false then self:Print((L["updateactionbars_debug_item_name"]):format(diffData.id, checkItemName)) end
                --@end-debug@

                -- does player have the item
                local itemCount = C_Item.GetItemCount(diffData.id)

                -- add to action bar if two tests pass...
                -- if the user has the item
                if itemCount > 0 then
                    -- item exists
                    if itemName then
                        -- set the action bar button to the item
                        C_Item.PickupItem(itemName)
                        PlaceAction(tonumber(diffData.buttonID))
                        ClearCursor()
                    else
                        -- if item name not found then log error
                        -- table.insert(errors, {
                        --     buttonID = diffData.buttonID,
                        --     actionType = diffData.actionType,
                        --     id = diffData.id,
                        --     name = diffData.name,
                        --     descr = (L["updateactionbars_item_not_found"]):format(buttonName, diffData.id, diffData.buttonID)
                        -- })
                        err["name"] = checkItemName
                        err["msg"] = L["notfound"]
                        table.insert(errors, err)
                    end

                -- if player doesn't have item then log as error
                else
                    -- table.insert(errors, {
                    --     buttonID = diffData.buttonID,
                    --     actionType = diffData.actionType,
                    --     id = diffData.id,
                    --     name = diffData.name,
                    --     descr = (L["updateactionbars_user_doesnot_have_item"]):format(buttonName, checkItemName, diffData.id)
                    -- })
                    err["name"] = checkItemName
                    err["msg"] = L["notinbags"]
                    table.insert(errors, err)
                end
            elseif diffData.actionType == "macro" then
                -- get macro information: name, iconTexture, body, isLocal
                local macroName = GetMacroInfo(diffData.id)

                -- if macro name is found proceed
                if macroName then
                    -- set the action bar button to the macro
                    PickupMacro(macroName)
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()

                -- if macro name is not found then record error and remove whatever is in the bar
                else
                    -- if macro name not found then log error
                    -- table.insert(errors, {
                    --     buttonID = diffData.buttonID,
                    --     actionType = diffData.actionType,
                    --     id = diffData.id,
                    --     name = diffData.name,
                    --     descr = (L["updateactionbars_macro_not_found"]):format(buttonName, diffData.id)
                    -- })
                    err["name"] = L["unknown"]
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)

                    -- remove if not found
                    PickupAction(tonumber(diffData.buttonID))
                    ClearCursor()
                end
            elseif diffData.actionType == "summonpet" then
                -- get pet information
                local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(diffData.id)

                -- if pet name is found proceed
                if name then
                    -- set the action bar button to the pet
                    C_PetJournal.PickupPet(diffData.id)
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()
                else
                    -- if pet name not found then log error
                    -- table.insert(errors, {
                    --     buttonID = diffData.buttonID,
                    --     actionType = diffData.actionType,
                    --     id = diffData.id,
                    --     name = diffData.name,
                    --     descr = (L["updateactionbars_pet_not_found"]):format(buttonName, diffData.id)
                    -- })
                    err["name"] = L["unknown"]
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end
            elseif diffData.actionType == "summonmount" then
                -- get the mount spell name; see function details for why we get its spell name
                local mountInfo = self:GetMountinfo(diffData.id)

                -- if mount name is found proceed
                if mountInfo.name then
                    C_MountJournal.Pickup(tonumber(mountInfo.displayID))
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()
                else
                    -- if mount name not found then log error
                    -- table.insert(errors, {
                    --     buttonID = diffData.buttonID,
                    --     actionType = diffData.actionType,
                    --     id = diffData.id,
                    --     name = diffData.name,
                    --     descr = (L["updateactionbars_mount_not_found"]):format(buttonName, diffData.id)
                    -- })
                    err["name"] = L["unknown"]
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end

            -- notfound means the button was empty
            elseif diffData.actionType == "notfound" then
                PickupAction(tonumber(diffData.buttonID))
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

--[[---------------------------------------------------------------------------
    Function:   GetActionBarData
    Purpose:    Fetch current action bar button data.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarData()
    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")
    local WoW10 = StdFuncs:IsWoW10()

    -- reset actionBars
    self.db.profile.actionBars = {}
    
    -- reset currentBarData
    self.db.profile.currentBarData = {}
    
    -- get action bar details
    for btnName, btnData in pairs(_G) do
        -- filter out by proper naming of the action bars done by blizzard
        -- need to know if this changes based on language!
        if string.find(btnName, "^ActionButton%d+$") or string.find(btnName, "^MultiBarBottomLeftButton%d+$") or string.find(btnName, "^MultiBarBottomRightButton%d+$") or string.find(btnName, "^MultiBarLeftButton%d+$") or string.find(btnName, "^MultiBarRightButton%d+$") or string.find(btnName, "^MultiBar%d+Button%d+$") then
            -- make up a name for each bar using the button names by removing the button number
            local barName = string.gsub(btnName, L["getactionbardata_button_name_template"], "")

            -- translate barName into the blizzard visible name in settings for the bars
            local barName = ABSync.blizzardTranslate[barName] or L["unknown"]

            -- get action ID and type information
            local actionID = btnData:GetPagedID()

            -- get action type and ID information
            local actionType, id, subType = GetActionInfo(actionID)

            --@debug@
            -- debug when if no action info returned
            -- if self.isLive == false and (not actionType or not id or not subType) then
            --     local missingValues = {}
            --     if not actionType then table.insert(missingValues, "Action Type") end
            --     if not id then table.insert(missingValues, "ID") end
            --     if not subType then table.insert(missingValues, "Sub Type") end
            --     self:Print(("Action Bar Button '%s' is missing the following: %s"):format(btnName, table.concat(missingValues, ", ")))
            -- end
            --@end-debug@

            -- build the info table
            local info = {
                -- actionID = actionID or "notfound",
                name = btnName,
                actionType = actionType or L["notfound"],
                id = id or L["notfound"],
                subType = subType or L["notfound"]
            }

            -- check if barName is already in actionBars
            local barNameInserted = false
            for _, name in ipairs(self.db.profile.actionBars) do
                if name == barName then
                    barNameInserted = true
                    break
                end
            end

            -- add the bar name to the actionBars table if it doesn't exist
            if barNameInserted == false then
                table.insert(self.db.profile.actionBars, barName)
            end

            -- check if barName is already in currentBarData
            local barNameInserted = false
            for name, _ in pairs(self.db.profile.currentBarData) do
                if name == barName then
                    barNameInserted = true
                    break
                end
            end

            -- add the bar name to the currentBarData table if it doesn't exist
            if barNameInserted == false then
                self.db.profile.currentBarData[barName] = {}
            end

            -- insert the info table into the current action bar data
            self.db.profile.currentBarData[barName][tostring(actionID)] = info
        end
    end

    -- sort the actionBars table
    table.sort(self.db.profile.actionBars, function(a, b)
        return a < b
    end)

    -- update db
    self.db.char.lastScan = date("%Y-%m-%d %H:%M:%S")
    
    -- sync keys of actionBars to barsToSync and barOwner
    for _, barName in ipairs(self.db.profile.actionBars) do
        -- instantiate barsToSync if it doesn't exist
        if not self.db.profile.barsToSync then
            self.db.profile.barsToSync = {}
        end

        -- if the barName is not in barsToSync then add it with default value of false
        if not self.db.profile.barsToSync[barName] then
            self.db.profile.barsToSync[barName] = false
        end

        -- instantiate barOwner if it doesn't exist
        if not self.db.profile.barOwner then
            self.db.profile.barOwner = {}
        end

        -- if the bar is not in barOwner then add it with default value of "Unknown"
        if not self.db.profile.barOwner[barName] then
            self.db.profile.barOwner[barName] = L["unknown"]
        end
    end

    -- sync the updated data into the sync settings only when the same character is triggering the update
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        if syncOn == true then
            local playerID = self:GetPlayerNameFormatted()
            local barOwner = self.db.profile.barOwner[barName] or L["unknown"]
            if playerID == barOwner then
                -- get the bar index
                local barIndex = nil
                for index, name in ipairs(self.db.profile.actionBars) do
                    if name == barName then
                        barIndex = index
                        break
                    end
                end
                -- trigger the profile sync
                self:SetBarToSync(barIndex, syncOn)
            end
        end
    end

    -- trigger update for options UI
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)

    -- let user know its done
    if self.isLive == false then self:Print(L["getactionbardata_final_notification"]) end
end

--[[---------------------------------------------------------------------------
    Function:   SlashCommand
    Purpose:    Respond to all slash commands.
-----------------------------------------------------------------------------]]
function ABSync:SlashCommand(text)
    -- if no text is provided, show the options dialog
    if text == nil or text == "" then
        LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
        return
    end
    -- get args
    for arg in string.gmatch(self:GetArgs(text), "%S+") do
        if arg:lower() == "options" then
            LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
        elseif arg:lower() == "sync" then
            self:BeginSync()
        elseif arg:lower() == "errors" then
            self:ShowErrorLog()
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
        if ABSync.isLive == false then self:Print(L["registerevents_addon_loaded"]) end
    end)

    self:RegisterEvent("PLAYER_LOGIN", function()
        if ABSync.isLive == false then self:Print(L["registerevents_player_login"]) end

        -- trigger the collection of action bar button data
        ABSync:ActionBarData()
    end)

    self:RegisterEvent("PLAYER_LOGOUT", function()
        if ABSync.isLive == false then self:Print(L["registerevents_player_logout"]) end

        -- clear currentBarData and actionBars when the code is live
        if ABSync.isLive == true then
            ABSync.db.profile.currentBarData = {}
        end
    end)

    self:RegisterEvent("VARIABLES_LOADED", function()
        if ABSync.isLive == false then self:Print(L["registerevents_variables_loaded"]) end
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

--[[---------------------------------------------------------------------------
    Function:   ShowErrorLog
    Purpose:    Open custom UI to show last sync errors to user.
-----------------------------------------------------------------------------]]
function ABSync:ShowErrorLog()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- columns
    local columns = {"Bar Name", "Bar Pos", "Button ID", "Action Type", "Action Name", "Action ID", "Message"}
    local columnLoop = {"barName", "barPos", "buttonID", "actionType", "name", "id", "msg"}

    -- Get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    -- Create the main frame
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Action Bar Sync - Sync Errors")
    -- TODO: format the dttm or store a formatted value instead...
    frame:SetStatusText(("Last Sync Error: %s"):format(self.db.char.lastSyncErrorMsg or "-"))
    frame:SetLayout("Flow")
    local frameWidth = screenWidth * 0.8
    local frameHeight = screenHeight * 0.8
    frame:SetWidth(frameWidth)
    frame:SetHeight(frameHeight)

    -- Create a scroll container for the spreadsheet
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    frame:AddChild(scroll)

    -- determine column width
    -- 5px for spacing
    local columnWidth = ((frameWidth - 5) / #columns) - 5

    -- Create header row
    local header = AceGUI:Create("SimpleGroup")
    header:SetLayout("Flow")
    header:SetFullWidth(true)
    for _, colName in ipairs(columns) do
        local label = AceGUI:Create("Label")
        label:SetText("|cff00ff00" .. colName .. "|r")
        label:SetWidth(columnWidth)
        header:AddChild(label)
    end
    scroll:AddChild(header)

    -- loop over sync errors
    for _, errorRcd in ipairs(self.db.char.syncErrors) do
        -- continue to next row if key doesn't match
        if errorRcd.key == self.db.char.lastSyncErrorDttm then
            -- loop over the rows
            for _, errorRow in ipairs(errorRcd.errors) do
                -- set up row group of columns
                local rowGroup = AceGUI:Create("SimpleGroup")
                rowGroup:SetLayout("Flow")
                rowGroup:SetFullWidth(true)

                -- loop over the column defintions
                for _, colDef in ipairs(columnLoop) do
                    local cell = AceGUI:Create("Label")
                    cell:SetText(tostring(errorRow[colDef] or "-"))
                    cell:SetWidth(columnWidth)
                    rowGroup:AddChild(cell)
                end
                scroll:AddChild(rowGroup)
            end
        end
    end

    -- display the frame
    frame:Show()
end