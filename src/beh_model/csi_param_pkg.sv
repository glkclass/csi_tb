/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Package         :   csi_param_pkg
    Description     :   Contain CSI params.
******************************************************************************************************************************/


// ****************************************************************************************************************************

// `timescale 1ps/1ps

package csi_param_pkg;
    parameter

    // General
    HIGH                                =   1'b1,
    LOW                                 =   1'b0,
    TRUE                                =   1'b1,
    FALSE                               =   1'b0,
    X                                   =   1'bx,

    // image sensor
    IMAGE_LINES                         =   4,  // number of lines per frame
    IMAGE_LINE_PIXELS                   =   16,  // number of pixels per line
    IMAGE_LINE_GAP                      =   8,  // gap in clk between two lines
    IMAGE_PIXEL_WIDTH                   =   14,  // image pixel width
    IMAGE_PIXEL_MAX_VALUE               =   (2**IMAGE_PIXEL_WIDTH) - 1,  // max pixel value 2^14 -1

    T_IMAGE_PIXEL_CLK                   =   1ns,  // Image pixel clock period length

    // Camera serial interface protocol
    VIRTUAL_CHANNEL                     =   2'h0,
    ECC                                 =   8'hCC,
    PIXEL14BITS_DATA_TYPE               =   6'h2D,
    FRAME_START_DATA_TYPE               =   6'h0,
    FRAME_END_DATA_TYPE                 =   6'h1,
    
    // FRAME_COUNTER_WIDTH                 =   16,
    // LONG_PACKET_WC_WIDTH                =   16,
    // SHORT_PACKET_HEADER_WIDTH           =   32,
    // LONG_PACKET_HEADER_WIDTH            =   32,
    // LONG_PACKET_FOOTER_WIDTH            =   16,
    // ECC_WIDTH                           =   8,
    // DATA_ID_WIDTH                       =   8,

    BYTE_WIDTH                          =   8,   // Width of byte
    CSI_FIFO_DATA_WIDTH                 =   8,   // Width of FIFO word
    CSI_FIFO_MAX_SIZE                   =   10*IMAGE_LINES*IMAGE_LINE_PIXELS;


    // *********************************************************************
    // timing
    parameter time
    // HS clock = 2.225 GHz, DDR data rate = 4.5 Gbps
    T_HS_CLK_UI                 =   222ps,

    // ESC_CLK = HS_CLK div T_HS_ESC_CLK_RATIO
    T_HS_ESC_CLK_RATIO          =   256,

    // HS Clock timing
    // Time that the transmitter drives the Clock Lane LP-00 Line state immediately before the HS-0 Line state starting the HS transmission
    T_CLK_PREPARE               =   40ns,

    // Time (in UI) that the HS clock shall be driven by the transmitter prior to any associated Data Lane beginning the transition from LP to HS mode.
    T_CLK_PRE                   =   8,

    // Time that the transmitter drives the HS-0 state prior to starting the Clock
    T_CLK_ZERO                  =   270ns,

    // Time that the transmitter continues to send HS clock after the last associated Data Lane has transitioned to LP mode.
    // Interval is defined as the period from the end of T HS-TRAIL to the beginning of T CLK-TRAIL .
    T_CLK_POST_0                =   60ns,
    T_CLK_POST_1                =   52,  //UI

    // Time that the transmitter drives the HS-0 state after the last payload clock bit of a HS
    // transmission burst.
    T_CLK_TRAIL                 =   60ns,

    // Time that the transmitter drives the flipped differential state after last payload data bit of a HS transmission burst.
    T_HS_TRAIL_0                =   60ns,
    T_HS_TRAIL_1                =   4,


    // Time that the transmitter drives LP-11 following a HS burst.
    T_HS_EXIT                   =   100ns,

    // Time that the transmitter drives the Data Lane LP-00 Line state immediately before the HS-0 Line state starting the HS transmission.
    T_HS_PREPARE                =   41ns,

    // ...time that the transmitter drives the HS-0 state prior to transmitting the Sync sequence.
    T_HS_ZERO_0                 =   105ns,
    T_HS_ZERO_1                 =   10,  //UI


    // Transmitted length of any Low-Power state period
    T_LPX                       =   55ns,

    // Init time. Spesified by CSI-2 protocol (min val = 100us)
    T_INIT                      =   1us,

    // Idle mode timing
    T_HS_IDLE_POST              =   8,  //UI
    T_HS_IDLE_CLK_HS0           =   60ns,
    T_HS_IDLE_PRE               =   8,  //UI

    // Time that a transmitter drives a Mark-1 state prior to a Stop state in order to initiate an exit from ULPS (min val = 1ms)
    T_WAKEUP                    =   1us,

    // max simulation time after which sim will be terminated (to resolve 'freeze' issue).
    T_MAX_SIM_DURATION          =   10us;

    // *********************************************************************
    // arch
    parameter
    // Number of D-PHY Data Lanes
    N_DATA_LANES                =   4,

    // HS TX bus width in bytes. Should be multiple of bytes: 1, 2, 4.
    HS_TX_WORD_BYTE_WIDTH       =   1,

    // HS TX bus width in bits
    HS_TX_WORD_BIT_WIDTH        =   HS_TX_WORD_BYTE_WIDTH*8,

    // Max HS TX bus width in bits
    //MAX_HS_TX_WORD_BIT_WIDTH    =   32,

    // LOG2(HS_TX_WORD_BIT_WIDTH)
    LOG_HS_TX_WORD_BIT_WIDTH    =   (2 + HS_TX_WORD_BYTE_WIDTH),


    // All sequences will be shifted out LSB-first!!!
    HS_SYNC_SEQUENCE            =   8'b10111000,
    LP_ULPS_SEQUENCE            =   8'b01111000;
endpackage : csi_param_pkg
// ****************************************************************************************************************************



