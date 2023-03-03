module ttb;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    import dutb_param_pkg::*;
    import dutb_util_pkg::*;

    import dut_tb_param_pkg::*;

    bit clk, rst_n;

    rst_clk_gen             #(.T_RST_LENGTH(P_RSTN_LENGTH), .T_CLK_HALF_PERIOD(P_CLK_HALF_PERIOD)) 
    rst_clk_gen             (.clk(clk), .rst_n(rst_n));

    dut_if  dut_if_h        (.clk(clk), .rst_n(rst_n));
    dut_wrp dut             (dut_if_h);

    initial
        begin : l_main
            $timeformat(-9, 0, "ns", 8);
            // Provide DUT interfaces to UVM infra
            uvm_config_db #(virtual dut_if)::set(null, "uvm_test_top", "dut_vif", dut_if_h);
            fork
                run_test();
                timeout_sim(100, 20);
            join_any
        end

    // store waveforms if not disabled
    initial `STORE_WAVE
endmodule

// Module to provide 'clock' and 'rst' signals
module rst_clk_gen #(parameter T_RST_LENGTH = 1ns, T_CLK_HALF_PERIOD = 10ns) (output bit clk, rst_n);
    initial     {rst_n, clk}                = 2'b00;
    initial     #T_RST_LENGTH rst_n         = 1'b1;
    always      #(T_CLK_HALF_PERIOD) clk    = ~clk;
endmodule