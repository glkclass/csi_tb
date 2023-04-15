/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   June 2022
    Module          :   d_phy_mfen
    Description     :   MIPI D-PHY v.2.5 Master Data Lane module behavioral model.
                        CIL-MFEN type. Master Data Lane module with Forward High-speed only and Forward Escape Mode only.
******************************************************************************************************************************/


// ****************************************************************************************************************************
import csi_param_pkg::*;
import csi_typedef_pkg::*;

module d_phy_mfen (
    input hs_clk,
    interface ppi,
    output t_phy_line_states line
    );

    typedef enum {
        Off, On, Init, Stop,
        HsTxStart, HsTx, HsTxFinish,
        HsTxIdleStart, HsTxIdle, HsTxIdleFinish,
        EscUlpsStart, EscUlps, EscUlpsFinish,
        Error } t_mcnn_states;

    t_mcnn_states state = Off, next_state = Off;

    // inputs
    // outputs
    // internals

// ****************************************************************************************************************************
    // tasks
    // Shift 8/16/32-bit HS data word out to line (LSB-first) based on hs_clk (both edges)
    // If n_ui > 8/16/32 last bit is sent several times.
    // The task should be start just after hs_clk rising edge.
    task send_hs_data(input logic[HS_TX_WORD_BIT_WIDTH-1 : 0] data, integer n_ui);
        `assert (n_ui > 0, $sformatf("Wrong number of UI(%d) for HS data sending", n_ui));

        `assert (hs_clk, "We should start from 'hs clk' rising edge!");
        line = (data & 1'b1) ? HS1 : HS0;
        data  >>=  1;

        repeat (n_ui-1)
            begin
                @(posedge hs_clk or negedge hs_clk)
                    line = (data & 1'b1) ? HS1 : HS0;
                    data  >>=  1;
            end

        `assert (~hs_clk, "We should end by 'hs clk' falling edge!");

    endtask : send_hs_data

    // Shift 8-bit LP data word out to line (LSB-first) based on ppi.TxClkEsc (rising edge)
    // If n > 8 last bit is sent several times.
    // The task should be start just after ppi.TxClkEsc rising edge.
    task send_lp_data(input logic[7 : 0] data, integer n);
        `assert (n > 0, $sformatf("Wrong number of bits(%d) for LP data sending", n));

        `assert (ppi.TxClkEsc, "We should start from 'ppi.TxClkEsc' rising edge!");
        line = (data & 1'b1) ? MARK1 : MARK0;
        @(negedge ppi.TxClkEsc)
            line = LP00;
        data  >>=  1;

        repeat (n-1)
            begin
                @(posedge ppi.TxClkEsc)
                    line = (data & 1'b1) ? MARK1 : MARK0;
                @(negedge ppi.TxClkEsc)
                    line = LP00;
                data  >>=  1;
            end
    endtask : send_lp_data
// ****************************************************************************************************************************


// ****************************************************************************************************************************
    // model
    // Lane main FSM
    always @(state, ppi.Enable)
        begin
            // logic [HS_TX_WORD_BIT_WIDTH-1 : 0] tx_word;
            // `uvm_debug($sformatf("state: %s", state.name()))

            case(state)
                // Shutdown
                Off:
                    begin
                        ppi.Stopstate = X;
                        ppi.TxReadyHS = X;
                        line = XXX;

                        wait (ppi.Enable);  // Take Lane out from Shutdown mode
                        next_state = Init;
                        //`uvm_debug($sformatf("next_state: %s", next_state.name()))
                    end

                // Initialization stage
                Init:
                    begin
                        ppi.Stopstate           =   FALSE;
                        ppi.TxReadyHS           =   FALSE;
                        ppi.UlpsActiveNot       =   HIGH;
                        line = LP11;

                        fork
                            wait (~ppi.Enable);  // It's Ok to Shutdown Lane at any moment
                            #T_INIT;
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : Stop;
                        //`uvm_debug($sformatf("next_state: %s", next_state.name()))
                    end

                // Generate LP11 and waiting for requests
                Stop:
                    begin
                        ppi.Stopstate = TRUE;
                        line = LP11;

                        fork
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be asserted here!")                           

                            // 3 ways to leave Stop stage: Shutdown, request for HS Tx , request for ESC mode .
                            wait(~ppi.Enable | ppi.TxRequestHS);

                            @(posedge ppi.TxClkEsc iff ppi.TxRequestEsc & ~ppi.TxUlpsEsc)
                                `assert(FALSE, "Request Esc should be asserted together with ULPS!")

                            @(posedge ppi.TxClkEsc iff ppi.TxRequestEsc & ppi.TxUlpsEsc);
                        join_any disable fork;

                        `assert (~ppi.TxRequestHS  | ~ppi.TxRequestEsc, "'HS Tx' and 'ESC' modes are mutually exclusive!")

                        next_state =    (~ppi.Enable)           ?   Off :
                                        (ppi.TxRequestHS)       ?   HsTxStart :
                                        (ppi.TxRequestEsc)      ?   EscUlpsStart: Error;
                        // `uvm_debug($sformatf("next_state: %s", next_state.name()))
                    end

                // Start HS Data Burst from 'Stop' stage
                HsTxStart:
                    begin
                        ppi.Stopstate = FALSE;
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during 'HS Tx StartUp' stage!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be asserted during 'HS Tx StartUp' stage!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment

                            // StartUp stage
                            begin
                                line = LP01;
                                #T_LPX          line    = LP00;
                                #T_HS_PREPARE   line    = HS0;
                                #T_HS_ZERO_0    line    = HS0;

                                @(posedge hs_clk)
                                    send_hs_data(8'h00, T_HS_ZERO_1);
                            end
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : HsTx;
                    end

                // HS Data Burst sending
                HsTx:
                    begin
                        // schedule first burst word to sent
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted till at least one TX word will be sent!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be asserted till at least one TX word will be sent!")

                            // 1 way to leave HS Tx stage here: Shutdown,
                            wait (~ppi.Enable);

                            begin
                                @(posedge ppi.TxWordClkHS)
                                    ppi.TxReadyHS = TRUE;
                                    send_hs_data(HS_SYNC_SEQUENCE, 8);  // send Sync sequence

                                @(posedge ppi.TxWordClkHS);  // the first HS burst word has been scheduled to send
                            end
                        join_any disable fork;

                        // schedule and send rest of burst
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx' and 'ULPS' modes are mutually exclusive!")

                            // 3 ways to leave HS Tx stage: Shutdown - at any time,
                            // request for 'HS Tx' finish or request for 'HS TX Idle' mode - after scheduled word will be sent
                            wait (~ppi.Enable);

                            begin
                                send_hs_data(ppi.TxDataHS, 8);  // send the first HS burst word

                                forever
                                    @(posedge ppi.TxWordClkHS iff (ppi.TxRequestHS & ~ppi.TxHSIdleClkHS))
                                        send_hs_data(ppi.TxDataHS, 8);  // send the next HS burst word
                            end

                            // Stop when HS Tx deasserted or Idle request asserted
                            @ (posedge ppi.TxWordClkHS iff (~ppi.TxRequestHS | ppi.TxHSIdleClkHS));
                        join_any disable fork;

                        `assert (ppi.TxRequestHS | ~ppi.TxHSIdleClkHS, "'HS Tx Finish' and 'HS Tx Idle' modes are mutually exclusive!")

                        next_state =    (~ppi.Enable) ? Off :
                                        (~ppi.TxRequestHS) ? HsTxFinish :
                                        (ppi.TxHSIdleClkHS) ? HsTxIdleStart : Error;
                    end

                // Finish HS Data Burst sending and move to 'Stop' stage
                HsTxFinish:
                    begin
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(ppi.TxRequestHS, "Too short gap between HS TX stages!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be asserted here!")

                            // 1 way to leave HS Tx finish stage: Shutdown
                            wait (~ppi.Enable);

                            // Finish 'HS TX' stage
                            begin
                                ppi.TxReadyHS = FALSE;
                                line = (HS0 == line ) ? HS1 : HS0;
                                repeat (T_HS_TRAIL_1)
                                    @(posedge hs_clk or negedge hs_clk);
                                #T_HS_TRAIL_0   line = LP11;
                                #T_HS_EXIT;
                            end
                        join_any disable fork;

                        next_state = (~ppi.Enable) ? Off : Stop;
                    end

                // Finish HS Data Burst sending and move to 'Idle' stage
                HsTxIdleStart:
                    begin
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx(Idle)' and 'Esc' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")
                            `assert_wait(~ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be deasserted here!")

                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment

                            begin
                                ppi.TxReadyHS = FALSE;
                                line = HS0;
                            end
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : HsTxIdle;
                    end

                HsTxIdle:
                    begin
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx(Idle)' and 'Esc' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")
                            // 2 ways to leave HS Tx Idle stage: Shutdown or request to exit 'HS Tx Idle' mode
                            wait (~ppi.Enable | ~ppi.TxHSIdleClkHS);
                        join_any disable fork;

                        next_state =    (~ppi.Enable)           ?   Off :
                                        (~ppi.TxHSIdleClkHS)    ?   HsTxIdleFinish :
                                                                    Error;
                    end

                HsTxIdleFinish:
                    begin
                        fork
                            `assert_wait(ppi.TxRequestEsc, "'HS Tx Idle' and 'Esc' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")
                            `assert_wait(ppi.TxHSIdleClkHS, "Too short gap between HS TX Idles stages!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment
                            begin
                                @(posedge ppi.TxReadyHSClk);  // wait for HS Clock is ready
                                #T_HS_ZERO_0;
                                repeat (T_HS_ZERO_1)
                                    @(posedge hs_clk or negedge hs_clk);
                            end
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : HsTx;
                    end

                EscUlpsStart:
                    begin
                        ppi.Stopstate = FALSE;
                        fork
                            `assert_wait(ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestEsc, "'TxUlpsClk' shouldn't be deasserted during 'ULPS Start' stage!")
                            `assert_wait(ppi.TxUlpsExit, "'TxUlpsExit' shouldn't be asserted during 'ULPS Start' stage!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment

                            begin
                                @(posedge ppi.TxClkEsc)
                                    send_lp_data(2'b01, 2);
                                @(posedge ppi.TxClkEsc)
                                    send_lp_data(LP_ULPS_SEQUENCE, 8);
                            end
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : EscUlps;
                    end

                EscUlps:
                    begin
                        `assert(line == LP00, "Line should be LP00 here")
                        @(posedge ppi.TxClkEsc)
                            ppi.UlpsActiveNot = LOW;

                        fork
                            `assert_wait(ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestEsc, "'TxRequestEsc' shouldn't be deasserted during 'ULPS' stage!")

                            // 2 ways to leave ULPS stage: Shutdown or request to exit ULPS
                            wait (~ppi.Enable);
                            @(posedge ppi.TxClkEsc iff ppi.TxUlpsExit);

                        join_any disable fork;

                        next_state =    (~ppi.Enable)       ?   Off :
                                        (ppi.TxUlpsExit)    ?   EscUlpsFinish :
                                                                Error;
                    end

                EscUlpsFinish:
                    begin
                        line = MARK1;
                        @(posedge ppi.TxClkEsc)
                            ppi.UlpsActiveNot = HIGH;

                        fork
                            `assert_wait(ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive'!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestEsc, "'TxRequestEsc' shouldn't be deasserted during 'ULPS Wakeup stage' stage!")
                            #T_WAKEUP;
                        join_any disable fork;

                        fork
                            // 2 ways to leave ULPS Finish stage after wakeup: Shutdown or deassert request TxRequestEsc
                            wait (~ppi.Enable);
                            @(posedge ppi.TxClkEsc iff ppi.TxRequestEsc);
                        join_any disable fork;

                        next_state =    (~ppi.Enable)           ?   Off :
                                        (ppi.TxRequestEsc)      ?   Stop :
                                                                    Error;
                    end

                Error:
                    begin
                        `assert(FALSE, "Error FSM state")
                    end

                default:
                    begin
                        next_state = Off;
                    end
            endcase
        end

    always @(next_state)
        begin
            // `uvm_debug($sformatf("state: %s    next_state: %s", state.name(), next_state.name()))
            #0 state = next_state;
        end

endmodule
// ****************************************************************************************************************************