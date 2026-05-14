"""Tiny placeholder for vendored helpers.

Kept so older imports don't break; the canonical Levenshtein lives inline
in `evaluation/phonetic_confusables.py`.
"""

from __future__ import annotations


def edit_distance(a: str, b: str) -> int:
    if len(a) < len(b):
        a, b = b, a
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        curr = [i]
        for j, cb in enumerate(b, 1):
            curr.append(min(curr[-1] + 1, prev[j] + 1, prev[j - 1] + (ca != cb)))
        prev = curr
    return prev[-1]
