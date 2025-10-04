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
L["Action Bar 1"] = "Action Bar 1"
L["Action Bar 2"] = "Action Bar 2"
L["Action Bar 3"] = "Action Bar 3"
L["Action Bar 4"] = "Action Bar 4"
L["Action Bar 5"] = "Action Bar 5"
L["Action Bar 6"] = "Action Bar 6"
L["Action Bar 7"] = "Action Bar 7"
L["Action Bar 8"] = "Action Bar 8"
L["Enter a name for this backup:"] = "Enter a name for this backup:"
L["Invalid Action Bar ID. Report this to the author."] = "Invalid Action Bar ID. Report this to the author."
L["actionbarsync_invalid_key_text"] = "Action Bar Key '%s' is not valid. Please open an issue and include the key and which action bar you checked. Get links on the About tab in options."
L["actionbarsync_no_diffs_found_text"] = "For the action bars flagged for syncing, no differences were found."
L["actionbarsync_no_scan_text"] = "Current bar configuration for '%s' is not found. Scan and try sharing again. Proceed with a scan?"
L["You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."] = "You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."
L["actionbarsync_not_bar_owner_text"] = "This bar (%s) is owned by '%s'; please switch to this character to uncheck it."
L["Action Bar Sync has been cancelled."] = "Action Bar Sync has been cancelled."
L["actionbarsync_sync_errors_found"] = "Action Bar Sync encountered errors during a sync; key: '%s':"
L["Action Bar Sync encountered errors during a sync; key: '%s':"] = "Action Bar Sync encountered errors during a sync; key: '%s':"
L["actionbarsynctitle"] = "Action Bar Sync"
L["actioniddesc"] = "The ID of the item you want to look up."
L["actionidname"] = "Action ID"
L["actionlookupdesc"] = "This section allows you to look up actions by ID."
L["This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."] = "This tab allows you to look up actions by ID, Name and Type. You can also assign the action to an action bar."
L["actionlookupname"] = "Action ID Lookup"
L["actiontypedesc"] = "The type of the action you want to look up."
L["actiontypename"] = "Action Type"
L["bars2sync"] = "Bars to Share"
L["cancel"] = "Cancel"
L["disabled"] = "Disabled"
L["enabled"] = "Enabled"
L["finaldescr"] = "Finally, review and update the settings below."
L["finalhdr"] = "Final Step"
L["finalstep"] = "Check bars after logging into a character."
L["Button%d+$"] = "Button%d+$"
L["getactionbardata_final_notification"] = "Fetch Current Action Bar Button Data - Done"
L["initialized"] = "Initialized"
L["initializing"] = "Initializing..."
L["introduction"] = "Introduction"
L["introname"] = "This addon allows you to sync selected action bars across characters."
L["invalidactiontype"] = "Invalid Action Type. Please enter/select a valid action type."
L["Item"] = "Item/Toy"
L["Flyout"] = "Flyout"
L["Utilities"] = "Utilities"
L["Clear Selected Bar"] = "Clear Selected Bar"
L["Clear %s"] = "Clear %s"
L["Action Bar Clear has been cancelled."] = "Action Bar Clear has been cancelled."
L["itemlookupresult"] = [=[Item Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["lastscandescr"] = "Last time an action bar scan was completed."
L["lastscanname"] = "Last Scan on this Character"
L["lastsyncerrorsdesc"] = "The last time there was an error syncing action bars on this character."
L["lastsyncerrorsname"] = "Last Sync Errors"
L["lastupdateddesc"] = "The last time the action bars were synced on this character."
L["lastupdatedname"] = "Last Synced on this Character"
L["Looking up Action - Type: %s - ID: %s"] = "Looking up Action - Type: %s - ID: %s"
L["lookupbuttondesc"] = "Click to look up the action."
L["lookupbuttonname"] = "Lookup"
L["Macro"] = "Macro"
L["macrolookupresult"] = [=[Macro Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["mountlookupresult"] = [=[Mount Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["Never"] = "Never"
L["No"] = "No"
L["noerrorsfound"] = "No Errors Found"
L["noowner"] = "No Owner"
L["No Scan Completed"] = "No Scan Completed"
L["notfound"] = "Not Found"
L["notinbags"] = "Not in Bags"
L["objectname"] = "Action Name"
L["objectnamedesc"] = "Enter the exact name of the action you want to look up."
L["ok"] = "OK"
L["Database Not Found? Strange...please reload the UI. If error returns, restart the game."] = "Database Not Found? Strange...please reload the UI. If error returns, restart the game."
L["petlookupresult"] = [=[Pet Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["profilesync"] = "Sync to My UI"
L["Event - %s"] = "Event - %s"
L["Registering Events..."] = "Registering Events..."
L["scan"] = "Scan"
L["slashcommand_none_setup_yet"] = "No Slash Commands Setup Yet"
L["Spell"] = "Spell"
L["spelllookupresult"] = [=[Spell Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["step1desc"] = "Go to Profiles and be sure you are using the correct profile."
L["step1hdr"] = "Step 1"
L["step2desc"] = "Click the Scan button. This will capture your current action bars and buttons."
L["step2hdr"] = "Step 2"
L["step3desc"] = "Indicate which action bars to share."
L["step3hdr"] = "Step 3"
L["step4desc"] = "Indicate which action bars to sync to your UI."
L["step4hdr"] = "Step 4"
L["Mount"] = "Mount"
L["Pet"] = "Pet"
L["syncsettings"] = "Sync Settings"
L["syncsettingsdesc"] = "See directions and current sync settings."
L["synctitle"] = "Sync!"
L["synctitledesc"] = "Trigger a sync and/or restore from a backup."
L["No note provided!"] = "No note provided!"
L["No sync data found for backup."] = "No sync data found for backup."
L["Backing Up Action Bar '%s'..."] = "Backing Up Action Bar '%s'..."
L["triggerdesc"] = "Sync your action bars with the current profile."
L["triggerhdr"] = "Perform a Sync"
L["triggername"] = "Start!"
L["unavailable"] = "Unavailable"
L["Unknown"] = "Unknown"
L["updateactionbars_button_name_template"] = "%s-Button-%d"
L["updateactionbars_debug_item_name"] = "Item Name for ID '%s': %s"
L["updateactionbars_item_not_found"] = "(%s) Item with ID %s for button %s not found."
L["updateactionbars_macro_not_found"] = "(%s) Macro with ID %s not found."
L["updateactionbars_mount_not_found"] = "(%s) Mount with ID %s not found."
L["updateactionbars_pet_not_found"] = "(%s) Pet with ID %s not found."
L["updateactionbars_player_doesnot_have_spell"] = "(%s) Player does not have spell '%s' with ID '%s'."
L["updateactionbars_spell_not_found"] = "(%s) Spell with ID %s for button %s not found."
L["updateactionbars_user_doesnot_have_item"] = "(%s) User does not have item '%s' with ID '%s' in their bags."
L["Yes"] = "Yes"
L["actionbarsync_mount_issue_text"] = "%d out of %d mount issues occurred. The functionality from Blizzard to assign mounts to an action bar requires those mounts to be visible in the Mount Journal. The issues this addon has encountered could be caused by the current Mount Journal filters. Either reset the filters to default or click the button 'Reset Mount Journal Filters' (only makes collected and usable mounts visible) and try the sync again."
L["charactermacro"] = "Character specific macro's can't be shared. To share a macro, it must be moved or copied to the General Macro tab in the macro interface."
L["notapplicable"] = "Not Applicable"
L["unknownitemtype"] = "Unknown Item Type"
L["Action Button '%s' has an unrecognized type of '%s'. Adding issue to Scan Errors and skipping...lots more text."] = "Action Button '%s' has an unrecognized type of '%s'. Recording issue to the saved variables file for this addon. Please open a ticket and include a copy of your 'ActionBarSync.lua' file in this folder path found in your World of Warcraft folder: \\_retail_\\WTF\\Account\\<ACCTNAME>\\SavedVariables"
L["English"] = "English"
L["German"] = "German"
L["Spanish (Spain)"] = "Spanish (Spain)"
L["Spanish (Mexico)"] = "Spanish (Mexico)"
L["French"] = "French"
L["Italian"] = "Italian"
L["Korean"] = "Korean"
L["Portuguese (Brazil)"] = "Portuguese (Brazil)"
L["Russian"] = "Russian"
L["Chinese (Simplified)"] = "Chinese (Simplified)"
L["Chinese (Traditional)"] = "Chinese (Traditional)"
L["Last Scan on this Character"] = "Last Scan on this Character"
L["Last Sync on this Character"] = "Last Sync on this Character"
L["Last Sync Errors"] = "Last Sync Errors"
L["Lookup & Assign"] = "Lookup & Assign"
L["Saved!"] = "Saved!"
L["History"] = "History"
L["None"] = "None"
L["restore"] = "Restore"
L["Default Name"] = "Default Name"
L["Unknown issue when trying to pickup and/or place the spell."] = "Unknown issue when trying to pickup and/or place the spell."
L["Switch Flight Style cannot be synced because it is a zone ability, not a normal spell."] = "Switch Flight Style cannot be synced because it is a zone ability, not a normal spell."
L["Warning"] = "Warning"
L["This tab is used for development purposes only."] = "This tab is used for development purposes only. If you are a user and using anything on this tab, then please use at your own risk. Please do not open tickets about this tab unless you believe it's causing issues with standard functionality."
L["Specialization Changed"] = "Specialization Changed"
L["About"] = "About"
L["Introduction"] = "Introduction"
L["Share/Sync"] = "Share/Sync"
L["Last Sync Errors"] = "Last Sync Errors"
L["Lookup & Assign"] = "Lookup & Assign"
L["Backup/Restore"] = "Backup/Restore"
L["Developer"] = "Developer"