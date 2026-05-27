local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game"
import "game/level"
import "game/player"

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
end

function GameScene:exit()
    -- ← НЕ трогаем self.game здесь!
    -- SceneManager во время фазы "out" ещё вызывает draw(),
    -- картинка завершения должна оставаться видна под fade-overlay
    Game.instance = nil
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