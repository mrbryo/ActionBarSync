--[[---------------------------------------------------------------------------
    Localization for Action Bar Sync
    Language: English (US)
-----------------------------------------------------------------------------]]

-- Addon ID
local optionLocName = _G.ABSync.optionLocName

-- switch to true when releasing it
local silent = false

-- instantiate the new locale
local L = LibStub("AceLocale-3.0"):NewLocale(optionLocName, "enUS", true, silent)

-- following line is replaced when packaged through curseforge using their localization tool
--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat", handle-unlocalized="english")@

--@do-not-package@ 
--[[ leaving all for development purposes, export from curseforge ]]
L["actionbar1"] = "Action Bar 1"
L["actionbar2"] = "Action Bar 2"
L["actionbar3"] = "Action Bar 3"
L["actionbar4"] = "Action Bar 4"
L["actionbar5"] = "Action Bar 5"
L["actionbar6"] = "Action Bar 6"
L["actionbar7"] = "Action Bar 7"
L["actionbar8"] = "Action Bar 8"
L["actionbarsync_backup_note_text"] = "Enter a note for this backup:"
L["actionbarsync_invalid_key_text"] = "Action Bar Key '%s' is not valid. Please open an issue and include the key and which action bar you checked. Get links on the About tab in options."
L["actionbarsync_no_diffs_found_text"] = "For the action bars flagged for syncing, no differences were found."
L["actionbarsync_no_scan_text"] = "Current bar configuration for '%s' is not found. Scan and try sharing again. Proceed with a scan?"
L["actionbarsync_no_syncbars_text"] = "You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."
L["actionbarsync_not_bar_owner_text"] = "This bar (%s) is owned by '%s'; please switch to this character to uncheck it."
L["actionbarsync_sync_cancelled_text"] = "Action Bar Sync has been cancelled."
L["actionbarsync_sync_errors_found"] = "Action Bar Sync encountered errors during a sync; key: '%s':"
L["actionbarsynctitle"] = "Action Bar Sync"
L["actioniddesc"] = "The ID of the item you want to look up."
L["actionidname"] = "Action ID"
L["actionlookupdesc"] = "This section allows you to look up actions by ID."
L["actionlookupintro"] = "This section allows you to look up actions by type and ID or Name."
L["actionlookupname"] = "Action ID Lookup"
L["actiontypedesc"] = "The type of the action you want to look up."
L["actiontypename"] = "Action Type"
L["bars2sync"] = "Bars to Share"
L["beginsyncdefaultbackupreason"] = "Because..."
L["cancel"] = "Cancel"
L["disabled"] = "Disabled"
L["enabled"] = "Enabled"
L["finaldescr"] = "Finally, review and update the settings below."
L["finalhdr"] = "Final Step"
L["finalstep"] = "Check bars after logging into a character."
L["getactionbardata_button_name_template"] = "Button%d+$"
L["getactionbardata_final_notification"] = "Fetch Current Action Bar Button Data - Done"
L["getmountinfolookup"] = "Mount Name: %s - ID: %s - Display ID: %s"
L["initialized"] = "Initialized"
L["initializing"] = "Initializing..."
L["introduction"] = "Introduction"
L["introname"] = "This addon allows you to sync selected action bars across characters."
L["invalidactiontype"] = "Invalid Action Type. Please enter/select a valid action type."
L["item"] = "Item"
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
L["lookingupactionnotifytext"] = "Looking up Action - Type: %s - ID: %s"
L["lookupbuttondesc"] = "Click to look up the action."
L["lookupbuttonname"] = "Lookup"
L["macro"] = "Macro"
L["macrolookupresult"] = [=[Macro Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["mountlookupresult"] = [=[Mount Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["never"] = "Never"
L["no"] = "No"
L["noerrorsfound"] = "No Errors Found"
L["noowner"] = "No Owner"
L["noscancompleted"] = "No Scan Completed"
L["notfound"] = "Not Found"
L["notinbags"] = "Not in Bags"
L["objectname"] = "Action Name"
L["objectnamedesc"] = "Enter the exact name of the action you want to look up."
L["ok"] = "OK"
L["onenable_db_not_found"] = "Database Not Found? Strange...please reload the UI. If error returns, restart the game."
L["petlookupresult"] = [=[Pet Lookup Result
ID: %s
Name: %s
Has: %s]=]
L["profilesync"] = "Sync to My UI"
L["registerevents_addon_loaded"] = "Event - ADDON_LOADED"
L["registerevents_player_login"] = "Event - PLAYER_LOGIN"
L["registerevents_player_logout"] = "Event - PLAYER_LOGOUT"
L["registerevents_starting"] = "Registering Events..."
L["registerevents_variables_loaded"] = "Event - VARIABLES_LOADED"
L["scan"] = "Scan"
L["slashcommand_none_setup_yet"] = "No Slash Commands Setup Yet"
L["spell"] = "Spell"
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
L["summonmount"] = "Mount"
L["summonpet"] = "Pet"
L["syncsettings"] = "Sync Settings"
L["syncsettingsdesc"] = "See directions and current sync settings."
L["synctitle"] = "Sync!"
L["synctitledesc"] = "Trigger a sync and/or restore from a backup."
L["triggerbackup_no_note_provided"] = "No note provided!"
L["triggerbackup_no_sync_data_found"] = "No sync data found for backup."
L["triggerbackup_notify"] = "Backing Up Action Bar '%s'..."
L["triggerdesc"] = "Sync your action bars with the current profile."
L["triggerhdr"] = "Perform a Sync"
L["triggername"] = "Start!"
L["unavailable"] = "Unavailable"
L["unknown"] = "Unknown"
L["updateactionbars_button_name_template"] = "%s-Button-%d"
L["updateactionbars_debug_item_name"] = "Item Name for ID '%s': %s"
L["updateactionbars_item_not_found"] = "(%s) Item with ID %s for button %s not found."
L["updateactionbars_macro_not_found"] = "(%s) Macro with ID %s not found."
L["updateactionbars_mount_not_found"] = "(%s) Mount with ID %s not found."
L["updateactionbars_pet_not_found"] = "(%s) Pet with ID %s not found."
L["updateactionbars_player_doesnot_have_spell"] = "(%s) Player does not have spell '%s' with ID '%s'."
L["updateactionbars_spell_not_found"] = "(%s) Spell with ID %s for button %s not found."
L["updateactionbars_user_doesnot_have_item"] = "(%s) User does not have item '%s' with ID '%s' in their bags."
L["yes"] = "Yes"
--@end-do-not-package@