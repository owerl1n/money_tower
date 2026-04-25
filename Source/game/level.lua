local pd  <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

ldtk.load("level/world.ldtk", usePrecomputedLevels)

if pd.isSimulator then
    ldtk.export_to_lua_files()
end

class('Level').extends()

function Level:init(levelName)
    self.levelName = levelName

    self:goToLevel("Level_0")
end


function Level:getNeighbour(direction)
    local neighbours = ldtk.get_neighbours(self.levelName, direction)
    return neighbours and neighbours[1]
end

function Level:goToLevel(levelName)
    if not levelName then return end

    self.levelName = levelName

    gfx.sprite.removeAll()

    for layerName, layer in pairs(ldtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = ldtk.create_tilemap(levelName, layerName)

            local layerSprite = gfx.sprite.new()
            layerSprite:setTilemap(tilemap)
            layerSprite:moveTo(0, 0)
            layerSprite:setCenter(0, 0)
            layerSprite:setZIndex(layer.zIndex)
            layerSprite:add()

            local emptyTiles = ldtk.get_empty_tileIDs(levelName, "Solid", layerName)
            if emptyTiles then
                gfx.sprite.addWallSprites(tilemap, emptyTiles)
            end
        end
    end

    for _, entity in ipairs(ldtk.get_entities(levelName)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name
        if entityName == "Ability" then
            Ability(entityX, entityY, entity)
        elseif entityName == "Teleport" then
            Teleport(entityX, entityY, entity, self)
        elseif entityName == "Zombie" then
            Zombie(entityX, entityY, entity)
        end
    end
end