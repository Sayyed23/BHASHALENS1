"""Tests for the detection metrics in `evaluation/metrics.py`."""

from __future__ import annotations

import numpy as np

from speech_disentanglement.evaluation.metrics import (
    equal_error_rate,
    evaluate,
    threshold_for_far_per_hour,
    true_acceptance_at_threshold,
)


def _toy_scores(seed: int = 0, n: int = 1000):
    rng = np.random.default_rng(seed)
    pos = rng.normal(loc=0.9, scale=0.05, size=n // 2)
    neg = rng.normal(loc=0.1, scale=0.05, size=n // 2)
    scores = np.concatenate([pos, neg])
    labels = np.concatenate([np.ones(n // 2), np.zeros(n // 2)]).astype(int)
    return scores, labels


def test_eer_is_low_for_well_separated_scores() -> None:
    scores, labels = _toy_scores()
    eer, _ = equal_error_rate(scores, labels)
    assert eer < 0.05


def test_threshold_for_far_per_hour_caps_false_accepts() -> None:
    scores, labels = _toy_scores(n=2000)
    thr, achieved = threshold_for_far_per_hour(scores, labels, test_duration_hours=2.0,
                                                target_far_per_hour=1.0)
    assert achieved <= 1.0 + 1e-6


def test_evaluate_returns_consistent_metrics() -> None:
    scores, labels = _toy_scores()
    m = evaluate(scores, labels, test_duration_hours=1.0)
    assert 0.0 <= m.true_acceptance <= 1.0
    assert m.false_acceptance_per_hour >= 0.0
    assert 0.0 <= m.equal_error_rate <= 0.5


def test_true_acceptance_at_threshold_zero_is_one() -> None:
    scores, labels = _toy_scores()
    ta = true_acceptance_at_threshold(scores, labels, threshold=-1e9)
    assert ta == 1.0
