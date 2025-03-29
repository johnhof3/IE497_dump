module udp_rx #(
    parameter int AXIS_DATA_WIDTH     = 32,         // 32b = 4-byte beats
    parameter int ETH_HEADER_BYTES    = 14,
    parameter int IP_HEADER_BYTES     = 20,         // no IP options
    parameter int UDP_HEADER_BYTES    = 8,
    parameter int HEADER_BYTES        = 44          // 14 + 20 + 8, padded to 4-byte boundary
) (
    input  logic                             clk,
    input  logic                             rst,

    input  logic [AXIS_DATA_WIDTH-1:0]       s_axis_tdata,
    input  logic [AXIS_DATA_WIDTH/8-1:0]     s_axis_tkeep,
    input  logic                             s_axis_tvalid,
    output logic                             s_axis_tready,
    input  logic                             s_axis_tlast,

    output logic [AXIS_DATA_WIDTH-1:0]       m_axis_tdata,
    output logic [AXIS_DATA_WIDTH/8-1:0]     m_axis_tkeep,
    output logic                             m_axis_tvalid,
    input  logic                             m_axis_tready,
    output logic                             m_axis_tlast
);

    // ----------------------------------------
    // Offset helper function
    // ----------------------------------------
    function automatic logic [15:0] get_field_16 (
        input logic [31:0] data,
        input int          byte_offset_in_word
    );
        case (byte_offset_in_word)
            0: return data[15:0];
            1: return data[23:8];
            2: return data[31:16];
            default: return 16'hxxxx;
        endcase
    endfunction

    function automatic logic [7:0] get_field_8 (
        input logic [31:0] data,
        input int          byte_offset_in_word
    );
        case (byte_offset_in_word)
            0: return data[7:0];
            1: return data[15:8];
            2: return data[23:16];
            3: return data[31:24];
            default: return 8'hxx;
        endcase
    endfunction


    // ----------------------------------------
    // Byte-aligned header field offsets
    // ----------------------------------------

    // Ethernet header
    localparam int ETH_DST_MAC_BYTE_OFFSET       = 0;
    localparam int ETH_SRC_MAC_BYTE_OFFSET       = 6;
    localparam int ETH_TYPE_BYTE_OFFSET          = 12;

    // IP header (starts at byte 14)
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

    // UDP header (starts at byte 34)
    localparam int UDP_SRC_PORT_BYTE_OFFSET      = 34;
    localparam int UDP_DST_PORT_BYTE_OFFSET      = 36;
    localparam int UDP_LENGTH_BYTE_OFFSET        = 38;
    localparam int UDP_CHECKSUM_BYTE_OFFSET      = 40;

    // ----------------------------------------
    // Useful derived constants
    // ----------------------------------------

    localparam int BYTES_PER_BEAT   = AXIS_DATA_WIDTH / 8;
    localparam int HEADER_WORDS     = HEADER_BYTES / BYTES_PER_BEAT;
    localparam int HEADER_BITS      = HEADER_BYTES * 8;

    // ----------------------------------------
    // user logic here...
    // ----------------------------------------

endmodule