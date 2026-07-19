# Solar + Battery LP Optimization

A MATLAB-based linear programming optimization for solar generation and battery storage dispatch, demonstrating cost savings under time-of-use (TOU) tariffs with real Abu Dhabi load profiles.

## Overview

This project optimizes the hourly charge/discharge schedule of a battery system paired with solar generation to minimize grid electricity costs under a dynamic TOU tariff. It compares:
- **LP-optimized dispatch**: Solves a linear program to minimize daily cost
- **Rule-based dispatch**: Simple charge-on-excess, discharge-on-deficit logic

The optimization achieves **3.2% cost reduction** (approximately AED 0.50/day) compared to rule-based control under a modeled TOU tariff structure.

## Motivation

Time-of-use tariffs encourage load shifting — charging batteries during cheap hours (night) and discharging during peak-price hours (evening). Abu Dhabi's peak demand and pricing both peak in the evening, creating a clear economic incentive for optimized battery dispatch. This simulation quantifies the value of mathematical optimization over heuristic rules.

## Files

- `solar_battery_optimization.m` – Main optimization script with LP formulation
- `solarbattery.m` – Supporting analysis and visualization
- `01_Load_Profile.png` – Typical daily electricity load (1.2–5.5 kW)
- `02_Load_vs_Solar.png` – Load demand vs solar generation mismatch
- `03_Battery_SoC.png` – Optimized battery state-of-charge trajectory over 24 hours

## How to Run

1. Have MATLAB installed (R2020a or later recommended)
2. Download both `.m` files
3. Open MATLAB and navigate to the directory containing the scripts
4. Run: `solar_battery_optimization`
5. The script prints optimization results and displays three plots

## Key Results

- **Optimized daily cost (TOU tariff)**: ~AED 15.00 (example; varies with tariff)
- **Rule-based daily cost**: ~AED 15.50
- **Optimization advantage**: 3.2% savings
- **Battery capacity**: 10 kWh; max charge/discharge rate: 3 kW
- **Battery efficiency**: 90%

## Model Parameters

- **Load profile**: Simplified 24-hour profile (peak 5.5 kW at 4 PM)
- **Solar generation**: Real Abu Dhabi irradiance data (0 W/m² night, peak ~973 W/m² midday)
- **TOU tariff** (illustrative):
  - Off-peak (midnight–6 AM, 10 PM–midnight): AED 0.15/kWh
  - Mid-peak (7 AM–3 PM): AED 0.25/kWh
  - Peak (4 PM–9 PM): AED 0.45/kWh

## Notes

The TOU tariff used here is a plausible demonstration structure, not an actual current UAE utility rate. Real tariffs vary by provider and may include demand charges, minimum consumption, or other factors not modeled here.

## Contact

Questions? Reach out via GitHub or email: anlon9564@gmail.com
