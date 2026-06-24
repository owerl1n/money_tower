import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "libs/AnimatedSprite"
import "libs/SceneManager"
import "libs/LDtk"

import "game/level"
import "game/player"
import "game/animTile"
import "game/coin"
import "game/coinManager"
import "game/coinPopup"
import "game/levelComplete"
import "game/spellbook"
import "game/projectile"
import "game/placedBlock"
import "game/anchorMarker"
import "game/bounceBlock"
import "game/smokeEffect"
import "game/spike"

import "scenes/SplashScene"
import "scenes/GameScene"
import "scenes/TitleScene"

local pd  <const> = playdate
local gfx <const> = pd.graphics

-- Регистрируем сцены
SceneManager.register("splash", SplashScene)
SceneManager.register("game",   GameScene)
SceneManager.register("title", TitleScene)

pd.display.setScale(2)
SceneManager.go("splash", nil, SceneManager.transitions.cut)


function pd.update()
    SceneManager.update()
    gfx.sprite.update()
    SceneManager.drawOverlay()
    pd.timer.updateTimers()
    --pd.drawFPS(1,1)
end

function pd.cranked(change, acceleratedChange)
    SceneManager.cranked(change, acceleratedChange)
end