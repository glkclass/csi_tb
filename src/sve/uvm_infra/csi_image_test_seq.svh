/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   csi_image_test_seq
    Description     :   Interface   -   
                        Task        -   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class csi_image_test_seq extends uvm_sequence #(csi_image_txn);
    `uvm_object_utils(csi_image_test_seq)

    uvm_barrier         synch_seq_br_h;

    extern function     new(string name = "csi_image_test_seq");
    extern task         body();
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function csi_image_test_seq::new(string name = "csi_image_test_seq");
    super.new(name);
endfunction


task csi_image_test_seq::body();
    csi_image_txn     txn;

    // extract barrier for sequence synchronization
    if (!uvm_config_db #(uvm_barrier)::get(get_sequencer(), "", "synch_seq_barrier", synch_seq_br_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'synch_seq_barrier' from config db")

    repeat (2)
        begin
            // txn = csi_image_txn::type_id::create("txn");
            txn = new();
            start_item(txn);
            assert (txn.randomize());
            `uvm_debug("Txn sent")
            finish_item (txn);
            // synch_seq_br_h.wait_for();
        end

endtask
// ****************************************************************************************************************************
