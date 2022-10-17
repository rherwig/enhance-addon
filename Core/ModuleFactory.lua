local Enhance = _G.Enhance

ModuleFactory = {}

ModuleFactory.CreateModule = function(id, name, dependencies)
    local Module = Enhance:NewModule(name, unpack(dependencies))

    Module.id = id

    Module.defaults = {
        enabled = true
    }

    Module.options = {
        name = name,
        type = 'group',
        handler = Module,
        args = {
            enabled = {
                name = 'Enabled',
                desc = '|cffcccccc(on/off)|r - Enables the `' .. name .. '` module',
                type = 'toggle',
                set = function(info, value)
                    Module:SetOption('enabled', value)

                    if (value) then
                        Module:Initialize();
                    else
                        Module:Destroy();
                    end
                end,
                get = function(info)
                    return Module:GetOption('enabled')
                end
            },
        },
    }

    function Module:RegisterOptions(options, defaults)
        Module.options.args = table.merge(Module.options.args, options)
        Module.defaults = table.merge(Module.defaults, defaults)
    end

    function Module:GetOption(key)
        return Enhance.db.profile.modules[Module.id][key]
    end

    function Module:SetOption(key, value)
        Enhance.db.profile.modules[Module.id][key] = value
    end

    function Module:IsEnabled()
        return Module:GetOption('enabled')
    end

    function Module:Initialize()
        if not Module:IsEnabled() or Module.isInitialized then
            return
        end

        if Module.Bootstrap then
            Module:Bootstrap()
        end
    end

    return Module;
end
