interface dut_if
(
    input clk, rst_n
);
    import dut_tb_param_pkg::*;

    // DUT interface
    logic           [P_CIN_DATA_WIDTH-1 : 0]                data;
    logic                                                   valid;
endinterface
