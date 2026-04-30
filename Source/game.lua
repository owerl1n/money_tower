local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "game/level"
import "game/player"

class('Game').extends()

Game.instance = nil

TAGS = {
    Pickup = 1,
    Player = 2,
    Hazard = 3
}

Z_INDEXES = {
    Hazard = 20,
    Pickup = 50,
    Player = 100
}

function Game:init(startLevel)
    startLevel = startLevel or 1

    -- Загружаем LDtk
    local world = json.decodeFile("level/world.ldtk")
    assert(world, "Не удалось загрузить world.ldtk")

    -- Уровни в LDtk нумеруются с 0, но мы передаём с 1
    local levelIndex = startLevel  -- level 1 → levels[1] (Level_0)
    local levelData = world.levels[levelIndex]
    assert(levelData, "Уровень " .. levelIndex .. " не найден в world.ldtk")

    print("Загружаем уровень:", levelData.identifier)

    -- Создаём уровень (тайлы + коллизии)
    self.level = Level(levelData)

    -- Спавним игрока примерно по центру снизу уровня
    local spawnX = 100
    local spawnY = 10
    self.player = Player(spawnX, spawnY)

    -- HUD — простая заглушка
    self.hud = { draw = function() end }
end

function Game:update()
    -- Player обновляется через sprite.update() в pd.update
    -- Здесь можно добавить логику уровня, врагов и т.д.
end

function Game:handleCrank(change, acceleratedChange)
    -- будущая логика кранка
end