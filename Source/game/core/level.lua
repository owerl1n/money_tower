local pd  <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

ldtk.load("level/world.ldtk", usePrecomputedLevels)

if pd.isSimulator then
    ldtk.export_to_lua_files()
end

class('Level').extends()

local TAX_LAYER_NAME = "Tax"
local TAX_MULTIPLIER = 2

function Level:init(levelName)
    self.levelName = levelName
    self:goToLevel(levelName)
end

function Level:getTaxMultiplierAt(worldX, worldY, w, h)
    if LDtk.has_tile_in_rect(self.levelName, TAX_LAYER_NAME, worldX - 6, worldY, w or 0, h or 0) then
        return TAX_MULTIPLIER
    end
    return 1
end

function Level:getNeighbour(direction)
    local neighbours = ldtk.get_neighbours(self.levelName, direction)
    return neighbours and neighbours[1]
end

function Level:_spawnTaxZoneTiles(layer)
    local imageTable = layer.tileset_image
    if not imageTable then return end

    local gsize = layer.grid_size
    local width = layer.tilemap_width

    for index, tileID in ipairs(layer.tiles) do
        if tileID ~= 0 then
            local cellIndex = index - 1
            local cx = cellIndex % width
            local cy = cellIndex // width

            local worldX = layer.rect.x + cx * gsize
            local worldY = layer.rect.y + cy * gsize

            local image = imageTable[tileID]
            if image then
                TaxZoneTile(worldX + 6, worldY, image, layer.zIndex)
            end
        end
    end
end

function Level:goToLevel(levelName)
    if not levelName then return end

    self.levelName = levelName

    gfx.sprite.removeAll()
    Portal.resetRegistry()
    KeyBlock.resetRegistry()

    local rect = ldtk.get_rect(levelName) -- {x=, y=, width=, height=}
    local offsetX = math.floor((196 - rect.width) / 2)
    local offsetY = math.floor((120 - rect.height) / 2)
    gfx.setDrawOffset(offsetX - 4, offsetY)

    for layerName, layer in pairs(ldtk.get_layers(levelName)) do
        if layer.tiles then
            if layerName == TAX_LAYER_NAME then
                self:_spawnTaxZoneTiles(layer)
            else
                local tilemap = ldtk.create_tilemap(levelName, layerName)

                local layerSprite = gfx.sprite.new()
                layerSprite:setTilemap(tilemap)
                layerSprite:moveTo(0, 0)
                layerSprite:setCenter(0, 0)
                layerSprite:setZIndex(layer.zIndex)
                layerSprite:add()

                local emptyTiles = ldtk.get_empty_tileIDs(levelName, "Solid", layerName)
                if emptyTiles then
                    local wallSprites = gfx.sprite.addWallSprites(tilemap, emptyTiles)
                    for _, wallSprite in ipairs(wallSprites) do
                        wallSprite.type = "Solid"
                    end
                end
            end
        end
    end

    for _, entity in ipairs(ldtk.get_entities(levelName)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name

        if entityName == "Ability" then
            Ability(entityX, entityY, entity)
        elseif entityName == "Exit" then
            Exit(entityX, entityY, entity)
        elseif entityName == "Portal" then
            Portal(entityX + 8, entityY + 8, entity)
        elseif entityName == "Treasure" then
            local kind = "coin"
            if entity.fields and entity.fields.Kind then
                kind = string.lower(entity.fields.Kind)
            end
            Treasure(entityX + 8, entityY + 8, kind, entity)
        elseif entityName == "Spikes" then
            Spike(entityX, entityY, entity)
        elseif entityName == "CrumblingBlock" then
            CrumblingBlock(entityX, entityY)
        elseif entityName == "Key" then
            Key(entityX + 8, entityY + 8, entity)
        elseif entityName == "KeyBlock" then
            KeyBlock(entityX, entityY)
        elseif entityName == "FlyingEnemy" then
            FlyingEnemy(entityX + 8, entityY + 8, entity)
        elseif entityName == "DebtCollector" then
            DebtCollector(entityX + 8, entityY + 8, entity)
        elseif entityName == "NPC" then
            NPC(entityX + 8, entityY + 16, entity)
        elseif entityName == "Spawn" then
            self.spawnX = entityX + 8
            self.spawnY = entityY + 8
        end
        
    end

    if not self.spawnX or not self.spawnY then
        print("⚠️ WARNING: No Spawn entity found in level " .. levelName)
        self.spawnX = self.spawnX or 80
        self.spawnY = self.spawnY or 80
    end
end