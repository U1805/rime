-- amzxyz@https://github.com/amzxyz/rime-wanxiang
-- 万象输入统计 · 效率仪表盘 · 改
-- 触发: 输入 stats，选择菜单项后自动上屏报告

local userdb = require("wanxiang/userdb")
local wanxiang = require("wanxiang/wanxiang")

local _db_pool = {}
local raw_software_name = rime_api.get_distribution_code_name()

-- ==================== 硬编码默认值 ====================
local MERGED_DB_NAME = "lua/stats"

local MENU_TRIGGER = "stats"

-- 菜单选项: { label, days_lookback (0=total, -1=挂接自定义逻辑) }
local MENU_ITEMS = {
    { label = "今日统计", icon = "📅", days = 1 },
    { label = "本周统计", icon = "📆", days = 7 },
    { label = "本月统计", icon = "🗓️", days = 30 },
    { label = "年度统计", icon = "📋", days = 365 },
    { label = "生涯统计", icon = "🏆", days = 0 },
    { label = "历史查询", icon = "🕰️", days = -1 },
    { label = "清理统计", icon = "🗑️", days = -2 },
}

local DEFAULT_TITLES = {
    { threshold = 5000000, name = "⌨️·天人合一" },
    { threshold = 1000000, name = "⌨️·登峰造极" },
    { threshold = 500000,  name = "✨·出神入化" },
    { threshold = 100000,  name = "💨·行云流水" },
    { threshold = 50000,   name = "🚀·运指如飞" },
    { threshold = 10000,   name = "🌟·渐入佳境" },
    { threshold = 0,       name = "🌱·初学乍练" },
}

-- ==================== 数据库 ====================

local function get_db(env)
    -- 优先从 schema 读取 db_name，否则用硬编码默认值
    local config = env.engine.schema.config
    local db_name = config:get_string("input_stats/db_name") or MERGED_DB_NAME
    if not _db_pool[db_name] then
        _db_pool[db_name] = userdb.LevelDb(db_name)
    end
    local db = _db_pool[db_name]
    if db and not db:loaded() then db:open() end
    return db
end

local function db_get(db, key)
    return tonumber(db:fetch(key)) or 0
end

local function clear_all_data(env)
    local db = get_db(env)
    if not db or not db:loaded() then return false end
    if db.empty then
        db:empty()
        speed_buffer = {}
        pending_stats = {}
        pending_max_speeds = {}
        return true
    end
    local iter = db:query("")
    if iter then
        local keys = {}
        for key, _ in iter do table.insert(keys, key) end
        for _, key in ipairs(keys) do db:erase(key) end
        speed_buffer = {}
        pending_stats = {}
        pending_max_speeds = {}
        return true
    end
    return false
end

-- ==================== 平台信息 ====================

local function process_platform_info(name, ver)
    name = name or ""
    ver = ver or ""
    ver = ver:match("^([vV]?%d+%.%d+%.%d+)") or ver
    if name == "Weasel" then name = "小狼毫" end
    if name == "trime" then name = "同文输入法" end
    if name == "hamster3" then name = "元书输入法" end
    if name == "hamster" then name = "仓输入法" end
    if name == "lyraime" then name = "灵韵输入法" end
    if name == "xime" then name = "曦码输入法" end
    if name == "default" then name = "超越输入法" end
    return name, ver
end

-- ==================== 汉字识别 ====================

local function is_chinese_code(c)
    return (c >= 0x4E00 and c <= 0x9FFF) or (c >= 0x3400 and c <= 0x4DBF) or
           (c >= 0x20000 and c <= 0x2A6DF) or (c >= 0x2A700 and c <= 0x2B73F) or
           (c >= 0x2B740 and c <= 0x2B81F) or (c >= 0x2B820 and c <= 0x2CEAF) or
           (c >= 0x2CEB0 and c <= 0x2EBEF) or (c >= 0x30000 and c <= 0x3134F) or
           (c >= 0x31350 and c <= 0x323AF) or (c >= 0x2EBF0 and c <= 0x2EE5F) or
           (c >= 0xF900  and c <= 0xFAFF) or (c >= 0x2F800 and c <= 0x2FA1F) or
           (c >= 0x2E80  and c <= 0x2EFF) or (c >= 0x2F00  and c <= 0x2FDF)
end

local function get_pure_chinese_length(text)
    local count = 0
    for _, code in utf8.codes(text) do
        if is_chinese_code(code) then count = count + 1 end
    end
    return count
end

-- ==================== 速度跟踪 ====================

local speed_buffer = {}
local last_cleanup_ts = 0
local pending_stats = {}      -- { [day_key] = { ["_len"]=N, ["_cnt"]=N, ... } }
local pending_max_speeds = {} -- { [day_key] = { ["_spd"]=N } }
local BATCH_INTERVAL = 5      -- 最多每5秒落盘一次
local MAX_PENDING_WORDS = 200 -- 积累超过200字时强制刷盘
local last_flush_ts = 0

local function get_current_kpm(now)
    if now - last_cleanup_ts > 5 then
        local new_buf = {}
        local threshold = now - 60
        for _, item in ipairs(speed_buffer) do
            if item.ts > threshold then table.insert(new_buf, item) end
        end
        speed_buffer = new_buf
        last_cleanup_ts = now
    end
    local total = 0
    local threshold = now - 60
    for _, item in ipairs(speed_buffer) do
        if item.ts > threshold then total = total + item.len end
    end
    return total
end

local function pending_accum(day_key, suffix, amount)
    if not pending_stats[day_key] then pending_stats[day_key] = {} end
    pending_stats[day_key][suffix] = (pending_stats[day_key][suffix] or 0) + amount
end

local function pending_max(day_key, suffix, new_val)
    if not pending_max_speeds[day_key] then pending_max_speeds[day_key] = {} end
    local old = pending_max_speeds[day_key][suffix] or 0
    if new_val > old then pending_max_speeds[day_key][suffix] = new_val end
end

local function do_flush(env)
    if not pending_stats or next(pending_stats) == nil then return end
    local db = get_db(env)
    if not db or not db:loaded() then return end
    
    for day_key, fields in pairs(pending_stats) do
        for suffix, amount in pairs(fields) do
            local d_key = day_key .. suffix
            local old_val = tonumber(db:fetch(d_key)) or 0
            db:update(d_key, tostring(old_val + amount))
            local t_key = "total" .. suffix
            local total_val = tonumber(db:fetch(t_key)) or 0
            db:update(t_key, tostring(total_val + amount))
        end
    end
    
    for day_key, max_fields in pairs(pending_max_speeds) do
        for suffix, new_val in pairs(max_fields) do
            local d_key = day_key .. suffix
            local old_val = tonumber(db:fetch(d_key)) or 0
            if new_val > old_val then db:update(d_key, tostring(new_val)) end
            local t_key = "total" .. suffix
            local total_val = tonumber(db:fetch(t_key)) or 0
            if new_val > total_val then db:update(t_key, tostring(new_val)) end
        end
    end
    
    pending_stats = {}
    pending_max_speeds = {}
    last_flush_ts = os.time()
end

local function try_flush(env)
    local now = os.time()
    -- 估算 pending 总字数
    local total_words = 0
    for _, fields in pairs(pending_stats) do
        total_words = total_words + (fields["_len"] or 0)
    end
    if total_words >= MAX_PENDING_WORDS or now - last_flush_ts >= BATCH_INTERVAL then
        do_flush(env)
    end
end

local function record_stats_mem(env, hanzi_len, code_len)
    local now = os.time()
    local t = os.date("*t", now)
    local day_key = string.format("d_%04d%02d%02d", t.year, t.month, t.day)
    
    local current_kpm = 0
    if hanzi_len <= 30 then table.insert(speed_buffer, {ts = now, len = hanzi_len}) end
    current_kpm = get_current_kpm(now)
    
    pending_accum(day_key, "_len", hanzi_len)
    pending_accum(day_key, "_cnt", 1)
    pending_accum(day_key, "_code", code_len)
    
    if hanzi_len == 1 then pending_accum(day_key, "_l1", 1)
    elseif hanzi_len == 2 then pending_accum(day_key, "_l2", 1)
    elseif hanzi_len == 3 then pending_accum(day_key, "_l3", 1)
    elseif hanzi_len == 4 then pending_accum(day_key, "_l4", 1)
    elseif hanzi_len > 4 then pending_accum(day_key, "_l_gt4", 1) end
    
    pending_max(day_key, "_spd", current_kpm)
end

-- ==================== 数据聚合 ====================

local function aggregate_stats(env, days_lookback)
    local db = get_db(env)
    if not db or not db:loaded() then return nil end
    if days_lookback == 0 then
        local p = "total"
        return {
            len = db_get(db, p .. "_len"), cnt = db_get(db, p .. "_cnt"),
            code = db_get(db, p .. "_code"), spd = db_get(db, p .. "_spd"),
            l1 = db_get(db, p .. "_l1"), l2 = db_get(db, p .. "_l2"),
            l3 = db_get(db, p .. "_l3"), l4 = db_get(db, p .. "_l4"),
            l_gt4 = db_get(db, p .. "_l_gt4"),
        }
    end
    local res = {len=0, cnt=0, code=0, spd=0, l1=0, l2=0, l3=0, l4=0, l_gt4=0}
    local now_ts = os.time()
    for i = 0, days_lookback - 1 do
        local t = os.date("*t", now_ts - i * 86400)
        local dk = string.format("d_%04d%02d%02d", t.year, t.month, t.day)
        res.len = res.len + db_get(db, dk .. "_len")
        res.cnt = res.cnt + db_get(db, dk .. "_cnt")
        res.code = res.code + db_get(db, dk .. "_code")
        res.l1 = res.l1 + db_get(db, dk .. "_l1")
        res.l2 = res.l2 + db_get(db, dk .. "_l2")
        res.l3 = res.l3 + db_get(db, dk .. "_l3")
        res.l4 = res.l4 + db_get(db, dk .. "_l4")
        res.l_gt4 = res.l_gt4 + db_get(db, dk .. "_l_gt4")
        local ds = db_get(db, dk .. "_spd")
        if ds > res.spd then res.spd = ds end
    end
    return res
end

-- ==================== 段位系统 ====================

local function get_user_title(env)
    local db = get_db(env)
    if not db or not db:loaded() then return "初学乍练" end
    local current_len = db_get(db, "total_len")
    for _, item in ipairs(env.titles) do
        if current_len >= item.threshold then return item.name end
    end
    return "初学乍练"
end

local function load_titles(env)
    local config = env.engine.schema.config
    local custom_titles = config:get_list("input_stats/titles")
    if custom_titles and custom_titles.size > 0 then
        local titles = {}
        for i = 0, custom_titles.size - 1 do
            local item = custom_titles:get_value_at(i)
            if item and item.value then
                local t_val, t_name = item.value:match("^(%d+):(.+)$")
                if t_val and t_name then table.insert(titles, { threshold = tonumber(t_val), name = t_name }) end
            end
        end
        if #titles > 0 then
            table.sort(titles, function(a, b) return a.threshold > b.threshold end)
            return titles
        end
    end
    return DEFAULT_TITLES
end

-- ==================== 报告格式化 ====================

local function draw_bar(percent)
    local length = 10
    local filled_len = math.floor((percent / 100) * length)
    return string.rep("▓", filled_len) .. string.rep("░", length - filled_len)
end

local function format_summary(title, subtitle, data, env)
    if not data or data.cnt == 0 then return "※ " .. title .. "暂无数据" end
    local avg_code = data.len > 0 and (data.code / data.len) or 0
    local phrase_rate = data.len > 0 and ((data.len - data.l1) / data.len * 100) or 0
    local estimated_avg_spd = 0
    if data.cnt > 0 then
        estimated_avg_spd = math.floor(data.len / ((data.cnt * 2) / 60))
        if estimated_avg_spd > data.spd then estimated_avg_spd = math.floor(data.spd * 0.8) end
        if estimated_avg_spd == 0 and data.len > 0 then estimated_avg_spd = data.len end
    end
    local p1 = data.cnt > 0 and (data.l1 / data.cnt * 100) or 0
    local p2 = data.cnt > 0 and (data.l2 / data.cnt * 100) or 0
    local p3 = data.cnt > 0 and (data.l3 / data.cnt * 100) or 0
    local p4 = data.cnt > 0 and (data.l4 / data.cnt * 100) or 0
    local pgt4 = data.cnt > 0 and (data.l_gt4 / data.cnt * 100) or 0

    local raw_ver = rime_api.get_distribution_version() or ""
    local clean_name, clean_ver = process_platform_info(raw_software_name, raw_ver)
    local user_achievement = get_user_title(env)
    local finger_style = wanxiang.get_input_method_type(env)
    local finger_style_map = {
        ["pinyin"]="全拼", ["zrm"]="自然码", ["flypy"]="小鹤双拼", ["mspy"]="微软双拼",
        ["sogou"]="搜狗双拼", ["abc"]="智能ABC", ["ziguang"]="紫光双拼", ["pyjj"]="拼音加加",
        ["gbpy"]="国标双拼", ["zrlong"]="自然龙", ["hxlong"]="汉心龙", ["ltsp"]="蓝天双拼",
        ["lxsq"]="乱序17", ["sdpy"]="首道双拼", ["t9"]="九键",
    }
    local finger_label = finger_style_map[finger_style] or finger_style

    local header = string.format("※ %s统计 · 效率仪表盘\n", title)
    if subtitle and subtitle ~= "" then
        header = header .. string.format("📅 %s\n", subtitle)
    end
    local z = "\226\128\139"  -- ZWSP 用于横向展开
    return header .. string.format(
        "───────────────" .. z .. "\n" ..
        "📊 综合数据" .. z .. "\n" ..
        "  均速:%-5d 上屏:%d" .. z .. "\n" ..
        "  峰速:%-5d 字数:%d" .. z .. "\n" ..
        "🏆 段位：%s" .. z .. "\n" ..
        "───────────────" .. z .. "\n" ..
        "⚡ 核心效率" .. z .. "\n" ..
        "  平均编码：%.2f 键/字" .. z .. "\n" ..
        "  词组连打：%.1f %%" .. z .. "\n" ..
        "───────────────" .. z .. "\n" ..
        "📈 字词分布" .. z .. "\n" ..
        "  [1] %3d%% %s" .. z .. "\n" ..
        "  [2] %3d%% %s" .. z .. "\n" ..
        "  [3] %3d%% %s" .. z .. "\n" ..
        "  [4] %3d%% %s" .. z .. "\n" ..
        "  [+] %2d%% %s" .. z .. "\n" ..
        "───────────────" .. z .. "\n" ..
        "◉ 方案：%s" .. z .. "\n" ..
        "◉ 编码：%s" .. z .. "\n" ..
        "◉ 前端：%s %s" .. z,
        math.floor(estimated_avg_spd), math.floor(data.cnt),
        math.floor(data.spd), math.floor(data.len),
        user_achievement, avg_code, phrase_rate,
        math.floor(p1), draw_bar(p1), math.floor(p2), draw_bar(p2),
        math.floor(p3), draw_bar(p3), math.floor(p4), draw_bar(p4),
        math.floor(pgt4), draw_bar(pgt4),
        env.schema_name, finger_label, clean_name, clean_ver
    )
end

-- ==================== 菜单命令 → 实际动作映射 ====================

-- 菜单标签到 aggregate_stats 参数的映射（-1=历史帮助, -2=清理）
local MENU_DAYS = {
    ["[今日统计]"] = { days = 1,  title = "今日" },
    ["[本周统计]"] = { days = 7,  title = "七日" },
    ["[本月统计]"] = { days = 30, title = "卅日" },
    ["[年度统计]"] = { days = 365,title = "本年" },
    ["[生涯统计]"] = { days = 0,  title = "生涯" },
    ["[清理统计]"] = { days = -2 },
    ["[历史查询]"] = { days = -1 },
}

local function handle_menu_commit(env, commit_text)
    local cmd = MENU_DAYS[commit_text]
    if not cmd then return false end

    if cmd.days == -1 then
        -- 历史查询: 输出帮助
        env.engine:commit_text("※ 历史查询功能开发中")
        return true
    end

    if cmd.days == -2 then
        clear_all_data(env)
        env.engine:commit_text("🗑️ ※ 统计数据已全部清空。")
        return true
    end

    -- 普通统计: 查数据 → 格式化 → 自动上屏
    local data = aggregate_stats(env, cmd.days)
    local report
    if data and data.cnt > 0 then
        report = format_summary(cmd.title, nil, data, env)
    else
        report = "※ " .. cmd.title .. "暂无数据"
    end
    env.engine:commit_text(report)
    return true
end

-- ==================== 初始化 / 销毁 ====================

local function init(env)
    env.schema_name = env.engine.schema.schema_name or "万象方案"
    env.titles = load_titles(env)
    get_db(env)

    if env.stat_notifier then env.stat_notifier:disconnect() end
    local ctx = env.engine.context

    env.stat_notifier = ctx.commit_notifier:connect(function(ctx)
        local commit_text = ctx:get_commit_text()
        if not commit_text or commit_text == "" then return end

        -- 菜单命令: 检测 [...] 标签 → 执行对应动作 → 自动上屏报告
        if commit_text:sub(1, 1) == "[" and handle_menu_commit(env, commit_text) then
            return
        end

        -- 跳过统计报告文本，不纳入打字统计
        if commit_text:find("^[※◉🏆📊⚡📈🗑️]") then return end

        local hanzi_len = get_pure_chinese_length(commit_text)
        if hanzi_len == 0 then return end
        local raw_input = ctx.input or ""
        local code_len = string.len(raw_input)
        if code_len == 0 then code_len = hanzi_len * 2 end
        record_stats_mem(env, hanzi_len, code_len)
        try_flush(env)
    end)
end

local function fini(env)
    do_flush(env)
    if env.stat_notifier then
        env.stat_notifier:disconnect()
        env.stat_notifier = nil
    end
end

-- ==================== Translator ====================

local function translator(input, seg, env)
    try_flush(env)

    -- ===== 菜单模式: stats → 仅显示标签，实际动作由 commit_notifier 处理 =====
    if input == MENU_TRIGGER then
        for _, item in ipairs(MENU_ITEMS) do
            local label = "[" .. item.label .. "]"
            yield(Candidate("stat", seg.start, seg._end, label, item.icon))
        end
        return
    end
end

return { init = init, func = translator, fini = fini }
