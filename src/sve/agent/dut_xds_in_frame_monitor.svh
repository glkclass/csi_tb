// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_xds_in_frame_monitor #(type t_dut_txn = dutb_txn_base) extends dutb_monitor_base #(t_dut_txn);
    `uvm_component_param_utils (dut_xds_in_frame_monitor #(t_dut_txn))

    extern function new(string name = "dut_xds_in_frame_monitor", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function dut_xds_in_frame_monitor::new(string name = "dut_xds_in_frame_monitor", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_xds_in_frame_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


task dut_xds_in_frame_monitor::run_phase(uvm_phase phase);
    @(posedge dutb_if_h.dutb_vif.rstn)
    forever
        begin
            t_dut_txn txn;
            txn = t_dut_txn::type_id::create("txn");

            do
                begin
                    @(posedge dutb_if_h.dutb_vif.clk)
                    ;
                end
            while (1'b1 != dutb_if_h.dutb_vif.frame_start);

            do
                begin
                    @(posedge dutb_if_h.dutb_vif.clk)
                    txn.read(dutb_if_h.dutb_vif);
                    txn.push();
                end
            while (1'b1 != dutb_if_h.dutb_vif.frame_finish);
            txn.width = dutb_if_h.dutb_vif.width;
            txn.height = dutb_if_h.dutb_vif.height;
            aport.write(txn);
            `uvm_info("MONITOR", {"content\n", txn.convert2string()}, UVM_FULL)
        end
endtask
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
