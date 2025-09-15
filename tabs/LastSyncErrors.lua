--[[---------------------------------------------------------------------------
    Function:   CreateLastSyncErrorFrame
    Purpose:    Create the Last Sync Error frame for the addon.
-----------------------------------------------------------------------------]]
function ABSync:CreateLastSyncErrorFrame(parent)
    -- create main frame
    local lastErrorGroup = AceGUI:Create("SimpleGroup")
    lastErrorGroup:SetLayout("Flow")
    lastErrorGroup:SetFullWidth(true)
    lastErrorGroup:SetFullHeight(true)
    parent:AddChild(lastErrorGroup)

    -- columns
    local columns = {
        { name = "Bar Name", key = "barName", width = 0.10},        -- 10
        { name = "Bar Pos", key = "barPosn", width = 0.05},         -- 15
        { name = "Button ID", key = "buttonID", width = 0.05},      -- 20
        { name = "Action Type", key = "type", width = 0.10},        -- 30
        { name = "Action Name", key = "name", width = 0.25},        -- 55
        { name = "Action ID", key = "id", width = 0.05},            -- 60
        { name = "Shared By", key = "sharedby", width = 0.15},      -- 75
        { name = "Message", key = "msg", width = 0.25}              -- 100
    }

    -- Create header row; important to add the header group to the parent group to maintain a proper layout
    local errHeader = AceGUI:Create("SimpleGroup")
    errHeader:SetLayout("Flow")
    errHeader:SetFullWidth(true)
    lastErrorGroup:AddChild(errHeader)
    for _, colDefn in ipairs(columns) do
        local label = AceGUI:Create("Label")
        label:SetText("|cff00ff00" .. colDefn.name .. "|r")
        label:SetRelativeWidth(colDefn.width)
        errHeader:AddChild(label)
    end

    -- create a container for the scroll region
    local errScrollContainer = AceGUI:Create("SimpleGroup")
    errScrollContainer:SetLayout("Fill")
    errScrollContainer:SetFullWidth(true)
    errScrollContainer:SetFullHeight(true)
    lastErrorGroup:AddChild(errScrollContainer)

    -- Create a scroll container for the spreadsheet
    local errScroll = AceGUI:Create("ScrollFrame")
    errScroll:SetLayout("List")
    errScrollContainer:AddChild(errScroll)

    --@debug@
    -- if self.db.char.isDevMode == true then
    --     local testdttmpretty = date("%Y-%m-%d %H:%M:%S")
    --     local testdttmkey = date("%Y%m%d%H%M%S")
    --     self.db.char.lastSyncErrorDttm = testdttmkey
    --     local testerrors = {}
    --     for i = 1, 10 do
    --         table.insert(testerrors, {barName = "Test Bar", barPos = i, buttonID = i, actionType = "spell", name = "Test Spell", id = 12345, msg = "Test Error Message"})
    --     end
    --     table.insert(self.db.char.syncErrors, {
    --         key = testdttmkey,
    --         errors = testerrors
    --     })
    -- end
    --@end-debug@

    -- verify if we a last sync error
    local errorsExist = false
    if not self.db.char then
        errorsExist = false
    else
        local lastDateTime = self.db.char.lastSyncErrorDttm or L["never"]
        if lastDateTime ~= nil and lastDateTime ~= L["never"] then
            errorsExist = true
        end
    end
    --@debug@
    if self.db.char.isDevMode == true then self:Print(("Errors Exist: %s"):format(tostring(errorsExist))) end
    --@end-debug@
    
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
        for _, errorRcd in ipairs(self.db.char.syncErrors) do
            -- print("here1")
            -- continue to next row if key doesn't match
            if errorRcd.key == self.db.char.lastSyncErrorDttm then
                -- print("here2")
                -- loop over the rows
                for _, errorRow in ipairs(errorRcd.errors) do
                    errScroll:AddChild(self:AddErrorRow(errorRow, columns))
                end
            end
        end
    end
end