"""将 emoji_full.json 转换为 emoji.txt 格式（OpenCC emoji 词典）"""
import json
from collections import defaultdict

with open("emoji_full.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# tag/name -> set of emojis
tag_emojis = defaultdict(set)

for category in data:
    for sub in category.get("subcategories", []):
        for entry in sub.get("emojis", []):
            emoji_char = entry["emoji"]
            tags = entry.get("tags", [])

            for t in tags:
                t = t.strip()
                if t:
                    tag_emojis[t].add(emoji_char)

# 排序输出
lines = []
for tag, emojis in sorted(tag_emojis.items()):
    candidates = " ".join(sorted(emojis))
    lines.append(f"{tag}\t{tag} {candidates}")

with open("emoji.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print(f"转换完成: {len(tag_emojis)} 个触发词, 共 {len(lines)} 行")
print(f"输出: emoji.txt")
