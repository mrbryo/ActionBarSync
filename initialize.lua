--[[ ------------------------------------------------------------------------
	Title: 			Initialize.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	All initialization needed for the addon to function.
-----------------------------------------------------------------------------]]

---@class ns
local addonName, ns = ...

-- instantiate variable to hold functionality!
ns.data = {
	-- always set to false so the event can set it to true
	hasPlayerEnteredWorld = false,
	modules = {},
	events = {},
	name = "@addon-name@",
	version = "@project-version@",
	prefix = "ActionBarSyncUIObject",
	optionID = "ActionBarSync",

	-- addon ui columns
	columns = {},

	-- track minimap button issues
	minimap = {
		libdbiconStatus = true,
		libdbStatus = true,
		libstubStatus = true,
	},

	-- addon access to UI elements
	ui = {
		label = {},
		editbox = {},
		scroll = {},
		group = {},
		dropdown = {},
		frame = {},
		checkbox = {},
	},

	-- track popups
	popups = {
		clearbarBackupConfirmation = "ACTIONBARSYNC_CLEARBAR_BACKUP_NAME",
		clearbarSyncCancelled = "ACTIONBARSYNC_CLEARBAR_SYNC_CANCELLED",
		clearBarInvalidBarID = "ACTIONBARSYNC_CLEARBAR_INVALID_BARID",
		missingKey = "ACTIONBARSYNC_INVALID_KEY",
		noscan = "ACTIONBARSYNC_NO_SCAN",
		nodiffsfound = "ACTIONBARSYNC_NO_DIFFS_FOUND",
		mountissue = "ACTIONBARSYNC_MOUNT_ISSUE",
		nosyncbars = "ACTIONBARSYNC_NO_SYNCBARS",
		synccancelled = "ACTIONBARSYNC_SYNC_CANCELLED",
		backupname = "ACTIONBARSYNC_BACKUP_NAME",
	},

	-- action bar keys and their order
    actionBarOrder = {
        "actionbar1",
        "actionbar2",
        "actionbar3",
        "actionbar4",
        "actionbar5",
        "actionbar6",
        "actionbar7",
        "actionbar8",
    },

	-- colors
	constants = {
		colors = {
			white = "|cffffffff",
			yellow = "|cffffff00",
			green = "|cff00ff00",
			blue = "|cff0000ff",
			purple = "|cffff00ff",
			red = "|cffff0000",
			orange = "|cffff7f00",
			gray = "|cff7f7f7f",
			label = "|cffffd100"
		},
		ui = {
			checkbox = {
				size = 16,
				padding = 5
			},
			generic = {
				padding = 10
			},
			mainFrame = {
				minWidth = 855,
				minHeight = 480
			},
		},
		objectNames = {
			tabContentFrame = "TabContentFrame",
			shareCheckboxes = "ShareCheckboxes",
		},
		actionButtonTranslation = {
			actionbar7 = {
				157,
				158,
				159,
				160,
				161,
				162,
				163,
				164,
				165,
				166,
				167,
				168
			},
			actionbar4 = {
				25,
				26,
				27,
				28,
				29,
				30,
				31,
				32,
				33,
				34,
				35,
				36
			},
			actionbar6 = {
				145,
				146,
				147,
				148,
				149,
				150,
				151,
				152,
				153,
				154,
				155,
				156
			},
			actionbar3 = {
				49,
				50,
				51,
				52,
				53,
				54,
				55,
				56,
				57,
				58,
				59,
				60
			},
			actionbar1 = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10,
				11,
				12
			},
			actionbar5 = {
				37,
				38,
				39,
				40,
				41,
				42,
				43,
				44,
				45,
				46,
				47,
				48
			},
			actionbar2 = {
				61,
				62,
				63,
				64,
				65,
				66,
				67,
				68,
				69,
				70,
				71,
				72
			},
			actionbar8 = {
				169,
				170,
				171,
				172,
				173,
				174,
				175,
				176,
				177,
				178,
				179,
				180
			}
		},
		actionButtons = {
			"1",
			"2",
			"3",
			"4",
			"5",
			"6",
			"7",
			"8",
			"9",
			"10",
			"11",
			"12",
		},
	},

	-- lookup values for action button lookup
	actionTypeLookup = {},

	-- translate blizzard Action Bar settings names to LUA Code Names
	blizzardTranslate = {},

	-- lookup macro types
	macroType = {
		general = "general",
		character = "character",
	},

	-- ui tabs
	uitabs = {
		["order"] = {
			"about",
			"introduction",
			"sharesync",
			"last_sync_errors",
			"lookup",
			"backup",
			"utilities",
			"developer",
		},
		["varnames"] = {},
		["buttons"] = {},
		["buttonref"] = {},
		["tabframe"] = {},
	},

	-- track timers
	timers = {},
}

-- initialize the main db
if not ActionBarSyncDB then
	ActionBarSyncDB = {}
end

-- initialize the mount db
if not ActionBarSyncMountDB then
    ActionBarSyncMountDB = {}
end

--[[ slash command must be global to work correctly; I know there is another way to do it but not important right now. ]]

-- register slash commands
SLASH_ACTIONBARSYNC1 = "/actionbarsync"
SLASH_ACTIONBARSYNC2 = "/abs"

-- register slash command function
SlashCmdList.ACTIONBARSYNC = function(msg, editBox)
	ns:SlashCommand(msg)
end

--[[---------------------------------------------------------------------------
	Function:   AddModule
	Purpose:    Add a module to the addon.
-----------------------------------------------------------------------------]]
function ns:AddModule(name, module)
	local newModule = {}
	newModule.name = name
	newModule.parent = self
	ns.data.modules[name] = module
	return module
end

--[[---------------------------------------------------------------------------
	Function:   GetModule
	Purpose:    Retrieve a module from the addon.
-----------------------------------------------------------------------------]]
function ns:GetModule(name)
	return ns.data.modules[name]
end

--[[---------------------------------------------------------------------------
	Function:   Print
	Purpose:    Standard print function for the addon.
-----------------------------------------------------------------------------]]
function ns:Print(msg)
	if msg then
		print(("%s%s:|r %s"):format("|cffffd100", ns.L["Action Bar Sync"], tostring(msg)))
	end
end

--[[---------------------------------------------------------------------------
	Function:   RegisterEvent
	Purpose:    Register new events with in the addon.
-----------------------------------------------------------------------------]]
function ns:RegisterEvent(event, handler)
	--@debug@
	-- ns:Print(("Registering Event: %s"):format(event))
	--@end-debug@
	ns.data.events[event] = handler or function() end
	self.eventFrame:RegisterEvent(event)
end

--[[---------------------------------------------------------------------------
	Function:   Timer
	Purpose:    Create a timer to call a function after a delay.
-----------------------------------------------------------------------------]]
function ns:Timer(name, delay, func)
	-- if timer already exists; clear and cancel it first
	if ns.data.timers[name] then
		ns.data.timers[name]:Cancel()
		ns.TimerClear(name)
	end

	-- trigger new timer
	ns.data.timers[name] = C_Timer.After(delay, func)
end

--[[---------------------------------------------------------------------------
	Function:   TimerClear
	Purpose:    Clear a timer by name.
-----------------------------------------------------------------------------]]
function ns:TimerClear(name)
	if ns.data.timers[name] then
		ns.data.timers[name] = nil
	end
end

--[[---------------------------------------------------------------------------
	Function:   UnregisterEvent
	Purpose:    Unregister events within the addon.
-----------------------------------------------------------------------------]]
function ns:UnregisterEvent(event)
	ns.data.events[event] = nil
	self.eventFrame:UnregisterEvent(event)
end

--[[---------------------------------------------------------------------------
	Initialize addon loaded event.
-----------------------------------------------------------------------------]]
ns.eventFrame = CreateFrame("Frame")
ns.eventFrame:SetScript("OnEvent", function(self, event, ...)
	-- trigger function handler assigned to the registered event
	ns.data.events[event](self, event, ...)
end)