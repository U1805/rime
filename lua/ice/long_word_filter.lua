-- 长词优先（提升「西安」「提案」「图案」「饥饿」等词汇的优先级）
-- 感谢&参考于： https://github.com/tumuyan/rime-melt
-- 不提升包含英文、数字的候选项
-- 不提升包含 emoji、假名的候选项（通过将此 Lua 放到 simplifier@emoji 前面来实现）

local M = {}

function M.init(env)
    -- 提升 count 个词语，插入到第 idx 个位置，默认 2、1。
    -- 示例：将 2 个词插入到第 1  个候选项，输入 总算 得到「1总算 2纵」
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub("^*", "")
    M.count = config:get_int(env.name_space .. "/count") or 2
    M.idx = config:get_int(env.name_space .. "/idx") or 1

    M.input_str = env.engine.context.input
end

function M.func(input)
    local preedit_len = 0
    local l = {}
    local firstWordLength = 0 -- 记录第一个候选词的长度，提前的候选词至少要比第一个候选词长
    local done = 0         -- 记录筛选了多少个词条(只提升 count 个词的权重)
    local i = 1
    for cand in input:iter() do
        local leng = utf8.len(cand.text)
        -- 只以第一个候选项的长度作为参考
        if firstWordLength < 1 then
            firstWordLength = leng
        end
        if preedit_len < 1 then
            local str = cand.preedit
            str = str:gsub("%s+", "")
            preedit_len = utf8.len(str)
        end
        
        -- 不处理 M.idx 之前的候选项
        if i < M.idx then
            i = i + 1
            yield(cand)
        -- 长词直接 yield，其余的放到 l 里
        elseif leng <= firstWordLength or cand.text:find("[%a%d]") then
            table.insert(l, cand)
        -- 如果
        elseif firstWordLength == 1 and preedit_len == 4 then
            yield(cand)
            done = done + 1
        elseif firstWordLength == 2 and preedit_len == 6 then
            yield(cand)
            done = done + 1
        elseif firstWordLength <=3 and preedit_len == 8 then
            yield(cand)
            done = done + 1
        elseif firstWordLength <=4 and preedit_len == 10 then
            yield(cand)
            done = done + 1
        else
            table.insert(l, cand)
        end
        -- 找齐了或者 l 太大了，就不找了，一般前 50 个就够了
        if done == M.count or #l > 20 then
            break
        end
    end
    -- yield l 及后续的候选项
    for _, cand in ipairs(l) do
        yield(cand)
    end
    for cand in input:iter() do
        yield(cand)
    end
end

return M
