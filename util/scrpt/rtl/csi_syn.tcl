#!dc_shell -f

# setup param

# compile mapping efforts: low medium high
set MAP_EFFORT medium

# Setup for Formality Verification
#set_svf rtl2net.svf

# setup PATH
set RTL_FILELIST ../../util/scrpt/csi_rtl.filelist

# top design
set DESIGN_NAME d_phy

# setup libs
set search_path [concat $search_path ../../lib/tps65fs190rf_lvt_nt/db]
set MAIN_LIB tps65fs190rf_lvt_nt_ss_1p14v_40c
set target_library [ list ${MAIN_LIB}.db ]
set link_library [ list $target_library]


# setup input rtl
set RTL_FILELIST [open $RTL_FILELIST]
set RTL_FILE_LIST [split [read $RTL_FILELIST] "\n"]
close $RTL_FILELIST


# read_file -format verilog $RTL_FILE_LIST
analyze -format verilog $RTL_FILE_LIST
elaborate $DESIGN_NAME
current_design $DESIGN_NAME

write -hierarchy -format verilog -output ${DESIGN_NAME}.elab.v
#write -hierarchy -format ddc -output ${DESIGN_NAME}.elab.ddc

# Check the current design for consistency
check_design -summary
check_design > ${DESIGN_NAME}.elab.check_design.rpt

# setup constraints
source csi_constr.tcl

# make the synthesis
compile -map_effort $MAP_EFFORT -incremental_mapping

# High-effort area optimization
#optimize_netlist -area

# store output
write 		-hierarchy -format verilog 	-output ${DESIGN_NAME}.v
# write 		-hierarchy -format ddc    	-output ${DESIGN_NAME}.ddc
write_sdc 	-nosplit                 	${DESIGN_NAME}.sdc

# Write and close SVF file and make it available for immediate use
#set_svf -off

#generate report
#check_design  -nosplit                      > ${DESIGN_NAME}.check_design.rpt
#report_qor                                  > ${DESIGN_NAME}.qor.rpt
report_constraint -all_violators -nosplit   > ${DESIGN_NAME}.cons.rpt
report_cell                           		> ${DESIGN_NAME}.gates.rpt
report_area -hierarchy                      > ${DESIGN_NAME}.area.rpt
report_timing 		                    	> ${DESIGN_NAME}.time.rpt
#report_clock                                > ${DESIGN_NAME}.clocks.rpt
#report_power                                > ${DESIGN_NAME}.pwr.rpt

quit
