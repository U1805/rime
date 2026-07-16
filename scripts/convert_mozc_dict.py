#!/usr/bin/env python
"""
Convert Mozc OSS dictionary to Rime japanese.mozc.dict.yaml format.

Mozc text format:
    key[TAB]lid[TAB]rid[TAB]cost[TAB]value

Rime output format:
    value[TAB]romaji[TAB]weight

Cost semantics:
    cost = -ln(P) * 500
    P    = e^(-cost/500)

Weight mapping (clamped at cost=7000, i.e. -ln(P)=14):
    weight = round(e^(14 - min(cost, 7000) / 500))

Input:
    src/data/dictionary_oss/dictionary0*.txt  -- main dictionary
    src/data/dictionary_oss/suffix.txt         -- suffix entries
    src/data/dictionary_oss/aux_dictionary.tsv -- auxiliary entries
"""

import math
import sys
import os
from collections import defaultdict

import pykakasi


# ── Configuration ──────────────────────────────────────────────
MOZC_DATA_DIR = "/tmp/mozc-sparse/src/data"
OUTPUT_YAML   = "/tmp/japanese.mozc.dict.yaml"

COST_CLAMP = 7000          # cost >= 7000 → clamp to 7000 (-ln(P) >= 14)
K_EXPONENT = 14            # weight = e^(14 - cost/500)
RIME_VERSION = "v0.3-20260716"


# ── Romaji converter ───────────────────────────────────────────
kks = pykakasi.kakasi()

def hira_to_romaji(text: str) -> str:
    """Convert hiragana/katakana to Hepburn romaji."""
    result = kks.convert(text)
    return ''.join(item['hepburn'] for item in result)


# ── Load main dictionary files ─────────────────────────────────
def load_dictionary_txt(filepath: str, entries: dict):
    """
    Parse dictionary0x.txt.
    Format: key\tlid\trid\tcost\tvalue
    Dedup: keep lowest cost for same (value, key).
    """
    count = 0
    with open(filepath, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('\t')
            if len(parts) < 5:
                continue
            key   = parts[0]   # hiragana reading
            # lid = parts[1]
            # rid = parts[2]
            cost  = int(parts[3])
            value = parts[4]   # surface form

            k = (value, key)
            if k not in entries or cost < entries[k]:
                entries[k] = cost
            count += 1
    return count


def load_suffix_txt(filepath: str, entries: dict):
    """Parse suffix.txt (same format as dictionary0x.txt)."""
    return load_dictionary_txt(filepath, entries)


def load_aux_dictionary(filepath: str, entries: dict):
    """
    Parse aux_dictionary.tsv.
    Format: key\tvalue\tbase_key\tbase_value\tcost_offset
    The new word's cost = base_word.cost + cost_offset.
    Other fields (lid, rid) are copied from base_word but we don't need them.
    """
    added = 0
    skipped_no_base = 0
    with open(filepath, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('\t')
            if len(parts) < 5:
                continue
            key         = parts[0]
            value       = parts[1]
            base_key    = parts[2]
            base_value  = parts[3]
            cost_offset = int(parts[4])

            base_cost = entries.get((base_value, base_key))
            if base_cost is None:
                skipped_no_base += 1
                continue

            new_cost = base_cost + cost_offset
            k = (value, key)
            if k not in entries or new_cost < entries[k]:
                entries[k] = new_cost
            added += 1
    if skipped_no_base:
        print(f"  [aux] skipped {skipped_no_base} entries (base not found in main dict)",
              file=sys.stderr)
    return added


# ── Weight calculation ─────────────────────────────────────────
def cost_to_weight(cost: int) -> int:
    clamped = min(cost, COST_CLAMP)
    w = math.exp(K_EXPONENT - clamped / 500.0)
    return max(1, round(w))


# ── Main ───────────────────────────────────────────────────────
def main():
    entries: dict[tuple[str, str], int] = {}  # (value, key) → cost

    # 1. Load main dictionaries
    dict_dir = os.path.join(MOZC_DATA_DIR, "dictionary_oss")
    total_txt = 0
    for i in range(10):
        fpath = os.path.join(dict_dir, f"dictionary{i:02d}.txt")
        n = load_dictionary_txt(fpath, entries)
        print(f"  dictionary{i:02d}.txt: {n} lines", file=sys.stderr)
        total_txt += n

    # 2. Load suffix
    suffix_path = os.path.join(dict_dir, "suffix.txt")
    n_suf = load_suffix_txt(suffix_path, entries)
    print(f"  suffix.txt: {n_suf} lines", file=sys.stderr)
    total_txt += n_suf

    print(f"  Total raw lines: {total_txt}", file=sys.stderr)
    print(f"  Unique (value,key) pairs: {len(entries)}", file=sys.stderr)

    # 3. Load aux dictionary
    aux_path = os.path.join(dict_dir, "aux_dictionary.tsv")
    n_aux = load_aux_dictionary(aux_path, entries)
    print(f"  aux_dictionary.tsv: {n_aux} entries added", file=sys.stderr)
    print(f"  Final unique pairs: {len(entries)}", file=sys.stderr)

    # 4. Convert to romaji + weight, build output list
    #    Second-stage dedup: different keys may romanize identically.
    #    Keep the entry with the lowest cost (= highest weight).
    output_map: dict[tuple[str, str], int] = {}  # (value, romaji) → weight
    romaji_cache: dict[str, str] = {}

    for (value, key), cost in entries.items():
        if key not in romaji_cache:
            romaji_cache[key] = hira_to_romaji(key)
        romaji = romaji_cache[key]
        weight = cost_to_weight(cost)
        k = (value, romaji)
        if k not in output_map or weight > output_map[k]:
            output_map[k] = weight

    output: list[tuple[str, str, int]] = [
        (v, r, w) for (v, r), w in output_map.items()
    ]

    # 5. Sort by weight descending
    output.sort(key=lambda x: x[2], reverse=True)

    # 6. Write output
    with open(OUTPUT_YAML, 'w', encoding='utf-8', newline='\n') as f:
        # YAML header
        f.write(f"""# Rime dictionary
# converted from dictionaries of mozc (https://github.com/google/mozc)
#
# encoding: utf-8
# vim: set noet:

---
name: japanese.mozc
version: '{RIME_VERSION}'
sort: by_weight
...

""")
        for value, romaji, weight in output:
            f.write(f"{value}\t{romaji}\t{weight}\n")

    # 7. Summary
    print(f"\nDone: {len(output)} entries written to {OUTPUT_YAML}", file=sys.stderr)
    if output:
        print(f"Weight range: {output[-1][2]} ~ {output[0][2]}", file=sys.stderr)


if __name__ == '__main__':
    main()
