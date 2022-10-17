local AddOnName = ...

local _G = _G
local LibStub = LibStub

local Enhance = LibStub('AceAddon-3.0'):NewAddon(AddOnName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

Enhance.Name = AddOnName
Enhance.Debug = true

Enhance.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Enhance.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Enhance.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
Enhance.Wrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

_G.Enhance = Enhance

function Enhance:CallModuleFunction(module, func)
    local pass, err = pcall(func, module)
    if not pass and Enhance.Debug then
        error(err)
    end
end

Enhance.defaults = {
    profile = {
        enabled = true,
        modules = {}
    }
}

Enhance.options = {
    name = Enhance.Name,
    handler = Enhance,
    type = "group",
    args = {
        enabled = {
            name = "Enable",
            desc = "Enables / disables the addon",
            type = "toggle",
            set = function(info, val)
                Enhance.db.profile.enabled = val
            end,
            get = function(info)
                return Enhance.db.profile.enabled
            end
        },

        options = {
            name = "Options",
            desc = "Opens the options UI",
            type = "execute",
            guiHidden = true,
            func = function()
                InterfaceOptionsFrame_OpenToCategory(Enhance.optionsFrame)
                InterfaceOptionsFrame_OpenToCategory(Enhance.optionsFrame)
            end
        },
    }
}

function Enhance:OnInitialize()
    for _, Module in Enhance:IterateModules() do
        if Module.defaults then
            self.defaults.profile.modules[Module.id] = Module.defaults
        end

        if Module.options then
            self.options.args[Module.id] = Module.options
        end
    end

    Enhance.db = LibStub("AceDB-3.0"):New("EnhanceDB", self.defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(Enhance.Name, self.options, { "enhance", "eh" })
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(Enhance.Name, Enhance.Name)

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(Enhance.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(Enhance.Name .. "_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(Enhance.Name .. "_Profiles", "Profiles", Enhance.Name)

    for _, Module in Enhance:IterateModules() do
        if Module.Initialize then
            Enhance:CallModuleFunction(Module, Module.Initialize)
        end
    end
end
