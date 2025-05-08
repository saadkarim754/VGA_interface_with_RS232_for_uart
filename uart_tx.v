module uart_tx_pattern(
    input clk,
    input rst,
    output reg tx,
    output reg busy,
    output reg [1:0] led // <-- Add 2-bit LED output
);
    parameter BAUD_TICK_COUNT = 434; // 115200 baud for 50 MHz clock
    parameter IDLE = 3'b000, START = 3'b001, DATA = 3'b010,
              STOP = 3'b011, CLEANUP = 3'b100;

    reg [2:0] state = IDLE;
    reg [7:0] tx_data; // <-- updated (was initialized earlier, now loaded dynamically)
    reg [2:0] bit_index = 0;
    reg [15:0] baud_counter = 0;
    reg wr_en = 0;
    reg [23:0] delay_counter = 0; // To auto-trigger tx periodically

    // ROM for string "saad is a good boy" + null terminator (or can repeat)
    reg [7:0] message [0:16];
    reg [4:0] char_index = 0; // to index up to 17 chars

    initial begin
        message[0]  = "s";
        message[1]  = "a";
        message[2]  = "a";
        message[3]  = "d";
        message[4]  = " ";
        message[5]  = "i";
        message[6]  = "s";
        message[7]  = " ";
        message[8]  = "a";
        message[9]  = " ";
        message[10] = "g";
        message[11] = "o";
        message[12] = "o";
        message[13] = "d";
        message[14] = " ";
        message[15] = "b";
		  message[16] = "o";
        message[17] = "y";
		  message[18] = " ";
		  message[19] = "\r";
        // optionally you can add newline or \r here if desired
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1'b1;
            busy <= 1'b0;
            baud_counter <= 0;
            bit_index <= 0;
            delay_counter <= 0;
            wr_en <= 0;
            led <= 2'b00;
            char_index <= 0;
        end else begin
            // Trigger a new transmission every ~0.1s
            if (state == IDLE && !busy) begin
                if (delay_counter < 5_000_000) begin
                    delay_counter <= delay_counter + 1;
                    wr_en <= 0;
                end else begin
                    wr_en <= 1;
                    delay_counter <= 0;
                end
            end

            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    busy <= 1'b0;
                    if (wr_en) begin
                        tx_data <= message[char_index]; // load next character
                        state <= START;
                        busy <= 1'b1;
                        wr_en <= 0;
                        led <= led + 1;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (baud_counter < BAUD_TICK_COUNT)
                        baud_counter <= baud_counter + 1;
                    else begin
                        baud_counter <= 0;
                        state <= DATA;
                        bit_index <= 0;
                    end
                end

                DATA: begin
                    tx <= tx_data[bit_index];
                    if (baud_counter < BAUD_TICK_COUNT)
                        baud_counter <= baud_counter + 1;
                    else begin
                        baud_counter <= 0;
                        if (bit_index < 7)
                            bit_index <= bit_index + 1;
                        else
                            state <= STOP;
                    end
                end

                STOP: begin
                    tx <= 1'b1;
                    if (baud_counter < BAUD_TICK_COUNT)
                        baud_counter <= baud_counter + 1;
                    else begin
                        baud_counter <= 0;
                        state <= CLEANUP;
                    end
                end

                CLEANUP: begin
                    // Move to next character
                    if (char_index < 16)
                        char_index <= char_index + 1;
                    else
                        char_index <= 0; // loop back to start
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
