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

interface d_phy_appi_if(input Enable);
    logic
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


// Camera serial interface
interface ci_if (input Clk, Rst_n);
    logic
        Enable = LOW,
        VSync = 1'b0,
        HSync = 1'b0;
    t_pixel
        Data = {IMAGE_PIXEL_WIDTH{1'bx}};

    // Camera -> CSI protocol
    modport tx (
        input   Clk, Rst_n,
        output  VSync, HSync, Data);

    //  CSI protocol <- Camera
    modport rx (
        input Clk, Rst_n, Enable, VSync, HSync, Data);
endinterface

// Fifo interface
interface csi_fifo_if(input ClkRx, ClkTx);
    logic
        ValidRx,
        FullRx = FALSE,

        ReadyTx,
        EmptyTx = TRUE;

    t_fifo_data
        DataRx,
        DataTx;

    t_fifo_data fifo[$];

    task push(input t_fifo_data data);
        `ASSERT (~full(), $sformatf("FIFO is full, size = %d",size()));
        fifo.push_front(data);
        EmptyTx = FALSE;
        // log_debug($sformatf("Push data: 0x%2H, FIFO size = %0d",data, size()), FALSE);
    endtask

    task pop(output t_fifo_data data);
        `ASSERT (~empty(), "FIFO is empty");
        data = fifo.pop_back();
        EmptyTx = empty() ? TRUE : FALSE;
        // log_debug($sformatf("Pop data: 0x%2H, FIFO size = %0d",data, size()), FALSE);
    endtask

    function int size();
        return fifo.size();
    endfunction : size

    function logic empty();
        return 0 == fifo.size();
    endfunction

    function logic full();
        return CSI_FIFO_MAX_SIZE <= fifo.size();
    endfunction


    // modport master_tx (
    //     output  ClkRx, ValidRx, DataRx,
    //     input   FullRx);

    modport slave_rx (
        input   ClkRx, ValidRx, DataRx,
        output  FullRx);

    // modport master_rx (
    //     output  ClkTx, ReadyTx,
    //     input   EmptyTx, DataTx);

    modport slave_tx (
        inout   ClkTx, ReadyTx,
        output  EmptyTx, DataTx);
endinterface


// Interface to output Line (One Clock and up to N Data lines)
interface d_phy_adapter_line_if;
    parameter   N = N_DATA_LANES;  //Number of data lines

    t_phy_line_states       clk;
    t_phy_line_states       data[0 : N-1];

    modport master (output clk, data);
    modport slave (input clk, data);
endinterface
// ****************************************************************************************************************************
