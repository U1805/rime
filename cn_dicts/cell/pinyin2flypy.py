tranlate1 = {
    "sh": "u",
    "ch": "i",
    "zh": "v"
}

tranlate2 = {
    "iang": "l",
    "uang": "l",
    "iong": "s",
    "ong": "s",
    "ing": "k",
    "uai": "k",
    "uan": "r",
    "eng": "g",
    "ang": "h",
    "iao": "n",
    "ian": "m",
    "iu": "q",
    "ei": "w",
    "ue": "t",
    "ve": "t",
    "un": "y",
    "uo": "o",
    "ie": "p",
    "ai": "d",
    "en": "f",
    "an": "j",
    "ou": "z",
    "ia": "x",
    "ua": "x",
    "ao": "c",
    "ui": "v",
    "in": "b",
}

# local dir files

dict_old        = "moegirl.dict.yaml"
dict_new        = "moegirl.flypy.dict.yaml"

with open(dict_old, 'r', encoding='utf-8') as fp_dict_old:    
    for line in fp_dict_old:
        result = ""
        
        if '\t' not in line or line.startswith("#"):
            result = line
        
        else:
            if len(line.split("\t")) == 3:
                word, pinyin, weight = line.split('\t')
            else:
                line = line.replace("\n", "")
                word, pinyin = line.split('\t')
                weight = None
            
            pinyin = pinyin.split(" ")
            pinyin_xh = []
            for item in pinyin:
                # 单字母韵母，零声母 + 韵母所在键，如： 啊＝aa 哦=oo 额=ee
                if len(item) == 1:
                    item = item+item
                # 双字母韵母，零声母 + 韵母末字母，如： 爱＝ai 恩=en 欧=ou
                if len(item) == 2:
                    pinyin_xh.append(item)
                    continue
                
                for key, value in tranlate2.items():
                    if key in item:
                        item = item.replace(key, value.upper())
                        break
                for key, value in tranlate1.items():
                    if key in item:
                        item = item.replace(key, value)
                        break
                item = item.lower()
                
                # 三字母韵母，零声母 + 韵母所在键，如： 昂＝ah 
                if len(item) == 1:
                    for key, value in tranlate2.items():
                        if item == value:
                            item = key[0] + item
                            break
                pinyin_xh.append(item)
            
            result = f"{ word }\t{ ' '.join(pinyin_xh) }" + (f"\t{ weight }" if weight else "\n")

        with open(dict_new, "a", encoding="utf-8") as file_dict_new:
            file_dict_new.write(result)

