import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "libs/AnimatedSprite"
import "libs/SceneManager"
import "libs/LDtk"
import "libs/pdDialogue"

import "game/assets"
import "game/level"
import "game/player"
import "game/promptHint"
import "game/npc"
import "game/exit"
import "game/treasure"
import "game/treasureManager"
import "game/scorePopup"
import "game/levelComplete"
import "game/spellbook"
import "game/projectile"
import "game/placedBlock"
import "game/anchorMarker"
import "game/bounceBlock"
import "game/smokeEffect"
import "game/spike"
import "game/crumblingBlock"
import "game/portal"
import "game/key"
import "game/keyBlock"
import "game/blockIndicator"
import "game/flyingEnemy"
import "game/debtCollector"
import "game/taxZoneTile"

import "scenes/SplashScene"
import "scenes/GameScene"
import "scenes/TitleScene"

local pd  <const> = playdate
local gfx <const> = pd.graphics

SceneManager.register("splash", SplashScene)
SceneManager.register("game",   GameScene)
SceneManager.register("title", TitleScene)

-- Настройка окна диалога под игровое разрешение 200x120
pdDialogue.set("width", 190)
pdDialogue.set("height", 40)
pdDialogue.set("x", 5)
pdDialogue.set("y", 74)
pdDialogue.set("padding", 4)

pd.display.setScale(2)
SceneManager.go("splash", nil, SceneManager.transitions.cut)


function pd.update()
    SceneManager.update()
    gfx.sprite.update()
    SceneManager.drawOverlay()
    pdDialogue.update()
    pd.timer.updateTimers()
    --pd.drawFPS(1,1)
end

function pd.cranked(change, acceleratedChange)
    SceneManager.cranked(change, acceleratedChange)
end