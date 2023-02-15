`timescale 1ns/1ns
package sequence_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    import dutb_typedef_pkg::*;
    import dutb_param_pkg::*;
    import dutb_pkg::*;
    
    import dut_param_pkg::*;
    import dut_if_proxy_pkg::*;

    `include "cin_txn.svh"
    `include "cin_test_seq.svh"

    // `include "depth_txn.svh"
    // `include "depth_frame_txn.svh"
    // `include "histo_txn.svh"
    // `include "dut_pout_txn.svh"
    // `include "series_seq.svh"
endpackage

