--[[ Just storying stuff for later! ]]



--[[ Big Blizzard Bear - Mount
    Could be just a fluke from an old action bar placement? This is the data the addon captured:
    
    ["41"] = {
        unknownActionType = true,
        blizData = {},
        buttonActionID = 41,
        subType = "MOUNT",
        originalSourceID = 58983,
        name = "Unknown",
        barPosn = 5,
        sourceID = -1,
        actionType = "companion",
        icon = -1,
        btnName = "MultiBarLeftButton5"
    },

    If I re-add the bear then same error about "companion" didn't show up.
]]



--[[function ABSync:ProcessSpell(inputButtonID, inputSpellID)
    -- button ID is required
    if not inputButtonID then
        return {
            msg = "Error: No Button ID",
            success = false,
            errors = true,
        }
    end

    -- if spell ID is zero then get from difference record
    if not inputSpellID then inputSpellID = 0 end

    -- if inputSpellID is zero then get spellID from difference record
    local buttonActionID = 0
    if inputSpellID == 0 then
        
    end

    -- get action details
    local actionDetails = self:GetActionData(buttonActionID, "spell")




    -- review base ID vs source ID and override with base ID
    if diffData.shared.blizData.baseID and diffData.shared.blizData.baseID ~= diffData.shared.sourceID then
        err.id = diffData.shared.blizData.baseID
        --@debug@
        if self:GetDevMode() == true then self:Print(("(%s) Overriding SourceID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"):format("UpdateActionBars", tostring(err.name), tostring(diffData.shared.sourceID), tostring(diffData.shared.blizData.baseID))) end
        --@end-debug@
    end

    -- verify if user has spell
    local hasSpell = self:CharacterHasSpell(err.id)

    -- report error if player does not have the spell
    --@debug@
    -- self:Print("Does player have spell? " .. tostring(hasSpell) .. ", Spell Name: " .. tostring(err.name) .. ", Spell ID: " .. tostring(err.id))
    --@end-debug@
    if hasSpell == self.L["No"] then
        -- update message to show character doesn't have the spell
        err["msg"] = self.L["unavailable"]

        -- insert the error record into tracking table
        table.insert(errors, err)

    -- proceed if player has the spell
    -- make sure we have a name that isn't unknown
    elseif err.name ~= self.L["Unknown"] then
        -- set the action bar button to the spell
        C_Spell.PickupSpell(err.id)
        PlaceAction(tonumber(err.buttonID))
        ClearCursor()

        -- button was updated
        buttonUpdated = true

    -- else should never trigger but set message to not found and add to tracking table
    else
        err["msg"] = self.L["notfound"]
        table.insert(errors, err)
    end
end]]