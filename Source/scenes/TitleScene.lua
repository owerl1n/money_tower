-- Source/scenes/TitleScene.lua
local pd  <const> = playdate
local gfx <const> = pd.graphics

TitleScene = {}

function TitleScene:enter(params)
    gfx.setDrawOffset(0, 0)
    
    self._image = gfx.image.new("images/splash")
    self._ready = false

    gfx.sprite.removeAll()

    SceneManager.flashBlack(1)

    self._inputTimer = pd.timer.performAfterDelay(300, function()
        self._ready = true
    end)

    -- DEBUG: сброс сейва, доступен только в симуляторе
    if pd.isSimulator then
        self._debugMenuItem = pd.getSystemMenu():addMenuItem("Reset Save (DEBUG)", function()
            SaveManager.reset()
            print("[DEBUG] сейв сброшен")
        end)
    end
end

function TitleScene:exit()
    if self._inputTimer then
        self._inputTimer:remove()
        self._inputTimer = nil
    end

    if self._debugMenuItem then
        pd.getSystemMenu():removeMenuItem(self._debugMenuItem)
        self._debugMenuItem = nil
    end
end

function TitleScene:update()
    if not self._ready then return end
    if SceneManager.isTransitioning() then return end

    if pd.buttonJustPressed(pd.kButtonA) then
        self._ready = false
        SceneManager.go("game", { level = SaveManager.getCurrentLevel() }, SceneManager.transitions.fade)
    elseif pd.buttonJustPressed(pd.kButtonB) then
        self._ready = false
        SceneManager.go("levelSelect", nil, SceneManager.transitions.fade)
    end
end

function TitleScene:draw()
    if self._image then
        local w, h = self._image:getSize()
        self._image:draw(100 - w / 2, 60 - h / 2)
    end
end

return TitleScene