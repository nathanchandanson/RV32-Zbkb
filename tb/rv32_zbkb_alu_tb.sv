// NOTE: This testbench was written using AI

`timescale 1ns/1ps

import rv32_zbkb_pkg::*;

/* verilator lint_off UNUSEDSIGNAL */
module rv32_zbkb_alu_tb;

    //-----------------------------------------------------------
    // Parameters / DUT signals
    //-----------------------------------------------------------
    localparam int XLEN = 32;

    op_e                 op_i;
    logic [XLEN-1:0]     opa_i;
    logic [XLEN-1:0]     opb_i;
    logic [XLEN-1:0]     res_o;

    int unsigned          err_cnt   = 0;
    int unsigned          test_cnt  = 0;

    //-----------------------------------------------------------
    // DUT instantiation
    //-----------------------------------------------------------
    rv32_zbkb_alu #(
        .XLEN(XLEN)
    ) dut (
        .op_i   (op_i),
        .opa_i  (opa_i),
        .opb_i  (opb_i),
        .res_o  (res_o)
    );

    //-----------------------------------------------------------
    // Reference model functions
    //-----------------------------------------------------------
    function automatic logic [31:0] f_rol(input logic [31:0] a, input logic [4:0] sh);
        f_rol = (a << sh) | (a >> (32 - sh));
    endfunction

    function automatic logic [31:0] f_ror(input logic [31:0] a, input logic [4:0] sh);
        f_ror = (a >> sh) | (a << (32 - sh));
    endfunction

    function automatic logic [31:0] f_andn(input logic [31:0] a, input logic [31:0] b);
        f_andn = a & ~b;
    endfunction

    function automatic logic [31:0] f_orn(input logic [31:0] a, input logic [31:0] b);
        f_orn = a | ~b;
    endfunction

    function automatic logic [31:0] f_xnor(input logic [31:0] a, input logic [31:0] b);
        f_xnor = ~(a ^ b);
    endfunction

    function automatic logic [31:0] f_pack(input logic [31:0] a, input logic [31:0] b);
        f_pack = {b[15:0], a[15:0]};
    endfunction

    function automatic logic [31:0] f_packh(input logic [31:0] a, input logic [31:0] b);
        f_packh = {16'h0, b[7:0], a[7:0]};
    endfunction

    function automatic logic [31:0] f_brev8(input logic [31:0] a);
        logic [31:0] res;
        for (int b = 0; b < 4; b++) begin
            for (int i = 0; i < 8; i++) begin
                res[b*8 + i] = a[b*8 + (7-i)];
            end
        end
        f_brev8 = res;
    endfunction

    function automatic logic [31:0] f_rev8(input logic [31:0] a);
        f_rev8 = {a[7:0], a[15:8], a[23:16], a[31:24]};
    endfunction

    // zip: even output bits <- lower half input; odd output bits <- upper half input
    function automatic logic [31:0] f_zip(input logic [31:0] a);
        logic [31:0] res;
        for (int i = 0; i < 16; i++) begin
            res[2*i]   = a[i];
            res[2*i+1] = a[16+i];
        end
        f_zip = res;
    endfunction

    // unzip: inverse of zip
    function automatic logic [31:0] f_unzip(input logic [31:0] a);
        logic [31:0] res;
        for (int i = 0; i < 16; i++) begin
            res[i]    = a[2*i];
            res[16+i] = a[2*i+1];
        end
        f_unzip = res;
    endfunction

    // top level reference model dispatcher
    function automatic logic [31:0] ref_model(input op_e op, input logic [31:0] a, input logic [31:0] b);
        case (op)
            OP_ROL   : ref_model = f_rol(a, b[4:0]);
            OP_ROR   : ref_model = f_ror(a, b[4:0]);
            OP_RORI  : ref_model = f_ror(a, b[4:0]); // shamt passed through opb_i
            OP_ANDN  : ref_model = f_andn(a, b);
            OP_ORN   : ref_model = f_orn(a, b);
            OP_XNOR  : ref_model = f_xnor(a, b);
            OP_PACK  : ref_model = f_pack(a, b);
            OP_PACKH : ref_model = f_packh(a, b);
            OP_BREV8 : ref_model = f_brev8(a);
            OP_REV8  : ref_model = f_rev8(a);
            OP_ZIP   : ref_model = f_zip(a);
            OP_UNZIP : ref_model = f_unzip(a);
            default  : ref_model = '0;
        endcase
    endfunction

    //-----------------------------------------------------------
    // Helper: string for op (for error messages)
    //-----------------------------------------------------------
    function automatic string op_name(input op_e op);
        case (op)
            OP_ROL   : return "OP_ROL";
            OP_ROR   : return "OP_ROR";
            OP_RORI  : return "OP_RORI";
            OP_ANDN  : return "OP_ANDN";
            OP_ORN   : return "OP_ORN";
            OP_XNOR  : return "OP_XNOR";
            OP_PACK  : return "OP_PACK";
            OP_PACKH : return "OP_PACKH";
            OP_BREV8 : return "OP_BREV8";
            OP_REV8  : return "OP_REV8";
            OP_ZIP   : return "OP_ZIP";
            OP_UNZIP : return "OP_UNZIP";
            default  : return "UNKNOWN";
        endcase
    endfunction

    //-----------------------------------------------------------
    // Check task: drive inputs, wait, compare
    //-----------------------------------------------------------
    task automatic check_op(input op_e op, input logic [31:0] a, input logic [31:0] b);
        logic [31:0] expected;
        op_i  = op;
        opa_i = a;
        opb_i = b;
        #1; // allow combinational settling
        expected = ref_model(op, a, b);
        test_cnt++;
        if (res_o !== expected) begin
            err_cnt++;
            $error("[FAIL] op=%s a=%h b=%h => got=%h exp=%h",
                    op_name(op), a, b, res_o, expected);
        end
        else begin
            $display("[PASS] op=%s a=%h b=%h => res=%h", op_name(op), a, b, res_o);
        end
    endtask

    //-----------------------------------------------------------
    // Directed test vectors
    //-----------------------------------------------------------
    task automatic directed_tests();
        // Rotate operations
        check_op(OP_ROL,  32'h0000_0001, 32'd0);
        check_op(OP_ROL,  32'h0000_0001, 32'd1);
        check_op(OP_ROL,  32'h8000_0000, 32'd1);
        check_op(OP_ROL,  32'h1234_5678, 32'd31);
        check_op(OP_ROL,  32'hFFFF_FFFF, 32'd7);

        check_op(OP_ROR,  32'h0000_0001, 32'd0);
        check_op(OP_ROR,  32'h0000_0001, 32'd1);
        check_op(OP_ROR,  32'h8000_0000, 32'd31);
        check_op(OP_ROR,  32'h1234_5678, 32'd4);

        check_op(OP_RORI, 32'hDEAD_BEEF, 32'd8);
        check_op(OP_RORI, 32'hDEAD_BEEF, 32'd0);
        check_op(OP_RORI, 32'hDEAD_BEEF, 32'd31);

        // Logic-with-negate operations
        check_op(OP_ANDN, 32'hFFFF_0000, 32'h00FF_00FF);
        check_op(OP_ANDN, 32'h0000_0000, 32'hFFFF_FFFF);
        check_op(OP_ORN,  32'hFFFF_0000, 32'h00FF_00FF);
        check_op(OP_ORN,  32'h0000_0000, 32'h0000_0000);
        check_op(OP_XNOR, 32'hAAAA_AAAA, 32'h5555_5555);
        check_op(OP_XNOR, 32'hFFFF_FFFF, 32'hFFFF_FFFF);

        // Pack operations
        check_op(OP_PACK,  32'h1234_5678, 32'h9ABC_DEF0);
        check_op(OP_PACK,  32'hFFFF_0000, 32'h0000_FFFF);
        check_op(OP_PACKH, 32'h1234_5678, 32'h9ABC_DEF0);
        check_op(OP_PACKH, 32'h0000_00FF, 32'h0000_00AA);

        // Bit/byte reversal
        check_op(OP_BREV8, 32'h0102_0408, 32'h0);
        check_op(OP_BREV8, 32'hFFFF_FFFF, 32'h0);
        check_op(OP_BREV8, 32'h0000_0001, 32'h0);
        check_op(OP_REV8,  32'h1234_5678, 32'h0);
        check_op(OP_REV8,  32'h0000_0001, 32'h0);
        check_op(OP_REV8,  32'hFF00_00FF, 32'h0);

        // Zip / Unzip
        check_op(OP_ZIP,   32'h0000_FFFF, 32'h0);
        check_op(OP_ZIP,   32'hFFFF_0000, 32'h0);
        check_op(OP_ZIP,   32'hFFFF_FFFF, 32'h0);
        check_op(OP_ZIP,   32'h1234_5678, 32'h0);
        check_op(OP_UNZIP, 32'h0000_FFFF, 32'h0);
        check_op(OP_UNZIP, 32'hFFFF_0000, 32'h0);
        check_op(OP_UNZIP, 32'hFFFF_FFFF, 32'h0);
        check_op(OP_UNZIP, 32'h1234_5678, 32'h0);

        // ZIP/UNZIP inverse property check
        begin
            logic [31:0] a, zipped, unzipped;
            a = 32'hCAFEBABE;
            zipped   = f_zip(a);
            check_op(OP_ZIP,   a,       32'h0);
            check_op(OP_UNZIP, zipped,  32'h0);
        end
    endtask

    //-----------------------------------------------------------
    // Randomized tests across all ops
    //-----------------------------------------------------------
    task automatic random_tests(input int num_iters);
        op_e ops[$] = '{OP_ROL, OP_ROR, OP_RORI, OP_ANDN, OP_ORN, OP_XNOR,
                         OP_PACK, OP_PACKH, OP_BREV8, OP_REV8, OP_ZIP, OP_UNZIP};
        op_e sel_op;
        logic [31:0] a, b;
        int idx;

        for (int i = 0; i < num_iters; i++) begin
            idx    = $urandom_range(0, ops.size()-1);
            sel_op = ops[idx];
            a      = $urandom();
            b      = $urandom();
            check_op(sel_op, a, b);
        end
    endtask

    //-----------------------------------------------------------
    // Main stimulus
    //-----------------------------------------------------------
    initial begin
        $display("=== Starting Zbkb ALU Testbench ===");
        op_i  = OP_ROL;
        opa_i = '0;
        opb_i = '0;

        directed_tests();
        random_tests(500);

        $display("=== Testbench Complete: %0d tests run, %0d errors ===", test_cnt, err_cnt);
        if (err_cnt == 0)
            $display("*** ALL TESTS PASSED ***");
        else
            $display("*** %0d TEST(S) FAILED ***", err_cnt);

        $finish;
    end

endmodule
/* verilator lint_on UNUSEDSIGNAL */
