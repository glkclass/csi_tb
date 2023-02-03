// dut test point transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_pout_txn extends dut_txn_base #(dut_pout_txn);
    `uvm_object_utils(dut_pout_txn)
    int     stuff [$];

    extern function new(string name = "dut_pout_txn");
    extern virtual function vector pack2vector ();  // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    extern function void read (virtual dut_if dut_vif);  // read 'txn content' from interface
    extern function dut_pout_txn pop_front();  // extract oldest txn
endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_pout_txn dut_pout_txn::pop_front();
    dut_pout_txn txn;
    txn = dut_pout_txn::type_id::create("txn");
    $cast(txn, this.clone());
    // txn.depth[0]         = depth.pop_front();
    // txn.histo[0]         = histo.pop_front();
    return txn;
endfunction


function dut_pout_txn::new(string name = "dut_pout_txn");
    super.new(name);
    stuff = {};
endfunction


function vector dut_pout_txn::pack2vector();
    return stuff;
endfunction


function void dut_pout_txn::unpack4vector(vector packed_txn);
    foreach (packed_txn[i])
        begin
            stuff[i] = packed_txn[i];
        end
endfunction


function void dut_pout_txn::read(virtual dut_if dut_vif);
    content_valid = dut_vif.probe_valid;

    if (dut_vif.image_depth_valid)
        begin
            for (int i=0; i<256; i++)
                begin
                    stuff.push_back(dut_vif.image_depth[i]);
                end
        end

    if (dut_vif.histo_valid)
        begin
            for (int i=0; i<p_histo_size; i++)
                begin
                    stuff.push_back(dut_vif.histo[i]);
                end
            `uvm_info("dut_pout_txn", "push histo", UVM_HIGH)
        end

endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
