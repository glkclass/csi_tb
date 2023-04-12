/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Module          :   d_phy_adapter_layer
    Description     :   MIPI D-PHY v.2.5 PHY Adapter Layer that ties all Lanes( Data and Clock) and the PHY Protocol Interface together.
******************************************************************************************************************************/

// ****************************************************************************************************************************
import csi_param_pkg::*;
import csi_typedef_pkg::*;


module d_phy_master_adapter_layer (
    input logic hs_clk,
    fifo_if fifo,
    d_phy_appi_if appi,
    interface line
    );
// ****************************************************************************************************************************

// ****************************************************************************************************************************
    // For every Data Lane extract tx word from fifo
    function t_data_lane_bus pop_vector();
        t_data_lane_bus vec;
        foreach (vec[i])
            vec[i] = fifo.pop();
        // `uvm_debug($sformatf("Fifo size after read out: %d", fifo.size()))
        return vec;
    endfunction
// ****************************************************************************************************************************

// ****************************************************************************************************************************
    // inputs

    // internals
    logic
        hs_tx_word_clk, esc_tx_clk;

    // inputs to Clock lane
    t_clock_lane_signal
        tx_ulps_clk = FALSE;

    // inputs to Data Lane
    t_data_lane_signal
        tx_clk_esc = {N_DATA_LANES{FALSE}},
        tx_ulps_esc = {N_DATA_LANES{FALSE}},
        tx_request_esc = {N_DATA_LANES{FALSE}};

    t_data_lane_bus
        tx_data_hs = {N_DATA_LANES{{HS_TX_WORD_BIT_WIDTH{X}}}};

    // inputs to Lane
    t_lane_signal
        tx_ulps_exit = '{FALSE, {N_DATA_LANES{FALSE}}},
        tx_hs_idle_clk_hs = '{FALSE, {N_DATA_LANES{FALSE}}},
        tx_request_hs = '{FALSE, {N_DATA_LANES{FALSE}}};

    // outputs from Lane
    t_lane_signal
        stop_state, tx_ready_hs;

    int open_requests = 0;  //count data transfer requests
// ****************************************************************************************************************************

// ****************************************************************************************************************************
    // Integral Lane Stopstate signal (inform protocol side that Lane is ready)
    assign appi.Stopstate = (stop_state.clk & (&stop_state.data));

    // Used only for monitoring data stream from adapter to Data Lane
    assign appi.TxReadyHS = (&tx_ready_hs.data);
    assign appi.TxDataHS = tx_data_hs;


    always
        begin
            // Wait for the 'request (1-clock strobe) to initiate data burst sending' from protocol side
            @(posedge hs_tx_word_clk iff appi.TxRequestHS) #0 
                open_requests++;
        end


    // Receive HS TX request from protocol and transfer it to Lane
    always
        begin
            wait (open_requests > 0);

            // Start D-PHY transmitt procedure
            tx_request_hs.clk   = TRUE;  // request Clock Lane to start Clock
            @(posedge tx_ready_hs.clk);  // feedback: Clock is running

            `uvm_debug_m($sformatf("Burst read out started. Fifo size: %0d", fifo.size()))
            @(posedge hs_tx_word_clk) #0 
                tx_request_hs.data  =   {N_DATA_LANES{TRUE}};  // request All Data Lanes to start transmitting
                tx_data_hs = pop_vector();  // read first N_DATA_LANES bytes from fifo

            // read rest burst
            repeat (appi.BurstSize/N_DATA_LANES - 1)
                begin
                    @(posedge hs_tx_word_clk iff (&tx_ready_hs.data)) #0 
                        tx_data_hs = pop_vector();  // read N_DATA_LANES bytes from fifo
                end
            
            tx_request_hs.data   =   {N_DATA_LANES{FALSE}};  // request Data Lane to finish transmitting

            fork
                // last N_DATA_LANES bytes transmitted
                @(posedge hs_tx_word_clk iff (&tx_ready_hs.data)) #0
                    tx_data_hs = {N_DATA_LANES{{HS_TX_WORD_BIT_WIDTH{X}}}};

                `uvm_debug_m($sformatf("Burst read out finished. Fifo size: %0d",fifo.size()))

                begin
                    @(negedge |tx_ready_hs.data)
                        tx_request_hs.clk   =   FALSE;                  //  request Clock Lane to stop Clock
                        open_requests--;  // given request is processed                    
                end
            join


        end


    // Clock generator
    d_phy_clk_gen d_phy_clk_gen (
        .hs_clk(hs_clk),
        .hs_tx_word_clk(hs_tx_word_clk),
        .esc_tx_clk(esc_tx_clk));
    assign appi.TxWordClkHS =   hs_tx_word_clk;


    // Clock Lane
    assign d_phy_mcnn_ppi_if.Enable         =   appi.Enable;
    assign d_phy_mcnn_ppi_if.TxWordClkHS    =   hs_tx_word_clk;
    assign d_phy_mcnn_ppi_if.TxRequestHS    =   tx_request_hs.clk;
    assign d_phy_mcnn_ppi_if.TxHSIdleClkHS  =   tx_hs_idle_clk_hs.clk;
    assign d_phy_mcnn_ppi_if.TxUlpsClk      =   tx_ulps_clk;
    assign d_phy_mcnn_ppi_if.TxUlpsExit     =   tx_ulps_exit.clk;

    assign tx_ready_hs.clk                  =   d_phy_mcnn_ppi_if.TxReadyHS;
    assign stop_state.clk                   =   d_phy_mcnn_ppi_if.Stopstate;

    d_phy_full_ppi_if   d_phy_mcnn_ppi_if();
    d_phy_mcnn d_phy_mcnn (
        .hs_clk(hs_clk),
        .ppi(d_phy_mcnn_ppi_if.mcnn),
        .line(line.clk));


generate
    genvar ii;
    // N Data Lanes
    for (ii = 0; ii < N_DATA_LANES; ii++)
        begin

            assign d_phy_mfen_ppi_if.Enable             =   appi.Enable;
            assign d_phy_mfen_ppi_if.TxWordClkHS        =   hs_tx_word_clk;

            assign d_phy_mfen_ppi_if.TxRequestHS        =   tx_request_hs.data[ii];
            assign d_phy_mfen_ppi_if.TxDataHS           =   tx_data_hs[ii];


            assign d_phy_mfen_ppi_if.TxClkEsc           =   tx_clk_esc[ii];
            assign d_phy_mfen_ppi_if.TxUlpsEsc          =   tx_ulps_esc[ii];
            assign d_phy_mfen_ppi_if.TxRequestEsc       =   tx_request_esc[ii];

            assign d_phy_mfen_ppi_if.TxHSIdleClkHS      =   tx_hs_idle_clk_hs.data[ii];
            assign d_phy_mfen_ppi_if.TxUlpsExit         =   tx_ulps_exit.data[ii];


            assign  stop_state.data[ii] = d_phy_mfen_ppi_if.Stopstate;
            assign  tx_ready_hs.data[ii] = d_phy_mfen_ppi_if.TxReadyHS;

            d_phy_full_ppi_if   d_phy_mfen_ppi_if();
            d_phy_mfen d_phy_mfen (
                .hs_clk(hs_clk),
                .ppi(d_phy_mfen_ppi_if.mfen),
                .line(line.data[ii]));
        end
endgenerate

endmodule
// ****************************************************************************************************************************
