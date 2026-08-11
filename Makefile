# verilog-basics  -  simulation targets
#
#   make            כל המודולים
#   make dff        מודול בודד
#   make wave_dff   פתיחת הגלים (VaporView: פשוט לחץ על ה-.vcd ב-Explorer)
#   make clean      ניקוי קבצי הרצה

IV   = iverilog -g2005
VVP  = vvp

# ---------------- Day 2 : combinational ----------------
mux4:
	$(IV) -o sim_mux4.out mux4.v tb_mux4.v
	$(VVP) sim_mux4.out

decoder:
	$(IV) -o sim_decoder.out decoder3to8.v tb_decoder3to8.v
	$(VVP) sim_decoder.out

adder:
	$(IV) -o sim_adder.out ripple_carry_adder.v tb_ripple_carry_adder.v
	$(VVP) sim_adder.out

# ---------------- Day 3 : sequential ----------------
dff:
	$(IV) -o sim_dff.out dff.v tb_dff.v
	$(VVP) sim_dff.out

shift:
	$(IV) -o sim_shift.out shift_reg8.v tb_shift_reg8.v
	$(VVP) sim_shift.out

counter:
	$(IV) -o sim_counter.out counter_mod10.v tb_counter_mod10.v
	$(VVP) sim_counter.out

# ---------------- aggregates ----------------
day2: mux4 decoder adder
day3: dff shift counter
all:  day2 day3

clean:
	rm -f *.out *.vcd

.PHONY: all day2 day3 mux4 decoder adder dff shift counter clean
