package dut_param_pkg;
    parameter
    // dut param
    P_CIN_DATA_WIDTH            =   4,

    p_depth_bit                 =   8,  // input pixel bit width
    p_width_bit                 =   6,  // 2**p_width_bit - line size
    p_height_bit                =   6,  // 2**p_height_bit - column size
    p_depth_size_bit            =   10,  // p_width_bit + p_height_bit,  // 2**p_depth_size_bit - max num of input pixels
    p_depth_size                =   2**p_depth_size_bit,
    p_depth_qnt_bit             =   3,  // output (after quantization) pixel bit width
    p_th_num                    =   7,

    // image sram //
    p_depth_sram_a_bit          =   p_depth_size_bit,
    p_depth_sram_d_bit          =   p_depth_bit,

    // histo sram //
    p_histo_sram_a_bit          =   p_depth_bit,  // address bus. 2^8 histo values
    p_histo_sram_d_bit          =   p_depth_size_bit,  // data bus = 'histo' value bit width depends on image size

    p_histo_size                =   2**p_depth_bit;  //num of histo columns

endpackage

