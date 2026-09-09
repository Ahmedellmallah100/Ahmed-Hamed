module ALU (ALU
    ALuResult, SrcA, SrcB, ALUControl, zero_flag, sign_flag
);

// Ports Declaration
input  [31:0] SrcA, SrcB;
input  [2:0]  ALUControl;
output reg [31:0] ALuResult;
output zero_flag, sign_flag;

// Logic for ALU operations
always @(*) begin
    case (ALUControl)
        3'b000: ALuResult = SrcA + SrcB;          // ADD
        3'b001: ALuResult = SrcA << SrcB[4:0];    // SHL
        3'b010: ALuResult = SrcA - SrcB;          // SUB
        3'b100: ALuResult = SrcA ^ SrcB;          // XOR
        3'b101: ALuResult = SrcA >> SrcB[4:0];    // SHR
        3'b110: ALuResult = SrcA | SrcB;          // OR
        3'b111: ALuResult = SrcA & SrcB;          // AND
        default: ALuResult = 32'b0;
    endcase
 end

assign zero_flag = (ALuResult == 32'b0);
assign sign_flag = ALuResult[31];

endmodule  // ALU
