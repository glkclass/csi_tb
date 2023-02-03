module dut_wrp
(
    interface _if
);

    import dut_param_pkg::*;


    // DEPTH SRAM if
    logic                                                       image_sram_wen;
    logic           [p_depth_sram_a_bit-1 : 0]                  image_sram_a;
    logic           [p_depth_sram_d_bit-1 : 0]                  image_sram_d;
    logic           [p_depth_sram_d_bit-1 : 0]                  image_sram_q;

    // HISTO SRAM if
    logic                                                       histo_sram_wen;
    logic           [p_histo_sram_a_bit-1 : 0]                  histo_sram_a;
    logic           [p_histo_sram_d_bit-1 : 0]                  histo_sram_d;
    logic           [p_histo_sram_d_bit-1 : 0]                  histo_sram_q;

    logic           [p_th_num*p_depth_bit-1 : 0]                histo_th;

    // DEPTHHISTOGRAM
    //     #(
    //         .p_depth_bit                        ( p_depth_bit )
    //     )
    // DUT
    //     (
    //         .i_CLK                              ( _if.clk ),
    //         .i_RSTn                             ( _if.rstn ),

    //         .i_WIDTH                            (_if.width),
    //         .i_HEIGHT                           (_if.height),
    //         .i_FRAME_START                      ( _if.frame_start ),
    //         .i_FRAME_FINISH                     ( _if.frame_finish ),

    //         .i_DEPTH_XDS_IN_VALID               ( _if.xds_in_valid ),
    //         .o_DEPTH_XDS_IN_READY               ( _if.xds_in_ready ),
    //         .i_DEPTH                            ( _if.depth),

    //         .o_XDS_OUT_VALID                    ( _if.xds_out_valid ),
    //         .i_XDS_OUT_READY                    ( _if.xds_out_ready ),
    //         .o_HISTO_TH                         ( histo_th),

    //         .o_HISTO_SRAM_WEN                   ( histo_sram_wen ),
    //         .o_HISTO_SRAM_A                     ( histo_sram_a ),
    //         .o_HISTO_SRAM_D                     ( histo_sram_d ),
    //         .i_HISTO_SRAM_Q                     ( histo_sram_q ),

    //         .o_DEPTH_SRAM_WEN                   ( image_sram_wen ),
    //         .o_DEPTH_SRAM_A                     ( image_sram_a ),
    //         .o_DEPTH_SRAM_D                     ( image_sram_d ),
    //         .i_DEPTH_SRAM_Q                     ( image_sram_q )
    //     );

    SRAM
        #(
            .p_addr_bit             ( p_depth_sram_a_bit ),
            .p_data_bit             ( p_depth_sram_d_bit )
        )
    DEPTH
        (
            .CLK                    ( _if.clk ),
            .CEN                    ( 1'b0 ),  //always enabled
            .WEN                    ( image_sram_wen ),
            .A                      ( image_sram_a ),
            .D                      ( image_sram_d ),
            .Q                      ( image_sram_q)
        );

    SRAM
        #(
            .p_addr_bit             ( p_histo_sram_a_bit ),
            .p_data_bit             ( p_histo_sram_d_bit )
        )
    HISTO
        (
            .CLK                    ( _if.clk ),
            .CEN                    ( 1'b0 ),  //always enabled
            .WEN                    ( histo_sram_wen ),
            .A                      ( histo_sram_a ),
            .D                      ( histo_sram_d ),
            .Q                      ( histo_sram_q )
        );



    // assign _if.probe_valid              =   (DUT.DONE == DUT.state) ? 1'b1 : 1'b0;

    // assign _if.image_depth_valid        =   (DUT.HISTO_LPF_PRE == DUT.state) ? 1'b1 : 1'b0;

    // wire histo_valid                    =   (DUT.HISTO_LPF_PRE == DUT.state) ? 1'b1 : 1'b0;

    // assign _if.histo_valid              =   DUT.w_lpf_post_finish | histo_valid;

genvar ii;
generate
    for (ii=0; ii<p_depth_size; ii=ii+1)
        begin
            assign  _if.image_depth[ii]  =   DEPTH.r_MEM[ii];
        end

    for (ii=0; ii<p_histo_size; ii=ii+1)
        begin
            assign  _if.histo[ii]  =   HISTO.r_MEM[ii];
        end

endgenerate


generate
    for (ii=0; ii<p_th_num; ii=ii+1)
        begin
            assign  _if.histo_th[ii]  =   histo_th[(ii+1)*p_depth_bit-1 : ii*p_depth_bit];
        end
endgenerate





endmodule
