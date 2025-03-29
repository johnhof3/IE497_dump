module udp_top #
(
    // this assumes 312MHz, 32 bit width
    parameter integer AXIS_DATA_WIDTH = 32,
    parameter integer AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8
)
(
    input  wire                          clk,
    input  wire                          rst,

    // cmac rx interface
    input  wire [AXIS_DATA_WIDTH-1:0]   axis_rx_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]   axis_rx_tkeep,
    input  wire                          axis_rx_tvalid,
    output wire                          axis_rx_tready,
    input  wire                          axis_rx_tlast,
    input  wire                          axis_rx_tuser,

    // cmac tx interface
    output wire [AXIS_DATA_WIDTH-1:0]   axis_tx_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]   axis_tx_tkeep,
    output wire                          axis_tx_tvalid,
    input  wire                          axis_tx_tready,
    output wire                          axis_tx_tlast,
    output wire                          axis_tx_tuser,

    // user rx output (parsed udp payload)
    output wire [AXIS_DATA_WIDTH-1:0]   axis_udp_rx_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]   axis_udp_rx_tkeep,
    output wire                          axis_udp_rx_tvalid,
    input  wire                          axis_udp_rx_tready,
    output wire                          axis_udp_rx_tlast,
    output wire                          axis_udp_rx_tuser,

    // user tx input (raw udp payload to transmit)
    input  wire [AXIS_DATA_WIDTH-1:0]   axis_udp_tx_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0]   axis_udp_tx_tkeep,
    input  wire                          axis_udp_tx_tvalid,
    output wire                          axis_udp_tx_tready,
    input  wire                          axis_udp_tx_tlast,
    input  wire                          axis_udp_tx_tuser
);

    // rx path
    udp_rx #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
    ) udp_rx_inst (
        .clk(clk),
        .rst(rst),

        .axis_rx_tdata(axis_rx_tdata),
        .axis_rx_tkeep(axis_rx_tkeep),
        .axis_rx_tvalid(axis_rx_tvalid),
        .axis_rx_tready(axis_rx_tready),
        .axis_rx_tlast(axis_rx_tlast),
        .axis_rx_tuser(axis_rx_tuser),

        .axis_udp_tdata(axis_udp_rx_tdata),
        .axis_udp_tkeep(axis_udp_rx_tkeep),
        .axis_udp_tvalid(axis_udp_rx_tvalid),
        .axis_udp_tready(axis_udp_rx_tready),
        .axis_udp_tlast(axis_udp_rx_tlast),
        .axis_udp_tuser(axis_udp_rx_tuser)
    );

    // tx path
    udp_tx #(
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
    ) udp_tx_inst (
        .clk(clk),
        .rst(rst),

        .axis_udp_tdata(axis_udp_tx_tdata),
        .axis_udp_tkeep(axis_udp_tx_tkeep),
        .axis_udp_tvalid(axis_udp_tx_tvalid),
        .axis_udp_tready(axis_udp_tx_tready),
        .axis_udp_tlast(axis_udp_tx_tlast),
        .axis_udp_tuser(axis_udp_tx_tuser),

        .axis_tx_tdata(axis_tx_tdata),
        .axis_tx_tkeep(axis_tx_tkeep),
        .axis_tx_tvalid(axis_tx_tvalid),
        .axis_tx_tready(axis_tx_tready),
        .axis_tx_tlast(axis_tx_tlast),
        .axis_tx_tuser(axis_tx_tuser)
    );

endmodule