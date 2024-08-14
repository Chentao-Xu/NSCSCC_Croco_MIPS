`include "defines.v"
module mem (
    input wire rst,

    // 来自执行阶段的信息
    input wire [`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire [`RegBus] wdata_i,

    input wire [`AluOpBus] aluop_i,
    input wire [  `RegBus] mem_addr_i,
    input wire [  `RegBus] reg2_i,

    // 来自数据存储器的信息
    input wire [`RegBus] mem_data_i,

    // 访存阶段的结果
    output reg wreg_o,
    output reg [`RegAddrBus] wd_o,
    output reg [`RegBus] wdata_o,

    //送到数据存储器的数据
    output reg [`RegBus] mem_addr_o,
    output reg [`RegBus] mem_data_o,
    output wire mem_we_o,

    output reg [3:0] mem_sel_o,
    output reg mem_ce_o,

    output wire stallreq
);

  assign stallreq = (mem_addr_i >= 32'h80000000) && (mem_addr_i < 32'h80400000);

  wire [`RegBus] zero32;
  reg mem_we;

  // DRAM的读写信号
  assign mem_we_o = mem_we;

  assign zero32   = `ZeroWord;

  always @(*) begin
    if (rst == `RstEnable) begin
      wd_o = `NOPRegAddr;
      wreg_o = `WriteDisable;
      wdata_o = `ZeroWord;

      mem_addr_o = `ZeroWord;
      mem_we = !`WriteDisable;
      mem_sel_o = 4'b1111;
      mem_data_o = `ZeroWord;
      mem_ce_o = `ChipDisable;
    end else begin
      wd_o = wd_i;
      wreg_o = wreg_i;
      wdata_o = wdata_i;
      mem_we = !`WriteDisable;
      mem_addr_o = `ZeroWord;
      mem_sel_o = 4'b1111;
      mem_ce_o = `ChipDisable;

      case (aluop_i)
        `EXE_LB_OP: begin  // lb指令
          mem_addr_o = mem_addr_i;
          wdata_o = mem_data_i;
          mem_we = !`WriteDisable;
          mem_ce_o = `ChipEnable;
          case (mem_addr_i[1:0])
            2'b00: begin
              mem_sel_o = 4'b1110;
            end
            2'b01: begin
              mem_sel_o = 4'b1101;
            end
            2'b10: begin
              mem_sel_o = 4'b1011;
            end
            2'b11: begin
              mem_sel_o = 4'b0111;
            end
            default: begin
              mem_sel_o = 4'b1111;
            end
          endcase
        end

        `EXE_LW_OP: begin  // lw指令
          mem_addr_o = mem_addr_i;
          mem_we = !`WriteDisable;
          wdata_o = mem_data_i;
          mem_sel_o = 4'b0000;
          mem_ce_o = `ChipEnable;
        end

        `EXE_SB_OP: begin  // sb指令
          wdata_o = `ZeroWord;
          mem_addr_o = mem_addr_i;
          mem_we = !`WriteEnable;
          mem_data_o = {4{reg2_i[7:0]}};
          mem_ce_o = `ChipEnable;
          case (mem_addr_i[1:0])
            2'b00: begin
              mem_sel_o = 4'b1110;
            end
            2'b01: begin
              mem_sel_o = 4'b1101;
            end
            2'b10: begin
              mem_sel_o = 4'b1011;
            end
            2'b11: begin
              mem_sel_o = 4'b0111;
            end
            default: begin
              mem_sel_o = 4'b1111;
            end
          endcase
        end

        `EXE_SW_OP: begin  //sw指令
          wdata_o = `ZeroWord;
          mem_addr_o = mem_addr_i;
          mem_we = !`WriteEnable;
          mem_data_o = reg2_i;
          mem_sel_o = 4'b0000;
          mem_ce_o = `ChipEnable;
        end

        default: begin
        end

      endcase
    end
  end

endmodule
