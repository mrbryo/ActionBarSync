--[[---------------------------------------------------------------------------
    Function:   SyncOnValueChanged
    Purpose:    Sync the action bar state when the checkbox value changes.
-----------------------------------------------------------------------------]]
function ABSync:SyncOnValueChanged(value, barName, playerID)
    if value == true then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barName] = playerID
    else
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barName] = false
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateSyncCheckbox
    Purpose:    Create a checkbox for syncing action bars.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncCheckbox(parent, barName, playerID, currentPlayerID, padding, offsetY)
    -- set barName to green and playerID to orange
    local label = self.constants.colors.green .. barName .. "|r from |cffffa500" .. playerID .. "|r"

    -- change color to all gray because syncing to yourself as same spec is not allowed
    if playerID == currentPlayerID then
        label = ("%s%s from %s|r"):format(self.constants.colors.gray, barName, playerID)
    end

    -- create a checkbox
    local checkbox = self:CreateCheckbox(parent, label, self:GetBarToSync(barName, playerID), function(self, button, checked)
        ABSync:SyncOnValueChanged(checked, barName, playerID)
    end)

    -- print(("CreateSyncCheckbox: playerID: %s, currentPlayerID: %s"):format(playerID, currentPlayerID))
    if playerID == currentPlayerID then
        checkbox:Disable()
    end
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", padding + 5, -offsetY - 5)

    return checkbox
end

--[[---------------------------------------------------------------------------
    Function:   UpdateShareRegion
    Purpose:    Update the share region with checkboxes for each action bar and character combo that has data.
-----------------------------------------------------------------------------]]
function ABSync:UpdateShareRegion()
    -- only run when the shareContent frame exists
    if self.ui.frame.shareContent then
        -- current player ID
        local currentPlayerID = self:GetKeyPlayerServerSpec()

        -- loop over data and add checkboxes per character and action bar combo where they are enabled
        -- track if anything was added or not
        local sharedActionBarsAdded = false

        -- track y offset for checkboxes
        local offsetY = 10

        -- standard padding
        local padding = ABSync.constants.ui.generic.padding

        -- remove all existing children from the shareContent frame
        self:RemoveFrameChildren(self.ui.frame.shareContent)

        -- primary loop is actionBars as it's sorted
        if ActionBarSyncDB.global.actionBars ~= nil then
            for _, barName in ipairs(ActionBarSyncDB.global.actionBars) do
                -- verify bar exists in global.barsToSync
                if ActionBarSyncDB.global.barsToSync[barName] ~= nil then
                    -- loop over the barName in global.barsToSync
                    for playerID, buttonData in pairs(ActionBarSyncDB.global.barsToSync[barName]) do
                        -- to see if enabled the buttonData must be a table and have at least 1 record
                        -- count variable
                        local foundData = false
                        
                        -- make sure buttonData is a table
                        if type(buttonData) == "table" then
                            -- next returns the first key in the table or nil if the table is empty
                            if next(buttonData) then
                                foundData = true
                            end
                        end

                        -- create a checkbox if data is found
                        if foundData == true then
                            local checkbox = self:CreateSyncCheckbox(self.ui.frame.shareContent, barName, playerID, currentPlayerID, padding, offsetY)
                            sharedActionBarsAdded = true
                            offsetY = offsetY + checkbox:GetHeight()
                        end
                    end
                end
            end
        end

        -- if no shared action bars were added, then add a label to indicate that
        if sharedActionBarsAdded == false then
            local noDataLabel = self.ui.frame.shareContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            noDataLabel:SetPoint("TOPLEFT", self.ui.frame.shareContent, "TOPLEFT", padding + 5, -padding - 5)
            noDataLabel:SetText("No Shared Action Bars Found")
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateSyncFromFrameContent
    Purpose:    Create the sync from frame for selecting action bars to sync from other characters.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncFromFrameContent(parent)
    -- standard padding
    local padding = ABSync.constants.ui.generic.padding

    -- add label for sync frame
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText("Sync Action Bars From:")

    -- create inset frame for syncing from other characters
    local insetFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("TOPRIGHT", regionLabel, "BOTTOMRIGHT", 0, 0)
    insetFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

    -- create frame for listing who can be synced from and their bars
    local scrollContainer = CreateFrame("ScrollFrame", nil, insetFrame, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", 5, -5)
    scrollContainer:SetPoint("BOTTOMRIGHT", insetFrame, "BOTTOMRIGHT", -27, 5)
    
    -- create scroll content frame
    self.ui.frame.shareContent = CreateFrame("Frame", nil, scrollContainer)
    self.ui.frame.shareContent:SetWidth(scrollContainer:GetWidth() - padding)
    self.ui.frame.shareContent:SetHeight(scrollContainer:GetHeight() - padding)
    scrollContainer:SetScrollChild(self.ui.frame.shareContent)

    -- load checkboxes
    self:UpdateShareRegion()

    -- --@debug@
    -- -- for adding 20 rows of fake data
    -- for i = 1, 20 do
    --     scrollFrame:AddChild(self:CreateSyncCheckbox(("Test Bar %d"):format(i), "Test Player"))
    -- end
    -- --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareCheckboxes
    Purpose:    Create checkboxes for each action bar to select which action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareCheckboxes(parent)
    -- for debugging
    local funcName = "CreateShareCheckboxes"

    -- get the player ID for the current profile
    local playerID = self:GetKeyPlayerServerSpec()

    -- get action bar names
    local actionBars = ABSync:GetBarNames()

    -- track y offset
    local offsetY = 10
    
    -- loop over the action bars and create a checkbox for each one
    for _, checkboxName in pairs(actionBars) do
        -- create a checkbox for each action bar
        local checkBox = self:CreateCheckbox(parent, checkboxName, self:GetBarToShare(checkboxName, playerID), function(self, button, checked)
            ABSync:ShareBar(checkboxName, checked)
        end)

        -- position the checkbox
        checkBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -offsetY - 5)
        offsetY = offsetY + (checkBox:GetHeight())
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareFrameContent
    Purpose:    Create the share frame for selecting action bars to share. This is the "Scan" 
                label with an inset frame and scroll area with checkboxes for each action bar
                for the current user to share or not.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareFrameContent(parent)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- title
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText("Select Action Bars to Share:")

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("TOPRIGHT", regionLabel, "BOTTOMRIGHT", 0, 0)
    insetFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)

    -- create scroll frame
    local scrollContainer = CreateFrame("ScrollFrame", nil, insetFrame, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", 5, -5)
    scrollContainer:SetPoint("BOTTOMRIGHT", insetFrame, "BOTTOMRIGHT", -27, 5)

    -- create scroll content frame
    local scrollContent = CreateFrame("Frame", nil, scrollContainer)
    scrollContent:SetWidth(scrollContainer:GetWidth() - padding)
    scrollContent:SetHeight(scrollContainer:GetHeight() - padding)
    scrollContainer:SetScrollChild(scrollContent)

    -- initial add of checkboxes
    self:CreateShareCheckboxes(scrollContent)
end

--[[---------------------------------------------------------------------------
    Function:   UpdateLastScanLabel
    Purpose:    Update the last scan label with the latest scan date/time.
-----------------------------------------------------------------------------]]
function ABSync:UpdateLastScanLabel()
    self.ui.label.lastScan:SetText(self:FormatDateString(ActionBarSyncDB.char[self.currentPlayerServerSpec].lastScan))
end

--[[---------------------------------------------------------------------------
    Function:   UpdateLastSyncLabel
    Purpose:    Update the last sync label with the latest sync date/time.
-----------------------------------------------------------------------------]]
function ABSync:UpdateLastSyncLabel()
    self.ui.label.lastSync:SetText(self:FormatDateString(self:GetLastSyncedOnChar()))
end

function ABSync:UpdateCheckboxState(checkbox, checked)
    if checked == true then
        checkbox:Enable()
        checkbox.Text:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    else
        checkbox:Disable()
        checkbox.Text:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareSyncTopFrameContent
    Purpose:    Create the Scan frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareSyncTopFrameContent(parent)
    -- get language data
    local L = self.localeData
    
    -- debugging
    local funcName = "CreateShareSyncTopFrameContent"

    -- add additional y offset to add spacing below the portrait art
    local offsetY = 10
    local buttonOffset = 5
    local padding = ABSync.constants.ui.generic.padding

    -- track content size
    local contentHeight = 0

    -- add inset frame
    local regionContent = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    regionContent:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionContent:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- last scan title
    local lastScanTitle = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lastScanTitle:SetPoint("TOPLEFT", regionContent, "TOPLEFT", padding, -offsetY + -buttonOffset)
    lastScanTitle:SetJustifyH("LEFT")
    lastScanTitle:SetText(("%s%s:|r"):format(ABSync.constants.colors.orange, L["Last Scan on this Character"]))
    contentHeight = contentHeight + lastScanTitle:GetHeight() + offsetY + buttonOffset

    -- last scan date/time label
    self.ui.label.lastScan = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.lastScan:SetPoint("TOPLEFT", lastScanTitle, "TOPRIGHT", padding, 0)
    self.ui.label.lastScan:SetJustifyH("LEFT")
    self:UpdateLastScanLabel()

    -- scan button
    local scanButton = self:CreateStandardButton(regionContent, "Scan Now", 100, function(self, button, down)
        ABSync:UpdateCheckboxState(self, false) -- disable button while scanning
        ABSync:GetActionBarData()
        ABSync:UpdateLastScanLabel()
        ABSync:UpdateShareRegion()
        ABSync:UpdateCheckboxState(self, true) -- re-enable button after scan is complete
    end)
    scanButton:SetPoint("LEFT", self.ui.label.lastScan, "RIGHT", padding, 0)

    -- last sync date/time title
    local lastSyncTitle = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lastSyncTitle:SetPoint("TOPLEFT", lastScanTitle, "BOTTOMLEFT", 0, -offsetY + -buttonOffset)
    lastSyncTitle:SetJustifyH("LEFT")
    lastSyncTitle:SetText(("%s%s:|r"):format(ABSync.constants.colors.orange, L["Last Sync on this Character"]))
    contentHeight = contentHeight + lastSyncTitle:GetHeight() + offsetY + buttonOffset

    -- last sync date/time label
    self.ui.label.lastSync = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.lastSync:SetPoint("TOPLEFT", lastSyncTitle, "TOPRIGHT", padding, 0)
    self.ui.label.lastSync:SetJustifyH("LEFT")
    self:UpdateLastSyncLabel()

    -- create button for manual sync
    local manualSyncButton = self:CreateStandardButton(regionContent, "Sync Now", 100, function()
        self:BeginSync()
    end)
    manualSyncButton:SetPoint("LEFT", self.ui.label.lastSync, "RIGHT", padding, 0)
    manualSyncButton:SetPoint("TOPLEFT", scanButton, "BOTTOMLEFT", 0, -buttonOffset)

    -- create button for manual mount filter reset
    local manualMountFilterResetButton = self:CreateStandardButton(regionContent, "Reset Mount Filters", 160, function()
        self:MountJournalFilterReset()
    end)
    manualMountFilterResetButton:SetPoint("TOPLEFT", manualSyncButton, "TOPRIGHT", padding, 0)
    
    -- create checkbox for auto mount journal filter reset; must create prior to loginCheckBox so it can be called in the OnValueChanged
    self.ui.checkbox.autoMountFilterReset = self:CreateCheckbox(regionContent, "Automatically Reset Mount Journal Filters", ActionBarSyncDB.profile.autoResetMountFilters, function(checked)
        ABSync.db.profile.autoResetMountFilters = checked
    end)
    self:UpdateCheckboxState(self.ui.checkbox.autoMountFilterReset, ActionBarSyncDB.profile.checkOnLogon)

    -- create checkbox for sync on login
    local loginCheckBox = self:CreateCheckbox(regionContent, "Enable Sync on Login", ActionBarSyncDB.profile.checkOnLogon, function(checked)
        ABSync.db.profile.checkOnLogon = checked
        self:UpdateCheckboxState(self.ui.checkbox.autoMountFilterReset, checked)
    end)
    loginCheckBox:SetPoint("TOPLEFT", lastSyncTitle, "BOTTOMLEFT", 0, -offsetY)
    contentHeight = contentHeight + loginCheckBox:GetHeight() + offsetY

    -- set the autoMountFilterReset checkbox to the right of the loginCheckBox
    self.ui.checkbox.autoMountFilterReset:SetPoint("TOPLEFT", loginCheckBox, "TOPRIGHT", self:GetCheckboxOffsetY(loginCheckBox), 0)

    -- add in offsetY for padding below last item
    contentHeight = contentHeight + offsetY

    -- return info
    return {
        height = contentHeight,
    }
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareSyncFrame
    Purpose:    Create the share frame for selecting action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareSyncFrame(parent)
    -- for debugging
    local funcName = "CreateShareSyncFrame"

    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create main frame
    local mainShareFrame = CreateFrame("Frame", nil, parent)
    mainShareFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
    mainShareFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, 0)

    -- create title for share frame
    local title = mainShareFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainShareFrame, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", mainShareFrame, "TOPRIGHT", 0, 0)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText("Share & Sync")

    -- create main content frame
    local mainContentFrame = CreateFrame("Frame", nil, mainShareFrame)
    mainContentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMLEFT", mainShareFrame, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMRIGHT", mainShareFrame, "BOTTOMRIGHT", 0, 0)

    -- calculate bottom width for left and right frames
    local bottomWidth = (mainContentFrame:GetWidth() - (padding * 0.5)) * 0.5

    -- create each frame attached to mainContentFrame
    local topFrame = CreateFrame("Frame", nil, mainShareFrame)
    local bottomLeftFrame = CreateFrame("Frame", nil, mainShareFrame)
    local bottomRightFrame = CreateFrame("Frame", nil, mainShareFrame)

    -- attach all points for topFrame
    topFrame:SetPoint("TOPLEFT", mainContentFrame, "TOPLEFT", 0, 0)
    topFrame:SetPoint("TOPRIGHT", mainContentFrame, "TOPRIGHT", 0, 0)

    -- create the share frame; bottom left region
    bottomLeftFrame:SetPoint("TOPLEFT", topFrame, "BOTTOMLEFT", 0, -padding)
    bottomLeftFrame:SetPoint("BOTTOMLEFT", mainContentFrame, "BOTTOMLEFT", 0, 0)
    bottomLeftFrame:SetWidth(bottomWidth)

    -- create the sync from frame; bottom right region
    bottomRightFrame:SetPoint("TOPRIGHT", topFrame, "BOTTOMRIGHT", 0, -padding)
    bottomRightFrame:SetPoint("BOTTOMLEFT", bottomLeftFrame, "BOTTOMRIGHT", padding, 0)
    bottomRightFrame:SetPoint("BOTTOMRIGHT", mainContentFrame, "BOTTOMRIGHT", 0, 0)
    -- bottomRightFrame:SetWidth(bottomWidth)

    -- add in frame content
    local scanShareContent = self:CreateShareSyncTopFrameContent(topFrame)
    local shareContent = self:CreateShareFrameContent(bottomLeftFrame)
    local syncFromContent = self:CreateSyncFromFrameContent(bottomRightFrame)

    -- set the sizes of each frame based on content
    topFrame:SetHeight(scanShareContent.height)

    -- finally return the frame
    return mainShareFrame
end