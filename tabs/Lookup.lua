--[[---------------------------------------------------------------------------
    Function:   LookupAction
    Purpose:    Look up the action based on the last entered action type and ID.
-----------------------------------------------------------------------------]]
function ABSync:LookupAction()
    -- get language data
    local L = self.localeData

    -- get the action type
    local actionType = self:GetLastActionType()
    
    -- get the action ID
    local actionID = self:GetLastActionID()

    --@debug@
    if self.db.char.isDevMode == true then self:Print((L["Looking up Action - Type: %s - ID: %s"]):format(actionType, actionID)) end
    --@end-debug@

    -- instantiate lookup storage
    local lookupInfo = {
        type = actionType,
        id = actionID,
        name = L["unknown"],
        has = L["no"]
    }

    -- perform lookup based on type
    local actionData = self:GetActionData(actionID, actionType)
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
    Function:   CreateLookupQueryFrame
    Purpose:    Create the lookup query frame for performing action lookups.
    Arguments:  parent  - The parent frame to attach this frame to
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:CreateLookupQueryFrame(parent)
    -- get language data
    local L = self.localeData

    -- set standard values
    local labelWidth = 75
    local controlWidth = 200
    local padding = ABSync.constants.ui.generic.padding
    local paddingAdjust = 5 -- to align edit boxes with drop downs, add N padding to the left of edit boxes and make the size N smaller

    -- track heights and widths
    local topFrameHeight = 0
    local colOneWidth = 0
    
    -- create top section group with label named "Perform a Lookup"
    local topContent = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    topContent:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    topContent:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    topContent:SetHeight(100) -- set initial height, will expand as needed

    -- intro at top of top section
    local introLabel = topContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    introLabel:SetPoint("TOPLEFT", topContent, "TOPLEFT", padding, -padding)
    introLabel:SetPoint("TOPRIGHT", topContent, "TOPRIGHT", -padding, -padding)
    introLabel:SetJustifyH("LEFT")
    introLabel:SetText(L["This tab allows you to look up actions by type and ID."])
    -- topFrameHeight = topFrameHeight + introLabel:GetHeight() + padding

    -- build table
    local rowOne = CreateFrame("Frame", nil, topContent)
    rowOne:SetPoint("TOPLEFT", introLabel, "BOTTOMLEFT", 0, -padding)
    rowOne:SetPoint("TOPRIGHT", introLabel, "BOTTOMRIGHT", 0, -padding)
    rowOne:SetHeight(25)    -- set initial height, will expand as needed
    local rowTwo = CreateFrame("Frame", nil, topContent)
    rowTwo:SetPoint("TOPLEFT", rowOne, "BOTTOMLEFT", 0, 0)
    rowTwo:SetPoint("TOPRIGHT", rowOne, "BOTTOMRIGHT", 0, 0)
    rowTwo:SetHeight(25)    -- set initial height, will expand as needed

    -- action id row; label for edit box
    local actionIdLabel = rowOne:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionIdLabel:SetPoint("LEFT", rowOne, "LEFT", 0, 0)
    actionIdLabel:SetJustifyH("LEFT")
    actionIdLabel:SetText(("%sAction ID:|r"):format(ABSync.constants.colors.label))

    -- action id row; edit box for entering action id
    local actionIdInput = self:CreateEditBox(rowOne, controlWidth - paddingAdjust, nil, false, function(self)
        local value = self:GetText()
        ABSync:SetLastActionID(value)

        -- trigger timer
        if value and value ~= "" then
            ABSync:SetLabelWithTimer(ABSync.ui.label.actionSaved, L["Saved!"], 3, nil)
        end
    end)
    actionIdInput:SetPoint("LEFT", actionIdLabel, "RIGHT", padding + paddingAdjust, 0)
    actionIdInput:SetText(ABSync:GetLastActionID() or "")
    -- topFrameHeight = topFrameHeight + actionIdInput:GetHeight() + padding

    -- action id row; label to show entered action id, confirms to use it was entered successfully
    self.ui.label.actionSaved = rowOne:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ui.label.actionSaved:SetPoint("LEFT", actionIdInput, "RIGHT", padding, 0)
    self.ui.label.actionSaved:SetJustifyH("LEFT")
    
    -- action type row; label for drop down
    local actionTypeLabelText = ("%sAction Type:|r"):format(ABSync.constants.colors.label)
    local actionTypeLabel = rowTwo:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionTypeLabel:SetPoint("LEFT", rowTwo, "LEFT", 0, 0)
    actionTypeLabel:SetJustifyH("LEFT")
    actionTypeLabel:SetText(actionTypeLabelText)
    colOneWidth = math.max(actionIdLabel:GetStringWidth(), actionTypeLabel:GetStringWidth())

    -- set action ID now we know which label is wider
    actionIdLabel:SetWidth(colOneWidth)

    -- must set the size of this label in case the action ID was larger
    actionTypeLabel:SetWidth(colOneWidth)

    -- action type row; drop down for selecting action type
    local actionTypeDropDown = self:CreateDropdown(rowTwo, self:GetActionTypeValues(), self:GetLastActionType(), function(key)
        ABSync:SetLastActionType(key)
    end)
    --@debug@
    -- swap this in for CreateDropdown to see if size is really same as the action id row; it normally is and the drop down is more narrow for some reason
    -- local actionTypeDropDown = self:CreateEditBox(rowTwo, controlWidth, nil, false, function(self)
    --     local value = self:GetText()
    --     ABSync:SetLastActionType(value)
    -- end)
    --@end-debug@
    actionTypeDropDown:SetWidth(controlWidth)
    actionTypeDropDown:SetPoint("LEFT", actionTypeLabel, "RIGHT", padding, 0)
    -- topFrameHeight = topFrameHeight + actionTypeDropDown:GetHeight() + padding

    -- action type row; button to perform the lookup
    local lookupButton = self:CreateStandardButton(rowTwo, L["lookupbuttonname"], 75, function()
        ABSync:LookupAction()
    end)
    lookupButton:SetPoint("LEFT", actionTypeDropDown, "RIGHT", padding, 0)
    -- topFrameHeight = topFrameHeight + lookupButton:GetHeight() + padding

    -- adjust height of trigger content frame
    topContent:SetHeight(rowOne:GetHeight() + rowTwo:GetHeight() + introLabel:GetHeight() + (padding * 3))

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
    -- if self.db.char.isDevMode == true then
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
                colVal = ABSync.actionTypeLookup[colVal]
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
    if #self.db.char.lookupHistory > 0 then
        for _, histRow in ipairs(self.db.char.lookupHistory) do
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
    -- get language data
    local L = self.localeData

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
    title:SetText(L["History"])

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
    Function:   CreateLookupFrame
    Purpose:    Create the lookup frame for displaying action lookups.
    Arguments:  parent  - The parent frame to attach this frame to
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:CreateLookupFrame(parent)
    -- get language data
    local L = self.localeData

    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create main frame which fills the parent with type fill
    local mainFrame = CreateFrame("Frame", nil, parent)
    mainFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
    mainFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, 0)

    -- create the title
    local title = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText(L["Lookup"])

    -- create main content frame
    local mainContentFrame = CreateFrame("Frame", nil, mainFrame)
    mainContentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)

    -- add top frame to perform lookup
    local topFrame = self:CreateLookupQueryFrame(mainContentFrame)

    -- create lower section group with label named "Lookup History"
    local historyFrame = self:CreateLookupHistoryFrame(mainContentFrame, topFrame:GetHeight())
end