// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_test extends dutb_test_base #(.T_DIN_TXN(cin_txn));
    `uvm_component_utils(dut_test)
    
    virtual dut_if              dut_vif;

    extern function             new(string name = "dut_test", uvm_component parent = null);
    extern function void        build_phase(uvm_phase phase);
    extern task                 run_phase(uvm_phase phase);
endclass

function dut_test::new(string name = "dut_test", uvm_component parent = null);
    super.new(name, parent);
endfunction
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function void dut_test::build_phase(uvm_phase phase);
    uvm_factory factory = uvm_factory::get();

    dutb_if_proxy_base::type_id::set_type_override(dut_if_proxy::get_type());
    // factory.print();

    // pass dut_vif to dut_if_proxy
    if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_vif", dut_vif))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get \"dut_vif\" from config db")
    else
        uvm_config_db #(virtual dut_if)::set(this, "dutb_if_h", "dut_vif", dut_vif);

    super.build_phase(phase);
endfunction


task dut_test::run_phase(uvm_phase phase);
    cin_test_seq seq_h;

    seq_h = cin_test_seq::type_id::create("seq_h");
    // dut_handler_h.recorder_db_mode = WRITE;  // enable store failed txn to 'recorder_db' file
    phase.raise_objection(this, "dut_test started");
    @ (posedge dut_vif.rstn);
    // uvm_top.print_topology();

    fork
        seq_h.start(env_h.din_agent_h.sqncr_h);
        dutb_handler_h.wait_for_stop_test();
        timeout_sim(100, 20);
    join_any
    phase.drop_objection(this, "dut_test finished");
endtask
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
