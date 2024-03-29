/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   dut_test
    Description     :   Interface   -   
                        Task        -   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class dut_test extends dutb_test_base #(.T_DIN_TXN(csi_image_txn), .T_DOUT_TXN(csi_packet_txn));
    `uvm_component_utils(dut_test)
    
    virtual dut_if              dut_vif;

    extern function             new(string name = "dut_test", uvm_component parent = null);
    extern function void        build_phase(uvm_phase phase);
    extern function void        start_of_simulation_phase(uvm_phase phase);
    extern task                 run_phase(uvm_phase phase);
endclass

function dut_test::new(string name = "dut_test", uvm_component parent = null);
    super.new(name, parent);
endfunction
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function void dut_test::build_phase(uvm_phase phase);
    uvm_factory factory = uvm_factory::get();

    dutb_if_proxy_base::type_id::set_type_override(dut_if_proxy::get_type());
    // factory.print();

    // pass dut_vif to dut_if_proxy
    if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_vif", dut_vif))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get \"dut_vif\" from config db")
    else
        uvm_config_db #(virtual dut_if)::set(this, "dutb_if_h", "dut_vif", dut_vif);

    uvm_config_db #(bit)::set(this, "env_h*", "dout_agent_has_driver", 0);

    super.build_phase(phase);
endfunction


function void dut_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
endfunction


task dut_test::run_phase(uvm_phase phase);
    csi_image_test_seq seq_h;

    seq_h = csi_image_test_seq::type_id::create("seq_h");
    phase.raise_objection(this, "dut_test started");
    fork
        seq_h.start(env_h.din_agent_h.sqncr_h);
        dutb_handler_h.wait_for_stop_test();
    join_any
    phase.drop_objection(this, "dut_test finished");
endtask
// ****************************************************************************************************************************
