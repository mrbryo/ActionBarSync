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
            local itemOrder = ABSync.actionBarOrder
            local selectedItem = self:GetRestoreChoiceActionBar()

            -- loop over the action bars in the backup record and create a checkbox for each one
            for actionBarName, _ in pairs(backupRow.data) do
                newData[actionBarName] = actionBarName
                dataAdded = true
                print("Found Action Bar in Backup: " .. actionBarName)
            end

            -- if no data added then apply default value
            if not dataAdded then
                newData = {["none"] = "No Action Bars Backed Up"}
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
        self:ClearBackupActionBarDropdow()
    end
end

--[[---------------------------------------------------------------------------
    Function:   ClearActionBarDropDown
    Purpose:    Clear the action bar selection dropdown and reset to a single "None" value.
-----------------------------------------------------------------------------]]
function ABSync:ClearActionBarDropDown()
    local items = {["none"] = "No Action Bars Found"}
    local itemOrder = {"none"}
    self.ui.dropdown.actionBarSelection:UpdateItems(itemOrder, items, "none")
end

--[[---------------------------------------------------------------------------
    Function:   LoadBackups
    Purpose:    Load the checkboxes for available backups into the scroll frame.
-----------------------------------------------------------------------------]]
function ABSync:LoadBackups()
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- add the available backups
    local trackInserts = 0
    local offsetY = 5
    for _, backupRow in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].backup) do
        -- check for selected value
        local isChecked = false
        if ActionBarSyncDB.char[self.currentPlayerServerSpec].restore.choice.backupDttm == backupRow.dttm then
            -- set the new checkbox to be checked since the dttm values match
            isChecked = true

            -- load the drop down with the action bars for this backup
            self:LoadBackupActionBars(self.ui.scroll.backups, backupRow.dttm)
        end

        -- create a checkbox for each backup
        local checkbox = self:CreateCheckbox(self.ui.scroll.backups, self:FormatDateString(backupRow.dttm), isChecked, self:GetObjectName("CheckboxBackup" .. backupRow.dttm), function(self, button, value)
            -- clear all other checkboxes
            ABSync:UncheckAllChildCheckboxes(ABSync.ui.scroll.backups, self)
            
            -- if checked, load the action bars for this backup into the action bar selection scroll region
            if value == true then
                -- track choice by character
                ABSync:SetRestoreChoiceDateTime(backupRow.dttm)

                -- update the drop down with action bars for this backup
                ABSync:LoadBackupActionBars(ABSync.ui.scroll.backups, backupRow.dttm)
            else
                -- blank out selected backup
                ABSync:SetRestoreChoiceDateTime(ABSync.L["None"])
                ABSync:SetRestoreChoiceActionBar(ABSync.L["None"])

                -- clear dropdown and choice
                ABSync:ClearActionBarDropDown()
            end
        end)
        checkbox:SetPoint("TOPLEFT", self.ui.scroll.backups, "TOPLEFT", 5, -offsetY)

        -- add description below
        local noteLabel = self.ui.scroll.backups:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        noteLabel:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 20, 0)
        noteLabel:SetPoint("RIGHT", self.ui.scroll.backups, "RIGHT", -5, 0)
        noteLabel:SetJustifyH("LEFT")
        noteLabel:SetText(backupRow.note or "No Description")
        noteLabel:SetWordWrap(false)

        -- checkbox:SetDescription(backupRow.note)
        trackInserts = trackInserts + 1
        offsetY = offsetY + checkbox:GetHeight() + noteLabel:GetStringHeight() + padding
    end

    -- final adjustment to content height
    self.ui.scroll.backups:SetHeight(offsetY)

    -- insert empty records if no records inserted
    if trackInserts == 0 then
        local noDataLabel = self.ui.scroll.backups:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        noDataLabel:SetPoint("TOPLEFT", self.ui.scroll.backups, "TOPLEFT", 5, -5)
        noDataLabel:SetPoint("RIGHT", self.ui.scroll.backups, "RIGHT", 0, 0)
        noDataLabel:SetJustifyH("LEFT")
        noDataLabel:SetText("No Backups Found")
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
    regionLabel:SetText("Backups Available:")

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("TOPRIGHT", regionLabel, "BOTTOMRIGHT", 0, 0)
    insetFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

    -- create a scroll container for the spreadsheet
    local scrollContainer = CreateFrame("ScrollFrame", nil, insetFrame, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", 5, -5)
    scrollContainer:SetPoint("BOTTOMRIGHT", insetFrame, "BOTTOMRIGHT", -27, 5)

    -- create scroll content frame
    self.ui.scroll.backups = CreateFrame("Frame", nil, scrollContainer)
    self.ui.scroll.backups:SetWidth(scrollContainer:GetWidth() - padding)
    self.ui.scroll.backups:SetHeight(scrollContainer:GetHeight() - padding)
    scrollContainer:SetScrollChild(self.ui.scroll.backups)
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
    regionLabel:SetText("Restore one Action Bar per Click:")

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("TOPRIGHT", regionLabel, "BOTTOMRIGHT", 0, 0)
    insetFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

    -- label for dropdown
    local dropdownLabel = insetFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText("Select Action Bar to Restore:")

    -- create drop down based on selected backup, initially it will have a fake value
    local items = {["none"] = "No Backups Selected"}
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
        return backupFrame
    end

    -- set frame position
    backupFrame:SetAllPoints(parent)

    -- create title for backup frame
    local title = backupFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", backupFrame, "TOPLEFT", padding, -padding)
    title:SetPoint("TOPRIGHT", backupFrame, "TOPRIGHT", -padding, -padding)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText("Backup and Restore")

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
    infoLabel:SetText("Backups are stored per character. Select backups by date and time and the action bar (one at a time) to restore. Then click the 'Restore Selected Backup' button.")

    -- adjust info frame to height of label
    infoFrame:SetHeight(infoLabel:GetStringHeight() + (2 * padding) + 10)

    -- get width and cut in half
    local bottomWidth = (backupFrame:GetWidth() - (padding * 0.5)) * 0.5

    -- create frame for backup listing
    local bottomLeftFrame = CreateFrame("Frame", nil, backupFrame)
    bottomLeftFrame:SetPoint("TOPLEFT", infoFrame, "BOTTOMLEFT", 0, -padding)
    bottomLeftFrame:SetPoint("BOTTOMLEFT", backupFrame, "BOTTOMLEFT", 0, 0)
    bottomLeftFrame:SetWidth(bottomWidth)

    -- create frame for action bar selection
    local bottomRightFrame = CreateFrame("Frame", nil, backupFrame)
    bottomRightFrame:SetPoint("TOPRIGHT", infoFrame, "BOTTOMRIGHT", 0, -padding)
    bottomRightFrame:SetPoint("BOTTOMLEFT", bottomLeftFrame, "BOTTOMRIGHT", padding, 0)
    bottomRightFrame:SetPoint("BOTTOMRIGHT", backupFrame, "BOTTOMRIGHT", 0, 0)

    -- add frame content
    local backupSelectContent = self:CreateBackupListFrame(bottomLeftFrame)
    local actionBarSelectContent = self:CreateRestoreFrame(bottomRightFrame)

    -- load content
    self:LoadBackups()
end