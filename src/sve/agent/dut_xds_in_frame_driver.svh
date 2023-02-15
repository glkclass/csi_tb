// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_xds_in_frame_driver #(type t_dut_txn = dutb_txn_base) extends dut_xds_in_driver #(t_dut_txn);
    `uvm_component_param_utils (dut_xds_in_frame_driver #(t_dut_txn))

    extern function new(string name = "dut_xds_in_frame_driver", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_xds_in_frame_driver::new(string name = "dut_xds_in_frame_driver", uvm_component parent=null);
    super.new(name, parent);
endfunction

function void dut_xds_in_frame_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


task dut_xds_in_frame_driver::run_phase(uvm_phase phase);
    forever
        begin
            t_dut_txn txn;
            seq_item_port.get_next_item(txn);  // check whether we have txn to transmitt

            @(posedge dutb_if_h.dutb_vif.clk);
            #p_tco; // flipflop update gap (to avoid race condition)

            `uvm_info("DRIVER", {"start txn\n", txn.convert2string()}, UVM_FULL)
            txn.frame_start(dutb_if_h.dutb_vif);
            do
                begin
                    @(posedge dutb_if_h.dutb_vif.clk);
                    #p_tco; // flipflop update gap (to avoid race condition)
                end
            while (xds_write(txn, dutb_if_h.dutb_vif));  // till txn content isn't over
            txn.frame_finish(dutb_if_h.dutb_vif);
            `uvm_info("DRIVER", {"finish txn\n", txn.convert2string()}, UVM_FULL)
            seq_item_port.item_done();
            //progress_bar_h.display();
        end
endtask
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
