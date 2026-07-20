module alu #(
    parameter int XLEN = 32
) (
    input  rv32_zbkb_pkg::op_e     op_i,
    input  logic [XLEN-1:0]        opa_i,
    input  logic [XLEN-1:0]        opb_i,

    output logic [XLEN-1:0]        res_o
);

    localparam int HALFXLEN = XLEN/2;

    logic [$clog2(XLEN)-1:0] shamt;
    logic [  $clog2(XLEN):0] xlen_minus_shamt;    // NOTE: 5:0 to allow for rotation by 0
    assign shamt            = opb_i[4:0];
    /* verilator lint_off WIDTHTRUNC */
    /* verilator lint_off WIDTHEXPAND */
    assign xlen_minus_shamt = XLEN - shamt;
    /* verilator lint_on WIDTHTRUNC */
    /* verilator lint_on WIDTHEXPAND */

    always_comb begin
        unique case (op_i)
            rv32_zbkb_pkg::OP_ROL:   res_o = (opa_i << shamt) | (opa_i >> xlen_minus_shamt);
            rv32_zbkb_pkg::OP_ROR,
            rv32_zbkb_pkg::OP_RORI:  res_o = (opa_i >> shamt) | (opa_i << xlen_minus_shamt);
            rv32_zbkb_pkg::OP_ANDN:  res_o = opa_i & ~opb_i;
            rv32_zbkb_pkg::OP_ORN:   res_o = opa_i | ~opb_i;
            rv32_zbkb_pkg::OP_XNOR:  res_o = ~(opa_i ^ opb_i);
            rv32_zbkb_pkg::OP_PACK:  res_o = { opb_i[HALFXLEN-1:0], opa_i[HALFXLEN-1:0] };
            rv32_zbkb_pkg::OP_PACKH: res_o = { HALFXLEN'(1'd0), opb_i[7:0], opa_i[7:0] };
            rv32_zbkb_pkg::OP_BREV8: begin
                for (int i = 0; i < XLEN; i += 8) begin
                    for (int j = 0; j < 8; j++) res_o[i+j] = opa_i[i+(7-j)];
                end
            end
            rv32_zbkb_pkg::OP_REV8: begin
                for (int i = 0; i < XLEN; i += 8) begin
                    res_o[i +: 8] = opa_i[XLEN-1-i -: 8];
                end
            end
            rv32_zbkb_pkg::OP_ZIP: begin
                for (int i = 0; i < HALFXLEN; i++) begin
                    res_o[2*i +: 2] = { opa_i[HALFXLEN+i], opa_i[i] };
                end
            end
            rv32_zbkb_pkg::OP_UNZIP: begin
                for (int i = 0; i < HALFXLEN; i++) begin
                    res_o[i]          = opa_i[2*i];
                    res_o[HALFXLEN+i] = opa_i[2*i+1];
                end
            end
            default: res_o = '0;
        endcase
    end

endmodule
