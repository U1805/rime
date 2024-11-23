
--- 百度云拼音，Control+t 为云输入触发键
--- 使用方法：
--- 将 "lua_translator@baidu_translator" 和 "lua_processor@baidu_processor"
--- 分别加到输入方案的 engine/translators 和 engine/processors 中
local baidu = require("cloud/baidu")
baidu_processor = baidu.processor
return baidu_processor