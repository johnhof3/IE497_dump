module user_logic (
    input  wire         aclk,
    input  wire         aresetn,
    
    // RX AXI Stream interface (from MAC)
    input  wire [63:0]  s_axis_rx_tdata,
    input  wire [7:0]   s_axis_rx_tkeep,
    input  wire         s_axis_rx_tvalid,
    output wire         s_axis_rx_tready,
    input  wire         s_axis_rx_tlast,
    input  wire         s_axis_rx_tuser,
    
    // TX AXI Stream interface (to MAC)
    output wire [63:0]  m_axis_tx_tdata,
    output wire [7:0]   m_axis_tx_tkeep,
    output wire         m_axis_tx_tvalid,
    input  wire         m_axis_tx_tready,
    output wire         m_axis_tx_tlast,
    output wire         m_axis_tx_tuser
);

    // State machine states
    localparam IDLE = 2'b00;
    localparam MAC_ADDR = 2'b01;
    localparam PAYLOAD = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Registers to store MAC addresses
    reg [47:0] src_mac;
    reg [47:0] dst_mac;
    
    // Counter for MAC address bytes
    reg [2:0] mac_byte_cnt;
    
    // Buffer for output data
    reg [63:0] tx_data;
    reg [7:0]  tx_keep;
    reg        tx_valid;
    reg        tx_last;
    reg        tx_user;
    
    // State machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (s_axis_rx_tvalid && s_axis_rx_tready)
                    next_state = MAC_ADDR;
            end
            
            MAC_ADDR: begin
                if (mac_byte_cnt == 3'd5)
                    next_state = PAYLOAD;
            end
            
            PAYLOAD: begin
                if (s_axis_rx_tvalid && s_axis_rx_tready && s_axis_rx_tlast)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // MAC address handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mac_byte_cnt <= 3'd0;
            src_mac <= 48'd0;
            dst_mac <= 48'd0;
        end else begin
            case (state)
                IDLE: begin
                    mac_byte_cnt <= 3'd0;
                end
                
                MAC_ADDR: begin
                    if (s_axis_rx_tvalid && s_axis_rx_tready) begin
                        // First 6 bytes are destination MAC
                        if (mac_byte_cnt < 3'd6) begin
                            dst_mac <= {dst_mac[39:0], s_axis_rx_tdata[7:0]};
                        end
                        // Next 6 bytes are source MAC
                        else if (mac_byte_cnt < 3'd12) begin
                            src_mac <= {src_mac[39:0], s_axis_rx_tdata[7:0]};
                        end
                        
                        mac_byte_cnt <= mac_byte_cnt + 3'd1;
                    end
                end
                
                default: begin
                    // Do nothing in other states
                end
            endcase
        end
    end
    
    // Data path logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            tx_data <= 64'd0;
            tx_keep <= 8'd0;
            tx_valid <= 1'b0;
            tx_last <= 1'b0;
            tx_user <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx_valid <= 1'b0;
                end
                
                MAC_ADDR: begin
                    if (s_axis_rx_tvalid && s_axis_rx_tready) begin
                        tx_valid <= 1'b1;
                        
                        // For MAC address bytes, we need to swap src and dst
                        if (mac_byte_cnt < 3'd6) begin
                            // This is a destination MAC byte, replace with source MAC
                            tx_data <= {56'd0, src_mac[47 - mac_byte_cnt*8 -: 8]};
                            tx_keep <= 8'h01;
                        end else if (mac_byte_cnt < 3'd12) begin
                            // This is a source MAC byte, replace with destination MAC
                            tx_data <= {56'd0, dst_mac[47 - (mac_byte_cnt-6)*8 -: 8]};
                            tx_keep <= 8'h01;
                        end else begin
                            // Pass through the rest of the header
                            tx_data <= s_axis_rx_tdata;
                            tx_keep <= s_axis_rx_tkeep;
                        end
                        
                        tx_last <= 1'b0;
                        tx_user <= 1'b0;
                    end
                end
                
                PAYLOAD: begin
                    if (s_axis_rx_tvalid && s_axis_rx_tready) begin
                        tx_data <= s_axis_rx_tdata;
                        tx_keep <= s_axis_rx_tkeep;
                        tx_valid <= 1'b1;
                        tx_last <= s_axis_rx_tlast;
                        tx_user <= s_axis_rx_tuser;
                    end
                end
                
                default: begin
                    tx_valid <= 1'b0;
                end
            endcase
        end
    end
    
    // Output assignments
    assign m_axis_tx_tdata = tx_data;
    assign m_axis_tx_tkeep = tx_keep;
    assign m_axis_tx_tvalid = tx_valid;
    assign m_axis_tx_tlast = tx_last;
    assign m_axis_tx_tuser = tx_user;
    
    // Backpressure handling
    assign s_axis_rx_tready = (state == IDLE) || 
                             (state == MAC_ADDR) || 
                             (state == PAYLOAD && m_axis_tx_tready);
    
endmodule
