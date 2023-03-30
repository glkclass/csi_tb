/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Interface       :   d_phy_full_ppi_if, d_phy_appi_if, ci_if, csi_fifo_if, d_phy_adapter_line_if
    Description     :   Contain TB/DUT interfaces declaration for CSI project
******************************************************************************************************************************/


// ****************************************************************************************************************************
`include "uvm_macros.svh"
import uvm_pkg::*;

import dutb_macro_pkg::*;

import csi_param_pkg::*;
import csi_typedef_pkg::*;

// ****************************************************************************************************************************
// Full PPI interface to D-PHY CIL-XXXX Lane
interface d_phy_full_ppi_if;
    logic                                   TxWordClkHS;
    logic [1 : 0]                           TxDataWidthHS;
    logic [HS_TX_WORD_BIT_WIDTH-1 : 0]      TxDataHS;
    logic [3 : 0]                           TxWordValidHS;
    logic                                   TxEqActiveHS;
    logic                                   TxEqLevelHS;
    logic                                   TxRequestHS;
    logic                                   TxReadyHS;
    logic                                   TxDataTransferEnHS;
    logic                                   TxSkewCalHS;
    logic                                   TxAlternateCalHS;
    logic                                   RxWordClkHS;
    logic [1 : 0]                           RxDataWidthHS;
    logic [HS_TX_WORD_BIT_WIDTH-1 : 0]      RxDataHS;
    logic [3 : 0]                           RxValidHS;
    logic                                   RxActiveHS;
    logic                                   RxSyncHS;
    logic                                   RxDetectEobHS;
    logic                                   RxClkActiveHS;
    logic                                   RxDDRClkHS;
    logic                                   RxSkewCalHS;
    logic                                   RxAlternateCalHS;
    logic                                   RxErrorCalHS;
    logic                                   TxClkEsc;
    logic                                   TxRequestEsc;
    logic [3 : 0]                           TxRequestTypeEsc;
    logic                                   TxLpdtEsc;
    logic                                   TxUlpsExit;
    logic                                   TxUlpsEsc;
    logic [3 : 0]                           TxTriggerEsc;
    logic [7 : 0]                           TxDataEsc;
    logic                                   TxValidEsc;
    logic                                   TxReadyEsc;
    logic                                   RxClkEsc;
    logic                                   RxLpdtEsc;
    logic                                   RxUlpsEsc;
    logic [3 : 0]                           RxTriggerEsc;
    logic                                   RxWakeup;
    logic [7 : 0]                           RxDataEsc;
    logic                                   RxValidEsc;
    logic                                   TurnRequest;
    logic                                   Direction;
    logic                                   TurnDisable;
    logic                                   ForceRxmode;
    logic                                   ForceTxStopmode;
    logic                                   Stopstate;
    logic                                   Enable;
    logic                                   AlpMode;
    logic                                   TxUlpsClk;
    logic                                   RxUlpsClkNot;
    logic                                   UlpsActiveNot;
    logic                                   TxHSIdleClkHS;
    logic                                   TxHSIdleClkReadyHS;
    logic                                   ErrSotHS;
    logic                                   ErrSotSyncHS;
    logic                                   ErrEsc;
    logic                                   ErrSyncEsc;
    logic                                   ErrControl;
    logic                                   ErrContentionLP0;
    logic                                   ErrContentionLP1;

    // 'HS Clock Ready' generated in 'Clock Lane' and fed to 'Data Lane'
    logic                                   TxReadyHSClk;


    modport adapter (
        output
            Stopstate,
            TxClkEsc
        );

    modport mcnn (
        input
            Enable,
            TxWordClkHS,
            TxRequestHS,
            TxHSIdleClkHS,
            TxClkEsc,
            TxUlpsClk,
            TxUlpsExit,
        output
            Stopstate,
            TxReadyHS,
            TxHSIdleClkReadyHS,
            UlpsActiveNot
    );

    modport mfen (
        input
            Enable,
            TxWordClkHS,
            TxRequestHS,
            TxDataHS,
            TxWordValidHS,
            TxReadyHSClk,
            TxHSIdleClkHS,
            TxClkEsc,
            TxRequestEsc,
            TxUlpsEsc,
            TxUlpsExit,

        output
            Stopstate,
            TxReadyHS,
            TxHSIdleClkReadyHS,
            UlpsActiveNot
        );
endinterface
// ****************************************************************************************************************************


// ****************************************************************************************************************************
interface d_phy_appi_if();
    logic
        Enable,     // Enable Lane, protocol and adapter modules  
        Stopstate,
        TxRequestHS,
        TxWordClkHS;

    int
        BurstSize;


    modport adapter (
        input
            Enable,
            TxRequestHS,
            BurstSize,
        output
            Stopstate,
            TxWordClkHS
        );

    modport protocol (
        input
            Enable,
            Stopstate,
            TxWordClkHS,
        output
            TxRequestHS,
            BurstSize
    );

endinterface
// ****************************************************************************************************************************


// ****************************************************************************************************************************
// Camera serial interface
interface ci_if (
    input 
        rst, 
        clk);  // clock to read out data from Image sensor 
    logic
        ready = 1'b0;  // CSI protocol is ready to accept image frame

    // Camera Serial If
    logic
        vsync = 1'b0,
        hsync = 1'b0;
    t_pixel
        data = {IMAGE_PIXEL_WIDTH{1'bx}};

    // Camera -> CSI protocol
    modport tx (
        input   clk, rst, ready,
        output  vsync, hsync, data);

    //  CSI protocol <- Camera
    modport rx (
        input clk, rst, vsync, hsync, data,
        output ready);
endinterface
// ****************************************************************************************************************************


// ****************************************************************************************************************************
// FIFO input interface
interface fifo_in_if(input rst, clk);
    logic           
                    valid       = FALSE,
                    full        = FALSE;
    t_fifo_data     data;
    t_fifo_data     fifo[$];

    task push(input t_fifo_data data);
        `ASSERT (~is_full(), $sformatf("FIFO is full, size = %d", size()));
        fifo.push_front(data);
        // `uvm_debug($sformatf("Push data: 0x%2H, FIFO size = %0d", data, size()));
        full = is_full();
    endtask

    function int size();
        return fifo.size();
    endfunction : size

    function logic is_full();
        return CSI_FIFO_MAX_SIZE <= fifo.size();
    endfunction

    // FIFO <- CSI protocol
    modport rx (
        input   clk, valid, data,
        output  full);

    // CSI protocol -> FIFO
    modport tx (
        input   clk, full,
        output  valid, data);
endinterface
// ****************************************************************************************************************************


// ****************************************************************************************************************************
// FIFO output interface
interface fifo_out_if(input rst, clk);
    logic
                    ready = FALSE,
                    empty = FALSE;
    t_fifo_data     data;
    t_fifo_data     fifo[$];

    task pop(output t_fifo_data data);
        `ASSERT (~is_empty(), "FIFO is empty");
        data = fifo.pop_back();
        empty = is_empty();
        `uvm_debug($sformatf("Pop data: 0x%2H, FIFO size = %0d",data, size()));
    endtask

    function int size();
        return fifo.size();
    endfunction : size

    function logic is_empty();
        return 0 == fifo.size();
    endfunction

    // FIFO -> APPI
    modport out_tx (
        input   clk, ready,
        output  empty, data);

    // APPI <- FIFO
    modport out_rx (
        input   clk, empty, data,
        output  ready);
endinterface
// ****************************************************************************************************************************

// ****************************************************************************************************************************
// Interface to output Line (One Clock and up to N Data lines)
interface d_phy_adapter_line_if;
    parameter   N = N_DATA_LANES;  //Number of data lines

    t_phy_line_states       clk;
    t_phy_line_states       data[0 : N-1];

    modport master (output clk, data);
    modport slave (input clk, data);
endinterface
// ****************************************************************************************************************************
// ****************************************************************************************************************************
