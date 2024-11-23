local labels = {
    ["ocm"] = {"[Windows Terminal]", "[命令提示符]"}, 
    ["odn"] = {"[文件管理器]"},
    ["oex"] = {"[Excel]"},
    ["oht"] = {"[画图]"},
    ["ojs"] = {"[计算器]"},
    ["owd"] = {"[Word]"},
}

local function translator(input, seg)
  local lbls = labels[input]
  if lbls == nil then return end
  for i, lbl in pairs(lbls) do
    yield(Candidate("shortcut", seg.start, seg._end, lbl, ""))
  end
end

return translator
