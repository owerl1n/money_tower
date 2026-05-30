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
    Projectile = 5,
    Block = 6,
}

Z_INDEXES = {
    Hazard = 20,
    Pickup = 50,
    Player = 100
}

function Game:init(startLevel, onNextLevel, onRestart)
    startLevel = startLevel or 0

    local world = json.decodeFile("level/world.ldtk")
    assert(world, "Не удалось загрузить world.ldtk")

    local levelData = world.levels[startLevel]
    assert(levelData, "Уровень " .. startLevel .. " не найден в world.ldtk")
    local levelName = levelData.identifier -- "Level_0", "Level_1", ...
    print("Загружаем уровень:", levelName)
    self.currentLevel = startLevel

    -- Если следующего уровня нет — onNextLevel рестартует последний
    local totalLevels = #world.levels
    local nextLevel   = startLevel < totalLevels and (startLevel + 1) or startLevel

    --print("Загружаем уровень:", levelData.identifier)

    self.currentLevel = startLevel

    self.levelComplete = LevelComplete(
        startLevel,
        function()  -- onNext
            CoinManager.reset()
            if onNextLevel then
                onNextLevel(nextLevel)
            end
        end,
        function()  -- onRestart
            CoinManager.reset()
            if onRestart then
                onRestart(startLevel)
            end
        end
    )

    self.level  = Level(levelName)

    self.player = Player(self.level.spawnX, self.level.spawnY, self.levelComplete)

    self.spellbook     = SpellBook(self.levelComplete, function(slot)
        -- Сбрасываем все способности
        self.player.dashAbility       = false
        self.player.projectileAbility = false

        if slot == 1 then
            self.player.dashAbility = true
            print("[Spell] Dash")
        elseif slot == 2 then
            self.player.projectileAbility = true
            print("[Spell] Projectile + Block")
        end
    end)

    self.hud = {
        draw = function()
            self.player.coinPopup:draw()
            self.levelComplete:draw()
        end
    }
end

function Game:update()
    self.spellbook:update()

    -- Блокируем обновление мира пока книга открыта
    if not self.spellbook:isActive() then
        self.player.coinPopup:update()
        self.levelComplete:update()
    end
end

function Game:handleInput()
    if pd.buttonJustPressed(pd.kButtonB) then
        self.spellbook:onButtonB()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        self.spellbook:onButtonA()
    end
end

function Game:handleCrank(change, acceleratedChange)
    self.spellbook:onCrank(change)
end