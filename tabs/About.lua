--[[---------------------------------------------------------------------------
    Function:   CreateAboutFrame
    Purpose:    Create the About frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateAboutFrame(parent)
    -- get language data
    local L = self.localeData

    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create main frame
    local aboutFrame = CreateFrame("Frame", nil, parent)
    aboutFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
    aboutFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, 0)

    -- tooltip text
    data = {
        order = {
            "author",
            "version",
            "supportnote",
            "patreon",
            "coffee",
            "issuenote",
            "issues",
            "localeauthors",
            "localization",
        },
        text = {
            ["author"] = {
                type = "data",
                label = "Author",
                text = C_AddOns.GetAddOnMetadata("ActionBarSync", "Author"),
                disable = true,
                tip = {
                    disable = true,
                    text = "",
                },
            },
            ["version"] = {
                type = "data",
                label = "Version",
                text = C_AddOns.GetAddOnMetadata("ActionBarSync", "Version"),
                disable = true,
                tip = {
                    disable = true,
                    text = ""
                },
            },
            ["supportnote"] = {
                type = "note",
                text = "If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!",
            },
            ["patreon"] = {
                type = "data",
                label = "Patreon",
                text = "https://www.patreon.com/Bryo",
                disable = false,
                tip = {
                    disable = false,
                    text = "If you like this addon and want to support me, please consider becoming a patron."
                }
            },
            ["coffee"] = {
                type = "data",
                label = "Buy Me a Coffee",
                text = "https://www.buymeacoffee.com/mrbryo",
                disable = false,
            },
            ["issuenote"] = {
                type = "note",
                text = "If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits.",
            },
            ["issues"] = {
                type = "data",
                label = "Issues",
                text = "https://github.com/mrbryo/ActionBarSync/issues",
                disable = false,
            },
            ["localeauthors"] = {
                type = "note",
                text = "Another support option is to help with localizations. If you are fluent in other language(s) and would like to help translate this addon, please use the link below. I'm still learning about CurseForge's localization system. My hope, as translations are submitted, they are added automatically and the project deploys a new version. If not, please let me know through a ticket using the issues link above.",
            },
            ["localization"] = {
                type = "data",
                label = "Localization",
                text = "https://legacy.curseforge.com/wow/addons/action-bar-sync/localization",
                disable = false,
                tip = {
                    disable = false,
                    text = "Help translate this addon into your language.",
                },
            }
        }
    }

    -- local store english translators; for debug mode I need a variable to add fake translators
    -- local englishTranslators = {
    --     "mrbryo",
    -- }
    --@debug@
    -- if ActionBarSyncDB.char[self.currentPlayerServerSpec].isDevMode == true then
    --     englishTranslators = {
    --         "mrbryo",
    --         "Johnny",
    --         "Raffi",
    --         "Mordra",
    --         "Khalan",
    --         "Evilbunny",
    --         "Hyesung",
    --         "Guilherme",
    --         "Dmitry",
    --         "Xiaojun",
    --         "Yuchen",
    --     }
    -- end
    --@end-debug@

    -- localizations by data structure
    local localeAuthors = {
        -- {
        --     label = L["English"],
        --     people = englishTranslators
        -- },
        {
            label = L["German"],
            people = {}
        },
        {
            label = L["Spanish (Spain)"],
            people = {}
        },
        {
            label = L["Spanish (Mexico)"],
            people = {}
        },
        {
            label = L["French"],
            people = {}
        },
        {
            label = L["Italian"],
            people = {}
        },
        {
            label = L["Korean"],
            people = {}
        },
        {
            label = L["Portuguese (Brazil)"],
            people = {}
        },
        {
            label = L["Russian"],
            people = {}
        },
        {
            label = L["Chinese (Simplified)"],
            people = {}
        },
        {
            label = L["Chinese (Traditional)"],
            people = {}
        },
    }

    -- start under the portrait unless i have a header which shifts to the right of the portrait
    local topOffset = -50

    -- tracking y offset
    local currentY = -15 

    -- spacing between lines
    local spacing = 15

    -- standard label dimensions
    local labelWidth = 120

    -- spacing between columns
    local columnSpacing = 10

    -- create title for about frame
    local title = aboutFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", aboutFrame, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", aboutFrame, "TOPRIGHT", 0, 0)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText("About")

    -- left hand side
    local leftInsetFrame = CreateFrame("Frame", nil, aboutFrame, "InsetFrameTemplate")
    leftInsetFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    leftInsetFrame:SetWidth(aboutFrame:GetWidth() * 0.6 - 20)
    leftInsetFrame:SetPoint("BOTTOM", aboutFrame, "BOTTOM", 0, 0)

    -- add scroll frame to left hand side
    local leftScrollContainer = CreateFrame("ScrollFrame", nil, leftInsetFrame, "UIPanelScrollFrameTemplate")
    leftScrollContainer:SetPoint("TOPLEFT", leftInsetFrame, "TOPLEFT", 5, -5)
    leftScrollContainer:SetPoint("BOTTOMRIGHT", leftInsetFrame, "BOTTOMRIGHT", -27, 5)

    -- add scroll content frame
    local leftContent = CreateFrame("Frame", nil, leftScrollContainer)
    leftContent:SetWidth(leftScrollContainer:GetWidth() - 20)
    leftContent:SetHeight(leftInsetFrame:GetHeight() - 10)
    leftScrollContainer:SetScrollChild(leftContent)

    -- loop over the data and build the ui
    for _, id in pairs(data.order) do
        -- based on the order table get the data based on the id
        local rowData = data.text[id]

        -- instantiate label
        local label = leftContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")

        -- check type to proceed
        if rowData.type == "note" then
            currentY = currentY - 5
            
            -- insert horizontal rule
            local horizontalRule = leftContent:CreateTexture(nil, "ARTWORK")
            horizontalRule:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
            horizontalRule:SetHeight(10)
            horizontalRule:SetPoint("TOPLEFT", leftContent, "TOPLEFT", spacing, currentY)
            horizontalRule:SetPoint("RIGHT", leftContent, "RIGHT", -spacing, 0)

            -- add note
            label:SetPoint("TOPLEFT", horizontalRule, "BOTTOMLEFT", 0, -spacing)
            label:SetPoint("TOPRIGHT", horizontalRule, "BOTTOMRIGHT", 0, -spacing)
            label:SetJustifyH("LEFT")
            label:SetWordWrap(true)
            label:SetText(rowData.text)
        
            -- update y offset
            currentY = currentY - (label:GetStringHeight() + horizontalRule:GetHeight() + 30)
        elseif rowData.type == "data" then
            -- column 1 is a label
            label:SetPoint("TOPLEFT", leftContent, "TOPLEFT", spacing, currentY)
            label:SetWidth(labelWidth)
            label:SetJustifyH("LEFT")
            label:SetText(rowData.label .. ":")
            
            -- column 2 is an edit box
            local editBox = self:CreateEditBox(leftContent, editBoxWidth, label:GetHeight(), rowData.disable)
            editBox:SetPoint("LEFT", label, "RIGHT", columnSpacing, 0)
            editBox:SetPoint("RIGHT", leftContent, "RIGHT", -spacing, 0)
            editBox:SetText(rowData.text)
        
            -- update y offset
            currentY = currentY - (label:GetStringHeight() + spacing)
        end
    end
    
    -- add spacing at end of scroll area
    leftContent:SetHeight(math.abs(currentY))

    -- reset y offset
    currentY = -15

    -- right hand side frame
    local rightFrame = CreateFrame("Frame", nil, aboutFrame)
    rightFrame:SetPoint("TOPLEFT", leftInsetFrame, "TOPRIGHT", 10, 0)
    rightFrame:SetPoint("BOTTOMLEFT", leftInsetFrame, "BOTTOMRIGHT", 0, 0)
    rightFrame:SetPoint("RIGHT", aboutFrame, "RIGHT", 0, 0)

    -- right hand side label
    local rightLabel = rightFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    rightLabel:SetPoint("TOPLEFT", rightFrame, "TOPLEFT", 0, 0)
    rightLabel:SetPoint("TOPRIGHT", rightFrame, "TOPRIGHT", 0, 0)
    rightLabel:SetHeight(30)
    rightLabel:SetJustifyH("LEFT")
    rightLabel:SetText("Translators")

    -- right hand side frame
    local rightInsetFrame = CreateFrame("Frame", nil, aboutFrame, "InsetFrameTemplate")
    rightInsetFrame:SetPoint("TOPLEFT", rightLabel, "BOTTOMLEFT", 0, 0)
    rightInsetFrame:SetPoint("BOTTOMRIGHT", rightFrame, "BOTTOMRIGHT", 0, 0)

    -- add scroll frame to right hand side
    local rightScrollFrame = CreateFrame("ScrollFrame", nil, rightInsetFrame, "UIPanelScrollFrameTemplate")
    rightScrollFrame:SetPoint("TOPLEFT", rightInsetFrame, "TOPLEFT", 0, 0)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", rightInsetFrame, "BOTTOMRIGHT", -25, 0)

    -- add scroll content frame
    local rightScrollContentFrame = CreateFrame("Frame", nil, rightScrollFrame)
    rightScrollContentFrame:SetSize(rightScrollFrame:GetWidth() - 20, rightInsetFrame:GetHeight() - 10)
    rightScrollFrame:SetScrollChild(rightScrollContentFrame)

    -- thank you
    local thankYou = rightScrollContentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    thankYou:SetPoint("TOPLEFT", rightScrollContentFrame, "TOPLEFT", spacing, -spacing)
    thankYou:SetPoint("TOPRIGHT", rightScrollContentFrame, "TOPRIGHT", -spacing, -spacing)
    thankYou:SetJustifyH("LEFT")
    thankYou:SetText("Please accept this pre-emptive thank you to all community members who help translate this addon into different languages!")
    thankYou:SetWordWrap(true)

    -- reset y offset
    currentY = thankYou:GetHeight() + (spacing * 2)

    -- add translators
    for idxa, localeData in pairs(localeAuthors) do
        -- locale name
        local localeLabel = rightScrollContentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        localeLabel:SetPoint("TOPLEFT", rightScrollContentFrame, "TOPLEFT", spacing, -currentY)
        localeLabel:SetJustifyH("LEFT")
        localeLabel:SetText(ABSync.constants.colors.orange .. localeData.label .. ":|r")
        
        -- update y offset
        -- currentY = currentY + (localeLabel:GetHeight() + 5)

        -- loop over people and build string
        local personText = ""
        local personFound = false
        for idxb, person in pairs(localeData.people) do
            if idxb > 1 then
                personText = personText .. ", "
            end
            personText = personText .. person
            personFound = true
        end

        -- if no translators, show none found
        if personFound == false then
            personText = "None"
        end

        -- create label
        local personLabel = rightScrollContentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        personLabel:SetPoint("TOPLEFT", localeLabel, "TOPRIGHT", spacing, 0)
        personLabel:SetPoint("RIGHT", rightScrollContentFrame, "RIGHT", -spacing, 0)
        personLabel:SetJustifyH("LEFT")
        personLabel:SetWordWrap(true)
        personLabel:SetText(personText)

        -- add extra spacing between locales
        currentY = currentY + personLabel:GetStringHeight() + spacing
    end

    -- add spacing at end of scroll area
    rightScrollContentFrame:SetHeight(currentY)
end