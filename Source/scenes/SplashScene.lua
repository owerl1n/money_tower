local pd <const> = playdate
local gfx <const> = pd.graphics

SplashScene = {}

function SplashScene:enter(params)
    self._logo = gfx.image.new("images/loading")  -- твой loading.png
    self._alpha = 1.0

    self._fadeTimer = pd.timer.new(500, 1.0, 0.0)
    self._fadeTimer.easingFunction = pd.easingFunctions.outCubic

    self._timer = pd.timer.performAfterDelay(2000, function()
        SceneManager.go("game", { level = 1 }, SceneManager.transitions.fade)
    end)
end

function SplashScene:exit()
    if self._timer    then self._timer:remove();    self._timer = nil end
    if self._fadeTimer then self._fadeTimer:remove(); self._fadeTimer = nil end
end

function SplashScene:update()
    if self._fadeTimer then
        self._alpha = self._fadeTimer.value
    end
    if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
        if self._timer then self._timer:remove() end
        SceneManager.go("game", { level = 1 }, SceneManager.transitions.fade)
    end
end

function SplashScene:draw()
    if self._logo then
        local w, h = self._logo:getSize()
        -- центрируем на игровом экране 200×120
        self._logo:draw(100 - w/2, 60 - h/2)
    end
    -- чёрный overlay при старте
    if self._alpha and self._alpha > 0 then
        gfx.setDitherPattern(self._alpha, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, 200, 120)
        gfx.setColor(gfx.kColorBlack)
    end
end

return SplashScene