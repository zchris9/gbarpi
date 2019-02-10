
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name GBARPi -dir "C:/Users/Christian/OneDrive/Dokumente/GBA RPi/FPGA/GBARPi/planAhead_run_3" -part xc3s50antqg144-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "GBARPiTop.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {ipcore_dir/PROGMEM.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {SRAMController.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {SPIFrameReceiver.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {SoundFIFO.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/DCM_SRAM.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {GBAROM.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {GBARPiTop.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set_property top GBARPiTop $srcset
add_files [list {GBARPiTop.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s50antqg144-4
