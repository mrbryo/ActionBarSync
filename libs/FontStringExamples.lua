--[[---------------------------------------------------------------------------
    FontString Examples Frame
    Purpose: Display all available FontString objects in the standard WoW UI
-----------------------------------------------------------------------------]]

local ABSync = _G.ABSync

-- List of verified standard WoW FontString objects (current as of retail WoW)
local FONT_OBJECTS = {
    -- Core Game Fonts (VERIFIED - these definitely exist)
    "GameFontNormal",
    "GameFontNormalSmall",
    "GameFontNormalLarge",
    "GameFontNormalHuge",
    
    -- Highlight Fonts (VERIFIED)
    "GameFontHighlight",
    "GameFontHighlightSmall", 
    "GameFontHighlightLarge",
    "GameFontHighlightHuge",
    
    -- Disabled Fonts (VERIFIED)
    "GameFontDisable",
    "GameFontDisableSmall",
    "GameFontDisableLarge",
    
    -- Colored Fonts (VERIFIED)
    "GameFontGreen",
    "GameFontGreenSmall",
    "GameFontGreenLarge",
    "GameFontRed",
    "GameFontRedSmall", 
    "GameFontRedLarge",
    "GameFontWhite",
    "GameFontWhiteSmall",
    "GameFontDarkGold",
    "GameFontDarkGoldSmall",
    
    -- System Fonts (VERIFIED - core ones that still exist)
    "SystemFont_Small",
    "SystemFont_Med1",
    "SystemFont_Med2", 
    "SystemFont_Med3",
    "SystemFont_Large1",
    "SystemFont_Large2",
    "SystemFont_Huge1",
    "SystemFont_Shadow_Small",
    "SystemFont_Shadow_Med1",
    "SystemFont_Shadow_Med2",
    "SystemFont_Shadow_Med3",
    "SystemFont_Shadow_Large",
    "SystemFont_Shadow_Huge1",
    "SystemFont_OutlineThick_Huge2",
    "SystemFont_OutlineThick_Huge4",
    "SystemFont_OutlineThick_WTF",
    
    -- Number Fonts (VERIFIED)
    "NumberFont_GameNormal",
    "NumberFont_Normal_Med",
    "NumberFont_Outline_Med",
    "NumberFont_Outline_Large", 
    "NumberFont_Outline_Huge",
    "NumberFont_Shadow_Med",
    "NumberFont_Shadow_Small",
    
    -- Chat Fonts (VERIFIED)
    "ChatFontNormal",
    "ChatFontSmall",
    
    -- Tooltip Fonts (VERIFIED)
    "Tooltip_Med",
    "Tooltip_Small",
    
    -- Quest Fonts (VERIFIED - these still exist)
    "QuestFont_Large",
    "QuestFont_Huge", 
    "QuestFont_Super_Huge",
    "QuestFont_Outline_Huge",
    "QuestFont_Shadow_Huge",
    
    -- Zone/PvP Fonts (VERIFIED)
    "ZoneTextFont",
    "SubZoneTextFont",
    "PVPInfoTextFont",
    
    -- Special Purpose Fonts (VERIFIED)
    "ErrorFont",
    "CombatTextFont",
    "MailFont_Large",
    "SplashHeaderFont",
    "FancyFont",
    
    -- Modern WoW Fonts (ADDED - these are current)
    "Game12Font",
    "Game13Font", 
    "Game15Font",
    "Game18Font",
    "Game24Font",
    "Game27Font",
    "Game30Font",
    "Game32Font",
    "Game36Font",
    "Game48Font",
    "Game60Font",
    "Game72Font",
    "GameFont_Gigantic",
    "GameTooltipText",
    "GameTooltipTextSmall",
    "GameTooltipHeaderText",
    
    -- Blizzard UI Specific (VERIFIED - used in current UI)
    "BossEmoteNormalHuge",
    "CoreAbilityFont",
    "DestinyFontLarge", 
    "DestinyFontHuge",
    "InvoiceFont_Med",
    "InvoiceFont_Small",
    "ReputationDetailFont",
    "AchievementFont_Small",
    "Fancy12Font",
    "Fancy14Font",
    "Fancy16Font",
    "Fancy18Font",
    "Fancy20Font",
    "Fancy22Font",
    "Fancy24Font",
    "Fancy27Font",
    "Fancy30Font",
    "Fancy32Font",
    "Fancy48Font",
    
    -- Objective/Quest Related (VERIFIED)
    "ObjectiveFont",
    
    -- Cinematic Fonts (VERIFIED)
    "CinematicTextFont",
    
    -- Nameplate Fonts (MODERN - for current nameplate system)
    "SystemFont_NamePlate",
    "SystemFont_LargeNamePlate", 
    "SystemFont_NamePlateFixed",
    "SystemFont_LargeNamePlateFixed",
}

function ABSync:CreateFontStringExamplesFrame()
    -- Create main frame
    local frame = CreateFrame("Frame", "FontStringExamplesFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    
    -- Set title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("WoW FontString Examples")
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    
    -- Create content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth() - 20)
    scrollFrame:SetScrollChild(content)
    
    -- Create search box
    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -5)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("Search fonts...")
    
    -- Search functionality
    local originalFonts = {}
    for i, fontName in ipairs(FONT_OBJECTS) do
        originalFonts[i] = fontName
    end
    
    local function filterFonts(searchText)
        if not searchText or searchText == "" or searchText == "Search fonts..." then
            return originalFonts
        end
        
        local filtered = {}
        searchText = searchText:lower()
        for _, fontName in ipairs(originalFonts) do
            if fontName:lower():find(searchText) then
                table.insert(filtered, fontName)
            end
        end
        return filtered
    end
    
    local function createFontExamples(fontList)
        -- Clear existing content
        for i = 1, content:GetNumChildren() do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        local yOffset = -10
        local leftColumnWidth = 300
        local baseRowPadding = 10 -- Minimum padding between rows
        
        -- Header
        local headerName = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        headerName:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
        headerName:SetText("Font Name")
        headerName:SetTextColor(1, 0.82, 0) -- Gold
        
        local headerExample = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        headerExample:SetPoint("TOPLEFT", content, "TOPLEFT", leftColumnWidth, yOffset)
        headerExample:SetText("Example Text")
        headerExample:SetTextColor(1, 0.82, 0) -- Gold
        
        -- Calculate header height and adjust yOffset
        local headerHeight = math.max(headerName:GetStringHeight(), headerExample:GetStringHeight())
        yOffset = yOffset - headerHeight - 15
        
        -- Create horizontal rule
        local rule = content:CreateTexture(nil, "ARTWORK")
        rule:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
        rule:SetHeight(8)
        rule:SetPoint("LEFT", content, "LEFT", 10, yOffset)
        rule:SetPoint("RIGHT", content, "RIGHT", -10, yOffset)
        
        yOffset = yOffset - 20
        
        -- Create font examples with dynamic row heights
        for i, fontName in ipairs(fontList) do
            -- Check if font object exists
            local fontObj = _G[fontName]
            if fontObj then
                -- Font name label
                local nameLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                nameLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
                nameLabel:SetText(fontName)
                nameLabel:SetTextColor(0.7, 0.7, 1) -- Light blue
                
                -- Example text using the font
                local exampleText = content:CreateFontString(nil, "OVERLAY", fontName)
                exampleText:SetPoint("TOPLEFT", content, "TOPLEFT", leftColumnWidth, yOffset)
                exampleText:SetText("The quick brown fox jumps over the lazy dog. 1234567890")
                
                -- Calculate the height needed for this row
                local nameLabelHeight = nameLabel:GetStringHeight()
                local exampleTextHeight = exampleText:GetStringHeight()
                local rowHeight = math.max(nameLabelHeight, exampleTextHeight) + baseRowPadding
                
                -- Alternate row background - size it based on calculated row height
                if i % 2 == 0 then
                    local bg = content:CreateTexture(nil, "BACKGROUND")
                    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
                    bg:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset + (baseRowPadding / 2))
                    bg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, yOffset + (baseRowPadding / 2))
                    bg:SetHeight(rowHeight)
                end
                
                -- Add copy button for each font
                local copyBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
                copyBtn:SetSize(40, 18)
                copyBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -20, yOffset - (rowHeight / 4))
                copyBtn:SetText("Copy")
                copyBtn:SetScript("OnClick", function()
                    print("Font name copied: " .. fontName)
                    if ChatEdit_GetActiveWindow() then
                        ChatEdit_GetActiveWindow():Insert(fontName)
                    end
                end)
                
                -- Update yOffset for next row
                yOffset = yOffset - rowHeight
            end
        end
        
        -- Set content height based on actual content
        content:SetHeight(math.abs(yOffset) + 20)
    end
    
    -- Search box events
    searchBox:SetScript("OnEnterPressed", function(self)
        local searchText = self:GetText()
        local filteredFonts = filterFonts(searchText)
        createFontExamples(filteredFonts)
        self:ClearFocus()
    end)
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Search fonts..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Search fonts...")
            self:SetTextColor(0.5, 0.5, 0.5)
        end
    end)
    
    -- Clear search button
    local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(60, 20)
    clearButton:SetPoint("LEFT", searchBox, "RIGHT", 5, 0)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("Search fonts...")
        searchBox:SetTextColor(0.5, 0.5, 0.5)
        createFontExamples(originalFonts)
    end)
    
    -- Copy button functionality
    local function createCopyButton(parent, fontName)
        local copyBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        copyBtn:SetSize(40, 18)
        copyBtn:SetText("Copy")
        copyBtn:SetScript("OnClick", function()
            -- Simple way to "copy" - could enhance with a popup showing the font name
            print("Font name copied to chat: " .. fontName)
            if ChatEdit_GetActiveWindow() then
                ChatEdit_GetActiveWindow():Insert(fontName)
            end
        end)
        return copyBtn
    end
    
    -- Initial population
    createFontExamples(originalFonts)
    
    -- Add info label
    local infoLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 5)
    infoLabel:SetText(string.format("Showing %d font objects | Use search to filter", #FONT_OBJECTS))
    infoLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Store frame reference
    self.fontExamplesFrame = frame
    
    return frame
end

function ABSync:VerifyFontObjects()
    local validFonts = {}
    local invalidFonts = {}
    
    for _, fontName in ipairs(FONT_OBJECTS) do
        local fontObj = _G[fontName]
        if fontObj and type(fontObj) == "table" and fontObj.GetFont then
            table.insert(validFonts, fontName)
        else
            table.insert(invalidFonts, fontName)
        end
    end
    
    print("Valid fonts:", #validFonts)
    print("Invalid fonts:", #invalidFonts)
    
    if #invalidFonts > 0 then
        print("Invalid font objects:")
        for _, name in ipairs(invalidFonts) do
            print("  " .. name)
        end
    end
    
    return validFonts, invalidFonts
end

-- Slash command to show the frame
SLASH_FONTEXAMPLES1 = "/fontexamples"
SLASH_FONTEXAMPLES2 = "/fonts"
SlashCmdList["FONTEXAMPLES"] = function()
    if ABSync and ABSync.CreateFontStringExamplesFrame then
        local frame = ABSync:CreateFontStringExamplesFrame()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    end
end