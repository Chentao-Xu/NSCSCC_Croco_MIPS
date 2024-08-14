`include "defines.v"
//给出指令地址
module pc_reg (
    input wire clk,
    input wire rst,

    input wire branch_flag_i,
    input wire [`RegBus] branch_target_address_i,
    
    input wire [5:0] stall,

    output reg [`InstAddrBus] pc,
    output reg ce
);

  wire [`InstAddrBus] next_pc;
  wire [`InstAddrBus] seq_pc;

  always @(posedge clk) begin
    if (rst == `RstEnable) begin
      ce <= `ChipDisable;
    end else begin
      ce <= `ChipEnable;
    end
  end

  always @(posedge clk) begin
    if (ce == `ChipDisable) begin
      pc <= 32'h80000000;
    end else if (stall[0] == `NoStop) begin
      pc <= next_pc;
    end
  end

  assign seq_pc = pc + 32'h4;
  assign next_pc = branch_flag_i ? branch_target_address_i : seq_pc;

endmodule
