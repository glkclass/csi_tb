// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_txn_base #(type t_dut_txn = uvm_sequence_item) extends uvm_sequence_item;
    `uvm_object_param_utils (dut_txn_base #(t_dut_txn))

    dut_utils util;
    bit content_valid; // validates transaction content
    string str;
    int i;
    bit ans, empty;

    extern function new (string name = "dut_txn_base");
    extern virtual function void do_copy (uvm_object rhs);  // make a deep copy
    extern virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
    extern virtual function void do_print (uvm_printer printer);  // print transaction content
    extern virtual function string convert2string ();  // represent 'txn content' as string
    extern virtual function string convert2string_pair (uvm_object txn);  // represent 'txn pair content' as string
    extern virtual function vector pack2vector (); // pack 'txn content' to 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //unpack 'txn content' from 'vector of int'
    extern virtual function bit write (virtual dut_if dut_vif);  // write 'txn content' to interface
    extern virtual function bit write_x (virtual dut_if dut_vif);  // write 'x' values to interface
    extern virtual function void read (virtual dut_if dut_vif);  // read 'txn content' from interface
    extern virtual function void push ();  // store 'txn content' to the buffer
    extern virtual function void pop ();  // extract 'txn content' from buffer (if 'fifo txn structure' used)
    extern virtual function int size ();  // size of txn (in int-parrot). Actually size of txn packed to vector of int.
endclass
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function dut_txn_base::new (string name = "dut_txn_base");
    super.new(name);
    util = new();
    empty = 1'b0;
endfunction


// base methods

function void dut_txn_base::do_copy (uvm_object rhs);
    t_dut_txn _txn;

    if(!$cast(_txn, rhs))
        begin
            `uvm_error("TXN_DO_COPY", "Txn cast was failed")
            return;
        end
    super.do_copy(_txn); // chain the copy with parent classes

    unpack4vector (_txn.pack2vector());
endfunction


function bit dut_txn_base::do_compare(uvm_object rhs, uvm_comparer comparer);
    t_dut_txn _txn;
    vector packed_txn[2];
    bit eq;

    // If the cast fails, comparison has also failed
    // A check for null is not needed because that is done in the compare() function which calls do_compare()
    if(!$cast(_txn, rhs))
        begin
            `uvm_error("TXN_DO_COMPARE", "Txn cast was failed")
            return 1'b0;
        end

    if (size() != _txn.size())
        begin
            `uvm_error ( "TXN_DO_COMPARE", $sformatf ( "Txn size mismatch: %0d vs %0d", size(), _txn.size() ) )
            return (1'b0);
        end

    packed_txn[0] = pack2vector();
    packed_txn[1] = _txn.pack2vector();

    ans = super.do_compare (_txn, comparer);
    util.reset_check();
    foreach (packed_txn[0][i])
        begin
            eq = (packed_txn[0][i] == packed_txn[1][i]);
            util.dispaly_check(eq);
            ans = ans & eq;
        end

    return (ans);
endfunction


function void dut_txn_base::do_print (uvm_printer printer);
    super.do_print (printer);
    str = "\n-------------------\n";
    printer.m_string = {get_type_name(), " ",  get_name(), str, convert2string()};
endfunction


function string dut_txn_base::convert2string ();
    return ( util.vec2str( pack2vector() ) );
endfunction


function string dut_txn_base::convert2string_pair (uvm_object txn);
    t_dut_txn _txn;
    if(!$cast(_txn, txn))
        begin
            `uvm_error("TXN_PRINT_PAIR", "Txn cast was failed")
            return "";
        end
    str = {convert2string(), "\n", _txn.convert2string(), "\n", util.check_str};
    return str;
endfunction


function int dut_txn_base::size ();
    vector packed_txn;
    int size_int;

    packed_txn = pack2vector();
    size_int = packed_txn.size();

    return size_int;
endfunction


//  next methods should be overrided
function vector dut_txn_base::pack2vector ();
    `uvm_error("VFNOTOVRDN", "Override 'pack2vector ()' method")
    return ({});
endfunction


function void dut_txn_base::unpack4vector (vector packed_txn);
    `uvm_error("VFNOTOVRDN", "Override 'unpack4vector (vector packed_txn)' method")
endfunction


function bit dut_txn_base::write (virtual dut_if dut_vif);
    `uvm_error("VFNOTOVRDN", "Override 'write (virtual dut_if dut_vif)' method")
endfunction


function bit dut_txn_base::write_x (virtual dut_if dut_vif);
endfunction


function void dut_txn_base::read (virtual dut_if dut_vif);
    `uvm_error("VFNOTOVRDN", "Override 'read (virtual dut_if dut_vif)' method")
endfunction


function void dut_txn_base::push ();
endfunction


function void dut_txn_base::pop ();
    empty = 1'b1;
endfunction
// - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
