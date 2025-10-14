--[[ ------------------------------------------------------------------------
	Title: 			Restore.lua
	Author: 		mrbryo
	Create Date : 	2025-Oct-03
	Description: 	Building the Restore tab in the UI.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   ClearBackupActionBarDropdown
    Purpose:    Clear the action bar selection dropdown.
-----------------------------------------------------------------------------]]
--[[function ABSync:ClearBackupActionBarDropdown()
    if ABSync.ui.dropdown.currentBackupActionBars then
        local data = {}
        data["none"] = "None"
        ABSync.ui.dropdown.currentBackupActionBars:SetList(data)
        ABSync.ui.dropdown.currentBackupActionBars:SetValue("none")
    end
end]]

--[[---------------------------------------------------------------------------
    Function:   LoadBackupActionBars
    Purpose:    Load the action bars from a selected backup into the action bar selection dropdown.
-----------------------------------------------------------------------------]]
function ABSync:LoadBackupActionBars(parent, backupKey)
    -- find the backup record
    local found = false
    for _, backupRow in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup) do
        if backupRow.dttm == backupKey then
            -- instantiate needed data
            local newData = {}
            local dataAdded = false
            local itemOrder = {}
            local selectedItem = self:GetRestoreChoiceActionBar()

            -- loop over the action bars in the backup record and create a checkbox for each one
            for idx, actionBarID in ipairs(ABSync.actionBarOrder) do
                local tmprow = backupRow.data[actionBarID]
                local actionBarName = ABSync.barNameLanguageTranslate[actionBarID] or ABSync.L["Unknown"]
                if tmprow then
                    newData[actionBarID] = actionBarName
                    table.insert(itemOrder, actionBarID)
                    dataAdded = true
                    --@debug@
                    -- if self:GetDevMode() == true then
                        -- self:Print(("Found Action Bar in Backup: %s, ActionBar ID: %s"):format(actionBarName, actionBarID))
                    -- end
                    --@end-debug@
                end
            end

            -- if no data added then apply default value
            if not dataAdded then
                newData = {["none"] = ABSync.L["No Action Bars Backed Up"]}
                itemOrder = {"none"}
                selectedItem = "none"
            end

            -- update list
            self.ui.dropdown.actionBarSelection:UpdateItems(itemOrder, newData, selectedItem)

            -- set found to true
            found = true

            -- exit loop
            break
        end
    end
    -- if no records found then reset table with a single "None" value
    if found == false then
        self:ClearActionBarDropDown()
    end
end

--[[---------------------------------------------------------------------------
    Function:   ClearActionBarDropDown
    Purpose:    Clear the action bar selection dropdown and reset to a single "None" value.
-----------------------------------------------------------------------------]]
function ABSync:ClearActionBarDropDown()
    local items = {["none"] = ABSync.L["No Backups Selected"]}
    local itemOrder = {"none"}
    self.ui.dropdown.actionBarSelection:UpdateItems(itemOrder, items, "none")
end

--[[---------------------------------------------------------------------------
    Function:   UncheckAllBackups
    Purpose:    Uncheck all checkboxes stored in the backup list for checkboxes.
-----------------------------------------------------------------------------]]
function ABSync:UncheckAllBackups(parent, exclude)
    -- track unchecked boxes
    local processed = {}

    -- verify records exist
    if not ABSync.ui.checkbox.backupList then
        return
    end

    -- loop over the tracking variables and uncheck each checkbox
    for key, checkboxName in ipairs(ABSync.ui.checkbox.backupList or {}) do
        --@debug@
        -- if self:GetDevMode() == true then
            -- self:Print(("(UncheckAllBackups) Processing Checkbox: %s"):format(checkboxName))
        -- end
        --@end-debug@
        -- get checkbox to process it
        local currentBox = _G[checkboxName]
        if currentBox then
            -- track each checkbox if it exists
            table.insert(processed, checkboxName)

            -- if not the excluded checkbox, uncheck it
            if currentBox ~= exclude then
                currentBox:SetChecked(false)
            end
        end
    end

    -- override backupList with only checkboxes which exist
    ABSync.ui.checkbox.backupList = processed
end

--[[---------------------------------------------------------------------------
    Function:   ClearAllChildFrames
    Purpose:    Clear all child frames of the specified parent frame.
-----------------------------------------------------------------------------]]
function ABSync:ClearAllChildFrames(parent)
    -- loop over all children and remove them
    for _, child in ipairs({parent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
        child = nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   HideAllChildFrames
    Purpose:    Hide all child frames of the specified parent frame.
-----------------------------------------------------------------------------]]
function ABSync:HideAllChildFrames(parent)
    -- loop over all children and hide them
    for _, child in ipairs({parent:GetChildren()}) do
        child:Hide()
        --@debug@
        -- if self:GetDevMode() == true then
            -- print("Hiding Child Frame: " .. tostring(child:GetName()))
        -- end
        --@end-debug@
    end
end

--[[---------------------------------------------------------------------------
    Function:   AddBackupGlobalNames
    Purpose:    Track the global names of the backup checkboxes and groups for later reference.
-----------------------------------------------------------------------------]]
function ABSync:AddBackupGlobalNames(globalGroupName, globalCheckboxName)
    -- add checkbox global name to tracking array
    if not ABSync.ui.checkbox.backupList then
        ABSync.ui.checkbox.backupList = {}
    end

    -- add checkbox group global name to tracking array
    if not ABSync.ui.group.backupList then
        ABSync.ui.group.backupList = {}
    end

    -- make sure global name isn't already tracked
    local found = false
    for _, name in ipairs(ABSync.ui.checkbox.backupList) do
        if name == globalCheckboxName then
            found = true
            break
        end
    end

    -- insert if not found
    if not found then
        table.insert(ABSync.ui.checkbox.backupList, globalCheckboxName)
    end

    -- make sure global group name isn't already tracked
    found = false
    for _, name in ipairs(ABSync.ui.group.backupList) do
        if name == globalGroupName then
            found = true
            break
        end
    end

    -- insert if not found
    if not found then
        table.insert(ABSync.ui.group.backupList, globalGroupName)
    end
end

--[[---------------------------------------------------------------------------
    Function:   ProcessBackupListFrame
    Purpose:    Load the checkboxes for available backups into the scroll frame.
-----------------------------------------------------------------------------]]
function ABSync:ProcessBackupListFrame()
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- get the content frame for updating
    local scrollContent = nil
    local scrollContentName = self:GetObjectName("BackupListScrollContent")
    if _G[scrollContentName] then
        scrollContent = _G[scrollContentName]
    else
        -- if the frame doesn't exist, nothing to process
        return
    end

    -- remove all existing children from the scroll frame
    ABSync:HideAllChildFrames(scrollContent)

    -- add the available backups
    local trackInserts = 0
    local offsetY = 5
    --@debug@
    -- if self:GetDevMode() == true then
        -- self:Print(("(ProcessBackupListFrame) Current Character/Server Spec: %s - Backup Rows: %d"):format(self.currentPlayerServerSpec, #ActionBarSyncDB.char[self.currentPlayerServerSpec].backup) or 0)
    -- end
    --@end-debug@
    for _, backupRow in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup) do
        --@debug@
        -- if self:GetDevMode() == true then
            -- print(("(ProcessBackupListFrame) Found Backup Record: %s, Note: %s"):format(backupRow.dttm, backupRow.note or "No Description"))
        -- end
        --@end-debug@
        -- check for selected value
        local isChecked = false
        if self:GetRestoreChoiceDateTime() == backupRow.dttm then
            -- set the new checkbox to be checked since the dttm values match
            isChecked = true

            -- load the drop down with the action bars for this backup
            self:LoadBackupActionBars(scrollContent, backupRow.dttm)
        end

        -- instantiate variables
        local checkbox = nil
        local checkboxGroup = nil
        local checkboxNote = nil

        -- get global name for checkbox and note grouping
        local groupName = self:GetObjectName("CheckboxBackupGroup" .. backupRow.dttm)
        
        -- see if group frame already exists
        if _G[groupName] then
            -- if the group already exists, skip creating it again
            checkboxGroup = _G[groupName]
        else
            -- create a checkbox group for each backup to allow only one selection at a time
            checkboxGroup = CreateFrame("Frame", groupName, scrollContent)
        end

        -- position group frame
        checkboxGroup:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, -offsetY)
        checkboxGroup:SetPoint("RIGHT", scrollContent, "RIGHT", -5, 0)

        -- show the group frame
        checkboxGroup:Show()

        -- get global name for the checkbox
        local checkboxGlobalName = self:GetObjectName("CheckboxBackup" .. backupRow.dttm)

        -- track the name
        self:AddBackupGlobalNames(groupName, checkboxGlobalName)
        
        -- check if the checkbox already exists, if not create it
        if _G[checkboxGlobalName] then
            -- if the checkbox already exists, skip creating it again
            checkbox = _G[checkboxGlobalName]
        else
            -- create a checkbox for each backup
            checkbox = self:CreateCheckbox(checkboxGroup, self:FormatDateString(backupRow.dttm), isChecked, checkboxGlobalName, function(self, button, value)
                -- get the content frame for updating
                local scrollContent = nil
                local scrollContentName = ABSync:GetObjectName("BackupListScrollContent")
                if _G[scrollContentName] then
                    scrollContent = _G[scrollContentName]
                else
                    -- if the frame doesn't exist, nothing to process
                    return
                end

                -- clear all other checkboxes
                ABSync:UncheckAllBackups(scrollContent, self)
                
                -- if checked, load the action bars for this backup into the action bar selection scroll region
                if value == true then
                    -- track choice by character
                    ABSync:SetRestoreChoiceDateTime(backupRow.dttm)

                    -- update the drop down with action bars for this backup
                    ABSync:LoadBackupActionBars(scrollContent, backupRow.dttm)
                else
                    -- blank out selected backup
                    ABSync:SetRestoreChoiceDateTime(ABSync.L["None"])
                    ABSync:SetRestoreChoiceActionBar(ABSync.L["None"])

                    -- clear dropdown and choice
                    ABSync:ClearActionBarDropDown()
                end
            end)

            -- update location of checkbox
            checkbox:SetPoint("TOPLEFT", checkboxGroup, "TOPLEFT", 0, 0)

            -- get global name for the note
            local noteGlobalName = self:GetObjectName("CheckboxBackupNote" .. backupRow.dttm)

            -- check if the note already exists, if not create it
            if _G[noteGlobalName] then
                checkboxNote = _G[noteGlobalName]
            else
                checkboxNote = checkboxGroup:CreateFontString(noteGlobalName, "ARTWORK", "GameFontHighlightSmall")

                -- position the note
                checkboxNote:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 20, 0)
                checkboxNote:SetPoint("RIGHT", scrollContent, "RIGHT", -5, 0)
                checkboxNote:SetJustifyH("LEFT")
                checkboxNote:SetText(backupRow.note or ABSync.L["No Description"])
                checkboxNote:SetWordWrap(false)
            end

            -- update height of group frame
            checkboxGroup:SetHeight(checkbox:GetHeight() + checkboxNote:GetStringHeight())
        end

        -- track checkbox groups
        trackInserts = trackInserts + 1

        -- update offset for next insert
        offsetY = offsetY + checkboxGroup:GetHeight() + padding
    end

    -- final adjustment to content height
    scrollContent:SetHeight(offsetY)

    -- instantiate variables
    local noDataLabel = nil

    -- get global name for no data label
    local noDataLabelName = self:GetObjectName("CheckboxBackupNoDataLabel")

    -- check to see if label exists already
    if _G[noDataLabelName] then
        noDataLabel = _G[noDataLabelName]
    else
        noDataLabel = scrollContent:CreateFontString(noDataLabelName, "ARTWORK", "GameFontNormal")
        noDataLabel:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 5, -5)
        noDataLabel:SetPoint("RIGHT", scrollContent, "RIGHT", 0, 0)
        noDataLabel:SetJustifyH("LEFT")
        noDataLabel:SetText(ABSync.L["No Backups Found"])
    end

    -- insert empty records if no records inserted
    if trackInserts > 0 then
        --@debug@
        -- if self:GetDevMode() == true then
            -- self:Print(("Track Inserts: %d, Hiding No Data Label"):format(trackInserts))
        -- end
        --@end-debug@
        -- hide no data label
        noDataLabel:Hide()

        -- update dropdown
        ABSync:LoadBackupActionBars(scrollContent, self:GetRestoreChoiceDateTime())
    else
        --@debug@
        -- if self:GetDevMode() == true then
            -- self:Print(("Track Inserts: %d, Showing No Data Label"):format(trackInserts))
        -- end
        --@end-debug@
        -- show no data label
        noDataLabel:Show()
        
        -- update dropdown
        self:ClearActionBarDropDown()
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateBackupListFrame
    Purpose:    Create the backup list frame for displaying available backups.
-----------------------------------------------------------------------------]]
function ABSync:CreateBackupListFrame(parent)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- region label
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText(ABSync.L["Backups Available:"])

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("TOPRIGHT", regionLabel, "BOTTOMRIGHT", 0, 0)
    insetFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

    -- create a scroll container for the spreadsheet
    local scrollContainerName = self:GetObjectName("BackupListScrollContainer")
    local scrollContainer = nil

    -- see if the frame already exists
    if _G[scrollContainerName] then
        scrollContainer = _G[scrollContainerName]
    else
        scrollContainer = CreateFrame("ScrollFrame", scrollContainerName, insetFrame, "UIPanelScrollFrameTemplate")
    end

    -- adjust location
    scrollContainer:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", 5, -5)
    scrollContainer:SetPoint("BOTTOMRIGHT", insetFrame, "BOTTOMRIGHT", -27, 5)

    -- create scroll content frame
    local scrollContentName = self:GetObjectName("BackupListScrollContent")
    local scrollContent = nil

    -- see if the frame already exists
    if _G[scrollContentName] then
        scrollContent = _G[scrollContentName]
    else
        scrollContent = CreateFrame("Frame", scrollContentName, scrollContainer)
        scrollContainer:SetScrollChild(scrollContent)
    end

    -- adjust the frame
    scrollContent:SetWidth(scrollContainer:GetWidth() - padding)
    scrollContent:SetHeight(scrollContainer:GetHeight() - padding)
end

--[[---------------------------------------------------------------------------
    Function:   CreateRestoreFrame
    Purpose:    Create the restore frame for selecting which action bars to restore and a button to trigger it.
-----------------------------------------------------------------------------]]
function ABSync:CreateRestoreFrame(parent)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- region label
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText(ABSync.L["Restore one Action Bar per Click:"])

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("TOPRIGHT", regionLabel, "BOTTOMRIGHT", 0, 0)
    insetFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

    -- label for dropdown
    local dropdownLabel = insetFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText(ABSync.L["Select Action Bar to Restore:"])

    -- create drop down based on selected backup, initially it will have a fake value
    local items = {["none"] = ABSync.L["No Backups Selected"]}
    local itemOrder = {"none"}
    self.ui.dropdown.actionBarSelection = self:CreateDropdown(insetFrame, itemOrder, items, "none", self:GetObjectName("DropdownRestoreActionBar"), function(key)
        -- track choice by character
        if key ~= "none" and key ~= nil then
            ABSync:SetRestoreChoiceActionBar(key)
            -- ABSync.db.char[self.currentPlayerServerSpec].restore.choice.actionBar = key
            --@debug@
            -- print("(ActionBarDropdownOnClick) Selected Action Bar to Restore:", key)
            --@end-debug@
        end
    end)
    self.ui.dropdown.actionBarSelection:SetWidth(200)

    -- position the label and then dropdown
    local dropdownOffset = (self.ui.dropdown.actionBarSelection:GetHeight() - dropdownLabel:GetStringHeight()) / 2
    dropdownLabel:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", padding, -(padding + dropdownOffset))
    self.ui.dropdown.actionBarSelection:SetPoint("LEFT", dropdownLabel, "RIGHT", padding, 0)

    -- add button to trigger restore
    local restoreButton = self:CreateStandardButton(insetFrame, nil, "Restore", 100, function(self, button, down)        
        ABSync:BeginRestore(self)
    end)
    restoreButton:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", 0, -(padding + dropdownOffset))
end

--[[---------------------------------------------------------------------------
    Function:   ProcessBackupFrame
    Purpose:    Create the backup frame for displaying and restoring backups.
-----------------------------------------------------------------------------]]
function ABSync:ProcessBackupFrame(parent, tabKey)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    local backupFrame, existed = self:ProcessTabContentFrame(tabKey, parent)

    -- if frame existed then just return it, no need to recreate content
    if existed then
        backupFrame:Show()
    else
        -- set frame position
        backupFrame:SetAllPoints(parent)

        -- create title for backup frame
        local title = backupFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", backupFrame, "TOPLEFT", padding, -padding)
        title:SetPoint("TOPRIGHT", backupFrame, "TOPRIGHT", -padding, -padding)
        title:SetHeight(30)
        title:SetJustifyH("CENTER")
        title:SetText(ABSync.L["Restore"])

        -- add info label
        local infoFrame = CreateFrame("Frame", nil, backupFrame, "InsetFrameTemplate")
        infoFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
        infoFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
        infoFrame:SetHeight(60)
        local infoLabel = infoFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        infoLabel:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", padding, -padding)
        infoLabel:SetPoint("BOTTOMRIGHT", infoFrame, "BOTTOMRIGHT", -padding, padding)
        infoLabel:SetJustifyH("LEFT")
        infoLabel:SetWordWrap(true)
        infoLabel:SetText(ABSync.L["Backups are stored per character. Select backups by date and time and the action bar (one at a time) to restore. Then click the 'Restore Selected Backup' button."])

        -- adjust info frame to height of label
        infoFrame:SetHeight(infoLabel:GetStringHeight() + (2 * padding) + 10)

        -- get width and cut in half
        local bottomWidth = (backupFrame:GetWidth() - (padding * 0.5)) * 0.5

        -- get left frame name
        local bottomLeftFrameName = self:GetObjectName("BackupListLeftFrame")
        local bottomLeftFrame = nil

        -- see if it already exists
        if _G[bottomLeftFrameName] then
            bottomLeftFrame = _G[bottomLeftFrameName]
        else
            bottomLeftFrame = CreateFrame("Frame", bottomLeftFrameName, backupFrame)
        end

        -- adjust location and width
        bottomLeftFrame:SetPoint("TOPLEFT", infoFrame, "BOTTOMLEFT", 0, -padding)
        bottomLeftFrame:SetPoint("BOTTOMLEFT", backupFrame, "BOTTOMLEFT", 0, 0)
        bottomLeftFrame:SetWidth(bottomWidth)

        -- get right frame name
        local bottomRightFrameName = self:GetObjectName("BackupListRightFrame")
        local bottomRightFrame = nil

        -- see if it already exists
        if _G[bottomRightFrameName] then
            bottomRightFrame = _G[bottomRightFrameName]
        else
            bottomRightFrame = CreateFrame("Frame", bottomRightFrameName, backupFrame)
        end
        
        -- adjust location and width
        bottomRightFrame:SetPoint("TOPRIGHT", infoFrame, "BOTTOMRIGHT", 0, -padding)
        bottomRightFrame:SetPoint("BOTTOMLEFT", bottomLeftFrame, "BOTTOMRIGHT", padding, 0)
        bottomRightFrame:SetPoint("BOTTOMRIGHT", backupFrame, "BOTTOMRIGHT", 0, 0)

        -- add frame content
        local backupSelectContent = self:CreateBackupListFrame(bottomLeftFrame)
        local actionBarSelectContent = self:CreateRestoreFrame(bottomRightFrame)
    end

    -- load content
    self:ProcessBackupListFrame()
end