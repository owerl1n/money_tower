TreasureManager = {}
TreasureManager.score = 0
TreasureManager.collected = 0

function TreasureManager.trySpend(amount)
    if TreasureManager.score >= amount then
        TreasureManager.score -= amount
        print("[treasure] потрачено: " .. amount .. " | осталось: " .. TreasureManager.score)
        return true
    end
    print("[treasure] недостаточно денег: нужно " .. amount .. ", есть " .. TreasureManager.score)
    return false
end

function TreasureManager.addScore(amount)
    TreasureManager.score += amount
    TreasureManager.collected += 1
    print("[treasure] собрано: " .. TreasureManager.collected .. " | очки: " .. TreasureManager.score)
end

function TreasureManager.addBonus(amount)
    if not amount or amount == 0 then return end
    TreasureManager.score += amount
    print("[treasure] бонус: " .. amount .. " | очки: " .. TreasureManager.score)
end

function TreasureManager.reset()
    TreasureManager.score = 0
    TreasureManager.collected = 0
    print("[treasure] сброс")
end