// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class depth_frame_seq extends uvm_sequence #(depth_frame_txn);
    `uvm_object_utils(depth_frame_seq)

    uvm_barrier                 synch_seq_br_h;
    rand int unsigned           width, height;

    extern function new(string name = "depth_frame_seq");
    extern task body();
endclass
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function depth_frame_seq::new(string name = "depth_frame_seq");
    super.new(name);
endfunction


task depth_frame_seq::body();
    int cnt = 0;
    depth_frame_txn     txn;

    // extract barrier for sequence synchronization
    if (!uvm_config_db #(uvm_barrier)::get(get_sequencer(), "", "synch_seq_barrier", synch_seq_br_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'synch_seq_barrier' from config db")

    repeat (5)
        begin
            txn = depth_frame_txn::type_id::create("txn");

            start_item(txn);
            //  randomize frame size
            assert
                (
                    txn.randomize() with
                        {
                            txn.width inside {[16:16]};
                            txn.height inside {[16:16]};
                        }
                );
            `uvm_info("SEQNCE", $sformatf("'Single pic scenario #%0d' width/height = %0d/%0d", cnt, txn.width, txn.height), UVM_HIGH)
            for (int i=0; i<txn.width*txn.height; i++)
                begin
                    //  randomize depth
                    assert
                        (
                            txn.depth_h.randomize() with
                                {
                                    txn.depth_h.depth inside {[0:255]};
                                }
                        );

                    txn.depth_frame.push_back(txn.depth_h.depth);
                end
            finish_item (txn);

            #p_tco
            // synch_seq_br_h.wait_for();
            cnt++;
        end

endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
