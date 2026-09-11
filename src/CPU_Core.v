// 8-bit RISC CPU core + memory-mapped peripherals
module CPU_Core (
    input         clk,
    input         rst,
    input  [15:0] instruction,
    output [7:0]  CPU_out,
    output [7:0]  peripheral_out
`ifdef FORMAL
    ,
    output         formal_state,
    output [7:0]   formal_pc,
    output [63:0]  formal_registers,
    output [127:0] formal_memory
`endif
);

    localparam EXECUTE_AND_RESULT = 1'b0;
    localparam SWITCH_TO_NEXTPC   = 1'b1;

    reg state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= SWITCH_TO_NEXTPC;
        else if (state == EXECUTE_AND_RESULT)
            state <= SWITCH_TO_NEXTPC;
        else
            state <= EXECUTE_AND_RESULT;
    end

    wire [15:0] current_instruction =
        (state == EXECUTE_AND_RESULT) ? instruction : 16'hF000;

    wire control_Mux_out_sig, PC_enable_sig, Branch_control_top;
    wire RegWrite_wire, ALUSrc_wire, MemWrite_wire, MemRead_wire;
    wire MemToReg_wire, Is_beq_wire, Is_bne_wire, Is_blt_wire;
    wire zero_wire, less_than_wire;

    wire [7:0] PC_top_wire, CPU_result_wire, PCplus4_Top;
    wire [7:0] SUM_top, PC_input_wire, Imm_Gen_out_wire;
    wire [7:0] Reg_data1_wire, Reg_data2_wire;
    wire [7:0] ALU_A_top, ALU_Mux_top, ALU_Top;
    wire [7:0] MemData_out_wire;
    wire [7:0] LoadData_wire;

    wire [2:0] ALUOp_wire;

    // Peripheral signals
    wire       is_mmio_wire;
    wire       uart_start_wire;
    wire       uart_tx_wire;
    wire       uart_busy_wire;
    wire       timer_enable_wire;
    wire [7:0] timer_count_wire;
    wire [7:0] gpio_out_wire;
    wire [1:0] output_mode_wire;
    wire [7:0] peripheral_read_wire;

    Program_Counter PC (
        .clk(clk),
        .rst(rst),
        .PC_enable_sig(PC_enable_sig),
        .PC_in(PC_input_wire),
        .PC_out(PC_top_wire)
    );

    PCplus4Adder PC_adder (
        .FromPC(PC_top_wire),
        .NextPC(PCplus4_Top)
    );

    Adder Jump_adder (
        .in_1(PC_top_wire),
        .in_2(Imm_Gen_out_wire),
        .Add_out(SUM_top)
    );

    Registers Registers (
        .clk(clk),
        .rst(rst),
        .RegWrite(RegWrite_wire),
        .rs1(current_instruction[8:6]),
        .rs2(current_instruction[5:3]),
        .rd(current_instruction[11:9]),
        .write_data(CPU_result_wire),
        .reg_data_1(Reg_data1_wire),
        .reg_data_2(Reg_data2_wire)
`ifdef FORMAL
        ,
        .formal_registers(formal_registers)
`endif
    );

    Control_Unit control_unit (
        .Instruction(current_instruction[15:12]),
        .funct3(current_instruction[2:0]),
        .Control_Mux_out_sig(control_Mux_out_sig),
        .PC_enable_sig(PC_enable_sig),
        .RegWrite(RegWrite_wire),
        .ALUSrc(ALUSrc_wire),
        .MemRead(MemRead_wire),
        .MemWrite(MemWrite_wire),
        .MemToReg(MemToReg_wire),
        .is_BEQ(Is_beq_wire),
        .is_BLT(Is_blt_wire),
        .is_BNE(Is_bne_wire),
        .ALUOp(ALUOp_wire)
    );

    Imm_Gen imm_gen (
        .Instruction(current_instruction),
        .Imm_Out(Imm_Gen_out_wire)
    );

    assign ALU_A_top =
        (current_instruction[15:12] == 4'b0010) ? 8'b0 : Reg_data1_wire;

    ALU ALU (
        .A(ALU_A_top),
        .B(ALU_Mux_top),
        .ALU_Op_in(ALUOp_wire),
        .zero(zero_wire),
        .less_than(less_than_wire),
        .ALU_result(ALU_Top)
    );

    Branch_Control branch_control (
        .is_beq(Is_beq_wire),
        .is_bne(Is_bne_wire),
        .is_blt(Is_blt_wire),
        .zero(zero_wire),
        .less_than(less_than_wire),
        .branch_control_top(Branch_control_top)
    );

    // Normal RAM occupies 0x00-0x0F.
    // MMIO occupies 0x10-0x1F.
    Data_Memory data_memory (
        .clk(clk),
        .rst(rst),
        .Address(ALU_Top),
        .PC_enable_sig(PC_enable_sig),
        .MemWrite(MemWrite_wire && !is_mmio_wire),
        .MemRead(MemRead_wire && !is_mmio_wire),
        .WriteData(Reg_data2_wire),
        .MemData_Out(MemData_out_wire)
`ifdef FORMAL
        ,
        .formal_memory(formal_memory)
`endif
    );

    Peripheral_Block peripherals (
        .clk(clk),
        .rst(rst),
        .address(ALU_Top),
        .mem_write(MemWrite_wire && PC_enable_sig && is_mmio_wire),
        .mem_read(MemRead_wire && is_mmio_wire),
        .write_data(Reg_data2_wire),
        .uart_busy(uart_busy_wire),
        .timer_count(timer_count_wire),
        .uart_start(uart_start_wire),
        .timer_enable(timer_enable_wire),
        .gpio_out(gpio_out_wire),
        .output_mode(output_mode_wire),
        .read_data(peripheral_read_wire),
        .is_mmio(is_mmio_wire)
    );

    UART_TX #(
        .CLKS_PER_BIT(87) // 10 MHz clock -> approximately 115200 baud
    ) uart_tx (
        .clk(clk),
        .rst(rst),
        .start(uart_start_wire),
        .data_in(Reg_data2_wire),
        .tx(uart_tx_wire),
        .busy(uart_busy_wire)
    );

    Timer timer (
        .clk(clk),
        .rst(rst),
        .enable(timer_enable_wire),
        .count(timer_count_wire)
    );

    assign LoadData_wire = is_mmio_wire ? peripheral_read_wire : MemData_out_wire;

    Mux1 Output_mux (
        .sel1(control_Mux_out_sig),
        .A1(PC_top_wire),
        .B1(CPU_result_wire),
        .mux1_out(CPU_out)
    );

    Mux1 Adder_Mux (
        .sel1(Branch_control_top),
        .A1(PCplus4_Top),
        .B1(SUM_top),
        .mux1_out(PC_input_wire)
    );

    Mux1 Data_memory_mux (
        .sel1(MemToReg_wire),
        .A1(ALU_Top),
        .B1(LoadData_wire),
        .mux1_out(CPU_result_wire)
    );

    Mux1 ALU_mux (
        .sel1(ALUSrc_wire),
        .A1(Reg_data2_wire),
        .B1(Imm_Gen_out_wire),
        .mux1_out(ALU_Mux_top)
    );

    // External output can be switched by software through MMIO 0x14.
    // 00 = normal CPU output, 01 = GPIO, 10 = UART TX, 11 = timer count.
    assign peripheral_out =
        (output_mode_wire == 2'b01) ? gpio_out_wire :
        (output_mode_wire == 2'b10) ? {7'b0, uart_tx_wire} :
        (output_mode_wire == 2'b11) ? timer_count_wire :
                                      CPU_out;

`ifdef FORMAL
    assign formal_state = state;
    assign formal_pc = PC_top_wire;
`endif

endmodule
