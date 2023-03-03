// CSI TB param
package dut_tb_param_pkg;
    import csi_param_pkg::*;

    parameter
    P_CLK_HALF_PERIOD           =   T_HS_CLK_UI,  // single clk cycle duration
    P_RSTN_LENGTH               =   33,     // rst signal duration

    P_CIN_DATA_WIDTH            =   4;
endpackage

