
create_clock -name main_clk -period 35 [get_ports clk_main_drv]
set_clock_uncertainty 0.2  main_clk

set_max_fanout 8 [all_inputs]
set_load -pin_load 0.05 [all_outputs]
set_driving_cell -lib_cell NAND2_X4_12_LVT_NT -pin Q -library $MAIN_LIB [all_inputs]

#set_input_delay 0.7 -clock main_clk [get_ports {foo bar cp_gain}]
set_output_delay 0 -clock main_clk [get_ports {cnt}]
