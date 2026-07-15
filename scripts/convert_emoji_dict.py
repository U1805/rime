"""将 emoji_full.json 转换为 Rime emojis.dict.yaml 格式"""
import json
from pypinyin import lazy_pinyin

with open("emoji_full.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# emoji -> set of (tag, pinyin) tuples to deduplicate
entries = set()

for category in data:
    for sub in category.get("subcategories", []):
        for entry in sub.get("emojis", []):
            emoji_char = entry["emoji"]
            tags = entry.get("tags", [])

            for t in tags:
                t = t.strip()
                if not t:
                    continue
                py = " ".join(lazy_pinyin(t))
                entries.add((emoji_char, py))

# 排序：先按 emoji 字符排序
sorted_entries = sorted(entries, key=lambda x: x[0])

# 生成 YAML 头部
header = """# 使用opencc/emoji.txt数据转换
# 转换脚本为https://github.com/gaboolic/rime-shuangpin-fuzhuma/program/emoji/deal_emoji_dict.py
# 

---
name: emojis
version: "2026-07-15"
sort: by_weight
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
...
"""

with open("emojis.dict.yaml", "w", encoding="utf-8") as f:
    f.write(header)
    for emoji_char, py in sorted_entries:
        f.write(f"{emoji_char}\t{py}\n")

print(f"转换完成: {len(sorted_entries)} 条记录")
print(f"输出: emojis.dict.yaml")
