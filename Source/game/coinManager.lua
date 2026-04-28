CoinManager = {}
CoinManager.score = 0
CoinManager.collected = 0

function CoinManager.addCoins(amount)
    CoinManager.score += amount
    CoinManager.collected += 1
    print("[Coins] собрано: " .. CoinManager.collected .. " | очки: " .. CoinManager.score)
end

function CoinManager.reset()
    CoinManager.score = 0
    CoinManager.collected = 0
    print("[Coins] сброс")
end