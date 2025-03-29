module udp_rx #(
    parameter int AXIS_DATA_WIDTH = 32,
    parameter int HEADER_BYTES    = 28            // number of header bytes to strip (ETH+IP+UDP)
) (
    input  logic                             clk,
    input  logic                             rst,

    // AXI-S input (from udp_rx, includes ETH+IP+UDP headers)
    input  logic [AXIS_DATA_WIDTH-1:0]       s_axis_tdata,   // input data
    input  logic [AXIS_DATA_WIDTH/8-1:0]     s_axis_tkeep,   // byte-valid indicator
    input  logic                             s_axis_tvalid,  // input valid
    output logic                             s_axis_tready,  // input ready
    input  logic                             s_axis_tlast,   // input frame boundary

    // AXI-S output (realigned UDP payload, no headers)
    output logic [AXIS_DATA_WIDTH-1:0]       m_axis_tdata,   // output data (realigned)
    output logic [AXIS_DATA_WIDTH/8-1:0]     m_axis_tkeep,   // valid bytes in output beat
    output logic                             m_axis_tvalid,  // output valid
    input  logic                             m_axis_tready,  // output ready
    output logic                             m_axis_tlast    // output frame boundary
);

    // -------------------------------------------------------------
    // implementation notes:
    // - beat 0: contains headers and possibly first part of payload
    //   - discard first HEADER_BYTES
    //   - store remaining data (payload fragment) in buffer
    //   - do NOT assert m_axis_tvalid in this cycle
    //
    // - beat 1: combine buffered data with next beat to emit aligned
    //   - output m_axis_tvalid
    //   - update tkeep based on how many payload bytes available
    //
    // - subsequent beats: pass through remaining payload with adjusted alignment
    //   - track and handle cross-beat boundaries if alignment causes spill
    //
    // - special case: if entire payload fits in beat 0 (tlast=1), output one aligned beat
    //
    // required state:
    // - FSM (IDLE, PARSE, EMIT, STREAM)
    // - buffer for partial word
    // - alignment offset (HEADER_BYTES % 64)
    // - byte counter (optional)
    // -------------------------------------------------------------

    // IP Header (IPv4, 20 bytes, no options)
    localparam int IP_VERSION_IHL_OFFSET    = 14*8 +  0;  // 1 byte
    localparam int IP_TOS_OFFSET            = 14*8 +  8;  // 1 byte
    localparam int IP_TOTAL_LENGTH_OFFSET   = 14*8 + 16;  // 2 bytes
    localparam int IP_ID_OFFSET             = 14*8 + 32;  // 2 bytes
    localparam int IP_FLAGS_FRAG_OFFSET     = 14*8 + 48;  // 2 bytes
    localparam int IP_TTL_OFFSET            = 14*8 + 64;  // 1 byte
    localparam int IP_PROTOCOL_OFFSET       = 14*8 + 72;  // 1 byte
    localparam int IP_CHECKSUM_OFFSET       = 14*8 + 80;  // 2 bytes
    localparam int IP_SRC_ADDR_OFFSET       = 14*8 + 96;  // 4 bytes
    localparam int IP_DST_ADDR_OFFSET       = 14*8 + 128; // 4 bytes

    // UDP Header (8 bytes)
    localparam int UDP_SRC_PORT_OFFSET      = 14*8 + 160; // 2 bytes
    localparam int UDP_DST_PORT_OFFSET      = 14*8 + 176; // 2 bytes
    localparam int UDP_LENGTH_OFFSET        = 14*8 + 192; // 2 bytes
    localparam int UDP_CHECKSUM_OFFSET      = 14*8 + 208; // 2 bytes

    // Useful calculated values
    localparam int ETH_HEADER_BYTES         = 14;
    localparam int IP_HEADER_BYTES          = 20;
    localparam int UDP_HEADER_BYTES         = 8;
    localparam int HEADER_BYTES_TOTAL       = ETH_HEADER_BYTES + IP_HEADER_BYTES + UDP_HEADER_BYTES;

    localparam int HEADER_BITS_TOTAL        = HEADER_BYTES_TOTAL * 8;
    localparam int ALIGNMENT_BITS           = HEADER_BITS_TOTAL % AXIS_DATA_WIDTH;
    localparam int ALIGNMENT_BYTES          = HEADER_BYTES_TOTAL % (AXIS_DATA_WIDTH / 8);

    logic prev_input_valid;

    always_ff @(posedge clk) begin
        if(rst) begin
            prev_input_valid <= '0;
        end

        prev_input_valid    <= s_axis_tvalid;

        if(prev_input_valid == 1'b0 && s_axis_tvalid == 1'b1) begin
            buffer_1        <= s_axis_tdata[512-(HEADER_BYTES*8):0]; // todo, if first frame doesn't use whole input need to only store tkeep, maybe have a valid byte array for stored regs
            // check valid input packet
            if()
                buffer_1_valid  <= '0;
            else
                buffer_1_valid  <= m_axis_tkeep[(AXIS_DATA_WIDTH/8) - HEADER_BYTES:0];
        end
    end
        

endmodule