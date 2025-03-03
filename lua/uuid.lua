-- 乱加的功能
-- 开发指南：
-- https://docs.nopdan.com/rime/Scripting.html

-- UUID
local function guid()
    local seed={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb={}
    for i=1,32 do
        table.insert(tb,seed[math.random(1,16)])
    end
    local sid=table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(sid,1,8),
        string.sub(sid,9,12),
        string.sub(sid,13,16),
        string.sub(sid,17,20),
        string.sub(sid,21,32)
    )
end


local M = {}

function M.init(env)
    M.uuid = "uuid"
end

function M.func(input, seg, env)
    -- UUID
    if (input == M.uuid) then
        local cand = Candidate("UUID", seg.start, seg._end, guid(), " -V4")
        cand.quality = 100
        yield(cand)
    end
end

return M
