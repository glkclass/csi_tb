interface dut_if
(
    input clk, rstn
);
    import dut_param_pkg::*;

    // DUT interface
    logic           [P_CIN_DATA_WIDTH-1 : 0]                data;
    logic                                                   valid;
endinterface
