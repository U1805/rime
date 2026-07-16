-- ae 前缀 emoji 模式：长码优先
-- 按候选覆盖的输入长度降序排列，使 qiee→🐧 优先于 qi→🏳️
local M = {}

function M.init(env)
end

function M.func(input, env)
  local seg = env.engine.context.composition:back()

  -- 仅处理 emojis 段，其他段原样透传
  if not (seg and seg:has_tag("emojis")) then
    for cand in input:iter() do
      yield(cand)
    end
    return
  end

  -- 收集所有候选，按覆盖长度降序排列
  local cands = {}
  for cand in input:iter() do
    table.insert(cands, cand)
  end

  table.sort(cands, function(a, b)
    local a_len = a._end - a.start
    local b_len = b._end - b.start
    -- 覆盖更长的排在前面
    if a_len ~= b_len then
      return a_len > b_len
    end
    -- 长度相同时保持原始顺序
    return false
  end)

  for _, cand in ipairs(cands) do
    yield(cand)
  end
end

return M
