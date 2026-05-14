"""Enforce the Samsung KPI: model must have fewer than 3 M parameters.

If this test fails, our entry is disqualified by the rules -- so we keep
it as a hard gate in CI.
"""

from __future__ import annotations

from speech_disentanglement.models import PVT, count_params

PARAM_BUDGET = 3_000_000


def test_pvt_fits_in_param_budget() -> None:
    model = PVT()
    n = count_params(model)
    assert n < PARAM_BUDGET, (
        f"PVT has {n:,} params, exceeds Samsung budget of {PARAM_BUDGET:,}. "
        "Reduce encoder hidden dim or depth in models/encoder.py."
    )


def test_pvt_uses_a_reasonable_fraction_of_budget() -> None:
    """Sanity check: we shouldn't be using <30% of the budget either --
    that usually means we're under-using capacity. Adjustable as we tune."""
    model = PVT()
    n = count_params(model)
    assert n > 0.3 * PARAM_BUDGET, (
        f"PVT has only {n:,} params (<30% of the {PARAM_BUDGET:,} budget). "
        "Consider increasing model capacity."
    )
