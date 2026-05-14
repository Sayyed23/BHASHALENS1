"""Tests for the phonetic-confusable helper."""

from __future__ import annotations

from speech_disentanglement.evaluation.phonetic_confusables import find_confusables


def test_find_confusables_orders_by_edit_distance() -> None:
    vocab = ["marvin", "marlin", "marvel", "carbon", "elephant"]
    out = find_confusables("marvin", vocab, k=3)
    # marlin (1 edit) and marvel (2 edits) should rank above elephant / carbon.
    assert out[0] == "marlin"
    assert "elephant" not in out


def test_find_confusables_excludes_self() -> None:
    out = find_confusables("hello", ["hello", "hallo", "world"], k=5)
    assert "hello" not in out
