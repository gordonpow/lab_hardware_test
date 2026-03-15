set_property IOSTANDARD LVCMOS25 [get_ports i_clk]
set_property PACKAGE_PIN Y9 [get_ports i_clk]

#btn
#S5
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS25} [get_ports {i_rst}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS25} [get_ports {i_load}]
#set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS25} [get_ports {i_load}]
#set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS25} [get_ports {i_load}]
#set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS25} [get_ports {i_load}]

#Switch
#SW1
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS25} [get_ports {i_en}]
#set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS25} [get_ports {i_en}]
#set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS25} [get_ports {i_d[1]}]
#set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS25} [get_ports {i_d[0]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS25} [get_ports {i_Cnt2_lim_up[3]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS25} [get_ports {i_Cnt2_lim_up[2]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS25} [get_ports {i_Cnt2_lim_up[1]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS25} [get_ports {i_Cnt2_lim_up[0]}]

#LED
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS25} [get_ports {o_led[7]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS25} [get_ports {o_led[6]}]
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS25} [get_ports {o_led[5]}]
set_property -dict {PACKAGE_PIN V22 IOSTANDARD LVCMOS25} [get_ports {o_led[4]}]

set_property -dict {PACKAGE_PIN U21  IOSTANDARD LVCMOS25} [get_ports {o_led[3]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS25} [get_ports {o_led[2]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS25} [get_ports {o_led[1]}]
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS25} [get_ports {o_led[0]}]
