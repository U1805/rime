# 小鹤双拼+鹤形辅助+英日输入

基于 [墨奇音形](https://github.com/gaboolic/rime-shuangpin-fuzhuma)

## Feature

- 打词时插入辅助码：寄宿jisub 极速jimsu
- `ab` 笔画输入（反查）
- `az` 部件组字输入（反查）
- `ae` emoji输入
- `aw` 开头[英文输入](https://github.com/tumuyan/rime-melt) 
- `aj` 开头[日文输入](https://github.com/gkovacs/rime-japanese) 
- N开头快捷日期输入 eg. N20240515
- R开头 大写数字 eg. R123
- U开头unicode输入 eg. u2ffb
- V开头计算器模式
- o开头，快速输入各种符号偏旁部件[小鹤 · 部件]
- `ctrl+1` emoji 开关；`ctrl+2` 简繁开关
- 三字词，用e引导简码，简码取声母，eg. 阿波罗eabl, 差不多eibd, 巴不得ebbd。
- 多字词，用e引导简码，简码取前3+末字声母，eg. 当仁不让edrbr, 兵败如山倒ebbrd, 天有不测风云etyby
- 日期时间相关输入：`date time week` `datetime` `timestamp`
- 符号输入`/`开头，支持[常用 Latex 符号](https://github.com/wklchris/Rime-latex-symbols) 
- 好看的皮肤 https://github.com/LufsX/rime

## Usage

- 方案选单：`Control+Shift+space` （原始的 Control+grave 与 vscode 打开终端冲突）
- 翻页: 
  - `-` / `=`
  - `Tab` / `Shift+Tab`
  - `Control` + `hjkl` (vim 风格)
- 自定义词库在根目录新建 `custom_phrase.txt` 文件

```
# Rime table
# coding: utf-8
#
# 请将该文件以UTF-8编码保存为
# Rime用户文件夹/custom_phrase.txt
#
# 码表各字段以制表符（Tab）分隔
# 顺序为：文字、编码、权重（决定重码的次序、可选）
#
# 虽然文本码表编辑较为方便，但不适合导入大量条目

榆井希实	yujkxiui
```

## File Description

- flypy: 小鹤双拼+形码辅助
- emoji: ae 输入 emoji
- japanese: aj 输入日语
- melt_eng: aw 输入英语
- chaizi: 部首组字
- radical_flypy: 部首组字