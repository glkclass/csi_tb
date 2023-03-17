/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Interface       :   dut_if
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
interface dut_if(input 
                bit rst_n, hs_clk, csi_clk, 
                ci_if ci_vif, csi_fifo_if csi_fifo_vif, d_phy_appi_if d_phy_appi_vif, d_phy_adapter_line_if d_phy_adapter_line_vif);
    
    import dut_tb_param_pkg::*;

    // DUT interface
    logic           [P_CIN_DATA_WIDTH-1 : 0]                data;
    logic                                                   valid;
endinterface
// ****************************************************************************************************************************
