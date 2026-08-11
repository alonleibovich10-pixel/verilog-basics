# verilog-basics

Digital design fundamentals in Verilog-2001 — combinational and sequential building
blocks, each written from scratch and verified with a self-checking testbench.

Simulated with Icarus Verilog (`iverilog` + `vvp`), waveforms inspected in a VCD viewer.

## Day 1 — Gates & Basic Modules

| Module | File | Description |
|---|---|---|
| `and_gate` | `and_gate.v` | Basic gate-level module, first simulation flow |
| `mux2_1bit` | `mux2_1bit.v` | 1-bit 2-to-1 multiplexer |

## Day 2 — Combinational Logic & Module Hierarchy

| Module | File | Description |
|---|---|---|
| `mux2` / `mux4` | `mux4.v` | 8-bit 4-to-1 multiplexer built hierarchically from three 2-to-1 mux instances |
| `decoder3to8` | `decoder3to8.v` | 3-to-8 one-hot decoder with active-high enable; `always @(*)` with a fully covered `case` (no inferred latches) |
| `full_adder` / `ripple_carry_adder` | `ripple_carry_adder.v` | Parameterized N-bit ripple-carry adder built with a `generate` loop over full-adder instances |

### Verification

Every testbench computes the expected result independently of the DUT and reports
PASS/FAIL with an error count.

| Testbench | Strategy | Vectors | Result |
|---|---|---|---|
| `tb_mux4.v` | directed + constrained random | 104 | PASS |
| `tb_decoder3to8.v` | exhaustive (full input space) | 16 | PASS |
| `tb_ripple_carry_adder.v` | directed corner cases + random vs. reference model | 509 | PASS |

### Running

```bash
make all        # compile + simulate everything
make adder      # a single module
```

### Design notes

- Ripple-carry delay grows linearly with N — the carry chain is the critical path.
  Faster adders (carry-lookahead, carry-select) trade area for delay using the
  generate/propagate formulation `c[i+1] = g[i] | (p[i] & c[i])`.
- The adder is reused as the arithmetic core of the ALU and of the single-cycle CPU project.
- Ports are connected by name, never by position.

## Tools

`Icarus Verilog` · `GTKWave / VCD viewer` · `make` · `Git`

![Ripple-carry adder waveform — 8-bit addition with carry propagation](rca_waveform.png)