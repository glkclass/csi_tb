/******************************************************************************************************************************
    Project         :   CSI
    Creation Date   :   Dec 2021
    Class           :   dut_fcc
    Description     :   Interface   -   
                        Task        -   
******************************************************************************************************************************/


// ****************************************************************************************************************************
class dut_fcc  #(type   T_DIN_TXN   = dutb_txn_base,
                        T_DOUT_TXN  = dutb_txn_base,
                        T_POUT_TXN  = dutb_txn_base)
extends dut_fcc_base #(T_DIN_TXN, T_DOUT_TXN, T_POUT_TXN);
    `uvm_component_param_utils(dut_fcc #(T_DIN_TXN, T_DOUT_TXN, T_POUT_TXN))

    covergroup cover_din_txn (string name);
        option.per_instance = 1;
        option.name = name;

        cover_frame_width:      coverpoint din_txn.width
            {
                bins corner_values[] = {0, 1, 16, 1024, 2048, 2};
            }

        cover_frame_height:      coverpoint din_txn.height
            {
                bins corner_values[] = {0, 1, 16, 1024, 2048};
            }
    endgroup

    extern function new(string name = "dut_fcc", uvm_component parent=null);
    //extern          task            run_phase( uvm_phase phase );


    extern virtual  function void sample_coverage();
    extern virtual  function void check_coverage_results();
endclass
// ****************************************************************************************************************************


// ****************************************************************************************************************************
function dut_fcc::new(string name = "dut_fcc", uvm_component parent=null);
    super.new(name, parent);
    cover_din_txn = new("cover_din_txn");
endfunction


function void dut_fcc::sample_coverage();
    cover_din_txn.sample ();
endfunction


function void dut_fcc::check_coverage_results();
    cov_value["width"]  = din_txn.width;
    cov_value["height"]  = din_txn.height;

    cov_result["width"]  = cover_din_txn.cover_frame_width.get_inst_coverage();
    cov_result["height"]  = cover_din_txn.cover_frame_height.get_inst_coverage();
    cov_result["width + height"]  = cover_din_txn.get_inst_coverage();

    `uvm_info("COVERAGE", {"\n", map_int2str(cov_value), "\n", map_flt2str(cov_result)}, UVM_HIGH)

    progress_bar_h.display();
    if (34 == progress_bar_h.cnt)
        begin
            dut_handler_h.stop_test("FCC target achieved");  // finish current test
        end
endfunction
// ****************************************************************************************************************************
