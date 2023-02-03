`timescale 1ns/1ns
package sequence_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import dut_sequence_pkg::*;

    import typedef_pkg::*;
    import dut_param_pkg::*;
    import dut_tb_param_pkg::*;
    import dut_handler_pkg::*;

    `include "depth_txn.svh"
    `include "depth_frame_txn.svh"
    `include "histo_txn.svh"
    `include "dut_pout_txn.svh"
    `include "series_seq.svh"
endpackage

