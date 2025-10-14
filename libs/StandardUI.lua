--[[---------------------------------------------------------------------------
    Function:   CreateBarIdentificationFrame
    Purpose:    Create a movable and resizable frame that displays the action bar identification image.
-----------------------------------------------------------------------------]]
function ABSync:CreateBarIdentificationFrame(positionFrame, offsetX, offsetY)
    -- Check if frame already exists to prevent duplicates
    if self.ui.frame.barIdentification and self.ui.frame.barIdentification:IsShown() then
        return
    end

    -- if positionFrame is nil then set it to the UIParent
    if not positionFrame then
        positionFrame = UIParent
    end

    -- Create a temporary texture to get the image dimensions
    local tempTexture = UIParent:CreateTexture()
    tempTexture:SetTexture("Interface\\AddOns\\ActionBarSync\\assets\\action-bar-sync-bar-identification.png")
    
    -- Get the actual image dimensions
    local imageWidth = 1732 / 2
    local imageHeight = 994 / 2
    
    -- Clean up temporary texture
    tempTexture:Hide()
    tempTexture = nil

    -- Set frame padding for title bar and borders
    local framePadding = 50  -- Extra space for title and borders
    local titleBarHeight = 30
    local frameWidth = imageWidth + framePadding
    local frameHeight = imageHeight + framePadding + titleBarHeight

    -- create main frame with standard WoW frame template with close button
    local frame = CreateFrame("Frame", nil, positionFrame, "BasicFrameTemplateWithInset")

    -- set frame properties using actual image dimensions
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("CENTER", positionFrame, "CENTER", offsetX or 0, offsetY or 0)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1)
    
    -- Set minimum and maximum size constraints
    local minWidth, minHeight = 300, 200
    local maxWidth, maxHeight = 2000, 1500
    frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
    
    -- Create resize button in bottom-right corner
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeButton:SetScript("OnMouseUp", function(self, button)
        frame:StopMovingOrSizing()
    end)
    
    -- set frame title following addon's color scheme
    frame.TitleText:SetText(("%s%s|r"):format(self.constants.colors.label, ABSync.L["Action Bar Identification Guide"]))
    
    -- create texture to display the image using actual dimensions
    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", frame.InsetBorderTop, "BOTTOMLEFT", 10, -10)
    texture:SetPoint("BOTTOMRIGHT", frame.InsetBorderBottom, "TOPRIGHT", -10, 10)
    
    -- Set the texture to your image file
    texture:SetTexture("Interface\\AddOns\\ActionBarSync\\assets\\action-bar-sync-bar-identification.png")
    texture:SetTexCoord(0, 1, 0, 1) -- Use full texture coordinates
    
    -- Store frame reference in UI table following addon pattern
    if not self.ui.frame then
        self.ui.frame = {}
    end
    self.ui.frame.barIdentification = frame
    
    -- Show the frame
    frame:Show()
    
    --@debug@
    if self:GetDevMode() == true then 
        self:Print((ABSync.L["Bar identification frame created - Image: %dx%d, Frame: %dx%d (Resizable)"]):format(
            imageWidth or 0, imageHeight or 0, frameWidth, frameHeight))
    end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   ShowBarIdentificationGuide
    Purpose:    Public function to show the bar identification guide frame.
-----------------------------------------------------------------------------]]
function ABSync:ShowBarIdentificationGuide()
    self:CreateBarIdentificationFrame()
end

--[[---------------------------------------------------------------------------
    Function:   CreateContentFrame
    Purpose:    Create the frame for showing the content of each tab. Each tab will have its own frame which extends to this whole frame.
    Arguments:  parent - The parent frame to attach this frame to
    Returns:    The created ScrollFrame and its child Frame for content.
-----------------------------------------------------------------------------]]
function ABSync:CreateContentFrame(parent)
    -- check to see if frame exists already
    if not ActionBarSyncMainFrameTabContent then
        -- add footer; must be created first and anchored in order to properly anchor the contentFrame above it
        local footer = CreateFrame("Frame", "ActionBarSyncMainFrameFooter", parent)
        footer:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        footer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
        footer:SetHeight(40)

        -- create main content frame
        local contentFrame = CreateFrame("Frame", "ActionBarSyncMainFrameTabContent", parent)
        contentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -15)
        contentFrame:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 0)
        
        -- create close button
        local closeButton = self:CreateStandardButton(footer, nil, ABSync.L["Close"], 80, function()
            parent:Hide()
        end)
        local buttonOffset = (footer:GetHeight() - closeButton:GetHeight()) / 2
        closeButton:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", -10, buttonOffset)
    
        -- add button to show action bar guide
        local guideButton = self:CreateStandardButton(footer, nil, ABSync.L["Show Action Bar Guide"], 150, function()
            self:CreateBarIdentificationFrame(parent)
        end)
        guideButton:SetPoint("LEFT", footer, "LEFT", 10, 0)

        

        -- create a frame to hold the content
        local contentFrame = CreateFrame("Frame", nil, parent)
        contentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -15)
        contentFrame:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 0)
    end
end

--[[---------------------------------------------------------------------------
    Function:   ProcessTabContentFrame
    Purpose:    Create a standard content frame for a tab.
    Arguments:  tabKey - When creating the content frame use this to name the frame to lookup the proper 'varname'.
    Returns:    The created Frame for the tab content.
-----------------------------------------------------------------------------]]
function ABSync:ProcessTabContentFrame(tabKey, parent)
    --@debug@
    -- print(("(ProcessTabContentFrame) Called with tabKey: %s"):format(tostring(tabKey)))
    --@end-debug@
    -- get global variable friendly tab name
    local tabID = self.uitabs["varnames"][tabKey] or ABSync.L["Unknown"]

    -- check if nil
    if tabID == ABSync.L["Unknown"] then
        self:Print((ABSync.L["Error: tabKey (%s) provided to ProcessTabContentFrame is invalid or not found."]):format(tostring(tabKey)))
        return nil, false
    end

    -- generate global frame name
    local frameName = self:GetObjectName(ABSync.constants.objectNames.tabContentFrame .. tabID)

    -- report back if it was newly created or not
    local existed = false

    -- create the content frame
    local frame = nil
    if not _G[frameName] then
        frame = CreateFrame("Frame", frameName, parent)
        frame:SetAllPoints(parent)
    else
        frame = _G[frameName]
        existed = true
    end

    -- return the created frame
    return frame, existed
end

--[[---------------------------------------------------------------------------
    Function:   CreateStandardButton
    Purpose:    Standardize button creation.
    Arguments:  parent   - The parent frame to attach this frame to
                text     - The button text
                width    - The width of the button
                onClick  - Callback function when the button is clicked
    Returns:    The created Button frame.
-----------------------------------------------------------------------------]]
function ABSync:CreateStandardButton(parent, buttonName, text, width, onClick)
    local button = CreateFrame("Button", buttonName, parent, "GameMenuButtonTemplate")
    button:SetSize(width or 120, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

--[[---------------------------------------------------------------------------
    Function:   CreateEditBox
    Purpose:    Standardize edit box creation.
    Arguments:  parent   - The parent frame to attach this frame to
                width    - The width of the edit box
                height   - The height of the edit box
                readOnly - Boolean to set if the edit box is read-only
    Returns:    The created EditBox frame.
-----------------------------------------------------------------------------]]
function ABSync:CreateEditBox(parent, width, height, readOnly, onEnter)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(width or 200, height or 20)
    editBox:SetAutoFocus(false)
    
    if readOnly then
        editBox:SetEnabled(false)
        editBox:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    end

    if onEnter then
        editBox:SetScript("OnEnterPressed", function(self)
            onEnter(self) 
        end)
    end
    
    return editBox
end

--[[---------------------------------------------------------------------------
    Function:   SetLabelWithTimer
    Purpose:    Set a label's text and clear it after a specified duration.
    Arguments:  label     - The font string label to update
                text      - The text to display
                duration  - How long to show the text before clearing (optional, default 3 seconds)
                color     - Color table {r, g, b} for the text (optional)
    Returns:    None
-----------------------------------------------------------------------------]]
function ABSync:SetLabelWithTimer(label, text, duration, color)
    if not label then return end
    
    duration = duration or 3.0  -- Default 3 seconds
    
    -- Cancel any existing timer
    if label.clearTimer then
        label.clearTimer:Cancel()
        label.clearTimer = nil
    end
    
    -- Set the text immediately
    label:SetText(text)
    
    -- Set color if provided
    if color then
        label:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
    end
    
    -- Create timer to clear the text
    label.clearTimer = C_Timer.NewTimer(duration, function()
        label:SetText("")
        label.clearTimer = nil
    end)
end

--[[---------------------------------------------------------------------------
    Function:   CreateCheckbox
    Purpose:    Standardize checkbox creation.
    Arguments:  parent       - The parent frame to attach this frame to
                text         - The label text for the checkbox
                initialValue - The initial checked state (true/false)
                onChanged    - Callback function when the checkbox state changes
    Returns:    The created CheckButton frame.
----------------------------------------------------------------------------]]
function ABSync:CreateCheckbox(parent, text, initialValue, frameName, OnClick)
    -- create checkbox
    local checkbox = CreateFrame("CheckButton", frameName, parent, "ChatConfigCheckButtonTemplate")

    -- set its label
    checkbox.Text:SetText(text)

    -- set if its checked or not
    checkbox:SetChecked(initialValue)

    -- set the OnClick event function to the onChanged parameter function
    checkbox:SetScript("OnClick", function(self, button, down)
        local checked = self:GetChecked()
        if OnClick then
            OnClick(self, button, checked)
        end
    end)
    
    -- finally return the checkbox object
    return checkbox
end

--[[---------------------------------------------------------------------------
    Function:   CreateDropdown
    Purpose:    Standardize dropdown creation.
    Arguments:  parent          - The parent frame to attach this frame to
                items           - A table of items for the dropdown (key-value pairs)
                initialValue    - The initial selected value
                onSelectionChanged - Callback function when the selection changes
    Returns:    The created Dropdown frame.
-----------------------------------------------------------------------------]]
function ABSync:CreateDropdown(parent, itemOrder, items, initialValue, frameName, onChange)
    -- create dropdown and set it up
    local dropdown = CreateFrame("DropdownButton", frameName, parent, "WowStyle1DropdownTemplate")
    
    -- store dropdown state
    dropdown.selectedValue = initialValue or ""
    if items == nil then
        dropdown.selectedText = itemOrder[initialValue] or ""
        dropdown.items = itemOrder
    else
        dropdown.selectedText = items[initialValue] or ""
        dropdown.items = items
    end
    dropdown.itemOrder = itemOrder
    
    -- external function; change selected value
    local function SetSelectedValue(key)
        --@debug@
        -- print("(CreateDropdown) SetSelectedValue called with key:", key)
        --@end-debug@
        if dropdown.items[key] then
            dropdown.selectedValue = key
            dropdown.selectedText = dropdown.items[key] or ""
        elseif dropdown.items[key] == nil then
            dropdown.selectedValue = key
            dropdown.selectedText = key
        else
            dropdown.selectedValue = ""
            dropdown.selectedText = ""
        end
        if onChange then
            onChange(key)
        end
    end

    -- function to check if a value is selected
    local function IsSelectedValue(key)
        return dropdown.selectedValue == key
    end

    -- function to build the dropdown menu from the items parameter
    local function GeneratorFunction(dropdown, rootDescription)
        -- add buttons for each item
        -- for key, value in pairs(dropdown.items) do
        for key, value in pairs(dropdown.itemOrder) do
            local radioValue = dropdown.items[value]
            local radioKey = value
            if items == nil then
                radioValue = value
                radioKey = key
            end
            rootDescription:CreateRadio(radioValue, IsSelectedValue, SetSelectedValue, radioKey)
        end
    end

    -- setup the menu
    dropdown:SetupMenu(GeneratorFunction)

    -- external function; update function
    function dropdown:UpdateItems(newItemOrder, newItems, newValue)
        --@debug@
        -- print("(CreateDropdown) New Value:", newValue)
        --@end-debug@
        if newItems == nil then
            self.selectedText = newItemOrder[newValue] or ""
            self.items = newItemOrder
        else
            self.selectedText = newItems[newValue] or ""
            self.items = newItems
        end
        self.itemOrder = newItemOrder
        SetSelectedValue(newValue)
        dropdown:GenerateMenu()
    end

    -- external function; get selected value
    function dropdown:GetSelectedValue()
        return self.selectedValue
    end

    -- set initial value if provided
    if initialValue and dropdown.items[initialValue] then
        SetSelectedValue(initialValue)
    end
    
    -- return the created dropdown
    return dropdown
end

-- EOF