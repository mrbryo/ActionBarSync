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
                        order = 1,
                    },
                    intro = {
                        name = L["introname"],
                        type = "description",
                        order = 2,
                    },
                    step1hdr = {
                        name = L["step1hdr"],
                        type = "header",
                        order = 10,
                    },
                    step1 = {
                        name = L["step1desc"],
                        type = "description",
                        order = 11,
                    },
                    step2hdr = {
                        name = L["step2hdr"],
                        type = "header",
                        order = 12,
                    },
                    step2 = {
                        name = L["step2desc"],
                        type = "description",
                        order = 13,
                    },
                    scan = {
                        name = L["scan"],
                        type = "execute",
                        order = 14,
                        func = function()
                            ABSync:GetActionBarData()
                        end
                    },
                    lastscan = {
                        name = L["lastscanname"],
                        desc = L["lastscandescr"],
                        type = "input",
                        order = 15,
                        disabled = true,
                        get = function(info)
                            return ABSync.db.char.lastScan or L["never"]
                        end,
                    },
                    step3hdr = {
                        name = L["step3hdr"],
                        type = "header",
                        order = 30,
                    },
                    step3 = {
                        name = L["step3desc"],
                        type = "description",
                        order = 31,
                    },

                    -- bars to sync for sharing with other characters
                    bars2sync = {
                        name = L["bars2sync"],
                        values = function(info, value)
                            local source = ABSync.profiletype["global"]
                            return ABSync:GetActionBarNames(source)
                        end,
                        type = "multiselect",
                        order = 32,
                        get = function(info, key)
                            local source = ABSync.profiletype["global"]
                            return ABSync:GetBarsToSync(source, key)
                        end,
                        set = function(info, key, value)
                            -- print(("Info: %s, Key: %s, Value: %s"):format(tostring(info), tostring(key), tostring(value)))
                            ABSync:SetBarToShare(key, value)
                        end,
                    },
                    step4hdr = {
                        name = L["step4hdr"],
                        type = "header",
                        order = 40,
                    },
                    step4 = {
                        name = L["step4desc"],
                        type = "description",
                        order = 41,
                    },

                    -- bars to sync in current characters UI
                    profilesync = {
                        name = L["profilesync"],
                        values = function(info, value)
                            local source = ABSync.profiletype["profile"]
                            return ABSync:GetActionBarNames()
                        end,
                        type = "multiselect",
                        order = 42,
                        get = function(info, key)
                            local source = ABSync.profiletype["profile"]
                            return ABSync:GetBarsToSync(key)
                        end,
                        set = function(info, key, value)
                            ABSync:SetBarToSync(key)
                        end,
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
                            return ABSync:GetLastSyncedOnChar() or L["never"]
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
    Function:   GetBarsToSync
    Purpose:    Get the bars set to be synced for the current profile.
-----------------------------------------------------------------------------]]
function ABSync:GetBarsToSync(source, key)
    -- initialize variables
    local barName = L["noscancompleted"]

    -- based on source we have slightly different processing
    if source == self.profiletype["profile"] then
        -- make sure actionBars exists
        if not self.db.profile.actionBars then
            self.db.profile.actionBars = {}
        end

        -- check if the key exists in actionBars, if so fetch it, if not set to "Unknown"
        print("Key: " .. tostring(key))
        if self.db.profile.actionBars[key] then
            barName = self.db.profile.actionBars[key]
        end

        -- check for barsToSync in profile
        if not self.db.profile.barsToSync then
            self.db.profile.barsToSync = {}
        end

        -- get the sync value for the bar, if not found return false
        if not self.db.profile.barsToSync[barName] then
            return false
        end

    elseif source == self.profiletype["global"] then
        -- make sure actionBars exists
        if not self.db.global.actionBars then
            self.db.global.actionBars = {}
        end

        -- check if the key exists in actionBars, if so fetch it, if not set to "Unknown"
        if self.db.global.actionBars[key] then
            barName = self.db.global.actionBars[key]
        end    
        
        -- check for barsToSync in global
        if not self.db.global.barsToSync then
            self.db.global.barsToSync = {}
        end

        -- get the sync value for the bar, if not found return false
        if not self.db.global.barsToSync[barName] then
            return false
        else
            -- get player id
            local playerID = self:GetPlayerNameFormatted()

            -- check if the owner matches the player id, if so return true, else false
            if self.db.global.barsToSync[barName].owner == playerID then
                return true
            else
                return false
            end
        end

    -- invalid profile type
    else
        return false
    end
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
    Function:   SetBarToShare
    Purpose:    Set the bar to share for the current global db settings.
-----------------------------------------------------------------------------]]
function ABSync:SetBarToShare(key, value)
    --@debug@
    print(("(%s) Key: %s, Value: %s"):format("SetBarToShare", tostring(key), tostring(value)))
    --@end-debug@

    -- initialize variables
    local barName = L["unknown"]
    local playerID = self:GetPlayerNameFormatted()

    -- initialize missing key dialog
    StaticPopupDialogs["ACTIONBARSYNC_INVALID_KEY"] = {
        text = (L["actionbarsync_invalid_key_text"]):format(key, source),
        button1 = L["ok"],
        timeout = 15,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- check global.actionBars
    if not self.db.global.actionBars then
        self.db.global.actionBars = {}
    end

    -- check for input key, if it doesn't exist then let user know and return false
    if not self.db.global.actionBars[key] then
        StaticPopup_Show("ACTIONBARSYNC_INVALID_KEY")
        return false
    end

    -- set bar name
    barName = self.db.global.actionBars[key]

    -- need to get the bar owner which is only under the global db
    -- make sure barsToSync exists under global
    if not self.db.global.barsToSync then
        self.db.global.barsToSync = {}
    end

    -- make sure the bar name exists, if not add it and set defaults
    if not self.db.global.barsToSync[barName] then
        self.db.global.barsToSync[barName] = {
            owner = L["noowner"],
            buttonsToSync = {},
        }
    end

    -- make sure owner exists, if not set the default
    if not self.db.global.barsToSync[barName].owner then
        self.db.global.barsToSync[barName].owner = L["noowner"]
    end

    -- finally...get bar owner
    local barOwner = self.db.global.barsToSync[barName].owner or L["noowner"]
    
    -- if the player and the bar owner do not match or the bar owner is not No Owner (meaning someone owns it) then let user know they can't uncheck this bar from syncing
    if playerID ~= barOwner and barOwner ~= L["noowner"] then
        -- show popup
        StaticPopupDialogs["ACTIONBARSYNC_NOT_BAR_OWNER"] = {
            text = (L["actionbarsync_not_bar_owner_text"]):format(barName, barOwner),
            button1 = L["ok"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ACTIONBARSYNC_NOT_BAR_OWNER")
        return
    end

    -- track if bar is found in currentBarData
    local barFound = false
    
    -- make sure currentBarData exists and is a table
    if type(self.db.profile.currentBarData) == "table" then
        -- make sure the bar name exists
        if not self.db.profile.currentBarData[barName] then
            -- if it doesn't exist then set it to an empty table
            self.db.profile.currentBarData[barName] = {}
        else
            -- if it exists then set barFound to true
            barFound = true
        end
    end

    -- if currentBarData is emtpy then let user know they must trigger a sync first
    if barFound == false then
        StaticPopupDialogs["ACTIONBARSYNC_NO_SCAN"] = {
            text = (L["actionbarsync_no_scan_text"]):format(barName),
            button1 = L["ok"],
            button2 = L["cancel"],
            timeout = 0,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function(self)
                ABSync:GetActionBarData()
            end,
        }
        StaticPopup_Show("ACTIONBARSYNC_NO_SCAN")

        -- just return to cancel the rest of the function
        return
    end

    -- getting to this point has passed all tests so we can sync the data to the global settings and mark this player as the owner
    -- set the bar owner to the current character
    self.db.global.barsToSync[barName].owner = playerID

    -- if the value is true, add the bar data to the buttonsToSync table under the barsToSync[barName] table
    if value == true then
        -- set the bar owner
        self.db.global.barsToSync[barName].owner = playerID

        -- add the bar data
        for buttonID, buttonData in pairs(self.db.profile.currentBarData[barName]) do
            -- make sure buttonsToSync exists
            if not self.db.global.barsToSync[barName].buttonsToSync then
                self.db.global.barsToSync[barName].buttonsToSync = {}
            end

            -- add the button data to the buttonsToSync table
            self.db.global.barsToSync[barName].buttonsToSync[buttonID] = buttonData
        end
    else
        -- remove all the button data
        self.db.global.barsToSync[barName].buttonsToSync = {}

        -- remove bar owner
        self.db.global.barsToSync[barName].owner = L["noowner"]
    end

    --@debug@
    if self.isLive == false then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToShare", barName, (value and "Yes" or "No"))) end
    --@end-debug@
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
    
    -- make certain the variable exists to hold bars to sync info
    if self.db.global.barsToSync then
        -- count entries
        for barName, syncOn in pairs(self.db.global.barsToSync) do
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
    for barName, syncOn in pairs(self.db.global.barsToSync) do
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
    for barName, syncOn in pairs(self.db.global.barsToSync) do
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

            -- if the button position is populated, remove the item
            -- the button currently being processed should always be in currentBarData because a sync is required to update action bars...
            -- check to make sure currentBarData exists
            if self.db.profile.currentBarData then
                -- check to make sure the barName exists in currentBarData
                if self.db.profile.currentBarData[diffData.barName] then
                    -- check to make sure the buttonID exists in the barName table
                    if self.db.profile.currentBarData[diffData.barName][diffData.buttonID] then
                        -- remove the action bar button
                        PickupAction(tonumber(diffData.buttonID))
                        ClearCursor()
                    end
                end
            end
        end

        -- get the name of the id based on action type
        if actionType == "spell" then
            -- get spell details
            local spellInfo = self:GetSpellDetails(actionID, buttonID)

            -- report error if player does not have the spell
            if spellInfo.hasSpell == false then
                err["name"] = spellInfo.spellName
                err["msg"] = L["unavailable"]
                table.insert(errors, err)

            -- proceed if player has the spell
            else                    
                if spellInfo.name then
                    -- set the action bar button to the spell
                    C_Spell.PickupSpell(spellInfo.name)
                    PlaceAction(tonumber(buttonID))
                    ClearCursor()
                else
                    err["name"] = diffData.name
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end
            end
        elseif actionType == "item" then
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(actionID)

            -- need a string as itemName or error occurs if the item actually doesn't exist
            local checkItemName = itemName or L["unknown"]

            -- if checkItemName is unknown then see if its a toy?
            local isToy = false
            if checkItemName == L["unknown"] then
                local toyID, toyName, toyIcon, toyIsFavorite, toyHasFanfare, toyItemQuality = C_ToyBox.GetToyInfo(actionID)
                if toyName then
                    -- print(("toy found: %s (%s)"):format(tostring(toyName or L["unknown"]), toyID))
                    checkItemName = toyName or L["unknown"]
                    isToy = true
                end
            end

            --@debug@
            if self.isLive == false then self:Print((L["updateactionbars_debug_item_name"]):format(actionID, checkItemName)) end
            --@end-debug@

            -- does player have the item
            local itemCount = C_Item.GetItemCount(actionID)

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
                    err["name"] = checkItemName
                    err["msg"] = L["notfound"]
                    table.insert(errors, err)
                end

            -- could be a toy
            elseif isToy == true then
                -- print("toy found: " .. checkItemName)
                -- set the action bar button to the toy
                C_ToyBox.PickupToyBoxItem(actionID)
                PlaceAction(tonumber(buttonID))
                ClearCursor()

            -- if player doesn't have item then log as error
            else
                err["name"] = checkItemName
                err["msg"] = L["notinbags"]
                table.insert(errors, err)
            end
        elseif actionType == "macro" then
            -- get macro information: name, iconTexture, body, isLocal
            local macroName = GetMacroInfo(actionID)

            -- if macro name is found proceed
            if macroName then
                -- set the action bar button to the macro
                PickupMacro(macroName)
                PlaceAction(tonumber(buttonID))
                ClearCursor()

            -- if macro name is not found then record error and remove whatever is in the bar
            else
                err["name"] = L["unknown"]
                err["msg"] = L["notfound"]
                table.insert(errors, err)

                -- remove if not found
                PickupAction(tonumber(diffData.buttonID))
                ClearCursor()
            end
        elseif actionType == "summonpet" then
            -- get pet information
            local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(diffData.id)

            -- if pet name is found proceed
            if name then
                -- set the action bar button to the pet
                C_PetJournal.PickupPet(diffData.id)
                PlaceAction(tonumber(diffData.buttonID))
                ClearCursor()
            else
                err["name"] = L["unknown"]
                err["msg"] = L["notfound"]
                table.insert(errors, err)
            end
        elseif actionType == "summonmount" then
            -- get the mount spell name; see function details for why we get its spell name
            local mountInfo = self:GetMountinfo(diffData.id)

            -- if mount name is found proceed
            if mountInfo.name then
                C_MountJournal.Pickup(tonumber(mountInfo.displayID))
                PlaceAction(tonumber(diffData.buttonID))
                ClearCursor()
            else
                err["name"] = L["unknown"]
                err["msg"] = L["notfound"]
                table.insert(errors, err)
            end

        -- else as actionType is "notfound" means the button was empty
        else
            PickupAction(tonumber(diffData.buttonID))
            ClearCursor()
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
    Function:   GetSpellDetails
    Purpose:    Retrieve spell information based on the spell ID.
-----------------------------------------------------------------------------]]
function ABSync:GetSpellDetails(spellID, buttonID)
    -- get spell info: name, iconID, originalIconID, castTime, minRange, maxRange, spellID
    local spellData = C_Spell.GetSpellInfo(spellID)
    local spellName = spellData and spellData.name or L["unknown"]

    -- determine if player has the spell, if not report error
    -- local hasSpell = C_Spell.IsCurrentSpell(spellID) or false

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
        -- hasSpell = hasSpell,
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
    if checkItemName == L["unknown"] then
        local toyID, toyName, toyIcon, toyIsFavorite, toyHasFanfare, toyItemQuality = C_ToyBox.GetToyInfo(itemID)
        if toyName then
            -- print(("toy found: %s (%s)"):format(tostring(toyName or L["unknown"]), toyID))
            checkItemName = toyName or L["unknown"]
            isToy = true
        end
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
        isToy = isToy
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

    -- finally return the data collected
    return {
        blizData = {
            name = macroName or L["unknown"],
            icon = iconTexture or -1,
            body = body or L["unknown"]
        }
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

    elseif actionType == "macro" then
        -- get macro details
        local macroInfo = self:GetMacroDetails(infoID)

        -- assign data
        returnData.name = macroInfo.blizData.name
        returnData.icon = macroInfo.blizData.icon
        returnData.sourceID = macroInfo.blizData.id
        returnData.has = macroInfo.hasMacro
        returnData.blizData = macroInfo.blizData

    elseif actionType == "summonpet" then
        -- get pet data
        local petInfo = self:GetPetDetails(infoID)

        -- assign data
        returnData.name = petInfo.name
        returnData.icon = petInfo.blizData.icon
        returnData.blizData = petInfo.blizData

    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        local mountInfo = self:GetMountinfo(infoID)

        -- assign data
        returnData.name = mountInfo.name
        returnData.icon = mountInfo.blizData.icon
        returnData.sourceID = mountInfo.sourceID
        returnData.blizData = mountInfo.blizData
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
    self.db.profile.currentBarData = {}
    
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
                -- local info = {
                --     btnName = btnName,
                --     actionType = actionType or L["notfound"],
                --     sourceID = id or -1,
                --     subType = subType or L["notfound"]
                -- }

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
                self.db.profile.currentBarData[barName][tostring(actionID)] = buttonData
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
        -- instantiate barsToSync if it doesn't exist
        if not self.db.global.barsToSync then
            self.db.global.barsToSync = {}
        end

        -- if the barName is not in barsToSync then add it with default value of false
        if not self.db.global.barsToSync[barName] then
            self.db.global.barsToSync[barName] = {
                owner = L["noowner"],
                buttonsToSync = {},
            }
        end

        -- instantiate bar owner if it doesn't exist
        if not self.db.global.barsToSync[barName].owner then
            self.db.global.barsToSync[barName].owner = L["noowner"]
        end

        -- instantiate barsToSync also under the character profile
        if not self.db.profile.barsToSync then
            self.db.profile.barsToSync = {}
        end

        -- if the barName is missing in the profile barToSync data, add it with default value of false
        if not self.db.profile.barsToSync[barName] then
            self.db.profile.barsToSync[barName] = false
        end
    end

    -- sync the updated data into the sync settings only when the same character is triggering the update
    for barName, barData in pairs(self.db.global.barsToSync) do
        -- get player unique id
        local playerID = self:GetPlayerNameFormatted()

        -- get bar current owner
        local barOwner = self.db.global.barsToSync[barName].owner

        -- see if current player matches the owner
        if playerID == barOwner then
            -- get the bar index
            -- local barIndex = nil
            -- for index, name in ipairs(self.db.global.actionBars) do
            --     if name == barName then
            --         barIndex = index
            --         break
            --     end
            -- end
            -- trigger the profile sync
            -- self:SetBarToSync(barIndex, syncOn)
            self:SetBarToSync(barName, barOwner)
        end
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
        -- elseif arg:lower() == "errors" then
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
function ABSync:ShowUI()
    -- instantiate AceGUI; can't be called when registering the addon in the initialize.lua file!
    local AceGUI = LibStub("AceGUI-3.0")

    -- Get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    --[[ top group ]]

    local topGroup = AceGUI:Create("SimpleGroup")
    topGroup:SetLayout("Flow")
    topGroup:SetFullWidth(true)

    --[[ middle group ]]

    local middleGroup = AceGUI:Create("SimpleGroup")
    middleGroup:SetLayout("Flow")
    middleGroup:SetFullWidth(true)

    --[[ bottom group ]]

    local bottomGroup = AceGUI:Create("SimpleGroup")
    bottomGroup:SetLayout("Flow")
    bottomGroup:SetFullWidth(true) 

    --[[ top right group ]]

    local topRightGroup = AceGUI:Create("SimpleGroup")
    topRightGroup:SetLayout("List")
    topRightGroup:SetFullWidth(true)

    --[[ about frame ]]

    -- create the main about frame
    local aboutFrame = AceGUI:Create("InlineGroup")
    aboutFrame:SetTitle("About")
    aboutFrame:SetLayout("List")
    -- aboutFrame:SetFullHeight(true)

    --[[ instructions frame ]]

    -- create instructions frame
    local instructionsFrame = AceGUI:Create("InlineGroup")
    instructionsFrame:SetTitle("Instructions")
    instructionsFrame:SetLayout("List")
    -- instructionsFrame:SetFullHeight(true)

    -- add scroll frame for instructions
    local instructionsScroll = AceGUI:Create("ScrollFrame")
    instructionsScroll:SetLayout("List")
    instructionsScroll:SetFullWidth(true)
    -- instructionsScroll:SetFullHeight(true)
    instructionsFrame:AddChild(instructionsScroll)

    -- add step 1
    local step1 = AceGUI:Create("Label")
    step1:SetText("1. Open the options and set the correct profile. I suggest to leave the default which is for your current characters profile.")
    step1:SetFullWidth(true)
    instructionsScroll:AddChild(step1)

    -- add button to open options for this addon
    local step1Button = AceGUI:Create("Button")
    step1Button:SetText("Open Options")
    step1Button:SetWidth(200)
    step1Button:SetCallback("OnClick", function()
        LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
    end)
    instructionsScroll:AddChild(step1Button)
    local step1spacer = AceGUI:Create("Label")
    step1spacer:SetText(" ")
    step1spacer:SetFullWidth(true)
    instructionsScroll:AddChild(step1spacer)

    -- add step 2
    local step2 = AceGUI:Create("Label")
    step2:SetText("2. Click the 'Scan Now' button. An initial scan is required for the addon to function.")
    step2:SetFullWidth(true)
    instructionsScroll:AddChild(step2)
    local step2spacer = AceGUI:Create("Label")
    step2spacer:SetText(" ")
    step2spacer:SetFullWidth(true)
    instructionsScroll:AddChild(step2spacer)

    -- add step 3
    local step3 = AceGUI:Create("Label")
    step3:SetText("3. Optional, in the 'Share' section, select which action bars to share.")
    step3:SetFullWidth(true)
    instructionsScroll:AddChild(step3)
    local step3spacer = AceGUI:Create("Label")
    step3spacer:SetText(" ")
    step3spacer:SetFullWidth(true)
    instructionsScroll:AddChild(step3spacer)

    -- add step 4
    local step4 = AceGUI:Create("Label")
    step4:SetText("4. In the 'Sync' section, select character action bars to sync into this character's action bars.")
    step4:SetFullWidth(true)
    instructionsScroll:AddChild(step4)
    local step4spacer = AceGUI:Create("Label")
    step4spacer:SetText(" ")
    step4spacer:SetFullWidth(true)
    instructionsScroll:AddChild(step4spacer)

    -- add step 5
    local step5 = AceGUI:Create("Label")
    step5:SetText("5. Click the 'Sync Now' button to sync your action bars.")
    step5:SetFullWidth(true)
    instructionsScroll:AddChild(step5)

    --[[ scan frame ]]

    -- create group
    local scanFrame = AceGUI:Create("InlineGroup")
    scanFrame:SetTitle("Scan Bars")
    scanFrame:SetLayout("List")
    -- scanFrame:SetFullHeight(true)

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
        ABSync:GetActionBarData()
    end)
    scanFrame:AddChild(button)

    --[[ trigger sync frame ]]

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

    --[[ last sync errors frame ]]

    -- create a group for the error scroll frame
    local lastErrorGroup = AceGUI:Create("InlineGroup")
    lastErrorGroup:SetTitle("Last Sync Errors")
    lastErrorGroup:SetLayout("Fill")

    --[[ create frame for last scan errors ]]

    -- columns
    local columns = {"Bar Name", "Bar Pos", "Button ID", "Action Type", "Action Name", "Action ID", "Message"}
    local columnLoop = {"barName", "barPos", "buttonID", "actionType", "name", "id", "msg"}

    -- Create a scroll container for the spreadsheet
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    lastErrorGroup:AddChild(scroll)

    -- determine column width
    -- 5px for spacing
    -- local columnWidth = ((frameWidth - 5) / #columns) - 5
    local columnWidth = 1/#columns

    -- Create header row
    local header = AceGUI:Create("SimpleGroup")
    header:SetLayout("Flow")
    header:SetFullWidth(true)
    for _, colName in ipairs(columns) do
        local label = AceGUI:Create("Label")
        label:SetText("|cff00ff00" .. colName .. "|r")
        -- label:SetWidth(columnWidth)
        label:SetRelativeWidth(columnWidth)
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

    --[[ create share frame ]]

    local shareFrame = AceGUI:Create("InlineGroup")
    shareFrame:SetTitle("Share")
    shareFrame:SetLayout("Flow")

    -- add a multiselect for sharing which action bars to share
    local actionBars = ABSync:GetActionBarNames(ABSync.profiletype["global"])
    local dataChanged = false
    for _, checkboxName in pairs(actionBars) do
        -- create a checkbox for each action bar
        local checkBox = AceGUI:Create("CheckBox")
        checkBox:SetLabel(checkboxName)
        checkBox:SetValue(self.db.global.barsToSync[checkboxName].owner == playerID)
        -- checkBox:SetFullWidth(true)

        -- set callback for when checkbox is clicked
        checkBox:SetCallback("OnValueChanged", function(widget, event, value)
            -- update the profile barsToSync value
            self.db.profile.barsToSync[syncKey] = value

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

    -- [[ create sync frame ]]

    -- generate tree
    local treeData = {}
    for barName, barData in pairs(self.db.global.barsToSync) do
 
    end

    local syncFrame = AceGUI:Create("TreeGroup")
    syncFrame:SetTitle("Sync")
    syncFrame:SetLayout("Flow")



    --[[ Create the main frame]]

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Action Bar Sync")
    -- TODO: format the dttm or store a formatted value instead...
    frame:SetStatusText(("Last Synced to UI: %s"):format(self.db.char.lastSynced or "-"))
    frame:SetLayout("Flow")
    local frameWidth = screenWidth * 0.8
    local frameHeight = screenHeight * 0.8
    frame:SetWidth(frameWidth)
    frame:SetHeight(frameHeight)

    -- add child frames; must add to group before adding group to main frame
    aboutFrame:SetAutoAdjustHeight(false)
    aboutFrame:SetRelativeWidth(0.3)
    aboutFrame:SetHeight(300)

    instructionsFrame:SetAutoAdjustHeight(false)
    instructionsFrame:SetRelativeWidth(0.5)
    instructionsFrame:SetHeight(300)

    scanFrame:SetFullWidth(true)

    triggerSyncFrame:SetFullWidth(true)

    topRightGroup:SetAutoAdjustHeight(false)
    topRightGroup:SetRelativeWidth(0.2)
    topRightGroup:SetHeight(300)
    topRightGroup:AddChild(scanFrame)
    topRightGroup:AddChild(triggerSyncFrame)

    topGroup:AddChild(aboutFrame)
    topGroup:AddChild(instructionsFrame)
    topGroup:AddChild(topRightGroup)

    shareFrame:SetAutoAdjustHeight(false)
    shareFrame:SetRelativeWidth(0.5)
    shareFrame:SetHeight(200)

    syncFrame:SetAutoAdjustHeight(false)
    syncFrame:SetRelativeWidth(0.5)
    syncFrame:SetHeight(200)

    middleGroup:AddChild(shareFrame)
    middleGroup:AddChild(syncFrame)

    lastErrorGroup:SetAutoAdjustHeight(false)
    lastErrorGroup:SetFullWidth(true)
    lastErrorGroup:SetHeight(300)

    frame:AddChild(topGroup)
    frame:AddChild(middleGroup)
    frame:AddChild(lastErrorGroup)

    -- display the frame
    frame:Show()
end