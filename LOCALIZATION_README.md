# Tome of Teleportation Localization System

## Overview

This localization system provides multi-language support for the Tome of Teleportation addon, specifically for expansion suffixes and category names localization.

## Features

### 1. Expansion Suffix Localization
- **Legion** → **军团再临** (Simplified Chinese)
- **WotLK** → **巫妖王之怒** (Simplified Chinese)
- **BFA** → **争霸艾泽拉斯** (Simplified Chinese)
- **Shadowlands** → **暗影国度** (Simplified Chinese) / **暗影國度** (Traditional Chinese)
- **Dragonflight** → **巨龙时代** (Simplified Chinese)
- **WarWithin** → **地心之战** (Simplified Chinese)

### 2. Category Name Localization
- **Draenor Dungeons** → **德拉诺地下城** (Simplified Chinese)
- **Dragon Isles Dungeons** → **巨龙群岛地下城** (Simplified Chinese)
- **Pandaria Dungeons** → **潘达利亚地下城** (Simplified Chinese)
- **Shadowlands Dungeons** → **暗影国度地下城** (Simplified Chinese) / **暗影國度地下城** (Traditional Chinese)
- **War Within Dungeons** → **地心之战地下城** (Simplified Chinese)
- **Dragon Isles Raids** → **巨龙群岛团队副本** (Simplified Chinese)
- **Fishing Pool** → **钓鱼池** (Simplified Chinese)
- **Delves** → **地下堡** (Simplified Chinese)

## Supported Languages

- **enUS** - English
- **zhCN** - Simplified Chinese
- **zhTW** - Traditional Chinese
- **deDE** - German
- **frFR** - French
- **esES** - Spanish
- **ruRU** - Russian
- **koKR** - Korean

## Usage

### 1. Expansion Suffix Localization
```lua
-- Old hardcoded way
CreateZone(LocZone("Dalaran", 41).name .. " (Legion)", 627)

-- New localized way
CreateZone(CreateLocalizedZoneName(LocZone("Dalaran", 41).name, "Legion"), 627)
```

### 2. Category Name Localization
```lua
-- Old hardcoded way
CreateDestination("Draenor Dungeons", { ... })

-- New localized way
CreateDestination(GetLocalizedCategoryName("Draenor Dungeons"), { ... })
```

## Display Examples

### English Client
- "Dalaran (Legion)"
- "Draenor Dungeons"

### Simplified Chinese Client
- "达拉然 (军团再临)"
- "德拉诺地下城"

### Traditional Chinese Client
- "達拉然 (軍團再臨)"
- "德拉諾地下城"

## Extending Localization

To add new localized strings, add the corresponding key-value pairs in the `LocalizedStrings` table:

```lua
local LocalizedStrings = {
    ["enUS"] = {
        ["NewKey"] = "English Text",
    },
    ["zhCN"] = {
        ["NewKey"] = "中文文本",
    },
    -- Other languages...
}
```

## Testing

To test the localization system, uncomment the test function in `Spells.lua`:

```lua
TestLocalization()
```

This will output the current language's localization results to the chat window.

## Notes

1. If a language is missing translations, the system will automatically fall back to English
2. Zone names (such as "Dalaran") still use the World of Warcraft client's localization
3. Only expansion suffixes and category names use the addon's localization system
4. The localization system is automatically initialized when the addon loads 