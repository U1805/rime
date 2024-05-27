-- 乱加的功能
-- 开发指南：
-- https://docs.nopdan.com/rime/Scripting.html

-- 获取用户目录
local function getCurrentDir()
function sum(a, b)
    return a + b
end
local info = debug.getinfo(sum)
local path = info.source
path = string.sub(path, 2, -1) -- 去掉开头的"@"
path = string.match(path, "^(.*[\\/])") -- 捕获目录路径
local spacer = string.match(path,"[\\/]")
path=string.gsub(path,'[\\/]',spacer)  .. ".." .. spacer 
return path
end

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
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    M.uuid = config:get_string(env.name_space .. '/uuid') or 'guid'
end

function M.func(input, seg, env)
    -- UUID
    if (input == M.uuid) then
        local cand = Candidate("UUID", seg.start, seg._end, guid(), " -V4")
        cand.quality = 100
        yield(cand)
    -- 保存自定义词
    else
        local inpu = string.gsub(input,"[/]+$","")
        if (string.len(inpu) > 1 and string.sub(input,1,1) ~= "/") then
            if ( string.sub(input,-2)  == "//") then
                local context = env.engine.context
                local history_str = context.commit_history:latest_text()
                
                if history_str ~= "" then
                    ppath = getCurrentDir() .. "custom_phrase.txt"
                    local file = io.open(ppath,"a")
                    file:write("\n" .. history_str .. "\t" .. inpu)
                    file:close()

                    local tip = string.format("已保存[%s %s]", history_str, inpu)
                    yield(Candidate("pin", seg.start, seg._end, inpu , tip))

                    -- todo 获取deployer路径进行隐式自动部署
                    -- local script = "WeaselDeployer.exe /deploy"
                    -- os.execute(script)
                end
            elseif ( string.sub(input, -1)  == "/") then
                local context = env.engine.context
                local history_str = context.commit_history:latest_text()
                local tip = string.format("/保存[%s %s]", history_str, inpu)
                yield(Candidate("pin", seg.start, seg._end, inpu , tip))
            end
        end
    end
end

return M
