-- game/core/saveManager.lua
-- Хранит: последний доступный уровень (Continue) и лучший счёт по каждому
-- пройденному уровню (для отображения порогов в LevelSelect).

SaveManager = {}

local SAVE_FILENAME = "save"

SaveManager.currentLevel = 1
SaveManager.levelScores  = {} -- [level] = лучший счёт, набранный на этом уровне

local function persist()
    playdate.datastore.write({
        currentLevel = SaveManager.currentLevel,
        levelScores  = SaveManager.levelScores,
    }, SAVE_FILENAME)
end

function SaveManager.load()
    local data = playdate.datastore.read(SAVE_FILENAME)
    if data then
        SaveManager.currentLevel = data.currentLevel or 1
        SaveManager.levelScores  = data.levelScores or {}
    else
        SaveManager.currentLevel = 1
        SaveManager.levelScores  = {}
    end
    print("[SaveManager] загружено: currentLevel=" .. SaveManager.currentLevel)
end

-- Вызывать при переходе на следующий уровень. Никогда не откатывается назад
-- и не превышает totalLevels.
function SaveManager.setProgress(level, totalLevels)
    if not level then return end
    if totalLevels then
        level = math.min(level, totalLevels)
    end
    if level <= SaveManager.currentLevel then return end

    SaveManager.currentLevel = level
    persist()
    print("[SaveManager] сохранено: currentLevel=" .. level)
end

function SaveManager.getCurrentLevel()
    return SaveManager.currentLevel
end

-- Сохраняет лучший результат по очкам для конкретного уровня (только рекорд)
function SaveManager.setLevelScore(level, score)
    if not level or not score then return end
    local best = SaveManager.levelScores[level] or 0
    if score > best then
        SaveManager.levelScores[level] = score
        persist()
        print("[SaveManager] лучший счёт уровня " .. level .. ": " .. score)
    end
end

function SaveManager.getLevelScore(level)
    return SaveManager.levelScores[level] or 0
end

-- DEBUG
function SaveManager.reset()
    SaveManager.currentLevel = 1
    SaveManager.levelScores  = {}
    persist()
    print("[SaveManager] сброшено")
end