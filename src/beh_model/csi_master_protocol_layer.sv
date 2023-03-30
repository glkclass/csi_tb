/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Module          :   csi_master_protocol_layer

    Description     :
                        MIPI CSI-2 Protocol Layer.
                        - Recieve image from Camera (vsync, hsync, raw 14-bit pixels),
                        - pack into CSI-2 packets,
                        - push to fifo to be transmitted using D-PHY.
                        Pack every 'four' 14-bit pixels to 'seven' bytes according to CSI-2 spec.
                        Send every Frame as follows:    Sync Frame Start 'short packet'     + 
                                                        Payload 'long packet' (line 0)      +  
                                                        Payload 'long packet' (line 1)      + 
                                                        ...                                 + 
                                                        Payload 'long packet' (line n-1)    + 
                                                        Sync Frame End 'short packet'
******************************************************************************************************************************/


// ****************************************************************************************************************************
import csi_param_pkg::*;

module csi_master_protocol_layer (
    ci_if.rx ci,
    fifo_in_if fifo,
    d_phy_appi_if.protocol appi
    );
// ****************************************************************************************************************************

// ****************************************************************************************************************************
    task push_vector(logic   [7*BYTE_WIDTH - 1  : 0] vec, int n_bytes=7);
        logic   [7*BYTE_WIDTH - 1  : 0] foo;
        foo = vec;
        repeat (n_bytes)
            begin
                fifo.push(foo[BYTE_WIDTH-1 : 0]);
                foo = foo >> BYTE_WIDTH;
            end
    endtask : push_vector

    function byte calc_check_sum(
        byte check_sum,
        logic   [7*BYTE_WIDTH - 1  : 0] vec,
        int n_bytes=7);
        
        logic   [7*BYTE_WIDTH - 1  : 0] foo;
        byte                            bar;

        foo = vec;
        bar = check_sum;
        repeat (n_bytes)
            begin
                bar = bar ^ foo[BYTE_WIDTH-1 : 0];
                foo = foo >> BYTE_WIDTH;
            end
        return bar;
    endfunction : calc_check_sum
// ****************************************************************************************************************************

// ****************************************************************************************************************************
    localparam
        IMAGE_LINE_WIDTH                    =   IMAGE_LINE_PIXELS * IMAGE_PIXEL_WIDTH,
        SHORT_PACKET_WIDTH                  =   4*BYTE_WIDTH,
        LONG_PACKET_WIDTH                   =   4*BYTE_WIDTH + IMAGE_LINE_WIDTH + 2*BYTE_WIDTH,
        LONG_PACKET_WC                      =   LONG_PACKET_WIDTH/BYTE_WIDTH,
        IMAGE_PIXEL_TAIL_WIDTH              =   IMAGE_PIXEL_WIDTH - BYTE_WIDTH;  // 14-bit pixel is split in two parts: 8-bit word and 6-bit tail

    logic   [4*BYTE_WIDTH - 1       : 0]            short_packet;
    logic   [4*BYTE_WIDTH - 1       : 0]            long_packet_header;
    logic   [2*BYTE_WIDTH - 1       : 0]            long_packet_footer;
    logic   [4*BYTE_WIDTH - 1       : 0]            four_byte_vector;
    logic   [3*BYTE_WIDTH - 1       : 0]            three_byte_vector;
    logic   [7*BYTE_WIDTH - 1       : 0]            four_pixel_vector;
    logic   [2*BYTE_WIDTH - 1       : 0]            wc, frame_counter = 1;
    byte                                            data_id, ecc, check_sum;
// ****************************************************************************************************************************


// ****************************************************************************************************************************
    always
        begin
            wait(appi.Enable & appi.Stopstate);
                ci.ready = TRUE;
            wait(~appi.Enable);
                ci.ready = FALSE;
        end

    always
        begin
            @(posedge ci.vsync);
                // Size in fifo words(bytes) of burst to send: 3 Packet headers (1 short packet + 2 packet headers) + payload
                appi.BurstSize = (2*SHORT_PACKET_WIDTH + IMAGE_LINES*LONG_PACKET_WIDTH)/BYTE_WIDTH;
                @(posedge appi.TxWordClkHS)
                    appi.TxRequestHS = HIGH;
                @(posedge appi.TxWordClkHS)
                    appi.TxRequestHS = LOW;
        end

    always
        begin
            @(posedge ci.vsync);
            `uvm_debug("Conversion of Image data to CSI protocol packets: started")
            // Push data for single burst to fifo: 'Frame Start' sync Short packet,  'Payload' Long packets(image lines), 'Frame End' sync Short packet

            // Frame start 'sync' Short packet
            data_id = {VIRTUAL_CHANNEL, FRAME_START_DATA_TYPE};
            ecc = calc_check_sum(0, {frame_counter, data_id}, 3);
            short_packet = {ecc, frame_counter, data_id};
            push_vector(short_packet, 4);
            `uvm_debug($sformatf("Frame start sync: 0x%h", short_packet))
            // Frame(image) 'data' Long packets: every Long packet contains single image line
            repeat (IMAGE_LINES)
                begin
                    // Image line 'data' Long packet: header
                    data_id = {VIRTUAL_CHANNEL, PIXEL14BITS_DATA_TYPE};
                    wc = LONG_PACKET_WC;
                    ecc = calc_check_sum(0, {wc, data_id}, 3);
                    long_packet_header = {ecc, wc, data_id};
                    push_vector(long_packet_header, 4);                    
                    check_sum = calc_check_sum(0, long_packet_header, 4);
                    `uvm_debug($sformatf("Long packet header: 0x%h", long_packet_header))

                    // Image line 'data' Long packet: payload
                    repeat (IMAGE_LINE_PIXELS/4)
                        begin
                            // pack four 14-bit pixels to seven 8-bit bytes according to CSI-2 spec
                            repeat (4)
                                begin
                                    @(posedge ci.clk iff ci.hsync)
                                        // 8-bit bytes
                                        four_byte_vector = four_byte_vector >> CSI_FIFO_DATA_WIDTH;
                                        four_byte_vector[4*CSI_FIFO_DATA_WIDTH - 1 -: CSI_FIFO_DATA_WIDTH] = ci.data[IMAGE_PIXEL_WIDTH - 1 -: CSI_FIFO_DATA_WIDTH];
                                        // 6-bit tails
                                        three_byte_vector = three_byte_vector >> IMAGE_PIXEL_TAIL_WIDTH;
                                        three_byte_vector[3*CSI_FIFO_DATA_WIDTH - 1 -: IMAGE_PIXEL_TAIL_WIDTH] = ci.data[IMAGE_PIXEL_TAIL_WIDTH - 1 -: IMAGE_PIXEL_TAIL_WIDTH];
                                end                            
                            four_pixel_vector = {three_byte_vector, four_byte_vector};
                            push_vector(four_pixel_vector, 7);
                            check_sum = calc_check_sum(check_sum, four_pixel_vector, 7);
                        end
                    
                    // Image line 'data' Long packet: footer
                    long_packet_footer = {check_sum, check_sum};  // to keep it simple we calculate '8-bit xor' instead '16-bit crc'
                    push_vector(long_packet_footer, 2);
                    `uvm_debug($sformatf("Long packet footer: 0x%h", long_packet_footer))
                end

            // Frame end 'sync' Short package
            data_id = {VIRTUAL_CHANNEL, FRAME_END_DATA_TYPE};
            ecc = calc_check_sum(0, {frame_counter, data_id}, 3);
            short_packet = {ecc, frame_counter, {VIRTUAL_CHANNEL, FRAME_END_DATA_TYPE}};
            push_vector(short_packet, 4);
            `uvm_debug($sformatf("Frame end sync: 0x%h", short_packet))
            frame_counter++;
            `uvm_debug("Conversion of image data to CSI protocol packets: finished")
        end
endmodule
// ****************************************************************************************************************************
