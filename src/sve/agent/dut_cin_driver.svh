// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_cin_driver #(type t_dut_txn = dut_txn_base) extends dut_driver_base #(t_dut_txn);
    `uvm_component_param_utils (dut_cin_driver #(t_dut_txn))

    extern function new(string name = "dut_cin_driver", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_cin_driver::new(string name = "dut_cin_driver", uvm_component parent=null);
    super.new(name, parent);
endfunction

function void dut_cin_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction

task dut_cin_driver::run_phase(uvm_phase phase);
    forever
        begin
            t_dut_txn txn;
            seq_item_port.try_next_item(txn);  // check whether we have txn to transmitt

            if (null != txn)  // 'sram type' txn
                begin
                    @(posedge dut_vif.clk);
                    #p_tco; // flipflop update gap(to avoid race condition)
                    txn.write(dut_vif);
                    seq_item_port.item_done();
                    dut_vif.cin_txn_valid = 1'b1;
                end
            else
                begin
                    @(posedge dut_vif.clk);
                    #p_tco; // flipflop update gap(to avoid race condition)
                    dut_vif.cin_txn_valid = 1'b0;
                end
        end
endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
