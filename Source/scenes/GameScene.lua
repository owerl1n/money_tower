local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game/core/game"
import "game/core/level"
import "game/entities/player/player"

GameScene = {}

local function goToLevel(level)
    SceneManager.go("game", { level = level }, SceneManager.transitions.fade)
end

function GameScene:enter(params)
    params = params or {}
    local startLevel = params.level or 1

    gfx.sprite.removeAll()

    local blackImg    = gfx.image.new(200, 120, gfx.kColorBlack)
    local blackSprite = gfx.sprite.new(blackImg)
    blackSprite:setCenter(0, 0)
    blackSprite:moveTo(0, 0)
    blackSprite:setZIndex(1000)
    blackSprite:setIgnoresDrawOffset(true)
    blackSprite:add()

    pd.timer.performAfterDelay(1, function()
        self.game = Game(
            startLevel,
            function(next)  goToLevel(next)  end,
            function(cur)   goToLevel(cur)   end
        )
        Game.instance = self.game
        blackSprite:remove()
    end)

    -- Пункт "Restart" в системном меню (открывается кнопкой Menu).
    -- Пока меню открыто, игра автоматически на паузе.
    self._menuItem = pd.getSystemMenu():addMenuItem("Restart", function()
        self:_restartLevel()
    end)
end

function GameScene:_restartLevel()
    if not self.game then return end
    if SceneManager.isTransitioning() then return end

    local level = self.game.currentLevel
    TreasureManager.reset()
    goToLevel(level)
end

function GameScene:exit()
    gfx.setDrawOffset(-4,0)
    Game.instance = nil

    if self._menuItem then
        pd.getSystemMenu():removeMenuItem(self._menuItem)
        self._menuItem = nil
    end
end

function GameScene:update()
    if not self.game then return end
    if SceneManager.isTransitioning() then return end
    self.game:handleInput()
    self.game:update()
end

function GameScene:draw()
    if not self.game then return end
    self.game.hud:draw()
    self.game.spellbook:draw()
end

function GameScene:cranked(change, acceleratedChange)
    if not self.game then return end
    self.game:handleCrank(change, acceleratedChange)
end