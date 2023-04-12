/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   image_txn
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class csi_packet_txn extends dutb_txn_base;
    `uvm_object_utils(csi_packet_txn)

    dut_if_proxy            dut_if;
    virtual d_phy_appi_if   vif;

    byte            csi_frame_start[SHORT_PACKET_WIDTH_BYTES], csi_frame_finish[SHORT_PACKET_WIDTH_BYTES];
    byte            csi_frame[IMAGE_LINES][LONG_PACKET_WIDTH_BYTES];
    
    // t_pixel    image[IMAGE_LINES][IMAGE_LINE_PIXELS];  //  2-D matrix of 14-bit pixel

    
    extern function                             new             (string name = "csi_packet_txn");
    extern virtual  function vector             pack2vector     ();                                     // represent 'txn content' as 'vector of int'
    extern virtual  function void               unpack4vector   (vector packed_txn);                    // extract 'txn content' from 'vector of int'
    // extern virtual  task                        drive           (input dutb_if_proxy_base dutb_if);     // write 'txn content' to interface
    extern virtual  task                        monitor         (input dutb_if_proxy_base dutb_if);     // read 'txn content' from interface
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function csi_packet_txn::new(string name = "csi_packet_txn");
    super.new(name);
endfunction


function vector csi_packet_txn::pack2vector();
    vector foo;
    foo = new[IMAGE_LINES * LONG_PACKET_WIDTH_BYTES + 2*SHORT_PACKET_WIDTH_BYTES];

    foreach (csi_frame_start[i]) 
        begin
            foo[i] = unsigned'(csi_frame_start[i]);
        end

    foreach (csi_frame_finish[i]) 
        begin
            foo[SHORT_PACKET_WIDTH_BYTES + i] = unsigned'(csi_frame_finish[i]);
        end

    foreach (csi_frame[i, j]) 
        begin
            foo[2*SHORT_PACKET_WIDTH_BYTES + i*LONG_PACKET_WIDTH_BYTES + j] = unsigned'(csi_frame[i][j]);
        end

    return foo;
endfunction


function void csi_packet_txn::unpack4vector(vector packed_txn);
    `ASSERT (packed_txn.size() == (IMAGE_LINES * LONG_PACKET_WIDTH_BYTES + 2*SHORT_PACKET_WIDTH_BYTES), 
            $sformatf("Wrong 'packed_txn' size: %0d", packed_txn.size()))    
    
    foreach (csi_frame_start[i]) 
        begin
            csi_frame_start[i] = byte'(packed_txn[i]);
        end

    foreach (csi_frame_finish[i]) 
        begin
            csi_frame_finish[i] = byte'(packed_txn[SHORT_PACKET_WIDTH_BYTES + i]);
        end

    foreach (csi_frame[i, j]) 
        begin
            csi_frame[i][j] = byte'(packed_txn[2*SHORT_PACKET_WIDTH_BYTES + i*LONG_PACKET_WIDTH_BYTES + j]);
        end
endfunction


// task csi_packet_txn::drive(input dutb_if_proxy_base dutb_if);
// endtask


task csi_packet_txn::monitor(input dutb_if_proxy_base dutb_if);
    `ASSERT_TYPE_CAST(dut_if, dutb_if)
    vif = dut_if.dut_vif.d_phy_appi_vif;

    wait (dut_if.dut_vif.rst) #0;   // wait for reset off

    foreach (csi_frame_start[i]) 
        begin
            @(posedge vif.TxWordClkHS iff vif.TxReadyHS)
            `ASSERT_X(vif.TxDataHS[0])
            csi_frame_start[i] = vif.TxDataHS[0];
        end

    foreach (csi_frame[i, j]) 
        begin
            @(posedge vif.TxWordClkHS iff vif.TxReadyHS)
            `ASSERT_X(vif.TxDataHS[0])
            csi_frame[i][j] = vif.TxDataHS[0];
        end

    foreach (csi_frame_finish[i]) 
        begin
            @(posedge vif.TxWordClkHS iff vif.TxReadyHS)
            `ASSERT_X(vif.TxDataHS[0])
            csi_frame_finish[i] = vif.TxDataHS[0];
        end

    // `uvm_debug_m({"Content monitored:\n", convert2string()})

endtask
// ****************************************************************************************************************************
