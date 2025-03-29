module top()

  // mac axi tx (output from fifo)
  logic [31:0] eth_axis_tx_0_tdata;
  logic        eth_axis_tx_0_tvalid;
  logic        eth_axis_tx_0_tlast;
  logic [3:0]  eth_axis_tx_0_tkeep;
  logic        eth_axis_tx_0_tready;

  // udp tx axi to fifo
  logic [31:0] eth_axis_tx_0_tdata_to_fifo;
  logic        eth_axis_tx_0_tvalid_to_fifo;
  logic        eth_axis_tx_0_tlast_to_fifo;
  logic [3:0]  eth_axis_tx_0_tkeep_to_fifo;
  logic        eth_axis_tx_0_tready_to_fifo;

  // mac axi rx
  logic [31:0] eth_axis_rx_0_tdata;
  logic        eth_axis_rx_0_tvalid;
  logic        eth_axis_rx_0_tlast;
  logic [3:0]  eth_axis_rx_0_tkeep;
  logic        eth_axis_rx_0_tready;

  logic        rx_core_clk_0;
  logic        user_rx_reset_0;

  logic        tx_core_clk_0;

  ethernet_block_wrapper eth_inst (
    .axis_rx_0_0_tdata              (eth_axis_rx_0_tdata),
    .axis_rx_0_0_tkeep              (eth_axis_rx_0_tkeep),
    .axis_rx_0_0_tlast              (eth_axis_rx_0_tlast),
    .axis_rx_0_0_tuser              (eth_axis_rx_0_tuser),
    .axis_rx_0_0_tvalid             (eth_axis_rx_0_tvalid),

    .axis_tx_0_0_tdata              (eth_axis_tx_0_tdata),
    .axis_tx_0_0_tkeep              (eth_axis_tx_0_tkeep),
    .axis_tx_0_0_tlast              (eth_axis_tx_0_tlast),
    .axis_tx_0_0_tready             (eth_axis_tx_0_tready),
    .axis_tx_0_0_tuser              (eth_axis_tx_0_tuser),
    .axis_tx_0_0_tvalid             (eth_axis_tx_0_tvalid),

    .ctl_rx_0_0_ctl_rx_check_preamble     (1'b0),
    .ctl_rx_0_0_ctl_rx_check_sfd          (1'b0),
    .ctl_rx_0_0_ctl_rx_data_pattern_select(1'b0),
    .ctl_rx_0_0_ctl_rx_delete_fcs         (1'b0),
    .ctl_rx_0_0_ctl_rx_enable             (1'b1),
    .ctl_rx_0_0_ctl_rx_force_resync       (1'b0),
    .ctl_rx_0_0_ctl_rx_ignore_fcs         (1'b1),
    .ctl_rx_0_0_ctl_rx_max_packet_len     (16'h3fff),
    .ctl_rx_0_0_ctl_rx_min_packet_len     (16'h0040),
    .ctl_rx_0_0_ctl_rx_process_lfi        (1'b0),
    .ctl_rx_0_0_ctl_rx_test_pattern       (1'b0),
    .ctl_rx_0_0_ctl_rx_test_pattern_enable(1'b0),

    .ctl_rx_wdt_disable_0_0               (1'b1),

    .ctl_tx_0_0_ctl_tx_data_pattern_select(1'b0),
    .ctl_tx_0_0_ctl_tx_enable             (1'b1),
    .ctl_tx_0_0_ctl_tx_fcs_ins_enable     (1'b1),
    .ctl_tx_0_0_ctl_tx_ignore_fcs         (1'b0),
    .ctl_tx_0_0_ctl_tx_send_idle          (1'b0),
    .ctl_tx_0_0_ctl_tx_send_lfi           (1'b0),
    .ctl_tx_0_0_ctl_tx_send_rfi           (1'b0),
    .ctl_tx_0_0_ctl_tx_test_pattern       (1'b0),
    .ctl_tx_0_0_ctl_tx_test_pattern_enable(1'b0),
    .ctl_tx_0_0_ctl_tx_test_pattern_seed_a(58'd0),
    .ctl_tx_0_0_ctl_tx_test_pattern_seed_b(58'd0),
    .ctl_tx_0_0_ctl_tx_test_pattern_select(1'b0),

    .dclk_0                                (1'b0), // replace w/ real clock
    .gt_loopback_in_0_0                    (3'b000),

    .gt_ref_clk_0_clk_n                    (1'b0), // diff clock input
    .gt_ref_clk_0_clk_p                    (1'b0),

    .gt_refclk_out_0                       (),
    .gt_rx_0_gt_port_0_n                   (1'b0),
    .gt_rx_0_gt_port_0_p                   (1'b0),
    .gt_tx_0_gt_port_0_n                   (),
    .gt_tx_0_gt_port_0_p                   (),

    .gtpowergood_out_0_0                   (),
    .gtwiz_reset_rx_datapath_0_0           (1'b0),
    .gtwiz_reset_tx_datapath_0_0           (1'b0),
    .qpllreset_in_0_0                      (1'b0),

    .rx_clk_out_0_0                        (),
    .rx_core_clk_0_0                       (rx_core_clk_0),
    .rx_reset_0_0                          (),
    .rxoutclksel_in_0_0                    (3'b010),
    .rxrecclkout_0_0                       (),
    .stat_rx_status_0_0                    (),

    .sys_reset_0                           (1'b0),

    .tx_clk_out_0_0                        (tx_core_clk_0), // used in async fifo
    .tx_reset_0_0                          (),
    .tx_unfout_0_0                         (),
    .txoutclksel_in_0_0                    (3'b010),

    .user_rx_reset_0_0                     (user_rx_reset_0),
    .user_tx_reset_0_0                     (1'b0)
  );

  udp_top #(
    .AXIS_DATA_WIDTH(32),
    .AXIS_KEEP_WIDTH(4)
  ) udp_top_inst (
    .clk(rx_core_clk_0),
    .rst(user_rx_reset_0),

    // cmac rx interface
    .axis_rx_tdata(eth_axis_rx_0_tdata),
    .axis_rx_tkeep(eth_axis_rx_0_tkeep),
    .axis_rx_tvalid(eth_axis_rx_0_tvalid),
    .axis_rx_tready(eth_axis_rx_0_tready),
    .axis_rx_tlast(eth_axis_rx_0_tlast),
    .axis_rx_tuser(1'b0),

    // cmac tx interface
    .axis_tx_tdata(eth_axis_tx_0_tdata_to_fifo),
    .axis_tx_tkeep(eth_axis_tx_0_tkeep_to_fifo),
    .axis_tx_tvalid(eth_axis_tx_0_tvalid_to_fifo),
    .axis_tx_tready(eth_axis_tx_0_tready_to_fifo),
    .axis_tx_tlast(eth_axis_tx_0_tlast_to_fifo),
    .axis_tx_tuser(),

    // user rx output
    .axis_udp_rx_tdata(),
    .axis_udp_rx_tkeep(),
    .axis_udp_rx_tvalid(),
    .axis_udp_rx_tready(1'b1),
    .axis_udp_rx_tlast(),
    .axis_udp_rx_tuser(),

    // user tx input
    .axis_udp_tx_tdata(),
    .axis_udp_tx_tkeep(),
    .axis_udp_tx_tvalid(),
    .axis_udp_tx_tready(),
    .axis_udp_tx_tlast(),
    .axis_udp_tx_tuser()
  );

  // logic into regs

  // FINN core

  // TX frame builder

  // async fifo builder for input to mac
    async_fifo_wrapper tx_fifo_inst (
    .S_AXIS_0_tdata  (eth_axis_tx_0_tdata_to_fifo),
    .S_AXIS_0_tkeep  (eth_axis_tx_0_tkeep_to_fifo),
    .S_AXIS_0_tlast  (eth_axis_tx_0_tlast_to_fifo),
    .S_AXIS_0_tvalid (eth_axis_tx_0_tvalid_to_fifo),
    .S_AXIS_0_tready (eth_axis_tx_0_tready_to_fifo),

    .M_AXIS_0_tdata  (eth_axis_tx_0_tdata),
    .M_AXIS_0_tkeep  (eth_axis_tx_0_tkeep),
    .M_AXIS_0_tlast  (eth_axis_tx_0_tlast),
    .M_AXIS_0_tvalid (eth_axis_tx_0_tvalid),
    .M_AXIS_0_tready (eth_axis_tx_0_tready),

    .s_aclk_0        (rx_core_clk_0),
    .m_aclk_0        (tx_core_clk_0),
    .s_aresetn_0     (~user_rx_reset_0)
  );

endmodule
