/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   cin_txn
    Description     :   Interface   -   
                        Task        -   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class cin_txn extends dutb_txn_base;
    `uvm_object_utils(cin_txn)

    dut_if_proxy                                dut_if;

    rand logic   [P_CIN_DATA_WIDTH - 1 : 0]     data;
    logic                                       valid;
    
    extern function                             new(string name = "cin_txn");
    extern virtual function vector              pack2vector ();                                 // represent 'txn content' as 'vector of int'
    extern virtual function void                unpack4vector (vector packed_txn);              // extract 'txn content' from 'vector of int'
    extern virtual task                         drive (input dutb_if_proxy_base dutb_if);       // write 'txn content' to interface
    extern virtual task                         monitor (input dutb_if_proxy_base dutb_if);     // read 'txn content' from interface
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function cin_txn::new(string name = "cin_txn");
    super.new(name);
endfunction


function vector cin_txn::pack2vector();
    return {data};
endfunction


function void cin_txn::unpack4vector(vector packed_txn);
    data = packed_txn[0];
endfunction


task cin_txn::drive(input dutb_if_proxy_base dutb_if);
    if(!$cast(dut_if, dutb_if))
        `uvm_fatal("TXNTPYERR", "Txn cast was failed")

    @(posedge dut_if.dut_vif.clk)
    #0
    dut_if.dut_vif.data = data;
    dut_if.dut_vif.valid = 1'b1;
    `uvm_debug("TXNWRTN", convert2string())

    @(posedge dut_if.dut_vif.clk)
    #0
    dut_if.dut_vif.data = 4'hX;
    dut_if.dut_vif.valid = 1'b0;
endtask


task cin_txn::monitor(input dutb_if_proxy_base dutb_if);
    // `uvm_debug("TXNTYP", $sformatf("%s", get_type_name()))

    if (!$cast(dut_if, dutb_if))
        `uvm_fatal("TXNTPYERR", "Txn cast was failed")
    
    wait(dut_if.dut_vif.rst_n);  // wait for reset off
    do
        begin
            @(posedge dut_if.dut_vif.clk)
            data = dut_if.dut_vif.data;            
        end
    while (1'b1 !== dut_if.dut_vif.valid);
    `uvm_debug("TXNREAD", convert2string())
    // print();
endtask
// ****************************************************************************************************************************
