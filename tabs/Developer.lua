--[[ ------------------------------------------------------------------------
	Title: 			Developer.lua
	Author: 		mrbryo
	Create Date : 	2025-Oct-03
	Description: 	Building the Developer tab in the UI.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   CreateDevMountDBContent
    Purpose:    Create the mount database content for the developer frame.
-----------------------------------------------------------------------------]]
function ABSync:CreateDevMountDBContent(parent, halfWidth, posnFrame)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding
    -- make the frame just high enough for the content, track its height
    local dbMountFrameHeight = 0

    -- create frame for mount db
    local mountDBFrame = CreateFrame("Frame", nil, parent)
    mountDBFrame:SetPoint("TOPLEFT", posnFrame, "BOTTOMLEFT", 0, -padding)
    mountDBFrame:SetHeight(300)
    mountDBFrame:SetWidth(halfWidth)

    -- add title to mount db frame
    local mountDBTitle = mountDBFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mountDBTitle:SetPoint("TOPLEFT", mountDBFrame, "TOPLEFT", 0, 0)
    mountDBTitle:SetPoint("TOPRIGHT", mountDBFrame, "TOPRIGHT", 0, 0)
    mountDBTitle:SetJustifyH("LEFT")
    mountDBTitle:SetText(ABSync.L["Mount Database"])
    dbMountFrameHeight = dbMountFrameHeight + mountDBTitle:GetStringHeight()

    -- add inset frame to mount db frame
    local mountDBInsetFrame = CreateFrame("Frame", nil, mountDBFrame, "InsetFrameTemplate")
    mountDBInsetFrame:SetPoint("TOPLEFT", mountDBTitle, "BOTTOMLEFT", 0, 0)
    mountDBInsetFrame:SetPoint("BOTTOMRIGHT", mountDBFrame, "BOTTOMRIGHT", 0, 0)

    -- add label explaining the purpose of the button
    local mountDBRefreshInfoLabel = mountDBInsetFrame:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
    mountDBRefreshInfoLabel:SetText(ABSync.L["Click the button below to refresh the mount database for this character. DB stores mount data by character for, currently, manual data comparison. Then click the 'Reload UI' button so the data is available in the saved variables file."])
    mountDBRefreshInfoLabel:SetPoint("TOPLEFT", mountDBInsetFrame, "TOPLEFT", padding, -padding)
    mountDBRefreshInfoLabel:SetPoint("TOPRIGHT", mountDBInsetFrame, "TOPRIGHT", -padding, -padding)
    mountDBRefreshInfoLabel:SetJustifyH("LEFT")
    mountDBRefreshInfoLabel:SetWordWrap(true)
    dbMountFrameHeight = dbMountFrameHeight + mountDBRefreshInfoLabel:GetStringHeight() + (padding * 2)

    -- create button to refresh mount db
    local mountDBRefreshButton = self:CreateStandardButton(mountDBInsetFrame, nil, ABSync.L["Refresh Mount DB"], 150, function()
        ABSync:RefreshMountDB()
    end)
    mountDBRefreshButton:SetPoint("TOPLEFT", mountDBRefreshInfoLabel, "BOTTOMLEFT", 0, -padding)
    dbMountFrameHeight = dbMountFrameHeight + mountDBRefreshButton:GetHeight() + padding

    -- create button to reload the ui
    local mountDBReloadButton = self:CreateStandardButton(mountDBInsetFrame, nil, ABSync.L["Reload UI"], 100, function()
        C_UI.Reload()
    end)
    mountDBReloadButton:SetPoint("TOPLEFT", mountDBRefreshButton, "TOPRIGHT", padding, 0)

    -- create button to clear db for this char
    local mountDBClearButton = self:CreateStandardButton(mountDBInsetFrame, nil, ABSync.L["Clear Character Mount DB"], 200, function()
        ABSync:ClearMountDB()
    end)
    mountDBClearButton:SetPoint("TOPLEFT", mountDBRefreshButton, "BOTTOMLEFT", 0, -padding)
    dbMountFrameHeight = dbMountFrameHeight + mountDBClearButton:GetHeight() + padding

    -- adjust height of mount db frame
    mountDBFrame:SetHeight(dbMountFrameHeight)

    -- return object in case I need it
    return mountDBFrame
end

function CreateDevManualActionButton(parent, halfWidth, posnFrame)
    -- get language data
    local L = ABSync.localeData

    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- make the frame just high enough for the content, track its height
    local manualFrameHeight = 0

    -- create frame for manual action button placement
    local manualFrame = CreateFrame("Frame", nil, parent)
    manualFrame:SetPoint("TOPLEFT", posnFrame, "BOTTOMLEFT", 0, -padding)
    manualFrame:SetHeight(300)
    manualFrame:SetWidth(halfWidth)

    -- add title to manual frame
    local manualTitle = manualFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    manualTitle:SetPoint("TOPLEFT", manualFrame, "TOPLEFT", 0, 0)
    manualTitle:SetPoint("TOPRIGHT", manualFrame, "TOPRIGHT", 0, 0)
    manualTitle:SetJustifyH("LEFT")
    manualTitle:SetText(ABSync.L["Manual Action Button Placement"])
    manualFrameHeight = manualFrameHeight + manualTitle:GetStringHeight()

    -- add inset frame to mount db frame
    local manualInsetFrame = CreateFrame("Frame", nil, manualFrame, "InsetFrameTemplate")
    manualInsetFrame:SetPoint("TOPLEFT", manualTitle, "BOTTOMLEFT", 0, 0)
    manualInsetFrame:SetPoint("BOTTOMRIGHT", manualFrame, "BOTTOMRIGHT", 0, 0)

    -- add label explaining the purpose of the button
    local manualInfoLabel = manualInsetFrame:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
    manualInfoLabel:SetText(ABSync.L["Click the button below to open a dialog that allows you to manually place an action button on your action bars. This is primarily for testing purposes."])
    manualInfoLabel:SetPoint("TOPLEFT", manualInsetFrame, "TOPLEFT", padding, -padding)
    manualInfoLabel:SetPoint("TOPRIGHT", manualInsetFrame, "TOPRIGHT", -padding, -padding)
    manualInfoLabel:SetJustifyH("LEFT")
    manualInfoLabel:SetWordWrap(true)
    dbMountFrameHeight = dbMountFrameHeight + manualInfoLabel:GetStringHeight() + (padding * 2)

    -- create button to open the dialog
    
end

--[[---------------------------------------------------------------------------
    Function:   ProcessDeveloperFrame
    Purpose:    Create the developer frame for testing and debugging.
-----------------------------------------------------------------------------]]
function ABSync:ProcessDeveloperFrame(parent, tabKey)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    local devFrame, existed = self:ProcessTabContentFrame(tabKey, parent)

    -- if frame existed then just return it, no need to recreate content
    if existed then
        return devFrame
    end

    -- make sure devFrame was populated
    if not devFrame then
        self:Print(ABSync.L["Error: devFrame is nil in ProcessDeveloperFrame."])
        return nil
    end

    -- set frame position
    devFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
    devFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, 0)

    -- create title for frame
    local title = devFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", devFrame, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", devFrame, "TOPRIGHT", 0, 0)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText(ABSync.L["Developer"])

    --[[ warning! ]]

    -- create frame for warning
    local warningFrame = CreateFrame("Frame", nil, devFrame, "InsetFrameTemplate")
    warningFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    warningFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    warningFrame:SetHeight(30)

    -- add label to warning frame
    local warningText = warningFrame:CreateFontString(nil, "ARTWORK", "GameFontWhiteSmall")
    warningText:SetPoint("TOPLEFT", warningFrame, "TOPLEFT", padding, -padding)
    warningText:SetPoint("BOTTOMRIGHT", warningFrame, "BOTTOMRIGHT", -padding, padding)
    warningText:SetJustifyH("LEFT")
    warningText:SetWordWrap(true)
    warningText:SetText(("|cffff0000%s|r: %s"):format(ABSync.L["Warning"], ABSync.L["This tab is used for development purposes only."]))
    warningFrame:SetHeight(warningText:GetStringHeight() + (padding * 2))

    -- get 50% width of the dev frame minus padding
    local halfWidth = (devFrame:GetWidth() / 2) - (padding * 1.5)

    --[[ mount db refresh ]]
    local mountDBFrame = self:CreateDevMountDBContent(devFrame, halfWidth, warningFrame)

    --[[ manual action button placement ]]
    -- local manualFrame = self:CreateDevManualActionButton(parent, halfWidth, mountDBFrame)

    -- return object
    return devFrame
end