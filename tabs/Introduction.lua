--[[---------------------------------------------------------------------------
    Function:   CreateInstructionsFrame
    Purpose:    Create the Introduction frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateIntroductionFrame(parent)
    -- get instructions
    local instructions = {
        "Open the options and set the correct profile. I suggest to leave the default which is for your current character.",
        "On the |cff00ff00Share|r tab, click the |cff00ff00Scan Now|r button. An initial scan is required for the addon to function.",
        "Optional, on the |cff00ff00Share|r tab, select which action bars to share.",
        "On the |cff00ff00Sync|r tab, select the shared action bars from other characters to update this character's action bars.",
        "On the |cff00ff00Sync|r tab, once the previous step is done, click the |cff00ff00Sync Now|r button to sync your action bars. If you want your bars auto synced, enable the |cff00ff00Auto Sync on Login|r option.",
        "Done!",
    }

    -- FAQ
    local faq = {
        "If an action button does not sync and an error for the same button isn't on the 'Last Sync Errors' tab, it means the action can't be picked up and placed through Blizzard's API via this addon. Trying to figure out how to capture pickup or placement failures.",
    }

    -- set label height
    local labelHeight = 30
    local labelCount = 2

    -- create main instructions frame
    local instructionsFrame = CreateFrame("Frame", nil, parent)
    instructionsFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    instructionsFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- create title for instructions frame
    local title = instructionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", instructionsFrame, "TOPLEFT", 10, -10)
    title:SetPoint("TOPRIGHT", instructionsFrame, "TOPRIGHT", -10, -10)
    title:SetHeight(labelHeight)
    title:SetJustifyH("CENTER")
    title:SetText("Instructions")

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
    faqTitle:SetText("Frequently Asked Questions")

    -- create faq content frame
    local faqInsetFrame = CreateFrame("Frame", nil, instructionsFrame, "InsetFrameTemplate")
    faqInsetFrame:SetWidth(instructionsScrollContent:GetWidth())
    faqInsetFrame:SetPoint("TOPLEFT", faqTitle, "BOTTOMLEFT", 0, 0)
    faqInsetFrame:SetPoint("TOPRIGHT", faqTitle, "BOTTOMRIGHT", 0, 0)
    faqInsetFrame:SetPoint("BOTTOM", instructionsFrame, "BOTTOM", 0, 15)

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

        -- add special button for step 1
        if i == 1 then
            local step1Button = ABSync:CreateStandardButton(instructionsScrollContent, "Open Options", 150, function()
                LibStub("AceConfigDialog-3.0"):Open(ABSync.optionLocName)
            end)
            step1Button:SetPoint("TOPLEFT", stepLabel, "BOTTOMLEFT", 15, -10)
            
            currentY = currentY - step1Button:GetHeight() - spacing -- Account for button height
        end
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

    -- Add FAQ section
    -- local faqFrame = self:CreateInlineGroup(instructionsContent, instructionsContent:GetWidth() - 20, 100)
    -- faqFrame:SetPoint("TOPLEFT", instructionsContent, "TOPLEFT", 10, currentY)

    -- Add FAQ content
    -- local faqLabel = faqFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- faqLabel:SetPoint("TOPLEFT", faqFrame, "TOPLEFT", 15, -25)
    -- faqLabel:SetPoint("TOPRIGHT", faqFrame, "TOPRIGHT", -15, -25)
    -- faqLabel:SetText("New addon and no common questions yet. This is a placeholder.")
    -- faqLabel:SetJustifyH("LEFT")
    -- faqLabel:SetWordWrap(true)

    -- Update FAQ frame height based on content
    -- local faqHeight = faqLabel:GetStringHeight() + 40
    -- faqFrame:SetHeight(faqHeight)
    -- currentY = currentY - faqHeight - 20

    -- Set the content frame height to accommodate all content
    -- instructionsContent:SetHeight(math.abs(currentY) + 20)

    return instructionsFrame
end