local pd  <const> = playdate
local gfx <const> = playdate.graphics

import "libs/AnimatedSprite"
import "game/level"
import "game/player"

class('Game').extends()

Game.instance = nil

TAGS = {
    Pickup = 1,
    Player = 2,
    Hazard = 3,
    Exit = 4,
    Projectile = 5,
    Block = 6,
    AnchorMark = 7,
    BounceBlock = 8,
    CrumblingBlock = 9,
}

Z_INDEXES = {
    Hazard = 20,
    Pickup = 50,
    Player = 100
}

function Game:init(startLevel, onNextLevel, onRestart)
    startLevel = startLevel or 0

    local world = json.decodeFile("level/world.ldtk")
    assert(world, "Не удалось загрузить world.ldtk")

    local levelData = world.levels[startLevel]
    assert(levelData, "Уровень " .. startLevel .. " не найден в world.ldtk")
    local levelName = levelData.identifier
    print("Загружаем уровень:", levelName)
    self.currentLevel = startLevel

    local totalLevels = #world.levels
    local nextLevel   = startLevel < totalLevels and (startLevel + 1) or startLevel

    self.currentLevel = startLevel

    self.levelComplete = LevelComplete(
        startLevel,
        function()  -- onNext
            CoinManager.reset()
            if onNextLevel then
                onNextLevel(nextLevel)
            end
        end,
        function()  -- onRestart
            CoinManager.reset()
            if onRestart then
                onRestart(startLevel)
            end
        end
    )

    self.level  = Level(levelName)

    self.player = Player(self.level.spawnX, self.level.spawnY, self.levelComplete)

    self._activeSlot   = 2 -- добавь это поле до SpellBook

    self.spellbook     = SpellBook(self.levelComplete, function(slot)
        if slot ~= self._activeSlot then
            local prev = SPELLS[self._activeSlot]
            if prev and prev.onUnequip then
                prev.onUnequip(self.player)
            end
            self._activeSlot = slot
        end

        local spell = SPELLS[slot]
        if spell and spell.onEquip then
            spell.onEquip(self.player)
            print("[Spell] equipped: " .. spell.name)
        end
    end)

    -- Применяем заклинание Block по умолчанию (слот 1)
    local defaultSpell = SPELLS[2]
    if defaultSpell and defaultSpell.onEquip then
        defaultSpell.onEquip(self.player)
        print("[Spell] default equipped: " .. defaultSpell.name)
    end

    self.hud = {
        draw = function()
            self.player.coinPopup:draw()
            self.levelComplete:draw()
        end
    }
end

function Game:update()
    self.spellbook:update()

    if not self.spellbook:isActive() then
        self.player.coinPopup:update()
        self.levelComplete:update()
    end
end

function Game:handleInput()
    if self.player.dead then return end
    -- Когда книга открыта — ▲/▼ переключают слоты, A/B закрывают
    if self.spellbook:isActive() then
        if pd.buttonJustPressed(pd.kButtonUp) then
            self.spellbook:onUp()
        elseif pd.buttonJustPressed(pd.kButtonDown) then
            self.spellbook:onDown()
        elseif pd.buttonJustPressed(pd.kButtonB) then
            self.spellbook:onButtonB()
        elseif pd.buttonJustPressed(pd.kButtonA) then
            self.spellbook:onButtonA()
        end
        return
    end

    -- Книга закрыта — B открывает книгу
    if pd.buttonJustPressed(pd.kButtonB) then
        self.spellbook:onButtonB()
    end
end

function Game:handleCrank(change, acceleratedChange)
    -- кранк больше не используется для книги
end