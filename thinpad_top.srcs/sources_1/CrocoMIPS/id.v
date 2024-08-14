`include "defines.v"
module id (
    input wire rst,
    input wire [`InstAddrBus] pc_i,
    input wire [`InstBus] inst_i,

    //输出到regfile的信息
    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg [`RegAddrBus] reg1_addr_o,
    output reg [`RegAddrBus] reg2_addr_o,

    //读取regfile的输出
    input wire [`RegBus] reg1_data_i,
    input wire [`RegBus] reg2_data_i,

    //执行阶段指令的运算结果
    input wire ex_wreg_i,
    input wire [`RegBus] ex_wdata_i,
    input wire [`RegAddrBus] ex_addr_i,
    input wire [`AluOpBus] ex_aluop_i,

    //处于访存阶段的指令运算结果
    input wire mem_wreg_i,
    input wire [`RegBus] mem_wdata_i,
    input wire [`RegAddrBus] mem_addr_i,

    //送到执行阶段的信信息
    output reg [`AluOpBus] aluop_o,
    output reg [`AluSelBus] alusel_o,
    output reg [`RegBus] reg1_o,
    output reg [`RegBus] reg2_o,
    output reg [`RegAddrBus] wd_o,
    output reg wreg_o,

    //送回到取址阶段的跳转信息
    output reg branch_flag_o,
    output reg [`RegBus] branch_target_address_o,

    output reg  [`RegBus] link_addr_o,
    output wire [`RegBus] inst_o,

    //流水线暂停请求
    output wire stallreq
);

  //取得指令的功能码
  wire [5:0] op = inst_i[31:26];
  wire [4:0] op2 = inst_i[10:6];
  wire [5:0] op3 = inst_i[5:0];
  wire [4:0] op4 = inst_i[20:16];

  //保存指令执行要的立即数
  reg [`RegBus] imm;

  //指令是否有效
  reg instvalid;

  //reg1是否与上一条指令存在load相关
  reg stallreq_for_reg1_loadrelate;

  //reg2是否与上一条指令存在load相关
  reg stallreq_for_reg2_loadrelate;

  //上一条是否是load
  wire pre_inst_is_load;

  assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
                            (ex_aluop_i == `EXE_LW_OP))
                            ? 1'b1 : 1'b0;

  assign stallreq = stallreq_for_reg1_loadrelate || stallreq_for_reg2_loadrelate;

  wire [`RegBus] pc_plus_8;
  wire [`RegBus] pc_plus_4;

  wire [`RegBus] imm_sll2_signedext;

  assign pc_plus_8 = pc_i + 8;
  assign pc_plus_4 = pc_i + 4;

  assign inst_o = inst_i;

  //对应分支指令offset左移两位再符号扩展至32位
  assign imm_sll2_signedext = {{14{inst_i[15]}}, {inst_i[15:0]}, 2'b00};

  /****************************************************************
*********** 第一段：对指令进行译码 *********
*****************************************************************/

  always @(*) begin
    if (rst == `RstEnable) begin
      aluop_o = `EXE_NOP_OP;
      alusel_o = `EXE_RES_NOP;
      wd_o = `NOPRegAddr;
      wreg_o = `WriteDisable;
      instvalid = `InstValid;
      reg1_read_o = 1'b0;
      reg2_read_o = 1'b0;
      reg1_addr_o = `NOPRegAddr;
      reg2_addr_o = `NOPRegAddr;
      imm = 32'h0;
      link_addr_o = `ZeroWord;
      branch_target_address_o = `ZeroWord;
      branch_flag_o = `NotBranch;
    end else begin
      aluop_o = `EXE_NOP_OP;
      alusel_o = `EXE_RES_NOP;
      wd_o = inst_i[15:11];
      wreg_o = `WriteDisable;
      instvalid = `InstInvalid;
      reg1_read_o = 1'b0;
      reg2_read_o = 1'b0;
      reg1_addr_o = inst_i[25:21];
      reg2_addr_o = inst_i[20:16];
      imm = `ZeroWord;
      link_addr_o = `ZeroWord;
      branch_flag_o = `NotBranch;
      branch_target_address_o = `ZeroWord;
      case (op)
        `EXE_SPECIAL_INST: begin
          case (op2)
            5'b00000: begin
              case (op3)
                `EXE_OR: begin  //or指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_OR_OP;
                  alusel_o = `EXE_RES_LOGIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_AND: begin  //and指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_AND_OP;
                  alusel_o = `EXE_RES_LOGIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_XOR: begin  //xor指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_XOR_OP;
                  alusel_o = `EXE_RES_LOGIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_SLLV: begin  //sllv指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_SLL_OP;
                  alusel_o = `EXE_RES_SHIFT;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_SRLV: begin  //srlv指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_SRL_OP;
                  alusel_o = `EXE_RES_SHIFT;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_SRAV: begin  //srav指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_SRA_OP;
                  alusel_o = `EXE_RES_SHIFT;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_SLT: begin  // slt指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_SLT_OP;
                  alusel_o = `EXE_RES_ARITHMETIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_ADD: begin  // add指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_ADD_OP;
                  alusel_o = `EXE_RES_ARITHMETIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_ADDU: begin  // addu指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_ADDU_OP;
                  alusel_o = `EXE_RES_ARITHMETIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_SUB: begin  // sub指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_SUB_OP;
                  alusel_o = `EXE_RES_ARITHMETIC;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b1;
                  instvalid = `InstValid;
                end

                `EXE_JR: begin  // jr指令
                  wreg_o = `WriteDisable;
                  aluop_o = `EXE_JR_OP;
                  alusel_o = `EXE_RES_JUMP_BRANCH;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b0;
                  link_addr_o = `ZeroWord;
                  branch_target_address_o = reg1_o;
                  branch_flag_o = `Branch;
                  instvalid = `InstValid;
                end

                `EXE_JALR: begin  // jalr指令
                  wreg_o = `WriteEnable;
                  aluop_o = `EXE_JALR_OP;
                  alusel_o = `EXE_RES_JUMP_BRANCH;
                  reg1_read_o = 1'b1;
                  reg2_read_o = 1'b0;
                  wd_o = inst_i[15:11];
                  link_addr_o = pc_plus_8;
                  branch_target_address_o = reg1_o;
                  branch_flag_o = `Branch;
                  instvalid = `InstValid;
                end

                default: begin
                end
              endcase  // end case op3
            end
            default: begin
            end
          endcase  // end case op2
        end

        `EXE_ORI: begin  //ori指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_OR_OP;
          alusel_o = `EXE_RES_LOGIC;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          imm = {16'h0, inst_i[15:0]};
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end

        `EXE_ANDI: begin  //andi指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_AND_OP;
          alusel_o = `EXE_RES_LOGIC;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          imm = {16'h0, inst_i[15:0]};
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end

        `EXE_XORI: begin  //xori指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_XOR_OP;
          alusel_o = `EXE_RES_LOGIC;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          imm = {16'h0, inst_i[15:0]};
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end

        `EXE_LUI: begin  //lui指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_OR_OP;
          alusel_o = `EXE_RES_LOGIC;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          imm = {inst_i[15:0], 16'h0};
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end


        `EXE_ADDI: begin  // addi指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_ADDI_OP;
          alusel_o = `EXE_RES_ARITHMETIC;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          imm = {{16{inst_i[15]}}, inst_i[15:0]};
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end

        `EXE_ADDIU: begin  // addiu指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_ADDIU_OP;
          alusel_o = `EXE_RES_ARITHMETIC;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          imm = {{16{inst_i[15]}}, inst_i[15:0]};
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end

        `EXE_J: begin  // j指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_J_OP;
          alusel_o = `EXE_RES_JUMP_BRANCH;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b0;
          link_addr_o = `ZeroWord;
          branch_flag_o = `Branch;
          instvalid = `InstValid;
          branch_target_address_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
        end

        `EXE_JAL: begin  // jal指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_JAL_OP;
          alusel_o = `EXE_RES_JUMP_BRANCH;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b0;
          wd_o = 5'b11111;
          link_addr_o = pc_plus_8;
          branch_flag_o = `Branch;
          instvalid = `InstValid;
          branch_target_address_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
        end

        `EXE_BEQ: begin  // beq指令
          wreg_o = `WriteDisable;
          aluop_o = `EXE_BEQ_OP;
          alusel_o = `EXE_RES_JUMP_BRANCH;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b1;
          instvalid = `InstValid;
          if (reg1_o == reg2_o) begin
            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
            branch_flag_o = `Branch;
          end
        end

        `EXE_BGTZ: begin  // bgtz指令
          wreg_o = `WriteDisable;
          aluop_o = `EXE_BGTZ_OP;
          alusel_o = `EXE_RES_JUMP_BRANCH;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          instvalid = `InstValid;
          if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
            branch_flag_o = `Branch;
          end
        end

        `EXE_BLEZ: begin  // blez指令
          wreg_o = `WriteDisable;
          aluop_o = `EXE_BLEZ_OP;
          alusel_o = `EXE_RES_JUMP_BRANCH;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          instvalid = `InstValid;
          if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
            branch_flag_o = `Branch;
          end
        end

        `EXE_BNE: begin  // bne指令
          wreg_o = `WriteDisable;
          aluop_o = `EXE_BLEZ_OP;
          alusel_o = `EXE_RES_JUMP_BRANCH;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b1;
          instvalid = `InstValid;
          if (reg1_o != reg2_o) begin
            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
            branch_flag_o = `Branch;
          end
        end

        `EXE_REGIMM_INST: begin
          case (op4)
            `EXE_BGEZ: begin  // bgez指令
              wreg_o = `WriteDisable;
              aluop_o = `EXE_BGEZ_OP;
              alusel_o = `EXE_RES_JUMP_BRANCH;
              reg1_read_o = 1'b1;
              reg2_read_o = 1'b0;
              instvalid = `InstValid;
              if (reg1_o[31] == 1'b0) begin
                branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                branch_flag_o = `Branch;
              end
            end

            `EXE_BLTZ: begin  // bltz指令
              wreg_o = `WriteDisable;
              aluop_o = `EXE_BLTZ_OP;
              alusel_o = `EXE_RES_JUMP_BRANCH;
              reg1_read_o = 1'b1;
              reg2_read_o = 1'b0;
              instvalid = `InstValid;
              if (reg1_o[31] == 1'b1) begin
                branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                branch_flag_o = `Branch;
              end
            end

            default: begin
            end
          endcase
        end

        `EXE_SPECIAL2_INST: begin  // op等于SPECIAL2
          case (op3)
            `EXE_MUL: begin  // mul指令
              wreg_o = `WriteEnable;
              aluop_o = `EXE_MUL_OP;
              alusel_o = `EXE_RES_MUL;
              reg1_read_o = 1'b1;
              reg2_read_o = 1'b1;
              instvalid = `InstValid;
            end

            default: begin
            end
          endcase  // end case op3
        end

        `EXE_LB: begin  // lb指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_LB_OP;
          alusel_o = `EXE_RES_LOAD_STORE;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end


        `EXE_LW: begin  // lw指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_LW_OP;
          alusel_o = `EXE_RES_LOAD_STORE;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b0;
          wd_o = inst_i[20:16];
          instvalid = `InstValid;
        end

        `EXE_SB: begin  // sb指令
          wreg_o = `WriteDisable;
          aluop_o = `EXE_SB_OP;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b1;
          instvalid = `InstValid;
          alusel_o = `EXE_RES_LOAD_STORE;
        end

        `EXE_SW: begin  // sw指令
          wreg_o = `WriteDisable;
          aluop_o = `EXE_SW_OP;
          reg1_read_o = 1'b1;
          reg2_read_o = 1'b1;
          instvalid = `InstValid;
          alusel_o = `EXE_RES_LOAD_STORE;
        end

        default: begin
        end
      endcase  // end case op

      if (inst_i[31:21] == 11'b00000000000) begin

        if (op3 == `EXE_SLL) begin  //sll指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_SLL_OP;
          alusel_o = `EXE_RES_SHIFT;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b1;
          imm[4:0] = inst_i[10:6];
          wd_o = inst_i[15:11];
          instvalid = `InstValid;

        end else if (op3 == `EXE_SRL) begin  //srl指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_SRL_OP;
          alusel_o = `EXE_RES_SHIFT;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b1;
          imm[4:0] = inst_i[10:6];
          wd_o = inst_i[15:11];
          instvalid = `InstValid;

        end else if (op3 == `EXE_SRA) begin  //sra指令
          wreg_o = `WriteEnable;
          aluop_o = `EXE_SRA_OP;
          alusel_o = `EXE_RES_SHIFT;
          reg1_read_o = 1'b0;
          reg2_read_o = 1'b1;
          imm[4:0] = inst_i[10:6];
          wd_o = inst_i[15:11];
          instvalid = `InstValid;
        end
      end
    end
  end


  /****************************************************************
*********** 第二段：确定进行运算的源操作数1 *********
*****************************************************************/

  always @(*) begin
    if (rst == `RstEnable) begin
      reg1_o = `ZeroWord;
    end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_addr_i == reg1_addr_o)) begin
      reg1_o = ex_wdata_i;
    end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_addr_i == reg1_addr_o)) begin
      reg1_o = mem_wdata_i;
    end else if (reg1_read_o == 1'b1) begin
      reg1_o = reg1_data_i;
    end else if (reg1_read_o == 1'b0) begin
      reg1_o = imm;
    end else begin
      reg1_o = `ZeroWord;
    end
  end

  always @(*) begin
    if (pre_inst_is_load == 1'b1 && ex_addr_i == reg1_addr_o && reg1_read_o == 1'b1) begin
      stallreq_for_reg1_loadrelate = `Stop;
    end else begin
      stallreq_for_reg1_loadrelate = `NoStop;
    end
  end

  /****************************************************************
*********** 第二段：确定进行运算的源操作数2 *********
*****************************************************************/

  always @(*) begin
    if (rst == `RstEnable) begin
      reg2_o = `ZeroWord;
    end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_addr_i == reg2_addr_o)) begin
      reg2_o = ex_wdata_i;
    end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_addr_i == reg2_addr_o)) begin
      reg2_o = mem_wdata_i;
    end else if (reg2_read_o == 1'b1) begin
      reg2_o = reg2_data_i;
    end else if (reg2_read_o == 1'b0) begin
      reg2_o = imm;
    end else begin
      reg2_o = `ZeroWord;
    end
  end

  always @(*) begin
    if (pre_inst_is_load == 1'b1 && ex_addr_i == reg2_addr_o && reg2_read_o == 1'b1) begin
      stallreq_for_reg2_loadrelate = `Stop;
    end else begin
      stallreq_for_reg2_loadrelate = `NoStop;
    end
  end


endmodule
