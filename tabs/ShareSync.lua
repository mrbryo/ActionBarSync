--[[---------------------------------------------------------------------------
    Function:   SyncOnValueChanged
    Purpose:    Sync the action bar state when the checkbox value changes.
-----------------------------------------------------------------------------]]
function ABSync:SyncOnValueChanged(value, barID, playerID)
    -- initialize database if needed
    self:InstantiateDBChar(barID)

    -- update database
    if value == true then
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] = playerID
    else
        ActionBarSyncDB.char[self.currentPlayerServerSpec].barsToSync[barID] = false
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateSyncCheckbox
    Purpose:    Create a checkbox for syncing action bars.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncCheckbox(parent, globalID, barName, playerID, currentPlayerID, padding)
    -- define labels for enabled and disabled states; set barName to green and playerID to orange
    local labelEnabled = ("%s%s|r from |cffffa500%s|r"):format(self.constants.colors.green, barName, playerID)
    -- set whole label to gray
    local labelDisabled = ("%s%s from %s|r"):format(self.constants.colors.gray, barName, playerID)

    -- create the checkbox since not found globally
    local checkbox = self:CreateCheckbox(parent, "-", self:IsSyncSet(barName, playerID), globalID, function(self, button, checked)
        ABSync:SyncOnValueChanged(checked, barName, playerID)
    end)

    -- print(("ProcessSyncCheckbox: playerID: %s, currentPlayerID: %s"):format(playerID, currentPlayerID))
    if playerID == currentPlayerID then
        checkbox.Text:SetText(labelDisabled)
        checkbox:Disable()
    else
        checkbox.Text:SetText(labelEnabled)
        checkbox:Enable()
    end

    return checkbox
end

--[[---------------------------------------------------------------------------
    Function:   RemoveHyphens
    Purpose:    Remove hyphens from a string.
-----------------------------------------------------------------------------]]
function ABSync:RemoveHyphens(text)
    -- remove all hyphens from the text
    return string.gsub(text, "-", "")
end

--[[---------------------------------------------------------------------------
    Function:   GetCheckboxGlobalName
    Purpose:    Get the global name for the sync checkbox based on bar key and player/server/spec.
-----------------------------------------------------------------------------]]
function ABSync:GetCheckboxGlobalName(barID, playerID)
    -- translate the bar key into the variable name friendly action bar name
    local fixedBarName = self.barNameTranslate[barID]

    -- if not found report issue to user
    -- TODO: add to issues in saved variables as well
    if not fixedBarName then
        fixedBarName = "UnknownBarName" .. self:GetRandom6DigitNumber()
        if self:GetDevMode() == true then
            self:Print("(ProcessSyncCheckbox) Failed to Translate Bar Name! Please report as an issue. Using: " .. fixedBarName)
        end
    end

    -- get global name for the checkbox
    return self:GetObjectName("CheckboxSync" .. fixedBarName .. self:RemoveHyphens(playerID))
end

--[[---------------------------------------------------------------------------
    Function:   ProcessSyncRegion
    Purpose:    Process the sync region to add checkboxes for each action bar and character combo that has data.
-----------------------------------------------------------------------------]]
function ABSync:ProcessSyncRegion(callingFunction)
    --@debug@
    -- self:Print(("(%s) called from: %s"):format("ProcessSyncRegion", callingFunction or "Unknown"))
    --@end-debug@
    -- current player ID
    local currentPlayerID = self:GetKeyPlayerServerSpec()

    -- track if anything was added or not
    local objectsTouched = CreateFontStringExamplesFrame
    
    -- track if no checkboxes were added; if none added then show user a message in the frame instead
    local visibleCheckboxes = false

    -- define no shared action bar label unique id
    local noSharedActionBarLabelID = self:GetObjectName("LabelNoSharedActionBars")

    -- track y offset for checkboxes
    local offsetY = 10

    -- standard padding
    local padding = ABSync.constants.ui.generic.padding

    -- only run when the syncContent frame exists
    if self.ui.frame.syncContent then
        -- loop over shared action bars
        for _, barID in ipairs(ABSync.actionBarOrder) do
            -- get the bar name from the key
            local barName = ABSync.barNameLanguageTranslate[barID]

            -- verify bar exists in global.barsToSync
            if ActionBarSyncDB.global.barsToSync[barID] ~= nil then
                -- loop over the barID in global.barsToSync
                for playerID, buttonData in pairs(ActionBarSyncDB.global.barsToSync[barID]) do
                    -- to see if enabled, the buttonData must be a table and have at least 1 record
                    -- count variable
                    local foundData = false
                    
                    -- make sure buttonData is a table
                    if type(buttonData) == "table" then
                        -- next returns the first key in the table or nil if the table is empty
                        if next(buttonData) then
                            foundData = true
                        end
                    end

                    -- get global checkbox variable name
                    local checkboxGlobalID = self:GetCheckboxGlobalName(barID, playerID)

                    -- get length of name
                    local nameLength = string.len(checkboxGlobalID)

                    -- define labels for enabled and disabled states; set barName to green and playerID to orange
                    local labelEnabled = ("%s%s|r from |cffffa500%s|r"):format(self.constants.colors.green, barName, playerID)

                    -- set whole label to gray
                    local labelDisabled = ("%s%s from %s|r"):format(self.constants.colors.gray, barName, playerID)

                    -- create a checkbox if data is found
                    if foundData == true then                    
                        -- track current checkbox
                        local checkbox = {}

                        -- does the checkbox already exist?
                        if _G[checkboxGlobalID] ~= nil then
                            --@debug@
                            -- print(("Checkbox - Reuse: %s (%d)"):format(checkboxGlobalID, nameLength))
                            --@end-debug@
                            checkbox = _G[checkboxGlobalID]
                        else
                            --@debug@
                            -- print(("Checkbox - Create: %s (%d)"):format(checkboxGlobalID, nameLength))
                            --@end-debug@
                            -- checkbox = self:CreateSyncCheckbox(self.ui.frame.syncContent, checkboxGlobalID, barName, playerID, currentPlayerID, padding)
                            
                            -- create the checkbox since not found globally
                            checkbox = self:CreateCheckbox(self.ui.frame.syncContent, "-", self:IsSyncSet(barID, playerID), checkboxGlobalID, function(self, button, checked)
                                ABSync:SyncOnValueChanged(checked, barID, playerID)
                            end)
                        end

                        -- adjust text and checkbox state based on current player and player assigned to the checkbox
                        if playerID == currentPlayerID then
                            checkbox.Text:SetText(labelDisabled)
                            checkbox:Disable()
                        else
                            checkbox.Text:SetText(labelEnabled)
                            checkbox:Enable()
                        end

                        -- update checkbox position
                        checkbox:SetPoint("TOPLEFT", self.ui.frame.syncContent, "TOPLEFT", padding + 5, -offsetY - 5)
                        offsetY = offsetY + checkbox:GetHeight()

                        -- indicate something was added or touched
                        objectsTouched = true

                        -- make checkbox visible if it isn't
                        if not checkbox:IsVisible() then
                            checkbox:Show()
                        end

                        -- indicate at least one checkbox is visible
                        visibleCheckboxes = true

                        -- update value
                        checkbox:SetChecked(self:IsSyncSet(barID, playerID))

                    -- if no data found then remove the checkbox if it exists
                    else
                        -- does the checkbox already exist?
                        if _G[checkboxGlobalID] and _G[checkboxGlobalID]:IsShown() == true then
                            --@debug@
                            -- print(("Checkbox - Remove: %s (%d)"):format(checkboxGlobalID, string.len(checkboxGlobalID)))
                            --@end-debug@
                            _G[checkboxGlobalID]:Hide()
                        end
                    end
                end
            end
        end

        -- if no shared action bars were added, then add a label to indicate that
        local noDataLabel = _G[noSharedActionBarLabelID]
        if visibleCheckboxes == false then
            if not noDataLabel then
                noDataLabel = self.ui.frame.syncContent:CreateFontString(noSharedActionBarLabelID, "ARTWORK", "GameFontHighlight")
                    
                -- position and set text
                noDataLabel:SetPoint("TOPLEFT", self.ui.frame.syncContent, "TOPLEFT", padding + 5, -padding - 5)
                noDataLabel:SetText("No Shared Action Bars Found")
            else
                -- make visible
                if not noDataLabel:IsVisible() then
                    noDataLabel:Show()
                end
            end
        else
            -- hide if checkboxes are visible
            if noDataLabel then
                noDataLabel:Hide()
            end
        end
    else
        --@debug@
        if self:GetDevMode() == true then
            self:Print(("(%s) self.ui.frame.syncContent does not exist, cannot process sync region."):format("ProcessSyncRegion"))
        end
        --@end-debug@
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
    self.ui.frame.syncContent = CreateFrame("Frame", nil, scrollContainer)
    self.ui.frame.syncContent:SetWidth(scrollContainer:GetWidth() - padding)
    self.ui.frame.syncContent:SetHeight(scrollContainer:GetHeight() - padding)
    --@debug@
    -- print("(CreateSyncFromFrameContent) self.ui.frame.syncContent Height: " .. tostring(self.ui.frame.syncContent:GetHeight()))
    --@end-debug@
    scrollContainer:SetScrollChild(self.ui.frame.syncContent)

    -- load checkboxes
    self:ProcessSyncRegion("CreateSyncFromFrameContent")

    -- --@debug@
    -- -- for adding 20 rows of fake data
    -- for i = 1, 20 do
    --     scrollFrame:AddChild(self:ProcessSyncCheckbox(("Test Bar %d"):format(i), "Test Player"))
    -- end
    -- --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   ProcessShareCheckboxes
    Purpose:    Create checkboxes for each action bar to select which action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:ProcessShareCheckboxes(callingFunction)
    -- for debugging
    local funcName = "ProcessShareCheckboxes"
    --@debug@
    -- notify of function call
    if self:GetDevMode() == true then
        self:Print(("(%s) called from: %s"):format(funcName, callingFunction or "Unknown"))
    end
    --@end-debug@

    -- track y offset
    local offsetY = 10

    -- set the parent
    local parent = ActionBarSyncShareScrollContent
    
    -- loop over the action bars and create a checkbox for each one
    for _, checkboxID in pairs(ABSync.actionBarOrder) do
        --@debug@
        -- print(("(%s) Processing checkboxID: %s"):format(funcName, tostring(checkboxID)))
        --@end-debug@
        -- get variable friendly name for the action bar
        local varName = self.barNameTranslate[checkboxID]
        
        -- get the checkbox name
        local checkboxName = self.barNameLanguageTranslate[checkboxID]

        -- create a checkbox for each action bar
        local checkboxFrameID = self:GetObjectName(ABSync.constants.objectNames.shareCheckboxes .. varName)
        
        -- instantiate variable to hold checkbox
        local checkBox = nil

        -- see if it exists already
        if _G[checkboxFrameID] ~= nil then
            --@debug@
            -- print(("(%s) Reusing existing checkbox for '%s' with ID '%s'"):format(funcName, checkboxName, checkboxFrameID))
            --@end-debug@
            -- associate existing checkbox
            checkBox = _G[checkboxFrameID]

            -- update the checked state
            checkBox:SetChecked(self:GetBarToShare(checkboxName, self.currentPlayerServerSpec))
        else
            checkBox = self:CreateCheckbox(parent, checkboxName, self:GetBarToShare(checkboxID, self.currentPlayerServerSpec), checkboxFrameID, function(self, button, checked)
                ABSync:ShareBar(checkboxID, checked, checkBox)
            end)
        end

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
    local scrollContent = CreateFrame("Frame", "ActionBarSyncShareScrollContent", scrollContainer)
    scrollContent:SetWidth(scrollContainer:GetWidth() - padding)
    scrollContent:SetHeight(scrollContainer:GetHeight() - padding)
    --@debug@
    -- print("(CreateShareFrameContent) scrollContent Height: " .. tostring(scrollContent:GetHeight()))
    --@end-debug@
    scrollContainer:SetScrollChild(scrollContent)

    -- initial add of checkboxes
    self:ProcessShareCheckboxes("CreateShareFrameContent")
end

--[[---------------------------------------------------------------------------
    Function:   UpdateLastScanLabel
    Purpose:    Update the last scan label with the latest scan date/time.
-----------------------------------------------------------------------------]]
function ABSync:UpdateLastScanLabel()
    local lastScan = self:GetLastScan()
    local formatString = self:FormatDateString(lastScan)
    --@debug@
    -- print("UpdateLastScanLabel Value: " .. formatString)
    --@end-debug@
    if self.ui.label.lastScan then
        self.ui.label.lastScan:SetText(formatString)
    end
end

--[[---------------------------------------------------------------------------
    Function:   UpdateLastSyncLabel
    Purpose:    Update the last sync label with the latest sync date/time.
-----------------------------------------------------------------------------]]
function ABSync:UpdateLastSyncLabel()
    if not self.ui.label.lastSync then
        return
    end
    self.ui.label.lastSync:SetText(self:FormatDateString(self:GetLastSynced()))
end

--[[---------------------------------------------------------------------------
    Function:   UpdateCheckboxState
    Purpose:    Update the checkbox state to enabled or disabled and change text color.
-----------------------------------------------------------------------------]]
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
    -- set language variable
    local L = self.L
    
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
    lastScanTitle:SetText(("%s%s:|r"):format(ABSync.constants.colors.orange, ABSync.L["Last Scan on this Character"]))
    contentHeight = contentHeight + lastScanTitle:GetHeight() + offsetY + buttonOffset

    -- last scan date/time label
    self.ui.label.lastScan = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.lastScan:SetPoint("TOPLEFT", lastScanTitle, "TOPRIGHT", padding, 0)
    self.ui.label.lastScan:SetJustifyH("LEFT")
    self:UpdateLastScanLabel()

    -- set minimum width for last scan label
    local lastScanWidth = (self.ui.label.lastScan:GetWidth() > 140) and self.ui.label.lastScan:GetWidth() or 140
    self.ui.label.lastScan:SetWidth(lastScanWidth)

    -- scan button
    local scanButton = self:CreateStandardButton(regionContent, nil, "Scan Now", 100, function(self, button, down)
        ABSync:UpdateCheckboxState(self, false) -- disable button while scanning
        ABSync:GetActionBarData()
        ABSync:ProcessSyncRegion("CreateShareSyncTopFrameContent:ScanButton")
        ABSync:UpdateCheckboxState(self, true) -- re-enable button after scan is complete
    end)
    scanButton:SetPoint("LEFT", self.ui.label.lastScan, "RIGHT", padding, 0)

    -- last sync date/time title
    local lastSyncTitle = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lastSyncTitle:SetPoint("TOPLEFT", lastScanTitle, "BOTTOMLEFT", 0, -offsetY + -buttonOffset)
    lastSyncTitle:SetJustifyH("LEFT")
    lastSyncTitle:SetText(("%s%s:|r"):format(ABSync.constants.colors.orange, ABSync.L["Last Sync on this Character"]))
    contentHeight = contentHeight + lastSyncTitle:GetHeight() + offsetY + buttonOffset

    -- last sync date/time label
    self.ui.label.lastSync = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.lastSync:SetPoint("TOPLEFT", lastSyncTitle, "TOPRIGHT", padding, 0)
    self.ui.label.lastSync:SetJustifyH("LEFT")
    self:UpdateLastSyncLabel()

    -- create button for manual sync
    local manualSyncButton = self:CreateStandardButton(regionContent, nil, "Sync Now", 100, function()
        self:BeginSync()
    end)
    manualSyncButton:SetPoint("LEFT", self.ui.label.lastSync, "RIGHT", padding, 0)
    manualSyncButton:SetPoint("TOPLEFT", scanButton, "BOTTOMLEFT", 0, -buttonOffset)

    -- create button for manual mount filter reset
    local manualMountFilterResetButton = self:CreateStandardButton(regionContent, nil, "Reset Mount Filters", 160, function()
        self:MountJournalFilterReset()
    end)
    manualMountFilterResetButton:SetPoint("TOPLEFT", manualSyncButton, "TOPRIGHT", padding, 0)
    
    -- create checkbox for auto mount journal filter reset; must create prior to loginCheckBox so it can be called in the OnValueChanged
    self.ui.checkbox.autoMountFilterReset = self:CreateCheckbox(regionContent, "Automatically Reset Mount Journal Filters", ABSync:GetAutoResetMountFilters(), nil, function(self, button, checked)
        ABSync:SetAutoResetMountFilters(checked)
    end)
    -- self:UpdateCheckboxState(self.ui.checkbox.autoMountFilterReset, ABSync:GetSyncOnLogon())

    -- create checkbox for sync on login
    local loginCheckBox = self:CreateCheckbox(regionContent, "Enable Sync on Login (no backups occur)", ABSync:GetSyncOnLogon(), nil, function(self, button, checked)
        ABSync:SetSyncOnLogon(checked)
        -- self:UpdateCheckboxState(self.ui.checkbox.autoMountFilterReset, checked)
    end)
    loginCheckBox:SetPoint("TOPLEFT", lastSyncTitle, "BOTTOMLEFT", 0, -offsetY)
    contentHeight = contentHeight + loginCheckBox:GetHeight() + offsetY

    -- set the autoMountFilterReset checkbox to the right of the loginCheckBox
    self.ui.checkbox.autoMountFilterReset:SetPoint("TOPLEFT", loginCheckBox, "TOPRIGHT", self:GetCheckboxOffsetY(loginCheckBox), 0)

    -- create checkbox for removing action button if there is an error in placing the new one
    self.ui.checkbox.removeActionButtonOnError = self:CreateCheckbox(regionContent, "On Placement Failure Remove Current Action Button", ABSync:GetPlacementErrorClearButton(), nil, function(self, button, checked)
        print("SetPlacementErrorClearButton: " .. tostring(checked))
        ABSync:SetPlacementErrorClearButton(checked)
    end)
    self.ui.checkbox.removeActionButtonOnError:SetPoint("TOPLEFT", loginCheckBox, "BOTTOMLEFT", 0, 0)
    contentHeight = contentHeight + self.ui.checkbox.removeActionButtonOnError:GetHeight()

    -- add in offsetY for padding below last item
    contentHeight = contentHeight + offsetY

    -- return info
    return {
        height = contentHeight,
    }
end

--[[---------------------------------------------------------------------------
    Function:   ProcessShareSyncFrame
    Purpose:    Create the share frame for selecting action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:ProcessShareSyncFrame(parent, tabKey)
    -- for debugging
    local funcName = "ProcessShareSyncFrame"

    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    local mainShareFrame, existed = self:ProcessTabContentFrame(tabKey, parent)

    -- if frame existed then just return it, no need to recreate content
    if existed then
        return mainShareFrame
    end

    -- set frame position
    mainShareFrame:SetAllPoints(parent)

    -- create title for share frame
    local title = mainShareFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainShareFrame, "TOPLEFT", padding, -padding)
    title:SetPoint("TOPRIGHT", mainShareFrame, "TOPRIGHT", -padding, -padding)
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