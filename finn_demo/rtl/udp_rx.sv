module udp_rx #(
    parameter int AXIS_DATA_WIDTH     = 32,         // 32b = 4-byte beats
    parameter int ETH_HEADER_BYTES    = 14,
    parameter int IP_HEADER_BYTES     = 20,         // no IP options
    parameter int UDP_HEADER_BYTES    = 8,
    parameter int HEADER_BYTES        = 44,         // 14 + 20 + 8, padded to 4-byte boundary

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
    // State Machine:
    // ----------------------------------------
    typedef enum logic [3:0] {
        IDLE,           // parse dst MAC[47:16] (bytes 0–3)

        ETH_HEAD_2,     // dst MAC[15:0], src MAC[47:32] (bytes 4–7)
        ETH_HEAD_3,     // src MAC[31:0]                (bytes 8–11)
        ETH_HEAD_4,     // ethertype + IP ver/IHL       (bytes 12–15)

        IP_HEAD_1,      // bytes 16–19
        IP_HEAD_2,
        IP_HEAD_3,
        IP_HEAD_4,
        IP_HEAD_5,

        UDP_HEAD_1,     // bytes 36–39
        UDP_HEAD_2,     // bytes 40–43

        DATA_PASSTHROUGH
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk) begin : state_transition
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ----------------------------------------
    // Parsing Logic
    // ----------------------------------------

    // hold invalid state until frame is done
    logic invalid_flag, invalid_flag_next;

    always_ff @(posedge clk) begin
        if (rst)
            invalid_flag <= 1'b0;
        else if (s_axis_tvalid && s_axis_tlast)
            invalid_flag <= 1'b0; // clear at end of frame
        else if (s_axis_tvalid)
            invalid_flag <= invalid_flag_next;
    end

    always_comb begin : fsm
        next_state = state;
        invalid_flag_next = invalid_flag;

        m_axis_tdata    = '0;
        m_axis_tkeep    = '0;
        m_axis_tvalid   = '0;
        m_axis_tlast    = '0;

        // TODO is this what we want?
        assign s_axis_tready = (state != IDLE) || (s_axis_tvalid && !invalid_flag);

        unique case (state)

            IDLE: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata == DEST_MAC[47:16])
                        next_state = ETH_HEAD_2;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            ETH_HEAD_2: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata[31:16] == DEST_MAC[15:0] && s_axis_tdata[15:0] == SRC_MAC[47:32])
                        next_state = ETH_HEAD_3;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            ETH_HEAD_3: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata == SRC_MAC[31:0])
                        next_state = ETH_HEAD_4;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            ETH_HEAD_4: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata[31:16] == ETH_TYPE && s_axis_tdata[15:8] == IP_VERSION && s_axis_tdata[7:0] == IP_TOS)
                        next_state = IP_HEAD_1;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            IP_HEAD_1: begin
                if (s_axis_tvalid)
                    next_state = IP_HEAD_2;
            end

            IP_HEAD_2: begin
                if (s_axis_tvalid)
                    next_state = IP_HEAD_3;
            end

            IP_HEAD_3: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata[31:24] == IP_TTL && s_axis_tdata[23:16] == IP_PROTOCOL)
                        next_state = IP_HEAD_4;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            IP_HEAD_4: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata == SRC_IP_ADDR)
                        next_state = IP_HEAD_5;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            IP_HEAD_5: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata == DST_IP_ADDR)
                        next_state = UDP_HEAD_1;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            UDP_HEAD_1: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata[31:16] == SRC_PORT && s_axis_tdata[15:0] == DST_PORT)
                        next_state = UDP_HEAD_2;
                    else
                        invalid_flag_next = 1'b1;
                end
            end
            // TODO actually check checksums this is invalid rn
            UDP_HEAD_2: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata[15:0] == UDP_CHECKSUM)
                        next_state = DATA_PASSTHROUGH;
                    else
                        invalid_flag_next = 1'b1;
                end
            end

            DATA_PASSTHROUGH: begin
                if(!invalid_flag) begin
                    // TODO ignoring tready for now
                    m_axis_tdata    = s_axis_tdata;
                    m_axis_tkeep    = s_axis_tkeep;
                    m_axis_tvalid   = s_axis_tvalid;
                    m_axis_tlast    = s_axis_tlast;
                end

                // I don't think we can get into data_passthrough when we have the invalid flag high, but here for redundancy rn
                if(s_axis_tlast || invalid_flag)
                    next_state = IDLE;
            end

            default: begin
                if (s_axis_tvalid)
                    next_state = IDLE;
            end

        endcase
    end
    
    
endmodule