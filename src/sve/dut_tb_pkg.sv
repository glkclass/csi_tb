/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2015
    Package         :   dut_tb_pkg
    Description     :   Contain dut_tb stuff
******************************************************************************************************************************/


// ****************************************************************************************************************************
`timescale 1ps/1ps

package dut_tb_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    import dutb_typedef_pkg::*;
    import dutb_util_pkg::*;
    import dutb_pkg::*;
    
    import dut_tb_param_pkg::*;
    
    // UVM infra
    `include "dut_if_proxy.svh"
    `include "csi_image_txn.svh"
    `include "csi_packet_txn.svh"
    `include "csi_image_test_seq.svh"
    `include "dut_test.svh"
endpackage
// ****************************************************************************************************************************




