local pd <const> = playdate
local gfx <const> = pd.graphics

SplashScene = {}

function SplashScene:enter(params)
    pd.timer.performAfterDelay(1, function ()
        self._logo = gfx.image.new("images/logo2")
    end)
    
    self._alpha = 1.0 -- начинаем с чёрного overlay

    --Плавно убираем overlay за 500мс
    -- self._fadeTimer = pd.timer.new(2000, 1.0, 0.0)
    -- self._fadeTimer.easingFunction = playdate.easingFunctions.outCubic

    -- После 2.5 сек идём в игру
    self._timer = pd.timer.performAfterDelay(2000, function()
        SceneManager.go("game", { level = 1 }, SceneManager.transitions.fade)
    end)
end

function SplashScene:exit()
    if self._timer then
        self._timer:remove();
        self._timer = nil
    end
    if self._fadeTimer then
        self._fadeTimer:remove();
        self._fadeTimer = nil
    end
end

function SplashScene:update()
    if self._fadeTimer then
        self._alpha = self._fadeTimer.value
    end
    if pd.buttonJustPressed(pd.kButtonA) or
        pd.buttonJustPressed(pd.kButtonB) then
        if self._timer then self._timer:remove() end
        SceneManager.go("game", { level = 1 }, SceneManager.transitions.fade)
    end
end

function SplashScene:draw()
    if self._logo then
        local w, h = self._logo:getSize()
        self._logo:draw(200 - w, 120 - h)
    end

    if self._alpha and self._alpha > 0 then
        gfx.setDitherPattern(self._alpha, gfx.image.kDitherTypeBayer8x8)

        --pd.timer.performAfterDelay(100, function()
        gfx.fillRect(0, 0, 400, 240)
        gfx.setColor(gfx.kColorBlack)
        --end)
    end
end

return SplashScene
