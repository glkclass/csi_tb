/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Module          :   ttb
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
module ttb;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    import dutb_param_pkg::*;
    import dutb_util_pkg::*;

    import dut_tb_param_pkg::*;
    import dut_tb_pkg::*;

    wire hs_clk, csi_clk, rst_n;

    // global reset
    rst_gen                     #(.T_RST_LENGTH(P_RSTN_LENGTH)) 
    rst_gen                     (.rst_n(rst_n));

    // d-phy hs_clk
    clk_gen                     #(.T_CLK_HALF_PERIOD(P_CLK_HALF_PERIOD)) 
    hs_clk_gen                  (.clk(hs_clk));

    // csi clk
    clk_gen                     #(.T_CLK_HALF_PERIOD(P_CLK_HALF_PERIOD)) 
    csi_clk_gen                 (.clk(csi_clk));


    ci_if                       ci_if_h(.Clk(csi_clk), .Rst_n(rst_n));              // camera(image sensor) serial interface
    csi_fifo_if                 csi_fifo_if_h(.ClkRx(csi_clk), .ClkTx(hs_clk));     // csi(prrtocol) fifo
    d_phy_appi_if               d_phy_appi_if_h();                                  // d-phy appi intreface
    d_phy_adapter_line_if       d_phy_adapter_line_if_h();                          // d-phy data&clock line interface
    
    dut_if  dut_if_h(           .rst_n(rst_n), 
                                .hs_clk(hs_clk),
                                .csi_clk(csi_clk),
                                .ci_vif(ci_if_h),  
                                .csi_fifo_vif(csi_fifo_if_h),  
                                .d_phy_appi_vif(d_phy_appi_if_h),
                                .d_phy_adapter_line_vif(d_phy_adapter_line_if_h) );

    dut_wrp DUT                 (dut_if_h);

    initial
        begin : l_main
            $timeformat(-9, 3, "ns", 8);
            // Provide DUT interfaces to UVM infra
            uvm_config_db #(virtual dut_if)::set(null, "uvm_test_top", "dut_vif", dut_if_h);
            fork
                run_test();
                timeout_sim(1us, 200ns);
            join_any
        end

    // store waveform if not disabled
    initial `STORE_WAVE
endmodule

// Module to provide 'clock' and 'rst' signals
module clk_gen #(parameter time T_CLK_HALF_PERIOD = 10ns) (output bit clk);
    initial     clk                         = LOW;
    always      #(T_CLK_HALF_PERIOD) clk    = ~clk;
endmodule
module rst_gen #(parameter time T_RST_LENGTH = 1ns) (output bit rst_n);
    initial     
        begin 
            rst_n                       = LOW;
            #T_RST_LENGTH rst_n         = HIGH;
        end
endmodule
// ****************************************************************************************************************************


