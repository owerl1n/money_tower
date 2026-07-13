TreasureManager = {}
TreasureManager.score = 0
TreasureManager.collected = 0

function TreasureManager.addScore(amount)
    TreasureManager.score += amount
    TreasureManager.collected += 1
    print("[treasure] собрано: " .. TreasureManager.collected .. " | очки: " .. TreasureManager.score)
end

function TreasureManager.reset()
    TreasureManager.score = 0
    TreasureManager.collected = 0
    print("[treasure] сброс")
end