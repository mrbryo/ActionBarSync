--[[ ------------------------------------------------------------------------
	Title: 			ActionData.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	All functions for getting action bar button data.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   CharacterHasSpell
    Purpose:    Check if the current character has a specific spell.
-----------------------------------------------------------------------------]]
function ABSync:CharacterHasSpell(spellID)
    -- set language variable
    local L = self.L

    -- find the spell in the player's spell book
    local spellBookItemSlotIndex, spellBookItemSpellBank = C_SpellBook.FindSpellBookSlotForSpell(spellID)

    -- be sure index is not nil
    spellBookItemSlotIndex = spellBookItemSlotIndex or -1

    -- Enum.SpellBookSpellBank is either 0 for Player or 1 for Pet
    spellBookItemSpellBank = spellBookItemSpellBank or -1
    --@debug@
    --print(("Spell: %s, Spell Book Slot Index: %s, Spell Book Slot Bank: %s"):format(tostring(spellID), tostring(spellBookItemSlotIndex), tostring(spellBookItemSpellBank)))
    --@end-debug@

    -- finally return yes or no
    if spellBookItemSlotIndex > 0 then
        return L["Yes"]
    else
        return L["No"]
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetFlyoutDetails
    Purpose:    Retrieve flyout information based on the flyout ID.
-----------------------------------------------------------------------------]]
function ABSync:GetFlyoutDetails(buttonActionID)
    --@debug@
    if self:GetDevMode() == true then
        self:Print(("Getting details for Flyout ID: %s"):format(tostring(buttonActionID)))
    end
    --@end-debug@
    -- fetch blizzard flyout details
    local flyoutResult = self:SafeWoWAPICall(GetFlyoutInfo, buttonActionID)
    local errorText = "No Error"
    local flyoutName = ABSync.L["Unknown"]
    local flyoutDescription = ABSync.L["Unknown"]
    local numSlots = 0
    local isKnown = ABSync.L["No"]
    if not flyoutResult.success then
        errorText = ("GetFlyoutInfo failed: %s"):format(flyoutResult.error)
    else
        -- parse results
        flyoutName = select(1, flyoutResult.result)
        flyoutDescription = select(2, flyoutResult.result)
        numSlots = select(3, flyoutResult.result)
        isKnown = select(4, flyoutResult.result)
    end

    -- fetch blizzard flyout details by slot
    -- self:Print(("Flyout ID: %s, Name: %s, Descr: %s, Error Text: %s"):format(tostring(buttonActionID), tostring(flyoutName), tostring(flyoutDescription), tostring(errorText)))

    -- find the spell book slot for the flyout
    local includeHidden, includeFlyouts, includeFutureSpells, includeOffSpec = true, true, true, true
    local spellBookItemSlotIndex, spellBookItemSpellBank = C_SpellBook.FindSpellBookSlotForSpell(buttonActionID, includeHidden, includeFlyouts, includeFutureSpells, includeOffSpec)

    -- get spell book item link
    -- local spellBookItemLink = C_SpellBook.GetSpellBookItemLink(spellBookItemSlotIndex, spellBookItemSpellBank)

    -- get spellbook item info
    -- local itemType, buttonActionID, spellID = C_SpellBook.GetSpellBookItemType(spellBookItemSlotIndex, spellBookItemSpellBank)

    -- get spell data
    local spellData = C_Spell.GetSpellInfo(flyoutName)

    -- if spellData and spellData.name then
    --     print("Flyout Spell Name: " .. spellData.name)
    -- else
    --     print("Flyout Spell Name not found")
    -- end

    -- be sure values are not nil
    spellBookItemSlotIndex = spellBookItemSlotIndex or -1
    spellBookItemSpellBank = spellBookItemSpellBank or -1
    -- --@debug@
    -- self:Print(("Flyout: %s, Spell Book Slot Index: %s, Spell Book Slot Bank: %s"):format(tostring(buttonActionID), tostring(spellBookItemSlotIndex), tostring(spellBookItemSpellBank)))
    --@end-debug@

    -- finally return the data collected
    return {
        blizData = {
            -- GetFlyoutInfo
            flyoutInfo = {
                name = flyoutName or ABSync.L["Unknown"],
                descr = flyoutDescription or ABSync.L["Unknown"],
                numSlots = numSlots or 0,
                isKnown = isKnown and ABSync.L["Yes"] or ABSync.L["No"],    
            },
            -- C_SpellBook.FindSpellBookSlotForSpell
            spellBookSlot = {
                index = spellBookItemSlotIndex,
                bank = spellBookItemSpellBank,
            },
            -- C_Spell.GetSpellInfo           
            spellData = spellData or {},
        },
        buttonActionID = buttonActionID,
        errorText = errorText,
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetItemCount
    Purpose:    Retrieve the item count for a specific button ID.
-----------------------------------------------------------------------------]]
function ABSync:GetItemCount(id)
    local itemCount = C_Item.GetItemCount(id)
    return itemCount
end

--[[---------------------------------------------------------------------------
    Function:   GetItemDetails
    Purpose:    Retrieve item information based on the item ID.
-----------------------------------------------------------------------------]]
function ABSync:GetItemDetails(buttonActionID)
    -- fetch blizzard item details
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(buttonActionID)

    -- does player have the item
    local itemCount = self:GetItemCount(buttonActionID)

    --[[ get toy information ]]

    -- instantiate toy variables
    local isToy = false
    local toyID, toyName, toyIcon, toyIsFavorite, toyHasFanfare, toyItemQuality = C_ToyBox.GetToyInfo(buttonActionID)
    local qualityGlobalString = ABSync.L["Unknown"]

    -- get quality text if data is returned
    if toyItemQuality and type(toyItemQuality) == "number" then
        qualityGlobalString = _G["ITEM_QUALITY"..(toyItemQuality).."_DESC"] or ABSync.L["Unknown"]
    end

    -- create data structure for toy data
    local toyData = {
        id = toyID or -1,
        name = toyName or ABSync.L["Unknown"],
        icon = toyIcon or -1,
        isFavorite = toyIsFavorite or false,
        hasFanfare = toyHasFanfare or false,
        quality = toyItemQuality or -1,
        qualityText = qualityGlobalString,
    }
    
    -- if it is a toy then get additional details
    local toyUsable = false
    local toyIndex = -1
    local toyID = -1
    if toyName then
        -- is toy usable?
        toyUsable = C_ToyBox.IsToyUsable(buttonActionID)

        -- get toy ID by using the toy index
        local toyInfo = self:GetToyIDs(buttonActionID)

        -- print(("toy found: %s (%s)"):format(tostring(toyName or ABSync.L["Unknown"]), toyID))
        isToy = true
        toyIndex = toyInfo.index or -1
        toyID = toyInfo.id or -1
    end

    -- finally return the data collected
    return {
        blizData = {
            -- C_Item.GetItemInfo
            itemInfo = {
                name = itemName or ABSync.L["Unknown"],
                link = itemLink or ABSync.L["Unknown"],
                quality = itemQuality or ABSync.L["Unknown"],
                level = itemLevel or -1,
                minLevel = itemMinLevel or -1,
                type = itemType or ABSync.L["Unknown"],
                subType = itemSubType or ABSync.L["Unknown"],
                stackCount = itemStackCount or -1,
                equipLoc = itemEquipLoc or ABSync.L["Unknown"],
                texture = itemTexture or -1,
                sellPrice = sellPrice or -1,
                classID = classID or -1,
                subclassID = subclassID or -1,
                bindType = bindType or -1,
                expansionID = expansionID or -1,
                setID = setID or -1,
                isCraftingReagent = isCraftingReagent or false,
            },
            -- C_ToyBox.GetToyInfo
            toyInfo = toyData,
            -- C_ToyBox.IsToyUsable
            toyUsable = toyUsable and ABSync.L["Yes"] or ABSync.L["No"],
            -- GetToyIDs (custom function)
            toyIndex = toyIndex,
            ndex,
            toyID = toyID,
        },
        buttonActionID = buttonActionID,
        isToy = isToy,
        userItemCount = itemCount,
        has = (itemCount > 0 or toyUsable) and ABSync.L["Yes"] or ABSync.L["No"],
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMacroDetails
    Purpose:    Retrieve macro information based on the macro ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMacroDetails(buttonActionID)
    -- blizzard api; get macro information: name, iconTexture, body
    -- isLocal removed in patch 3.0.2
    local macroName, iconTexture, body = GetMacroInfo(buttonActionID)
    --@debug@
    -- print(("Macro ID: %s, Name: %s"):format(tostring(macroID), tostring(macroName or ABSync.L["Unknown"])))
    --@end-debug@

    -- macro type: general or character
    local macroType = ABSync.macroType.general
    if tonumber(buttonActionID) > 120 then
        macroType = ABSync.macroType.character
    end

    -- finally return the data collected
    return {
        blizData = {
            name = macroName or L["Unknown"],
            icon = iconTexture or -1,
            body = body or L["Unknown"]
        },
        macroType = macroType,
        buttonActionID = buttonActionID,
        hasMacro = macroName and L["Yes"] or L["No"],
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMountinfo
    Purpose:    Retrieve mount information based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMountinfo(buttonActionID)
    -- first call to get mount information based on the action bar action id
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, sourceMountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(buttonActionID)

    -- make sure certain values are not nil
    name = name or ABSync.L["Unknown"]

    -- get more mount data looking for how to pickup a mount with the cursor correctly
    local displayIDs = C_MountJournal.GetAllCreatureDisplayIDsForMountID(buttonActionID)

    -- get mount location in journal
    local mountJournalIndex = self:MountIDToOriginalIndex(buttonActionID)

    -- get more mount data!!!
    local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(buttonActionID)
    local extraInfo = {
        creatureDisplayInfoID = creatureDisplayInfoID or -1,
        description = description or ABSync.L["Unknown"],
        source = source or ABSync.L["Unknown"],
        isSelfMount = isSelfMount or false,
        mountTypeID = mountTypeID or -1,
        uiModelSceneID = uiModelSceneID or -1,
        animID = animID or -1,
        spellVisualKitID = spellVisualKitID or -1,
        disablePlayerMountPreview = disablePlayerMountPreview or false
    }

    -- and get more data!!!
    local mountCreatureDisplayInfoLink = ABSync.L["Unknown"]
    if spellID then
        mountCreatureDisplayInfoLink = C_MountJournal.GetMountLink(spellID)
    end

    -- get the buttonActionID to displayIndex mapping
    local mountLookup = C_MountJournal.GetMountIDs()

    -- loop over the values to get the key
    -- TODO: This might be unnecessary if we always use mountJournalIndex
    --       but keeping it for now in case we need it later
    local displayIndex = -1
    for journalIndex, journalMountID in pairs(mountLookup) do
        if journalMountID == mountID then
            displayIndex = journalIndex
            break
        end
    end

    --@debug@
    -- if self:GetDevMode() == true then self:Print(("Mount Name: %s - ID: %s - Display Index: %s"):format(name, mountID, tostring(displayIndex))) end
    --@end-debug@

    -- finally return the spell name
    return {
        blizData = {
            -- GetMountInfoByID
            mountInfo = {
                name = name,
                spellID = spellID or -1,
                icon = icon or -1,
                isActive = isActive or false,
                isUsable = isUsable or false,
                sourceType = sourceType or -1,
                isFavorite = isFavorite or false,
                isFactionSpecific = isFactionSpecific or false,
                faction = faction or -1,
                shouldHideOnChar = shouldHideOnChar or false,
                isCollected = isCollected or false,
                sourceMountID = sourceMountID or -1,
                isSteadyFlight = isSteadyFlight or false,
            },
            -- GetAllCreatureDisplayIDsForMountID
            displayIDs = displayIDs or {},
            -- GetMountInfoExtraByID
            extraInfo = extraInfo or {},
            -- GetMountLink
            mountLink = mountCreatureDisplayInfoLink or ABSync.L["Unknown"],    -- was displayInfoLink and was outside of blizData by one level
        },
        displayIndex = displayIndex or -1,
        buttonActionID = buttonActionID,
        mountJournalIndex = mountJournalIndex or -1,
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetPetDetails
    Purpose:    Retrieve pet information based on the pet ID.
-----------------------------------------------------------------------------]]
function ABSync:GetPetDetails(buttonActionID)
    -- requires a pet GUID
    local allPetIDs = C_PetJournal.GetOwnedPetIDs()

    -- was a valid pet id found
    local petFound = false

    -- see if buttonActionID is in the list
    for _, ownedPetID in ipairs(allPetIDs) do
        if ownedPetID == buttonActionID then
            -- print(("Pet ID %s found!"):format(tostring(buttonActionID)))
            petFound = true
            break
        end
    end

    -- get pet information
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable
    if petFound == true then
        speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(buttonActionID)
    end

    -- finally return the data collected
    return {
        blizData = {
            speciesID = speciesID or -1,
            customName = customName or ABSync.L["Unknown"],
            level = level or -1,
            xp = xp or -1,
            maxXp = maxXp or -1,
            displayID = displayID or -1,
            isFavorite = isFavorite or false,
            name = name or ABSync.L["Unknown"],
            icon = icon or -1,
            petType = petType or ABSync.L["Unknown"],
            creatureID = creatureID or -1,
            sourceText = sourceText or ABSync.L["Unknown"],
            description = description or ABSync.L["Unknown"],
            isWild = isWild or false,
            canBattle = canBattle or false,
            isTradeable = isTradeable or false,
            isUnique = isUnique or false,
            obtainable = obtainable or false
        },
        buttonActionID = buttonActionID,
        hasPet = name and ABSync.L["Yes"] or ABSync.L["No"]
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetSpellDetails
    Purpose:    Retrieve spell information based on the spell ID.
-----------------------------------------------------------------------------]]
function ABSync:GetSpellDetails(buttonActionID)
    -- get spell info: name, iconID, originalIconID, castTime, minRange, maxRange, buttonActionID
    local spellData = C_Spell.GetSpellInfo(buttonActionID)
    local spellName = spellData and spellData.name or ABSync.L["Unknown"]
    local hasSpell = self:CharacterHasSpell(buttonActionID)
    local isTalentSpell = C_Spell.IsClassTalentSpell(buttonActionID) or false
    local isPvpSpell = C_Spell.IsPvPTalentSpell(buttonActionID) or false
    local spellLink = C_Spell.GetSpellLink(buttonActionID) or ABSync.L["Unknown"]
    local baseID = C_Spell.GetBaseSpell(buttonActionID) or -1

    -- review base ID vs source ID and override with base ID
    local overrideWithBaseID = false
    if baseID > 0 and baseID ~= buttonActionID then
        --@debug@
        if self:GetDevMode() == true then self:Print(("(%s) Overriding Button Action ID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"):format("GetSpellDetails", tostring(spellName), tostring(buttonActionID), tostring(baseID))) end
        --@end-debug@
        overrideWithBaseID = true
    end

    -- finally return the data collected
    return {
        blizData = {
            name = spellName,
            iconID = spellData and spellData.iconID or -1,
            originalIconID = spellData and spellData.originalIconID or -1,
            castTime = spellData and spellData.castTime or -1,
            minRange = spellData and spellData.minRange or -1,
            maxRange = spellData and spellData.maxRange or -1,
            spellID = spellData and spellData.spellID or -1,
            link = spellLink,
            baseID = baseID,
        },
        buttonActionID = buttonActionID,
        hasSpell = hasSpell,
        isTalent = isTalentSpell,
        isPvp = isPvpSpell,
        overrideWithBaseID = overrideWithBaseID,
    }
end

--[[ --------------------------------------------------------------------------
    Function:   GetToyIDs
    Purpose:    Retrieve the toy index by using the toy item ID...and then get the toy ID from that index. Seems like it is always the same ID either way? But now after doing this search toys are being added to the action bar correctly.
-----------------------------------------------------------------------------]]
function ABSync:GetToyIDs(toyID)
    local count = C_ToyBox.GetNumFilteredToys()
    local toyIndex = -1
    local displayedToyID = -1
    
    for i = 1, count do
        displayedToyID = C_ToyBox.GetToyFromIndex(i)
        -- local toyData = C_ToyBox.GetToyFromIndex(i)

        -- for k, v in pairs(toyData) do
        --     print(("Toy Key: %s, Value: %s"):format(tostring(k), tostring(v)))
        -- end

        if displayedToyID == toyID then
            -- print("toy found - index: " .. i .. ", id: " .. displayedToyID)
            toyIndex = i
            break
        end
    end

    return { id = displayedToyID, index = toyIndex }
end