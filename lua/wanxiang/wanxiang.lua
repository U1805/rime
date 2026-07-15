-- 万象统计模块依赖的精简 wanxiang 工具函数
-- 仅保留 input_statistics.lua 所需的 get_input_method_type()

local wanxiang = {}

wanxiang.INPUT_METHOD_MARKERS = {
    ["Ⅰ"]   = "pinyin",  -- 全拼
    ["Ⅱ"]   = "zrm",     -- 自然码双拼
    ["Ⅲ"]   = "flypy",   -- 小鹤双拼
    ["Ⅳ"]   = "mspy",    -- 微软双拼
    ["Ⅴ"]   = "sogou",   -- 搜狗双拼
    ["Ⅵ"]   = "abc",     -- 智能ABC双拼
    ["Ⅶ"]   = "ziguang", -- 紫光双拼
    ["Ⅷ"]   = "pyjj",    -- 拼音加加
    ["Ⅸ"]   = "gbpy",    -- 国标双拼
    ["Ⅺ"]   = "zrlong",  -- 自然龙
    ["Ⅻ"]   = "hxlong",  -- 汉心龙
    ["Ⅿ"]   = "ltsp",    -- 蓝天双拼
    ["Ⅼ"]   = "lxsq",    -- 乱序17
    ["ⅩⅢ"] = "sdpy",    -- 首道双拼
    ["ⅲ"]   = "ⅲ",       -- 间接辅助标记：命中则额外返回 md="ⅲ"
    ["ⅱ"]   = "t9",      -- 拼音九键
}

local __input_type_cache = {}
local __input_md_cache   = {}

-- 扫描 speller/algebra 中的 Unicode 标记，识别输入方案类型
-- 返回: id（如 "flypy"），可选 md（"ⅲ" 若命中辅助码标记）
function wanxiang.get_input_method_type(env)
    local schema_id = env.engine.schema.schema_id or "unknown"

    local cached_id = __input_type_cache[schema_id]
    if cached_id then
        local cached_md = __input_md_cache[schema_id]
        if cached_md then
            return cached_id, cached_md
        else
            return cached_id
        end
    end

    local cfg = env.engine.schema.config
    local result_id = "unknown"
    local md = nil

    local n = cfg:get_list_size("speller/algebra")
    for i = 0, n - 1 do
        local s = cfg:get_string(("speller/algebra/@%d"):format(i))
        if s then
            for symbol, id in pairs(wanxiang.INPUT_METHOD_MARKERS) do
                if s:find(symbol, 1, true) then
                    if symbol == "ⅲ" or id == "ⅲ" then
                        md = "ⅲ"
                    else
                        if result_id == "unknown" then
                            result_id = id
                        end
                    end
                end
            end
        end
    end

    __input_type_cache[schema_id] = result_id
    __input_md_cache[schema_id] = md

    if md then
        return result_id, md
    else
        return result_id
    end
end

return wanxiang
