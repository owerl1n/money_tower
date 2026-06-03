SPELLS = {
    {
        id      = "block",
        glyph   = 1,
        name    = "Block",
        onEquip   = function(player) player.projectileAbility = true end,
        onUnequip = function(player) player.projectileAbility = false end,
    },
    {
        id      = "dash",
        glyph   = 2,
        name    = "Dash",
        onEquip   = function(player) player.dashAbility = true end,
        onUnequip = function(player) player.dashAbility = false end,
    },
    {
        id      = "anchor",
        glyph   = 4,            -- нужен третий глиф в glyphs-table
        name    = "Anchor",
        onEquip   = function(player) player.anchorAbility = true end,
        onUnequip = function(player)
            player.anchorAbility = false
            player:clearAnchor()
        end,
    },
}