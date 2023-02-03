module SRAM
#(
    parameter
        p_addr_bit      = 5,
        p_data_bit      = 32
)
(
    input                           CLK,
    input                           CEN,
    input                           WEN,
    input   [p_addr_bit-1:0]        A,
    input   [p_data_bit-1:0]        D,
    output  [p_data_bit-1:0]        Q
);

    localparam                p_memory_depth = 1<<p_addr_bit;
    // register files
    reg   [p_data_bit-1:0]    r_MEM[0:p_memory_depth-1];
    reg   [p_data_bit-1:0]    r_douta;
    always@(posedge CLK) 
        begin
            if (~CEN) 
                begin
                  if(WEN == 1'b1)
                    r_douta    <= r_MEM[A];
                  else
                    r_MEM[A]   <= D;
                end
        end
    assign Q = r_douta;
endmodule
