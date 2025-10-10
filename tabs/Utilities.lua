--[[ ------------------------------------------------------------------------
	Title: 			Utilities.lua
	Author: 		mrbryo
	Create Date : 	2025-Oct-03
	Description: 	Building the Utilities tab in the UI.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function: 	AddRemoveAllActionButtonsByBar
    Parameters: parent - the parent frame to attach this content to
    Returns: 	none
    Purpose: 	This function builds the UI components needed to remove all action buttons in a selected action bar.
-----------------------------------------------------------------------------]]
function ABSync:AddRemoveAllActionButtonsByBar(parent)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding
    local rowHeight = 30
    local controlWidth = 200

    -- get 50% width of the dev frame minus padding
    local halfWidth = (parent:GetWidth() / 2) - (padding * 1.5)
    
    -- create frame for this functionality
    local removeFrame = CreateFrame("Frame", nil, parent)
    removeFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    removeFrame:SetHeight(300)
    removeFrame:SetWidth(halfWidth)

    -- add title to remove frame
    local frameTitle = removeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frameTitle:SetPoint("TOPLEFT", removeFrame, "TOPLEFT", 0, 0)
    frameTitle:SetPoint("TOPRIGHT", removeFrame, "TOPRIGHT", 0, 0)
    frameTitle:SetJustifyH("LEFT")
    frameTitle:SetText("Remove Action Bar Buttons")

    -- update height
    local removeFrameHeight = frameTitle:GetStringHeight()

    -- create insert frame for directly under title
    local contentFrame = CreateFrame("Frame", nil, removeFrame, "InsetFrameTemplate")
    contentFrame:SetPoint("TOPLEFT", frameTitle, "BOTTOMLEFT", 0, 0)
    contentFrame:SetPoint("BOTTOMRIGHT", removeFrame, "BOTTOMRIGHT", 0, 0)

    -- creating padding frame
    local paddingFrame = CreateFrame("Frame", nil, contentFrame)
    paddingFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", padding, -padding)
    paddingFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -padding, padding)

    -- update height
    removeFrameHeight = removeFrameHeight + padding + 5

    -- row for the label and button
    local rowBar = CreateFrame("Frame", nil, paddingFrame)
    rowBar:SetPoint("TOPLEFT", paddingFrame, "TOPLEFT", 0, 0)
    rowBar:SetPoint("TOPRIGHT", paddingFrame, "TOPRIGHT", 0, 0)
    rowBar:SetHeight(rowHeight)
    
    -- row for button
    local rowButton = CreateFrame("Frame", nil, paddingFrame)
    rowButton:SetPoint("TOPLEFT", rowBar, "BOTTOMLEFT", 0, 0)
    rowButton:SetPoint("TOPRIGHT", rowBar, "BOTTOMRIGHT", 0, 0)
    rowButton:SetHeight(rowHeight)

    --[[ action bar choice row ]]

    -- label for drop down
    local actionBarLabel = rowBar:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    actionBarLabel:SetPoint("LEFT", rowBar, "LEFT", 0, 0)
    actionBarLabel:SetJustifyH("LEFT")
    actionBarLabel:SetText("Action Bar:")

    -- action bar drop down
    local barValues = self:GetBarValues()
    local lastBarAction = self:GetLastActionBarUtilities()
    local actionBarDropDown = self:CreateDropdown(rowBar, barValues.order, barValues.data, lastBarAction, self:GetObjectName("UtilitiesDropdownActionBar"), function(key)
        ABSync:SetLastActionBarUtilities(key)
    end)
    actionBarDropDown:SetWidth(controlWidth)
    actionBarDropDown:SetPoint("LEFT", actionBarLabel, "RIGHT", padding, 0)

    -- update height
    removeFrameHeight = removeFrameHeight + rowBar:GetHeight()

    --[[ button row ]]

    -- add button to row
    local globalButtonName = self:GetObjectName("UtilitiesClearButton")
    local clearButton = self:CreateStandardButton(rowButton, globalButtonName, ABSync.L["Clear Selected Bar"], 75, function()
        ABSync:BeginActionBarClear()
    end)
    clearButton:SetPoint("LEFT", rowButton, "LEFT", 0, 0)
    clearButton:SetHeight(clearButton.Text:GetStringHeight() + 10)
    clearButton:SetWidth(clearButton.Text:GetStringWidth() + 20)

    -- update height
    removeFrameHeight = removeFrameHeight + rowButton:GetHeight()

    -- adjust height of remove frame
    removeFrame:SetHeight(removeFrameHeight)

    -- adjust width
    local rowBarWidth = actionBarLabel:GetStringWidth() + actionBarDropDown:GetWidth() + (padding * 3)
    local rowButtonWidth = clearButton:GetWidth() + (padding * 3)
    removeFrame:SetWidth(math.max(rowBarWidth, rowButtonWidth))
end

--[[---------------------------------------------------------------------------
    Function: 	ProcessUtilitiesFrame
    Parameters: parent - the parent frame to attach this content to
                tabKey - the key name of the tab being processed
    Returns: 	the main frame for the tab
    Purpose: 	This function builds the Utilities tab in the main UI.
----------------------------------------------------------------------------]]
function ABSync:ProcessUtilitiesFrame(parent, tabKey)
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
    title:SetText(ABSync.L["Utilities"])

    -- create main content frame
    local mainContentFrame = CreateFrame("Frame", nil, mainFrame)
    mainContentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 0, 0)
    mainContentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)

    -- add UI components for removing all buttons in a bar
    self:AddRemoveAllActionButtonsByBar(mainContentFrame)

    -- finally return the main frame for the tab
    return mainFrame
end