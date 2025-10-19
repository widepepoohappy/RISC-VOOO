VCS_HOME = 
VERDI_HOME = 

VCS = $(VCS_HOME)/bin/Vcs
VERDI = $(VERDI_HOME)/bin/Verdi

src = ../scr/sverilog/fulladder.sv ../scr/sverilog/registers_rv.sv ../scr/sverilog/mux.sv ../scr/sverilog/register.sv  ../scr/sverilog/maindec.sv ../scr/sverilog/hazard_u_rv.sv ../scr/sverilog/aludec.sv ../scr/sverilog/demux.sv ../scr/sverilog/RCA.sv ../scr/sverilog/ALU.sv ../scr/sverilog/extend.sv ../scr/sverilog/register_generic.sv ../scr/tb/imem.sv ../scr/tb/dmem.sv ../scr/sverilog/CU_rv.sv ../scr/sverilog/datapath.sv ../scr/sverilog/RiscV.sv ../scr/sverilog/RV_wrapper.sv

TB  = ../scr/tb/testbench.sv
FILELIST = ../compiler/run.f

SIMV = simv

VCS_FLAGS = -full64 -sverilog -debug_access+all -timescale=1ns/1ps

all: $(SIMV)

$(SIMV): $(src) $(TB)
	VCS_HOME=$(VCS_HOME) PATH=$(VCS_HOME)/bin:$$PATH $(VCS) $(VCS_FLAGS) $(src) $(TB) -o $(SIMV)

run: $(SIMV)
	./$(SIMV)

verdi: $(src) $(TB)
	VERDI_HOME=$(VERDI_HOME) PATH=$(VERDI_HOME)/bin:$$PATH $(VERDI) -sv -f $(FILELIST) -ssf

clean: 
	rm -rf $(SIMV) csrc *.fsdb* *.vpd *.log *.key novas* verdiLog* DVEfiles simv.daidir sysBusyPLog/ sysProgressPLog/ 

.PHONY: all run verdi clean
