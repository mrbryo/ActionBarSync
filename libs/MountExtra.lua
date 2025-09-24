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
    self:Print("Mount Journal filters have been set to show all collected mounts.")
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