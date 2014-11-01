#include <stdio.h>
#include "Vtestbench.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vtestbench* top = new Vtestbench;

    // Verilated::traceEverOn(true);
    // VerilatedVcdC* tfp = new VerilatedVcdC;
    // top->trace (tfp, 99);
    // tfp->open ("simx.vcd");

    if (argc != 2) {
      fprintf(stderr, "usage: sim <input-file>\n");
      exit(1);
    }
    FILE *input = fopen(argv[1], "r");
    if (!input) {
      perror(argv[1]);
      exit(1);
    }

    // top->bus_in = getc(input);

    FILE *log = fopen("log", "w");
    int t = 0;
    int i;
    for (i = 0; i < 534563551; i++) {
      top->clock = 1;
      top->eval();
      // tfp->dump(t);
      t += 20;

      top->clock = 0;
      top->eval();
      // tfp->dump(t);
      t += 20;
      if (top->n & 1) {
        // fprintf(stderr, "%d emit %c\n", i, top->bus_out);
        putchar(top->bus_out);
        putc(top->bus_out, log);
      }
      if (top->n & 2) {
        top->bus_in = getc(input);
        // fprintf(stderr, "%d bump to %x\n", i, top->bus_in);
      }
    }
    delete top;
    // tfp->close();
    fclose(log);

    exit(0);
}
