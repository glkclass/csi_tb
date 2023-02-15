// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_xds_in_driver #(type t_dut_txn = dutb_txn_base) extends dutb_driver_base #(t_dut_txn);
    `uvm_component_param_utils (dut_xds_in_driver #(t_dut_txn))

    extern function new(string name = "dut_xds_in_driver", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    extern function bit xds_write(t_dut_txn txn, virtual dutb_if dutb_vif);

endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_xds_in_driver::new(string name = "dut_xds_in_driver", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_xds_in_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction


function bit dut_xds_in_driver::xds_write(t_dut_txn txn, virtual dutb_if dutb_vif);
    bit xds_valid, foo;
    static bit tx_active = 1'b0;

    xds_valid = std::randomize(xds_valid) with { xds_valid dist {1'b1:= p_xds_dist, 1'b0:= 100-p_xds_dist}; };

    if ( dutb_vif.xds_in_valid )  // there was a data waitng for recieve acknowledgement
        begin
            if ( dutb_vif.xds_in_ready )  // ack recieved -> transmit just took place
                begin
                    if ( txn.empty )  // we have no more data to transmitt
                        begin
                            tx_active = 1'b0;
                            dutb_vif.xds_in_valid = 1'b0;
                            foo = txn.write_x(dutb_vif);
                        end
                    else  // we have data to transmitt
                        begin
                            txn.pop();  // get next data portion
                            tx_active = 1'b1;
                            dutb_vif.xds_in_valid = xds_valid;  // random valid: 1 - tx request, 0 - no tx
                            // write data to tx channel : fill tx channel by 'x' or leave 'old' values (depending on txn.write_x() method impl)
                            foo = (dutb_vif.xds_in_valid) ?  txn.write(dutb_vif) : txn.write_x(dutb_vif);  //
                        end
                end
            else  // no ack -> transmitt wasn't finished
                begin
                    tx_active = 1'b1;
                    dutb_vif.xds_in_valid = xds_valid;  // random valid: 1 - continue tx, 0 - interrupt tx
                    // write data to tx channel : fill tx channel by 'x' or leave 'old' values (depending on txn.write_x() method impl)
                    foo = (dutb_vif.xds_in_valid) ?  txn.write(dutb_vif) : txn.write_x(dutb_vif);  //
                end
        end
    else  // there was no data waiting for ack
        begin
            if (tx_active)  // there is a data waiting for tx
                begin
                    tx_active = 1'b1;
                    dutb_vif.xds_in_valid = xds_valid;  // random valid: 1 - tx request, 0 - no tx
                    // write data to tx channel : fill tx channel by 'x' or leave 'old' values (depending on txn.write_x() method impl)
                    foo = (dutb_vif.xds_in_valid) ?  txn.write(dutb_vif) : txn.write_x(dutb_vif);  //
                end
            else  // there is no data waiting for tx (seems first function call)
                begin
                    if ( txn.empty )  // we have no more data to transmitt
                        begin
                            tx_active = 1'b0;
                            dutb_vif.xds_in_valid = 1'b0;
                            foo = txn.write_x(dutb_vif);
                        end
                    else  // we have data to transmitt
                        begin
                            txn.pop();  // get next data portion
                            tx_active = 1'b1;
                            dutb_vif.xds_in_valid = xds_valid;  // random valid
                            // write data to tx channel : fill tx channel by 'x' or leave 'old' values (depending on txn.write_x() method impl)
                            foo = (dutb_vif.xds_in_valid) ?  txn.write(dutb_vif) : txn.write_x(dutb_vif);  //
                        end
                end
        end
    return tx_active;
endfunction


task dut_xds_in_driver::run_phase(uvm_phase phase);
    forever
        begin
            t_dut_txn txn;
            seq_item_port.get_next_item(txn);  // check whether we have txn to transmitt
            do
                begin
                    @(posedge dutb_if_h.dutb_vif.clk);
                    #p_tco; // flipflop update gap (to avoid race condition)
                end
            while (xds_write(txn, dutb_if_h.dutb_vif));  // till txn content isn't over

            seq_item_port.item_done();
            //progress_bar_h.display();
            //`uvm_info("DRIVER CONTENT", txn.convert2string(), UVM_HIGH)
        end
endtask
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





