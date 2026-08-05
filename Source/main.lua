import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "libs/AnimatedSprite"
import "libs/SceneManager"
import "libs/LDtk"
import "libs/pdDialogue"

import "game/core/game"
import "game/core/assets"
import "game/core/level"
import "game/core/treasureManager"

import "game/entities/player/player"
import "game/entities/player/promptHint"
import "game/entities/player/scorePopup"
import "game/entities/player/projectile"
import "game/entities/hazards/crumblingBlock"
import "game/entities/hazards/exit"
import "game/entities/hazards/spike"
import "game/entities/hazards/portal"
import "game/entities/hazards/bounceBlock"
import "game/entities/hazards/keyBlock"
import "game/entities/pickups/treasure"
import "game/entities/pickups/key"
import "game/entities/npc/npc"
import "game/entities/enemies/flyingEnemy"
import "game/entities/enemies/debtCollector"
import "game/entities/effects/taxZoneTile"
import "game/entities/effects/smokeEffect"
import "game/entities/blocks/placedBlock"
import "game/entities/blocks/anchorMarker"
import "game/entities/blocks/blockIndicator"

import "game/ui/levelComplete"

import "game/spells/spellbook"


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
--gfx.setDrawOffset(0, 0)
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