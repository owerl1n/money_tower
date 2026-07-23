local gfx <const> = playdate.graphics



Tileset = gfx.imagetable.new("level/tileset-table-16-16")
assert(Tileset, "Tileset: не удалось загрузить level/tileset-table-16-16")


Glyphs = gfx.imagetable.new("images/glyphs-table-16-16")
assert(Glyphs, "Assets: не удалось загрузить images/glyphs-table-16-16")

