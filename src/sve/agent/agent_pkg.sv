`timescale 1ns/1ns
package agent_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import dut_agent_pkg::*;

    import dut_param_pkg::*;
    import dut_tb_param_pkg::*;
    import dut_util_pkg::*;
    import dut_sequence_pkg::*;

    `include "dut_cin_driver.svh"
endpackage
 