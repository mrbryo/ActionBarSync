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
function ABSync:GetFlyoutDetails(flyoutID)
    --@debug@
    self:Print(("Getting details for Flyout ID: %s"):format(tostring(flyoutID)))
    --@end-debug@
    -- fetch blizzard flyout details
    local flyoutResult = self:SafeWoWAPICall(GetFlyoutInfo, flyoutID)
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
    -- self:Print(("Flyout ID: %s, Name: %s, Descr: %s, Error Text: %s"):format(tostring(flyoutID), tostring(flyoutName), tostring(flyoutDescription), tostring(errorText)))

    -- find the spell book slot for the flyout
    local includeHidden, includeFlyouts, includeFutureSpells, includeOffSpec = true, true, true, true
    local spellBookItemSlotIndex, spellBookItemSpellBank = C_SpellBook.FindSpellBookSlotForSpell(flyoutID, includeHidden, includeFlyouts, includeFutureSpells, includeOffSpec)

    -- get spell book item link
    -- local spellBookItemLink = C_SpellBook.GetSpellBookItemLink(spellBookItemSlotIndex, spellBookItemSpellBank)

    -- get spellbook item info
    -- local itemType, actionID, spellID = C_SpellBook.GetSpellBookItemType(spellBookItemSlotIndex, spellBookItemSpellBank)

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
    -- self:Print(("Flyout: %s, Spell Book Slot Index: %s, Spell Book Slot Bank: %s"):format(tostring(flyoutID), tostring(spellBookItemSlotIndex), tostring(spellBookItemSpellBank)))
    --@end-debug@

    -- finally return the data collected
    return {
        blizData = {
            name = flyoutName or ABSync.L["Unknown"],
            descr = flyoutDescription or ABSync.L["Unknown"],
            numSlots = numSlots or 0,
            isKnown = isKnown and ABSync.L["Yes"] or ABSync.L["No"],
            spellData = spellData or {},
            spellBook = {
                slotIndex = spellBookItemSlotIndex,
                spellBank = spellBookItemSpellBank,
            },
        },
        flyoutID = flyoutID,
        errorText = errorText
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetItemDetails
    Purpose:    Retrieve item information based on the item ID.
-----------------------------------------------------------------------------]]
function ABSync:GetItemDetails(itemID)
    -- fetch blizzard item details
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(itemID)

    -- need a string as itemName or error occurs if the item actually doesn't exist
    local checkItemName = itemName or L["Unknown"]

    -- does player have the item
    local itemCount = self:GetItemCount(itemID)

    -- if checkItemName is unknown then see if its a toy
    local isToy = false
    local toyData = {}
    local toyID, toyName, toyIcon, toyIsFavorite, toyHasFanfare, toyItemQuality = C_ToyBox.GetToyInfo(itemID)
    if toyName then
        -- is toy usable?
        local toyUsable = C_ToyBox.IsToyUsable(itemID)

        -- get toy ID by using the toy index
        local toyInfo = self:GetToyIDs(itemID)

        -- print(("toy found: %s (%s)"):format(tostring(toyName or ABSync.L["Unknown"]), toyID))
        checkItemName = toyName or ABSync.L["Unknown"]
        isToy = true
        toyData = {
            id = toyID,
            name = toyName,
            icon = toyIcon,
            isFavorite = toyIsFavorite,
            hasFanfare = toyHasFanfare,
            quality = toyItemQuality,
            usable = toyUsable and ABSync.L["Yes"] or ABSync.L["No"],
            index = toyInfo.index or -1,
            toyID = toyInfo.id or -1,
        }
    end

    -- finally return the data collected
    return {
        blizData = {
            itemName = itemName or ABSync.L["Unknown"],
            itemLink = itemLink or ABSync.L["Unknown"],
            itemQuality = itemQuality or ABSync.L["Unknown"],
            itemLevel = itemLevel or -1,
            itemMinLevel = itemMinLevel or -1,
            itemType = itemType or ABSync.L["Unknown"],
            itemSubType = itemSubType or ABSync.L["Unknown"],
            itemStackCount = itemStackCount or -1,
            itemEquipLoc = itemEquipLoc or ABSync.L["Unknown"],
            itemTexture = itemTexture or -1,
            sellPrice = sellPrice or -1,
            classID = classID or -1,
            subclassID = subclassID or -1,
            bindType = bindType or -1,
            expansionID = expansionID or -1,
            setID = setID or -1,
            isCraftingReagent = isCraftingReagent or false,
        },
        itemID = itemID,
        finalItemName = checkItemName,
        isToy = isToy,
        toyData = toyData,
        userItemCount = itemCount,
        hasItem = (itemCount > 0 or toyData.usable) and ABSync.L["Yes"] or ABSync.L["No"],
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMacroDetails
    Purpose:    Retrieve macro information based on the macro ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMacroDetails(macroID)
    -- get language data
    local L = self.L

    -- get macro information: name, iconTexture, body
    -- isLocal removed in patch 3.0.2
    local macroName, iconTexture, body = GetMacroInfo(macroID)

    -- macro type: general or character
    local macroType = ABSync.macroType.general
    if tonumber(macroID) > 120 then
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
        id = macroID,
        hasMacro = macroName and L["Yes"] or L["No"],
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetMountinfo
    Purpose:    Retrieve mount information based on the action ID.
-----------------------------------------------------------------------------]]
function ABSync:GetMountinfo(mountID)
    -- set language variable
    local L = self.L

    -- first call to get mount information based on the action bar action id
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, sourceMountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)

    -- make sure certain values are not nil
    name = name or L["Unknown"]

    -- get more mount data looking for how to pickup a mount with the cursor correctly
    local displayIDs = C_MountJournal.GetAllCreatureDisplayIDsForMountID(mountID)

    -- get mount location in journal
    local mountJournalIndex = self:MountIDToOriginalIndex(mountID)

    -- get more mount data!!!
    local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)
    local extraInfo = {
        creatureDisplayInfoID = creatureDisplayInfoID or -1,
        description = description or L["Unknown"],
        source = source or L["Unknown"],
        isSelfMount = isSelfMount or false,
        mountTypeID = mountTypeID or -1,
        uiModelSceneID = uiModelSceneID or -1,
        animID = animID or -1,
        spellVisualKitID = spellVisualKitID or -1,
        disablePlayerMountPreview = disablePlayerMountPreview or false
    }

    -- and get more data!!!
    local mountCreatureDisplayInfoLink = self.L["Unknown"]
    if spellID then
        mountCreatureDisplayInfoLink = C_MountJournal.GetMountLink(spellID)
    end

    -- get the mountID to displayIndex mapping
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
            mountID = sourceMountID or -1,
            isSteadyFlight = isSteadyFlight or false
        },
        name = name or L["Unknown"],
        sourceID = sourceMountID or -1,
        displayIndex = displayIndex or -1,
        mountID = mountID,
        displayIDs = displayIDs or {},
        extraInfo = extraInfo or {},
        displayInfoLink = mountCreatureDisplayInfoLink,
        mountJournalIndex = mountJournalIndex or -1,
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetPetDetails
    Purpose:    Retrieve pet information based on the pet ID.
-----------------------------------------------------------------------------]]
function ABSync:GetPetDetails(petID)
    -- get language data
    local L = self.L

    -- requires a pet GUID
    local allPetIDs = C_PetJournal.GetOwnedPetIDs()

    -- was a valid pet id found
    local petFound = false

    -- see if petID is in the list
    for _, ownedPetID in ipairs(allPetIDs) do
        if ownedPetID == petID then
            -- print(("Pet ID %s found!"):format(tostring(petID)))
            petFound = true
            break
        end
    end

    -- get pet information
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable
    if petFound == true then
        speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(petID)
    end

    -- finally return the data collected
    return {
        blizData = {
            speciesID = speciesID or -1,
            customName = customName or L["Unknown"],
            level = level or -1,
            xp = xp or -1,
            maxXp = maxXp or -1,
            displayID = displayID or -1,
            isFavorite = isFavorite or false,
            name = name or L["Unknown"],
            icon = icon or -1,
            petType = petType or L["Unknown"],
            creatureID = creatureID or -1,
            sourceText = sourceText or L["Unknown"],
            description = description or L["Unknown"],
            isWild = isWild or false,
            canBattle = canBattle or false,
            isTradeable = isTradeable or false,
            isUnique = isUnique or false,
            obtainable = obtainable or false
        },
        petID = petID,
        name = name or L["Unknown"],
        hasPet = name and L["Yes"] or L["No"]
    }
end

--[[---------------------------------------------------------------------------
    Function:   GetSpellDetails
    Purpose:    Retrieve spell information based on the spell ID.
-----------------------------------------------------------------------------]]
function ABSync:GetSpellDetails(spellID)
    -- get spell info: name, iconID, originalIconID, castTime, minRange, maxRange, spellID
    local spellData = C_Spell.GetSpellInfo(spellID)
    local spellName = spellData and spellData.name or ABSync.L["Unknown"]
    local hasSpell = self:CharacterHasSpell(spellID)
    local isTalentSpell = C_Spell.IsClassTalentSpell(spellID) or false
    local isPvpSpell = C_Spell.IsPvPTalentSpell(spellID) or false
    local spellLink = C_Spell.GetSpellLink(spellID) or ABSync.L["Unknown"]
    local baseID = C_Spell.GetBaseSpell(spellID) or -1

    -- finally return the data collected
    return {
        blizData = {
            name = spellData and spellData.name or ABSync.L["Unknown"],
            iconID = spellData and spellData.iconID or -1,
            originalIconID = spellData and spellData.originalIconID or -1,
            castTime = spellData and spellData.castTime or -1,
            minRange = spellData and spellData.minRange or -1,
            maxRange = spellData and spellData.maxRange or -1,
            spellID = spellData and spellData.spellID or -1,
            link = spellLink,
            baseID = baseID,
        },
        name = spellName,
        hasSpell = hasSpell,
        isTalent = isTalentSpell,
        isPvp = isPvpSpell,
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