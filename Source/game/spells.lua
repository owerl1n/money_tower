-- game/spells.lua
SPELLS = {
    {
        id      = "fireball",
        glyph   = 1,        -- индекс в glyphs-table
        name    = "Fireball",
        onEquip = function(player) player.fireballAbility = true end,
        onUnequip = function(player) player.fireballAbility = false end,
    },
    {
        id      = "dash",
        glyph   = 2,
        name    = "Dash",
        onEquip   = function(player) player.dashAbility = true end,
        onUnequip = function(player) player.dashAbility = false end,
    },
    -- добавляй сюда сколько угодно
}