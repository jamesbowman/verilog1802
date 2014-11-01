/* verilator lint_off UNUSED */

module testbench (
  input clock,
  output [7:0] cc,
  output bad,
  input [7:0] bus_in,
  output [7:0] bus_out,
  output [2:0] n
);
  // initial begin $display("Hello World"); $finish; end

  reg [7:0] count;
  always @(posedge clock)
    count <= count + 1;
  assign cc = count;

  wire ram_rd, ram_wr;
  wire [7:0] ram_q, ram_d;
  wire [15:0] ram_a;

  ram _ram (
    .clk(clock),
    .re(ram_rd),
    .we(ram_wr),
    .d(ram_d),
    .a(ram_a),
    .q(ram_q));

  /* verilator lint_off UNUSED */
  wire Q;
  cdp1802 cdp1802 (
    .clock(clock),
    .resetq(1),
    .Q(Q),
    .EF(4'b0000),
    .n(n),

    .ram_rd(ram_rd),
    .ram_wr(ram_wr),
    .ram_q(ram_q),
    .ram_d(ram_d),
    .ram_a(ram_a),

    .bus_in(bus_in),
    .bus_out(bus_out),

    .bad(bad)
    );

endmodule
