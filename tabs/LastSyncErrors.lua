--[[ ------------------------------------------------------------------------
	Title: 			LastSyncErrors.lua
	Author: 		mrbryo
	Create Date : 	2025-Oct-03
	Description: 	Building the Last Sync Errors tab in the UI.
-----------------------------------------------------------------------------]]

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
                colVal = ABSync.actionTypeLookup.data[colVal]
            end
        
            -- check for nil
            if colVal == nil then
                colVal = ABSync.L["Unknown"]
            end

            -- check for negative number
            if type(colVal) == "number" and colVal < 0 then
                colVal = 0
            end
            --@debug@
            -- print("ColVal: " .. tostring(colVal))
            --@end-debug@
        end

        -- must dividte the width by 100 to get a proper width between 0 and 1
        local colWidth = colDef.width / 100

        -- create cell
        local cellWidth, cellHeight = self:AddErrorCell(rowGroup, colVal, colWidth, offsetX, isHeader)
        maxHeight = math.max(maxHeight, cellHeight)
        offsetX = offsetX + cellWidth + 5
    end

    -- finally set row height
    rowGroup:SetHeight(maxHeight)

    -- return row height
    return rowGroup:GetHeight()
end

--[[---------------------------------------------------------------------------
    Function:   ProcessErrorData
    Purpose:    Process the error data and populate the scroll frame.
-----------------------------------------------------------------------------]]
function ABSync:ProcessErrorData()
    -- standard variables
    local padding = ABSync.constants.ui.generic.padding

    -- get scroll content frame
    local scrollContentGlobalName = self:GetObjectName("ErrorScrollContent")
    local scrollContent = nil
    if _G[scrollContentGlobalName] then
        scrollContent = _G[scrollContentGlobalName]
    else
        return
    end

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
    if self:GetDevMode() == true then
        self:Print(("%s: %s"):format(ABSync.L["Errors Exist"], tostring(errorsExist)))
    end
    --@end-debug@

    -- instantiate initial y offset
    offsetY = 5

    -- if the scroll frame has children, remove them
    if scrollContent then
        if scrollContent:GetNumChildren() > 0 then
            self:RemoveFrameChildren(scrollContent)
        end
    end
    
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

    -- locate the correct record
    local errorRecords = nil
    if errorsExist == true and scrollContent then
        -- loop over the error records
        for _, errorRcd in ipairs(ActionBarSyncDB.char[self.currentPlayerServerSpec].syncErrors) do
            -- continue to next row if key doesn't match
            if errorRcd.key == ActionBarSyncDB.char[self.currentPlayerServerSpec].lastSyncErrorDttm then
                errorRecords = errorRcd.errors
                --@debug@
                -- if self:GetDevMode() == true then
                    -- self:Print(("Found %d error records for last sync error dated %s"):format(#errorRecords, tostring(errorRcd.key)))
                -- end
                --@end-debug@
                break
            end
        end

        -- process in action bar order
        for _, barID in ipairs(ABSync.actionBarOrder) do
            --@debug@
            -- if self:GetDevMode() == true then
                -- self:Print(("Processing errors for Action Bar: %s"):format(tostring(barID)))
            -- end
            --@end-debug@
            -- process in button order
            for _, barPosn in ipairs(ABSync.constants.actionButtons) do
                --@debug@
                -- if self:GetDevMode() == true then
                    -- self:Print(("Processing errors for Action Bar '%s' and Button Position '%s'."):format(tostring(barID), tostring(barPosn)))
                -- end
                --@end-debug@
                -- force barPosn to a number
                barPosn = tonumber(barPosn)

                -- loop over the rows
                for _, errorRow in ipairs(errorRecords) do
                    -- check the barID and button position
                    if errorRow.barPosn == barPosn and errorRow.barID == barID then
                        --@debug@
                        -- if self:GetDevMode() == true then
                            -- self:Print(("Adding error for Action Bar '%s' and Button Position '%s'."):format(tostring(barID), tostring(barPosn)))
                        -- end
                        --@end-debug@
                        -- add the row
                        local rowHeight = self:AddErrorRow(scrollContent, errorRow, ABSync.columns.errorColumns, offsetY)

                        -- add the row height and padding to the offset
                        offsetY = offsetY + rowHeight + padding

                        -- exist loop to next button 
                        break
                    end
                end
            end
        end

        -- update the scroll content height
        scrollContent:SetHeight(offsetY)
    end
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
    -- local columns = {
    --     { name = "Bar Name", key = "barName", width = 0.10},        -- 10
    --     { name = "Bar Pos", key = "barPosn", width = 0.05},         -- 15
    --     { name = "Button ID", key = "buttonID", width = 0.05},      -- 20
    --     { name = "Action Type", key = "type", width = 0.10},        -- 30
    --     { name = "Action Name", key = "name", width = 0.25},        -- 55
    --     { name = "Action ID", key = "id", width = 0.05},            -- 60
    --     { name = "Shared By", key = "sharedby", width = 0.15},      -- 75
    --     { name = "Message", key = "msg", width = 0.20}              -- 95
    -- }

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
    header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -5)
    header:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -27, 0)
    header:SetHeight(30)
    local offsetX = padding
    local maxHeight = 0
    local hdrRowHeight = self:AddErrorRow(header, nil, ABSync.columns.errorColumns, offsetY, true)
    maxHeight = math.max(maxHeight, hdrRowHeight)

    -- update header height
    header:SetHeight(maxHeight)

    -- create a container for the scroll region
    local scrollContainer = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
    scrollContainer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    scrollContainer:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -27, 0)

    -- create a scroll container for the spreadsheet
    local scrollContentGlobalName = self:GetObjectName("ErrorScrollContent")
    local scrollContent = CreateFrame("Frame", scrollContentGlobalName, scrollContainer)
    scrollContent:SetWidth(scrollContainer:GetWidth())
    scrollContent:SetHeight(scrollContainer:GetHeight() - padding)
    scrollContainer:SetScrollChild(scrollContent)

    -- get frame width offset between scrollContent and contentFrame
    -- print(("%s Region - Width: %d"):format("Header", header:GetWidth()))
    -- print(("%s Region - Width: %d"):format("Scroll Content", scrollContent:GetWidth()))

    --@debug@
    -- if self:GetDevMode() == true then
    --     local testdttmpretty = date("%Y-%m-%d %H:%M:%S")
    --     local testdttmkey = self:GetCurrentDateTime()
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

    -- process the error data
    self:ProcessErrorData()
end