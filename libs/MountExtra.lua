--[[ ------------------------------------------------------------------------
	Title: 			MountExtra.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	All functions for handling mount data in support of GetMountInfo in ActionData.lua.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   ClearMountDB
    Purpose:    Clear the mount database for the current character.
-----------------------------------------------------------------------------]]
function ABSync:ClearMountDB()
    -- get playerID
    -- no need to include spec in playerID for mount db since the mounts are not spec-specific
    local playerID = self:GetKeyPlayerServer(true)

    -- set language variable
    local L = self.L

    -- clear the existing mount database
    ActionBarSyncMountDB[playerID] = {}

    -- notify user its done
    self:Print(ABSync.L["Mount DB Cleared! Reload the UI by using the button (to update data now) or wait to logout on this character."])
end

--[[---------------------------------------------------------------------------
    Function:   MountJournalFilterBackup
    Purpose:    Backup the current mount journal filter settings.

    NOT USED YET
-----------------------------------------------------------------------------]]
function ABSync:MountJournalFilterBackup()
    -- backup current filter settings
    ActionBarSyncDB.char[self.currentPlayerServerSpec].mountJournalFilters = {
        collected = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED),
        notCollected = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED),
        unusable = C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE),
    }
end

--[[---------------------------------------------------------------------------
    Function:   MountJournalFilterReset
    Purpose:    Reset the mount journal filter settings to default.
-----------------------------------------------------------------------------]]
function ABSync:MountJournalFilterReset()
    -- reset default filter settings
    C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
    C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, false)
    C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, false)
    C_MountJournal.SetAllSourceFilters(true)
    C_MountJournal.SetSearch("")
    C_MountJournal.SetAllTypeFilters(true)

    -- notify user
    self:Print(ABSync.L["Mount Journal filters have been set to show all collected mounts."])
end

--[[---------------------------------------------------------------------------
    Function:   MountJournalFilterRestore
    Purpose:    Restore the mount journal filter settings from backup.

    NOT USED YET
-----------------------------------------------------------------------------]]
function ABSync:MountJournalFilterRestore()
    -- restore previous filter settings
    if ActionBarSyncDB.char[self.currentPlayerServerSpec].mountJournalFilters then
        C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, ActionBarSyncDB.char[self.currentPlayerServerSpec].mountJournalFilters.collected)
        C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, ActionBarSyncDB.char[self.currentPlayerServerSpec].mountJournalFilters.notCollected)
        C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE, ActionBarSyncDB.char[self.currentPlayerServerSpec].mountJournalFilters.unusable)
    end
end

--[[---------------------------------------------------------------------------
    Function:   MountIdToOriginalIndex
    Purpose:    Get the original index of a mount by its ID.
    Credit:     MountJournalEnhanced authors!

    Usage:      Should call MountJournalFilterReset() before calling this but should add code to let user know if mount is not found and ask if filter should be restored to default or our own "default".
-----------------------------------------------------------------------------]]
function ABSync:MountIDToOriginalIndex(mountID)
    -- get the current number from the journal
    local count = C_MountJournal.GetNumDisplayedMounts()
    for i = 1, count do
        local displayedMountID = select(12, C_MountJournal.GetDisplayedMountInfo(i))
        if displayedMountID == mountID then
            return i
        end
    end

    return nil
end

--[[---------------------------------------------------------------------------
    Function:   RefreshMountDB
    Purpose:    For development purposes only! Refresh the mount database for the current player.
-----------------------------------------------------------------------------]]
function ABSync:RefreshMountDB()
    -- get playerID
    -- no need to include spec in playerID for mount db since the mounts are not spec-specific
    local playerID = self:GetKeyPlayerServer(true)

    -- set language variable
    local L = self.L

    -- clear the existing mount database
    ActionBarSyncMountDB[playerID] = {}

    --[[ create sorted list of mount ID's ]]
    
    -- get all the mount id's
    local mountLookup = C_MountJournal.GetMountIDs()

    -- build table of mount ID's as keys and the index as the key's value
    local reversed = {}
    for journalIndex, journalMountID in pairs(mountLookup) do
        reversed[journalIndex] = journalMountID
    end

    -- build a table of just mount ID's for sorting them
    local keys = {}
    for journalMountID in pairs(reversed) do
        table.insert(keys, journalMountID)
    end

    -- sort the keys
    table.sort(keys)

    -- create sorted mountIDLookup table
    local mountIDLookup = {}
    for _, journalMountID in ipairs(keys) do
        table.insert(mountIDLookup, reversed[journalMountID])
    end

    -- clear unused tables
    wipe(reversed)
    wipe(keys)

    -- loop over sorted mount ID's
    for journalMountID, journalIndex in pairs(mountIDLookup) do
        -- get mount data
        local mountInfo = self:GetMountinfo(journalMountID)

        -- add index to mountInfo and the associated mount ID to confirm data from GetMountinfo aligns with the GetMountIDs function
        mountInfo.journalIndex = journalIndex
        mountInfo.journalMountID = journalMountID

        -- add to table
        table.insert(ActionBarSyncMountDB[playerID], mountInfo)
        -- ActionBarSyncMountDB[playerID][tostring(journalMountID)] = mountInfo
    end

    -- notify user its done
    self:Print(ABSync.L["Mount DB Refreshed! Reload the UI by using this command: /reload"])
end