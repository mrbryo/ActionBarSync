--[[-----------------------------------------------------------------------------
    Localization for Action Bar Sync
    Language: English (US)
-----------------------------------------------------------------------------]]

-- Addon ID
local optionLocName = "ActionBarSync"

-- switch to true when releasing it
local silent = false

-- instantiate the new locale
local L = LibStub("AceLocale-3.0"):NewLocale(optionLocName, "enUS", true, silent)

-- misc
L["actionbar2"] = "Action Bar 2"
L["actionbar3"] = "Action Bar 3"
L["actionbar4"] = "Action Bar 4"
L["actionbar5"] = "Action Bar 5"
L["actionbar6"] = "Action Bar 6"
L["actionbar7"] = "Action Bar 7"
L["actionbar8"] = "Action Bar 8"
L["actionbar1"] = "Action Bar 1"
L["spell"] = "Spell"
L["item"] = "Item"
L["macro"] = "Macro"
L["summonpet"] = "Pet"
L["summonmount"] = "Mount"
L["initializing"] = "Initializing..."
L["initialized"] = "Initialized"
L["never"] = "Never"
L["ok"] = "OK"
L["unknown"] = "Unknown"
L["yes"] = "Yes"
L["no"] = "No"
L["noerrorsfound"] = "No Errors Found"
L["cancel"] = "Cancel"
L["enabled"] = "Enabled"
L["disabled"] = "Disabled"

-- Options
L["actionbarsynctitle"] = "Action Bar Sync"
L["syncsettings"] = "Sync Settings"
L["syncsettingsdesc"] = "See directions and current sync settings."
L["introduction"] = "Introduction"
L["introname"] = "This addon allows you to sync selected action bars across characters."
L["step1hdr"] = "Step 1"
L["step1desc"] = "Go to Profiles and be sure you are using the correct profile."
L["step2hdr"] = "Step 2"
L["step2desc"] = "Click the Scan button. This will capture your current action bars and buttons."
L["scan"] = "Scan"
L["lastscanname"] = "Last Scan on this Character"
L["lastscandescr"] = "Last time an action bar scan was completed."
L["step3hdr"] = "Step 3"
L["step3desc"] = "Indicate which action bars to sync."
L["bars2sync"] = "Bars to Sync"
L["finalhdr"] = "Final Step"
L["finaldescr"] = "Finally, review and update the settings below."
L["finalstep"] = "Check bars after logging into a character."
L["synctitle"] = "Sync!"
L["synctitledesc"] = "Trigger a sync and/or restore from a backup."
L["triggerhdr"] = "Perform a Sync"
L["lastupdatedname"] = "Last Synced on this Character"
L["lastupdateddesc"] = "The last time the action bars were synced on this character."
L["triggername"] = "Start!"
L["triggerdesc"] = "Sync your action bars with the current profile."
L["lastsyncerrorsname"] = "Last Sync Errors"
L["lastsyncerrorsdesc"] = "The last time there was an error syncing action bars on this character."
L["actionlookupname"] = "Action ID Lookup"
L["actionlookupdesc"] = "This section allows you to look up actions by ID."
L["actionlookupintro"] = "This section allows you to look up actions by type and ID or Name."
L["objectname"] = "Action Name"
L["objectnamedesc"] = "Enter the exact name of the action you want to look up."
L["actionidname"] = "Action ID"
L["actioniddesc"] = "The ID of the item you want to look up."
L["actiontypename"] = "Action Type"
L["actiontypedesc"] = "The type of the action you want to look up."
L["lookupbuttonname"] = "Lookup"
L["lookupbuttondesc"] = "Click to look up the action."

-- function lookupAction
L["lookingupactionnotifytext"] = "Looking up Action - Type: %s - ID: %s"
L["invalidactiontype"] = "Invalid Action Type. Please enter/select a valid action type."
L["spelllookupresult"] = "Spell Lookup Result\nID: %s\nName: %s\nHas: %s"
L["itemlookupresult"] = "Item Lookup Result\nID: %s\nName: %s\nHas: %s"
L["macrolookupresult"] = "Macro Lookup Result\nID: %s\nName: %s\nHas: %s"
L["petlookupresult"] = "Pet Lookup Result\nID: %s\nName: %s\nHas: %s"
L["mountlookupresult"] = "Mount Lookup Result\nID: %s\nName: %s\nHas: %s"

-- function GetMountInfo
L["getmountinfolookup"] = "Mount Name: %s - ID: %s - Display ID: %s"

-- function GetActionBarNames
L["noscancompleted"] = "No Scan Completed"

-- function SetBarToSync
L["actionbarsync_not_bar_owner_text"] = "This bar (%s) is owned by '%s'; please switch to this character to uncheck it."
L["actionbarsync_no_scan_text"] = "In order to keep the save data at a minimum current bar settings are not retained. You must click the Scan button before you can change sync settings."
L["setbartosync_final_notification"] = "(%s) Set Bar '%s' to sync? %s - Done!"

-- function BeginSync
L["actionbarsync_backup_note_text"] = "Enter a note for this backup:"
L["beginsyncdefaultbackupreason"] = "Because..."
L["actionbarsync_sync_cancelled_text"] = "Action Bar Sync has been cancelled."
L["actionbarsync_no_syncbars_text"] = "You must select at least one action bar to sync. Go back to 'Sync Settings' and pick some."

-- function TriggerBackup
L["triggerbackup_notify"] = "Backing Up Action Bar '%s'..."
L["triggerbackup_no_sync_data_found"] = "No sync data found for backup."
L["triggerbackup_no_note_provided"] = "No note provided!"

-- function UpdateActionBars
L["actionbarsync_no_diffs_found_text"] = "For the action bars flagged for syncing, no differences were found."
L["updateactionbars_button_name_template"] = "%s-Button-%d"
L["updateactionbars_player_doesnot_have_spell"] = "(%s) Player does not have spell '%s' with ID '%s'."
L["updateactionbars_spell_not_found"] = "(%s) Spell with ID %s for button %s not found."
L["updateactionbars_debug_item_name"] = "Item Name for ID '%s': %s"
L["updateactionbars_item_not_found"] = "(%s) Item with ID %s for button %s not found."
L["updateactionbars_user_doesnot_have_item"] = "(%s) User does not have item '%s' with ID '%s' in their bags."
L["updateactionbars_macro_not_found"] = "(%s) Macro with ID %s not found."
L["updateactionbars_pet_not_found"] = "(%s) Pet with ID %s not found."
L["updateactionbars_mount_not_found"] = "(%s) Mount with ID %s not found."
L["actionbarsync_sync_errors_found"] = "Action Bar Sync encountered errors during a sync; key: '%s':"

-- function GetActionBarData
L["getactionbardata_button_name_template"] = "Button%d+$"
L["notfound"] = "notfound"
L["getactionbardata_final_notification"] = "Fetch Current Action Bar Button Data - Done"

-- function SlashCommand
L["slashcommand_none_setup_yet"] = "No Slash Commands Setup Yet"

-- function RegisterEvents
L["registerevents_starting"] = "Registering Events..."
L["registerevents_addon_loaded"] = "Event - ADDON_LOADED"
L["registerevents_player_login"] = "Event - PLAYER_LOGIN"
L["registerevents_player_logout"] = "Event - PLAYER_LOGOUT"
L["registerevents_variables_loaded"] = "Event - VARIABLES_LOADED"

-- function OnEnable
L["onenable_db_not_found"] = "Database Not Found? Strange...please reload the UI. If error returns, restart the game."