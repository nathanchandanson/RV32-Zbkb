package rv32_zbkb_pkg;

typedef enum logic [3:0] {
    OP_ROL,
    OP_ROR,
    OP_RORI,
    OP_ANDN,
    OP_ORN,
    OP_XNOR,
    OP_PACK,
    OP_PACKH,
    OP_BREV8,
    OP_REV8,
    OP_ZIP,
    OP_UNZIP,
    OP_UNKNOWN
} op_e;

endpackage
