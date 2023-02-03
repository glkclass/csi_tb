// output dut data transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class histo_txn extends dut_txn_base #(histo_txn);
    `uvm_object_utils(histo_txn)

    rand logic      [p_depth_bit - 1 : 0]                   histo_th[p_th_num];

    extern function new(string name = "histo_txn");
    extern virtual function vector pack2vector (); // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    extern function void read (virtual dut_if dut_vif); // read 'txn content' from interface
endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function histo_txn::new(string name = "histo_txn");
    super.new(name);
endfunction


function vector histo_txn::pack2vector();
    return {histo_th};
endfunction


function void histo_txn::unpack4vector(vector packed_txn);
    for (i=0; i<p_th_num; i=i+1)
        begin
            histo_th[i] = packed_txn[i];
        end


endfunction


function void histo_txn::read(virtual dut_if dut_vif);
    content_valid = dut_vif.xds_out_valid & dut_vif.xds_out_ready;

    if (1'b1 == content_valid)
        begin
            histo_th    = dut_vif.histo_th;
        end
endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


