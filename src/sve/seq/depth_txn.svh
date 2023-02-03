// input dut control transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class depth_txn extends dut_txn_base #(depth_txn);
    `uvm_object_utils(depth_txn)

    rand logic   [p_depth_bit - 1 : 0]               depth;

    extern function new(string name = "depth_txn");
    extern virtual function vector pack2vector ();  // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    extern virtual function bit write (virtual dut_if dut_vif);  // write 'txn content' to interface
    extern virtual function void read (virtual dut_if dut_vif);  // read 'txn content' from interface

endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function depth_txn::new(string name = "depth_txn");
    super.new(name);
endfunction


function vector depth_txn::pack2vector();
    return {depth};
endfunction


function void depth_txn::unpack4vector(vector packed_txn);
    foreach (packed_txn[i])
        begin
            depth = packed_txn[i];
        end
endfunction


function bit depth_txn::write(virtual dut_if dut_vif);
    dut_vif.depth = depth;
endfunction


function void depth_txn::read(virtual dut_if dut_vif);
    depth = dut_vif.depth;
endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
