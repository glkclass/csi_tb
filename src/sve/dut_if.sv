interface dut_if
(
    input clk, rstn
);
    import dut_param_pkg::*;



    // DUT interface
    logic           [p_width_bit-1 : 0]                 width;
    logic           [p_height_bit-1 : 0]                height;
    logic                                               frame_start;
    logic                                               frame_finish;

    // XDS IN
    logic                                               xds_in_valid;
    logic                                               xds_in_ready;
    logic           [p_depth_bit-1 : 0]                 depth;

    // XDS OUT
    logic                                               xds_out_valid;
    logic                                               xds_out_ready;
    logic           [p_depth_bit-1 : 0]                 histo_th [p_th_num];


    //
    logic                                               cin_txn_valid;

    // probes
    logic                                               probe_valid;
    logic                                               image_depth_valid, histo_valid;
    logic           [p_depth_bit-1 : 0]                 image_depth [p_depth_size];
    logic           [p_depth_size_bit-1 : 0]            histo [p_histo_size];


endinterface
