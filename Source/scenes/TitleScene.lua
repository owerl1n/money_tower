-- Source/scenes/TitleScene.lua
local pd  <const> = playdate
local gfx <const> = pd.graphics

TitleScene = {}

function TitleScene:enter(params)
    gfx.setDrawOffset(0, 0)
    
    self._image = gfx.image.new("images/splash")
    self._ready = false

    gfx.sprite.removeAll()

    local blackImg = gfx.image.new(200, 120, gfx.kColorBlack)
    local blackSprite = gfx.sprite.new(blackImg)
    blackSprite:setCenter(0, 0)
    blackSprite:moveTo(0, 0)
    blackSprite:setZIndex(1000)
    blackSprite:add()
    blackSprite:setIgnoresDrawOffset(true)

    pd.timer.performAfterDelay(1, function()
        blackSprite:remove()
    end)

    self._inputTimer = pd.timer.performAfterDelay(300, function()
        self._ready = true
    end)
end

function TitleScene:exit()
    if self._inputTimer then
        self._inputTimer:remove()
        self._inputTimer = nil
    end
end

function TitleScene:update()
    if not self._ready then return end
    if SceneManager.isTransitioning() then return end

    if pd.buttonJustPressed(pd.kButtonA) then
        self._ready = false
        SceneManager.go("game", { level = 1 }, SceneManager.transitions.fade)
    end
end

function TitleScene:draw()
    if self._image then
        local w, h = self._image:getSize()
        self._image:draw(100 - w / 2, 60 - h / 2)
    end
end

return TitleScene