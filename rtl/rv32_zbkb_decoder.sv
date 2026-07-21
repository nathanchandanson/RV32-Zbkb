module rv32_zbkb_decoder #(
    parameter int XLEN = 32,
    parameter int ILEN = 32
) (
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [ILEN-1:0] instr_i,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [XLEN-1:0] rega_i,
    input  logic [XLEN-1:0] regb_i,

    output rv32_zbkb_pkg::op_e     op_o,
    output logic [XLEN-1:0]        opa_o,
    output logic [XLEN-1:0]        opb_o
);

    // Useful signals
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [$clog2(XLEN)-1:0] imm_shamt;
    logic [6:0] funct7;
    assign opcode    = instr_i[6:0];
    assign funct3    = instr_i[14:12];
    assign imm_shamt = instr_i[20 +: $clog2(XLEN)];
    assign funct7    = instr_i[31:25];

    // Values outputting
    assign opa_o = rega_i;
    assign opb_o = (op_o == rv32_zbkb_pkg::OP_RORI) ? { {(XLEN-$clog2(XLEN)){1'b0}}, imm_shamt }
                                                    : regb_i;

    always_comb begin
        op_o = rv32_zbkb_pkg::OP_UNKNOWN;

        /* verilator lint_off CASEINCOMPLETE */
        if (opcode == 7'b0110011) begin
            unique0 case (funct7)
                7'b0110000: begin
                    unique0 case (funct3)
                        3'b001: op_o = rv32_zbkb_pkg::OP_ROL;
                        3'b101: op_o = rv32_zbkb_pkg::OP_ROR;
                    endcase
                end
                7'b0100000: begin
                    unique0 case (funct3)
                        3'b111: op_o = rv32_zbkb_pkg::OP_ANDN;
                        3'b110: op_o = rv32_zbkb_pkg::OP_ORN;
                        3'b100: op_o = rv32_zbkb_pkg::OP_XNOR;
                    endcase
                end
                7'b0000100: begin
                    unique0 case (funct3)
                        3'b111: op_o = rv32_zbkb_pkg::OP_PACKH;
                        3'b100: op_o = rv32_zbkb_pkg::OP_PACK;
                    endcase
                end
            endcase
        end else if (opcode == 7'b0010011) begin
            unique0 case (funct7)
                7'b0110000: begin
                    unique0 case (funct3)
                        3'b101: op_o = rv32_zbkb_pkg::OP_RORI;
                    endcase
                end
                7'b0110100: begin
                    unique0 case (funct3)
                        3'b101: begin
                            if      (instr_i[24:20] == 5'b00111) op_o = rv32_zbkb_pkg::OP_BREV8;
                            else if (instr_i[24:20] == 5'b11000) op_o = rv32_zbkb_pkg::OP_REV8;
                        end
                    endcase
                end
                7'b0000100: begin
                    unique0 case (funct3)
                        3'b001: if (instr_i[24:20] == 5'b01111) op_o = rv32_zbkb_pkg::OP_ZIP;
                        3'b101: if (instr_i[24:20] == 5'b01111) op_o = rv32_zbkb_pkg::OP_UNZIP;
                    endcase
                end
            endcase
        end
        /* verilator lint_on CASEINCOMPLETE */
    end

endmodule
