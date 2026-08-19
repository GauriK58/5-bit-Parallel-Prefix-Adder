# 5-bit Parallel Prefix Adder (Brent–Kung)

**Low-Power VLSI Design** : NGSPICE · MAGIC · AMD Xilinx Vivado

A 5-bit Carry Look-Ahead Adder built on the Brent–Kung parallel-prefix architecture, designed and characterized end-to-end: transistor-level gate design, TSPC flip-flop synchronization, MAGIC layout, pre-/post-layout SPICE simulation, static timing analysis, and final FPGA deployment in Verilog.

---

## Table of Contents

- [Overview](#overview)
- [Highlights](#highlights)
- [Why a Parallel Prefix Adder?](#why-a-parallel-prefix-adder)
- [Flip-Flop Design](#flip-flop-design)
  - [Why TSPC](#why-tspc)
  - [Timing Constraints](#timing-constraints)
  - [Sizing and Glitch Reduction](#sizing-and-glitch-reduction)
- [Gate Implementation](#gate-implementation)
  - [XOR (GDI-based)](#xor-gdi-based)
  - [AND / OR (Static CMOS)](#and--or-static-cmos)
- [Delay Characterization and Optimal Clock Speed](#delay-characterization-and-optimal-clock-speed)
- [Post-Layout Results](#post-layout-results)
- [FPGA Implementation](#fpga-implementation)
- [Tools Used](#tools-used)

---

## Overview

High-speed digital arithmetic is bottlenecked by carry-propagation delay. This project implements a **5-bit Brent–Kung parallel-prefix adder**, which restructures carry computation as an associative prefix-tree operation, cutting carry computation time from `O(n)` (ripple-carry) down to `O(log n)`. Flip-flops are placed at both the input and output boundaries of the combinational adder logic to eliminate race conditions and guarantee deterministic timing, and the full design is carried from transistor-level schematics through MAGIC layout, SPICE simulation, and static timing analysis to a working FPGA implementation.

## Highlights

- Designed a Brent–Kung adder computing all carries in `O(log n)` vs. `O(n)` for a ripple-carry adder, using an associative prefix operator on generate–propagate pairs.
- Performed post-layout **Static Timing Analysis (STA)** to select a **0.731 GHz** operating clock frequency.
- Built an **8T GDI-based XOR gate** in place of 12T static CMOS, reducing transistor count by ~33% while preserving rail-to-rail output.
- Achieved **50.9 ps setup** and **28.1 ps hold time** post-layout with zero timing violations on the TSPC flip-flops.
- Validated adder functionality pre- and post-layout in NGSpice, then synthesized and deployed the design on an FPGA using Verilog.

---

## Why a Parallel Prefix Adder?

A standard ripple-carry adder computes each carry only after the previous one resolves, making carry computation an inherently sequential, `O(n)` dependency chain. The Brent–Kung approach fixes this by defining an **associative operator** on bitwise generate–propagate pairs, which means groups of bits can be combined in any tree-shaped order rather than one at a time.

This lets carries be computed via a balanced prefix tree: bits are combined pairwise, then in groups of 4, 8, and so on, doubling the span at each level. Covering all `n` bits this way takes only `⌈log₂ n⌉` levels of constant-time AND/OR work, so the total carry computation time is `O(log n)` instead of `O(n)`. This regularity, low fanout, and controlled area make the Brent–Kung topology well suited to VLSI implementation and high-speed digital systems.

---

## Flip-Flop Design

### Why TSPC

Flip-flops are placed at both the input (`A_i`, `B_i`, `C_i`) and output (`S_0`–`S_4`, `C_5`) boundaries of the adder, sandwiching the combinational logic between two synchronous stages. This mitigates metastability and input skew, keeps outputs stable for the full clock period, and eliminates race conditions.

A **True Single-Phase Clock (TSPC)** D-flip-flop is used for this synchronization. Its single-clock operation minimizes control complexity, its compact structure reduces area and power, and it supports the rapid switching needed for high clock frequencies. 

It's positive-edge-triggered: `D` is sampled onto an internal node while the clock is low (M1–M3), then propagated through to the output on the rising edge (M4–M9), with the sampling path fully disabled during the high phase so later changes on `D` don't leak through.

### Timing Constraints

- **Setup time (`t_su`):** minimum time `D` must be stable before the clock edge.
- **Hold time (`t_h`):** minimum time `D` must remain stable after the clock edge.
- **Clock-to-Q delay (`t_PCQ`):** time for `Q` to reflect a change in `D` after the clock edge.

### Sizing and Glitch Reduction

The initial transistor sizing referenced a minimum-sized inverter, with PMOS widths scaled to 2× the NMOS widths to equalize rise/fall delays:

| Stage | PMOS | NMOS |
|---|---|---|
| 1 | 40λ | 10λ |
| 2 and 3 | 20λ | 20λ |

This initial sizing caused a glitch at the output: with `D` low and `Q = 1`, `Y` and `Q̄` briefly discharge simultaneously as the clock transitions high, causing `Q̄` to dip before settling. This was reduced by making the stage-3 pull-down transistors weaker than stage 2, so `Y` discharges faster than `Q̄`:

| Stage | PMOS | NMOS |
|---|---|---|
| 1 | 40λ | 10λ |
| 2 | 20λ | 20λ |
| 3 | 20λ | 10λ |

With this final ratio, the dip in `Q̄` is significantly reduced, confirmed by SPICE waveforms.

| Metric | Pre-Layout | Post-Layout |
|---|---|---|
| `t_su` | 53 ps | 50.9 ps |
| `t_h` | 37 ps | 28.1 ps |
| `t_PCQ` | 147 ps | 100 ps |

---

## Gate Implementation

The adder's combinational logic is built from AND, OR, and XOR gates.

### XOR (GDI-based)

A **Gate Diffusion Input (GDI)**-based XOR structure is used, followed by two cascaded inverters to restore full logic levels.

**Advantages**
- Realizes XOR with only 4 transistors vs. 12 for static CMOS, which saves significant area.
- Lower dynamic power consumption and improved switching speed.

**Disadvantages**
- GDI gates drive a signal onto a source/drain terminal rather than an insulated gate, so the driven node isn't fully isolated. This introduces finite input impedance, voltage degradation, and reduced noise margins.
- Since GDI doesn't produce rail-to-rail output, a buffer is added after the XOR logic, bringing the total to **8 transistors**, not 6. However, this is still better than the 12-transistor static CMOS implementation.

### AND / OR (Static CMOS)

AND and OR are implemented with standard static CMOS logic.

**Advantages**
- Guaranteed rail-to-rail voltage outputs.
- Low static power — current flows only during switching.
- High noise tolerance relative to other logic styles.

**Disadvantages**
- Larger transistor count and area than alternative styles (e.g. GDI).
- Increased layout complexity that can affect density in large-scale designs.

All gates were sized relative to a minimum-size inverter (PMOS at 2× NMOS width) to equalize rise/fall delays. For simplicity and uniformity across this design, a fixed NMOS width of `W_n = 10λ` was used at every stage, rather than progressively scaling transistor sizes at deeper logic levels.

---

## Delay Characterization and Optimal Clock Speed

For correct operation, the TSPC flip-flop's timing constraints must hold:

```
T_clk ≥ t_su + t_PCQ + t_pd(max)
t_h   ≤ t_PCQ + t_pd(min)
```

The adder's worst-case delay path runs from input `A0` to the carry-out `C5`; the minimum-delay path runs from `A0` to sum bit `S0`.

**Pre-layout propagation delay**

| Parameter | Value |
|---|---|
| `t_pd(max)` | 1003 ps |
| `t_pd(min)` | 363 ps |

The hold-time inequality holds with no violation. Solving for the maximum clock speed:

```
T_clk ≥ 53p + 147p + 1003p  ⟹  T_clk(min) = 1.203 ns
```

Adder functionality was verified against these timing constraints via pre- and post-layout NGSpice simulation.

## Post-Layout Results

| Parameter | Pre-Layout | Post-Layout |
|---|---|---|
| Minimum propagation delay | 363 ps | 450 ps |
| Maximum propagation delay | 1.003 ns | 1.450 ns |
| Flip-flop setup time | 53 ps | 51 ps |
| Flip-flop hold time | 37 ps | 28 ps |
| Clock-to-Q delay | 147 ps | 100 ps |
| Minimum clock period (`T_clk-min`) | 1.203 ns | 1.601 ns |
| **Max frequency** | 0.831 GHz | **0.731 GHz** |

Full-circuit layout was completed in MAGIC, and the design was re-simulated post-layout in NGSpice to confirm functionality against the extracted parasitics.

## FPGA Implementation

The adder was implemented in Verilog and deployed successfully on an FPGA, validating the design beyond simulation.

---

## Tools Used

| Tool | Purpose |
|---|---|
| **NGSPICE** | Transistor-level simulation, pre-/post-layout timing verification |
| **MAGIC** | Full-custom VLSI layout of gates, flip-flops, and the adder |
| **AMD Xilinx Vivado** | Verilog synthesis and FPGA deployment |
