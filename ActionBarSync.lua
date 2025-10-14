--[[ ------------------------------------------------------------------------
	Title: 			ActionBarSync.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	Main program for ActionBarSync addon.
-----------------------------------------------------------------------------]]

-- instantiate variable to hold functionality
ABSync = _G.ABSync

--[[---------------------------------------------------------------------------
    Function:   InitializeLocalization
    Purpose:    Load the localization table for the current locale.
-----------------------------------------------------------------------------]]
function ABSync:InitializeLocalization()
    -- get current local
    local locale = GetLocale() or "enUS"

    -- get language data
    self.L = self.locales[locale]

    -- clear locales to free memory
    self.locales = nil
end

--[[---------------------------------------------------------------------------
	Register the addon loaded event to begin further initialization.
-----------------------------------------------------------------------------]]
ABSync:RegisterEvent("ADDON_LOADED", function(self, event, addonName, ...)
	if addonName ~= "ActionBarSync" then
		return
	end

	--@debug@
	-- ABSync:Print(("%s loaded for Addon: %s"):format(event, addonName))
	--@end-debug@

    -- initialize language
    ABSync:InitializeLocalization()

    -- add variables which require translation
    ABSync.blizzardTranslate = {
		["MultiBarBottomLeft"] = "actionbar2",
		["MultiBarBottomRight"] = "actionbar3",
		["MultiBarRight"] = "actionbar4",
		["MultiBarLeft"] = "actionbar5",
		["MultiBar5"] = "actionbar6",
		["MultiBar6"] = "actionbar7",
		["MultiBar7"] = "actionbar8",
		["Action"] = "actionbar1"
    }
    -- translate the action bar keys into a formatted word for global variable naming
    ABSync.barNameTranslate = {
        ["actionbar1"] = "ActionBar1",
        ["actionbar2"] = "ActionBar2",
        ["actionbar3"] = "ActionBar3",
        ["actionbar4"] = "ActionBar4",
        ["actionbar5"] = "ActionBar5",
        ["actionbar6"] = "ActionBar6",
        ["actionbar7"] = "ActionBar7",
        ["actionbar8"] = "ActionBar8",
    }
    -- translate action bar keys into user friendly language for UI display
    ABSync.barNameLanguageTranslate = {
        ["actionbar1"] = ABSync.L["Action Bar 1"],
        ["actionbar2"] = ABSync.L["Action Bar 2"],
        ["actionbar3"] = ABSync.L["Action Bar 3"],
        ["actionbar4"] = ABSync.L["Action Bar 4"],
        ["actionbar5"] = ABSync.L["Action Bar 5"],
        ["actionbar6"] = ABSync.L["Action Bar 6"],
        ["actionbar7"] = ABSync.L["Action Bar 7"],
        ["actionbar8"] = ABSync.L["Action Bar 8"],
    }
    ABSync.columns = {
    	lookupHistory = {
			{ name = ABSync.L["Type"], key = "type", width = 0.20 },      -- 20
			{ name = ABSync.L["ID"], key = "id", width = 0.20 },          -- 40
			{ name = ABSync.L["Name"], key = "name", width = 0.50 },      -- 90
			{ name = ABSync.L["Has"], key = "has", width = 0.5 },         -- 95
		},
        errorColumns = {
            { name = ABSync.L["Bar Name"], key = "barName", width = 10},          -- 10
            { name = ABSync.L["Bar Pos"], key = "barPosn", width = 5},            -- 15
            { name = ABSync.L["Button ID"], key = "buttonID", width = 7.5},       -- 22.5
            { name = ABSync.L["Action Type"], key = "type", width = 10},          -- 32.5
            { name = ABSync.L["Action Name"], key = "name", width = 20},          -- 52.5
            { name = ABSync.L["Action ID"], key = "buttonActionID", width = 10},  -- 62.5
            { name = ABSync.L["Shared By"], key = "sharedby", width = 15},        -- 77.5
            { name = ABSync.L["Message"], key = "msg", width = 17}                -- 94.5
        }
    }
    -- define action type lookup values
    ABSync.actionTypeLookup = {
        order = { "spell", "item", "macro", "summonpet", "summonmount", "flyout" },
        data = {
            ["spell"] = ABSync.L["Spell"],
            ["item"] = ABSync.L["Item"],
            ["macro"] = ABSync.L["Macro"],
            ["summonpet"] = ABSync.L["Pet"],
            ["summonmount"] = ABSync.L["Mount"],
            ["flyout"] = ABSync.L["Flyout"],
        }
    }
    -- define tab names
    ABSync.uitabs["tabs"] = {
        ["about"] = ABSync.L["About"],
        ["introduction"] = ABSync.L["Introduction"],
        ["sharesync"] = ABSync.L["Share & Sync"],
        ["last_sync_errors"] = ABSync.L["Last Sync Errors"],
        ["lookup"] = ABSync.L["Lookup & Assign"],
        ["backup"] = ABSync.L["Restore"],
        ["utilities"] = ABSync.L["Utilities"],
        ["developer"] = ABSync.L["Developer"],
    }
    -- uitabs variable names for proper naming of global variables
    ABSync.uitabs["varnames"] = {
        ["about"] = ABSync.L["About"],
        ["introduction"] = ABSync.L["Introduction"],
        ["sharesync"] = ABSync.L["ShareSync"],
        ["last_sync_errors"] = ABSync.L["LastSyncErrors"],
        ["lookup"] = ABSync.L["Lookup"],
        ["backup"] = ABSync.L["Backup"],
        ["utilities"] = ABSync.L["Utilities"],
        ["developer"] = ABSync.L["Developer"],
    }
    ABSync.uitabs.count = {
        tabs = 8
    }

    -- verify data is loaded and not nil
    ABSync:Timer("tabnamevalidate", 5, function()
        local count = 0
        if not ABSync.uitabs["varnames"] then
            ABSync:Print(ABSync.L["Error: uitabs varnames is nil. Report this to the author."])
        else
            for key, value in pairs(ABSync.uitabs["varnames"]) do
                count = count + 1
                if value == nil then
                    ABSync:Print(ABSync.L["Error: uitabs[varnames] value is nil for key %s. Report this to the author."]:format(tostring(key)))
                end
            end
        end

        if count ~= ABSync.uitabs.count.tabs then
            ABSync:Print(ABSync.L["Error: uitabs varnames count mismatch. Report this to the author."])
        end
    end)

    -- Check the DB
    if not ActionBarSyncDB then
        ABSync:Print(ABSync.L["Database Not Found? Strange...please reload the UI. If error returns, restart the game."])
    end

    -- Register Events using native system
    ABSync:RegisterAddonEvents()

	-- unregister event
	ABSync:UnregisterEvent("ADDON_LOADED")
end)

--[[---------------------------------------------------------------------------
    Function:   BeginActionBarClear
    Purpose:    Trigger a backup if user hits OK on the confirmation dialog, then clear the selected action bar.
-----------------------------------------------------------------------------]]
function ABSync:BeginActionBarClear()
    -- disable button
    local globalButtonName = ABSync:GetObjectName("UtilitiesClearButton")
    _G[globalButtonName]:Disable()

    -- get bar to clear
    local barID = ABSync:GetLastActionBarUtilities()
    
    -- add dialog to let user know sync was cancelled
    StaticPopupDialogs[ABSync.popups.clearbarSyncCancelled] = {
        text = ABSync.L["Action Bar Clear has been cancelled."],
        button1 = ABSync.L["OK"],
        timeout = 15,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- get confirmation and backup name
    StaticPopupDialogs[ABSync.popups.clearbarBackupConfirmation] = {
        text = ABSync.L["Enter a name for this backup:"],
        button1 = ABSync.L["OK"],
        button2 = ABSync.L["Cancel"],
        hasEditBox = true,
        maxLetters = 64,
        OnAccept = function(self)
            --@debug@
            -- ABSync:Print("Backup Accepted...")
            --@end-debug@
            -- capture the name
            local backupName = self.EditBox:GetText()
            
            -- create variable table to hold a single action bar for backup
            local limitBars = {}
            limitBars[ABSync:GetLastActionBarUtilities()] = true

            -- start the actual backup passing in needed data
            local backupdttm = ABSync:TriggerBackup(backupName, limitBars)

            -- sync the bars
            ABSync:ClearActionBar()
        end, 
        OnCancel = function(self)
            StaticPopup_Show(ABSync.popups.clearbarSyncCancelled)

            -- enable button
            local globalButtonName = ABSync:GetObjectName("UtilitiesClearButton")
            _G[globalButtonName]:Enable()
        end,
        OnShow = function(self)
            self.EditBox:SetText((ABSync.L["Clear %s"]):format(ABSync.barNameLanguageTranslate[barID]))
            self.EditBox:SetFocus()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show(ABSync.popups.clearbarBackupConfirmation)
end

--[[---------------------------------------------------------------------------
    Function:   ClearActionBar
    Purpose:    Clear the selected action bar by removing all action buttons.
-----------------------------------------------------------------------------]]
function ABSync:ClearActionBar()
    -- get bar to clear
    local barID = self:GetLastActionBarUtilities()

    -- notify user if barID doesn't exist
    if barID == false then
        StaticPopupDialogs[self.popups.clearBarInvalidBarID] = {
            text = self.L["Invalid Action Bar ID. Report this to the author."],
            button1 = self.L["OK"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show(self.popups.clearBarInvalidBarID)
    else
        -- loop over action bar button number
        for _, buttonID in pairs(ABSync.constants.actionButtonTranslation[barID]) do
            --@debug@
            -- if self:GetDevMode() == true then
                -- self:Print("Clear Button: " .. buttonID)
            -- end
            --@end-debug@
            -- call function to remove a buttons action
            self:RemoveButtonAction(buttonID)
        end

        -- enable button
        local globalButtonName = self:GetObjectName("UtilitiesClearButton")
        _G[globalButtonName]:Enable()
    end
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
    local actionBarName = ABSync.barNameLanguageTranslate[ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.actionBar] or ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.actionBar
    self:Print((ABSync.L["Restore Triggered for Backup '%s' for Action Bar '%s'"]):format(self:FormatDateString(ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.backupDttm), actionBarName))

    -- trigger the update with the backup date time and a true value for isRestore
    self:UpdateActionBars(ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.backupDttm, true)

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
function ABSync:BeginSync(autoTriggered)
    --@debug@
    -- self:Print("BeginSync Called")
    --@end-debug@
    -- track testing
    local barsToSync = false

    -- check for nil autoTriggered
    if autoTriggered == nil then
        autoTriggered = false
    end
    
    -- count entries
    for barName, syncOn in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync) do
        if syncOn ~= false then
            barsToSync = true
            break
        end
    end

    -- if no data found, show a message and return
    if not barsToSync then
        -- skip dialog if auto triggered
        if autoTriggered == false then
            -- add dialog to let user know they must select bars to sync first
            StaticPopupDialogs[ABSync.popups.nosyncbars] = {
                text = ABSync.L["You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."],
                button1 = ABSync.L["OK"],
                timeout = 15,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }

            StaticPopup_Show(ABSync.popups.nosyncbars)
        end

    -- if data found, proceed with backup; ask user for backup note
    else
        -- add dialog to let user know sync was cancelled
        StaticPopupDialogs[ABSync.popups.synccancelled] = {
            text = ABSync.L["Action Bar Sync has been cancelled."],
            button1 = ABSync.L["OK"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }

        -- add dialog to ask for backup name
        if autoTriggered == false then
            StaticPopupDialogs[ABSync.popups.backupname] = {
                text = ABSync.L["Enter a name for this backup:"],
                button1 = ABSync.L["OK"],
                button2 = ABSync.L["Cancel"],
                hasEditBox = true,
                maxLetters = 64,
                OnAccept = function(self)
                    --@debug@
                    -- ABSync:Print("Backup Accepted...")
                    --@end-debug@
                    -- capture the name
                    local backupName = self.EditBox:GetText()

                    -- start the actual backup passing in needed data
                    local backupdttm = ABSync:TriggerBackup(backupName)

                    -- update last synced...though this should be done in the sync function after the sync is successful
                    ABSync:SetLastSynced(backupdttm)
                    
                    -- update the UI last synced label
                    ABSync:UpdateLastSyncLabel()
                    -- sync the bars
                    ABSync:UpdateActionBars(backupdttm)
                end, 
                OnCancel = function(self)
                    StaticPopup_Show(ABSync.popups.synccancelled)
                end,
                OnShow = function(self)
                    self.EditBox:SetText(ABSync.L["Default Name"])
                    self.EditBox:SetFocus()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show(ABSync.popups.backupname)
        else
            -- start the actual backup passing in needed data
            local syncdttm = self:GetCurrentDateTime()

            -- update last synced...though this should be done in the sync function after the sync is successful
            ABSync:SetLastSynced(syncdttm)

            -- update the UI last synced label
            ABSync:UpdateLastSyncLabel()

            -- sync the bars
            ABSync:UpdateActionBars(syncdttm)
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBChar
    Purpose:    Ensure the character specific DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ABSync:InstantiateDBChar(barID)
    -- create the character structure
    if not ActionBarSyncDB.char then
        ActionBarSyncDB.char = {}
    end

    -- currentBarData holds the last scan of data fetched from the action bars for the current character; hence stored in char
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec] then
        ActionBarSyncDB.char[self.currentPlayerServerSpec] = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData = {}
    end 

    -- character specific sync error data
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors = {}
    end

    -- character specific date/time of last scan, defaults to never, pass true for the never value
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastScan then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastScan = self.L["Never"]
    end

    -- character specific last synced date/time, defaults to never, pass true for the never value
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSynced = self.L["Never"]
    end

    -- backup of action bar data so a user can restore
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].backup then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].backup = {}
    end

    -- character last sync error date/time, represents the date/time of the errors captured
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm = self.L["Never"]
    end

    -- character last share scan error data
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastShareScanData then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].scanErrors = {}
    end

    -- character specific action lookup data
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].actionLookup = {
            name = "",
            id = "",
            type = "",
            bar = "",
            btn = "",
        }
    end

    -- character specific last action placement data
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastActionPlacement then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastActionPlacement = {}
    end

    -- character specific lookup history
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory = {}
    end

    -- set default for max history lookup records
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistoryMaxRecords then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistoryMaxRecords = 20
    end

    -- character last diff data
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastDiffData then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastDiffData = {}
    end

    -- character restore data
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice = {}
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.backupDttm then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.backupDttm = self.L["None"]
    end
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.actionBar then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.actionBar = self.L["None"]
    end

    -- instantiate barsToSync under the character spec profile
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync = {}
    end

    -- instantiate only if barID is passed
    if barID ~= nil then
        -- if the barID is missing in the character spec profile barToSync data, add it with default value of false
        if not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] then
            ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] = false
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBGlobal
    Purpose:    Ensure the global DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ABSync:InstantiateDBGlobal(barID)
    -- create the global structure
    self:SetupGlobalDB()

    -- add storage for action bars if missing
    if not ActionBarSyncDB.global.actionBars then
        ActionBarSyncDB.global.actionBars = {}
    end

    -- action buttons; used to process action bars buttons in number order; probably should be global variable instead of stored in DB...fix later
    -- TODO: move to global addon variable
    -- if not ActionBarSyncDB.global.actionButtons then
    --     ActionBarSyncDB.global.actionButtons = {}
    --     for i = 1, 12 do
    --         table.insert(ActionBarSyncDB.global.actionButtons, i, tostring(i))
    --     end
    -- end

    -- instantiate barsToSync if it doesn't exist
    if not ActionBarSyncDB.global.barsToSync then
        ActionBarSyncDB.global.barsToSync = {}
    end

    -- instantiate bar translation for UI objects
    -- if not ActionBarSyncDB.global.barNameTranslate then
    --     ActionBarSyncDB.global.barNameTranslate = {}
    -- end

    -- instantiate only if barID is passed
    if barID ~= nil then
        -- if the barID is not in barsToSync then add it with default value of false
        if not ActionBarSyncDB.global.barsToSync[barID] then
            ActionBarSyncDB.global.barsToSync[barID] = {}
        end

        -- instantiate bar owner if it doesn't exist
        if not ActionBarSyncDB.global.barsToSync[barID][self.currentPlayerServerSpec] then
            ActionBarSyncDB.global.barsToSync[barID][self.currentPlayerServerSpec] = false
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBProfile
    Purpose:    Ensure the profile DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ABSync:InstantiateDBProfile()
    -- auto reset mount journal filters flag; initially set to false
    self:SetAutoResetMountFilters(false)
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDB
    Purpose:    Ensure the DB has all the necessary values. Can run anytime to check and fix all data with default values.
-----------------------------------------------------------------------------]]
function ABSync:InstantiateDB(barID)
    --@debug@
    if self:GetDevMode() == true then
        self:Print(ABSync.L["DB Initialization"])
    end
    --@end-debug@
    -- make sure player key is set
    self:SetKeyPlayerServerSpec()
    self:SetKeyPlayerServer()

    -- instantiate db
    self:InstantiateDBProfile()
    self:InstantiateDBGlobal(barID)
    self:InstantiateDBChar(barID)
end

--[[---------------------------------------------------------------------------
    Function:   InsertLookupHistory
    Purpose:    Insert a new entry into the lookup history and only keeping the max records set by the user.
-----------------------------------------------------------------------------]]
function ABSync:InsertLookupHistory(info)
    -- insert the record
    table.insert(ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory, 1, info)

    -- if +1 of max records exist and the table has more then reduce the table size
    local nextRecord = ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistoryMaxRecords + 1
    if #ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory > ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistoryMaxRecords then
        for i = nextRecord, #ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory do
            table.remove(ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory, i)
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetActionData
    Purpose:    Get the action data for a specific action ID and type.
-----------------------------------------------------------------------------]]
function ABSync:GetActionData(buttonActionID, actionType)
    --@debug@
    -- self:Print(("(GetActionData) ActionID: %s, ActionType: %s"):format(tostring(buttonActionID), tostring(actionType)))
    --@end-debug@
    -- instantiate a return table
    local returnData = {}

    -- process by type
    if actionType == "spell" then
        -- get spell details: data, name, hasSpell
        returnData = self:GetSpellDetails(buttonActionID)
    elseif actionType == "item" then
        -- get item details
        returnData = self:GetItemDetails(buttonActionID)
    elseif actionType == "macro" then
        -- get macro details
        returnData = self:GetMacroDetails(buttonActionID)
    elseif actionType == "summonpet" then
        -- get pet data
        returnData = self:GetPetDetails(buttonActionID)
    elseif actionType == "summonmount" then
        -- get the mount spell name; see function details for why we get its spell name
        returnData = self:GetMountinfo(buttonActionID)
    elseif actionType == "flyout" then
        -- get flyout data
        returnData = self:GetFlyoutDetails(buttonActionID)
    elseif actionType == nil then
        -- leave as unknown since no action type of nil is assigned to the button which is valid
    else
        -- actually unknown action type, this addon doesn't know what to do with it!
        -- add unknown action type property
        returnData.unknownActionType = true
    end

    -- add additional details
    returnData.parameters = {
        buttonActionID = buttonActionID,
        actionType = actionType
    }
    if not returnData.unknownActionType then
        returnData.unknownActionType = false
    end

    -- is blizData missing? add it
    if not returnData.blizData then
        returnData.blizData = {}
    end

    -- finally return the data collected
    return returnData
end

--[[---------------------------------------------------------------------------
    Function:   FormatDateString
    Purpose:    Convert a date string from YYYYMMDDHHMISS or YYYY-MM-DD HH:MI:SS format to YYYY, Mon DD HH:MI:SS format.
-----------------------------------------------------------------------------]]
function ABSync:FormatDateString(dateString)    
    -- validate input
    if dateString == ABSync.L["Never"] then
        return ABSync.L["Never"]
    elseif not dateString or type(dateString) ~= "string" then
        return ABSync.L["Invalid Date"]
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
        return ABSync.L["Invalid Date"]
    end
    
    -- month names
    local monthNames = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    }
    
    -- validate month
    if month < 1 or month > 12 then
        return ABSync.L["Invalid Date"]
    end
    
    -- format and return the readable date string
    return string.format("%s, %s %s %s:%s:%s", year, monthNames[month], day, hour, minute, second)
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
    Function:   ConfirmBar
    Purpose:    Verify the bar exists in the current scan data by checking for one button as child data to the bar.
-----------------------------------------------------------------------------]]
function ABSync:ConfirmBar(barID)
    -- initialize variables
    local barFound = false

    -- verify bar exists, return false since we can't iterate over when it doesn't exist
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID] then
        return false
    end

    -- loop over current scan data and see if one button exists
    for _ in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID]) do
        barFound = true
        -- only need to loop once
        break
    end

    -- finally return
    return barFound
end

--[[---------------------------------------------------------------------------
    Function:   MarkBarToSync
    Purpose:    Update the db for current profile when the user changes the values in the options on which bars to sync.
-----------------------------------------------------------------------------]]
function ABSync:MarkBarToSync(key, value)
    --@debug@
    if self:GetDevMode() == true then self:Print(("Key: %s, Value: %s"):format(tostring(key), tostring(value))) end
    --@end-debug@

    -- initialize variables
    -- local barName = self.L["Unknown"]

    -- check for input key, if it doesn't exist then let user know and return false
    if not ActionBarSyncDB.global.actionBars[key] then
        -- initialize missing key dialog
        StaticPopupDialogs[ABSync.popups.missingKey] = {
            text = (ABSync.L["Action Bar Key '%s' is not valid. Please open an issue and include the key and which action bar you checked. Get links on the About tab in options."]):format(key),
            button1 = ABSync.L["OK"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }

        StaticPopup_Show(ABSync.popups.missingKey)
        return false
    end

    -- set bar name
    -- barName = ActionBarSyncDB.global.actionBars[key]
    
    -- track if bar is found in currentBarData
    local barFound = false

    -- check for profile.barsToSync
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync = {}
    end

    -- check for the barName in profile.barsToSync
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] = false
    end

    -- set the bar to sync on input value to the profile: true or false based on the value passed into this function
    ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] = value

    --@debug@ let the user know the value is changed only when developing though
    if self:GetDevMode() == true then self:Print((ABSync.L["(%s) Set Bar '%s' to sync? %s - Done!"]):format("MarkBarToSync", barID, (value and "Yes" or "No"))) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   PlaceActionOnBar
    Purpose:    Place a specific action on a specific action bar and button.
    Parameters: 
        buttonActionID - the action ID from Blizzard API for the action to place on the bar
        actionType      - the type of action: spell, item, macro, summonpet, summonmount, flyout
        actionBar       - the action bar to place the action on; ActionBar1, ActionBar2, etc.
        actionButton    - the button number on the action bar to place the action on; 1 through max number of buttons
        sharedAction    - optional parameter that is used when placing an action from a sync instead of the
                          current character's action details
-----------------------------------------------------------------------------]]
function ABSync:PlaceActionOnBar(buttonActionID, actionType, actionBar, actionButton, sharedAction)
    -- translate action bar number into action bar name
    -- actionBar = ActionBarSyncDB.global.actionBars[actionBar]

    -- translate action bar and button into button assignments; for example Action Bar 4 & Button 9 is Action Button 33.
    local buttonID = ABSync.constants.actionButtonTranslation[actionBar][actionButton]
    --@debug@
    -- if self:GetDevMode() == true then
        -- self:Print(("(%s) Input Parameters - Btn Action ID: %s, ActionType: %s, ActionBar: %s, ActionButton: %s"):format("PlaceActionOnBar", tostring(buttonActionID), tostring(actionType), tostring(actionBar), tostring(actionButton)))
    -- end
    --@end-debug@

    -- get action details
    local actionDetails = {}
    if actionType ~= ABSync.L["Unknown"] and actionType ~= nil then
        actionDetails = self:GetActionData(buttonActionID, actionType, buttonID)
    end

    --@debug@
    -- if self:GetDevMode() == true then
        -- self:Print(("(%s) Action ID: %s, Action Type: %s, Action Bar: %s, Action Button: %s, Action Button ID: %s"):format("PlaceActionOnBar", tostring(buttonActionID), tostring(actionType), tostring(actionBar), tostring(actionButton), tostring(buttonID)))
    -- end
    --@end-debug@

    -- response
    local response = {
        parameters = {
            buttonActionID = buttonActionID,
            actionType = actionType,
            actionBar = actionBar,
            actionButton = actionButton,
            sharedAction = sharedAction or {},
        },
        placement = {
            buttonID = buttonID,
        },
        cursor = {
            type = ABSync.L["Unknown"],
            id = -1,
        },
        actionDetails = actionDetails,
        -- actionDetailsOverride only indicates if an actionType overrode actionDetails with sharedAction data, actionDetails is still populated with current character data
        actionDetailsOverride = false,
        msg = ABSync.L["Not Picked Up - Unknown"],
        pickedUp = false,
    }

    -- check for valid buttonActionID
    if sharedAction then
        if not sharedAction.parameters.buttonActionID then
            response.msg = ABSync.L["Not Picked Up - Invalid Shared Action ID!"]
            return response
        end
    else
        if actionDetails.parameters.buttonActionID <= 0 then
            response.msg = ABSync.L["Not Picked Up - Invalid Action ID!"]
            return response
        end
    end

    --[[ ** place action on bar based on type ** ]]

    --[[ spell - do not override with sharedAction, we need current details for the same spell to act on ]]

    if actionType == "spell" then
        -- if hasSpell is no, set message as not picked up and spell unknown
        if actionDetails.hasSpell == ABSync.L["No"] then
            response.msg = ABSync.L["Not Picked Up - Spell not known!"]

        -- otherwise hasSpell is yes, pick it up
        else
            -- track correct spellid
            local spellID = sharedAction.parameters.buttonActionID

            -- check for spell override with base spell ID
            if actionDetails.overrideWithBaseID == true then
                spellID = actionDetails.blizData.baseID
            end

            -- pickup the spell
            C_Spell.PickupSpell(spellID)
            response.pickedUp = true
        end

    --[[ item - do not override with sharedAction, we need current details for the same item to act on ]]

    elseif actionType == "item" then
        -- if user has a toy, pick it up as a toy
        if actionDetails.isToy == true then
            if actionDetails.has == ABSync.L["Yes"] then
                C_ToyBox.PickupToyBoxItem(sharedAction.parameters.buttonActionID)
                response.pickedUp = true
                response.msg = ABSync.L["Picked Up"]
            else
                response.msg = ABSync.L["Not Picked Up - Item is a toy but not usable by character!"]
            end

        -- if not a toy, other checks needed
        elseif actionDetails.userItemCount > 0 then
            C_Item.PickupItem(sharedAction.parameters.buttonActionID)
            response.pickedUp = true
            response.msg = ABSync.L["Picked Up"]
        else
            response.msg = ABSync.L["Not Picked Up - Item is not a toy and not in inventory!"]
        end

    --[[ macro - macros have to be processed differently since they can be character specific or general (account wide) ]]

    elseif actionType == "macro" then
        -- get macro type if this is a shared action, if nil, then it will get the current action's macro type
        local macroType = sharedAction.macroType or actionDetails.macroType

        -- if shared action and the macro type is character specific, don't pick it up since it won't be the same macro
        if sharedAction and macroType == ABSync.macroType.character then
            response.msg = ABSync.L["Not Picked Up - Macro from sync is character specific!"]

        -- if shared action and the macro type is general (account wide), pick it up
        elseif sharedAction and macroType == ABSync.macroType.general then
            PickupMacro(sharedAction.blizData.name)
            response.pickedUp = true
            response.msg = ABSync.L["Picked Up - General Macro"]

        -- not shared action so pick up based on current action details for this character
        elseif actionDetails.hasMacro == ABSync.L["Yes"] then
            PickupMacro(actionDetails.blizData.name)
            response.pickedUp = true
            response.msg = ABSync.L["Picked Up - Not Shared Macro"]
        end

    --[[ summonpet - do not override with sharedAction, we need current details for the same pet to act on ]]

    elseif actionType == "summonpet" then
        if actionDetails.hasPet == ABSync.L["No"] then
            response.msg = ABSync.L["Not Picked Up - Pet not known!"]
        else
            -- pickup the pet
            C_PetJournal.PickupPet(sharedAction.parameters.buttonActionID)
            response.pickedUp = true
            response.msg = ABSync.L["Picked Up"]
        end

    --[[ summonmount ]]

    elseif actionType == "summonmount" then
        if actionDetails.mountJournalIndex >= 0 then
            --@debug@
            if self:GetDevMode() == true then print(ABSync.L["Mount Journal Index: "], actionDetails.mountJournalIndex) end
            --@end-debug@
            C_MountJournal.Pickup(actionDetails.mountJournalIndex)
            response.pickedUp = true
            response.msg = ABSync.L["Picked Up"]
        else
            response.msg = ABSync.L["Not Picked Up - Mount not found! May need to reset mount filters and sync again."]
        end

    --[[ flyout ]]

    elseif actionType == "flyout" then
        if actionDetails.blizData.flyoutInfo.isKnown == ABSync.L["Yes"] then
            response.msg = ABSync.L["Not Picked Up - Flyout not known!"]
            if actionDetails.blizData.spellBookSlot.index and actionDetails.blizData.spellBookSlot.index > 0 then
                PickupSpellBookItem(actionDetails.blizData.spellBookSlot.index, actionDetails.blizData.spellBookSlot.bank)
                response.pickedUp = true
                response.msg = ABSync.L["Picked Up"]
                response.method = ABSync.L["From Spell Book"]
            else
                if actionDetails.blizData.name then
                    C_Spell.PickupSpell(actionDetails.blizData.name)
                    response.pickedUp = true
                    response.msg = ABSync.L["Picked Up"]
                    response.method = ABSync.L["As a Spell (Flyout Name)"]
                elseif actionDetails.flyoutID then
                    C_Spell.PickupSpell(actionDetails.flyoutID)
                    response.pickedUp = true
                    response.msg = ABSync.L["Picked Up"]
                    response.method = ABSync.L["As a Spell (Flyout ID)"]
                else
                    response.msg = ABSync.L["Not Picked Up - Flyout Name and ID was Nil!"]
                end
            end
        else
            response.msg = ABSync.L["Not Picked Up - Flyout not known!"]
        end

    --[[ unknown action type ]]

    else
        -- response to unknown action type; should never get here since the default is set to 'Unknown'
        response.msg = ABSync.L["Not Picked Up - Unknown Action Type!"]
        -- basically duplicate but lets make sure its false
        response.pickedUp = false
    end

    -- place action and clear the cursor
    if response.pickedUp == true then
        -- get cursor details
        local cursorType, cursorID = GetCursorInfo()
        response.cursor.type = cursorType or ABSync.L["Unknown"]
        response.cursor.id = cursorID or -1

        if cursorType then
            PlaceAction(tonumber(buttonID))
            ClearCursor()
        else
            response.pickedUp = false
            response.msg = ABSync.L["Not Placed - Cursor Empty!"]
        end
    end

    -- return response
    return response
end

--[[---------------------------------------------------------------------------
    Function:   SafeWoWAPICall
    Purpose:    Safely execute a WoW API call with error handling.
    Arguments:  func - Function to call
                ... - Arguments to pass to the function
    Returns:    Table with success status, result, and error message
-----------------------------------------------------------------------------]]
function ABSync:SafeWoWAPICall(func, ...)
    -- set language variable
    local L = self.L
    
    local success, result = pcall(func, ...)
    
    if success then
        return {
            success = true,
            result = result,
            error = nil
        }
    else
        --@debug@
        if self:GetDevMode() == true then
            self:Print((ABSync.L["API Error: %s"]):format(tostring(result)))
        end
        --@end-debug@
        
        return {
            success = false,
            result = nil,
            error = result or L["Unknown"]
        }
    end
end

--[[---------------------------------------------------------------------------
    Function:   UpdateSharedData
    Purpose:    Update the global shared data structure with the current character's bar data for any bars they are sharing.]]
-----------------------------------------------------------------------------]]
function ABSync:UpdateSharedData()
    -- loop over the barsToSync table from global
    for barID, owners in pairs(ActionBarSyncDB.global.barsToSync) do
        -- loop over the owners of the bar
        for owner, buttonData in pairs(owners) do
            -- if the owner is the current player and spec and the table isn't empty, copy from the currentBarData to the global barsToSync structure
            if owner == self.currentPlayerServerSpec and buttonData ~= false then
                -- copy the data
                ActionBarSyncDB.global.barsToSync[barID][self.currentPlayerServerSpec] = ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID]
            end
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   ShareBar
    Purpose:    Set the bar to share for the current global db settings.
-----------------------------------------------------------------------------]]
function ABSync:ShareBar(barID, value, checkbox)
    -- instantiate db to ensure barID structures exist
    self:InstantiateDBGlobal(barID)

    -- track if bar is found in profile.currentBarData
    local barFound = self:ConfirmBar(barID)

    -- if currentBarData is emtpy then let user know they must trigger a sync first
    if barFound == false then
        StaticPopupDialogs[ABSync.popups.noscan] = {
            text = (ABSync.L["Current bar configuration for '%s' is not found. Scan and try sharing again. Proceed with a scan?"]):format(barID),
            button1 = ABSync.L["OK"],
            button2 = ABSync.L["Cancel"],
            timeout = 0,
            hideOnEscape = true,
            preferredIndex = 2,
            OnAccept = function(self)
                StaticPopup_Hide(ABSync.popups.noscan)
                ABSync:GetActionBarData()
            end,
        }
        StaticPopup_Show(ABSync.popups.noscan)

        -- uncheck the checkbox
        if checkbox then
            checkbox:SetChecked(false)
        end

        -- just return to cancel the rest of the function
        return false
    end

    -- if the value is true, add the bar data to the buttonsToSync table under the barsToSync[barID] table
    if value == true then
        -- add the bar data
        ActionBarSyncDB.global.barsToSync[barID][self.currentPlayerServerSpec] = ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID]
    else
        -- remove all the button data
        ActionBarSyncDB.global.barsToSync[barID][self.currentPlayerServerSpec] = false
    end

    -- update the check boxes in the share area
    ABSync:ProcessSyncRegion("ShareBar")

    --@debug@
    -- if self:GetDevMode() == true then self:Print(("(%s) Set Bar '%s' to sync? %s - Done!"):format("ShareBar", barName, (value and "Yes" or "No"))) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   TriggerBackup
    Purpose:    Compare two action bar button data tables.
-----------------------------------------------------------------------------]]
function ABSync:TriggerBackup(note, barsToProcess)
    --@debug@
    -- print("TriggerBackup Called")
    --@end-debug@

    -- set up backup timestamp
    local backupdttm = self:GetCurrentDateTime()
    -- local lastSyncedUpdated = self:SetLastSynced(backupdttm)
    
    -- update the UI last synced label
    -- ABSync:UpdateLastSyncLabel()

    -- track any errors in the data
    local errors = {}

    -- make sure data path exists
    if not ActionBarSyncDB.char[self.currentPlayerServerSpec].backup then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].backup = {}
    end

    -- force bar refresh
    self:GetActionBarData()

    -- loop over the values and act on true's
    local backupData = {}

    -- if barsToProcess is nil, set to the barsToSync for the character
    if not barsToProcess then
        barsToProcess = ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync
    end

    -- for completeness sake, make sure records are found to be synced...this is actually done in the calling parent but if I decide to call this function elsewhere better check!
    local syncDataFound = false
    for barID, syncOn in pairs(barsToProcess) do
        if syncOn ~= false then
            --@debug@
            if self:GetDevMode() == true then
                self:Print((ABSync.L["Backing Up Action Bar '%s'..."]):format(barID))
            end
            --@end-debug@

            -- make sync data found
            syncDataFound = true

            -- instantiate the barID index
            backupData[barID] = {}

            -- get the current bar data for the current barID; not the profile bar data to sync
            for buttonID, buttonData in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID]) do
                backupData[barID][buttonID] = buttonData
            end
        end
    end

    -- add error if no sync data found
    if syncDataFound == false then
        table.insert(errors, ABSync.L["No sync data found for backup."])
    end

    -- count number of backups
    local backupCount = 0
    for _ in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup) do
        backupCount = backupCount + 1
    end
    --@debug@
    if self:GetDevMode() == true then
        self:Print((ABSync.L["Current Backup Count: %d"]):format(backupCount))
    end
    --@end-debug@

    -- if more than 9 then remove the oldest 1
    -- next retrieves the key of the first entry in the backup table and then sets it to nil which removes it
    while backupCount > 9 do
        -- local oldestBackup = next(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup)
        -- ActionBarSyncDB.char[self.currentPlayerServerSpec].backup[oldestBackup] = nil
        --@debug@
        if self:GetDevMode() == true then
            local oldestBackupDttm = ABSync.L["Unknown"]
            if ActionBarSyncDB.char[self.currentPlayerServerSpec].backup[1] then
                if ActionBarSyncDB.char[self.currentPlayerServerSpec].backup[1].dttm then
                    oldestBackupDttm = ActionBarSyncDB.char[self.currentPlayerServerSpec].backup[1].dttm
                end
            end
            self:Print((ABSync.L["Removing oldest backup entry dated: %s"]):format(ABSync:FormatDateString(oldestBackupDttm)))
        end
        --@end-debug@
        table.remove(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup, 1)
        backupCount = backupCount - 1
    end

    -- add backup to db
    local backupEntry = {
        dttm = backupdttm,
        note = note or ABSync.L["No note provided!"],
        error = errors,
        data = backupData,
    }
    table.insert(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup, backupEntry)

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
    TODO:       Will likely need some adjustment for other languages.
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
    local checkValues = { "sourceIDString", "sourceIDNumber", "actionType", "subType" }

    -- determine differences
    if isRestore == false then
        --@debug@
        if self:GetDevMode() == true then
            self:Print((ABSync.L["Player Server Spec: %s"]):format(tostring(self.currentPlayerServerSpec)))
        end
        --@end-debug@
        -- compare the global barsToSync data to the user's current action bar data
        -- loop over only the bars the character wants to sync
        for barID, sharedby in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync) do
            --@debug@
            if self:GetDevMode() == true then
                self:Print((ABSync.L["Bar ID: %s, Shared By: %s"]):format(barID, tostring(sharedby)))
            end
            --@end-debug@
            if sharedby ~= false then
                --@debug@
                if self:GetDevMode() == true then
                    self:Print((ABSync.L["Bar ID: %s, Shared By: %s, Button ID: %s"]):format(barID, sharedby, tostring(buttonID)))
                end
                --@end-debug@
                -- loop over the shared data
                for buttonID, buttonData in pairs(ActionBarSyncDB.global.barsToSync[barID][sharedby]) do
                    -- loop over checkValues
                    for _, testit in ipairs(checkValues) do
                        if buttonData.blizData.actionInfo[testit] ~= ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID][buttonID].blizData.actionInfo[testit] then
                            differencesFound = true
                            table.insert(differences, {
                                shared = ActionBarSyncDB.global.barsToSync[barID][sharedby][buttonID],
                                current = ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID][buttonID],
                                barID = barID,
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
        for _, backupRow in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup) do
            -- verify the row has the matching date/time
            if backupRow.dttm == backupdttm then
                -- loop over the action bars
                for barID, barData in pairs(backupRow.data) do
                    -- loop over the buttons
                    for buttonID, buttonData in pairs(barData) do
                        -- loop over checkValues
                        for _, testit in ipairs(checkValues) do
                            --@debug@
                            -- self:Print(("Test It: %s, Button Data: %s, Current Data: %s"):format(testit, tostring(buttonData[testit]), tostring(ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barName][buttonID][testit])))
                            --@end-debug@
                            -- compare values
                            if buttonData.blizData.actionInfo[testit] ~= ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID][buttonID].blizData.actionInfo[testit] then
                                differencesFound = true
                                table.insert(differences, {
                                    shared = buttonData,
                                    current = ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID][buttonID],
                                    barID = barID,
                                    sharedBy = self.L["Restore"],
                                })
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    -- capture last diff data
    if isRestore == true then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastDiffDataRestore = differences
    else
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastDiffData = differences
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
    if self:GetDevMode() == true then
        self:Print((ABSync.L["(%s) Starting update process. Is Restore? %s"]):format("UpdateActionBars", isRestore and "Yes" or "No"))
    end
    --@end-debug@

    -- store differences
    local differences, differencesFound = self:GetActionBarDifferences(backupdttm, isRestore)

    -- reset mount filter if user has the option checked
    if ABSync:GetAutoResetMountFilters() == true then
        ABSync:MountJournalFilterReset()
    end

    -- do we have differences?
    if differencesFound == false then
        -- show popup telling user no differences found
        StaticPopupDialogs[ABSync.popups.nodiffsfound] = {
            text = self.L["For the action bars flagged for syncing, no differences were found."],
            button1 = self.L["OK"],
            timeout = 15,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show(ABSync.popups.nodiffsfound)
    else
        -- track any errors
        local errors = {}

        -- track any successes
        local successes = {}

        -- track if a mount issue occurred
        local mountIssue = false
        local mountIssueCount = 0
        local mountCount = 0

        -- loop over differences and apply changes
        for _, diffData in ipairs(differences) do
            -- process the button
            local placementResponse = self:PlaceActionOnBar(diffData.shared.parameters.buttonActionID, diffData.shared.parameters.actionType, diffData.barID, diffData.shared.barPosn, diffData.shared)

            -- instantiate variables
            local err = false

            -- count number of mounts processed
            if diffData.shared.parameters.actionType == "summonmount" then
                mountCount = mountCount + 1
            end

            -- check if the action was not placed
            if placementResponse.pickedUp == false then
                -- update error record with data; if not false then there is an error to report
                err = {
                    barName = ABSync.barNameLanguageTranslate[diffData.barID],
                    barID = diffData.barID,
                    barPosn = diffData.shared.barPosn,
                    buttonID = placementResponse.placement.buttonID,
                    type = diffData.shared.blizData.actionInfo.actionType,
                    name = diffData.shared.blizData.name,
                    buttonActionID = diffData.shared.parameters.buttonActionID,
                    link = diffData.shared.blizData.link or ABSync.L["Unknown"],
                    sharedby = diffData.sharedBy,
                    msg = placementResponse.msg
                }
                table.insert(errors, err)

                -- report mount issue
                if err.type == "summonmount" then
                    mountIssueCount = mountIssueCount + 1
                    mountIssue = true
                end

                -- remove button if there was an error and user has the checkbox checked to remove on placement failure
                if ABSync:GetPlacementErrorClearButton() == true then
                    --@debug@
                    -- if self:GetDevMode() == true then
                        -- self:Print(("Removing action from buttonID: %s due to placement error."):format(tostring(err.buttonID)))
                    -- end
                    --@end-debug@
                    self:RemoveButtonAction(err.buttonID)
                end
            else
                table.insert(successes, placementResponse)
            end
        end

        --[[ clean up error records; keep max 10; remove down to 9 then add the new one ]]

        -- count number of sync error records
        local syncErrorCount = 0
        for _ in pairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors) do
            syncErrorCount = syncErrorCount + 1
        end

        -- if more than 9 then remove the oldest 1
        -- since we use table.insert it always adds records to the end of the table and the oldest is at the top so keep deleting until we get to 9 records
        -- because we will insert one after this step
        while syncErrorCount > 9 do
            table.remove(ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors, 1)
            syncErrorCount = syncErrorCount - 1
        end

        -- store results
        --@debug@
        if self:GetDevMode() == true then self:Print((ABSync.L["Action Bar Sync encountered errors during a sync; key: '%s':"]):format(backupdttm)) end
        --@end-debug@

        -- make sure syncErrors exists
        if not ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors then
            ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors = {}
        end
        
        -- write to db
        table.insert(ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors, {
            key = backupdttm,
            errors = errors,
            successes = successes,
        })

        -- make sure lastSyncErrorDttm exists
        if not ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm then
            ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm = ""
        end

        -- update lastSyncErrorDttm
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm = backupdttm

        -- update the UI
        ABSync:ProcessErrorData()
        
        -- show popup if mount issue is true
        if mountIssue == true then
            StaticPopupDialogs[ABSync.popups.mountissue] = {
                text = (ABSync.L["%d out of %d mount issues occurred. The functionality from Blizzard to assign mounts to an action bar requires those mounts to be visible in the Mount Journal. The issues this addon has encountered could be caused by the current Mount Journal filters. Either reset the filters to default or click the button 'Reset Mount Journal Filters' (only makes collected and usable mounts visible) and try the sync again."]):format(mountIssueCount, mountCount),
                button1 = ABSync.L["OK"],
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show(ABSync.popups.mountissue)
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetActionDataWithButtonName
    Purpose:    Retrieve action button data based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetActionDataWithButtonName(buttonActionID, btnName)
    -- blizzard api; get action type, the buttons action ID (ex.: spellID, itemID, macroID, etc), and subType (ex.: spellbook, bag, etc)
    local actionType, buttonActionID, subType = GetActionInfo(buttonActionID)
    --@debug@
    -- if actionType == "macro" then
    --     print(("Action ID: '%s', Button Name: '%s', Action Type: '%s', Info ID: '%s', Sub Type: '%s'"):format(buttonActionID, btnName, actionType, buttonActionID, subType))
    -- end
    --@end-debug@

    -- fetch data with standard function
    local actionDetails = self:GetActionData(buttonActionID, actionType)

    -- add in additional properties from this function
    actionDetails.barPosn = tonumber(string.match(btnName, "(%d+)$")) or -1
    -- GetActionInfo
    actionDetails.blizData.actionInfo = {
        actionType = actionType or ABSync.L["Unknown"],
        subType = subType or ABSync.L["Unknown"],
        sourceIDString = tostring(buttonActionID) or ABSync.L["Unknown"],
        sourceIDNumber = tonumber(buttonActionID) or -1,
    }
    actionDetails.parameters.buttonActionID = buttonActionID or -1
    actionDetails.parameters.btnName = btnName or ABSync.L["Unknown"]

    -- finally return the data
    return actionDetails
end

--[[---------------------------------------------------------------------------
    Function:   GetActionBarData
    Purpose:    Fetch current action bar button data.
-----------------------------------------------------------------------------]]
function ABSync:GetActionBarData()
    -- reset actionBars
    ActionBarSyncDB.global.actionBars = {}
    
    -- reset currentBarData
    ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData = {}

    -- track scan errors
    -- TODO: variable is not used...
    local errs = {
        lastScan = "TBD",
        data = {}
    }
    
    -- get action bar details
    for btnName, btnData in pairs(_G) do
        -- filter out by proper naming of the action bars done by blizzard
        -- need to know if this changes based on language!
        if string.find(btnName, "^ActionButton%d+$") or string.find(btnName, "^MultiBarBottomLeftButton%d+$") or string.find(btnName, "^MultiBarBottomRightButton%d+$") or string.find(btnName, "^MultiBarLeftButton%d+$") or string.find(btnName, "^MultiBarRightButton%d+$") or string.find(btnName, "^MultiBar%d+Button%d+$") then
            -- make up a name for each bar using the button names by removing the button number
            local blizzardBarName = string.gsub(btnName, ABSync.L["Button%d+$"], "")
            --@debug@
            -- self:Print(("Processing Button Name: %s, Bar Name: %s"):format(btnName, blizzardBarName))
            --@end-debug@

            -- translate and replace barName into the blizzard visible name in settings for the bars
            local barID = ABSync.blizzardTranslate[blizzardBarName]
            local barName = ABSync.barNameLanguageTranslate[barID] or ABSync.L["Unknown"]
            --@debug@
            -- self:Print(("Bar ID: %s, Bar Name: %s, Blizzard Bar Name: %s"):format(barID, barName, blizzardBarName))
            --@end-debug@

            -- skip bar if unknown
            if barName == ABSync.L["Unknown"] then
                -- self:Print((ABSync.L["Action Bar Button '%s' is not recognized as a valid action bar button. Skipping..."]):format(barName))
                -- TODO: Need to log this as a scan error.

            -- continue if barname is known
            else
                -- get action ID and type information
                local buttonActionPosn = btnData:GetPagedID()

                -- process more data for info based on actionType
                local buttonData = self:GetActionDataWithButtonName(buttonActionPosn, btnName)

                -- check if barID exists in actionBars
                local barIDFound = false
                for _, existingBarID in ipairs(ActionBarSyncDB.global.actionBars) do
                    if existingBarID == barID then
                        barIDFound = true
                        break
                    end
                end

                -- instantiate barID
                if barIDFound == false then
                    self:InstantiateDBGlobal(barID)
                    self:InstantiateDBChar(barID)
                    table.insert(ActionBarSyncDB.global.actionBars, barID)
                end

                -- check the barID exists in currentBarData
                if not ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID] then
                    ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID] = {}
                end

                -- insert the info table into the current action bar data
                -- table.insert(ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID], buttonActionID, buttonData)
                ActionBarSyncDB.char[self.currentPlayerServerSpec].currentBarData[barID][buttonActionPosn] = buttonData
            end
        end
    end

    -- sort the actionBars table
    table.sort(ActionBarSyncDB.global.actionBars, function(a, b)
        return a < b
    end)

    -- set a new last scan date/time
    self:SetLastScan(self:GetCurrentDateTime())

    -- capture last scan data
    errs.lastScan = self:GetLastScan()

    -- update the last scan label in the UI
    ABSync:UpdateLastScanLabel()

    -- update shared bar data
    ABSync:UpdateSharedData()

    -- let user know its done
    --@debug@
    if self:GetDevMode() == true then self:Print(ABSync.L["Fetch Current Action Bar Button Data - Done"]) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   EnableDevelopment
    Purpose:    Enable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:EnableDevelopment()
    -- enable development mode
    self:SetDevMode(true)

    -- enable button
    self:SetDeveloperTabVisibleState(true)

    -- give user status
    self:Print(ABSync.L["Development Mode: Enabled"])
end

--[[---------------------------------------------------------------------------
    Function:   DisableDevelopment
    Purpose:    Disable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:DisableDevelopment()
    if self:GetTab() == "developer" then
        -- switch to default tab if the user is on the developer tab
        self:SetTab("introduction")
    end

    -- disable development mode
    self:SetDevMode(false)

    -- enable button
    self:SetDeveloperTabVisibleState(false)

    -- give user status
    self:Print(ABSync.L["Development Mode: Disabled"])
end

--[[---------------------------------------------------------------------------
    Function:   SlashCommand
    Purpose:    Respond to all slash commands.
-----------------------------------------------------------------------------]]
function ABSync:SlashCommand(text)
    -- if no text is provided, show the options dialog
    if text == nil or text == "" then
        self:ShowUI()
        return
    end

    -- get args
    for _, arg in ipairs(self:GetArgs(text)) do
        if arg:lower() == "sync" then
            self:BeginSync()
        --@debug@
        elseif arg:lower() == "enablemodedeveloper" then
            if not self:GetDevMode() or self:GetDevMode() == false then
                self:EnableDevelopment()
            else
                self:DisableDevelopment()
            end
        elseif arg:lower() == "refreshmountdb" then
            if self:GetDevMode() == true then
                self:RefreshMountDB()
            end
        elseif arg:lower() == "fonts" then
            ABSync:CreateFontStringExamplesFrame():Show()
        elseif arg:lower() == "dodiffs" then
            self:Print(ABSync.L["Doing Diffs..."])
            local isRestore = false
            local dttm = self:GetCurrentDateTime()
            ABSync:GetActionBarDifferences(dttm, isRestore)
        --@end-debug@
        else
            self:Print((ABSync.L["Unknown Command: %s"]):format(arg))
        --@debug@
        -- elseif arg:lower() == "spec" then
        --     local specializationIndex = C_SpecializationInfo.GetSpecialization()
        --     self:Print(("Current Specialization Index: %s"):format(tostring(specializationIndex)))
        --     local specId, name, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)
        --     self:Print(("Specialization ID: %d, Name: %s"):format(specId, name or ABSync.L["Unknown"]))
        -- elseif arg:lower() == "test" then
            -- local mountIDs = C_MountJournal.GetMountIDs()
            -- for midx, mountID in ipairs(mountIDs) do
            --     -- local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, sourceMountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
            --     -- self:Print(("(Test) Mount - Name: %s - ID: %d - Source ID: %d"):format(name, mountID, sourceMountID))
            --     self:Print(("<Test> Mount - ID: %d (%d)"):format(mountID, midx))
            -- end
        --@end-debug@
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   EventPlayerLogout
    Purpose:    Handle functionality which is best or must wait for the PLAYER_LOGOUT event.
-----------------------------------------------------------------------------]]
function ABSync:EventPlayerLogout()
    --@debug@
    if self:GetDevMode() == true then self:Print(ABSync.L["Player Logging Out..."]) end
    --@end-debug@

    -- clear currentBarData and actionBars when not in developer mode
    if self:GetDevMode() == false then
        ABSync.db.profile[self.currentPlayerServer].currentBarData = {}
        ABSync:ClearMountDB()
    end
end

--[[---------------------------------------------------------------------------
    Function:   OnSpecializationChanged
    Purpose:    Handle specialization change events to update action bar sync data and the player key which includes spec.
-----------------------------------------------------------------------------]]
function ABSync:OnSpecializationChanged(event, ...)
    -- do not run function unless player has entered world event has triggered
    if self.hasPlayerEnteredWorld == false then
        --@debug@
        -- if self:GetDevMode() == true then
        --     self:Print("OnSpecializationChanged skipped since PLAYER_ENTERING_WORLD has not triggered yet.")
        -- end
        --@end-debug@
        return
    end

    -- only allow this event content to trigger once
    if not ABSync.specializationChangeProcessed or ABSync.specializationChangeProcessed == false then
        -- set value to true which will run all the code below
        ABSync.specializationChangeProcessed = true
    else
        -- set value to false and then return to skip the rest of the code
        ABSync.specializationChangeProcessed = false
        return
    end
    
    --@debug@
    -- event notification
    if self:GetDevMode() == true then 
        self:Print(ABSync.L["Specialization Changed"])
    end

    -- capture ellipse properties into a table for processing
    --[[local eventArgs = {...}
    if self:GetDevMode() == true then 
        self:Print(("Specialization Changed - Event: %s, Args Count: %d"):format(event, #eventArgs))
        
        -- loop through the ellipse properties
        for argIndex, argValue in ipairs(eventArgs) do
            local argType = type(argValue)
            local displayValue = argValue
            
            -- handle different argument types for debugging
            if argType == "string" then
                displayValue = ("'%s'"):format(argValue)
            elseif argType == "boolean" then
                displayValue = argValue and ABSync.L["Yes"] or ABSync.L["No"]
            elseif argType == "nil" then
                displayValue = ABSync.L["Unknown"]
            elseif argType == "table" then
                displayValue = "Table"
            else
                displayValue = tostring(argValue)
            end
            
            self:Print(("  Arg %d (%s): %s"):format(argIndex, argType, displayValue))
        end
    end]]
    --@end-debug@

    -- update content
    if ActionBarSyncMainFrame and ActionBarSyncMainFrame:IsVisible() then
        -- update player keys
        ABSync:SetKeyPlayerServerSpec()
        ABSync:SetKeyPlayerServer()

        -- act based on which tab is currently visible
        if ABSync:GetTab() == "sharesync" then
            ABSync:UpdateLastScanLabel()
            ABSync:UpdateLastSyncLabel()
            ABSync:ProcessShareCheckboxes("CreateMainFrame:OnShow")
            ABSync:ProcessSyncRegion("CreateMainFrame:OnShow")
        elseif ABSync:GetTab() == "backup" then
            ABSync:ProcessBackupListFrame()
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   OnDisable
    Purpose:    Trigger code when addon is disabled.
-----------------------------------------------------------------------------]]
function ABSync:OnDisable()
    -- set language variable
    local L = self.L
    
    -- Unregister events by removing the event frame
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript("OnEvent", nil)
    end

    if self:GetDevMode() == true then
        self:Print(ABSync.L["Disabled"])
    end

    -- same clean up should occur when disabled
    ABSync:EventPlayerLogout()
end

--[[---------------------------------------------------------------------------
    Function:   RegisterAddonEvents
    Purpose:    Register all events for the addon using native WoW event system.
-----------------------------------------------------------------------------]]
function ABSync:RegisterAddonEvents()
    --@debug@
    -- if self:GetDevMode() == true then
    --     self:Print(ABSync.L["Registering Events..."]) 
    -- end
    --@end-debug@

    -- PLAYER_ENTERING_WORLD
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self, event, ...)
        -- get event parameters
        local isInitialLogin, isReload = ...
        --@debug@
        -- ABSync:Print(("Event - %s, isInitialLogin: %s, isReload: %s"):format(event, tostring(isInitialLogin) and ABSync.L["Yes"] or ABSync.L["No"], tostring(isReload) and ABSync.L["Yes"] or ABSync.L["No"]))
        --@end-debug@

        -- instantiate player keys
        ABSync:SetKeyPlayerServerSpec()
        ABSync:SetKeyPlayerServer()

        -- run db initialize again but pass in barName to make sure all keys are setup for this barName
        ABSync:InstantiateDB(nil)

        -- only run these commands if this is the initial login
        if isInitialLogin == true then
            -- name the timer
            local timerName = "AutoSyncOnLogon"

            -- set a timer to trigger an auto sync
            ABSync:Timer(timerName, 5, function(timerName)
                
                -- get action bar data automatically if user has opted in through the settings checkbox
                if ABSync:GetSyncOnLogon() == true or ABSync:GetLastScan() == ABSync.L["Never"] then
                    ABSync:Print(ABSync.L["Starting automatic action bar data scan..."])
                    ABSync:BeginSync(true)
                end

                -- clear timer
                ABSync:TimerClear(timerName)
            end)
        end
        
        -- update global variable for tracking if event has triggered
        ABSync.hasPlayerEnteredWorld = true
    end)

    -- PLAYER_LOGOUT
    self:RegisterEvent("PLAYER_LOGOUT", function(self, event, ...)
        --@debug@
        -- ABSync:Print(("Event Triggered - %s"):format(event))
        --@end-debug@
        ABSync:EventPlayerLogout()
    end)

    -- VARIABLES_LOADED
    self:RegisterEvent("VARIABLES_LOADED", function(self, event, ...)
        --@debug@
        -- ABSync:Print(("Event Triggered - %s"):format(event))
        --@end-debug@
    end)

    -- ACTIVE_TALENT_GROUP_CHANGED
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", function(self, event, ...)
        --@debug@
        -- ABSync:Print(("Event Triggered - %s"):format(event))
        --@end-debug@
        ABSync:OnSpecializationChanged(event, ...)
    end)

    -- PLAYER_SPECIALIZATION_CHANGED
    -- self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(self, event, ...)
    --     --@debug@
    --     ABSync:Print(("Event Triggered - %s"):format(event))
    --     --@end-debug@
    --     ABSync:OnSpecializationChanged(event, ...)
    -- end)
end

--[[---------------------------------------------------------------------------
    Function:   GetCheckboxOffsetY
    Purpose:    Calculate the vertical offset for a checkbox based on its size, padding, and text width.
    Arguments:  checkbox - the checkbox object to calculate the offset for
    Returns:    calculated vertical offset
-----------------------------------------------------------------------------]]
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
    Function:   UncheckAllBackups
    Purpose:    Uncheck all child checkboxes, except the one just clicked, in the given frame.
    Inputs:     frame       - parent frame containing the checkboxes
                checkbox    - checkbox that was just clicked; don't uncheck it
-----------------------------------------------------------------------------]]
function ABSync:UncheckAllBackups(frame, checkbox)
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
    Function:   SetDeveloperTabVisibleState
    Purpose:    Show/hide the developer tab based on input parameter.
    Arguments:  makeVisible - boolean; true to show, false to hide
-----------------------------------------------------------------------------]]
function ABSync:SetDeveloperTabVisibleState(makeVisible)
    local devTabButton = self:GetObjectName("TabButtonDeveloper")
    if _G[devTabButton] then
        if makeVisible then
            _G[devTabButton]:Show()
        else
            _G[devTabButton]:Hide()
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   ShowErrorLog
    Purpose:    Open custom UI to show last sync errors to user.
-----------------------------------------------------------------------------]]
function ABSync:ShowUI(openDelaySeconds)
    -- make sure key name, server and spec are set
    self:SetKeyPlayerServerSpec()

    -- make sure openDelaySeconds is not nil
    if not openDelaySeconds then
        openDelaySeconds = 0
    end

    -- be sure frame doesn't exist
    if not ActionBarSyncMainFrame then
        -- create main frame
        ABSync:CreateMainFrame()

        -- create tab group
        ABSync:ProcessTabSystem(ActionBarSyncMainFrame)

        -- create content area
        ABSync:CreateContentFrame(ActionBarSyncMainFrame)

        -- show initial tab
        local tabKey = self:GetTab()

        -- check on developer mode
        if self:GetDevMode() == false then
            -- hide developer tab button
            self:SetDeveloperTabVisibleState(false)

            -- if the current tab is developer then switch to introduction
            if tabKey == "developer" then
                tabKey = "introduction"
                self:SetTab(tabKey)
            end
        else
            -- show developer tab button
            self:SetDeveloperTabVisibleState(true)
        end
        --@debug@
        -- self:Print(("(ShowUI) Showing Initial Tab after creating UI: %s"):format(tabKey))
        --@end-debug@
        self:ShowTabContent(tabKey)
        local buttonID = ABSync.uitabs["buttonref"][tabKey]
        PanelTemplates_SetTab(ActionBarSyncMainFrameTabs, buttonID)
    end

    -- Trigger any necessary updates
    self:InstantiateDB(nil)  -- Ensure DB structure exists for new spec

    -- update action bar data
    self:GetActionBarData()

    -- display the frame
    ActionBarSyncMainFrame:Show()
end

--[[---------------------------------------------------------------------------
    Function:   ShowTabContent
    Purpose:    Show the content for the selected tab.
-----------------------------------------------------------------------------]]
function ABSync:ShowTabContent(tabKey)
    -- get current tab to hide
    local currentTab = self:GetTab()

    -- get global variable friendly tab name
    local varName = self.uitabs["varnames"][currentTab]

    -- get the global name of the tab
    local tabContentFrame = self:GetObjectName(ABSync.constants.objectNames.tabContentFrame .. varName)
    --@debug@
    -- self:Print(("(ShowTabContent) tabKey: %s, varName: %s, tabContentFrame is nil: %s"):format(tostring(tabKey), tostring(varName), tostring(tabContentFrame == nil)))
    --@end-debug@

    -- hide the tab
    if _G[tabContentFrame] then
        _G[tabContentFrame]:Hide()
    end
    
    --@debug@
    -- self:Print(("Showing Tab Content for tabKey: %s"):format(tostring(tabKey)))
    --@end-debug@

    -- set the tab
    self:SetTab(tabKey)

    -- currentframe
    local currentFrame = nil
    
    -- switch to the selected tab
    if tabKey == "about" then
        -- tabs\About.lua
        currentFrame = self:ProcessAboutFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "introduction" then
        -- tabs\Introduction.lua
        currentFrame = self:ProcessIntroductionFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "sharesync" then
        -- tabs\ShareSync.lua
        currentFrame = self:ProcessShareSyncFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "last_sync_errors" then
        -- tabs\LastSyncErrors.lua
        currentFrame = self:ProcessLastSyncErrorFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "lookup" then
        -- tabs\Lookup.lua
        currentFrame = self:ProcessLookupFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "backup" then
        -- tabs\Restore.lua
        currentFrame = self:ProcessBackupFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "utilities" then
        -- tabs\Utilities.lua
        currentFrame = self:ProcessUtilitiesFrame(ActionBarSyncMainFrameTabContent, tabKey)
    elseif tabKey == "developer" then
        -- tabs\Developer.lua
        currentFrame = self:ProcessDeveloperFrame(ActionBarSyncMainFrameTabContent, tabKey)
    end

    -- show new tab content frame
    if currentFrame then
        currentFrame:Show()
    end
end

--[[---------------------------------------------------------------------------
    Function:   StoreFramePosition
    Purpose:    Store the current frame position in the character database.
    Arguments:  frame - the frame whose position to store
-----------------------------------------------------------------------------]]
function ABSync:StoreFramePosition(frame)
    -- Get current position
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    -- get frame name
    local frameName = frame:GetName()
    if not frameName then
        if self:GetDevMode() == true then
            self:Print(ABSync.L["Error: Frame has no name, cannot store position."])
        end
        return
    end

    -- store position data in the character database
    local isSuccess = self:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)

    --@debug@
    -- if self:GetDevMode() == true then
    --     self:Print(("Frame position stored: %s %s %.1f %.1f"):format(point, relativePoint, xOfs, yOfs))
    -- end
    --@end-debug@

    return isSuccess
end

--[[---------------------------------------------------------------------------
    Function:   RestoreFramePosition
    Purpose:    Restore the frame position from stored data or center if bounds are invalid.
    Arguments:  frame - the frame to position
                frameWidth - width of the frame
                frameHeight - height of the frame
-----------------------------------------------------------------------------]]
function ABSync:RestoreFramePosition(frame, frameWidth, frameHeight)
    -- set language variable
    local L = self.L

    -- get frame name
    local frameName = frame:GetName()
    
    -- get stored position data
    local storedPosition = self:GetFramePosition(frameName)
    if not storedPosition then
        --@debug@
        if self:GetDevMode() == true then
            self:Print((ABSync.L["No stored position data found for frame: %s"]):format(frameName))
        end
        --@end-debug@
        return false
    end
    
    -- default to center position
    local point = "CENTER"
    local relativePoint = "CENTER"
    local xOffset = 0
    local yOffset = 0
    
    -- if we have stored position data, validate it's within bounds
    if storedPosition and storedPosition.point and storedPosition.xOffset and storedPosition.yOffset then
        local testX = storedPosition.xOffset
        local testY = storedPosition.yOffset
        
        -- get UIParent dimensions for bounds checking
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        
        -- calculate frame boundaries
        local halfWidth = frameWidth / 2
        local halfHeight = frameHeight / 2
        
        -- check if frame would be completely within UIParent bounds
        local withinBounds = true
        
        -- for CENTER positioning, check if frame stays within screen
        if storedPosition.point == "CENTER" then
            if (testX - halfWidth < -screenWidth/2) or (testX + halfWidth > screenWidth/2) or
               (testY - halfHeight < -screenHeight/2) or (testY + halfHeight > screenHeight/2) then
                withinBounds = false
            end

        -- for other anchor points, do more specific bounds checking
        elseif storedPosition.point == "TOPLEFT" then
            if testX < 0 or testY > 0 or 
               (testX + frameWidth > screenWidth) or (testY - frameHeight < -screenHeight) then
                withinBounds = false
            end
        elseif storedPosition.point == "BOTTOMRIGHT" then
            if testX > 0 or testY < 0 or
               (testX - frameWidth < -screenWidth) or (testY + frameHeight > screenHeight) then
                withinBounds = false
            end
        end
        
        -- use stored position if within bounds
        if withinBounds == true then
            point = storedPosition.point
            relativePoint = storedPosition.relativePoint
            xOffset = testX
            yOffset = testY
            
            --@debug@
            -- if self:GetDevMode() == true then
            --     self:Print(("Frame positioned from stored data: %s %.1f %.1f."):format(point, xOffset, yOffset))
            -- end
            --@end-debug@
        else
            --@debug@
            -- if self:GetDevMode() == true then
            --     self:Print("Stored frame position is outside bounds, centering frame.")
            -- end
            --@end-debug@
        end
    else
        --@debug@
        -- if self:GetDevMode() == true then
        --     self:Print("No stored frame position found, centering frame.")
        -- end
        --@end-debug@
    end
    
    -- Set the frame position
    frame:SetPoint(point, frame:GetParent(), relativePoint, xOffset, yOffset)
    return true
end

--[[---------------------------------------------------------------------------
    Function:   CreateMainFrame
    Purpose:    Create the main frame for the addon UI.
-----------------------------------------------------------------------------]]
function ABSync:CreateMainFrame()   
    -- get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    -- set initial sizes
    local frameWidth = screenWidth * 0.4
    local frameHeight = screenHeight * 0.4
    
    -- use PortraitFrameTemplate which is more reliable in modern WoW
    local frame = CreateFrame("Frame", "ActionBarSyncMainFrame", UIParent, "PortraitFrameTemplate")
    frame:SetSize(frameWidth, frameHeight)

    -- set the frame location
    local posnRestored = self:RestoreFramePosition(frame, frameWidth, frameHeight)

    -- frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- store window position
        ABSync:StoreFramePosition(self)
    end)
    frame:SetFrameStrata("HIGH")
    frame:SetTitle("Action Bar Sync")
    frame:SetPortraitToAsset("Interface\\Icons\\inv_misc_coinbag_special")
    
    -- enable escape key functionality following WoW addon patterns
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)

    -- setup OnShow event
    frame:SetScript("OnShow", function(self)
        if ABSync:GetTab() == "sharesync" then
            ABSync:UpdateLastScanLabel()
            ABSync:UpdateLastSyncLabel()
            ABSync:ProcessShareCheckboxes("CreateMainFrame:OnShow")
            ABSync:ProcessSyncRegion("CreateMainFrame:OnShow")
        end
    end)
    
    -- register frame for escape key handling using WoW's standard system
    tinsert(UISpecialFrames, "ActionBarSyncMainFrame")
    
    -- finally return the frame
    return frame
end

--[[---------------------------------------------------------------------------
    Function:   ProcessTabSystem
    Purpose:    Create a tab system at the bottom of the main frame.
-----------------------------------------------------------------------------]]
function ABSync:ProcessTabSystem(parent)
    -- instantiate variable for the main tab frame
    local tabFrame = nil

    -- check to see if tab system already exists
    if not ActionBarSyncMainFrameTabs then
        -- create a frame to hold the tabs
        tabFrame = CreateFrame("Frame", "ActionBarSyncMainFrameTabs", parent)
        
        -- position tabs at the bottom of the frame like Collections Journal
        tabFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, -5)
        tabFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, -5)
        tabFrame:SetHeight(30)
    else
        tabFrame = ActionBarSyncMainFrameTabs
    end

    -- track the tabs as we build them
    local tabButtons = {}

    -- keep track of tab count
    local tabCount = 0
    
    -- create tab buttons using PanelTabButtonTemplate
    for tabIndex, tabKey in ipairs(ABSync.uitabs.order) do
        -- get global variable friendly tab name
        local tabID = self.uitabs["varnames"][tabKey]
        --@debug@
        -- self:Print(("Processing Tab ID: %s (Index: %d, Key: %s, Var Friendly: %s, Label: %s)"):format(tostring(tabKey), tabIndex, tostring(tabKey), tostring(tabID), tostring(ABSync.uitabs.tabs[tabKey])))
        --@end-debug@

        -- create the tab button ID
        local tabButtonID = self:GetObjectName("TabButton" .. tabID)
        --@debug@
        -- self:Print(("Creating Tab Button: %s"):format(tabButtonID))
        --@end-debug@

        -- create variable for button
        local button = nil

        -- if tabButtonID doesn't exist create it
        if not _G[tabButtonID] then
            -- use PanelTabButtonTemplate for authentic Collections UI styling
            button = CreateFrame("Button", tabButtonID, tabFrame, "PanelTabButtonTemplate")
            button:SetID(tabIndex)
            local tabname = ABSync.uitabs.tabs[tabKey]
            button:SetText(tabname)
            self.uitabs["buttonref"][tabKey] = tabIndex
            
            -- use PanelTemplates functions for proper tab behavior
            PanelTemplates_TabResize(button, 0)

            -- set the buttons OnClick event
            button:SetScript("OnClick", function(self)
                --@debug@
                -- ABSync:Print(("Tab Clicked: %s (ID: %d)"):format(tabname, self:GetID()))
                --@end-debug@
                -- use PanelTemplates to handle tab selection properly
                PanelTemplates_SetTab(tabFrame, self:GetID())
                
                -- create the content for the tab
                ABSync:ShowTabContent(tabKey)
            end)
        else
            -- if it already exists just reference it
            button = _G[tabButtonID]
        end

        -- if this is the developer tab, hide it unless in dev mode
        if tabKey == "developer" and ABSync:GetDevMode() == false then
            button:Hide()
        end
         
        -- position tabs horizontally with proper spacing for Collections style
        if tabIndex == 1 then
            button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 11, 2)
        else
            button:SetPoint("LEFT", tabButtons[tabIndex-1], "RIGHT", -15, 0)
        end

        -- add button to table
        tabButtons[tabIndex] = button

        -- count the tabs
        tabCount = tabCount + 1
    end
    
    -- Set up the tab frame with PanelTemplates
    PanelTemplates_SetNumTabs(tabFrame, #tabButtons)
    PanelTemplates_SetTab(tabFrame, 1)

    -- initialize first tab to users last, if not set to introduction (which is done in GetTab)
    -- self:UpdateTabButtons()

    -- assign buttons to addon global
    ABSync.uitabs["buttons"] = tabButtons
end

--EOF