import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "libs/AnimatedSprite"
import "libs/SceneManager"   -- регистрирует глобальный SceneManager
import "libs/LDtk"

import "game/level"
import "game/player"


import "scenes/SplashScene"
import "scenes/GameScene"

local pd  <const> = playdate
local gfx <const> = pd.graphics

-- Регистрируем сцены
SceneManager.register("splash", SplashScene)
SceneManager.register("game",   GameScene)

-- Стартуем со game
pd.display.setScale(2)
SceneManager.go("splash", nil, SceneManager.transitions.fade)


function pd.update()
    SceneManager.update()
    gfx.sprite.update()
    SceneManager.drawOverlay()
    pd.timer.updateTimers()
    --pd.drawFPS(1,1)
end