// ****************************************************************************************************************************
class cin_test_seq extends uvm_sequence #(cin_txn);
    `uvm_object_utils(cin_test_seq)

    uvm_barrier         synch_seq_br_h;

    extern function     new(string name = "cin_test_seq");
    extern task         body();
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function cin_test_seq::new(string name = "cin_test_seq");
    super.new(name);
endfunction


task cin_test_seq::body();
    cin_txn     txn;

    // extract barrier for sequence synchronization
    if (!uvm_config_db #(uvm_barrier)::get(get_sequencer(), "", "synch_seq_barrier", synch_seq_br_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'synch_seq_barrier' from config db")

    repeat (5)
        begin
            txn = cin_txn::type_id::create("txn");

            start_item(txn);
            //  randomize frame size
            assert
                (
                    txn.randomize() with
                        {
                            txn.data inside {[0:7]};
                        }
                );
            `uvm_debug("SEQNCE", $sformatf("'Txn data = %0d", txn.data))
            finish_item (txn);
            // synch_seq_br_h.wait_for();
        end

endtask
// ****************************************************************************************************************************
