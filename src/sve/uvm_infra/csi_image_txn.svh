/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021

    Class           :   csi_image_cg
    Description     :   A wrapper class containing a covergroup, has a static nature (only a single instance is created).
                        Collect coverage for all the istances of given txn.
                        Should be used as wrapper for covergroup since covergroup itself doesn't support static reference
                        (covergroup variable inside class is 'garbage collected' after class instance is 'garbage collected' 
                        even if it's declared as 'static')

    Class           :   csi_image_txn
    Description     :   Image Txn: 2-D image, every pixel has 14 bits, number and size of lines are defined as parameters.
                        A gap between lines and images, image pixels are randomized.
                        A monitor expects a correct 'vsync, hsync, Pixel' protocol and doesn't perform any checks. 
                        A correctness should be checked using SVA inside the If.
******************************************************************************************************************************/


// ****************************************************************************************************************************
typedef class csi_image_txn;
class csi_image_cg extends uvm_object;
    `uvm_object_utils(csi_image_cg)

    // coverage map
    map_flt                                 cov_result;
    
    covergroup cg (string name) with function sample(csi_image_txn txn);
        option.per_instance = 1;
        option.name = name;

        cover_line_gap:      coverpoint txn.line_gap
            {
                bins values[] = {1, 2, 3};
            }

        cover_image_gap:      coverpoint txn.image_gap
            {
                bins values[] = {9, [10:12]};
            }
    endgroup

    
    function new(string name = "cg_name");
        cg = new(name);
        `uvm_debug({"'", name, "'", " covergroup was created"})
    endfunction

    
    function void analyze_coverage_results();
        cov_result["line_gap"]      =   cg.cover_line_gap.get_inst_coverage();
        cov_result["image_gap"]     =   cg.cover_image_gap.get_inst_coverage();
        cov_result["total"]         =   cg.get_inst_coverage();

        `uvm_info("COVERAGE", {"\n", map_flt_display(this.cov_result)}, UVM_HIGH)

        // progress_bar_h.display();
        // if (34 == progress_bar_h.cnt)
        //     begin
        //         dut_handler_h.stop_test("FCC target achieved");  // finish current test
        //     end
    endfunction
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
import dutb_util_pkg::byte_xor;
import csi_typedef_pkg::convert_4pixels_to_7bytes;

class csi_image_txn extends dutb_txn_base;
    `uvm_object_utils(csi_image_txn)

    // create single instance of class containing covergroup fopr this txn type
    static csi_image_cg         cover_wrp = new("cover_csi_image");
    
    dut_if_proxy                dut_if;
    virtual ci_if               vif;
    
    static  shortint            image_counter = 0;

    rand    int                 line_gap, image_gap;                    //  gap between sequential lines and images
    rand    t_pixel             image[IMAGE_LINES][IMAGE_LINE_PIXELS];  //  2-D matrix of 14-bit pixels

    constraint              c_line_gap      {line_gap inside {1, 2, 3};}
    constraint              c_image_gap     {image_gap inside {[10:12]};}
    
    extern function                             new                     (string name = "csi_image_txn");
    extern virtual  function void               sample_coverage         ();                                     // sample covergroups
    extern virtual  function void               analyze_coverage_results();                                     // store coverage data (to hashmap), report results
    extern virtual  function vector             pack2vector             ();                                     // represent 'txn content' as 'vector of int'
    extern virtual  function void               unpack4vector           (vector packed_txn);                    // extract 'txn content' from 'vector of int'
    extern virtual  function dutb_txn_base      gold                    ();                                     // generate a gold output txn
    extern virtual  task                        drive                   (input dutb_if_proxy_base dutb_if);     // write 'txn content' to interface
    extern virtual  task                        monitor                 (input dutb_if_proxy_base dutb_if);     // read 'txn content' from interface
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function csi_image_txn::new(string name = "csi_image_txn");
    super.new(name);
    // create single instance of class containing covergroup
    // if (null == cover_wrp)
    //     begin
    //         this.cover_wrp = new("cover_csi_image");
    //     end
endfunction


function void csi_image_txn::sample_coverage();
    cover_wrp.cg.sample (this);
endfunction


function void csi_image_txn::analyze_coverage_results();
    cover_wrp.analyze_coverage_results ();
endfunction


function vector csi_image_txn::pack2vector();
    vector foo;
    foo = new[IMAGE_LINES*IMAGE_LINE_PIXELS];
    foreach (image[i, j]) 
        begin
            foo[i*IMAGE_LINE_PIXELS + j] = image[i][j];
        end
    return foo;
endfunction


function void csi_image_txn::unpack4vector(vector packed_txn);
    `ASSERT (packed_txn.size() == IMAGE_LINES*IMAGE_LINE_PIXELS, 
            $sformatf("Wrong 'packed_txn' size: %0d", packed_txn.size()))    
    
    foreach (image[i, j]) 
        begin
            image[i][j] = packed_txn[i*IMAGE_LINE_PIXELS + j];
        end
endfunction

typedef csi_packet_txn;
function dutb_txn_base csi_image_txn::gold();
    csi_packet_txn      dout_txn;
    byte                data_id, ecc, check_sum;
    
    byte                                                short_packet[SHORT_PACKET_WIDTH_BYTES];
    byte                                                long_packet_header[LONG_PACKET_HEADER_WIDTH_BYTES];
    byte                                                long_packet_footer[LONG_PACKET_FOOTER_WIDTH_BYTES];
    t_pixel                                             four_pixel_vector [4];
    byte                                                seven_byte_vector [7];
    shortint                                            wc;

    dout_txn = new();

    data_id = {VIRTUAL_CHANNEL, FRAME_START_DATA_TYPE};
    ecc = byte_xor(0, {data_id, image_counter, image_counter>>8});
    short_packet = {data_id, image_counter, image_counter>>8, ecc};
    dout_txn.csi_frame_start = short_packet;
    
    data_id = {VIRTUAL_CHANNEL, FRAME_END_DATA_TYPE};
    ecc = byte_xor(0, {data_id, image_counter, image_counter>>8});
    short_packet = {data_id, image_counter, image_counter>>8, ecc};
    dout_txn.csi_frame_finish = short_packet;
    
    foreach (image[i]) 
        begin
            data_id = {VIRTUAL_CHANNEL, PIXEL14BITS_DATA_TYPE};
            wc = LONG_PACKET_WIDTH_BYTES;
            ecc = byte_xor(0, {data_id, wc, wc>>8});
            long_packet_header = {data_id, wc, wc>>8, ecc};
            check_sum = byte_xor(0, long_packet_header);
            dout_txn.csi_frame[i][0 : LONG_PACKET_HEADER_WIDTH_BYTES - 1] = long_packet_header;

            // loop on every 4 pixels, convert to 7 bytes and store to 'data area' of the packet
            for (int j = 0; j < IMAGE_LINE_PIXELS; j+=4) 
                begin
                    four_pixel_vector = {image[i][j], image[i][j+1], image[i][j+2], image[i][j+3]};
                    seven_byte_vector = convert_4pixels_to_7bytes(four_pixel_vector);
                    check_sum = byte_xor(check_sum, seven_byte_vector);
                    for (int k = 0; k < 7; k++) 
                        begin
                            dout_txn.csi_frame[i][LONG_PACKET_HEADER_WIDTH_BYTES + (j/4)*7 + k] = seven_byte_vector[k];
                        end
                end
            long_packet_footer = {check_sum, check_sum};
            dout_txn.csi_frame[i][LONG_PACKET_HEADER_WIDTH_BYTES + (IMAGE_LINE_PIXELS/4)*7]     = long_packet_footer[0];
            dout_txn.csi_frame[i][LONG_PACKET_HEADER_WIDTH_BYTES + (IMAGE_LINE_PIXELS/4)*7 + 1] = long_packet_footer[1];
        end
    return dout_txn;
endfunction


task csi_image_txn::drive(input dutb_if_proxy_base dutb_if);
    `ASSERT_TYPE_CAST(dut_if, dutb_if)
    vif = dut_if.dut_vif.ci_vif;

    wait (vif.rst);   // wait for reset off
    wait (dut_if.dut_vif.d_phy_appi_vif.Stopstate);   // wait for Lane is ready (Stopstate == HIGH)

    repeat(image_gap)
        @(posedge vif.clk) #0;

    vif.vsync = HIGH;
    foreach (image[i]) 
        begin
            vif.hsync = HIGH;
            foreach (image[i][j]) 
                begin
                    // `uvm_debug("TXNDBG", $sformatf("%d %d", i, j));
                    vif.data = image[i][j];
                    @(posedge vif.clk) #0;
                end
            vif.hsync = LOW;
            vif.data = {IMAGE_PIXEL_WIDTH{X}};                
            if ((IMAGE_LINES - 1) != i)  // no gap after last line
                repeat(line_gap)
                    @(posedge vif.clk) #0;
        end
    vif.vsync = LOW;
endtask


task csi_image_txn::monitor(input dutb_if_proxy_base dutb_if);
    `ASSERT_TYPE_CAST(dut_if, dutb_if)
    vif = dut_if.dut_vif.ci_vif;

    wait (vif.rst) #0;   // wait for reset off

    foreach (image[i, j]) 
        begin
            @(posedge vif.clk iff vif.vsync & vif.hsync)
            image[i][j] = vif.data;
        end
    image_counter++;

    // to debug fcc
    line_gap = 1;
    image_gap = 2;
endtask
// ****************************************************************************************************************************