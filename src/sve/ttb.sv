module ttb;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    
    import dutb_param_pkg::*;

    import dut_param_pkg::*;
    import test_pkg::*;

    bit clk, rstn;

    clocker clocker     (.clk(clk), .rstn(rstn));
    dutb_if dutb_if_h   (.clk(clk), .rstn(rstn));
    dut_if  dut_if_h    (.clk(clk), .rstn(rstn));
    dut_wrp dut         (dut_if_h);

    initial
        begin : l_main
            $timeformat(-9, 0, "ns", 8);
            // Provide DUT interfaces to UVM infra
            uvm_config_db #(virtual dutb_if)::set(null, "uvm_test_top", "dutb_vif", dutb_if_h);
            uvm_config_db #(virtual dut_if)::set(null, "uvm_test_top", "dut_vif", dut_if_h);
            run_test();
        end

    // store waveforms if not disabled
    initial `STORE_WAVE
endmodule

// Module to provide 'clock' and 'rst' signals
module clocker (output bit clk, rstn);
    import dutb_param_pkg::*;
    initial     {rstn, clk}             = 2'b00;
    initial     #P_RSTN_LENGTH rstn     = 1'b1;
    always      #(P_CLK_PERIOD/2) clk   = ~clk;
endmodule
