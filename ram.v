`default_nettype none

module ram(
  input clk,
  /* verilator lint_off UNUSED */
  input [15:0] a,
  /* verilator lint_on UNUSED */
  input [7:0] d,
  input we,
  input re,
  output reg [7:0] q);
  reg [7:0] store[0:32767] /* verilator public_flat */;

  always @(posedge clk)
    if (we) begin
      store[a[14:0]] <= d;
    end else if (re)
      q <= store[a[14:0]];
endmodule
