"""Tiny G2P shim.

Real implementation will plug in `g2p_en` for English and language-specific
G2Ps for HI / TA / TE / MR. Here we expose a stable interface plus a
deterministic fallback that maps characters to a small phoneme inventory --
enough to make the rest of the pipeline (and unit tests) runnable without
a heavy dependency.
"""

from __future__ import annotations

# Reserve 0 for padding; the rest are 79 "phonemes" in our toy inventory.
PAD_ID = 0
VOCAB_SIZE = 80

_LETTER_TO_ID = {c: (i % (VOCAB_SIZE - 1)) + 1 for i, c in enumerate("abcdefghijklmnopqrstuvwxyz")}


def text_to_phoneme_ids(text: str) -> list[int]:
    """Map a keyword string to a list of phoneme ids.

    Deterministic, language-agnostic fallback. Replaces with a real G2P
    in the Phase-2 expansion. Empty input returns a single PAD token so
    downstream code never sees an empty sequence.
    """
    text = (text or "").lower().strip()
    if not text:
        return [PAD_ID]
    ids = [_LETTER_TO_ID.get(ch, PAD_ID) for ch in text if ch.isalpha() or ch == " "]
    return ids or [PAD_ID]


def pad_phoneme_batch(seqs: list[list[int]]) -> list[list[int]]:
    """Right-pad a list of phoneme id sequences to a common length."""
    length = max((len(s) for s in seqs), default=1)
    return [s + [PAD_ID] * (length - len(s)) for s in seqs]
