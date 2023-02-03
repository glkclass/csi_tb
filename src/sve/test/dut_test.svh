class dut_test extends dut_test_base #(depth_frame_txn, histo_txn, dut_pout_txn);
    `uvm_component_utils(dut_test)
    extern function new(string name = "dut_test", uvm_component parent = null);
    extern task run_phase(uvm_phase phase);
endclass

function dut_test::new(string name = "dut_test", uvm_component parent = null);
    super.new(name, parent);
endfunction


task dut_test::run_phase(uvm_phase phase);
    depth_frame_seq seq_h;
    seq_h = depth_frame_seq::type_id::create("seq_h");
    // dut_handler_h.recorder_db_mode = WRITE;  // enable store failed txn to 'recorder_db' file
    phase.raise_objection(this, "dut_test started");
    @ (posedge dut_vif.rstn);
    uvm_top.print_topology();

    fork
        seq_h.start(env_h.din_agent_h.sqncr_h);
        dut_handler_h.wait_for_stop_test();
    join_any
    phase.drop_objection(this, "dut_test finished");
endtask