#include <stdio.h>
#include "Vtestbench.h"
#include "verilated_vcd_c.h"
// This include and the top->rootp syntax are proper for Verilator >= 4.210
#include "Vtestbench___024root.h"

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vtestbench* top = new Vtestbench;

    // Verilated::traceEverOn(true);
    // VerilatedVcdC* tfp = new VerilatedVcdC;
    // top->trace (tfp, 99);
    // tfp->open ("simx.vcd");

    if (argc != 2) {
      fprintf(stderr, "usage: sim <hex-file>\n");
      exit(1);
    }

    FILE *hex = fopen(argv[1], "r");
    int i;
    for (i = 0; i < 32768; i++) {
      unsigned int v;
      if (fscanf(hex, "%x\n", &v) != 1) {
        fprintf(stderr, "invalid hex value at line %d\n", i + 1);
        exit(1);
      }
      top->rootp->v__DOT___ram__DOT__store[i] = v;
    }

    FILE *log = fopen("log", "w");
    int t = 0;
    for (i = 0; !top->unsupported; i++) {
      top->clock = 1;
      top->eval();
      // tfp->dump(t);
      t += 20;

      top->clock = 0;
      top->eval();
      // tfp->dump(t);
      t += 20;
      if (top->io_out && (top->io_n == 1)) {
        putchar(top->io_dout);
        putc(top->io_dout, log);
      }
      if (top->io_inp && (top->io_n == 2)) {
        top->io_din = getchar();
      }
    }
    printf("Simulation ended after %d cycles\n", i);
    delete top;
    // tfp->close();
    fclose(log);

    exit(0);
}
