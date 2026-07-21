// NOTE: This testbench was written using AI

`timescale 1ns/1ps

/* verilator lint_off UNUSEDSIGNAL */
module rv32_zbkb_top_tb;
  import rv32_zbkb_pkg::*;

  localparam int XLEN = 32;
  localparam int ILEN = 32;
  localparam int N_RAND = 15; // random iterations per op

  logic [ILEN-1:0] instr;
  logic [XLEN-1:0] rega, regb;
  logic [XLEN-1:0] res;

  int unsigned checks = 0;
  int unsigned errors = 0;

  rv32_zbkb_top #(
      .XLEN(XLEN),
      .ILEN(ILEN)
  ) dut (
      .instr_i(instr),
      .rega_i (rega),
      .regb_i (regb),
      .res_o  (res)
  );

  // ---------------------------------------------------------------------
  // Fixed register-field placeholders (decoder only needs to route
  // rega_i/regb_i -> ALU operands; actual rs1/rs2/rd numbers are
  // arbitrary as long as they're non-zero/consistent).
  // ---------------------------------------------------------------------
  localparam logic [4:0] RS1 = 5'd1;
  localparam logic [4:0] RS2 = 5'd2;
  localparam logic [4:0] RD  = 5'd3;

  localparam logic [6:0] OPC_OP    = 7'b0110011;
  localparam logic [6:0] OPC_OPIMM = 7'b0010011;

  // ---------------------------------------------------------------------
  // ENCODING FIELDS (adjust here if your decoder differs)
  // ---------------------------------------------------------------------
  localparam logic [6:0] F7_ROL_ROR_RORI    = 7'b0110000;
  localparam logic [6:0] F7_ANDN_ORN_XNOR   = 7'b0100000;
  localparam logic [6:0] F7_PACK_PACKH      = 7'b0000100;

  localparam logic [2:0] F3_ROL        = 3'b001;
  localparam logic [2:0] F3_ROR_RORI   = 3'b101;
  localparam logic [2:0] F3_XNOR_PACK  = 3'b100;
  localparam logic [2:0] F3_ORN        = 3'b110;
  localparam logic [2:0] F3_ANDN_PACKH = 3'b111;

  localparam logic [11:0] IMM_BREV8 = 12'b0110_0000_0111; // 0x607
  localparam logic [11:0] IMM_REV8  = 12'b0110_1001_1000; // 0x698
  localparam logic [11:0] IMM_ZIP   = 12'b0000_1000_1111; // 0x08F (shared by zip/unzip)
  localparam logic [2:0]  F3_ZIP    = 3'b001;
  localparam logic [2:0]  F3_UNZIP  = 3'b101;

  // ---------------------------------------------------------------------
  // Generic encoders
  // ---------------------------------------------------------------------
  function automatic logic [31:0] enc_r(logic [6:0] funct7, logic [4:0] rs2,
                                         logic [4:0] rs1, logic [2:0] funct3,
                                         logic [4:0] rd, logic [6:0] opcode);
    enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  function automatic logic [31:0] enc_i(logic [11:0] imm, logic [4:0] rs1,
                                         logic [2:0] funct3, logic [4:0] rd,
                                         logic [6:0] opcode);
    enc_i = {imm, rs1, funct3, rd, opcode};
  endfunction

  // ---------------------------------------------------------------------
  // Per-op instruction builders
  // ---------------------------------------------------------------------
  function automatic logic [31:0] i_rol();
    i_rol = enc_r(F7_ROL_ROR_RORI, RS2, RS1, F3_ROL, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_ror();
    i_ror = enc_r(F7_ROL_ROR_RORI, RS2, RS1, F3_ROR_RORI, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_rori(logic [4:0] shamt);
    i_rori = enc_i({F7_ROL_ROR_RORI, shamt}, RS1, F3_ROR_RORI, RD, OPC_OPIMM);
  endfunction
  function automatic logic [31:0] i_andn();
    i_andn = enc_r(F7_ANDN_ORN_XNOR, RS2, RS1, F3_ANDN_PACKH, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_orn();
    i_orn = enc_r(F7_ANDN_ORN_XNOR, RS2, RS1, F3_ORN, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_xnor();
    i_xnor = enc_r(F7_ANDN_ORN_XNOR, RS2, RS1, F3_XNOR_PACK, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_pack();
    i_pack = enc_r(F7_PACK_PACKH, RS2, RS1, F3_XNOR_PACK, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_packh();
    i_packh = enc_r(F7_PACK_PACKH, RS2, RS1, F3_ANDN_PACKH, RD, OPC_OP);
  endfunction
  function automatic logic [31:0] i_brev8();
    i_brev8 = enc_i(IMM_BREV8, RS1, F3_ROR_RORI, RD, OPC_OPIMM);
  endfunction
  function automatic logic [31:0] i_rev8();
    i_rev8 = enc_i(IMM_REV8, RS1, F3_ROR_RORI, RD, OPC_OPIMM);
  endfunction
  function automatic logic [31:0] i_zip();
    i_zip = enc_i(IMM_ZIP, RS1, F3_ZIP, RD, OPC_OPIMM);
  endfunction
  function automatic logic [31:0] i_unzip();
    i_unzip = enc_i(IMM_ZIP, RS1, F3_UNZIP, RD, OPC_OPIMM);
  endfunction

  // ---------------------------------------------------------------------
  // Golden (reference) behavioral models
  // ---------------------------------------------------------------------
  function automatic logic [31:0] ref_rol(logic [31:0] a, logic [4:0] sh);
    ref_rol = (sh == 5'd0) ? a : ((a << sh) | (a >> (6'd32 - sh)));
  endfunction
  function automatic logic [31:0] ref_ror(logic [31:0] a, logic [4:0] sh);
    ref_ror = (sh == 5'd0) ? a : ((a >> sh) | (a << (6'd32 - sh)));
  endfunction
  function automatic logic [31:0] ref_andn(logic [31:0] a, logic [31:0] b);
    ref_andn = a & ~b;
  endfunction
  function automatic logic [31:0] ref_orn(logic [31:0] a, logic [31:0] b);
    ref_orn = a | ~b;
  endfunction
  function automatic logic [31:0] ref_xnor(logic [31:0] a, logic [31:0] b);
    ref_xnor = ~(a ^ b);
  endfunction
  function automatic logic [31:0] ref_pack(logic [31:0] a, logic [31:0] b);
    ref_pack = {b[15:0], a[15:0]};
  endfunction
  function automatic logic [31:0] ref_packh(logic [31:0] a, logic [31:0] b);
    ref_packh = {16'b0, b[7:0], a[7:0]};
  endfunction
  function automatic logic [31:0] ref_brev8(logic [31:0] a);
    logic [31:0] r;
    for (int byte_i = 0; byte_i < 4; byte_i++)
      for (int bit_i = 0; bit_i < 8; bit_i++)
        r[byte_i*8 + bit_i] = a[byte_i*8 + (7 - bit_i)];
    ref_brev8 = r;
  endfunction
  function automatic logic [31:0] ref_rev8(logic [31:0] a);
    ref_rev8 = {a[7:0], a[15:8], a[23:16], a[31:24]};
  endfunction
  function automatic logic [31:0] ref_zip(logic [31:0] a);
    logic [31:0] r;
    for (int i = 0; i < 16; i++) begin
      r[2*i]   = a[i];
      r[2*i+1] = a[i+16];
    end
    ref_zip = r;
  endfunction
  function automatic logic [31:0] ref_unzip(logic [31:0] a);
    logic [31:0] r;
    for (int i = 0; i < 16; i++) begin
      r[i]    = a[2*i];
      r[i+16] = a[2*i+1];
    end
    ref_unzip = r;
  endfunction

  // ---------------------------------------------------------------------
  // Check task
  // ---------------------------------------------------------------------
  task automatic check(input string name, input logic [31:0] instr_v,
                        input logic [31:0] a, input logic [31:0] b,
                        input logic [31:0] expected);
    instr = instr_v;
    rega  = a;
    regb  = b;
    #1;
    checks++;
    if (res !== expected) begin
      errors++;
      $display("[FAIL] %-6s instr=%08h a=%08h b=%08h exp=%08h got=%08h",
                name, instr_v, a, b, expected, res);
    end else begin
      $display("[PASS] %-6s instr=%08h a=%08h b=%08h exp=%08h got=%08h",
                name, instr_v, a, b, expected, res);
    end
  endtask

  // Directed corner-case operand set
  logic [31:0] corners[6] = '{
      32'h0000_0000, 32'hFFFF_FFFF, 32'h8000_0001,
      32'h1234_5678, 32'hAAAA_AAAA, 32'h0000_0001
  };

  initial begin
    logic [4:0] shamt;
    logic [31:0] a, b;

    $display("==== rv32_zbkb_top testbench start ====");

    // ---- Directed corner cases (each op x each corner pair) ----
    foreach (corners[i]) begin
      a = corners[i];
      b = corners[(i+1) % 6];
      check("ROL",   i_rol(),        a, b, ref_rol(a, b[4:0]));
      check("ROR",   i_ror(),        a, b, ref_ror(a, b[4:0]));
      check("ANDN",  i_andn(),       a, b, ref_andn(a, b));
      check("ORN",   i_orn(),        a, b, ref_orn(a, b));
      check("XNOR",  i_xnor(),       a, b, ref_xnor(a, b));
      check("PACK",  i_pack(),       a, b, ref_pack(a, b));
      check("PACKH", i_packh(),      a, b, ref_packh(a, b));
      check("BREV8", i_brev8(),      a, b, ref_brev8(a));
      check("REV8",  i_rev8(),       a, b, ref_rev8(a));
      check("ZIP",   i_zip(),        a, b, ref_zip(a));
      check("UNZIP", i_unzip(),      a, b, ref_unzip(a));
    end

    // RORI directed shift amounts (0, 1, 16, 31)
    a = 32'h1234_5678;
    check("RORI", i_rori(5'd0),  a, 32'b0, ref_ror(a, 5'd0));
    check("RORI", i_rori(5'd1),  a, 32'b0, ref_ror(a, 5'd1));
    check("RORI", i_rori(5'd16), a, 32'b0, ref_ror(a, 5'd16));
    check("RORI", i_rori(5'd31), a, 32'b0, ref_ror(a, 5'd31));

    // ---- Randomized regression per op ----
    for (int k = 0; k < N_RAND; k++) begin
      a = $urandom();
      b = $urandom();
      check("ROL",   i_rol(),   a, b, ref_rol(a, b[4:0]));
      check("ROR",   i_ror(),   a, b, ref_ror(a, b[4:0]));
      check("ANDN",  i_andn(),  a, b, ref_andn(a, b));
      check("ORN",   i_orn(),   a, b, ref_orn(a, b));
      check("XNOR",  i_xnor(),  a, b, ref_xnor(a, b));
      check("PACK",  i_pack(),  a, b, ref_pack(a, b));
      check("PACKH", i_packh(), a, b, ref_packh(a, b));
      check("BREV8", i_brev8(), a, b, ref_brev8(a));
      check("REV8",  i_rev8(),  a, b, ref_rev8(a));
      check("ZIP",   i_zip(),   a, b, ref_zip(a));
      check("UNZIP", i_unzip(), a, b, ref_unzip(a));

      shamt = $urandom_range(0, 31);
      check("RORI", i_rori(shamt), a, 32'b0, ref_ror(a, shamt));
    end

    // ---- Unknown / illegal instruction: expect decoder to flag OP_UNKNOWN.
    // res_o value is implementation-defined for this case, so we only log it
    // rather than compare against a golden value.
    instr = 32'h0000_0033; // add x0,x0,x0 -- not a Zbkb op
    rega  = 32'hDEAD_BEEF;
    regb  = 32'h1357_9BDF;
    #1;
    $display("[INFO] UNKNOWN instr=%08h -> res=%08h (implementation-defined)",
              instr, res);

    $display("==== rv32_zbkb_top testbench done ====");
    $display("Checks: %0d   Errors: %0d", checks, errors);
    if (errors == 0)
      $display("RESULT: ALL TESTS PASSED");
    else
      $display("RESULT: %0d TEST(S) FAILED", errors);

    $finish;
  end

endmodule
/* verilator lint_on UNUSEDSIGNAL */
