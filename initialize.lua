--[[ ------------------------------------------------------------------------
	Title: 			initialize.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	All initialization needed for the addon to function.
-----------------------------------------------------------------------------]]

-- Instantiate variable to hold functionality!
local ABSync = LibStub("AceAddon-3.0"):NewAddon("Action Bar Sync", "AceConsole-3.0", "AceEvent-3.0") -- "AceConfig-3.0"
_G.ABSync = ABSync

-- Option and Localization Name
ABSync.optionLocName = "ActionBarSync"