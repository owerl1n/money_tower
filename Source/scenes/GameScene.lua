local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "game"
import "game/level"
import "game/player"


GameScene = {}

function GameScene:enter(params)
    params = params or {}
    local startLevel = params.level or 1

    -- Здесь экран уже закрыт overlay — сначала чистим, потом создаём
    gfx.sprite.removeAll()

    local blackImg = gfx.image.new(200, 120, gfx.kColorBlack)
    local blackSprite = gfx.sprite.new(blackImg)
    blackSprite:setCenter(0, 0)
    blackSprite:moveTo(0, 0)
    blackSprite:setZIndex(1000)
    blackSprite:add()

    pd.timer.performAfterDelay(1, function()
        self.game = Game(startLevel)
        Game.instance = self.game
        blackSprite:remove()
    end)
end

function GameScene:exit()
    -- ничего не трогаем — спрайты живут до конца фазы "out"
    Game.instance = nil
end


function GameScene:update()
    if not self.game then return end  -- ← ждём пока таймер создаст игру
    self.game:update()
end

function GameScene:draw()
    if not self.game then return end
    -- временно для отладки
    --local lc = self.game.levelComplete
    --gfx.drawText("active:" .. tostring(lc._active) .. " t:" .. tostring(lc._timer), 10, 15)
    self.game.hud:draw()
end

function GameScene:cranked(change, acceleratedChange)
    if not self.game then return end
    self.game:handleCrank(change, acceleratedChange)
end