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

    wire hs_clk, csi_clk, rst;

    // global reset
    rst_gen                     #(.T_RST_LENGTH(P_RSTN_LENGTH)) 
    rst_gen                     (.rst(rst));

    // d-phy hs_clk
    clk_gen                     #(.T_CLK_HALF_PERIOD(P_CLK_HALF_PERIOD)) 
    hs_clk_gen                  (.clk(hs_clk));

    // csi clk
    clk_gen                     #(.T_CLK_HALF_PERIOD(P_CLK_HALF_PERIOD)) 
    csi_clk_gen                 (.clk(csi_clk));


    ci_if                       ci_if_h(.rst(rst), .clk(csi_clk));              // camera(image sensor) serial interface
    fifo_if                     fifo_if_h(.rst(rst), .clk(csi_clk));            // protocol fifo if
    
    d_phy_appi_if               d_phy_appi_if_h();                              // d-phy appi intreface
    d_phy_adapter_line_if       d_phy_adapter_line_if_h();                      // d-phy data&clock line interface
    
    dut_if  dut_if_h(           .rst(rst), 
                                .hs_clk(hs_clk),
                                .csi_clk(csi_clk),
                                .ci_vif(ci_if_h),  
                                .fifo_vif(fifo_if_h),  
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
                timeout_sim(100us, 1us);
            join_any
        end

    // store waveform if not disabled
    initial `STORE_WAVE
endmodule
// ****************************************************************************************************************************


// ****************************************************************************************************************************
// Module to provide 'clock' and 'rst' signals
module clk_gen #(parameter time T_CLK_HALF_PERIOD = 10ns) (output bit clk);
    initial     clk                         = LOW;
    always      #(T_CLK_HALF_PERIOD) clk    = ~clk;
endmodule

module rst_gen #(parameter time T_RST_LENGTH = 1ns) (output bit rst);
    initial     
        begin 
            rst                       = LOW;
            #T_RST_LENGTH rst         = HIGH;
        end
endmodule
// ****************************************************************************************************************************


