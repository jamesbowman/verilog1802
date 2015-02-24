/* verilator lint_off UNUSED */

module testbench (
  input clock,
  output [7:0] cc,
  output unsupported,
  input [7:0] io_din,
  output io_inp,
  output io_out,
  output [7:0] io_dout,
  output [2:0] io_n
);

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

    .io_n(io_n),
    .io_inp(io_inp),
    .io_out(io_out),

    .ram_rd(ram_rd),
    .ram_wr(ram_wr),
    .ram_q(ram_q),
    .ram_d(ram_d),
    .ram_a(ram_a),

    .io_din(io_din),
    .io_dout(io_dout),

    .unsupported(unsupported)
    );

endmodule
