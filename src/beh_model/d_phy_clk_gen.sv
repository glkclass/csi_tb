/***************************************************************************
Project        :  CSI
Module         :  d_phy_clk_gen
Author         :  Anton Voloshchuk
Creation Date  :  June 2022

Description.
    Generate 'Esc Clock' and 'Tx Word HS Clock' for MIPI D-PHY v.2.5 Master Clock/Data Lane module behavioral models.
***************************************************************************/

`timescale 1ns/1ps

// import tb_util_pkg::*;

module d_phy_clk_gen (
    input logic hs_clk,
    output logic hs_tx_word_clk, esc_tx_clk
    );

    // Generate 'Tx Word HS Clock'.
    // word clk = hs_clk div (HS_TX_WORD_BIT_WIDTH/2) since we use both edges
    always
        begin
            repeat(HS_TX_WORD_BIT_WIDTH / 4)
                @(posedge hs_clk);
            hs_tx_word_clk = LOW;
            repeat(HS_TX_WORD_BIT_WIDTH / 4)
                @(posedge hs_clk);
            hs_tx_word_clk = HIGH;
        end

    // Generate 'Esc Clock'.
    // word clk = hs_clk div T_HS_ESC_CLK_RATIO
    always
        begin
            repeat(T_HS_ESC_CLK_RATIO / 2)
                @(posedge hs_clk);
            esc_tx_clk = LOW;
            repeat(T_HS_ESC_CLK_RATIO / 2)
                @(posedge hs_clk);
            esc_tx_clk = HIGH;
        end


endmodule