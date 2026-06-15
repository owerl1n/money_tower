SPELLS = {
    {
        id      = "block",
        glyph   = 1,
        name    = "Block",
        onEquip   = function(player) player.projectileAbility = true end,
        onUnequip = function(player)
            player.projectileAbility = false
            -- снаряд НЕ уничтожаем, пусть летит/висит
        end,
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
        glyph   = 4,
        name    = "Anchor",
        onEquip   = function(player) player.anchorAbility = true end,
        onUnequip = function(player)
            player.anchorAbility = false
        end,
    },
    {
        id        = "bounceblock",
        glyph     = 3,
        name      = "BounceBlock",
        onEquip   = function(player) player.bounceBlockAbility = true end,
        onUnequip = function(player)
            player.bounceBlockAbility = false
            -- снаряд НЕ уничтожаем
        end,
    },
}