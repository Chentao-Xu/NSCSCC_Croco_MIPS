`include "defines.v"
//暂时保存取值阶段取得的指令
module if_id (
    input wire clk,
    input wire rst,
    //来自取指阶段的信号，其中宏定义InstBus表示指令宽度，为32
    input wire [`InstAddrBus] if_pc,
    input wire [`InstBus] if_inst,
    input wire [5:0] stall,

    //对应译码阶段的信号
    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
);

  always @(posedge clk) begin
    if (rst == `RstEnable) begin
      id_pc   <= `ZeroWord;  // 复位的时候pc为0
      id_inst <= `ZeroWord;  // 复位的时候指令也为0，实际就是空指令
    end else if (stall[1] == `Stop && stall[2] == `NoStop)begin
      id_pc <= `ZeroWord;
      id_inst <= `ZeroWord;
    end else if (stall[1] == `NoStop) begin
      id_pc   <= if_pc;
      id_inst <= if_inst;
    end
  end

endmodule
