--[[---------------------------------------------------------------------------
    Localization for Action Bar Sync
    Language: English (US)
-----------------------------------------------------------------------------]]

-- make sure locales variable exists
if not ABSync.locales then
    ABSync.locales = {}
end

-- add the locale
ABSync.locales["enUS"] = {}
local L = ABSync.locales["enUS"]

-- following line is replaced when packaged through curseforge using their localization tool
--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat", handle-unlocalized="english")@

--@do-not-package@ 
--[[ leaving all for development purposes, export from curseforge ]]

-- A
L["About"] = "About"
-- utilities tab; label for action bar selection dropdown
L["Action Bar:"] = "Action Bar:"
-- generic; used in multiple places
L["Action Bar 1"] = "Action Bar 1"
L["Action Bar 2"] = "Action Bar 2"
L["Action Bar 3"] = "Action Bar 3"
L["Action Bar 4"] = "Action Bar 4"
L["Action Bar 5"] = "Action Bar 5"
L["Action Bar 6"] = "Action Bar 6"
L["Action Bar 7"] = "Action Bar 7"
L["Action Bar 8"] = "Action Bar 8"
-- error to indicate data issue in addon to user
L["Action Bar Button '%s' is not recognized as a valid action bar button. Skipping..."] = "Action Bar Button '%s' is not recognized as a valid action bar button. Skipping..."
-- bar identification frame; title for the frame
L["Action Bar Identification Guide"] = "Action Bar Identification Guide"
-- application name
L["Action Bar Sync"] = "Action Bar Sync"
-- popup text for sync cancelled
L["Action Bar Sync has been cancelled."] = "Action Bar Sync has been cancelled."
-- about tab; description for support option to help with localizations
L["Another support option is to help with localizations. If you are fluent in other language(s) and would like to help translate this addon, please use the link below. I'm still learning about CurseForge's localization system. My hope, as translations are submitted, they are added automatically and the project deploys a new version. If not, please let me know through a ticket using the issues link above."] = "Another support option is to help with localizations. If you are fluent in other language(s) and would like to help translate this addon, please use the link below. I'm still learning about CurseForge's localization system. My hope, as translations are submitted, they are added automatically and the project deploys a new version. If not, please let me know through a ticket using the issues link above."
-- about tab; label for author
L["Author"] = "Author"
-- share/sync tab; label for checkbox to auto reset mount filters on sync
L["Automatically Reset Mount Journal Filters"] = "Automatically Reset Mount Journal Filters"

-- B
-- global variable safe name for the backup & restore tab
L["Backup"] = "Backup"
-- restore tab; description at top of tab
L["Backups are stored per character. Select backups by date and time and the action bar (one at a time) to restore. Then click the 'Restore Selected Backup' button."] = "Backups are stored per character. Select backups by date and time and the action bar (one at a time) to restore. Then click the 'Restore Selected Backup' button."
-- restore tab; label for backups available section
L["Backups Available:"] = "Backups Available:"
-- generic; used in multiple places
L["Bar"] = "Bar"
-- dev mode only; info about image and frame size
L["Bar identification frame created - Image: %dx%d, Frame: %dx%d (Resizable)"] = "Bar identification frame created - Image: %dx%d, Frame: %dx%d (Resizable)"
-- generic; used in multiple places
L["Button"] = "Button"
-- used to filter buttons names from the global variables to determine which are action buttons
L["Button%d+$"] = "Button%d+$"
-- about tab; label for buymeacoffee
L["Buy Me a Coffee"] = "Buy Me a Coffee"

-- C
-- share/sync tab; dev mode only; for troubleshooting
L["called from"] = "called from"
-- about tab; label for language
L["Chinese (Simplified)"] = "Chinese (Simplified)"
-- about tab; label for language
L["Chinese (Traditional)"] = "Chinese (Traditional)"
-- dev tab; label for button to clear mount db for this character
L["Clear Character Mount DB"] = "Clear Character Mount DB"
-- utilities tab; label for button to trigger clear action bar
L["Clear Selected Bar"] = "Clear Selected Bar"
-- dev tab; message about button (Manual Action Button Placement) purpose
L["Click the button below to open a dialog that allows you to manually place an action button on your action bars. This is primarily for testing purposes."] = "Click the button below to open a dialog that allows you to manually place an action button on your action bars. This is primarily for testing purposes."
-- dev tab; message about button (Refresh Mount DB) purpose
L["Click the button below to refresh the mount database for this character. DB stores mount data by character for, currently, manual data comparison. Then click the 'Reload UI' button so the data is available in the saved variables file."] = "Click the button below to refresh the mount database for this character. DB stores mount data by character for, currently, manual data comparison. Then click the 'Reload UI' button so the data is available in the saved variables file."
-- main frame; close button label found in footer area
L["Close"] = "Close"

-- D
-- dev tab; title at top of tab
L["Developer"] = "Developer"

-- E
-- share/sync tab; label for checkbox to auto sync on login
L["Enable Sync on Login (no backups occur)"] = "Enable Sync on Login (no backups occur)"
-- popup text for asking for backup name from user
L["Enter a name for this backup:"] = "Enter a name for this backup:"
-- dev tab; info shown to user if the dev frame isn't created
L["Error: devFrame is nil in ProcessDeveloperFrame."] = "Error: devFrame is nil in ProcessDeveloperFrame."
-- processing tab content function; if a tab key is invalid
L["Error: tabKey (%s) provided to ProcessTabContentFrame is invalid or not found."] = "Error: tabKey (%s) provided to ProcessTabContentFrame is invalid or not found."
-- dev mode only; notification that errors exist on the Sync Errors tab
L["Errors Exist"] = "Errors Exist"

-- F
-- about tab; label for language
L["French"] = "French"
-- about tab; label for FAQ section
L["Frequently Asked Questions"] = "Frequently Asked Questions"
-- generic; used in multiple places
L["from"] = "from"

-- G
-- about tab; label for language
L["German"] = "German"
-- action function for flyouts; error text for returning data from function
L["GetFlyoutInfo failed"] = "GetFlyoutInfo failed"

-- H
-- lookup tab; header for history section
L["Has"] = "Has"
-- about tab; localization help request
L["Help translate this addon into your language."] = "Help translate this addon into your language."
-- lookup tab; header for history section
L["History"] = "History"

-- I
-- generic; used in multiple places
L["ID"] = "ID"
-- about tab; issues note
L["If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits."] = "If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits."
-- about tab; support note
L["If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!"] = "If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!"
-- about tab; patreon support note
L["If you like this addon and want to support me, please consider becoming a patron."] = "If you like this addon and want to support me, please consider becoming a patron."
-- intro tab; title for tab
L["Instructions"] = "Instructions"
-- about tab; issues label
L["Issues"] = "Issues"
-- tab name and title for Introduction tab
L["Introduction"] = "Introduction"
-- about tab; label for language
L["Italian"] = "Italian"

-- J

-- K
-- about tab; label for language
L["Korean"] = "Korean"

-- L
-- global variable safe name for the last sync errors tab
L["LastSyncErrors"] = "LastSyncErrors"
-- share/sync tab; label for last scan time
L["Last Scan on this Character"] = "Last Scan on this Character"
-- last sync error tab header and label
L["Last Sync Errors"] = "Last Sync Errors"
-- share/sync tab; label for last sync time
L["Last Sync on this Character"] = "Last Sync on this Character"
-- about tab; localization label
L["Localization"] = "Localization"
-- dev mode only; lookup action tab lookup action triggered
L["Looking up Action - Type: %s - ID: %s"] = "Looking up Action - Type: %s - ID: %s"
-- generic; used in multiple places
L["Lookup"] = "Lookup"
-- lookup tab; section title
L["Lookup & Assign"] = "Lookup & Assign"

-- M
-- dev tab; area title for manual action placement section
L["Manual Action Button Placement"] = "Manual Action Button Placement"
-- dev tab; frame title for mount db section
L["Mount Database"] = "Mount Database"
-- mount db cleared message
L["Mount DB Cleared! Reload the UI by using the button (to update data now) or wait to logout on this character."] = "Mount DB Cleared! Reload the UI by using the button (to update data now) or wait to logout on this character."
-- mount db refreshed message
L["Mount DB Refreshed! Reload the UI by using this command: /reload"] = "Mount DB Refreshed! Reload the UI by using this command: /reload"
-- notify user mount filter has been reset
L["Mount Journal filters have been set to show all collected mounts."] = "Mount Journal filters have been set to show all collected mounts."

-- N
-- generic; used in multiple places
L["Name"] = "Name"
-- generic; used in multiple places
L["Never"] = "Never"
-- generic; used in multiple places
L["No"] = "No"
-- restore tab; populate action bar drop down when no backups are found
L["No Action Bars Backed Up"] = "No Action Bars Backed Up"
-- restore tab; shown when no backups are found in the listing where backups would go
L["No Backups Found"] = "No Backups Found"
-- restore tab; shown when no backups are selected
L["No Backups Selected"] = "No Backups Selected"
-- restore tab; shown when no note is found for a backup
L["No Description"] = "No Description"
-- default text for flyout data fetch
L["No Error"] = "No Error"
-- share/sync tab; shown when no shared action bars are found from other characters
L["No Shared Action Bars Found"] = "No Shared Action Bars Found"

-- O
-- share/sync tab; label for checkbox to remove current action button on placement failure
L["On Placement Failure Remove Current Action Button"] = "On Placement Failure Remove Current Action Button"

-- P
-- about tab; label for patreon
L["Patreon"] = "Patreon"
-- lookup tab; button to trigger action placement on action bar
L["Place Action"] = "Place Action"
-- thank you for any translation work by others
L["Please accept this pre-emptive thank you to all community members who help translate this addon into different languages!"] = "Please accept this pre-emptive thank you to all community members who help translate this addon into different languages!"
-- about tab; label for language
L["Portuguese (Brazil)"] = "Portuguese (Brazil)"

-- Q

-- R
-- dev tab; label for button to refresh mount db for this character
L["Refresh Mount DB"] = "Refresh Mount DB"
-- dev tab; label for button to reload the ui
L["Reload UI"] = "Reload UI"
-- utilities tab; frame title
L["Remove Action Bar Buttons"] = "Remove Action Bar Buttons"
-- share/sync tab; label for button to reset mount filters
L["Reset Mount Filters"] = "Reset Mount Filters"
-- restore tab; title for the entire tab
L["Restore"] = "Restore"
-- restore tab; label for area to pick action bar to restore when a backup is selected
L["Restore one Action Bar per Click:"] = "Restore one Action Bar per Click:"
-- about tab; label for language
L["Russian"] = "Russian"

-- S
-- lookup tab; shown when an edit box is updated to show the value was saved
L["Saved!"] = "Saved!"
-- share/sync tab; button to trigger a scan of the action bars on the current character
L["Scan Now"] = "Scan Now"
-- restore tab; label for action bar selection dropdown
L["Select Action Bar to Restore:"] = "Select Action Bar to Restore:"
-- share/sync tab; title for action bar listing
L["Select Action Bars to Share"] = "Select Action Bars to Share"
-- global variable safe name for the share & sync tab
L["ShareSync"] = "ShareSync"
-- share/sync tab; title for tab
L["Share & Sync"] = "Share & Sync"
-- footer button for showing the action bar guide picture
L["Show Action Bar Guide"] = "Show Action Bar Guide"
-- about tab; label for language
L["Spanish (Mexico)"] = "Spanish (Mexico)"
-- about tab; label for language
L["Spanish (Spain)"] = "Spanish (Spain)"
-- share/sync tab; title for area to pick whom to sync from
L["Sync Action Bars From"] = "Sync Action Bars From"
-- share/sync tab; button to trigger a sync of the action bars on the current character
L["Sync Now"] = "Sync Now"

-- T
-- intro description for lookup tab
L["This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."] = "This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."
-- dev tab; notification to non deveveloper users
L["This tab is used for development purposes only."] = "This tab is used for development purposes only."
-- about tab; title for translator section
L["Translators"] = "Translators"
-- generic; used in multiple places
L["Type"] = "Type"

-- U
-- generic; used in multiple places
L["Unknown"] = "Unknown"
-- utilities tab; title for the tab
L["Utilities"] = "Utilities"

-- V
-- about tab; label for version
L["Version"] = "Version"

-- W
L["Warning"] = "Warning"

-- X

-- Y
-- generic; used in multiple places
L["Yes"] = "Yes"
-- popup text for no action bars selected to sync
L["You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."] = "You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."

-- Z

-- Other
L["(%s) Overriding Button Action ID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"] = "(%s) Overriding Button Action ID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"

-- instructions
L["On the |cff00ff00%s|r tab click the |cff00ff00%s|r button. An initial scan is required for the addon to function. It should have a date/time to show a scan has already been done. The addon should perform a scan before it does any work. Eventually, the |cff00ff00%s|r button will be removed."] = "On the |cff00ff00%s|r tab click the |cff00ff00%s|r button. An initial scan is required for the addon to function. It should have a date/time to show a scan has already been done. The addon should perform a scan before it does any work. Eventually, the |cff00ff00%s|r button will be removed."
L["Definition: Source Character - A character which has action bars you want to share with other characters."] = "Definition: Source Character - A character which has action bars you want to share with other characters."
L["Definition: Target Character - A character which will receive action bar data from one or more source characters."] = "Definition: Target Character - A character which will receive action bar data from one or more source characters."
L["On the |cff00ff00%s|r tab for each Source Character, check each Action Bar you want to share in the |cff00ff00%s|r section."] = "On the |cff00ff00%s|r tab for each Source Character, check each Action Bar you want to share in the |cff00ff00%s|r section."
L["On the |cff00ff00%s|r tab for each Target Character, check each Action Bar you want to update from one or more Source Characters in the |cff00ff00%s|r section."] = "On the |cff00ff00%s|r tab for each Target Character, check each Action Bar you want to update from one or more Source Characters in the |cff00ff00%s|r section."
L["On the |cff00ff00%s|r tab, once the previous step is done, click the |cff00ff00%s|r button to sync your action bars. If you want your bars auto synced, enable the |cff00ff00%s|r option."] = "On the |cff00ff00%s|r tab, once the previous step is done, click the |cff00ff00%s|r button to sync your action bars. If you want your bars auto synced, enable the |cff00ff00%s|r option."
L["Done!"] = "Done!"

-- FAQ
L["If an action button does not sync and an error for the same button isn't on the '%s' tab, it means the action can't be picked up and placed through Blizzard's API via this addon. Trying to figure out how to capture pickup or placement failures."] = "If an action button does not sync and an error for the same button isn't on the '%s' tab, it means the action can't be picked up and placed through Blizzard's API via this addon. Trying to figure out how to capture pickup or placement failures."
L["Be sure to open all sources of action bar buttons in order for the game to load that particular data into the game memory so the WoW API can access it. For example, if you have a toy on an action button, open your toy box. You won't see any addon or WoW errors, but the addon won't be able to capture or place the toy on the action button and no errors will be recorded. All sources could be spells, items, toys, mounts, pets and macros. If you forget to do this, just rescan and then try syncing again after opening all game content."] = "Be sure to open all sources of action bar buttons in order for the game to load that particular data into the game memory so the WoW API can access it. For example, if you have a toy on an action button, open your toy box. You won't see any addon or WoW errors, but the addon won't be able to capture or place the toy on the action button and no errors will be recorded. All sources could be spells, items, toys, mounts, pets and macros. If you forget to do this, just rescan and then try syncing again after opening all game content."

-- Dev Only
L["(ProcessSyncCheckbox) Failed to Translate Bar Name! Please report as an issue. Using: "] = "(ProcessSyncCheckbox) Failed to Translate Bar Name! Please report as an issue. Using: "
L["(%s) self.ui.frame.syncContent does not exist, cannot process sync region."] = "(%s) self.ui.frame.syncContent does not exist, cannot process sync region."

-- header for sync errors
L["Bar Name"] = "Bar Name"
L["Bar Pos"] = "Bar Pos"
L["Button ID"] = "Button ID"
L["Action Type"] = "Action Type"
L["Action Name"] = "Action Name"
L["Action ID"] = "Action ID"
L["Shared By"] = "Shared By"
L["Message"] = "Message"

-- action types
L["Spell"] = "Spell"
L["Item"] = "Item"
L["Macro"] = "Macro"
L["Pet"] = "Pet"
L["Mount"] = "Mount"
L["Flyout"] = "Flyout"
--@end-do-not-package@