`default_nettype none

/* verilator lint_off UNOPTFLAT */

module cdp1802 (
  input               clock,
  input               resetq,
  output reg          Q,
  input      [3:0]    EF,
  input      [7:0]    bus_in,
  output     [2:0]    n,
  output     [7:0]    bus_out,

  output              bad,

  output              ram_rd,     // read enable
  output              ram_wr,     // write enable
  output     [15:0]   ram_a,      // RAM address
  input      [7:0]    ram_q,      // RAM read data
  output     [7:0]    ram_d       // RAM write data
);

  // ---------- execution states -------------------------
  reg [2:0] state, state_n;

  localparam RESET     = 3'd0;    // hardware reset asserted
  localparam FETCH     = 3'd1;    // fetching opcode from PC
  localparam EXECUTE   = 3'd2;    // main exection state
  localparam EXECUTE2  = 3'd3;    // second execute, if memory was read
  localparam BRANCH2   = 3'd4;    // long branch, collect new PC hi-byte
  localparam BRANCH3   = 3'd5;    // short branch, new PC lo-byte
  localparam SKIP      = 3'd6;    // for untaken branch

  // ---------- registers --------------------------------
  reg [3:0] P, X;

  reg [15:0] R[0:15];             // 16x16 register file
  wire [3:0] Ra;                  // which register to work on this clock
  wire [15:0] Rrd = R[Ra];        // read out the selected register
  reg [15:0] Rwd;                 // write-back value for the register

  reg [7:0] D;                    // data register (accumulator)
  reg DF;                         // data flag (ALU carry)
  reg [7:0] bhi;                  // needed for hi-byte of long branch
  reg [7:0] ram_q_;               // registered copy of ram_q, for multi-cycle ops
  wire [3:0] I, N;

  // ---------- RAM hookups ------------------------------
  assign ram_d = (I == 4'h6) ? bus_in : D;
  assign ram_a = Rrd;             // RAM address always one of the 16-bit regs

  // ---------- conditional branch -----------------------
  reg sense;
  always @*
    casez ({I, N})
      {4'h3, 4'b?000}, {4'hc, 4'b??00}: sense = 1;
      {4'h3, 4'b?001}, {4'hc, 4'b??01}: sense = Q;
      {4'h3, 4'b?010}, {4'hc, 4'b??10}: sense = (D == 8'h00);
      {4'h3, 4'b?011}, {4'hc, 4'b??11}: sense = DF;
      {4'h3, 4'b?1??}:                  sense = EF[N[1:0]];
      default:                          sense = 1'bx;
    endcase
  wire take = sense ^ N[3];

  // ---------- fetch/execute ----------------------------
  always @*
    case (state)
    FETCH:   state_n = EXECUTE;
    EXECUTE:
      case (I)
      4'h3:     state_n = take ? BRANCH3 : FETCH;
      4'hc:     state_n = take ? BRANCH2 : SKIP;
      default:  state_n = ram_rd ? EXECUTE2 : FETCH;
      endcase
    BRANCH2:    state_n = BRANCH3;
    default:    state_n = FETCH;
    endcase
  assign {I, N} = (state == EXECUTE) ? ram_q : ram_q_;

  // ---------- decode and execute -----------------------
  wire [3:0] P_n = ((I == 4'hD)) ? N : P;           // SEP
  wire [3:0] X_n = ((I == 4'hE)) ? N : X;           // SEX
  wire Q_n = (({I, N} == 8'h7a) | ({I, N} == 8'h7b)) ? N[0] : Q; // REQ, SEQ

  // reg. read address, memory access
  reg [5:0] action;
  assign {Ra, ram_rd, ram_wr} = action;

  localparam MEM___  = 2'b00;       // no memory access
  localparam MEM_RD  = 2'b10;       // memory read strobe
  localparam MEM_WR  = 2'b01;       // memory write strobe

  always @(state, I, N)
    case (state)
    FETCH, BRANCH2, SKIP:           {action, Rwd} = {P, MEM_RD, Rrd + 16'd1};
    EXECUTE, EXECUTE2:
      casez ({I, N})
      /* LDN  */ 8'h0?:             {action, Rwd} = {N, MEM_RD, Rrd};
      /* INC  */ 8'h1?:             {action, Rwd} = {N, MEM___, Rrd + 16'd1};
      /* DEC  */ 8'h2?:             {action, Rwd} = {N, MEM___, Rrd - 16'd1};
      /* LDA  */ 8'h4?:             {action, Rwd} = {N, MEM_RD, Rrd + 16'd1};
      /* STR  */ 8'h5?:             {action, Rwd} = {N, MEM_WR, Rrd};
      /* GLO  */ 8'h8?,
      /* GHI  */ 8'h9?:             {action, Rwd} = {N, MEM___, Rrd};
      /* PLO  */ 8'ha?:             {action, Rwd} = {N, MEM___, Rrd[15:8], D};
      /* PHI  */ 8'hb?:             {action, Rwd} = {N, MEM___, D, Rrd[7:0]};

      /* STXD */ 8'h73:             {action, Rwd} = {X, MEM_WR, Rrd - 16'd1};
      /* LDXA */ 8'h72,
      /* OUT  */ {4'h6, 4'b0???}:   {action, Rwd} = {X, MEM_RD, Rrd + 16'd1};
      /* INP  */ {4'h6, 4'b1???}:   {action, Rwd} = {X, MEM_WR, Rrd};

      8'h7c, 8'h7d, 8'h7f, 8'hf8, 8'hf9, 8'hfa, 8'hfb, 8'hfc, 8'hfd, 8'hff,
      8'h3?, 8'hc?:                 {action, Rwd} = {P, MEM_RD, Rrd + 16'd1};

      default:                      {action, Rwd} = {X, MEM_RD, Rrd};
      endcase
    BRANCH3:                        {action, Rwd} = {P, MEM___, (I == 4'hc) ? bhi : Rrd[15:8], ram_q};
    default:                        {action, Rwd} = {X, MEM___, Rrd};
    endcase

  wire [8:0] carry = (I[3]) ? 9'd0 : {8'd0, DF};      // 0 or 1 for ADC
  wire [8:0] borrow = (I[3]) ? 9'd0 : ~{9{DF}};       // 0 or -1 for SDB and SMB
  reg [8:0] DFD_n;
  always @*
    casez ({I, N})
    /* LDXA */ {8'h72},
    /* LDX  */ {8'hf0},
    /* LDI  */ {8'hf8},
    /* LDA  */ {8'h4?},
    /* LDN  */ {4'h0, 4'b????}:  DFD_n = {DF, ram_q};
    /* GLO  */ {4'h8, 4'b????}:  DFD_n = {DF, Rrd[7:0]};
    /* GHI  */ {4'h9, 4'b????}:  DFD_n = {DF, Rrd[15:8]};
    /* INP  */ {4'h6, 4'b1???}:  DFD_n = {DF, bus_in};
    /* OR   */ {8'b1111?001}:    DFD_n = {DF, D | ram_q};
    /* AND  */ {8'b1111?010}:    DFD_n = {DF, D & ram_q};
    /* XOR  */ {8'b1111?011}:    DFD_n = {DF, D ^ ram_q};
    /* ADD  */ {8'b?111?100}:    DFD_n = {1'b0, D} + {1'b0, ram_q} + carry;
    /* SD   */ {8'b?111?101}:    DFD_n = ({1'b1, ram_q} - {1'b0, D}) + borrow;
    /* SM   */ {8'b?111?111}:    DFD_n = ({1'b1, D} - {1'b0, ram_q}) + borrow;
    /* SHR  */ {8'b?1110110}:    DFD_n = {D[0], carry[0], D[7:1]};
    /* SHL  */ {8'b?1111110}:    DFD_n = {D, carry[0]};
    default:                     DFD_n = {DF, D};
    endcase

  assign n = ((I == 4'h6) &
              (N[3] ? (state == EXECUTE) : (state == EXECUTE2))) ? N[2:0] : 3'b000;
  assign bus_out = ram_q;
  assign bad = {I, N} == 8'h70;

  // ---------- cycle commit -----------------------------
  always @(negedge resetq or posedge clock)
    if (!resetq) begin
      {ram_q_, Q, P, X} <= 0;
      {DF, D} <= 9'd0;
      R[0] <= 16'd0;
      state <= RESET;
    end else begin
      state <= state_n;
      if (state == EXECUTE)
        {ram_q_, Q, P, X} <= {ram_q, Q_n, P_n, X_n};
      if (state != EXECUTE2)
        R[Ra] <= Rwd;
      if (((state == EXECUTE) & !ram_rd) || (state == EXECUTE2))
        {DF, D} <= DFD_n;
      if (state == BRANCH2)
        bhi <= ram_q;
    end
endmodule
