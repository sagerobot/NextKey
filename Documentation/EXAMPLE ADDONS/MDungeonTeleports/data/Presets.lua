local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")

MDT_ColourPresets = {
    {
        text = L["PRESET_DEFAULT"],
        back = { r = 0, g = 0, b = 0, a = 0.6 },
        border = { r = 0, g = 0, b = 0, a = 0.8 },
        buttonborder = { r = 0, g = 0, b = 0, a = 0.8 },
        title = { r = 1, g = 1, b = 1 },
        expansion = { r = 0, g = 1, b = 0.6 },
        button = { r = 1, g = 1, b = 1 }
    },
    {
        text = L["PRESET_ELVUI"],
        back = { r = 0, g = 0, b = 0, a = 0.4 },
        border = { r = 0, g = 0, b = 0, a = 1 },
        buttonborder = { r = 0.05, g = 0.05, b = 0.05, a = 0.8 },
        title = { r = 1, g = 1, b = 1 },
        expansion = { r = 1, g = 1, b = 1 },
        button = { r = 1, g = 1, b = 1 }
    },
    {
        text = L["PRESET_EMERALD_DREAM"],
        back = { r = 0.05, g = 0.3, b = 0.1, a = 0.65 },
        border = { r = 0, g = 0.4, b = 0.1, a = 0.85 },
        buttonborder = { r = 0, g = 0.4, b = 0.1, a = 0.85 },
        title = { r = 0.8, g = 1, b = 0.8 },
        expansion = { r = 0.5, g = 1, b = 0.6 },
        button = { r = 0.3, g = 1, b = 0.5 }
    },
    {
        text = L["PRESET_RED_DAWN"],
        back = { r = 0.3, g = 0, b = 0, a = 0.7 },
        border = { r = 0.6, g = 0.1, b = 0.1, a = 0.85 },
        buttonborder = { r = 0.6, g = 0.1, b = 0.1, a = 0.85 },
        title = { r = 1, g = 0.8, b = 0.8 },
        expansion = { r = 1, g = 0.4, b = 0.4 },
        button = { r = 1, g = 0.3, b = 0.3 }
    },
    {
        text = L["PRESET_SHADOWED_NIGHT"],
        back = { r = 0.05, g = 0.05, b = 0.1, a = 0.8 },
        border = { r = 0.2, g = 0.2, b = 0.3, a = 0.9 },
        buttonborder = { r = 0.2, g = 0.2, b = 0.3, a = 0.9 },
        title = { r = 0.9, g = 0.9, b = 1 },
        expansion = { r = 0.6, g = 0.6, b = 1 },
        button = { r = 0.5, g = 0.5, b = 1 }
    },
    {
        text = L["PRESET_STORMLIGHT"],
        back = { r = 0.05, g = 0.15, b = 0.3, a = 0.65 },
        border = { r = 0.1, g = 0.3, b = 0.5, a = 0.9 },
        buttonborder = { r = 0.1, g = 0.3, b = 0.5, a = 0.9 },
        title = { r = 1, g = 1, b = 1 },
        expansion = { r = 0.6, g = 0.85, b = 1 },
        button = { r = 0.4, g = 0.7, b = 1 }
    },
    {
        text = L["PRESET_TWILIGHT_GROVE"],
        back = { r = 0.1, g = 0.05, b = 0.2, a = 0.75 },
        border = { r = 0.3, g = 0.15, b = 0.5, a = 0.9 },
        buttonborder = { r = 0.3, g = 0.15, b = 0.5, a = 0.9 },
        title = { r = 0.9, g = 0.85, b = 1 },
        expansion = { r = 0.7, g = 0.5, b = 1 },
        button = { r = 0.7, g = 0.5, b = 1 }
    },
    {
        text = L["PRESET_FEL_INFUSION"],
        back = { r = 0.05, g = 0.2, b = 0.05, a = 0.7 },
        border = { r = 0.2, g = 0.6, b = 0.2, a = 0.9 },
        buttonborder = { r = 0.2, g = 0.6, b = 0.2, a = 0.9 },
        title = { r = 0.8, g = 1, b = 0.8 },
        expansion = { r = 0.5, g = 1, b = 0.5 },
        button = { r = 0.4, g = 1, b = 0.4 }
    },
    {
        text = L["PRESET_SUNFIRE"],
        back = { r = 0.3, g = 0.15, b = 0, a = 0.7 },
        border = { r = 0.6, g = 0.3, b = 0.05, a = 0.9 },
        buttonborder = { r = 0.6, g = 0.3, b = 0.05, a = 0.9 },
        title = { r = 1, g = 0.9, b = 0.7 },
        expansion = { r = 1, g = 0.7, b = 0.3 },
        button = { r = 1, g = 0.7, b = 0.2 }
    },
    {
        text = L["PRESET_VOID_EMBRACE"],
        back = { r = 0, g = 0, b = 0, a = 0.85 },
        border = { r = 0.25, g = 0, b = 0.4, a = 0.9 },
        buttonborder = { r = 0.25, g = 0, b = 0.4, a = 0.9 },
        title = { r = 0.85, g = 0.75, b = 1 },
        expansion = { r = 0.6, g = 0.4, b = 1 },
        button = { r = 0.7, g = 0.4, b = 1 }
    }
}
