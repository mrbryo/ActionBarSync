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
--@localization(locale="enUS", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="english")@

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
-- options panel
L["Action Bar Sync Options"] = "Action Bar Sync Options"
L["Action Bar Sync allows you to synchronize action bar configurations between your characters."] = "Action Bar Sync allows you to synchronize action bar configurations between your characters."
L["You can open the Action Bar Sync interface using the following slash commands:"] = "You can open the Action Bar Sync interface using the following slash commands:"
L["Open Action Bar Sync"] = "Open Action Bar Sync"
-- minimap button
L["Click to open ActionBarSync"] = "Click to open ActionBarSync"
L["Right-click for options"] = "Right-click for options"

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
-- Generic; used in multiple places, normally cancel buttons.
L["Cancel"] = "Cancel"
-- about tab; label for language
L["Chinese (Simplified)"] = "Chinese (Simplified)"
-- about tab; label for language
L["Chinese (Traditional)"] = "Chinese (Traditional)"
-- Dev tab; label for button to clear mount db for this character. Tab is only visible if a developer uses special command line value.
L["Clear Character Mount DB"] = "Clear Character Mount DB"
-- utilities tab; label for button to trigger clear action bar
L["Clear Selected Bar"] = "Clear Selected Bar"
-- Dev tab; UI message about button (Manual Action Button Placement) purpose. Tab is only visible if a developer uses special command line value.
L["Click the button below to open a dialog that allows you to manually place an action button on your action bars. This is primarily for testing purposes."] = "Click the button below to open a dialog that allows you to manually place an action button on your action bars. This is primarily for testing purposes."
-- Dev tab; UI message about button (Refresh Mount DB) purpose. Tab is only visible if a developer uses special command line value.
L["Click the button below to refresh the mount database for this character. DB stores mount data by character for, currently, manual data comparison. Then click the 'Reload UI' button so the data is available in the saved variables file."] = "Click the button below to refresh the mount database for this character. DB stores mount data by character for, currently, manual data comparison. Then click the 'Reload UI' button so the data is available in the saved variables file."
-- Main frame; close button label found in footer area.
L["Close"] = "Close"

-- D
-- Share/sync tab; default text for the backup name edit box in the popup when is triggered from clicking the sync button.
L["Default Name"] = "Default Name"
-- Dev tab; title at top of tab. Tab is only visible if a developer uses special command line value.
L["Developer"] = "Developer"

-- E
-- Share/sync tab; label for checkbox to auto sync on login.
L["Enable Sync on Login (no backups occur)"] = "Enable Sync on Login (no backups occur)"
-- Popup text for asking for backup name from user during manual sync.
L["Enter a name for this backup:"] = "Enter a name for this backup:"
-- Dev tab; info shown to user if the dev frame isn't created.
L["Error: devFrame is nil in ProcessDeveloperFrame."] = "Error: devFrame is nil in ProcessDeveloperFrame."
-- Processing tab content function; if a tab key is invalid. User can then open an issue.
L["Error: tabKey (%s) provided to ProcessTabContentFrame is invalid or not found."] = "Error: tabKey (%s) provided to ProcessTabContentFrame is invalid or not found."
-- Dev mode only; notification errors exist on the Sync Errors tab.
L["Errors Exist"] = "Errors Exist"
-- Share/sync tab; error text for checking the placement error clear button value. Other info appended to this string.
L["Error Setting Placement Error Clear Button to: %s for %s!"] = "Error Setting Placement Error Clear Button to: %s for %s!"

-- F
-- Share/sync tab; popup body message when no differences found to sync.
L["For the action bars flagged for syncing, no differences were found."] = "For the action bars flagged for syncing, no differences were found."
-- About tab; label for French language.
L["French"] = "French"
-- About tab; label for FAQ section.
L["Frequently Asked Questions"] = "Frequently Asked Questions"
-- Generic; used in multiple places; simply a lower case 'from', that's it.
L["from"] = "from"

-- G
-- About tab; label for German language.
L["German"] = "German"
-- Action function for flyouts; error text for returning data from function. Other info appended to this string.
L["GetFlyoutInfo failed"] = "GetFlyoutInfo failed"

-- H
-- Lookup tab; header for history section. If user has the action or not.
L["Has"] = "Has"
-- About tab; localization help request.
L["Help translate this addon into your language."] = "Help translate this addon into your language."
-- Lookup tab; header for history section.
L["History"] = "History"

-- I
-- Generic; used in multiple places.
L["ID"] = "ID"
-- About tab; issues note.
L["If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits."] = "If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits."
-- About tab; support note.
L["If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!"] = "If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!"
-- About tab; patreon support note.
L["If you like this addon and want to support me, please consider becoming a patron."] = "If you like this addon and want to support me, please consider becoming a patron."
-- Intro tab; title for tab.
L["Instructions"] = "Instructions"
-- Introduction tab, tab name and title.
L["Introduction"] = "Introduction"
-- About tab; issues label.
L["Issues"] = "Issues"
-- About tab; label for Italian language.
L["Italian"] = "Italian"

-- J

-- K
-- About tab; label for Korean language.
L["Korean"] = "Korean"

-- L
-- Share/sync tab; label for last scan time.
L["Last Scan on this Character"] = "Last Scan on this Character"
-- Last sync error tab, header and label.
L["Last Sync Errors"] = "Last Sync Errors"
-- Share/sync tab; label for last sync time.
L["Last Sync on this Character"] = "Last Sync on this Character"
-- Global variable safe name for the last sync errors tab.
L["LastSyncErrors"] = "LastSyncErrors"
-- About tab; localization label.
L["Localization"] = "Localization"
-- Dev mode only; on lookup action tab when lookup action triggered.
L["Looking up Action - Type: %s - ID: %s"] = "Looking up Action - Type: %s - ID: %s"
-- Generic; used in multiple places.
L["Lookup"] = "Lookup"
-- Lookup tab; section title.
L["Lookup & Assign"] = "Lookup & Assign"

-- M
-- Dev tab; area title for manual action placement section.
L["Manual Action Button Placement"] = "Manual Action Button Placement"
-- Dev tab; frame title for mount db section.
L["Mount Database"] = "Mount Database"
-- Dev tab, mount db cleared message.
L["Mount DB Cleared! Reload the UI by using the button (to update data now) or wait to logout on this character."] = "Mount DB Cleared! Reload the UI by using the button (to update data now) or wait to logout on this character."
-- Dev tab, mount db refreshed message.
L["Mount DB Refreshed! Reload the UI by using this command: /reload"] = "Mount DB Refreshed! Reload the UI by using this command: /reload"
-- Notify user mount filter has been reset.
L["Mount Journal filters have been set to show all collected mounts."] = "Mount Journal filters have been set to show all collected mounts."
-- Share/sync tab; used in response for trying to place an action button during a sync; mount successfully picked up so we record its index value
L["Mount Journal Index: "] = "Mount Journal Index: "

-- N
-- Generic; used in multiple places.
L["Name"] = "Name"
-- Generic; used in multiple places.
L["Never"] = "Never"
-- Generic; used in multiple places.
L["No"] = "No"
-- Restore tab; populates action bar drop down when no backups are found.
L["No Action Bars Backed Up"] = "No Action Bars Backed Up"
-- Restore tab; shown when no backups are found in the listing where backups would go.
L["No Backups Found"] = "No Backups Found"
-- Restore tab; shown when no backups are selected.
L["No Backups Selected"] = "No Backups Selected"
-- Restore tab; shown when no note is found for a backup.
L["No Description"] = "No Description"
-- Default text for flyout data fetch.
L["No Error"] = "No Error"
-- Share/sync tab; shown when no shared action bars are found from other characters.
L["No Shared Action Bars Found"] = "No Shared Action Bars Found"
-- Share/sync tab; used in response for trying to place an action button during a sync; cursor empty means game not able to pick up the action button to place it or remove it
L["Not Placed - Cursor Empty!"] = "Not Placed - Cursor Empty!"
-- Share/sync tab; used in response for trying to place an action button during a sync; shared macro successfully picked up
L["Picked Up - General Macro"] = "Picked Up - General Macro"
-- Share/sync tab; used in response for trying to place an action button during a sync; item is identified as a toy but character can't use it
L["Not Picked Up - Item is a toy but not usable by character!"] = "Not Picked Up - Item is a toy but not usable by character!"
-- Share/sync tab; used in response for trying to place an action button during a sync; item is not a toy and not in player's inventory
L["Not Picked Up - Item is not a toy and not in inventory!"] = "Not Picked Up - Item is not a toy and not in inventory!"
-- Share/sync tab; used in response for trying to place an action button during a sync; invalid action id
L["Not Picked Up - Invalid Action ID!"] = "Not Picked Up - Invalid Action ID!"
-- Share/sync tab; used in response for trying to place an action button during a sync; invalid shared action id
L["Not Picked Up - Invalid Shared Action ID!"] = "Not Picked Up - Invalid Shared Action ID!"
-- Share/sync tab; used in response for trying to place an action button during a sync; macro is character specific
L["Not Picked Up - Macro from sync is character specific!"] = "Not Picked Up - Macro from sync is character specific!"
-- Share/sync tab; used in response for trying to place an action button during a sync; mount not found
L["Not Picked Up - Mount not found! May need to reset mount filters and sync again."] = "Not Picked Up - Mount not found! May need to reset mount filters and sync again!"
-- Share/sync tab; used in response for trying to place an action button during a sync; character specific macro (or not shared or generic macro) picked up
L["Picked Up - Not Shared Macro"] = "Picked Up - Not Shared Macro"
-- Share/sync tab; used in response for trying to place an action button during a sync; pet not known
L["Not Picked Up - Pet not known!"] = "Not Picked Up - Pet not known!"
-- Share/sync tab; used in response for trying to place an action button during a sync; spell not known
L["Not Picked Up - Spell not known!"] = "Not Picked Up - Spell not known!"
-- Share/sync tab; used in response for trying to place an action button during a sync; generic unknown reason
L["Not Picked Up - Unknown"] = "Not Picked Up - Unknown"
-- Share/sync tab; used in response for trying to place an action button during a sync; unknown action type
L["Not Picked Up - Unknown Action Type!"] = "Not Picked Up - Unknown Action Type!"


-- O
-- Generic; used in multiple places, normally OK buttons.
L["OK"] = "OK"
-- Share/sync tab; label for checkbox to remove current action button on placement failure.
L["On Placement Failure Remove Current Action Button"] = "On Placement Failure Remove Current Action Button"

-- P
-- About tab; label for patreon.
L["Patreon"] = "Patreon"
-- Share/sync tab; used in response for trying to place an action button during a sync
L["Picked Up"] = "Picked Up"
-- Lookup tab; button to trigger action placement on action bar.
L["Place Action"] = "Place Action"
-- About tab, thank you for any translation work by others.
L["Please accept this pre-emptive thank you to all community members who help translate this addon into different languages!"] = "Please accept this pre-emptive thank you to all community members who help translate this addon into different languages!"
-- About tab; label for Portuguese Brazilian language.
L["Portuguese (Brazil)"] = "Portuguese (Brazil)"

-- Q

-- R
-- Dev tab; label for button to refresh mount db for this character.
L["Refresh Mount DB"] = "Refresh Mount DB"
-- Dev tab; label for button to reload the UI.
L["Reload UI"] = "Reload UI"
-- Utilities tab; frame title.
L["Remove Action Bar Buttons"] = "Remove Action Bar Buttons"
-- Share/sync tab; label for button to reset mount filters.
L["Reset Mount Filters"] = "Reset Mount Filters"
-- Restore tab; title for the entire tab.
L["Restore"] = "Restore"
-- Restore tab; label for area to pick action bar to restore when a backup is selected.
L["Restore one Action Bar per Click:"] = "Restore one Action Bar per Click:"
-- About tab; label for Russian language.
L["Russian"] = "Russian"

-- S
-- Lookup tab; shown when an edit box is updated to show the value was saved.
L["Saved!"] = "Saved!"
-- Share/sync tab; button to trigger a scan of the action bars on the current character.
L["Scan Now"] = "Scan Now"
-- Restore tab; label for action bar selection dropdown.
L["Select Action Bar to Restore:"] = "Select Action Bar to Restore:"
-- Share/sync tab; title for action bar listing. Colon left off intentionally.
L["Select Action Bars to Share"] = "Select Action Bars to Share"
-- Share/sync tab; title for tab.
L["Share & Sync"] = "Share & Sync"
-- Global variable safe name for the share & sync tab title. No spaces!
L["ShareSync"] = "ShareSync"
-- Footer button for showing the action bar guide picture.
L["Show Action Bar Guide"] = "Show Action Bar Guide"
-- About tab; label for Spanish (Mexico) language.
L["Spanish (Mexico)"] = "Spanish (Mexico)"
-- About tab; label for Spanish (Spain) language.
L["Spanish (Spain)"] = "Spanish (Spain)"
-- Share/sync tab; title for area to pick whom to sync from.
L["Sync Action Bars From"] = "Sync Action Bars From"
-- Share/sync tab; button to trigger a sync of the action bars on the current character.
L["Sync Now"] = "Sync Now"

-- T
-- Lookup tab, intro description.
L["This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."] = "This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."
-- Dev tab; notification to non developer users. Tab is only visible if a developer uses special command line value.
L["This tab is used for development purposes only."] = "This tab is used for development purposes only."
-- About tab; title for translator section.
L["Translators"] = "Translators"
-- Generic; used in multiple places.
L["Type"] = "Type"

-- U
-- Generic; used in multiple places.
L["Unknown"] = "Unknown"
-- Utilities tab; title for the tab.
L["Utilities"] = "Utilities"

-- V
-- About tab; label for version.
L["Version"] = "Version"

-- W
-- Dev tab; part of notification to developers. Tab is only visible if a developer uses special command line value.
L["Warning"] = "Warning"

-- X

-- Y
-- Generic; used in multiple places.
L["Yes"] = "Yes"
-- Popup text for no action bars selected to sync.
L["You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."] = "You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."

-- Z

-- Other
L["(%s) Overriding Button Action ID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"] = "(%s) Overriding Button Action ID with BaseID for Spell Name: %s, SourceID: %s, BaseID: %s"

-- Introduction tab; an instruction. Please leave '|cff00ff00' and '|r' intact as they are color codes.
L["On the |cff00ff00%s|r tab click the |cff00ff00%s|r button. An initial scan is required for the addon to function. It should have a date/time to show a scan has already been done. The addon should perform a scan before it does any work. Eventually, the |cff00ff00%s|r button will be removed."] = "On the |cff00ff00%s|r tab click the |cff00ff00%s|r button. An initial scan is required for the addon to function. It should have a date/time to show a scan has already been done. The addon should perform a scan before it does any work. Eventually, the |cff00ff00%s|r button will be removed."
L["Definition: Source Character - A character which has action bars you want to share with other characters."] = "Definition: Source Character - A character which has action bars you want to share with other characters."
L["Definition: Target Character - A character which will receive action bar data from one or more source characters."] = "Definition: Target Character - A character which will receive action bar data from one or more source characters."
L["On the |cff00ff00%s|r tab for each Source Character, check each Action Bar you want to share in the |cff00ff00%s|r section."] = "On the |cff00ff00%s|r tab for each Source Character, check each Action Bar you want to share in the |cff00ff00%s|r section."
L["On the |cff00ff00%s|r tab for each Target Character, check each Action Bar you want to update from one or more Source Characters in the |cff00ff00%s|r section."] = "On the |cff00ff00%s|r tab for each Target Character, check each Action Bar you want to update from one or more Source Characters in the |cff00ff00%s|r section."
L["On the |cff00ff00%s|r tab, once the previous step is done, click the |cff00ff00%s|r button to sync your action bars. If you want your bars auto synced, enable the |cff00ff00%s|r option."] = "On the |cff00ff00%s|r tab, once the previous step is done, click the |cff00ff00%s|r button to sync your action bars. If you want your bars auto synced, enable the |cff00ff00%s|r option."
L["Done!"] = "Done!"

-- FAQ
-- Introduction tab; another FAQ.
L["If an action button does not sync and an error for the same button isn't on the '%s' tab, it means the action can't be picked up and placed through Blizzard's API via this addon. Trying to figure out how to capture pickup or placement failures."] = "If an action button does not sync and an error for the same button isn't on the '%s' tab, it means the action can't be picked up and placed through Blizzard's API via this addon. Trying to figure out how to capture pickup or placement failures."
L["Be sure to open all sources of action bar buttons in order for the game to load that particular data into the game memory so the WoW API can access it. For example, if you have a toy on an action button, open your toy box. You won't see any addon or WoW errors, but the addon won't be able to capture or place the toy on the action button and no errors will be recorded. All sources could be spells, items, toys, mounts, pets and macros. If you forget to do this, just rescan and then try syncing again after opening all game content."] = "Be sure to open all sources of action bar buttons in order for the game to load that particular data into the game memory so the WoW API can access it. For example, if you have a toy on an action button, open your toy box. You won't see any addon or WoW errors, but the addon won't be able to capture or place the toy on the action button and no errors will be recorded. All sources could be spells, items, toys, mounts, pets and macros. If you forget to do this, just rescan and then try syncing again after opening all game content."

-- Dev Only
L["(GetCheckboxGlobalName) Failed to Translate Bar Name! Please report as an issue. Using: "] = "(GetCheckboxGlobalName) Failed to Translate Bar Name! Please report as an issue. Using: "
L["(%s) self.ui.frame.syncContent does not exist, cannot process sync region."] = "(%s) self.ui.frame.syncContent does not exist, cannot process sync region."

-- Sync error tab, table header.
L["Bar Name"] = "Bar Name"
L["Bar Pos"] = "Bar Pos"
L["Button ID"] = "Button ID"
L["Action Type"] = "Action Type"
L["Action Name"] = "Action Name"
L["Action ID"] = "Action ID"
L["Shared By"] = "Shared By"
L["Message"] = "Message"

-- Action Type, used in multiple places.
L["Spell"] = "Spell"
L["Item"] = "Item"
L["Macro"] = "Macro"
L["Pet"] = "Pet"
L["Mount"] = "Mount"
L["Flyout"] = "Flyout"
--@end-do-not-package@