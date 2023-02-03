// base virtual sequence - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_v_seq #(type t_din_txn = dut_txn_base) extends uvm_virtual_sequence;
    `uvm_object_param_utils(dut_v_seq #(t_din_txn))

    dut_v_sqncr #(t_din_txn)    v_sqncr ;
    uvm_sequencer #(t_din_txn)  din_sqncr_h;

    extern function new(string name = "dut_v_seq");
    extern task body();
endclass
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function dut_v_seq::new(string name = "dut_v_seq");
  super.new(name);
endfunction

task dut_v_seq::body();
    if(!$cast(v_sqncr, get_sequencer()))
        begin
            `uvm_error("CAST_ERROR", "Virtual sequencer pointer cast failed");
        end
    din_sqncr_h =   v_sqncr.din_sqncr_h;
endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
