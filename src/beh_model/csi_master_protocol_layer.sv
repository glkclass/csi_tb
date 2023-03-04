/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Module          :   csi_master_protocol_layer

    Description     :
                        MIPI CSI-2 Protocol Layer.
                        - Recieve image from Camera (Vsync, Hsync, raw 14-bit pixels),
                        - pack into CSI-2 packets,
                        - push to fifo to be transmitted using D-PHY.
                        Pack every four 14-bit pixels to 7 bytes according to CSI-2 spec.
                        Send every Frame as follows: Sync Start short packet + Payload long packet (all frame pixels) + Sync End short packet
******************************************************************************************************************************/


// ****************************************************************************************************************************
import csi_param_pkg::*;

module csi_master_protocol_layer (
    interface ci,
    interface csi_fifo,
    d_phy_appi_if.protocol appi
    );
    localparam
        IMAGE_PIXEL_TAIL_WIDTH              = IMAGE_PIXEL_WIDTH - CSI_FIFO_DATA_WIDTH;  // 14-bit pixel is split in two parts: 8-bit word and 6-bit tail


    logic   [FRAME_COUNTER_WIDTH - 1    : 0]      frame_counter = 1;
    logic   [FRAME_HEADER_WIDTH - 1     : 0]      frame_header;
    logic   [4*CSI_FIFO_DATA_WIDTH - 1  : 0]      four_byte_vector;
    logic   [3*CSI_FIFO_DATA_WIDTH - 1  : 0]      three_byte_vector;
    logic   [7*CSI_FIFO_DATA_WIDTH - 1  : 0]      four_pixel_vector;

    task push_vector(logic   [7*CSI_FIFO_DATA_WIDTH - 1  : 0] vec, int n_bytes=7);
        logic   [7*CSI_FIFO_DATA_WIDTH - 1  : 0] foo;
        foo = vec;
        repeat (n_bytes)
            begin
                csi_fifo.push(foo[CSI_FIFO_DATA_WIDTH-1 : 0]);
                foo = foo >> CSI_FIFO_DATA_WIDTH;
            end
    endtask : push_vector

    always
        begin
            wait(appi.Enable & appi.Stopstate);
                ci.Enable = TRUE;
            wait(~appi.Enable);
                ci.Enable = FALSE;
        end

    always
        begin
            @(posedge ci.VSync);
                // Size in fifo words(bytes) of burst to send: 3 Packet headers (1 short packet + 2 packet headers) + payload
                appi.BurstSize = 3*(FRAME_HEADER_WIDTH/CSI_FIFO_DATA_WIDTH) + IMAGE_LINES*(IMAGE_LINE_PIXELS/4)*7;
                @(posedge appi.TxWordClkHS)
                    appi.TxRequestHS = HIGH;
                @(posedge appi.TxWordClkHS)
                    appi.TxRequestHS = LOW;
        end


    always
        begin
            @(posedge ci.VSync);
            // Push data for single burst to fifo: 'Frame Start' short packet,  'Header + Frame Data' Long packet, 'Frame End' short packet

            // Frame start sync short packet
            frame_header = {ECC, frame_counter, {VIRTUAL_CHANNEL, FRAME_START_DATA_TYPE}};
            push_vector(frame_header, 4);
            // log_debug($sformatf("Push header: 0x%8H, FIFO size = %0d", frame_header, csi_fifo.size()), TRUE);


            // Frame Data long packet: header
            frame_header = {ECC, IMAGE_LINES*(IMAGE_LINE_PIXELS/4)*7, VIRTUAL_CHANNEL, PIXEL14BITS_DATA_TYPE};
            push_vector(frame_header, 4);
            // log_debug($sformatf("Push header: 0x%8H, FIFO size = %0d", frame_header, csi_fifo.size()), TRUE);

            // Frame Data long packet: payload (image pixels)
            repeat (IMAGE_LINES*(IMAGE_LINE_PIXELS/4))
                begin
                    repeat (4)
                        begin
                            @(posedge ci.Clk iff ci.HSync)
                                four_byte_vector = four_byte_vector >> CSI_FIFO_DATA_WIDTH;
                                three_byte_vector = three_byte_vector >> IMAGE_PIXEL_TAIL_WIDTH;
                                four_byte_vector[4*CSI_FIFO_DATA_WIDTH - 1 -: CSI_FIFO_DATA_WIDTH] = ci.Data[IMAGE_PIXEL_WIDTH - 1 -: CSI_FIFO_DATA_WIDTH];
                                three_byte_vector[3*CSI_FIFO_DATA_WIDTH - 1 -: IMAGE_PIXEL_TAIL_WIDTH] = ci.Data[IMAGE_PIXEL_TAIL_WIDTH - 1 -: IMAGE_PIXEL_TAIL_WIDTH];
                        end
                    four_pixel_vector = {four_byte_vector, three_byte_vector};
                    push_vector(four_pixel_vector, 7);
                end

            // Frame end sync short package
            @(negedge ci.VSync);
            frame_header = {ECC, frame_counter, {VIRTUAL_CHANNEL, FRAME_END_DATA_TYPE}};
            push_vector(frame_header, 4);
            // log_debug($sformatf("Push header: 0x%8H, FIFO size = %0d", frame_header, csi_fifo.size()), TRUE);
        end
endmodule
// ****************************************************************************************************************************
