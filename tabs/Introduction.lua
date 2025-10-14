--[[ ------------------------------------------------------------------------
	Title: 			Introduction.lua
	Author: 		mrbryo
	Create Date : 	2025-Oct-03
	Description: 	Building the Introduction tab in the UI.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   CreateInstructionsFrame
    Purpose:    Create the Introduction frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:ProcessIntroductionFrame(parent, tabKey)
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    local instructionsFrame, existed = self:ProcessTabContentFrame(tabKey, parent)

    -- if frame existed then just return it, no need to recreate content
    if existed then
        return instructionsFrame
    end

    -- get instructions
    local instructions = {
        (ABSync.L["On the |cff00ff00%s|r tab click the |cff00ff00%s|r button. An initial scan is required for the addon to function. It should have a date/time to show a scan has already been done. The addon should perform a scan before it does any work. Eventually, the |cff00ff00%s|r button will be removed."]):format(ABSync.uitabs["tabs"]["sharesync"], ABSync.L["Scan Now"], ABSync.L["Scan Now"]),
        ABSync.L["Definition: Source Character - A character which has action bars you want to share with other characters."],
        ABSync.L["Definition: Target Character - A character which will receive action bar data from one or more source characters."],
        (ABSync.L["On the |cff00ff00%s|r tab for each Source Character, check each Action Bar you want to share in the |cff00ff00%s|r section."]):format(ABSync.uitabs["tabs"]["sharesync"], ABSync.L["Select Action Bars to Share"]),
        (ABSync.L["On the |cff00ff00%s|r tab for each Target Character, check each Action Bar you want to update from one or more Source Characters in the |cff00ff00%s|r section."]):format(ABSync.uitabs["tabs"]["sharesync"], ABSync.L["Sync Action Bars From"]),
        (ABSync.L["On the |cff00ff00%s|r tab, once the previous step is done, click the |cff00ff00%s|r button to sync your action bars. If you want your bars auto synced, enable the |cff00ff00%s|r option."]):format(ABSync.uitabs["tabs"]["sharesync"], ABSync.L["Sync Now"], ABSync.L["Enable Sync on Login (no backups occur)"]),
        ABSync.L["Done!"],
    }

    -- FAQ
    local faq = {
        (ABSync.L["If an action button does not sync and an error for the same button isn't on the '%s' tab, it means the action can't be picked up and placed through Blizzard's API via this addon. Trying to figure out how to capture pickup or placement failures."]):format(ABSync.uitabs["tabs"]["last_sync_errors"]),
        ABSync.L["Be sure to open all sources of action bar buttons in order for the game to load that particular data into the game memory so the WoW API can access it. For example, if you have a toy on an action button, open your toy box. You won't see any addon or WoW errors, but the addon won't be able to capture or place the toy on the action button and no errors will be recorded. All sources could be spells, items, toys, mounts, pets and macros. If you forget to do this, just rescan and then try syncing again after opening all game content."],
    }

    -- set label height
    local labelHeight = 30
    local labelCount = 2

    -- place frame in parent
    instructionsFrame:SetAllPoints(parent)

    -- create title for instructions frame
    local title = instructionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", instructionsFrame, "TOPLEFT", 10, -10)
    title:SetPoint("TOPRIGHT", instructionsFrame, "TOPRIGHT", -10, -10)
    title:SetHeight(labelHeight)
    title:SetJustifyH("CENTER")
    title:SetText(ABSync.L["Instructions"])

    -- create the scroll frame inset frame, parent to the instructions scrolling area
    local instructionsInsetFrame = CreateFrame("Frame", nil, instructionsFrame, "InsetFrameTemplate")
    instructionsInsetFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    instructionsInsetFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    instructionsInsetFrame:SetHeight((instructionsFrame:GetHeight() - (labelHeight * labelCount)) * 0.5)

    -- create scroll frame for instructions
    local instructionsScroll = CreateFrame("ScrollFrame", nil, instructionsInsetFrame, "UIPanelScrollFrameTemplate")
    instructionsScroll:SetPoint("TOPLEFT", instructionsInsetFrame, "TOPLEFT", 5, -5)
    instructionsScroll:SetPoint("BOTTOMRIGHT", instructionsInsetFrame, "BOTTOMRIGHT", -27, 5)

    -- create content frame for the scroll area
    local instructionsScrollContent = CreateFrame("Frame", nil, instructionsScroll)
    instructionsScrollContent:SetWidth(instructionsScroll:GetWidth() - 20)
    -- TODO: Set Height based on content dynamically!
    instructionsScrollContent:SetHeight(instructionsInsetFrame:GetHeight() - 10)
    instructionsScroll:SetScrollChild(instructionsScrollContent)

    -- create faq title
    local faqTitle = instructionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    faqTitle:SetPoint("TOPLEFT", instructionsInsetFrame, "BOTTOMLEFT", 0, 0)
    faqTitle:SetPoint("TOPRIGHT", instructionsInsetFrame, "BOTTOMRIGHT", 0, 0)
    faqTitle:SetHeight(labelHeight)
    faqTitle:SetJustifyH("CENTER")
    faqTitle:SetText(ABSync.L["Frequently Asked Questions"])

    -- create faq content frame
    local faqInsetFrame = CreateFrame("Frame", nil, instructionsFrame, "InsetFrameTemplate")
    faqInsetFrame:SetWidth(instructionsScrollContent:GetWidth())
    faqInsetFrame:SetPoint("TOPLEFT", faqTitle, "BOTTOMLEFT", 0, 0)
    faqInsetFrame:SetPoint("TOPRIGHT", faqTitle, "BOTTOMRIGHT", 0, 0)
    faqInsetFrame:SetPoint("BOTTOM", instructionsFrame, "BOTTOM", 0, 0)

    -- create faq scroll frame
    local faqScroll = CreateFrame("ScrollFrame", nil, faqInsetFrame, "UIPanelScrollFrameTemplate")
    faqScroll:SetPoint("TOPLEFT", faqInsetFrame, "TOPLEFT", 5, -5)
    faqScroll:SetPoint("BOTTOMRIGHT", faqInsetFrame, "BOTTOMRIGHT", -27, 5)

    -- create faq content frame
    local faqScrollContent = CreateFrame("Frame", nil, faqScroll)
    faqScrollContent:SetWidth(faqScroll:GetWidth() - 20)
    faqScrollContent:SetHeight(faqScroll:GetHeight() - 10)
    faqScroll:SetScrollChild(faqScrollContent)

    -- track current Y position for vertical layout
    local currentY = -10
    local spacing = 10

    -- Add instruction steps
    for i, instruct in ipairs(instructions) do
        -- bullet
        local bullet = instructionsScrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        bullet:SetPoint("TOPLEFT", instructionsScrollContent, "TOPLEFT", 10, currentY)
        bullet:SetText(("%d."):format(i))
        bullet:SetJustifyH("LEFT")

        -- create instruction label
        local stepLabel = instructionsScrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        stepLabel:SetPoint("TOPLEFT", bullet, "TOPLEFT", 20, 0)
        stepLabel:SetPoint("RIGHT", instructionsScrollContent, "RIGHT", -10, 0)
        stepLabel:SetText(instruct)
        stepLabel:SetJustifyH("LEFT")
        stepLabel:SetWordWrap(true)

        -- calculate height needed for wrapped text
        local textHeight = stepLabel:GetStringHeight()
        currentY = currentY - textHeight - spacing
    end

    -- update height of content scroll frame for instructions
    instructionsScrollContent:SetHeight(math.abs(currentY) + 10)

    -- reset currentY for FAQ section
    currentY = -10

    -- loop over faq entries
    for i, faqentry in ipairs(faq) do
        -- bullet
        local bullet = faqScrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        bullet:SetPoint("TOPLEFT", faqScrollContent, "TOPLEFT", 10, currentY)
        bullet:SetText(("%d."):format(i))
        bullet:SetJustifyH("LEFT")

        -- create instruction label
        local stepLabel = faqScrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        stepLabel:SetPoint("TOPLEFT", bullet, "TOPLEFT", 20, 0)
        stepLabel:SetPoint("RIGHT", faqScrollContent, "RIGHT", -10, 0)
        stepLabel:SetText(string.format("%s", faqentry))
        stepLabel:SetJustifyH("LEFT")
        stepLabel:SetWordWrap(true)

        -- calculate height needed for wrapped text
        local textHeight = stepLabel:GetStringHeight()
        currentY = currentY - textHeight - spacing
    end

    return instructionsFrame
end