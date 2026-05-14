"""Generate phonetic-confusable trial lists.

Given a keyword and a vocabulary, produce hard negatives whose CMU dict /
G2P transcriptions share a small edit distance with the target. Used by
`eval_kpis.py` and during training (hard-negative mining).
"""

from __future__ import annotations

from .._vendor_stub import edit_distance  # noqa: F401 (kept for reference)

# A tiny, self-contained Levenshtein so we don't depend on a vendor stub.

def _lev(a: str, b: str) -> int:
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


def find_confusables(target: str, vocab: list[str], k: int = 10) -> list[str]:
    """Return the `k` vocabulary entries with smallest edit distance to `target` (excluding target)."""
    scored = sorted(((w, _lev(target.lower(), w.lower())) for w in vocab if w.lower() != target.lower()),
                    key=lambda x: x[1])
    return [w for w, _ in scored[:k]]
