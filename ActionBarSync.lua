--[[ ------------------------------------------------------------------------
	Title: 			ActionBarSync.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	Main program for ActionBarSync addon.
-----------------------------------------------------------------------------]]

-- Instantiate variable to hold functionality!
local ABSync = LibStub("AceAddon-3.0"):NewAddon("Action Bar Sync", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0") -- "AceConfig-3.0"
_G.ABSync = ABSync

ABSync.optionLocName = "AddonBarSync"
ABSync.isLive = false

-- lookup values for action button lookup
ABSync.actionTypeLookup = {
    ["spell"] = "Spell",
    ["item"] = "Item",
    ["macro"] = "Macro",
    ["summonpet"] = "Pet",
    ["summonmount"] = "Mount"
}

-- translate blizzard Action Bar settings names to LUA Code Names
ABSync.blizzardTranslate = {
    ["MultiBarBottomLeft"] = "Action Bar 2",
    ["MultiBarBottomRight"] = "Action Bar 3",
    ["MultiBarRight"] = "Action Bar 4",
    ["MultiBarLeft"] = "Action Bar 5",
    ["MultiBar5"] = "Action Bar 6",
    ["MultiBar6"] = "Action Bar 7",
    ["MultiBar7"] = "Action Bar 8",
    ["Action"] = "Action Bar 1"
}

--[[---------------------------------------------------------------------------
    Function:   ABSync:OnInitialize
    Purpose:    Initialize the addon and set up default values.
-----------------------------------------------------------------------------]]
function ABSync:OnInitialize()
    -- debug
    if self.isLive == false then self:Print("Initializing...") end

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
            lastScan = "Never",
            actionLookup = {
                type = "spell",
                id = "",
                name = ""
            }
        }
    }
    -- initialize the db
    self.db = LibStub("AceDB-3.0"):New("ActionBarSyncDB", dbDefaults)

    -- Instantiate Option Table
    self.ActionBarSyncOptions = {
        name = "Action Bar Sync",
        handler = ABSync,
        type = "group",
        args = {
            syncsettings = {
                name = "Sync Settings",
                desc = "See directions and current sync settings.",
                type = "group",
                order = 1,
                args = {
                    hdr1 = {
                        name = "Introduction",
                        type = "header",
                        order = 10
                    },
                    intro = {
                        name = "This addon allows you to sync selected action bars across characters.",
                        type = "description",
                        order = 11
                    },
                    step1hdr = {
                        name = "Step 1",
                        type = "header",
                        order = 20
                    },
                    step1 = {
                        name = "Go to Profiles and be sure you are using the correct profile.",
                        type = "description",
                        order = 21,
                    },
                    step2hdr = {
                        name = "Step 2",
                        type = "header",
                        order = 30
                    },
                    step2 = {
                        name = "Click the Scan button. This will capture your current action bars and buttons.",
                        type = "description",
                        order = 31,
                    },
                    scan = {
                        name = "Scan",
                        type = "execute",
                        order = 32,
                        func = function()
                            ABSync:GetActionBarData()
                        end
                    },
                    lastscan = {
                        name = "Last Scan on this Character",
                        desc = "Last time an action bar scan was completed.",
                        type = "input",
                        order = 33,
                        disabled = true,
                        get = function(info)
                            return ABSync.db.char.lastScan or "Never"
                        end,
                    },
                    step3hdr = {
                        name = "Step 3",
                        type = "header",
                        order = 40
                    },
                    step3 = {
                        name = "Indicate which action bars to sync.",
                        type = "description",
                        order = 41,
                    },
                    bars2sync = {
                        name = "Bars to Sync",
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
                        name = "Final Step",
                        type = "header",
                        order = 110
                    },
                    finaldescr = {
                        name = "Finally, review and update the settings below.",
                        type = "description",
                        order = 111,
                    },
                    finalstep = {
                        name = "Check bars after logging into a character.",
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
                name = "Sync!",
                desc = "Trigger a sync and/or restore from a backup.",
                type = "group",
                order = 2,
                args = {
                    triggerhdr = {
                        name = "Perform a Sync",
                        type = "header",
                        order = 1
                    },
                    lastupdated = {
                        name = "Last Synced on this Character",
                        width = "full",
                        desc = "The last time the action bars were synced on this character.",
                        type = "input",
                        order = 2,
                        get = function(info)
                            return ABSync:GetLastSyncedOnChar() or "Never"
                        end,
                        disabled = true
                    },
                    trigger = {
                        name = "Start!",
                        desc = "Sync your action bars with the current profile.",
                        type = "execute",
                        order = 3,
                        func = function()
                            self:BeginSync()
                        end
                    }
                }
            },
            -- barOwners = {
            --     name = "Bar Owners",
            --     desc = "This section shows the owners of the action bars for the current profile.",
            --     type = "group",
            --     order = 3,
            --     args = {}
            -- },
            lastSyncErrors = {
                name = "Last Sync Errors",
                desc = "This section shows any errors that occurred during the last sync.",
                type = "group",
                order = 4,
                args = {
                    errors = {
                        name = function()
                           return ABSync:GetErrorText()
                        end,
                        type = "description",
                        order = 20,
                        width = "full",
                    }
                }
            },
            actionlookup = {
                name = "Action ID Lookup",
                desc = "This section allows you to look up actions by ID.",
                type = "group",
                order = 5,
                args = {
                    intro = {
                        name = "This section allows you to look up actions by type and ID or Name.",
                        type = "description",
                        order = 0,
                        width = "full",
                    },
                    objectname = {
                        name = "Action Name",
                        desc = "Enter the exact name of the action you want to look up.",
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
                        name = "Action ID",
                        desc = "The ID of the item you want to look up.",
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
                        name = "Action Type",
                        desc = "The type of the action you want to look up.",
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
                        name = "Lookup",
                        desc = "Click to look up the action.",
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
    -- populate the barOwners
    -- for index, barName in ipairs(ABSync:GetActionBarNames()) do
    --     -- self:Print(("Adding Owner to Options - Bar Name: %s"):format(barName))

    --     -- create a new item for each action bar
    --     local newItem = {
    --         name = barName,
    --         type = "input",
    --         order = index,
    --         disabled = true,
    --         get = function(info)
    --             return ABSync.db.profile.barOwner[barName] or "Unknown"
    --         end,
    --         set = nil
    --     }
    --     -- add it to the barOwnersList
    --     self.ActionBarSyncOptions.args.barOwners.args[barName] = newItem
    -- end
    -- get the ace db options for profile management
    self.ActionBarSyncOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    -- register the options
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ABSync.optionLocName, self.ActionBarSyncOptions)
    -- create a title for the addon option section
    local optionsTitle = "Addon Bar Sync"
    -- add the options to the ui
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ABSync.optionLocName, optionsTitle, nil)
    -- register some slash commands
    self:RegisterChatCommand("abs", "SlashCommand")
    -- leave at end of function
    if self.isLive == false then self:Print("Initialized") end
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
    Purpose:    Get the last action type for the current character.
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
        button1 = "OK",
        timeout = 0,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- get the action type
    local actionType = self:GetLastActionType()
    
    -- get the action ID
    local actionID = self:GetLastActionID()

    -- debug
    if self.isLive == false then self:Print(("Looking up Action - Type: %s - ID: %s"):format(actionType, actionID)) end

    -- check for valid action type
    if not self.actionTypeLookup[actionType] then
        self:Print("")
        StaticPopupDialogs["ACTIONBARSYNC_INVALID_ACTION_TYPE"] = {
            text = "Invalid Action Type. Please enter/select a valid action type.",
            button1 = "OK",
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
        local spellName = spellData and spellData.name or "Unknown"

        -- assign to field
        self:SetLastActionName(spellName)

        -- determine if player has the spell, if not report error
        local hasSpell = C_Spell.IsCurrentSpell(actionID) and "Yes" or "No"

        -- generate message
        dialogMessage = ("Spell Lookup Result\nID: %s\nName: %s\nHas: %s"):format(actionID, spellName, hasSpell)
    elseif actionType == "item" then
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(actionID)
        -- self:Print(("Item Name for ID '%s': %s"):format(actionID, itemName or "Unknown/Nil"))

        -- does player have the item
        local itemCount = C_Item.GetItemCount(actionID)

        -- assign results
        self:SetLastActionName(itemName)

        -- generate message
        local hasItem = (itemCount > 0) and "Yes" or "No"
        dialogMessage = ("Item Lookup Result\nID: %s\nName: %s\nHas: %s"):format(actionID, itemName, hasItem)
    elseif actionType == "macro" then
        -- get macro information: name, iconTexture, body, isLocal
        local macroName, macroIcon, macroBody = GetMacroInfo(actionID)

        -- does player have this macro?
        local hasMacro = macroName and "Yes" or "No"

        -- fix macroName for output
        macroName = macroName or "Unknown"

        -- assign to field
        self:SetLastActionName(macroName)

        -- generate message
        dialogMessage = ("Macro Lookup Result\nID: %s\nName: %s\nHas: %s"):format(actionID, macroName, hasMacro)
    elseif actionType == "summonpet" then
        -- get pet information
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(actionID)

        -- check if has pet
        local hasPet = name and "Yes" or "No"

        -- assign to field
        self:SetLastActionName(name)        

        -- generate message
        dialogMessage = ("Pet Lookup Result\nID: %s\nName: %s\nHas: %s"):format(actionID, name, hasPet)
    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        local mountInfo = self:GetMountinfo(actionID, true)

        -- has mount
        local hasMount = mountInfo.name and "Yes" or "No"

        -- assign to field
        self:SetLastActionName(mountInfo.name)

        -- generate message
        dialogMessage = ("Mount Lookup Result\nID: %s\nName: %s\nHas: %s"):format(actionID, mountInfo.name, hasMount)
    end

    -- show results in dialog
    -- local actionTypeLabel = self.actionTypeLookup[actionType] or "Unknown"
    StaticPopupDialogs["ACTIONBARSYNC_LOOKUP_RESULT"].text = dialogMessage
    StaticPopup_Show("ACTIONBARSYNC_LOOKUP_RESULT")
end

function ABSync:GetMountinfo(actionID, showDialog)
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
    --[[ -- Getting Proper Mount Info --
        --------------------------------
        1) in order to get the correct action bar button for a mount you have to get the spellID from GetMountInfoByID
        2) use the spellID to get the spell information from GetSpellInfo
        3) pass the spell name into PickupSpell, just like actionType "spell" and then place this spell into the button
        ---
        Note: I could just use the mount name into the PickupSpell function but to be accurate I should get the spell name from GetSpellInfo
    ----------------------------------]]
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(actionID)
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
    -- local spellData = C_Spell.GetSpellInfo(spellID)
    -- local spellName = spellData and spellData.name or nil
    self:Print(("Mount Name: %s - ID: %s - Display ID: %s"):format(name, mountID, tostring(mountDisplayID)))


    -- update dialog text with mount information
    -- if showDialog == true then
    --     StaticPopupDialogs["ACTIONBARSYNC_MOUNT_INFO"].text = ("Mount Information\nAction ID: %s\nMount ID: %s\nName: %s\nSpell ID: %s\nSpell Name: %s"):format(actionID, mountID, name, spellID, spellName)
    --     StaticPopup_Show("ACTIONBARSYNC_MOUNT_INFO")
    -- end

    -- finally return the spell name
    return {name = name, mountID = mountID, displayID = mountDisplayID}
end

--[[---------------------------------------------------------------------------
    Function:   GetErrorText
    Purpose:    Return a string to populate an option description to show users the last sync errors.
-----------------------------------------------------------------------------]]
function ABSync:GetErrorText()
    -- instantiate variable to all all error messages
    local text = ""

    -- debug
    -- self:Print("here1")

    -- check variable exists
    if not self.db.char.syncErrors then
        -- self:Print("here2")
        return "No Errors Found"
    end

    -- check variable exists
    if not self.db.char.lastSyncErrorDttm then
        -- self:Print("here2")
        return "No Errors Found"
    end

    -- check for any sync errors
    if #self.db.char.syncErrors == 0 then
        -- self:Print("here3")
        return "No Errors Found"
    end

    -- loop over error data
    for _, errorRcd in ipairs(self.db.char.syncErrors) do
        -- self:Print("here loop")
        -- check key matches last sync dttm
        if errorRcd.key == self.db.char.lastSyncErrorDttm then            
            -- loop over each error message and concat to variable
            for _, errorData in ipairs(errorRcd.errors) do
                -- add return character for each loop if text is not blank
                if text ~= "" then
                    text = text .. "\n"
                end
                -- concatenate the next error description
                text = text .. "- " .. errorData.descr
            end
        end
    end

    -- debug
    -- self:Print("here4")

    -- finally return the text
    return text
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
        table.insert(barNames, "No Scan Completed")
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
        response = "Never"

    -- return the last synced time
    else
        -- if last synced time exists then return the formatted date
        response = self.db.char.lastSynced
    end

    -- test
    -- self:Print(("Last Synced On Character: %s"):format(response))

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
        -- self:Print("Here1")
        self.db.profile.actionBars = {}
    end
    -- check if the key exists in actionBars, if so fetch it, if not set to "Unknown"
    local barName = "Unknown"
    if self.db.profile.actionBars[key] then
        barName = self.db.profile.actionBars[key]
        -- debug
        -- self:Print(("(%s) Key is Bar: %s"):format("GetBarsToSync", barName))
    end
    -- check for barsToSync
    if not self.db.profile.barsToSync then
        -- self:Print("Here3")
        self.db.profile.barsToSync = {}
    end
    -- check for the barName in barsToSync
    local returnVal = self.db.profile.barsToSync[barName] or false
    -- self:Print(("(%s) Bar '%s' set to Sync: %s"):format("GetBarsToSync", barName, returnVal and "Yes" or "No"))
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

    -- debug
    -- self:Print(("(%s) Set Bar '%s' to Sync: %s"):format("SetBarToSync", barName, value and "Yes" or "No"))

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
            text = ("This bar (%s) is owned by '%s'; please switch to this character to uncheck it."):format(barName, barOwner),
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
            text = "In order to keep the save data at a minimum current bar settings are not retained. You must click the Scan button before you can change sync settings.",
            button1 = "OK",
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("ACTIONBARSYNC_NO_SCAN")
        return
    end

    -- debugging
    -- if self.isLive == false then self:Print("Set Bar '" .. tostring(barName) .. "' to sync? " .. (value and "Yes" or "No") .. " - Starting...") end
    
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
            -- debug
            -- if self.isLive == false then
            --     self:Print(("Processing Button - Bar: %s - Name: %s - ID: %s"):format(barName, buttonData.name, buttonID))
            -- end
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

    -- let the user know the value is changed only when developing though
    if self.isLive == false then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("SetBarToSync", barName, (value and "Yes" or "No"))) end
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
        text = "Enter a note for this backup:",
        button1 = "OK",
        button2 = "Cancel",
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
            self.EditBox:SetText("Because...")
            self.EditBox:SetFocus()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- add dialog to let user know sync was cancelled
    StaticPopupDialogs["ACTIONBARSYNC_SYNC_CANCELLED"] = {
        text = "Action Bar Sync has been cancelled.",
        button1 = "OK",
        timeout = 15,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- add dialog to let user know they must select bars to sync first
    StaticPopupDialogs["ACTIONBARSYNC_NO_SYNCBARS"] = {
        text = "You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some.",
        button1 = "OK",
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
            -- debug
            if self.isLive == false then self:Print(("Backing Up Action Bar '%s'..."):format(barName)) end

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
        table.insert(errors, "No sync data found for backup.")
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
        note = note or "No note provided!",
        error = errors,
        data = backupData,
    }
    table.insert(self.db.char.backup, backupEntry)
    return backupdttm
end

--[[---------------------------------------------------------------------------
    Function:   UpdateActionBars
    Purpose:    Compare the sync action bar data to the current action bar data and override current action bar buttons.
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
                            position = string.match(buttonData.name, "(%d+)$") or "Unknown"
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
            text = "For the action bars flagged for syncing, no differences were found.",
            button1 = "OK",
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
            local buttonName = ("%s-Button-%d"):format(diffData.barName, diffData.position)

            -- get the name of the id based on action type
            if diffData.actionType == "spell" then
                -- get spell info
                local spellData = C_Spell.GetSpellInfo(diffData.id)
                local spellName = spellData and spellData.name or "Unknown"

                -- determine if player has the spell, if not report error
                local hasSpell = C_Spell.IsCurrentSpell(diffData.id) or false

                -- report error if player does not have the spell
                if hasSpell == false then
                    table.insert(errors, {
                        buttonID = diffData.buttonID,
                        actionType = diffData.actionType,
                        id = diffData.id,
                        name = diffData.name,
                        descr = ("(%s) Player does not have spell '%s' with ID '%s'."):format(buttonName, spellName, diffData.id)
                    })
                -- proceed if player has the spell
                else
                    -- self:Print(("Spell Name for ID '%s': %s"):format(diffData.id, spellName))
                    
                    if spellName then
                        -- set the action bar button to the spell
                        C_Spell.PickupSpell(spellName)
                        PlaceAction(tonumber(diffData.buttonID))
                        ClearCursor()
                    else
                        -- if spell name not found then log error
                        table.insert(errors, {
                            buttonID = diffData.buttonID,
                            actionType = diffData.actionType,
                            id = diffData.id,
                            name = diffData.name,
                            descr = ("(%s) Spell with ID %s for button %s not found."):format(buttonName, diffData.id, diffData.buttonID)
                        })
                    end
                end
            elseif diffData.actionType == "item" then
                local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(diffData.id)

                -- need a string as itemName or error occurs if the item actually doesn't exist
                local checkItemName = itemName or "Unknown/Nil"

                -- debug
                self:Print(("Item Name for ID '%s': %s"):format(diffData.id, checkItemName))

                -- does player have the item
                local itemCount = C_Item.GetItemCount(diffData.id)

                -- if the user has the item and the item exists then add to action bar
                if itemCount > 0 then
                    if itemName then
                        -- set the action bar button to the item
                        C_Item.PickupItem(itemName)
                        PlaceAction(tonumber(diffData.buttonID))
                        ClearCursor()
                    else
                        -- if item name not found then log error
                        table.insert(errors, {
                            buttonID = diffData.buttonID,
                            actionType = diffData.actionType,
                            id = diffData.id,
                            name = diffData.name,
                            descr = ("(%s) Item with ID %s for button %s not found."):format(buttonName, diffData.id, diffData.buttonID)
                        })
                    end

                -- if player doesn't have item then log as error
                else
                    table.insert(errors, {
                        buttonID = diffData.buttonID,
                        actionType = diffData.actionType,
                        id = diffData.id,
                        name = diffData.name,
                        descr = ("(%s) User does not have item '%s' with ID '%s' in their bags."):format(buttonName, checkItemName, diffData.id)
                    })
                end
            elseif diffData.actionType == "macro" then
                -- get macro information: name, iconTexture, body, isLocal
                local macroName = GetMacroInfo(diffData.id)
                -- self:Print(("Macro Name for ID '%s': %s"):format(diffData.id, macroName))

                -- if macro name is found proceed
                if macroName then
                    -- set the action bar button to the macro
                    PickupMacro(macroName)
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()

                -- if macro name is not found then record error and remove whatever is in the bar
                else
                    -- if macro name not found then log error
                    table.insert(errors, {
                        buttonID = diffData.buttonID,
                        actionType = diffData.actionType,
                        id = diffData.id,
                        name = diffData.name,
                        descr = ("(%s) Macro with ID %s not found."):format(buttonName, diffData.id)
                    })

                    -- remove if not found
                    PickupAction(tonumber(diffData.buttonID))
                    ClearCursor()
                end
            elseif diffData.actionType == "summonpet" then
                -- get pet information
                local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(diffData.id)
                -- self:Print(("Pet Name for ID '%s': %s"):format(diffData.id, name or "Unknown/Nil"))

                -- if pet name is found proceed
                if name then
                    -- set the action bar button to the pet
                    C_PetJournal.PickupPet(diffData.id)
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()
                else
                    -- if pet name not found then log error
                    table.insert(errors, {
                        buttonID = diffData.buttonID,
                        actionType = diffData.actionType,
                        id = diffData.id,
                        name = diffData.name,
                        descr = ("(%s) Pet with ID %s not found."):format(buttonName, diffData.id)
                    })
                end
            elseif diffData.actionType == "summonmount" then
                -- get the mount spell name; see function details for why we get its spell name
                -- local spellName = self:GetMountinfo(diffData.id)
                -- if self.isLive == false then self:Print(("Mount Name for ID '%s': %s (Mount ID: %s)(Spell ID: %s)(Spell Name: %s)"):format(diffData.id, name or "Unknown/Nil", mountID, tostring(spellID), spellName or "Unknown/Nil")) end

                local mountInfo = self:GetMountinfo(diffData.id)

                -- if mount name is found proceed
                if mountInfo.name then
                    -- setting an action bar button with Pickup from MountJournal doesn't work!
                    -- C_MountJournal.Pickup(tonumber(mountID))
                    -- C_Spell.PickupSpell(spellName)
                    C_MountJournal.Pickup(tonumber(mountInfo.displayID))
                    PlaceAction(tonumber(diffData.buttonID))
                    ClearCursor()
                else
                    -- if mount name not found then log error
                    table.insert(errors, {
                        buttonID = diffData.buttonID,
                        actionType = diffData.actionType,
                        id = diffData.id,
                        name = diffData.name,
                        descr = ("(%s) Mount with ID %s not found."):format(buttonName, diffData.id)
                    })
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
            -- debug
            if self.isLive == false then self:Print(("Action Bar Sync encountered errors during a sync; key: '%s':"):format(backupdttm)) end

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
        if string.find(btnName, "^ActionButton%d+$") or string.find(btnName, "^MultiBarBottomLeftButton%d+$") or string.find(btnName, "^MultiBarBottomRightButton%d+$") or string.find(btnName, "^MultiBarLeftButton%d+$") or string.find(btnName, "^MultiBarRightButton%d+$") or string.find(btnName, "^MultiBar%d+Button%d+$") then
            -- make up a name for each bar using the button names by removing the button number
            local barName = string.gsub(btnName, "Button%d+$", "")

            -- translate barName into the blizzard visible name in settings for the bars
            local barName = ABSync.blizzardTranslate[barName] or "Unknown"

            -- get action ID and type information
            local actionID = btnData:GetPagedID()

            -- get action type and ID information
            local actionType, id, subType = GetActionInfo(actionID)

            -- debug if no action info returned
            -- if self.isLive == false and (not actionType or not id or not subType) then
            --     local missingValues = {}
            --     if not actionType then table.insert(missingValues, "Action Type") end
            --     if not id then table.insert(missingValues, "ID") end
            --     if not subType then table.insert(missingValues, "Sub Type") end
            --     self:Print(("Action Bar Button '%s' is missing the following: %s"):format(btnName, table.concat(missingValues, ", ")))
            -- end

            -- build the info table
            local info = {
                -- actionID = actionID or "notfound",
                name = btnName,
                actionType = actionType or "notfound",
                id = id or "notfound",
                subType = subType or "notfound"
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
                -- if self.isLive == false then
                --     self:Print(("Bar Added to actionBars: %s"):format(barName))
                -- end
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
                -- if self.isLive == false then
                --     self:Print(("Bar Added to currentBarData: %s"):format(barName))
                -- end
            end

            -- insert the info table into the current action bar data
            self.db.profile.currentBarData[barName][tostring(actionID)] = info
            -- if self.isLive == false then
            --     self:Print(("Added Button - Bar: %s - Name: %s - ID: %s"):format(barName, btnName, actionID))
            -- end
        end
    end

    -- sort the actionBars table
    table.sort(self.db.profile.actionBars, function(a, b)
        return a < b
    end)

    -- update db
    self.db.char.lastScan = date("%Y-%m-%d %H:%M:%S")

    -- sync the updated data into the sync settings only when the same character is triggering the update
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        local playerID = self:GetPlayerNameFormatted()
        local barOwner = self.db.profile.barOwner[barName] or "Unknown"
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

    -- sync actionBars to barsToSync
    for _, barName in ipairs(self.db.profile.actionBars) do
        -- instantiate barsToSync if it doesn't exist
        if not self.db.profile.barsToSync then
            self.db.profile.barsToSync = {}
        end

        -- if the barName is not in barsToSync then add it with default value of false
        if not self.db.profile.barsToSync[barName] then
            self.db.profile.barsToSync[barName] = false
        end

        -- if the bar is not in barOwner then add it with default value of "Unknown"
        if not self.db.profile.barOwner[barName] then
            self.db.profile.barOwner[barName] = "Unknown"
        end
    end

    -- if the current character is the barOwner then update the barData to sync
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        local playerID = self:GetPlayerNameFormatted()
        local barOwner = self.db.profile.barOwner[barName] or "Unknown"
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

    -- trigger update for options UI
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ABSync.optionLocName)

    -- let user know its done
    if self.isLive == false then self:Print("Fetch Current Action Bar Button Data - Done") end
end

function ABSync:SlashCommand(msg)
    if msg:lower() == "options" then
        self:Print("Opening Options...")
        LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
    else
        -- self:Print("Get Action Bar Data!")
        ABSync:ActionBarData()
        -- self:Print("Action Bar Sync - Slash Command does nothing currently!")
    end
end

function ABSync:RegisterEvents()
    if ABSync.isLive == false then self:Print("Registering Events...") end
	-- Hook to Action Bar On Load Calls
	-- self:Hook("ActionBarController_OnLoad", true)
	-- Hook to Action Bar On Event Calls
	-- self:Hook("ActionBarController_OnEvent", true)
    -- Register Events
    self:RegisterEvent("ADDON_LOADED", function()
        if ABSync.isLive == false then self:Print("Event - ADDON_LOADED") end
    end)

    self:RegisterEvent("PLAYER_LOGIN", function()
        if ABSync.isLive == false then self:Print("Event - PLAYER_LOGIN") end

        -- trigger the collection of action bar button data
        ABSync:ActionBarData()
    end)

    self:RegisterEvent("PLAYER_LOGOUT", function()
        if ABSync.isLive == false then self:Print("Event - PLAYER_LOGOUT") end

        -- clear currentBarData and actionBars when the code is live
        if ABSync.isLive == true then
            ABSync.db.profile.currentBarData = {}
        end
    end)

    self:RegisterEvent("VARIABLES_LOADED", function()
        if ABSync.isLive == false then self:Print("Event - VARIABLES_LOADED") end
    end)

	-- self:RegisterEvent("ACTIONBAR_UPDATE_STATE", function()
	-- 	self:Print("Event - ACTIONBAR_UPDATE_STATE")
	-- end)
end

-- Trigger code when addon is enabled.
function ABSync:OnEnable()
    -- Check the DB
    if not self.db then
        self:Print("Database Not Found? Strange...please reload the UI. If error returns restart the game.")
    end


    -- Register Events
    self:RegisterEvents()

    -- leave at end of function
    self:Print("Enabled")
end

-- Trigger code when addon is disabled.
function ABSync:OnDisable()
    -- TODO: Unregister Events?
    self:Print("Disabled")
end

