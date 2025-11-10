function patch(config)
    if xsb then -- Only show the "Proximity (Secondaries)" tick box on xStarbound, the only client it's relevant on.
        table.insert(
            config.modes,
            jobject({
                name = "xDPC::ProxSecondary",
                has_tab = false,
                priority = 16,
                has_toggle = true,
            })
        )
        config.baseConfigValues.modeColors["xDPC::ProxSecondary"] = config.baseConfigValues.modeColors["xDPC::Prox"]
    end
    return config
end
