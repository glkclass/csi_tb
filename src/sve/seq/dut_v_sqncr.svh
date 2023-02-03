// virtual sequencer class- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_v_sqncr #(type t_din_txn = dut_txn_base) extends uvm_virtual_sequencer;
    `uvm_component_param_utils(dut_v_sqncr #(t_din_txn))

    uvm_sequencer #(t_din_txn) din_sqncr_h;
    extern function new(string name = "dut_v_sqncr", uvm_component parent = null);

endclass
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_v_sqncr::new(string name = "dut_v_sqncr", uvm_component parent = null);
  super.new(name, parent);
endfunction
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
