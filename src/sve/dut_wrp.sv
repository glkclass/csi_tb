/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Module          :   dut_wrp
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
module dut_wrp(interface _if);

    import dut_tb_param_pkg::*;

    ci_if                       ci_if();
    csi_fifo_if                 csi_fifo_if();
    d_phy_appi_if               d_phy_appi_if();
    d_phy_adapter_line_if       d_phy_adapter_line_if();

    csi_master_protocol_layer   csi_master_protocol_layer(
        .ci(ci_if.rx),
        .appi(d_phy_appi_if.protocol),
        .csi_fifo(csi_fifo_if));

    d_phy_master_adapter_layer  d_phy_master_adapter_layer(
        .hs_clk(_if.clk),
        .appi(d_phy_appi_if.adapter),
        .csi_fifo(csi_fifo_if),
        .line(d_phy_adapter_line_if.master));




    `ifndef NO_PROBE
        probe probe ();
    `endif
endmodule
// ****************************************************************************************************************************
