-- game/core/scoreConfig.lua
-- Все "магические числа" по очкам собраны здесь, чтобы их было удобно
-- крутить, не залезая в логику игры.

ScoreConfig = {}

-- ── Очки, начисляемые в начале уровня (бонус) ────────────────────────────────
-- Ключ — номер уровня (тот же startLevel/currentLevel, что и в world.ldtk).
-- Если для уровня нет записи — используется DEFAULT_START_SCORE.
ScoreConfig.DEFAULT_START_SCORE = 0

ScoreConfig.startScore = {
    [1] = 0,
    [2] = 10,
    [3] = 0,
    -- [4] = 10,  -- пример: на 4-м уровне игрок стартует с 10 очками
}

-- ── Пороги очков для звёзд на экране завершения уровня ───────────────────────
-- Если для уровня нет записи — используется DEFAULT_STAR_THRESHOLDS.
ScoreConfig.DEFAULT_STAR_THRESHOLDS = { 0, 50 }

ScoreConfig.starThresholds = {
    [1] = { 0, 50 },
    [2] = { 50, 100 },
    [3] = { 40, 60 },
}

function ScoreConfig.getStartScore(level)
    return ScoreConfig.startScore[level] or ScoreConfig.DEFAULT_START_SCORE
end

function ScoreConfig.getStarThresholds(level)
    return ScoreConfig.starThresholds[level] or ScoreConfig.DEFAULT_STAR_THRESHOLDS
end