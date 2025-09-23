--[[---------------------------------------------------------------------------
    Function:   CreateBarIdentificationFrame
    Purpose:    Create a movable frame that displays the action bar identification image.
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
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1)
    
    -- set frame title following addon's color scheme
    frame.TitleText:SetText(("%sAction Bar Identification Guide|r"):format(self.constants.colors.label))
    
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
    if self.db.char.isDevMode == true then 
        self:Print(("Bar identification frame created - Image: %dx%d, Frame: %dx%d"):format(
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
    Purpose:    Create a scrollable content frame for tab content.
    Arguments:  parent - The parent frame to attach this frame to
    Returns:    The created ScrollFrame and its child Frame for content.
-----------------------------------------------------------------------------]]
function ABSync:CreateContentFrame(parent)
    -- add footer
    local footer = CreateFrame("Frame", nil, parent)
    footer:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(40)

    -- add button to show action bar guide
    local guideButton = self:CreateStandardButton(footer, "Show Action Bar Guide", 150, function()
        self:CreateBarIdentificationFrame(parent)
    end)
    guideButton:SetPoint("LEFT", footer, "LEFT", 10, 0)

    -- create close button
    local closeButton = self:CreateStandardButton(footer, "Close", 80, function()
        parent:Hide()
    end)
    local buttonOffset = (footer:GetHeight() - closeButton:GetHeight()) / 2
    closeButton:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", -10, buttonOffset)

    -- create a frame to hold the content
    local contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -15)
    contentFrame:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 0)

    -- return the created frame
    return contentFrame
end

--[[---------------------------------------------------------------------------
    Function:   CreateStandardButton
    Purpose:    Replace AceGUI buttons with standard buttons.
    Arguments:  parent   - The parent frame to attach this frame to
                text     - The button text
                width    - The width of the button
                onClick  - Callback function when the button is clicked
    Returns:    The created Button frame.

Usage example:

    local scanButton = CreateStandardButton(shareFrame, "Scan Now", 100, function()
        ABSync:GetActionBarData()
        -- Update UI
    end)
    scanButton:SetPoint("TOPLEFT", shareFrame, "TOPLEFT", 10, -10)
-----------------------------------------------------------------------------]]
function ABSync:CreateStandardButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    button:SetSize(width or 120, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

--[[---------------------------------------------------------------------------
    Function:   CreateEditBox
    Purpose:    Replace AceGUI edit boxes with standard edit boxes.
    Arguments:  parent   - The parent frame to attach this frame to
                width    - The width of the edit box
                height   - The height of the edit box
                readOnly - Boolean to set if the edit box is read-only
    Returns:    The created EditBox frame.

Usage example:

    local lastScanBox = CreateEditBox(scanFrame, 250, 20, true)
    lastScanBox:SetPoint("TOPLEFT", scanFrame, "TOPLEFT", 10, -40)
    lastScanBox:SetText(self.db.char.lastScan or "Never")
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
    Purpose:    Replace AceGUI checkboxes with standard check buttons.
    Arguments:  parent       - The parent frame to attach this frame to
                text         - The label text for the checkbox
                initialValue - The initial checked state (true/false)
                onChanged    - Callback function when the checkbox state changes
    Returns:    The created CheckButton frame.

Usage example:

----------------------------------------------------------------------------]]
function ABSync:CreateCheckbox(parent, text, initialValue, OnClick)
    -- create checkbox
    local checkbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")

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

ABSync.uniqueID = {
    dropdown = 0,
    checkbox = 0,
    button = 0,
    editbox = 0,
}

ABSync.uniqueIDPrefix = {
    dropdown = "DD",
    checkbox = "CB",
    button = "BTN",
    editbox = "EB",
}

ABSync.uiframetype = {
    dropdown = "dropdown",
    checkbox = "checkbox",
    button = "button",
    editbox = "editbox",
}

function ABSync:GetUniqueID(type, increment)
    if not ABSync.uniqueID[type] then
        ABSync.uniqueID[type] = 0
    end

    if increment then
        ABSync.uniqueID[type] = ABSync.uniqueID[type] + 1
    end

    return "ActionBarSyncUIObjectType" .. self.uniqueIDPrefix[type] .. "Nbr" .. ABSync.uniqueID[type]
end

--[[---------------------------------------------------------------------------
    Function:   CreateDropdown
    Purpose:    Replace AceGUI dropdowns with standard dropdown menus.
    Arguments:  parent          - The parent frame to attach this frame to
                items           - A table of items for the dropdown (key-value pairs)
                initialValue    - The initial selected value
                onSelectionChanged - Callback function when the selection changes
    Returns:    The created Dropdown frame.
    
Usage example:

    local actionTypeDropdown = CreateDropdown(lookupFrame, 
        ABSync:GetActionTypeValues(),
        ABSync:GetLastActionType(),
        function(value)
            ABSync:SetLastActionType(value)
        end
    )
-----------------------------------------------------------------------------]]
function ABSync:CreateDropdown(parent, items, initialValue, onChange, frameName)
    -- check frameName
    if not frameName then
        frameName = self:GetUniqueID(self.uiframetype.dropdown, true)
        -- print("Generated unique frameName for dropdown:", frameName)
    end

    -- create dropdown and set it up
    local dropdown = CreateFrame("DropdownButton", frameName, parent, "WowStyle1DropdownTemplate")
    
    -- store dropdown state
    dropdown.selectedValue = initialValue or ""
    dropdown.selectedText = items[initialValue] or ""
    dropdown.items = items
    
    -- external function; change selected value
    local function SetSelectedValue(key)
        --@debug@
        -- print("(CreateDropdown) SetSelectedValue called with key:", key)
        --@end-debug@
        if dropdown.items[key] then
            dropdown.selectedValue = key
            dropdown.selectedText = dropdown.items[key] or ""
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
        for key, value in pairs(dropdown.items) do
            rootDescription:CreateRadio(value, IsSelectedValue, SetSelectedValue, key)
        end
    end

    -- setup the menu
    dropdown:SetupMenu(GeneratorFunction)

    -- external function; update function
    function dropdown:UpdateItems(newItems, newValue)
        --@debug@
        -- print("(CreateDropdown) New Value:", newValue)
        --@end-debug@
        self.items = newItems
        -- dropdown:SetupMenu(GeneratorFunction)
        SetSelectedValue(newValue)
        dropdown:GenerateMenu()
    end

    -- external function; get selected value
    function dropdown:GetSelectedValue()
        return self.selectedValue
    end

    -- set initial value if provided
    if initialValue and items[initialValue] then
        SetSelectedValue(initialValue)
    end
    
    -- return the created dropdown
    return dropdown
end

--[[---------------------------------------------------------------------------
    Function:   CreateInlineGroup
    Purpose:    Replace AceGUI inline groups with standard frames with a title.
    Arguments:  parent - The parent frame to attach this frame to
                title  - The title text for the group
                width  - The width of the group
                height - The height of the group
    Returns:    The created Frame.
-----------------------------------------------------------------------------]]
function ABSync:CreateInlineGroup(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    frame:SetSize(width or 200, height or 100)
    
    return frame
end

--[[---------------------------------------------------------------------------
    Function:   CreateCustomDialog
    Purpose:    Create a custom dialog frame with adjustable size.
    Arguments:  parent      - The parent frame (optional, defaults to UIParent)
                title       - The title text for the dialog (optional)
                width       - The width of the dialog
                height      - The height of the dialog
                enableDrag  - Boolean, whether the dialog is draggable (optional)
                showOK      - Boolean, show OK button (optional)
                showCancel  - Boolean, show Cancel button (optional)
                onOK        - Function, called when OK is clicked (optional)
                onCancel    - Function, called when Cancel is clicked (optional)
    Returns:    The created dialog frame.
-----------------------------------------------------------------------------]]
--[[
function ABSync:CreateCustomDialog(parent, title, width, height, enableDrag, showOK, showCancel, onOK, onCancel)
    -- check parameters
    parent = parent or UIParent
    enableDrag = enableDrag or false
    showOK = showOK or false
    showCancel = showCancel or false

    -- create the dialog frame with basic settings
    local dialog = CreateFrame("Frame", nil, parent, "BasicFrameTemplateWithInset")
    dialog:SetSize(width or 400, height or 200)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    
    if enableDrag then
        dialog:SetMovable(true)
        dialog:RegisterForDrag("LeftButton")
        dialog:SetScript("OnDragStart", dialog.StartMoving)
        dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    end

    -- Set title if provided
    if title then
        if dialog.TitleText then
            dialog.TitleText:SetText(title)
        else
            local titleText = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            titleText:SetPoint("TOP", dialog, "TOP", 0, -8)
            titleText:SetText(title)
            dialog.TitleText = titleText
        end
    end

    -- OK and Cancel buttons
    local buttonSpacing = 10
    local buttonWidth = 80
    local buttonHeight = 22
    local bottomPadding = 16
    local buttonToFramePadding = 20
    local lastButton = nil

    -- setup OK button
    if showOK == true then
        local okButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
        okButton:SetSize(buttonWidth, buttonHeight)
        okButton:SetText("OK")
        okButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -buttonToFramePadding, bottomPadding)
        okButton:SetScript("OnClick", function()
            if onOK then onOK(dialog) end
            dialog:Hide()
        end)
        lastButton = okButton
        dialog.okButton = okButton
    end

    -- setup Cancel button
    if showCancel == true then
        local cancelButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
        cancelButton:SetSize(buttonWidth, buttonHeight)
        cancelButton:SetText("Cancel")
        if lastButton then
            cancelButton:SetPoint("RIGHT", lastButton, "LEFT", -buttonSpacing, 0)
        else
            cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -buttonToFramePadding, bottomPadding)
        end
        cancelButton:SetScript("OnClick", function()
            if onCancel then onCancel(dialog) end
            dialog:Hide()
        end)
        dialog.cancelButton = cancelButton
    end

    -- return the dialog for further adjustments
    return dialog
end]]

-- EOF