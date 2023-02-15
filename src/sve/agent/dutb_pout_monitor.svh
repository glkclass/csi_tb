class dutb_pout_monitor #(type t_dut_txn = dutb_txn_base) extends dutb_monitor_base #(t_dut_txn);
    `uvm_component_param_utils (dutb_pout_monitor #(t_dut_txn))

    extern function new(string name = "dutb_pout_monitor", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);

endclass


function dutb_pout_monitor::new(string name = "dutb_pout_monitor", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dutb_pout_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


task dutb_pout_monitor::run_phase(uvm_phase phase);
    t_dut_txn txn_ppln;
    @(posedge dutb_if_h.dutb_vif.rstn)
    txn_ppln = t_dut_txn::type_id::create("txn_ppln");
    forever
        begin
            t_dut_txn txn;
            do
                begin
                    @(posedge dutb_if_h.dutb_vif.clk)
                    txn_ppln.read(dutb_if_h);
                end
            while (1'b1 != txn_ppln.content_valid);
            txn = txn_ppln.pop_front();
            aport.write(txn);
            `uvm_info("dutb_pout_monitor: content", {"\n", txn.convert2string()}, UVM_HIGH)
        end
endtask
