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
import dutb_typedef_pkg::*;
import dutb_util_pkg::*;

module csi_master_protocol_layer (
    ci_if.rx ci,
    fifo_if fifo,
    d_phy_appi_if.protocol appi
    );
// ****************************************************************************************************************************

// ****************************************************************************************************************************
    function void push_vector(byte vec[]);
        foreach (vec[i])
            begin
                fifo.push(vec[i]);
            end
        // `uvm_debug($sformatf("Fifo size after write: %d",fifo.size()))
    endfunction : push_vector
// ****************************************************************************************************************************

// ****************************************************************************************************************************

    byte                                            short_packet[SHORT_PACKET_WIDTH_BYTES];
    byte                                            long_packet_header[LONG_PACKET_HEADER_WIDTH_BYTES];
    byte                                            long_packet_footer[LONG_PACKET_FOOTER_WIDTH_BYTES];
    t_pixel                                         four_pixel_vector[4];
    logic       [3 * BYTE_WIDTH - 1     : 0]        three_byte_vector;
    byte                                            seven_byte_vector [7];
    shortint                                        wc, frame_counter = 1;
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
                appi.BurstSize = (2*SHORT_PACKET_WIDTH_BYTES + IMAGE_LINES*LONG_PACKET_WIDTH_BYTES);
                
                // Generate a strobe to initiate data burst tarnsfer
                @(posedge appi.TxWordClkHS)
                    #0 appi.TxRequestHS = HIGH;
                @(posedge appi.TxWordClkHS)
                    #0 appi.TxRequestHS = LOW;
        end

    always
        begin
            @(posedge ci.vsync);
            `uvm_debug_m("Convert Image data to CSI protocol packets and store to FIFO: started")
            // Push data for single burst to fifo: 'Frame Start' sync Short packet,  'Payload' Long packets(image lines), 'Frame End' sync Short packet

            // Frame start 'sync' Short packet
            data_id = {VIRTUAL_CHANNEL, FRAME_START_DATA_TYPE};
            ecc = byte_xor(0, {data_id, frame_counter>>8, frame_counter});
            short_packet = {data_id, frame_counter, frame_counter>>8, ecc};
            push_vector(short_packet);
            `uvm_debug($sformatf("Frame start sync: %s", byte_vector2str(short_packet)))
            // Frame(image) 'data' Long packets: every Long packet contains single image line
            repeat (IMAGE_LINES)
                begin
                    // Image line 'data' Long packet: header
                    data_id = {VIRTUAL_CHANNEL, PIXEL14BITS_DATA_TYPE};
                    wc = LONG_PACKET_WIDTH_BYTES;
                    ecc = byte_xor(0, {data_id, wc, wc>>8});
                    long_packet_header = {data_id, wc, wc>>8, ecc};
                    push_vector(long_packet_header);
                    check_sum = byte_xor(0, long_packet_header);
                    `uvm_debug($sformatf("Long packet header: %s", byte_vector2str(long_packet_header)))

                    // Image line 'data' Long packet: payload
                    repeat (IMAGE_LINE_PIXELS/4)
                        begin
                            // pack four 14-bit pixels to seven 8-bit bytes according to CSI-2 spec
                            foreach (four_pixel_vector[i]) 
                                begin
                                    @(posedge ci.clk iff ci.hsync) 
                                        four_pixel_vector[i] = ci.data;
                                end  
                            seven_byte_vector = convert_4pixels_to_7bytes(four_pixel_vector);
                            push_vector(seven_byte_vector);                            
                            check_sum = byte_xor(check_sum, seven_byte_vector);
                        end
                    
                    // Image line 'data' Long packet: footer
                    long_packet_footer = {check_sum, check_sum};  // to keep it simple we calculate '8-bit xor' instead '16-bit crc'
                    push_vector(long_packet_footer);
                    `uvm_debug($sformatf("Long packet footer: %s", byte_vector2str(long_packet_footer)))
                end

            // Frame end 'sync' Short package
            data_id = {VIRTUAL_CHANNEL, FRAME_END_DATA_TYPE};
            ecc = byte_xor(0, {data_id, frame_counter, frame_counter>>8});
            short_packet = {data_id, frame_counter, frame_counter>>8, ecc};
            push_vector(short_packet);
            `uvm_debug($sformatf("Frame end sync: %s", byte_vector2str(short_packet)))
            frame_counter++;
            `uvm_debug_m("Convert Image data to CSI protocol packets and store to FIFO: finished")
        end
endmodule
// ****************************************************************************************************************************
