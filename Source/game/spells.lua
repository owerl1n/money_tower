SPELLS = {
    {
        id      = "block",
        glyph   = 1,
        name    = "Block",
        onEquip   = function(player) player.projectileAbility = true end,
        onUnequip = function(player)
            player.projectileAbility = false
            -- уничтожаем летящий снаряд при смене заклинания
            if player._lastProjectile and not player._lastProjectile.destroyed then
                player._lastProjectile.destroyed = true
                player._lastProjectile:remove()
            end
            player._lastProjectile = nil
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
            -- НЕ вызываем clearAnchor() — метка остаётся на месте
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
            -- уничтожаем летящий снаряд при смене заклинания
            if player._lastBounceProjectile and not player._lastBounceProjectile.destroyed then
                player._lastBounceProjectile.destroyed = true
                player._lastBounceProjectile:remove()
            end
            player._lastBounceProjectile = nil
        end,
    },
}