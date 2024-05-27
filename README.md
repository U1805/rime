# 小鹤双拼+鹤形辅助+英日输入

基于 [墨奇音形](https://github.com/gaboolic/rime-shuangpin-fuzhuma) 修改

## Feature

- 打词时插入辅助码 eg. 寄宿`jisub` 极速`jimsu`; `Tab` 引导辅助码
- `ab` 笔画输入（反查）eg. 木`abhspn`
- `az` 部件组字输入（反查）eg. 晶`azririri`
- `ae` emoji输入 (支持双拼、英文) eg. 🐧`aedswu`/`aeanimal`
- `aw` 开头[英文输入](https://github.com/tumuyan/rime-melt) eg. myGo`awmygo`
- `aj` 开头[日文输入](https://github.com/gkovacs/rime-japanese) eg. 春日影`ajharuhikage` 
- `ap` 开头临时[全拼](https://github.com/iDvel/rime-ice) eg. 炸梦我去`apzhamengwoqu`
- N开头农历输入 eg. 二〇二四年四月初八`N20240515`
- R开头大写数字 eg. 拾壹萬肆仟伍佰壹拾肆`R114514`
- U开头Unicode输入 eg. ⿻`U2ffb`
- V开头计算器模式 eg. 1+1=2`V1+1`
- o开头，快速输入各种符号偏旁部件 [小鹤 · 符号](https://flypy.cc/#/fh)
- `ctrl+1` emoji 开关；`ctrl+2` 简繁开关；`ctrl+3` 中英词典开关
- 三字词，用e引导简码，简码取声母，eg. 阿波罗`eabl`, 差不多`eibd`, 巴不得`ebbd`。
- 多字词，用e引导简码，简码取前3+末字声母，eg. 当仁不让`edrbr`, 兵败如山倒`ebbrd`, 天有不测风云`etyby`
- 日期时间相关输入：`date time week` `datetime` `timestamp` `anl`
- 符号输入 `/`开头，`/help` 查看帮助，另支持[常用 Latex 符号](https://github.com/wklchris/Rime-latex-symbols) 
- 自定义词 `//` 结尾，加入到 `custom_phrase.txt` 中，eg. 输入 `琴音` 然后输入 `kotone//` 下次部署就有词了
- 好看的皮肤 [win11_preset](https://github.com/LufsX/rime)

## Usage

- 方案选单：`Control+Shift+space` （原始的 Control+grave 与 vscode 打开终端冲突）
- 翻页: 
  - `- =`
  - `[ ]`
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
- pinyin_simp: ap 输入全拼
- chaizi: 部首组字
- radical_flypy: 部首组字