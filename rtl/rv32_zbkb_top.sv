module rv32_zbkb_top #(
    parameter int XLEN = 32,
    parameter int ILEN = 32
) (
    input  logic [ILEN-1:0] instr_i,
    input  logic [XLEN-1:0] rega_i,
    input  logic [XLEN-1:0] regb_i,

    output logic [XLEN-1:0] res_o
);

    rv32_zbkb_pkg::op_e op_o_dec;
    logic [XLEN-1:0]    opa_o_dec, opb_o_dec;

    rv32_zbkb_decoder #(
        .XLEN,
        .ILEN
    ) i_dec (
        .instr_i,
        .rega_i,
        .regb_i,
        .op_o(op_o_dec),
        .opa_o(opa_o_dec),
        .opb_o(opb_o_dec)
    );

    rv32_zbkb_alu #(
        .XLEN
    ) i_alu (
        .op_i(op_o_dec),
        .opa_i(opa_o_dec),
        .opb_i(opb_o_dec),

        .res_o
    );

endmodule
