// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_cin_driver #(type T_DUT_TXN = dutb_txn_base) extends dutb_driver_base #(T_DUT_TXN);
    `uvm_component_param_utils (dut_cin_driver #(T_DUT_TXN))

    extern function             new(string name = "dut_cin_driver", uvm_component parent=null);
    extern function void        build_phase(uvm_phase phase);
    extern task                 run_phase(uvm_phase phase);
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
            T_DUT_TXN txn;
            seq_item_port.try_next_item(txn);  // check whether we have txn to transmitt

            if (null != txn)  // 'sram type' txn
                begin
                    // @(posedge dut_vif.clk);
                    #p_tco; // flipflop update gap(to avoid race condition)
                    txn.write(dutb_if_h);
                    seq_item_port.item_done();
                    // dut_vif.cin_txn_valid = 1'b1;
                end
            else
                begin
                    // @(posedge dut_vif.clk);
                    #p_tco; // flipflop update gap(to avoid race condition)
                    // dut_vif.cin_txn_valid = 1'b0;
                end
        end
endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
