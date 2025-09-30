--[[---------------------------------------------------------------------------
    Function:   AddErrorCell
    Purpose:    Add a cell of error information to the error display.
-----------------------------------------------------------------------------]]
function ABSync:AddErrorCell(parent, data, width, offsetX, isHeader)
    -- default isHeader to false
    isHeader = isHeader or false

    -- determine font type
    local fontType = "GameFontWhiteSmall"
    if isHeader == true then
        fontType = "GameFontGreenSmall"
    end

    -- create cell
    local cell = parent:CreateFontString(nil, "ARTWORK", fontType)

    -- set cell text
    local checkValue = tostring(data) or "-"
    cell:SetText(checkValue)
    
    -- set cell properties
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, 0)
    local labelWidth = (parent:GetWidth() * width)
    -- print("Cell Data: " .. tostring(checkValue) .. " Width: " .. tostring(labelWidth))
    -- print("Row Width/Max Width: " .. tostring(labelWidth) .. "/" .. tostring(parent:GetWidth()))
    cell:SetWidth(labelWidth)
    cell:SetJustifyH("LEFT")
    cell:SetWordWrap(true)

    -- return the string height for row height calculation
    return labelWidth, cell:GetStringHeight()
end

--[[---------------------------------------------------------------------------
    Function:   AddErrorRow
    Purpose:    Add a row of error information to the error display.
-----------------------------------------------------------------------------]]
function ABSync:AddErrorRow(parent, data, columns, offsetY, isHeader)
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
    Function:   ProcessLastSyncErrorFrame
    Purpose:    Create the Last Sync Error frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:ProcessLastSyncErrorFrame(parent, tabKey)

    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    local lastErrorGroup, existed = self:ProcessTabContentFrame(tabKey, parent)

    -- if frame existed then just return it, no need to recreate content
    if existed then
        return lastErrorGroup
    end

    -- set frame position
    lastErrorGroup:SetAllPoints(parent)

    -- columns
    local columns = {
        { name = "Bar Name", key = "barName", width = 0.10},        -- 10
        { name = "Bar Pos", key = "barPosn", width = 0.05},         -- 15
        { name = "Button ID", key = "buttonID", width = 0.05},      -- 20
        { name = "Action Type", key = "type", width = 0.10},        -- 30
        { name = "Action Name", key = "name", width = 0.25},        -- 55
        { name = "Action ID", key = "id", width = 0.05},            -- 60
        { name = "Shared By", key = "sharedby", width = 0.15},      -- 75
        { name = "Message", key = "msg", width = 0.20}              -- 95
    }

    -- create title for frame
    local title = lastErrorGroup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", lastErrorGroup, "TOPLEFT", padding, -padding)
    title:SetPoint("TOPRIGHT", lastErrorGroup, "TOPRIGHT", -padding, -padding)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText(ABSync.L["Last Sync Errors"])

    -- create main content frame
    local contentFrame = CreateFrame("Frame", nil, lastErrorGroup, "InsetFrameTemplate")
    contentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    contentFrame:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, 0)
    contentFrame:SetPoint("BOTTOMLEFT", lastErrorGroup, "BOTTOMLEFT", 0, 0)
    contentFrame:SetPoint("BOTTOMRIGHT", lastErrorGroup, "BOTTOMRIGHT", 0, 0)

    -- instantiate initial y offset
    local offsetY = 5

    -- Create header row; important to add the header group to the parent group to maintain a proper layout
    local header = CreateFrame("Frame", nil, contentFrame)
    header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -27, 0)
    header:SetHeight(30)
    local offsetX = padding
    local maxHeight = 0
    local hdrRowHeight = self:AddErrorRow(header, nil, columns, offsetY, true)
    maxHeight = math.max(maxHeight, hdrRowHeight)

    -- update header height
    header:SetHeight(maxHeight + padding)

    -- create a container for the scroll region
    local scrollContainer = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -header:GetHeight())
    scrollContainer:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -27, 0)

    -- create a scroll container for the spreadsheet
    local scrollContent = CreateFrame("Frame", nil, scrollContainer)
    scrollContent:SetWidth(scrollContainer:GetWidth())
    scrollContent:SetHeight(scrollContainer:GetHeight() - padding)
    scrollContainer:SetScrollChild(scrollContent)

    -- get frame width offset between scrollContent and contentFrame
    -- print(("%s Region - Width: %d"):format("Header", header:GetWidth()))
    -- print(("%s Region - Width: %d"):format("Scroll Content", scrollContent:GetWidth()))

    --@debug@
    -- if self:GetDevMode() == true then
    --     local testdttmpretty = date("%Y-%m-%d %H:%M:%S")
    --     local testdttmkey = date("%Y%m%d%H%M%S")
    --     ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm = testdttmkey
    --     local testerrors = {}
    --     for i = 1, 10 do
    --         table.insert(testerrors, {barName = "Test Bar", barPos = i, buttonID = i, actionType = "spell", name = "Test Spell", id = 12345, msg = "Test Error Message"})
    --     end
    --     table.insert(ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors, {
    --         key = testdttmkey,
    --         errors = testerrors
    --     })
    -- end
    --@end-debug@

    -- verify if we a last sync error
    local errorsExist = false
    if not ActionBarSyncDB.char then
        errorsExist = false
    else
        local lastDateTime = ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm or L["Never"]
        if lastDateTime ~= nil and lastDateTime ~= self.L["Never"] then
            errorsExist = true
        end
    end
    --@debug@
    -- if self:GetDevMode() == true then self:Print(("Errors Exist: %s"):format(tostring(errorsExist))) end
    --@end-debug@

    -- instantiate initial y offset
    offsetY = 5
    
    -- loop over sync errors
    --[[ 
        errorRcd contains the following properties:
            property        description
            --------------- --------------------------------------------------------
            key             has a value of a date and time string
            errors          is a table containing error records

        errors contains the following:
            property        description
            --------------- --------------------------------------------------------
            barPos          the action is in which button in the action bars; action bars have buttons 1 to 12
            type            the action type
            name            the name of the action
            barName         the name of the action bar it resides
            id              the ID of the action
            msg             the error message
            sharedby        the player who shared the action
            buttonID        the blizzard designation for the button; all buttons are stored in a single array so 1 to N where N is the number of action bars times 12
    ]]
    if errorsExist == true then
        for _, errorRcd in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors) do
            -- print("here1")
            -- continue to next row if key doesn't match
            if errorRcd.key == ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm then
                -- print("here2")
                -- loop over the rows
                for _, errorRow in ipairs(errorRcd.errors) do
                    -- print("here3")
                    local rowHeight = self:AddErrorRow(scrollContent, errorRow, columns, offsetY)
                    offsetY = offsetY + rowHeight + padding
                    -- local fakelabel = scrollContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    -- fakelabel:SetText("Fake Info")
                    -- fakelabel:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
                    -- fakelabel:SetJustifyH("LEFT")
                    -- fakelabel:SetWidth(200)
                end
            end
        end
    end
end