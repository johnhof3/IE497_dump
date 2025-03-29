module udp_tx #(
    parameter int AXIS_DATA_WIDTH         = 32,
    parameter int ETH_HEADER_BYTES        = 14,
    parameter int IP_HEADER_BYTES         = 20,
    parameter int UDP_HEADER_BYTES        = 8,
    parameter int HEADER_BYTES            = 44,   // 14 + 20 + 8
    parameter int BYTES_PER_BEAT          = AXIS_DATA_WIDTH / 8,
    parameter int HEADER_WORDS            = HEADER_BYTES / BYTES_PER_BEAT,

    // Hardcoded fields for testing
    parameter logic [47:0] DEST_MAC       = 48'hdeadbeefcafe,
    parameter logic [47:0] SRC_MAC        = 48'h123456789abc,
    parameter logic [15:0] ETH_TYPE       = 16'h0800,            // IPv4

    parameter logic [7:0]  IP_VERSION     = 8'h45,               // IPv4 + IHL=5
    parameter logic [7:0]  IP_TOS         = 8'h00,
    parameter logic [15:0] IP_ID          = 16'h0000,
    parameter logic [15:0] IP_FLAGS_FRAG  = 16'h4000,            // Don't Fragment
    parameter logic [7:0]  IP_TTL         = 8'h40,
    parameter logic [7:0]  IP_PROTOCOL    = 8'h11,               // UDP
    parameter logic [15:0] IP_CHECKSUM    = 16'h0000,            // placeholder
    parameter logic [31:0] SRC_IP_ADDR    = 32'h0a000001,        // 10.0.0.1
    parameter logic [31:0] DST_IP_ADDR    = 32'h0a000002,        // 10.0.0.2

    parameter logic [15:0] SRC_PORT       = 16'd1234,
    parameter logic [15:0] DST_PORT       = 16'd5678,
    parameter logic [15:0] UDP_LENGTH     = 16'd32,              // header + payload
    parameter logic [15:0] UDP_CHECKSUM   = 16'h0000             // placeholder
) (
    input  logic                             clk,
    input  logic                             rst,

    // user payload input
    input  logic [AXIS_DATA_WIDTH-1:0]       s_axis_tdata,
    input  logic [AXIS_DATA_WIDTH/8-1:0]     s_axis_tkeep,
    input  logic                             s_axis_tvalid,
    output logic                             s_axis_tready,
    input  logic                             s_axis_tlast,

    // output AXI-S (prepends headers)
    output logic [AXIS_DATA_WIDTH-1:0]       m_axis_tdata,
    output logic [AXIS_DATA_WIDTH/8-1:0]     m_axis_tkeep,
    output logic                             m_axis_tvalid,
    input  logic                             m_axis_tready,
    output logic                             m_axis_tlast
);

    // ----------------------------------------
    // Byte offsets (aligned to mod-4)
    // ----------------------------------------

    localparam int ETH_DST_MAC_BYTE_OFFSET       = 0;
    localparam int ETH_SRC_MAC_BYTE_OFFSET       = 6;
    localparam int ETH_TYPE_BYTE_OFFSET          = 12;

    localparam int IP_VERSION_IHL_BYTE_OFFSET    = 14;
    localparam int IP_TOS_BYTE_OFFSET            = 15;
    localparam int IP_TOTAL_LENGTH_BYTE_OFFSET   = 16;
    localparam int IP_ID_BYTE_OFFSET             = 18;
    localparam int IP_FLAGS_FRAG_BYTE_OFFSET     = 20;
    localparam int IP_TTL_BYTE_OFFSET            = 22;
    localparam int IP_PROTOCOL_BYTE_OFFSET       = 23;
    localparam int IP_CHECKSUM_BYTE_OFFSET       = 24;
    localparam int IP_SRC_ADDR_BYTE_OFFSET       = 26;
    localparam int IP_DST_ADDR_BYTE_OFFSET       = 30;

    localparam int UDP_SRC_PORT_BYTE_OFFSET      = 34;
    localparam int UDP_DST_PORT_BYTE_OFFSET      = 36;
    localparam int UDP_LENGTH_BYTE_OFFSET        = 38;
    localparam int UDP_CHECKSUM_BYTE_OFFSET      = 40;

    // ----------------------------------------
    // user logic goes here
    // ----------------------------------------

    // suggestion: build a ROM of header words [0:HEADER_WORDS-1]
    // emit those first, then switch to streaming s_axis_* payload

endmodule