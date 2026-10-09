"""One shared RPM/load grid and default lambda targets for every tool.

Before this module, the optimiser binned 500 rpm x 10 kPa, telemetry_stats binned
900 rpm x 10 kPa, and the Freedom uses 500 rpm x 50 mmHg. Corrections landed in
cells that did not match the ECU's own cells.

Evidence: the 500 rpm / 50 mmHg pitch is `documented` (public FCST description and
Kunugi Runner FCSS manual, coefficient 13 "map axis pitch"). It is configurable on the
ECU (25 or 50 mmHg), so the pitch here must be confirmed against the unit being tuned.
"""
from __future__ import annotations

RPM_STEP = 500
MMHG_PER_KPA = 7.50062
PRESSURE_STEP_MMHG = 50
PRESSURE_STEP_KPA = PRESSURE_STEP_MMHG / MMHG_PER_KPA  # ~6.67 kPa

# Default lambda targets by load region. `inferred`: common NA 4A-G practice, not read
# from the ECU. A per-sample `lambda_target` (from the ECU target table or the engine
# profile) always overrides these. Replace with the car's own target table once decoded.
IDLE_CRUISE_MAX_KPA = 70
DEFAULT_TARGET_LIGHT_LOAD = 1.00
DEFAULT_TARGET_HIGH_LOAD = 0.88


def cell(rpm: float, load_kpa: float) -> tuple[int, int]:
    """Return the Freedom cell as (rpm bucket start, pressure bucket start in mmHg)."""
    rpm_start = int(rpm // RPM_STEP) * RPM_STEP
    mmhg = load_kpa * MMHG_PER_KPA
    pressure_start = int(mmhg // PRESSURE_STEP_MMHG) * PRESSURE_STEP_MMHG
    return rpm_start, pressure_start


def cell_label(rpm: float, load_kpa: float) -> str:
    rpm_start, pressure_start = cell(rpm, load_kpa)
    return f"{rpm_start}rpm:{pressure_start}mmHg"


def default_target(load_kpa: float) -> float:
    return DEFAULT_TARGET_LIGHT_LOAD if load_kpa < IDLE_CRUISE_MAX_KPA else DEFAULT_TARGET_HIGH_LOAD


def region(load_kpa: float, rpm: float) -> str:
    if rpm < 1200 and load_kpa < 50:
        return "idle"
    if load_kpa < IDLE_CRUISE_MAX_KPA:
        return "cruise"
    return "high_load"
