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
    Hazard = 3,
    Portal = 4,
}

Z_INDEXES = {
    Hazard = 20,
    Pickup = 50,
    Player = 100
}

function Game:init(startLevel)
    startLevel = startLevel or 1

    local world = json.decodeFile("level/world.ldtk")
    assert(world, "Не удалось загрузить world.ldtk")

    local levelIndex = startLevel
    local levelData  = world.levels[levelIndex]
    assert(levelData, "Уровень " .. levelIndex .. " не найден в world.ldtk")

    print("Загружаем уровень:", levelData.identifier)

    self.level  = Level(levelData)

    local spawnX = 100
    local spawnY = 10

    self.levelComplete = LevelComplete()
    self.player = Player(spawnX, spawnY, self.levelComplete)

    -- HUD теперь умеет рисовать попап монет
    self.hud = {
        draw = function()
            self.player.coinPopup:draw()
            self.levelComplete:draw()
        end
    }
end

function Game:update()
    -- Обновляем таймер попапа монет
    self.player.coinPopup:update()
    self.levelComplete:update()
end

function Game:handleCrank(change, acceleratedChange)
end