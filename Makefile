
$(SUBDIRS):
	$(MAKE) -C $@

all: obj_dir/Vtestbench $(SUBDIRS)

VERILOGS=testbench.v cdp1802.v ram.v

obj_dir/Vtestbench: $(VERILOGS) sim_main.cpp Makefile
	verilator -Wall --cc --trace $(VERILOGS) --top-module testbench --l2-name v --exe sim_main.cpp
	$(MAKE) -C obj_dir OPT_FAST="-O2" -f Vtestbench.mk Vtestbench

.PHONY: all
