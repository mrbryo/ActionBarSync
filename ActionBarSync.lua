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
ABSync.currentActionBarData = {}
ABSync.currentActionBars = {}

-- Initialize Event
-- ABSync.mainFrame = CreateFrame("Frame", "ActionBarSyncMainFrame", UIParent)
function ABSync:OnInitialize()
    -- initialize the db
    self.db = LibStub("AceDB-3.0"):New("ActionBarSyncDB")
    -- Instantiate Option Table
    self.ActionBarSyncOptions = {
        name = "Action Bar Sync",
        handler = ABSync,
        type = "group",
        args = {
            sync = {
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
                    lastupdated = {
                        name = "Last Synced on Logged on Character",
                        desc = "The last time the action bars were synced.",
                        type = "input",
                        order = 12,
                        get = function(info)
                            return self:GetLastUpdatedOn() or "Never"
                        end,
                        disabled = true
                    },
                    step1hdr = {
                        name = "Step 1",
                        type = "header",
                        order = 20
                    },
                    step1 = {
                        name = "Go to Profiles and be sure you are using the profile you want to use. The default profile is/was: Main",
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
                            self:GetActionBarData()
                        end
                    },
                    lastscan = {
                        name = "Last Scan",
                        desc = "Last time an action bar scan was completed.",
                        type = "input",
                        order = 33,
                        disabled = true,
                        get = function(info)
                            return self.db.profile.lastScan or "Never"
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
                            return self:GetActionBarNames()
                        end,
                        type = "multiselect",
                        order = 100,
                        get = function(info, key)
                            return self:GetBarsToSync(key)
                        end,
                        set = function(info, key, value)
                            self:SetBarToSync(key, value)
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
                        type = "toggle",
                        order = 112,
                        get = function(info, key)
                            -- if the value doesn't exist set a default value
                            if not self.db.profile.checkOnLogon then
                                self.db.profile.checkOnLogon = false
                            end
                            return self.db.profile.checkOnLogon
                        end,
                        set = function(info, key, value)
                            self.db.profile.checkOnLogon = value
                        end
                    }
                }
            }
        }
    }
    -- default db data
    local dbDefaults = {
        profile = {
            actionBars = {},
            toons = {},
            lastScan = "Never",
            currentBars = {},
            barsToSync = {},
            checkOnLogon = false,
            barData = {}
        },
        char = {
            backup = {}
        }
    }
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
    Function:   GetActionBarNames
    Purpose:    Return the list/table of action bar names.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarNames()
    -- check to make sure a data fetch has happened, if not return No Scan Completed
    local barNames = {}
    if not self.db.profile.currentBars then
        table.insert(barNames, "No Scan Completed")
        return barNames
    end
    -- if we get to here just return the list of bar names from the scan
    return self.db.profile.currentBars
end

--[[---------------------------------------------------------------------------
    Function:   GetLastUpdatedOn
    Purpose:    Get the last updated time for the action bars to update the Last Updated field in the options for the current profile.
-----------------------------------------------------------------------------]]
function ABSync:GetLastUpdatedOn()
    -- return the last updated time
    return self.db.profile.lastUpdated or "Never"
end

--[[---------------------------------------------------------------------------
    Function:   GetBarsToSync
    Purpose:    Get the bars set to be synced for the current profile.
-----------------------------------------------------------------------------]]
function ABSync:GetBarsToSync(key)
    local barName = self.db.profile.currentBars[key]
    if self.db and self.db.profile and self.db.profile.barsToSync then
        return self.db.profile.barsToSync[barName] or false
    else
        return false
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetBarToSync
    Purpose:    Update the db for current profile when the user changes the values in the options on which bars to sync.
-----------------------------------------------------------------------------]]
function ABSync:SetBarToSync(key, value)
    -- set the bars to sync
    local barName = self.db.profile.currentBars[key]
    
    -- debugging
    if self.isLive == false then self:Print("Set Bar '" .. tostring(barName) .. "' to sync? " .. (value and "Yes" or "No") .. " - Starting...") end
    
    -- instantiate barsToSync if it doesn't exist
    if not self.db.profile.barsToSync then
        self.db.profile.barsToSync = {}
    end

    -- set the bar to sync values: true or false based on the value passed into this function
    self.db.profile.barsToSync[barName] = value

    
    -- if the value is true, add the bar data to the barData table
    if value == true then
        -- based on value add or remove the bar data
        for _, button in ipairs(self.db.profile.currentBarData) do
            -- check if the bar name matches the one we are syncing
            if button.barName == barName then
                -- make sure barData exists
                if not self.db.profile.barData then
                    self.db.profile.barData = {}
                end
                if not self.db.profile.barData[barName] then
                    self.db.profile.barData[barName] = {}
                end
                self.db.profile.barData[barName][button.position] = {
                    actionType = button.actionType,
                    id = button.id,
                    subType = button.subType,
                    name = button.name
                }
            end
        end
    else
        -- if the bar is not set to sync, remove it from the bar data
        self.db.profile.barData[barName] = {}
    end

    -- let the user know the value is changed only when developing though
    if self.isLive == false then self:Print("Set Bar '" .. tostring(barName) .. "' to sync? " .. (value and "Yes" or "No") .. " - Done!") end
end

-- function ABSync:ActionBarController_OnLoad()
-- 	self:Print("Action Bar On Loaded")
-- end

-- function ABSync:ActionBarController_OnEvent(event, ...)
-- 	self:Print("Action Bar On Event")
-- end

-- function ABSync:hasElement(table, value)
-- 	for k, v in pairs(table) do
-- 	  if (k == value) then
-- 		return true
-- 	  end
-- 	end
-- 	return false
-- end

--[[---------------------------------------------------------------------------
    Function:   SaveToProfile
    Purpose:    Save the current action bar data to the current profile.
-----------------------------------------------------------------------------]]
-- function ABSync:SaveToProfile()
--     -- get the current action bar data
--     self:ActionBarData()

--     -- check if the current action bar data is empty
--     if not self.currentActionBarData or #self.currentActionBarData == 0 then
--         self:Print("No Action Bar Data to save.")
--         return
--     end

--     -- save the current action bar data to the profile
--     self.db.profile.actionBars = self.currentActionBarData

--     -- print a message to confirm saving
--     self:Print("Current Action Bar Data saved to profile. However, you need to specify which action bars to sync to all characters. Syncing happens only when you login to each character.")
-- end

--[[---------------------------------------------------------------------------
    Function:   CompareActionBarData
    Purpose:    Compare two action bar button data tables.
-----------------------------------------------------------------------------]]
function ABSync:CompareActionBarData()
    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")
    -- make certain the user has selected bars to sync
    if not self.db.profile.barsToSync then
        self:Print("No action bars selected to sync. Please select action bars to sync in the options.")
        return
    end

    -- loop over the values and act on trues
    for barName, syncOn in pairs(self.db.profile.barsToSync) do
        if syncOn == true then
            -- let user know syncing has started
            self:Print(("Syncing Action Bar '%s'..."):format(barName))
            -- make sure data path exists
            if not self.db.profile.char.backup then
                self.db.profile.char.backup = {}
            end
            if not self.db.profile.char.backup[barName] then
                self.db.profile.char.backup[barName] = {}
            end
            -- make a backup of current bars
            self.db.char.backup[backupdttm] = StdFuncs:shallowCopy(self.db.profile.currentBarData)
        end
    end

    -- store differences
    local differences = {}

    -- compare the profile data to the current action bar data
    for profKey, profData in pairs(profileData) do
        
        if not characterData[profKey] then
            self:Print(("Action Bar Button '%s' is missing in current data."):format(profKey))
        else
            local charInfo = characterData[profKey]
            -- Compare each field
            for k, v in pairs(profData) do
                if charInfo[k] ~= v then
                    self:Print(("Action Bar Button '%s' has changed: %s -> %s"):format(profKey, tostring(v), tostring(charInfo[k])))
                end
            end
        end
    end





    -- compare current character bars to the profile
    for charKey, charInfo in pairs(characterData) do
        



        if profileInfo then
            -- Compare each field
            for k, v in pairs(charInfo) do
                if v ~= profileInfo[k] then
                    self:Print(("Action Bar Button '%s' has changed: %s -> %s"):format(charInfo.name, tostring(profileInfo[k]), tostring(v)))
                end
            end
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarName
    Purpose:    Get the action bar name from the button name to build a
                a distinct list of action bar names.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarName(btnName)
    -- get button name with out number
    local btnNameNoNbr = string.gsub(btnName, "Button%d+$", "")
    -- search table for entry
    local barNameFound = false
    for _, v in pairs(self.currentActionBars) do
        if v == btnNameNoNbr then
            barNameFound = true
            break
        end
    end
    -- if we get to here then it isn't found, insert it
    if not barNameFound then
        table.insert(self.currentActionBars, btnNameNoNbr)
    end
    -- return the bar name
    return btnNameNoNbr
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarData
    Purpose:    Fetch current action bar button data.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarData()
    -- Instantiate Standard Functions
    local StdFuncs = ABSync:GetModule("StandardFunctions")
    local WoW10 = StdFuncs:IsWoW10()

    -- get action bar details
    for btnName, btnData in pairs(_G) do
        -- filter out by proper naming of the action bars done by blizzard
        if string.find(btnName, "^ActionButton%d+$") or string.find(btnName, "^MultiBarBottomLeftButton%d+$") or string.find(btnName, "^MultiBarBottomRightButton%d+$") or string.find(btnName, "^MultiBarLeftButton%d+$") or string.find(btnName, "^MultiBarRightButton%d+$") or string.find(btnName, "^MultiBar%d+Button%d+$") then
            -- make up a name for each bar using the button names by removing the button number
            local barName = self:GetActionBarName(btnName)

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
                name = btnName,
                position = actionID,
                actionType = actionType or "Unknown",
                id = id or "Unknown",
                subType = subType or "Unknown",
                barName = barName
            }

            -- insert the info table into the current action bar data
            table.insert(self.currentActionBarData, info)
        end
    end

    -- sort the action bar data by bar name
    table.sort(self.currentActionBarData, function(a, b)
        return a.name < b.name
    end)

    -- sort the action bar names
    table.sort(self.currentActionBars, function(a, b)
        return a < b
    end)

    -- print the action bar data when needed, swtich false to true
    if (false) then
        for _, info in ipairs(self.currentActionBarData) do
            print(string.format("Button: %s, Position: %d, Type: %s, ID: %s, SubType: %s", info.name, info.position, tostring(info.actionType), tostring(info.id), tostring(info.subType)))
        end
    end

    -- update db
    self.db.profile.lastScan = date("%Y-%m-%d %H:%M:%S")
    self.db.profile.currentBarData = self.currentActionBarData
    self.db.profile.currentBars = self.currentActionBars

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

