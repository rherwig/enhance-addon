local Enhance = _G.Enhance
local Module = ModuleFactory.CreateModule(
    'loot',
    'Loot',
    {
        'AceConsole-3.0',
        'AceEvent-3.0',
    }
);

local HaveEmptyBagSlots = 0

function Module:LootItems()
    if Module.isLooting then
        return
    end

    for i = 0, NUM_BAG_SLOTS do
        if not GetBagName(i) then
            HaveEmptyBagSlots = HaveEmptyBagSlots + 1
        end
    end

    local link, itemEquipLoc, bindType, _
    if (GetCVarBool('autoLootDefault') ~= IsModifiedClick('AUTOLOOTTOGGLE')) then
        Module.isLooting = true
        for i = GetNumLootItems(), 1, -1 do
            link = GetLootSlotLink(i)
            LootSlot(i)
            if link then
                itemEquipLoc, _, _, _, _, bindType = select(9, GetItemInfo(link))

                if itemEquipLoc == "INVTYPE_BAG" and bindType < 2 and HaveEmptyBagSlots > 0 then
                    EquipItemByName(link)
                end
            end
        end
    end
end

function Module:QUEST_COMPLETE(event)
end

function Module:LOOT_CLOSED()
    Module.isLooting = false
    Module.HaveEmptyBagSlots = 0
end

function Module:Bootstrap()
    LOOTFRAME_AUTOLOOT_DELAY = 0.1;
    LOOTFRAME_AUTOLOOT_RATE = 0.1;

    Module:RegisterEvent('LOOT_READY', 'LootItems')
    Module:RegisterEvent('LOOT_OPENED', 'LootItems')
    Module:RegisterEvent('LOOT_CLOSED')
    Module:RegisterEvent('QUEST_COMPLETE')

    Module.isInitialized = true
end
