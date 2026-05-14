"""Detection-side metrics: TA, FA / hr, EER, miss-rate-at-1-FA."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass
class DetectionMetrics:
    true_acceptance: float          # fraction of positives correctly accepted
    false_acceptance_per_hour: float
    equal_error_rate: float
    threshold_at_target: float


def _sweep(scores: np.ndarray, labels: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Return (thresholds, far, frr) sorted ascending by threshold."""
    thresholds = np.unique(scores)
    far = np.empty_like(thresholds, dtype=float)
    frr = np.empty_like(thresholds, dtype=float)
    pos = labels == 1
    neg = ~pos
    n_pos = max(int(pos.sum()), 1)
    n_neg = max(int(neg.sum()), 1)
    for i, t in enumerate(thresholds):
        accept = scores >= t
        far[i] = float(np.logical_and(accept, neg).sum()) / n_neg
        frr[i] = float(np.logical_and(~accept, pos).sum()) / n_pos
    return thresholds, far, frr


def equal_error_rate(scores: np.ndarray, labels: np.ndarray) -> tuple[float, float]:
    """Return (EER, threshold_at_EER)."""
    thresholds, far, frr = _sweep(scores, labels)
    diff = np.abs(far - frr)
    idx = int(np.argmin(diff))
    return float((far[idx] + frr[idx]) * 0.5), float(thresholds[idx])


def threshold_for_far_per_hour(
    scores: np.ndarray,
    labels: np.ndarray,
    test_duration_hours: float,
    target_far_per_hour: float = 1.0,
) -> tuple[float, float]:
    """Find the threshold that yields at most `target_far_per_hour` false accepts/hr.

    Returns (threshold, achieved_far_per_hour).
    """
    neg_mask = labels == 0
    neg_scores = scores[neg_mask]
    if neg_scores.size == 0 or test_duration_hours <= 0:
        return float("inf"), 0.0
    target_fa_count = max(int(target_far_per_hour * test_duration_hours), 0)
    sorted_neg = np.sort(neg_scores)[::-1]
    if target_fa_count == 0:
        # Force zero false accepts: threshold strictly above the worst negative.
        thr = float(sorted_neg[0]) + 1.0
    elif target_fa_count >= len(sorted_neg):
        thr = float(sorted_neg[-1] - 1e-6)
    else:
        # Midpoint between the k-th and (k+1)-th highest negative score yields
        # exactly `target_fa_count` negatives at-or-above the threshold.
        thr = float(0.5 * (sorted_neg[target_fa_count - 1] + sorted_neg[target_fa_count]))
    achieved = float((scores[neg_mask] >= thr).sum()) / max(test_duration_hours, 1e-9)
    return thr, achieved


def true_acceptance_at_threshold(scores: np.ndarray, labels: np.ndarray, threshold: float) -> float:
    pos = labels == 1
    return float((scores[pos] >= threshold).sum()) / max(int(pos.sum()), 1)


def evaluate(
    scores: np.ndarray,
    labels: np.ndarray,
    test_duration_hours: float,
    target_far_per_hour: float = 1.0,
) -> DetectionMetrics:
    threshold, far_per_hour = threshold_for_far_per_hour(
        scores, labels, test_duration_hours, target_far_per_hour
    )
    ta = true_acceptance_at_threshold(scores, labels, threshold)
    eer, _ = equal_error_rate(scores, labels)
    return DetectionMetrics(
        true_acceptance=ta,
        false_acceptance_per_hour=far_per_hour,
        equal_error_rate=eer,
        threshold_at_target=threshold,
    )
