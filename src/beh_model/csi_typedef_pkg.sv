/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Package         :   csi_typedef_pkg
    Description     :   Contain CSI model user defined types
******************************************************************************************************************************/


// ****************************************************************************************************************************
package csi_typedef_pkg;

    import dutb_typedef_pkg::*;
    import csi_param_pkg::*;

    // PHY Line states:
    // HS0, HS1 - high speed diff values
    // LP00, LP01, LP10, LP11 - low power single ended values. LP01 == MARK0, LP10 == MARK1
    // XXX - non-defined value (for sim)
    typedef enum { HS0, HS1, LP00, LP01, LP10, LP11, MARK0, MARK1, XXX } t_phy_line_states;


    // CSI interface signals
    typedef logic   [IMAGE_PIXEL_WIDTH - 1          : 0]        t_pixel;
    typedef logic   [CSI_FIFO_DATA_WIDTH - 1        : 0]        t_fifo_data;


    // PHY Lane signals
    typedef logic                                               t_clock_lane_signal;
    typedef logic   [N_DATA_LANES-1                 : 0]        t_data_lane_signal;

    typedef logic   [HS_TX_WORD_BIT_WIDTH - 1       : 0]        t_data_lane_bus [N_DATA_LANES];


    // complex Lane signal: Clk + Data
    typedef struct {
        t_clock_lane_signal clk;
        t_data_lane_signal data;
        } t_lane_signal;

    // should be moved from here to separate csi util package
    // convert four 14-bit pixels to 7-byte width vector
    function byte_vector convert_4pixels_to_7bytes(t_pixel four_pixels[4]);
        byte                                            seven_byte_vector [7];
        logic           [3 * BYTE_WIDTH - 1     : 0]    three_byte_vector;

        foreach (four_pixels[i]) 
            begin
                // 8-bit bytes
                seven_byte_vector[i] = four_pixels[i][IMAGE_PIXEL_WIDTH - 1 -: BYTE_WIDTH];
                // 6-bit tails
                three_byte_vector = three_byte_vector >> IMAGE_PIXEL_TAIL_WIDTH;
                three_byte_vector[3*BYTE_WIDTH - 1 -: IMAGE_PIXEL_TAIL_WIDTH] = four_pixels[i][IMAGE_PIXEL_TAIL_WIDTH - 1 : 0];
            end
        seven_byte_vector[4:6] = {three_byte_vector, three_byte_vector>>8, three_byte_vector>>16};
        return seven_byte_vector;
    endfunction : convert_4pixels_to_7bytes

endpackage : csi_typedef_pkg
// ****************************************************************************************************************************



