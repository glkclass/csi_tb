/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Interface       :   dut_if
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
interface dut_if(input 
                bit                     rst, hs_clk, csi_clk, 
                ci_if                   ci_vif, 
                fifo_in_if              fifo_in_vif,
                fifo_out_if             fifo_out_vif,
                d_phy_appi_if           d_phy_appi_vif,
                d_phy_adapter_line_if   d_phy_adapter_line_vif);
    
    import dut_tb_param_pkg::*;

    // DUT interface
    logic           [P_CIN_DATA_WIDTH-1 : 0]                data;
    logic                                                   valid;
endinterface
// ****************************************************************************************************************************
