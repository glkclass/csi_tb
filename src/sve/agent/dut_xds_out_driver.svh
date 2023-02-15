// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_xds_out_driver #(type t_dut_txn = dutb_txn_base) extends dutb_driver_base #(t_dut_txn);
    `uvm_component_param_utils (dut_xds_out_driver #(t_dut_txn))

    extern function new(string name = "dut_xds_out_driver", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_xds_out_driver::new(string name = "dut_xds_out_driver", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_xds_out_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


task dut_xds_out_driver::run_phase(uvm_phase phase);
    bit xds_out_ready;
    @ (posedge dutb_if_h.dutb_vif.rstn);
    forever
        begin
            @(posedge dutb_if_h.dutb_vif.clk);
            #p_tco; // flipflop update gap (to avoid race condition)
            xds_out_ready = std::randomize(xds_out_ready) with { xds_out_ready dist {1'b1:= p_xds_dist, 1'b0:= 100-p_xds_dist}; };
            dutb_if_h.dutb_vif.xds_out_ready = xds_out_ready;
        end
endtask
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





