`include "defines.v"
module ex (
    input wire rst,

    //id阶段送到ex阶段的信息
    input wire [`AluSelBus] alusel_i,
    input wire [ `AluOpBus] aluop_i,

    input wire [`RegBus] reg1_i,
    input wire [`RegBus] reg2_i,

    input wire wreg_i,
    input wire [`RegAddrBus] wd_i,
    input wire [`RegBus] inst_i,

    // 延迟槽-跳转信息
    input wire [`RegBus] link_address_i,

    // 送往mem阶段的信息
    output wire [`AluOpBus] aluop_o,
    output reg [  `RegBus] mem_addr_o,
    output reg [  `RegBus] reg2_o,

    //送往wb阶段的执行的结果
    output reg [`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg [`RegBus] wdata_o
);

  assign aluop_o = aluop_i; 

  //进行逻辑运算
  always @(*) begin
    if (rst == `RstEnable) begin
      wdata_o = `ZeroWord;
      wd_o = 5'b0;
      wreg_o  = `WriteDisable;
    end else begin
      wdata_o = `ZeroWord;
      wd_o = wd_i;
      wreg_o = wreg_i;
      case (aluop_i)
        `EXE_OR_OP: begin  // 逻辑或运算
          wdata_o = reg1_i | reg2_i;
        end
        `EXE_AND_OP: begin  // 逻辑与运算
          wdata_o = reg1_i & reg2_i;
        end
        `EXE_XOR_OP: begin  // 逻辑异或运算
          wdata_o = reg1_i ^ reg2_i;
        end
        `EXE_SLL_OP: begin
          wdata_o = reg2_i << reg1_i[4:0];
        end
        `EXE_SRL_OP: begin
          wdata_o = reg2_i >> reg1_i[4:0];
        end
        `EXE_SRA_OP: begin
          wdata_o = ($signed(reg2_i)) >>> reg1_i[4:0];
        end
        `EXE_SLT_OP: begin
          wdata_o = ($unsigned(reg1_i) < $unsigned(reg2_i)) ? 1 : 0;  // 比较运算
        end
        `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin
          wdata_o = reg1_i + reg2_i;  // 加法运算
        end
        `EXE_SUB_OP: begin
          wdata_o = reg1_i + (~reg2_i) + 1'b1;  // 减法运算
        end
        `EXE_MUL_OP: begin
          wdata_o = reg1_i * reg2_i;
        end
        `EXE_JAL_OP: begin
          wdata_o = link_address_i;
        end
        default: begin
        end
      endcase
    end
  end


  // 处理访存指令
  wire [31:0] imm_s = {{16{inst_i[15]}}, inst_i[15:0]};

  always @(*) begin
    if (rst == `RstEnable) begin
      mem_addr_o = `ZeroWord;
      reg2_o = `ZeroWord;
    end else begin
      case (aluop_i)
        `EXE_LB_OP: begin
          mem_addr_o = reg1_i + imm_s;
          reg2_o = `ZeroWord;
        end
        `EXE_LW_OP: begin
          mem_addr_o = reg1_i + imm_s;
          reg2_o = `ZeroWord;
        end
        `EXE_SB_OP: begin
          mem_addr_o = reg1_i + imm_s;
          reg2_o = reg2_i;
        end
        `EXE_SW_OP: begin
          mem_addr_o = reg1_i + imm_s;
          reg2_o = reg2_i;
        end
        default: begin
          mem_addr_o = `ZeroWord;
          reg2_o = `ZeroWord;
        end
      endcase
    end
  end

endmodule
