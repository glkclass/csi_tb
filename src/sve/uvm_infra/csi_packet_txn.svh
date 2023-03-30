/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   image_txn
    Description     :   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class csi_packet_txn extends dutb_txn_base;
    `uvm_object_utils(csi_packet_txn)

    dut_if_proxy    dut_if;
    virtual ci_if   vif;

    rand int        line_gap, image_gap;                    //  gap between sequential lines and images
    rand t_pixel    image[IMAGE_LINES][IMAGE_LINE_PIXELS];  //  2-D matrix of 14-bit pixel

    constraint      c_line_gap      {line_gap == 1;}
    constraint      c_image_gap     {image_gap == 10;}

    extern function                             new             (string name = "csi_packet_txn");
    extern virtual  function vector             pack2vector     ();                                     // represent 'txn content' as 'vector of int'
    extern virtual  function void               unpack4vector   (vector packed_txn);                    // extract 'txn content' from 'vector of int'
    extern virtual  function void               gold            (dutb_txn_base txn);                    // generate a gold output txn
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
    foo = new[IMAGE_LINES*IMAGE_LINE_PIXELS];
    foreach (image[i, j]) 
        begin
            foo[i*IMAGE_LINE_PIXELS + j] = image[i][j];
        end
    return foo;
endfunction


function void csi_packet_txn::unpack4vector(vector packed_txn);
    `ASSERT (packed_txn.size() == IMAGE_LINES*IMAGE_LINE_PIXELS, 
            $sformatf("Wrong 'packed_txn' size: %0d", packed_txn.size()))    
    
    foreach (image[i, j]) 
        begin
            image[i][j] = packed_txn[i*IMAGE_LINE_PIXELS + j];
        end
endfunction


function void csi_packet_txn::gold(dutb_txn_base txn);
    dutb_txn_base dout_txn;
    $cast(dout_txn, txn.clone());
    `uvm_warning("NOTOVRDN", "Override 'gold' func")
endfunction


// task csi_packet_txn::drive(input dutb_if_proxy_base dutb_if);
// endtask


task csi_packet_txn::monitor(input dutb_if_proxy_base dutb_if);
    `ASSERT_TYPE_CAST(dut_if, dutb_if)
    vif = dut_if.dut_vif.ci_vif;

    wait (vif.rst) #0;   // wait for reset off

    foreach (image[i, j]) 
        begin
            @(posedge vif.clk iff vif.vsync & vif.hsync)
            image[i][j] = vif.data;
        end
endtask
// ****************************************************************************************************************************
