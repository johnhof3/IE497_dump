# GT reference clock (156.25 MHz differential) for QSFP0
set_property PACKAGE_PIN R10 [get_ports gt_ref_clk_0_clk_p]
set_property PACKAGE_PIN R9  [get_ports gt_ref_clk_0_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports gt_ref_clk_0_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports gt_ref_clk_0_clk_n]

create_clock -name gt_refclk -period 6.4 [get_ports gt_ref_clk_0_clk_p]

# 100 MHz system clk from onboard oscillator
set_property PACKAGE_PIN H16 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS18 [get_ports clk_100mhz]

create_clock -name sys_clk -period 10.0 [get_ports clk_100mhz]