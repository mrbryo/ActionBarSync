# ActionBarSync World of Warcraft Addon - Copilot Instructions

## Architecture Overview

This is a World of Warcraft addon that synchronizes action bar configurations between characters. **Built with native WoW API only** (Ace3 framework has been removed), it follows WoW addon patterns with a modular structure centered around a global `ABSync` object.

### Core Components

- **`initialize.lua`**: Creates the main `ABSync` addon object using native WoW patterns and registers it globally as `_G.ABSync`
- **`ActionBarSync.lua`**: Main program containing the bulk of addon logic, UI definitions, and data management
- **`libs/`**: Utility modules containing helper functions (e.g., `StandardUI`, `ActionData`, `MountExtra`)
- **`tabs/`**: UI tab implementations for the addon's configuration interface
- **`locale/`**: Internationalization using simple locale tables with the pattern `L["key"] = "value"`

### Key Patterns

**Global Object Registration:**
```lua
-- Create addon object using native WoW patterns
local ABSync = {
    versionConfig = versionConfig,
    isDevelopmentVersion = IS_DEVELOPMENT_VERSION,
    eventFrame = nil,
    events = {},
    locales = {},
    L = {}
}
_G.ABSync = ABSync
```

**Event System (Native WoW API):**
```lua
function ABSync:RegisterEvent(event, handler)
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame", "ABSyncEventFrame")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if ABSync.events[event] then
                for _, handler in ipairs(ABSync.events[event]) do
                    handler(ABSync, event, ...)
                end
            end
        end)
    end
    
    if not self.events[event] then
        self.events[event] = {}
    end
    table.insert(self.events[event], handler)
    self.eventFrame:RegisterEvent(event)
end
```

**Database Access:**
- Uses native SavedVariables with direct access patterns
- Access via `self:GetDatabase().global.setting`, `self:GetDatabase().char[self.currentPlayerServerSpec].characterData`
- SavedVariables: `ActionBarSyncDB`, `ActionBarSyncMountDB`, `ActionBarSyncDevDB`, `ActionBarSyncDevMountDB` (defined in `.toc`)

**Development/Production Version Switching:**
```lua
-- Single variable controls entire addon behavior
local IS_DEVELOPMENT_VERSION = true  -- Set to false for production

local versionConfig = {
    addonName = IS_DEVELOPMENT_VERSION and "ActionBarSyncDev" or "ActionBarSync",
    globalVarName = IS_DEVELOPMENT_VERSION and "ABSyncDev" or "ABSync",
    databaseName = IS_DEVELOPMENT_VERSION and "ActionBarSyncDevDB" or "ActionBarSyncDB"
}
```

**UI Framework:**
- Uses native WoW UI creation functions: `CreateFrame()`, `CreateCheckButton()`, etc.
- UI elements stored in `ABSync.ui` table with categories: `label`, `editbox`, `scroll`, `group`, `dropdown`, `frame`, `checkbox`
- Custom UI creation functions follow pattern: `ABSync:CreateCheckbox()`, `ABSync:CreateSyncCheckbox()`

**Localization System:**
Uses native Lua tables with a structured multi-language approach:

```lua
-- In initialize.lua: Set up the locale identifier
ABSync.optionLocName = IS_DEVELOPMENT_VERSION and "ActionBarSyncDev" or "ActionBarSync"

-- In ActionBarSync.lua: Access localized strings
function ABSync:InitializeLocalization()
    local locale = GetLocale() or "enUS"
    self.L = self.locales[locale] or self.locales["enUS"] or {}
end
```

**Locale File Structure (`locale/*.lua`):**
- **enUS.lua**: Master locale (default fallback) with all strings defined
- **Other locales**: Sparse files that only override translated strings
- Uses `--@localization()@` markers for CurseForge integration
- Development strings wrapped in `--@do-not-package@` blocks

**Key Localization Patterns:**
```lua
-- Locale registration pattern
ABSync.locales["enUS"] = {}
local L = ABSync.locales["enUS"]

-- String categories for organization
L["actionbar1"] = "Action Bar 1"                    -- UI labels
L["actionbarsync_*_text"] = "Error message..."      -- Error messages  
L["spell"] = "Spell"                                -- Action types
L["initialized"] = "Initialized"                    -- Debug messages
```

**Console Output:**
```lua
function ABSync:Print(message)
    local prefix = self.isDevelopmentVersion and "[ActionBarSync Dev]" or "[ActionBarSync]"
    print(self.constants.colors.green .. prefix .. self.constants.colors.white .. " " .. tostring(message))
end
```

**Timer System:**
```lua
-- Uses C_Timer for delayed execution
function ABSync:ScheduleTimer(name, delay, func)
    if self.timers[name] then
        self.timers[name]:Cancel()
    end
    
    self.timers[name] = C_Timer.NewTimer(delay, function()
        func(self, name)
        self.timers[name] = nil
    end)
end
```

**CurseForge Integration:**
- `@localization(locale="enUS", format="lua_additive_table")@` markers enable automatic translation import
- Build system processes these markers during packaging
- Supports parameter customization: `same-key-is-true=true`, `handle-unlocalized="english"`

## Development Workflows

**Debug Mode:**
```lua
--@debug@ 
if self:GetDevMode() == true then 
    self:Print(L["initialized"]) 
end
--@end-debug@
```

**Slash Commands:**
```lua
-- Version-specific slash command registration
_G["SLASH_" .. versionConfig.slashCommandKey .. "1"] = versionConfig.slashCommand1
_G["SLASH_" .. versionConfig.slashCommandKey .. "2"] = versionConfig.slashCommand2

SlashCmdList[versionConfig.slashCommandKey] = function(msg, editBox)
    ABSync:SlashCommand(msg)
end
```

## Data Flow & Synchronization

**Action Bar Data Structure:**
- Stored in `self:GetDatabase().char[self.currentPlayerServerSpec].currentBarData[barID][buttonID]`
- Uses WoW's action bar naming: `"actionbar1"`, `"actionbar2"`, etc.
- Translated via `ABSync.blizzardTranslate` lookup table

**Sync Process:**
1. Scan current character's action bars via `ABSync:GetActionBarData()`
2. Store in database with player identifier `ABSync:GetKeyPlayerServerSpec()`
3. Compare with other characters' data in ShareSync tab
4. Apply selected changes via sync functions

**Action Types Supported:**
- `spell`, `item`, `macro`, `summonpet`, `summonmount`, `flyout` (stored in `ABSync.actionTypeLookup`)

## Project-Specific Conventions

**Color System:**
```lua
ABSync.constants = {
    colors = {
        white = "|cffffffff", yellow = "|cffffff00", green = "|cff00ff00",
        blue = "|cff0000ff", purple = "|cffff00ff", red = "|cffff0000",
        orange = "|cffff7f00", gray = "|cff7f7f7f", label = "|cffffd100"
    }
}
```

**TOC File Requirements:**
- Interface version format: `## Interface: 110200` (for 11.02.00)
- **No external dependencies** (Ace3 removed)
- Load order matters: `initialize.lua` → `locale/*.lua` → `ActionBarSync.lua` → `tabs/*.lua` → `libs/*.lua`
- SavedVariables includes both dev and prod databases

**Function Naming:**
- Public API: `ABSync:MethodName()` 
- Getters/Setters: `ABSync:GetLastActionName()`, `ABSync:SetLastActionName()`
- UI Creation: `ABSync:CreateCheckbox()`, `ABSync:UpdateSyncRegion()`
- Data Access: `ABSync:GetKeyPlayerServerSpec()`, `ABSync:GetActionData()`
- Database Access: `ABSync:GetDatabase()`, `ABSync:GetMountDatabase()`

**Error Handling:**
- Uses localized error messages stored in `L["actionbarsync_*_text"]` keys
- Validation functions check data integrity before sync operations
- Debug output wrapped in `--@debug@` blocks

**Development vs Production:**
- Single `IS_DEVELOPMENT_VERSION` boolean controls all naming and behavior
- Development version uses `ABSyncDev` global, `/absdev` commands, `ActionBarSyncDevDB` database
- Production version uses `ABSync` global, `/abs` commands, `ActionBarSyncDB` database
- Both versions can coexist without conflicts

## Important Notes

- **No Ace3 Dependencies**: This project uses native WoW API only
- **Version Switching**: Change single variable `IS_DEVELOPMENT_VERSION` to switch between dev/prod
- **Database Separation**: Dev and production versions use separate SavedVariables
- **Native Event System**: Custom event handling using `CreateFrame()` and `RegisterEvent()`
- **Localization**: Simple Lua table-based system, no AceLocale dependency

When modifying this addon, maintain the native WoW API patterns, respect the load order defined in the `.toc` file, and use the established `ABSync` global object for all functionality. Do not suggest Ace3 libraries - use only native WoW API functions.