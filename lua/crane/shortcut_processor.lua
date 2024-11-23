--[[
    shortcut_processor.lua
    这个文件包含了处理快捷键的逻辑，通过Lua脚本实现间接实现了部分直通车的功能。
    每个命令都是一个表，包含了执行该命令所需的所有参数。
]]

local function select_index(env, key)
  local ch = key.keycode
  local index = -1
  local select_keys = env.engine.schema.select_keys
  if select_keys ~= nil and select_keys ~= "" and not key.ctrl() and ch >= 0x20 and ch < 0x7f then
      local pos = string.find(select_keys, string.char(ch))
      if pos ~= nil then
          index = pos
      end
  elseif ch >= 0x30 and ch <= 0x39 then
      index = (ch - 0x30 + 9) % 10
  elseif ch >= 0xffb0 and ch < 0xffb9 then
      index = (ch - 0xffb0 + 9) % 10
  elseif ch == 0x20 then
      index = 0
  end
  return index
end

local common = {
  kRejected = 0,
  kAccepted = 1,
  kNoop = 2
}


local command = {
    ["ocm"] = {'start "" "wt.exe"', 'start "" "cmd.exe"'},
    ["odn"] = {'start "" "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"'},
    ["oex"] = {'start "" "excel.exe"'},
    ["oht"] = {'start "" "mspaint.exe"'},
    ["ojs"] = {'start "" "calc.exe"'},
    ["owd"] = {'start "" "winword.exe"'},
}

--[[

]]
local function restore_saved_options(key, env)
  local inp = env.engine.context.input
  if string.len(inp) <= 1 and env.switcher ~= nil then
    local swt = env.switcher
    local ctx = env.engine.context
    local conf = swt.user_config
  end
end

local function processor(key, env)
  restore_saved_options(key, env)
  local context = env.engine.context
  if key:release() or key:alt() then return common.kNoop end
  local index = select_index(env, key)
  if index < 0 then return common.kNoop end
  if command[context.input] ~= nil then
    local cmd = command[context.input][index+1]
    if cmd ~= nil then
      os.execute(cmd)
      context:clear()
      return common.kAccepted
    end
  end

  local comp = context.composition
  if comp.empty == nil then return common.kNoop end
  if comp:empty() then return common.kNoop end
  local seg = comp:back()
  if seg == nil or seg.menu == nil or seg:has_tag("raw") then return common.kNoop end
  local page_size = env.engine.schema.page_size
  if index >= page_size then return common.kNoop end
  local page_start = math.floor(seg.selected_index / page_size) * page_size
  local cand = seg:get_candidate_at(page_start + index)
  if cand == nil then return common.kNoop end
  if cand.type:sub(1,1) ~= "$" then return common.kNoop end
  local new_input = string.match(cand.type, "%$(%w+)")
  if new_input == nil or new_input == "" then return common.kNoop end
  context.input = new_input
  return common.kAccepted
end

local function init(env)
  if Switcher == nil then return end
  env.switcher = Switcher(env.engine)
end

return { init = init, func = processor }
