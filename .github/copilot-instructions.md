# ActionBarSync World of Warcraft Addon - Copilot Instructions

## Architecture Overview

This is a World of Warcraft addon that synchronizes action bar configurations between characters. Built with the **Ace3 framework**, it follows WoW addon patterns with a modular structure centered around a global `ABSync` object.

### Core Components

- **`initialize.lua`**: Creates the main `ABSync` addon object using `LibStub("AceAddon-3.0"):NewAddon()` and registers it globally as `_G.ABSync`
- **`ActionBarSync.lua`**: Main program containing the bulk of addon logic, UI definitions, and data management
- **`libs/`**: Utility modules created as `ABSync:NewModule()` submodules (e.g., `StandardFunctions`, `ActionData`)
- **`tabs/`**: UI tab implementations for the addon's configuration interface
- **`locale/`**: Internationalization using `AceLocale-3.0` with the pattern `L["key"] = "value"`

### Key Patterns

**Global Object Registration:**
```lua
local ABSync = LibStub("AceAddon-3.0"):NewAddon("Action Bar Sync", "AceHook-3.0", "AceConsole-3.0", "AceEvent-3.0")
_G.ABSync = ABSync
```

**Module Creation:**
```lua
local StdFuncs = ABSync:NewModule("StandardFunctions")
```

**Database Access:**
- Uses `AceDB-3.0` with profile/global/character storage patterns
- Access via `ActionBarSyncDB.profile.setting`, `ActionBarSyncDB.global.data`, `ActionBarSyncDB.char[self.currentPlayerServerSpec].characterData`
- SavedVariables: `ActionBarSyncDB`, `ActionBarSyncMountDB` (defined in `.toc`)

**UI Framework:**
- Leverages `AceConfig-3.0` and `AceConfigDialog-3.0` for options UI
- UI elements stored in `ABSync.ui` table with categories: `label`, `editbox`, `scroll`, `group`, `dropdown`, `frame`, `checkbox`
- Custom UI creation functions follow pattern: `ABSync:CreateCheckbox()`, `ABSync:CreateSyncCheckbox()`

**Localization System:**
Uses `AceLocale-3.0` with a structured multi-language approach:

```lua
-- In initialize.lua: Set up the locale identifier
ABSync.optionLocName = "ActionBarSync"

-- In ActionBarSync.lua: Access localized strings
local L = LibStub("AceLocale-3.0"):GetLocale(ABSync.optionLocName, ABSync.localeSilent)
ABSync.localeData = L  -- Store for use in other modules
```

**Locale File Structure (`locale/*.lua`):**
- **enUS.lua**: Master locale (default fallback) with all strings defined
- **Other locales**: Sparse files that only override translated strings
- Uses `--@localization()@` markers for CurseForge integration
- Development strings wrapped in `--@do-not-package@` blocks

**Key Localization Patterns:**
```lua
-- Locale registration pattern
local L = LibStub("AceLocale-3.0"):NewLocale(optionLocName, "enUS", true, silent)

-- String categories for organization
L["actionbar1"] = "Action Bar 1"                    -- UI labels
L["actionbarsync_*_text"] = "Error message..."      -- Error messages  
L["spell"] = "Spell"                                -- Action types
L["initialized"] = "Initialized"                    -- Debug messages
```

**CurseForge Integration:**
- `@localization(locale="enUS", format="lua_additive_table")@` markers enable automatic translation import
- Build system (`dev/release.sh`) processes these markers during packaging
- Supports parameter customization: `same-key-is-true=true`, `handle-unlocalized="english"`

## Development Workflows

**Build & Release:**
- Uses `dev/release.sh` bash script for packaging and uploading to CurseForge/WoWInterface
- Supports multi-game-version builds (Classic, TBC, Wrath, Retail)
- Filters for `--@do-not-package@` and `--@debug@` blocks during packaging
- Version replacement patterns: `@project-version@`, `@project-date-iso@`, etc.

**Debug Mode:**
```lua
--@debug@ 
if self:GetDevMode() == true then self:Print(L["initialized"]) end
--@end-debug@
```

**Slash Commands:**
- Registered as `/abs` pointing to `ABSync:SlashCommand()`
- Uses AceConsole-3.0 pattern: `self:RegisterChatCommand("abs", "SlashCommand")`

## Data Flow & Synchronization

**Action Bar Data Structure:**
- Stored in `ActionBarSyncDB.global.barsToSync[barName][playerID][buttonID]`
- Uses WoW's action bar naming: `"Action"` (bar 1), `"MultiBarBottomLeft"` (bar 2), etc.
- Translated via `ABSync.blizzardTranslate` lookup table

**Sync Process:**
1. Scan current character's action bars via `ABSync:ScanActionBars()`
2. Store in global database with player identifier `ABSync:GetKeyPlayerServerSpec()`
3. Compare with other characters' data in ShareSync tab
4. Apply selected changes via sync functions

**Action Types Supported:**
- `spell`, `item`, `macro`, `summonpet`, `summonmount` (stored in `ABSync.actionTypeLookup`)

## Project-Specific Conventions

**Color System:**
```lua
ABSync.constants.colors = {
    white = "|cffffffff", yellow = "|cffffff00", green = "|cff00ff00",
    blue = "|cff0000ff", purple = "|cffff00ff", red = "|cffff0000",
    orange = "|cffff7f00", gray = "|cff7f7f7f", label = "|cffffd100"
}
```

**TOC File Requirements:**
- Interface version format: `## Interface: 110200` (for 11.02.00)
- Dependency: `## RequiredDeps: Ace3` 
- Load order matters: `initialize.lua` → `locale/*.lua` → `ActionBarSync.lua` → `tabs/*.lua` → `libs/*.lua`

**Function Naming:**
- Public API: `ABSync:MethodName()` 
- Getters/Setters: `ABSync:GetLastActionName()`, `ABSync:SetLastActionName()`
- UI Creation: `ABSync:CreateCheckbox()`, `ABSync:UpdateSyncRegion()`
- Data Access: `ABSync:GetKeyPlayerServerSpec()`, `ABSync:GetActionData()`

**Error Handling:**
- Uses localized error messages stored in `L["actionbarsync_*_text"]` keys
- Validation functions check data integrity before sync operations

When modifying this addon, maintain the Ace3 patterns, respect the load order defined in the `.toc` file, and use the established `ABSync` global object for all functionality.