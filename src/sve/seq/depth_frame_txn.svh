// input dut control transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class depth_frame_txn extends dut_txn_base #(depth_frame_txn);
    `uvm_object_utils(depth_frame_txn)

            logic   [p_depth_bit - 1 : 0]               depth_frame[$];
    rand    logic   [p_width_bit-1 : 0]                 width;
    rand    logic   [p_height_bit-1 : 0]                height;

            depth_txn                                   depth_h;  // temp var

    extern function new(string name = "depth_frame_txn");
    extern virtual function vector pack2vector ();  // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    extern virtual function bit write (virtual dut_if dut_vif);  // write 'txn content' to interface
    extern virtual function void read (virtual dut_if dut_vif);  // read 'txn content' from interface
    extern virtual function void push ();  // store 'txn content' to the buffer
    extern virtual function void pop ();  // extract 'txn content' from buffer
    extern virtual function void frame_start (virtual dut_if dut_vif);  // write tile start signals
    extern virtual function void frame_finish (virtual dut_if dut_vif);  // write tile finish signals

endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function depth_frame_txn::new(string name = "depth_frame_txn");
    super.new(name);
    depth_frame = {};
    depth_h = depth_txn::type_id::create("depth_h");
endfunction


function vector depth_frame_txn::pack2vector();
    return {width, height, depth_frame};
endfunction


function void depth_frame_txn::unpack4vector(vector packed_txn);
    foreach (packed_txn[i])
        begin
            if (0 == i)
                begin
                    width = packed_txn[i];
                end
            else if (1 == i)
                begin
                    height = packed_txn[i];
                end
            else
                begin
                    depth_frame.push_back( packed_txn[i]);
                end
        end
endfunction


function bit depth_frame_txn::write(virtual dut_if dut_vif);
    dut_vif.depth = depth_h.depth;
endfunction


function void depth_frame_txn::read(virtual dut_if dut_vif);
    content_valid = (dut_vif.xds_in_valid & dut_vif.xds_in_ready);
    if (1'b1 == content_valid)
        begin
            depth_h.depth = dut_vif.depth;
        end
endfunction


function void depth_frame_txn::push();
    if (content_valid)
        begin
            depth_frame.push_back(depth_h.depth);
        end
endfunction


function void depth_frame_txn::pop();
    if (!empty)
        begin
            depth_h.depth   =   depth_frame.pop_front();
        end
    else
        begin
            `uvm_error("depth_frame_txn", "Empty txn buffer!!!")
        end
    empty   =   ( 0 == depth_frame.size() ) ? 1'b1 : 1'b0;
endfunction


function void depth_frame_txn::frame_start(virtual dut_if dut_vif);
    dut_vif.width = width;
    dut_vif.height = height;
    dut_vif.frame_start = 1'b1;
    dut_vif.frame_finish = 1'b0;
endfunction


function void depth_frame_txn::frame_finish(virtual dut_if dut_vif);
    dut_vif.frame_finish = 1'b1;
    dut_vif.frame_start = 1'b0;
endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
