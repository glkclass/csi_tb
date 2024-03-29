/******************************************************************************************************************************
    Project         :  CSI
    Creation Date   :  June 2022
    Module          :  d_phy_mcnn
    Description     :   MIPI D-PHY v.2.5 Master Clock Lane module behavioral model.
                        CIL-MCNN type. Master Clock Lane module with ULPS and HS Tx Idle support
******************************************************************************************************************************/


// ****************************************************************************************************************************
import csi_param_pkg::*;
import csi_typedef_pkg::*;


module d_phy_mcnn (
    input hs_clk,
    interface ppi,
    output t_phy_line_states line
    );

    typedef enum {
        Off, On, Init, Stop,
        HsTxStart, HsTx, HsTxFinish,
        HsTxIdleStart, HsTxIdle, HsTxIdleFinish,
        UlpsStart, Ulps, UlpsFinish,
        Error } t_mcnn_states;

    t_mcnn_states state, next_state;

    // inputs
    // outputs
    // internals

// ****************************************************************************************************************************
    // tasks
    task generate_line_hs_clk(input integer n_ui = 0, time tme = 0);
        if (0 == n_ui)
            begin
                // Generate HS Line clock forever or given time
                `assert(tme >= 0,$sformatf("Wrong generation time(%d) for HS clock generation", tme))

                if (0 == tme)
                    begin
                        // Generate HS Line clock forever
                        forever
                            @(posedge hs_clk or negedge hs_clk)
                                line = (1'b1 == hs_clk) ? HS1 : HS0;
                    end
                else
                    begin
                        // generate HS clock for a given time 'tme'
                        fork
                            #tme;
                            forever
                                begin
                                    @(posedge hs_clk or negedge hs_clk)
                                    line = (1'b1 == hs_clk) ? HS1: HS0;
                                end
                        join_any
                        disable fork;

                        // Always finish with 'HS0'
                        if (hs_clk)
                            @(negedge hs_clk) line = HS0;
                    end
            end
        else
            begin
                // Generate HS Line clock for a given number of UI
                `assert (n_ui > 0, $sformatf("Wrong number of UI(%d) for HS clk generation", n_ui))

                repeat (n_ui)
                    @(posedge hs_clk or negedge hs_clk)
                        line = (1'b1 == hs_clk) ? HS1 : HS0;

                // Always finish with 'HS0'
                if (hs_clk)
                    @(negedge hs_clk) line = HS0;
            end
    endtask : generate_line_hs_clk
// ****************************************************************************************************************************


// ****************************************************************************************************************************
    // model
    // Lane main FSM
    always @(state, ppi.Enable)
        begin
            // `uvm_debug($sformatf("state: %s", state.name()))
            case(state)
                // Shutdown
                Off:
                    begin
                        ppi.Stopstate = X;
                        ppi.TxReadyHS = X;
                        ppi.TxHSIdleClkReadyHS = X;
                        ppi.UlpsActiveNot = X;
                        line = XXX;

                        wait (ppi.Enable)  // Take Lane out from Shutdown mode
                        next_state = Init;
                        //`uvm_debug($sformatf("next_state: %s", next_state.name()))
                    end

                // Initialization stage
                Init:
                    begin
                        ppi.Stopstate = FALSE;
                        ppi.TxReadyHS = FALSE;
                        ppi.TxHSIdleClkReadyHS = FALSE;
                        ppi.UlpsActiveNot = HIGH;
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

                            // 3 ways to leave Stop stage: Shutdown, request for HS Tx , request for ULPS mode .
                            wait(~ppi.Enable | ppi.TxRequestHS | ppi.TxUlpsClk);
                        join_any disable fork;

                        `assert (~ppi.TxUlpsClk | ~ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive!")

                        next_state =    (~ppi.Enable)           ?   Off :
                                        (ppi.TxRequestHS)       ?   HsTxStart : 
                                        (ppi.TxUlpsClk)         ?   UlpsStart : Error;
                        // `uvm_debug($sformatf("next_state: %s", next_state.name()))
                    end

                // Start HS clock generation from 'Stop' stage
                HsTxStart:
                    begin
                        ppi.Stopstate = FALSE;
                        fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during 'HS Tx StartUp' stage!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be asserted here!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment

                            // StartUp stage
                            begin
                                line = LP01;
                                #T_LPX line = LP00;
                                #T_CLK_PREPARE line = HS0;
                                #T_CLK_ZERO generate_line_hs_clk(.n_ui(T_CLK_PRE));
                            end
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : HsTx;
                    end

                // HS clock generation
                HsTx:
                    begin
                        @(posedge ppi.TxWordClkHS)
                        ppi.TxReadyHS = TRUE;

                        fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx' and 'ULPS' modes are mutually exclusive!")

                            // 3 ways to leave HS Tx stage: Shutdown, request for 'HS Tx' finish, request for 'HS TX Idle' mode
                            wait (~ppi.Enable || ~ppi.TxRequestHS || ppi.TxHSIdleClkHS);

                            generate_line_hs_clk();  // generate HS clock till TXRequestHS will be deasserted or TxHSIdleClkHS will be asserted
                        join_any disable fork;

                        `assert (ppi.TxRequestHS | ~ppi.TxHSIdleClkHS, "'HS Tx Finish' and 'HS Tx Idle Start' modes are mutually exclusive!")

                        next_state =    (~ppi.Enable)           ?   Off :
                                        (~ppi.TxRequestHS)    ?   HsTxFinish :
                                        (ppi.TxHSIdleClkHS) ?   HsTxIdleStart :
                                                                Error;
                    end

                // Finish HS clock generation when Data Lane TxReadyHS deasserted and move to 'Stop' stage
                HsTxFinish:
                    begin
                         fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(ppi.TxRequestHS, "Too short gap between HS TX stages!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be asserted here!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment

                            // Finish 'HS TX' stage
                            begin
                                // provide HS Clock for HS Data Lane trail period
                                generate_line_hs_clk(.tme(T_HS_TRAIL_0));
                                generate_line_hs_clk(.n_ui(T_HS_TRAIL_1));

                                // provide HS Clock for HS Data Lane post-trail period
                                generate_line_hs_clk(.tme(T_CLK_POST_0));
                                generate_line_hs_clk(.n_ui(T_CLK_POST_1));
                                `assert (line == HS0, "The Clock Line state have to be HS0 here")

                                @(posedge ppi.TxWordClkHS)
                                ppi.TxReadyHS = FALSE;

                                #T_CLK_TRAIL    line = LP11;
                                #T_HS_EXIT;
                            end
                        join_any disable fork;

                        next_state = (~ppi.Enable) ? Off : Stop;
                    end

                // Finish HS clock generation and move to 'HS Tx Idle' stage
                HsTxIdleStart:
                    begin
                        fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx(Idle)' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")
                            `assert_wait(~ppi.TxHSIdleClkHS, "'HS Tx Idle' shouldn't be deasserted here!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment
                            generate_line_hs_clk(.n_ui(T_HS_IDLE_POST));  // generate HS clock for a given number of UI
                            `assert (line == HS0, "The Clock Line state have to be HS0 here")
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : HsTxIdle;
                    end

                HsTxIdle:
                    begin
                        @(posedge ppi.TxWordClkHS)
                            ppi.TxReadyHS = FALSE;
                        line = HS0;

                        // Min Idle duration
                        fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx(Idle)' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")
                            `assert_wait(~ppi.TxHSIdleClkHS, $sformatf("Min Idle Clk time is %t ns!", T_HS_IDLE_CLK_HS0))

                            // 1 way to leave HS Tx Idle stage here: Shutdown
                            wait (~ppi.Enable);
                            #T_HS_IDLE_CLK_HS0;
                        join_any disable fork;

                        @(posedge ppi.TxWordClkHS)
                            ppi.TxHSIdleClkReadyHS = TRUE;

                        // Idle stage can be finished here
                        fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx(Idle)' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")

                            // 2 ways to leave HS Tx Idle stage here: Shutdown or Stop Idle stage
                            wait (~ppi.Enable | ~ppi.TxHSIdleClkHS);
                        join_any disable fork;

                        next_state =    (~ppi.Enable) ?             Off :
                                        (~ppi.TxHSIdleClkHS) ?  HsTxIdleFinish :
                                                                Error;
                    end

                HsTxIdleFinish:
                    begin
                        fork
                            `assert_wait(ppi.TxUlpsClk, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxRequestHS, "'TxRequestHS' shouldn't be deasserted during HS TX Idle!")
                            `assert_wait(ppi.TxHSIdleClkHS, "Too short gap between HS TX Idles stages!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment
                            generate_line_hs_clk(.n_ui(T_HS_IDLE_PRE));  // generate HS clock for a given number of UI
                        join_any disable fork;

                        @(posedge ppi.TxWordClkHS)
                            ppi.TxHSIdleClkReadyHS = FALSE;
                            ppi.TxReadyHS = TRUE;

                        next_state = (~ppi.Enable) ? Off : HsTx;
                    end

                UlpsStart:
                    begin
                        ppi.Stopstate = FALSE;
                        line = LP10;
                        fork
                            `assert_wait(ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxUlpsClk, "'TxUlpsClk' shouldn't be deasserted during 'ULPS Start' stage!")
                            `assert_wait(ppi.TxUlpsExit, "'TxUlpsExit' shouldn't be asserted during 'ULPS Start' stage!")
                            wait (~ppi.Enable); // It's Ok to Shutdown Lane at any moment
                            #T_LPX;
                        join_any disable fork;
                        next_state = (~ppi.Enable) ? Off : Ulps;
                    end

                Ulps:
                    begin
                        line = LP00;
                        ppi.UlpsActiveNot = LOW;
                        fork
                            `assert_wait(ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxUlpsClk, "'TxUlpsClk' shouldn't be deasserted during 'ULPS' stage!")

                            // 2 ways to leave ULPS stage: Shutdown or request to exit ULPS
                            wait (~ppi.Enable | ppi.TxUlpsExit);
                        join_any disable fork;
                        next_state =    (~ppi.Enable)       ?   Off :
                                        (ppi.TxUlpsExit)    ?   UlpsFinish :
                                                                Error;
                    end

                UlpsFinish:
                    begin
                        line = MARK1;
                        ppi.UlpsActiveNot = HIGH;
                        fork
                            `assert_wait(ppi.TxRequestHS, "'HS Tx' and 'ULPS' modes are mutually exclusive'!")
                            `assert_wait(ppi.TxHSIdleClkHS, "'HS Tx Idle' and 'ULPS' modes are mutually exclusive!")
                            `assert_wait(~ppi.TxUlpsClk, "'TxUlpsClk' shouldn't be deasserted during 'ULPS Wakeup stage' stage!")
                        #T_WAKEUP;
                        join_any disable fork;

                        // 2 ways to leave ULPS Finish stage after wakeup: Shutdown or take request to 'ULPS' mode off
                        wait (~ppi.Enable | ~ppi.TxUlpsClk);
                        next_state =    (~ppi.Enable)       ?   Off :
                                        (~ppi.TxUlpsClk)    ?   Stop :
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