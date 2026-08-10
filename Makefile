# Day 2 - combinational logic + hierarchy
# שימוש:  make mux4   |   make decoder   |   make adder   |   make all
#         make wave_mux4  - פותח את הגלים ב-GTKWave

IV    = iverilog
VVP   = vvp
GTKW  = gtkwave

all: mux4 decoder adder

mux4:
	$(IV) -g2005 -o sim_mux4.out mux4.v tb_mux4.v
	$(VVP) sim_mux4.out

decoder:
	$(IV) -g2005 -o sim_decoder.out decoder3to8.v tb_decoder3to8.v
	$(VVP) sim_decoder.out

adder:
	$(IV) -g2005 -o sim_adder.out ripple_carry_adder.v tb_ripple_carry_adder.v
	$(VVP) sim_adder.out

wave_mux4:
	$(GTKW) tb_mux4.vcd &

wave_decoder:
	$(GTKW) tb_decoder3to8.vcd &

wave_adder:
	$(GTKW) tb_ripple_carry_adder.vcd &

clean:
	rm -f *.out *.vcd

.PHONY: all mux4 decoder adder clean wave_mux4 wave_decoder wave_adder
