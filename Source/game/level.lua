local pd  <const> = playdate
local gfx <const> = playdate.graphics

class('Level').extends()

-- Кэш тайлсета
local tilesetImage = nil

function getTileset()
    if not tilesetImage then
        tilesetImage = gfx.image.new("level/tileset-table-16-16")
    end
    return tilesetImage
end

-- Создаём спрайт одного тайла
function makeTileSprite(tileset, srcX, srcY, destX, destY, zIndex)
    local tileImg = gfx.image.new(16, 16)
    gfx.pushContext(tileImg)
        tileset:draw(-srcX, -srcY)
    gfx.popContext()

    local spr = gfx.sprite.new(tileImg)
    spr:setCenter(0, 0)
    spr:moveTo(destX, destY)
    spr:setZIndex(zIndex or 0)
    spr:setIgnoresDrawOffset(false)
    spr:add()
    return spr
end

-- Создаём collision-спрайт для IntGrid
function makeCollisionSprite(gridX, gridY, offsetX, offsetY)
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    local spr = gfx.sprite.new(img)
    spr:setCenter(0, 0)
    -- pxTotalOffset учитываем
    local wx = gridX * 16 + offsetX
    local wy = gridY * 16 + offsetY
    spr:moveTo(wx, wy)
    spr:setCollideRect(0, 0, 16, 16)
    spr.type = "solid"
    spr:setGroups({2})
    spr:setZIndex(-10)
    spr:add()
    return spr
end

function Level:init(levelData)
    self.sprites = {}   -- все спрайты этого уровня
    self:_load(levelData)
end

function Level:_load(levelData)
    local tileset = getTileset()

    for _, layer in ipairs(levelData.layerInstances) do
        local offX = layer.__pxTotalOffsetX
        local offY = layer.__pxTotalOffsetY

        -- Тайловые слои (Tiles1, Tiles2)
        if layer.__type == "Tiles" then
            local zIndex = (layer.__identifier == "Tiles2") and 5 or 10
            local tiles = layer.gridTiles
            if tiles and #tiles > 0 then
                for _, tile in ipairs(tiles) do
                    local spr = makeTileSprite(
                        tileset,
                        tile.src[1], tile.src[2],
                        tile.px[1] + offX, tile.px[2] + offY,
                        zIndex
                    )
                    table.insert(self.sprites, spr)
                end
            end
            -- autoLayerTiles (для Tiles1 с авто-тайлами)
            local autoTiles = layer.autoLayerTiles
            if autoTiles and #autoTiles > 0 then
                for _, tile in ipairs(autoTiles) do
                    local spr = makeTileSprite(
                        tileset,
                        tile.src[1], tile.src[2],
                        tile.px[1] + offX, tile.px[2] + offY,
                        zIndex - 1
                    )
                    table.insert(self.sprites, spr)
                end
            end

        -- IntGrid (Walls) — коллизии + авто-тайлы фона
        elseif layer.__type == "IntGrid" then
            local cWid = layer.__cWid
            -- Рисуем авто-тайлы (фоновые)
            if layer.autoLayerTiles and #layer.autoLayerTiles > 0 then
                for _, tile in ipairs(layer.autoLayerTiles) do
                    local spr = makeTileSprite(
                        tileset,
                        tile.src[1], tile.src[2],
                        tile.px[1] + offX, tile.px[2] + offY,
                        -5
                    )
                    table.insert(self.sprites, spr)
                end
            end
            -- Коллизии из intGridCsv
            if layer.intGridCsv then
                for i, val in ipairs(layer.intGridCsv) do
                    if val == 1 then
                        local gx = (i - 1) % cWid
                        local gy = math.floor((i - 1) / cWid)
                        local spr = makeCollisionSprite(gx, gy, offX, offY)
                        table.insert(self.sprites, spr)
                    end
                end
            end
        end
    end
end

-- Удалить все спрайты уровня со сцены
function Level:unload()
    for _, spr in ipairs(self.sprites) do
        spr:remove()
    end
    self.sprites = {}
end