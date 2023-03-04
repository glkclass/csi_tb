/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   dut_if_proxy
    Description     :   Interface   -   
                        Task        -   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class dut_if_proxy extends dutb_if_proxy_base;
    `uvm_component_utils (dut_if_proxy)

    virtual dut_if         dut_vif;

    extern function         new(string name = "dut_if_proxy", uvm_component parent=null);
    extern function void    build_phase(uvm_phase phase);
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function dut_if_proxy::new(string name = "dut_if_proxy", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_if_proxy::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // connect to dut interface
    if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_vif", dut_vif))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'dut_vif' from config db")
endfunction
// ****************************************************************************************************************************
