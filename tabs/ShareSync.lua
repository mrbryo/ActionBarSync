--[[---------------------------------------------------------------------------
    Function:   CreateSyncFromFrameContent
    Purpose:    Create the sync from frame for selecting action bars to sync from other characters.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncFromFrameContent(parent, padding)
    -- current player ID
    local currentPlayerID = self:GetPlayerNameKey()

    -- add label for sync frame
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText("Sync From")

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
    local scrollContent = CreateFrame("Frame", nil, scrollContainer)
    scrollContent:SetWidth(scrollContainer:GetWidth() - 20)
    scrollContent:SetHeight(scrollContainer:GetHeight() - 10)
    scrollContainer:SetScrollChild(scrollContent)

    -- loop over data and add checkboxes per character and action bar combo where they are enabled
    -- track if anything was added or not
    local sharedActionBarsAdded = false

    -- track y offset for checkboxes
    local offsetY = 10

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
                    self:CreateSyncCheckbox(scrollContent, barName, playerID, currentPlayerID, padding, offsetY)
                    sharedActionBarsAdded = true
                    offsetY = offsetY + padding + self.constants.ui.checkbox.size
                end
            end
        end
    end

    -- if no shared action bars were added, then add a label to indicate that
    if sharedActionBarsAdded == false then
        local noDataLabel = scrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        noDataLabel:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", padding, -padding)
        noDataLabel:SetText("No Shared Action Bars Found")
    end

    -- --@debug@
    -- -- for adding 20 rows of fake data
    -- for i = 1, 20 do
    --     scrollFrame:AddChild(self:CreateSyncCheckbox(("Test Bar %d"):format(i), "Test Player"))
    -- end
    -- --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareFrameContent
    Purpose:    Create the share frame for selecting action bars to share. This is the "Scan" label with an inset frame and scroll area with checkboxes for each action bar
                for the current user to share or not.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareFrameContent(parent, padding)
    -- title
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText("Share")

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
    scrollContent:SetWidth(scrollContainer:GetWidth() - 20)
    scrollContent:SetHeight(scrollContainer:GetHeight() - 10)
    scrollContainer:SetScrollChild(scrollContent)

    -- initial add of checkboxes
    self:CreateShareCheckboxes(scrollContent)
end

--[[---------------------------------------------------------------------------
    Function:   CreateSyncFrame
    Purpose:    Create the sync frame for selecting action bars to sync.
-----------------------------------------------------------------------------]]
function ABSync:CreateSyncFrameContent(parent, padding)
    -- get language data
    local L = self.localeData

    -- current player ID
    local currentPlayerID = self:GetPlayerNameKey()

    -- add additional y offset to match scan frame in (CreateScanFrameContent)
    local offsetY = 10

    -- track content height
    local contentHeight = 0

    -- add label
    local syncTitle = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    syncTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    syncTitle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    syncTitle:SetJustifyH("LEFT")
    syncTitle:SetText("Sync")
    contentHeight = contentHeight + syncTitle:GetHeight()

    -- add inset frame
    local syncFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    syncFrame:SetPoint("TOPLEFT", syncTitle, "BOTTOMLEFT", 0, 0)
    syncFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- create checkbox for auto mount journal filter reset; must create prior to loginCheckBox so it can be called in the OnValueChanged
    local autoMountFilterReset = self:CreateCheckbox(syncFrame, "Automatically Reset Mount Journal Filters", self.db.profile.autoResetMountFilters, function(checked)
        ABSync.db.profile.autoResetMountFilters = checked
    end)
    autoMountFilterReset:Disable(self.db.profile.checkOnLogon == false)

    -- create checkbox for sync on login
    local loginCheckBox = self:CreateCheckbox(syncFrame, "Enable Sync on Login", self.db.profile.checkOnLogon, function(checked)
        ABSync.db.profile.checkOnLogon = checked
        if checked == true then
            autoMountFilterReset:Disable(false)
        else
            autoMountFilterReset:Disable(true)
        end
    end)
    loginCheckBox:SetPoint("TOPLEFT", syncFrame, "TOPLEFT", padding, -offsetY)

    -- set the autoMountFilterReset checkbox to the right of the loginCheckBox
    autoMountFilterReset:SetPoint("TOPLEFT", loginCheckBox, "TOPRIGHT", self:GetCheckboxOffsetY(loginCheckBox), 0)

    -- create button for manual sync
    local manualSyncButton = self:CreateStandardButton(syncFrame, "Sync Now", 100, function()
        self:BeginSync()
    end)
    manualSyncButton:SetPoint("TOPLEFT", loginCheckBox, "BOTTOMLEFT", 0, -offsetY)

    -- create button for manual mount filter reset
    local manualMountFilterResetButton = self:CreateStandardButton(syncFrame, "Reset Mount Filters", 160, function()
        self:MountJournalFilterReset()
    end)
    manualMountFilterResetButton:SetPoint("TOPLEFT", manualSyncButton, "TOPRIGHT", padding, 0)
end

--[[---------------------------------------------------------------------------
    Function:   CreateScanFrameContent
    Purpose:    Create the Scan frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateScanFrameContent(parent, padding)
    -- get language data
    local L = self.localeData
    
    -- debugging
    local funcName = "CreateScanFrameContent"

    -- add additional y offset to add spacing below the portrait art
    local offsetY = 10

    -- track content size
    local contentHeight = 0
    local contentWidth = 0

    -- add label
    local regionLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    regionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    regionLabel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    regionLabel:SetJustifyH("LEFT")
    regionLabel:SetText("Scan")
    contentHeight = contentHeight + regionLabel:GetHeight()

    -- add inset frame
    local regionContent = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    regionContent:SetPoint("TOPLEFT", regionLabel, "BOTTOMLEFT", 0, 0)
    regionContent:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- last scan title
    local lastScanTitle = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lastScanTitle:SetPoint("TOPLEFT", regionContent, "TOPLEFT", padding, -offsetY)
    lastScanTitle:SetJustifyH("LEFT")
    lastScanTitle:SetText(("%s%s:|r"):format(ABSync.constants.colors.orange, L["Last Scan on this Character"]))
    contentHeight = contentHeight + lastScanTitle:GetHeight() + offsetY
    contentWidth = math.max(contentWidth, lastScanTitle:GetStringWidth() + (padding * 2))

    -- last scan date/time label
    self.ui.label.lastScan = regionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.lastScan:SetPoint("TOPLEFT", lastScanTitle, "BOTTOMLEFT", 0, -offsetY)
    self.ui.label.lastScan:SetJustifyH("LEFT")
    self:UpdateLastScanLabel()
    contentHeight = contentHeight + self.ui.label.lastScan:GetHeight() + offsetY
    contentWidth = math.max(contentWidth, self.ui.label.lastScan:GetStringWidth())

    -- scan button
    local scanButton = self:CreateStandardButton(regionContent, "Scan Now", 100, function()
        ABSync:GetActionBarData()
        ABSync:UpdateLastScanLabel()
        ABSync:UpdateShareCheckboxes(shareFrame)
    end)
    scanButton:SetPoint("TOPLEFT", self.ui.label.lastScan, "BOTTOMLEFT", 0, -offsetY)
    contentHeight = contentHeight + scanButton:GetHeight() + offsetY
    contentWidth = math.max(contentWidth, scanButton:GetWidth())

    -- add in offsetY for padding below last item
    contentHeight = contentHeight + offsetY

    -- return info
    return {
        width = contentWidth,
        height = contentHeight,
    }
end

--[[---------------------------------------------------------------------------
    Function:   CreateShareSyncFrame
    Purpose:    Create the share frame for selecting action bars to share.
-----------------------------------------------------------------------------]]
function ABSync:CreateShareSyncFrame(playerID, parent)
    -- for debugging
    local funcName = "CreateShareSyncFrame"

    -- standard variables
    local padding = 10

    -- create main frame
    local mainShareFrame = CreateFrame("Frame", nil, parent)
    mainShareFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
    mainShareFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, padding)

    -- create title for share frame
    local title = mainShareFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainShareFrame, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", mainShareFrame, "TOPRIGHT", 0, 0)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText("Share & Sync")

    -- create main content frame
    local mainContentFrame = CreateFrame("Frame", nil, mainShareFrame) --, "InsetFrameTemplate")
    mainContentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMLEFT", mainShareFrame, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMRIGHT", mainShareFrame, "BOTTOMRIGHT", 0, 0)

    -- create each frame attached to mainContentFrame
    local topLeftFrame = CreateFrame("Frame", nil, mainShareFrame)
    local bottomLeftFrame = CreateFrame("Frame", nil, mainShareFrame)
    local topRightFrame = CreateFrame("Frame", nil, mainShareFrame)
    local bottomRightFrame = CreateFrame("Frame", nil, mainShareFrame)

    -- attach all points for topLeftFrame
    topLeftFrame:SetPoint("TOPLEFT", mainContentFrame, "TOPLEFT", 0, 0)
    -- topLeftFrame:SetWidth(100)
    -- topLeftFrame:SetHeight(100)
    
    -- create the share frame; bottom left region
    bottomLeftFrame:SetPoint("TOPLEFT", topLeftFrame, "BOTTOMLEFT", 0, -padding)
    bottomLeftFrame:SetPoint("BOTTOMLEFT", mainContentFrame, "BOTTOMLEFT", 0, 0)

    -- create the sync frame; top right region
    topRightFrame:SetPoint("TOPLEFT", topLeftFrame, "TOPRIGHT", padding, 0)
    topRightFrame:SetPoint("TOPRIGHT", mainContentFrame, "TOPRIGHT", 0, 0)

    -- create the sync from frame; bottom right region
    bottomRightFrame:SetPoint("BOTTOMLEFT", bottomLeftFrame, "BOTTOMRIGHT", padding, 0)
    bottomRightFrame:SetPoint("BOTTOMRIGHT", mainContentFrame, "BOTTOMRIGHT", 0, 0)

    -- add in frame content
    local scanContent = self:CreateScanFrameContent(topLeftFrame, padding)
    local shareContent = self:CreateShareFrameContent(bottomLeftFrame, padding)
    local syncContent = self:CreateSyncFrameContent(topRightFrame, padding)
    local syncFromContent = self:CreateSyncFromFrameContent(bottomRightFrame, padding)

    -- set the sizes of each frame based on content
    topLeftFrame:SetWidth(scanContent.width)
    topLeftFrame:SetHeight(scanContent.height)

    -- finally return the frame
    return mainShareFrame
end