// NOTE: This testbench was written using AI

`timescale 1ns/1ps

/* verilator lint_off UNUSEDSIGNAL */
module decoder_tb;

    import rv32_zbkb_pkg::*;

    localparam int XLEN = 32;
    localparam int ILEN = 32;

    logic [ILEN-1:0] instr;
    logic [XLEN-1:0] rega, regb;
    op_e             op;
    logic [XLEN-1:0] opa, opb;

    int errors = 0;
    int checks = 0;

    decoder #(
        .XLEN(XLEN),
        .ILEN(ILEN)
    ) dut (
        .instr_i (instr),
        .rega_i  (rega),
        .regb_i  (regb),
        .op_o    (op),
        .opa_o   (opa),
        .opb_o   (opb)
    );

    // ---------------------------------------------------------------
    // Instruction encoders
    // ---------------------------------------------------------------
    function automatic logic [31:0] r_type(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        return {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] i_type(
        input logic [11:0] imm,
        input logic [4:0]  rs1,
        input logic [2:0]  funct3,
        input logic [4:0]  rd,
        input logic [6:0]  opcode
    );
        return {imm, rs1, funct3, rd, opcode};
    endfunction

    // ---------------------------------------------------------------
    // Check task
    // ---------------------------------------------------------------
    task automatic check(
        input string        name,
        input logic [31:0]  instr_v,
        input logic [31:0]  rega_v,
        input logic [31:0]  regb_v,
        input op_e          exp_op,
        input logic [31:0]  exp_opa,
        input logic [31:0]  exp_opb
    );
        instr = instr_v;
        rega  = rega_v;
        regb  = regb_v;
        #1; // allow combinational settle

        checks++;
        if (op !== exp_op) begin
            errors++;
            $error("[%s] op_o mismatch: got %s, exp %s (instr=%08h)",
                    name, op.name(), exp_op.name(), instr_v);
        end
        if (opa !== exp_opa) begin
            errors++;
            $error("[%s] opa_o mismatch: got %08h, exp %08h", name, opa, exp_opa);
        end
        if (opb !== exp_opb) begin
            errors++;
            $error("[%s] opb_o mismatch: got %08h, exp %08h", name, opb, exp_opb);
        end
    endtask

    // ---------------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------------
    logic [31:0] ra, rb;

    initial begin
        ra = 32'hCAFEBABE;
        rb = 32'hDEADBEEF;

        // ---------------- R-type ops (opcode 0110011) ----------------
        check("ROL",   r_type(7'b0110000, 5'd2, 5'd1, 3'b001, 5'd3, 7'b0110011),
              ra, rb, OP_ROL,   ra, rb);

        check("ROR",   r_type(7'b0110000, 5'd2, 5'd1, 3'b101, 5'd3, 7'b0110011),
              ra, rb, OP_ROR,   ra, rb);

        check("ANDN",  r_type(7'b0100000, 5'd2, 5'd1, 3'b111, 5'd3, 7'b0110011),
              ra, rb, OP_ANDN,  ra, rb);

        check("ORN",   r_type(7'b0100000, 5'd2, 5'd1, 3'b110, 5'd3, 7'b0110011),
              ra, rb, OP_ORN,   ra, rb);

        check("XNOR",  r_type(7'b0100000, 5'd2, 5'd1, 3'b100, 5'd3, 7'b0110011),
              ra, rb, OP_XNOR,  ra, rb);

        check("PACK",  r_type(7'b0000100, 5'd2, 5'd1, 3'b100, 5'd3, 7'b0110011),
              ra, rb, OP_PACK,  ra, rb);

        check("PACKH", r_type(7'b0000100, 5'd2, 5'd1, 3'b111, 5'd3, 7'b0110011),
              ra, rb, OP_PACKH, ra, rb);

        // ---------------- RORI (opcode 0010011, funct7=0110000) ------
        // shamt lives in imm[4:0] (instr[24:20]) for RV32; imm[11:5]=funct7
        check("RORI_shamt5",
              i_type({7'b0110000, 5'd5}, 5'd1, 3'b101, 5'd3, 7'b0010011),
              ra, rb, OP_RORI, ra, 32'd5);

        check("RORI_shamt31",
              i_type({7'b0110000, 5'd31}, 5'd1, 3'b101, 5'd3, 7'b0010011),
              ra, rb, OP_RORI, ra, 32'd31);

        // ---------------- BREV8 / REV8 (opcode 0010011, funct7=0110100)
        check("BREV8",
              i_type({7'b0110100, 5'b00111}, 5'd1, 3'b101, 5'd3, 7'b0010011),
              ra, rb, OP_BREV8, ra, rb);

        check("REV8",
              i_type({7'b0110100, 5'b11000}, 5'd1, 3'b101, 5'd3, 7'b0010011),
              ra, rb, OP_REV8, ra, rb);

        // BREV8/REV8 funct7 match but bad rs2 field -> unknown
        check("BREV8_REV8_bad_rs2",
              i_type({7'b0110100, 5'b00000}, 5'd1, 3'b101, 5'd3, 7'b0010011),
              ra, rb, OP_UNKNOWN, ra, rb);

        // ---------------- ZIP / UNZIP (opcode 0010011, funct7=0000100)
        check("ZIP",
              i_type({7'b0000100, 5'b01111}, 5'd1, 3'b001, 5'd3, 7'b0010011),
              ra, rb, OP_ZIP, ra, rb);

        check("UNZIP",
              i_type({7'b0000100, 5'b01111}, 5'd1, 3'b101, 5'd3, 7'b0010011),
              ra, rb, OP_UNZIP, ra, rb);

        // ZIP/UNZIP funct7 match but bad rs2 field -> unknown
        check("ZIP_bad_rs2",
              i_type({7'b0000100, 5'b00000}, 5'd1, 3'b001, 5'd3, 7'b0010011),
              ra, rb, OP_UNKNOWN, ra, rb);

        // ---------------- Unknown / unsupported encodings ------------
        // Valid opcode, unmapped funct7
        check("UNKNOWN_opcode0110011_badfunct7",
              r_type(7'b1111111, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011),
              ra, rb, OP_UNKNOWN, ra, rb);

        // Valid opcode 0010011, funct7 mapped but funct3 not mapped for that group
        check("UNKNOWN_RORI_group_badfunct3",
              i_type({7'b0110000, 5'd5}, 5'd1, 3'b000, 5'd3, 7'b0010011),
              ra, rb, OP_UNKNOWN, ra, rb);

        // Completely unrelated opcode (e.g. LOAD 0000011)
        check("UNKNOWN_opcode",
              i_type(12'h000, 5'd1, 3'b010, 5'd3, 7'b0000011),
              ra, rb, OP_UNKNOWN, ra, rb);

        // ---------------- Randomized regression over R-type ops -------
        for (int i = 0; i < 50; i++) begin
            automatic logic [31:0] rand_a = $urandom();
            automatic logic [31:0] rand_b = $urandom();
            check($sformatf("RAND_ROL_%0d", i),
                  r_type(7'b0110000, 5'd2, 5'd1, 3'b001, 5'd3, 7'b0110011),
                  rand_a, rand_b, OP_ROL, rand_a, rand_b);
        end

        // ---------------- Summary --------------------------------------
        if (errors == 0)
            $display("TESTBENCH PASSED: %0d checks, 0 errors", checks);
        else
            $display("TESTBENCH FAILED: %0d checks, %0d errors", checks, errors);

        $finish;
    end

endmodule
/* verilator lint_on UNUSEDSIGNAL */
