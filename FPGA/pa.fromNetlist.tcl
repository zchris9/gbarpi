
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name GBARPi -dir "D:/GBARPi/planAhead_run_2" -part xc3s50antqg144-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "D:/GBARPi/GBARPiTop.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {D:/GBARPi} {ipcore_dir} }
set_property target_constrs_file "GBARPiTop.ucf" [current_fileset -constrset]
add_files [list {GBARPiTop.ucf}] -fileset [get_property constrset [current_run]]
link_design
