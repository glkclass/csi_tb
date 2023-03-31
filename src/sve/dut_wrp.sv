/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Module          :   dut_wrp
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
module dut_wrp(dut_if vif);

    import dut_tb_param_pkg::*;

    assign vif.d_phy_appi_vif.Enable = vif.rst;

    csi_master_protocol_layer   csi_master_protocol_layer(
        .ci(vif.ci_vif.rx),
        .appi(vif.d_phy_appi_vif.protocol),
        .fifo(vif.fifo_vif));

    d_phy_master_adapter_layer  d_phy_master_adapter_layer(
        .hs_clk(vif.hs_clk),
        .appi(vif.d_phy_appi_vif.adapter),
        .fifo(vif.fifo_vif),
        .line(vif.d_phy_adapter_line_vif.master));


    `ifndef NO_PROBE
        probe probe ();
    `endif
endmodule
// ****************************************************************************************************************************
