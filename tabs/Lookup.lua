--[[ ------------------------------------------------------------------------
	Title: 			Lookup.lua
	Author: 		mrbryo
	Create Date : 	2025-Oct-03
	Description: 	Building the Lookup tab in the UI.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   LookupAction
    Purpose:    Look up the action based on the last entered action type and ID.
-----------------------------------------------------------------------------]]
function ABSync:LookupAction()
    -- get the action type
    local actionType = self:GetLastActionType()
    
    -- get the action ID
    local buttonActionID = self:GetLastActionID()

    --@debug@
    if self:GetDevMode() == true then
        self:Print((ABSync.L["Looking up Action - Type: %s - ID: %s"]):format(actionType, buttonActionID))
    end
    --@end-debug@

    -- instantiate lookup storage
    local lookupInfo = {
        type = actionType,
        id = buttonActionID,
        name = ABSync.L["Unknown"],
        has = ABSync.L["No"]
    }

    -- perform lookup based on type
    local actionData = self:GetActionData(buttonActionID, actionType)
    if actionData then
        lookupInfo.name = actionData.name
        lookupInfo.has = actionData.has
    end

    --@debug@
    -- for k, v in pairs(actionData)
    --@end-debug@

    -- insert record to lookupHistory
    self:InsertLookupHistory(lookupInfo)

    -- update scroll region for lookup history
    self:UpdateLookupHistory()
end

--[[---------------------------------------------------------------------------
    Function:   CreateTopRegion
    Purpose:    Create the lookup query frame for performing action lookups.
    Arguments:  parent  - The parent frame to attach this frame to
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:CreateTopRegion(parent)
    -- set standard values
    local labelWidth = 75
    local controlWidth = 200
    local padding = ABSync.constants.ui.generic.padding
    local paddingAdjust = 5 -- to align edit boxes with drop downs, add N padding to the left of edit boxes and make the size N smaller
    local rowHeight = 30

    -- track heights and widths
    local topFrameHeight = 0
    local colOneWidth = 0
    
    -- create top section group with label named "Perform a Lookup"
    local topContent = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    topContent:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    topContent:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    topContent:SetHeight(100) -- set initial height, will expand as needed
    local topWidth = (topContent:GetWidth() / 2) - (padding * 1.5)

    -- intro at top of top section
    local introLabel = topContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    introLabel:SetPoint("TOPLEFT", topContent, "TOPLEFT", padding, -padding)
    introLabel:SetPoint("TOPRIGHT", topContent, "TOPRIGHT", -padding, -padding)
    introLabel:SetJustifyH("LEFT")
    introLabel:SetText(ABSync.L["This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."])
    -- topFrameHeight = topFrameHeight + introLabel:GetHeight() + padding

    -- build table
    local rowID = CreateFrame("Frame", nil, topContent)
    rowID:SetPoint("TOPLEFT", introLabel, "BOTTOMLEFT", 0, -padding)
    rowID:SetHeight(rowHeight)    -- set initial height, will expand as needed
    rowID:SetWidth(topWidth)
    local rowName = CreateFrame("Frame", nil, topContent)
    rowName:SetPoint("TOPLEFT", rowID, "BOTTOMLEFT", 0, 0)
    rowName:SetPoint("TOPRIGHT", rowID, "BOTTOMRIGHT", 0, 0)
    rowName:SetHeight(rowHeight)  -- set initial height, will expand as needed
    rowID:SetWidth(topWidth)
    local rowType = CreateFrame("Frame", nil, topContent)
    rowType:SetPoint("TOPLEFT", rowName, "BOTTOMLEFT", 0, 0)
    rowType:SetPoint("TOPRIGHT", rowName, "BOTTOMRIGHT", 0, 0)
    rowType:SetHeight(rowHeight)    -- set initial height, will expand as needed
    rowID:SetWidth(topWidth)
    local rowBar = CreateFrame("Frame", nil, topContent)
    rowBar:SetPoint("LEFT", rowID, "RIGHT", padding, 0)
    rowBar:SetHeight(rowHeight)    -- set initial height, will expand as needed
    rowBar:SetWidth(topWidth)
    local rowBtn = CreateFrame("Frame", nil, topContent)
    rowBtn:SetPoint("LEFT", rowName, "RIGHT", padding, 0)
    rowBtn:SetHeight(rowHeight)    -- set initial height, will expand as needed
    rowBtn:SetWidth(topWidth)
    local rowTrigger = CreateFrame("Frame", nil, topContent)
    rowTrigger:SetPoint("LEFT", rowType, "RIGHT", padding, 0)
    rowTrigger:SetHeight(rowHeight)    -- set initial height, will expand as needed
    rowTrigger:SetWidth(topWidth)

    --[[ action id row ]]

    -- action id row; label for edit box
    local actionIdLabel = rowID:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionIdLabel:SetPoint("LEFT", rowID, "LEFT", 0, 0)
    actionIdLabel:SetJustifyH("LEFT")
    actionIdLabel:SetText(("%s%s:|r"):format(ABSync.constants.colors.label, ABSync.L["ID"]))

    -- action id row; edit box for entering action id
    local actionIdInput = self:CreateEditBox(rowID, controlWidth - paddingAdjust, nil, false, function(self)
        local value = self:GetText()
        ABSync:SetLastActionID(value)

        -- trigger timer
        if value and value ~= "" then
            ABSync:SetLabelWithTimer(ABSync.ui.label.actionIdSaved, ABSync.L["Saved!"], 3, nil)
        end
    end)
    actionIdInput:SetPoint("LEFT", actionIdLabel, "RIGHT", padding + paddingAdjust, 0)
    actionIdInput:SetText(self:GetLastActionID() or "")
    -- topFrameHeight = topFrameHeight + actionIdInput:GetHeight() + padding

    -- save confirmation
    self.ui.label.actionIdSaved = rowID:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.actionIdSaved:SetPoint("LEFT", actionIdInput, "RIGHT", padding, 0)
    self.ui.label.actionIdSaved:SetJustifyH("LEFT")
    self.ui.label.actionIdSaved:SetText(ABSync.L["Saved!"])
    local savedWidthId = self.ui.label.actionIdSaved:GetWidth()
    self.ui.label.actionIdSaved:SetText("")  -- clear it out for now

    --[[ action name row]]

    -- add label for Action Name
    local actionNameLabel = rowName:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionNameLabel:SetPoint("LEFT", rowName, "LEFT", 0, 0)
    actionNameLabel:SetJustifyH("LEFT")
    actionNameLabel:SetText(("%s%s:|r"):format(ABSync.constants.colors.label, ABSync.L["Name"]))

    -- edit box for enter action name
    local actionNameInput = self:CreateEditBox(rowName, controlWidth - paddingAdjust, nil, false, function(self)
        local value = self:GetText()
        ABSync:SetLastActionName(value)

        -- trigger timer
        if value and value ~= "" then
            ABSync:SetLabelWithTimer(ABSync.ui.label.actionNameSaved, ABSync.L["Saved!"], 3, nil)
        end
    end)
    actionNameInput:SetPoint("LEFT", actionNameLabel, "RIGHT", padding + paddingAdjust, 0)
    actionNameInput:SetText(self:GetLastActionName())

    -- save confirmation
    self.ui.label.actionNameSaved = rowName:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.actionNameSaved:SetPoint("LEFT", actionNameInput, "RIGHT", padding, 0)
    self.ui.label.actionNameSaved:SetJustifyH("LEFT")

    --[[ action type row ]]
    
    -- label for drop down
    local actionTypeLabelText = ("%s%s:|r"):format(ABSync.constants.colors.label, ABSync.L["Type"])
    local actionTypeLabel = rowType:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionTypeLabel:SetPoint("LEFT", rowType, "LEFT", 0, 0)
    actionTypeLabel:SetJustifyH("LEFT")
    actionTypeLabel:SetText(actionTypeLabelText)

    -- check which label is wider
    colOneWidth = math.max(actionIdLabel:GetStringWidth(), actionTypeLabel:GetStringWidth(), actionNameLabel:GetStringWidth())

    -- set all labels to same width
    actionIdLabel:SetWidth(colOneWidth)
    actionTypeLabel:SetWidth(colOneWidth)
    actionNameLabel:SetWidth(colOneWidth)

    -- action type row; drop down for selecting action type
    local actionTypeLookup = self:GetActionTypeValues()
    local actionTypeDropDown = self:CreateDropdown(rowType, actionTypeLookup.order, actionTypeLookup.data, self:GetLastActionType(), self:GetObjectName("DropdownActionType"), function(key)
        ABSync:SetLastActionType(key)
    end)
    --@debug@
    -- swap this in for CreateDropdown to see if size is really same as the action id row; it normally is and the drop down is more narrow for some reason
    -- local actionTypeDropDown = self:CreateEditBox(rowType, controlWidth, nil, false, function(self)
    --     local value = self:GetText()
    --     ABSync:SetLastActionType(value)
    -- end)
    --@end-debug@
    actionTypeDropDown:SetWidth(controlWidth)
    actionTypeDropDown:SetPoint("LEFT", actionTypeLabel, "RIGHT", padding, 0)
    -- topFrameHeight = topFrameHeight + actionTypeDropDown:GetHeight() + padding

    -- action type row; button to perform the lookup
    local lookupButton = self:CreateStandardButton(rowType, nil, ABSync.L["Lookup"], 75, function()
        ABSync:LookupAction()
    end)
    lookupButton:SetPoint("LEFT", actionTypeDropDown, "RIGHT", padding, 0)
    -- topFrameHeight = topFrameHeight + lookupButton:GetHeight() + padding

    --[[ action bar choice row ]]

    -- label for drop down
    local actionBarLabelText = ("%s%s:|r"):format(ABSync.constants.colors.label, ABSync.L["Bar"])
    local actionBarLabel = rowBar:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionBarLabel:SetPoint("LEFT", rowBar, "LEFT", 0, 0)
    actionBarLabel:SetJustifyH("LEFT")
    actionBarLabel:SetText(actionBarLabelText)

    -- action bar drop down
    local barValues = self:GetBarValues()
    local lastBarAction = self:GetLastActionBar()
    local actionBarDropDown = self:CreateDropdown(rowBar, barValues.order, barValues.data, lastBarAction, self:GetObjectName("DropdownActionBar"), function(key)
        ABSync:SetLastActionBar(key)
    end)
    actionBarDropDown:SetWidth(controlWidth)
    actionBarDropDown:SetPoint("LEFT", actionBarLabel, "RIGHT", padding, 0)

    --[[ action button drop down row]]

    -- label for button drop down
    local actionBtnLabelText = ("%s%s:|r"):format(ABSync.constants.colors.label, ABSync.L["Button"])
    local actionBtnLabel = rowBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionBtnLabel:SetPoint("LEFT", rowBtn, "LEFT", 0, 0)
    actionBtnLabel:SetJustifyH("LEFT")
    actionBtnLabel:SetText(actionBtnLabelText)

    -- action button drop down
    local actionButtonValues = self:GetButtonValues()
    local actionBtnDropDown = self:CreateDropdown(rowBtn, actionButtonValues, nil, self:GetLastActionButton(), self:GetObjectName("DropdownActionButton"), function(key)
        ABSync:SetLastActionButton(key)
    end)
    actionBtnDropDown:SetWidth(controlWidth)
    actionBtnDropDown:SetPoint("LEFT", actionBtnLabel, "RIGHT", padding, 0)

    --[[ place action button row ]]

    -- place action button
    local applyActionButton = self:CreateStandardButton(rowTrigger, nil, ABSync.L["Place Action"], 100, function()
        -- get stored values
        local buttonActionID = ABSync:GetLastActionID()
        local actionType = ABSync:GetLastActionType()
        local actionBar = ABSync:GetLastActionBar()
        local actionButton = ABSync:GetLastActionButton()
        ActionBarSyncDB.char[self.currentPlayerServerSpec].lastActionPlacement = ABSync:PlaceActionOnBar(buttonActionID, actionType, actionBar, actionButton)
    end)
    applyActionButton:SetPoint("LEFT", rowTrigger, "LEFT", 0, 0)

    -- [[ content added, below is further adjustments to layout and sizes ]]

    -- adjust height of trigger content frame
    topContent:SetHeight(rowID:GetHeight() + rowType:GetHeight() + rowName:GetHeight() + introLabel:GetHeight() + (padding * 3))

    -- check for max width of column 2
    local colTwoWidth = math.max(actionBtnLabel:GetWidth(), actionBarLabel:GetWidth())
    actionBtnLabel:SetWidth(colTwoWidth)
    actionBarLabel:SetWidth(colTwoWidth)

    -- return built frame
    return topContent
end

--[[---------------------------------------------------------------------------
    Function:   AddRow
    Purpose:    Add a row of information to the UI table.
-----------------------------------------------------------------------------]]
function ABSync:AddRow(parent, data, columns, offsetY, isHeader)
    -- default isHeader to false
    isHeader = isHeader or false
    -- print("Adding Error Row, isHeader: " .. tostring(isHeader))

    -- set up row group of columns
    local rowGroup = CreateFrame("Frame", nil, parent)
    rowGroup:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offsetY)
    rowGroup:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -offsetY)

    -- calculate height of row; temporary height, will be adjusted later
    local maxHeight = 20
    rowGroup:SetHeight(maxHeight)

    -- print("Width: " .. tostring(rowGroup:GetWidth()))

    --@debug@
    -- if self:GetDevMode() == true then
    --     local fakelabel = rowGroup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    --     fakelabel:SetText("Fake Info")
    --     fakelabel:SetPoint("TOPLEFT", rowGroup, "TOPLEFT", 0, 0)
    --     fakelabel:SetJustifyH("LEFT")
    --     fakelabel:SetWidth(200)
    -- end
    --@end-debug@

    -- track x offset
    local offsetX = 10

    -- loop over the column definitions
    for _, colDef in ipairs(columns) do
        -- initialize column value
        local colVal = "-"

        -- if header, read only from columns, data is nil
        if isHeader == true then
            colVal = colDef.name
        else
            -- translate data if necessary
            colVal = data[colDef.key]
            if colDef.key == "type" then
                colVal = ABSync.actionTypeLookup.data[colVal]
            end
            -- print("ColVal: " .. tostring(colVal))
        end

        -- create cell
        local cellWidth, cellHeight = self:AddErrorCell(rowGroup, colVal, colDef.width, offsetX, isHeader)
        maxHeight = math.max(maxHeight, cellHeight)
        offsetX = offsetX + cellWidth + 5
    end

    -- finally set row height
    rowGroup:SetHeight(maxHeight)

    -- return row height
    return rowGroup:GetHeight()
end

--[[---------------------------------------------------------------------------
    Function:   LookupHistoryRemoveAllRows
    Purpose:    Remove all rows from the lookup history.
-----------------------------------------------------------------------------]]
-- function ABSync:LookupHistoryRemoveAllRows()
--     -- if no scroll region, nothing to do
--     if not ABSync.ui.scroll.lookupHistory then return end

--     -- loop over children and remove them
--     for i, child in ipairs({ ABSync.ui.scroll.lookupHistory:GetChildren() }) do
--         child:Hide()
--         child:SetParent(nil)
--         child = nil
--         -- print("Removed Lookup History Row: " .. tostring(i))
--     end
-- end

--[[---------------------------------------------------------------------------
    Function:   UpdateLookupHistory
    Purpose:    Update the rows of data in the scroll region for lookup history.
-----------------------------------------------------------------------------]]
function ABSync:UpdateLookupHistory()
    -- set initial offset
    local offsetY = 5

    -- remove all existing rows
    self:RemoveFrameChildren(ABSync.ui.scroll.lookupHistory)

    -- if 1 or more rows loop and add a row for each history record
    if #ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory > 0 then
        for _, histRow in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].lookupHistory) do
            local rowHeight = self:AddRow(ABSync.ui.scroll.lookupHistory, histRow, ABSync.columns.lookupHistory, offsetY, false)
            offsetY = offsetY + rowHeight
        end
    end
end

 --[[---------------------------------------------------------------------------
    Function:   CreateLookupHistoryFrame
    Purpose:    Create the lookup history frame for displaying past lookups.
    Arguments:  parent      - The parent frame to attach this frame to
                frameOffsetY- The Y offset from the top of the parent frame
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:CreateLookupHistoryFrame(parent, frameOffsetY)
    -- set standard values
    local labelWidth = 75
    local controlWidth = 200
    local padding = ABSync.constants.ui.generic.padding
    local paddingAdjust = 5 -- to align edit boxes with drop downs, add N padding to the left of edit boxes and make the size N smaller

    -- track heights and widths
    local topFrameHeight = 0
    local colOneWidth = 0

    -- create main frame
    local historyContent = CreateFrame("Frame", nil, parent)
    frameOffsetY = frameOffsetY + padding
    historyContent:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -frameOffsetY)
    historyContent:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- add label
    local title = historyContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", historyContent, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", historyContent, "TOPRIGHT", 0, 0)
    title:SetJustifyH("LEFT")
    title:SetText(ABSync.L["History"])

    -- add frame to show history
    local historyFrame = CreateFrame("Frame", nil, historyContent, "InsetFrameTemplate")
    historyFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    historyFrame:SetPoint("BOTTOMRIGHT", historyContent, "BOTTOMRIGHT", 0, 0)

    -- add header
    local header = CreateFrame("Frame", nil, historyFrame)
    header:SetPoint("TOPLEFT", historyFrame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", historyFrame, "TOPRIGHT", -27, 0)
    header:SetHeight(30)
    local offsetX = padding
    local offsetY = 5
    local maxHeight = 0
    local hdrRowheight = self:AddRow(header, nil, ABSync.columns.lookupHistory, offsetY, true)
    maxHeight = math.max(maxHeight, hdrRowheight)
    header:SetHeight(maxHeight)

    -- create a scroll frame to hold the history
    local scrollContainer = CreateFrame("ScrollFrame", nil, historyFrame, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    scrollContainer:SetPoint("BOTTOMRIGHT", historyFrame, "BOTTOMRIGHT", -27, 0)

    -- add scroll frame to container
    ABSync.ui.scroll.lookupHistory = CreateFrame("Frame", nil, scrollContainer)
    ABSync.ui.scroll.lookupHistory:SetWidth(scrollContainer:GetWidth())
    ABSync.ui.scroll.lookupHistory:SetHeight(scrollContainer:GetHeight() - padding)
    scrollContainer:SetScrollChild(ABSync.ui.scroll.lookupHistory)
    
    -- populate the scroll frame
    -- self:InsertLookupHistoryRows(ABSync.ui.scroll.lookupHistory, ABSync.columns.lookupHistory)
    self:UpdateLookupHistory()
end

--[[---------------------------------------------------------------------------
    Function:   ProcessLookupFrame
    Purpose:    Create the lookup frame for displaying action lookups.
    Arguments:  parent  - The parent frame to attach this frame to
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:ProcessLookupFrame(parent, tabKey)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    local mainFrame, existed = self:ProcessTabContentFrame(tabKey, parent)

    -- if frame existed then just return it, no need to recreate content
    if existed then
        return mainFrame
    end

    -- set frame position
    mainFrame:SetAllPoints(parent)

    -- create the title
    local title = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", padding, -padding)
    title:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -padding, -padding)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText(ABSync.L["Lookup & Assign"])

    -- create main content frame
    local mainContentFrame = CreateFrame("Frame", nil, mainFrame)
    mainContentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)

    -- add top frame to perform lookup
    local topFrame = self:CreateTopRegion(mainContentFrame)

    -- create lower section group with label named "Lookup History"
    local historyFrame = self:CreateLookupHistoryFrame(mainContentFrame, topFrame:GetHeight())
end