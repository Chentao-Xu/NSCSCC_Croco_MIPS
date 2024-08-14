//******************* 全 局 的 宏 定 义 ***************************
`define RstEnable 1'b1 //复位信号有效
`define RstDisable 1'b0 //复位信号无效
`define ZeroWord 32'h00000000 //32位的数值0
`define WriteEnable 1'b1 //写使能
`define WriteEnable_n 1'b0 //写使能低有效
`define WriteDisable 1'b0 //写禁止
`define WriteDisable_n 1'b1 //写禁止对应低有效使能
`define ReadEnable 1'b1 //使能读
`define ReadDisable 1'b0 //禁止读
`define AluOpBus 7:0 //译码阶段的输出aluop_o的宽度
`define AluSelBus 2:0 //译码阶段的输出alusel_o的宽度
`define InstValid 1'b0 //指令有效
`define InstInvalid 1'b1 //指令无效
`define Stop 1'b1
`define NoStop 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 1'b1
`define TrapNotAssert 1'b0
`define True_v 1'b1 //逻辑“真”
`define False_v 1'b0 //逻辑“假”
`define ChipEnable 1'b1 //芯片使能
`define ChipDisable 1'b0 //芯片禁止

//********************* 与 具 体 指 令 有 关 的 宏 定 义 *****************************
`define EXE_AND 6'b100100 //and指令的功能码
`define EXE_OR 6'b100101 //or指令的功能码
`define EXE_XOR 6'b100110 //xor指令的功能码
`define EXE_ANDI 6'b001100 //andi指令的指令码
`define EXE_ORI 6'b001101 //ori指令的指令码
`define EXE_XORI 6'b001110 //xori指令的指令码
`define EXE_LUI 6'b001111 //lui指令的指令码

`define EXE_SLL 6'b000000 //sll指令的功能码
`define EXE_SLLV 6'b000100 //sllv指令的功能码
`define EXE_SRL 6'b000010 //sra指令的功能码
`define EXE_SRLV 6'b000110 //srlv指令的功能码
`define EXE_SRA 6'b000011 //sra指令的功能码
`define EXE_SRAV 6'b000111 //srav指令的功能码

`define EXE_SLT 6'b101010
`define EXE_ADD 6'b100000
`define EXE_ADDU 6'b100001
`define EXE_SUB 6'b100010
`define EXE_ADDI 6'b001000
`define EXE_ADDIU 6'b001001

`define EXE_MUL 6'b000010

`define EXE_J 6'b000010
`define EXE_JAL 6'b000011
`define EXE_JALR 6'b001001
`define EXE_JR 6'b001000
`define EXE_BEQ 6'b000100
`define EXE_BGEZ 5'b00001
`define EXE_BGTZ 6'b000111
`define EXE_BLEZ 6'b000110
`define EXE_BLTZ 5'b00000
`define EXE_BNE 6'b000101

`define EXE_LB 6'b100000
`define EXE_LW 6'b100011
`define EXE_SB 6'b101000
`define EXE_SW 6'b101011

`define EXE_NOP 6'b00000

`define EXE_SPECIAL_INST 6'b000000
`define EXE_REGIMM_INST 6'b000001
`define EXE_SPECIAL2_INST 6'b011100

//AluOp
`define EXE_AND_OP 8'b00100100
`define EXE_OR_OP 8'b00100101
`define EXE_XOR_OP 8'b00100110
`define EXE_ANDI_OP 8'b01011001
`define EXE_ORI_OP 8'b01011010
`define EXE_XORI_OP 8'b01011011
`define EXE_LUI_OP 8'b01011100   

`define EXE_SLL_OP 8'b01111100
`define EXE_SLLV_OP 8'b00000100
`define EXE_SRL_OP 8'b00000010
`define EXE_SRLV_OP 8'b00000110
`define EXE_SRA_OP 8'b00000011
`define EXE_SRAV_OP 8'b00000111


`define EXE_SLT_OP 8'b00101010
`define EXE_ADD_OP 8'b00100000
`define EXE_ADDU_OP 8'b00100001
`define EXE_SUB_OP 8'b00100010
`define EXE_ADDI_OP 8'b01010101
`define EXE_ADDIU_OP 8'b01010110

`define EXE_MUL_OP 8'b10101001

`define EXE_J_OP 8'b01001111
`define EXE_JAL_OP 8'b01010000
`define EXE_JALR_OP 8'b00001001
`define EXE_JR_OP 8'b00001000
`define EXE_BEQ_OP 8'b01010001
`define EXE_BGEZ_OP 8'b01000001
`define EXE_BGTZ_OP 8'b01010100
`define EXE_BLEZ_OP 8'b01010011
`define EXE_BLTZ_OP 8'b01000000
`define EXE_BNE_OP 8'b01010010

`define EXE_LB_OP 8'b11100000
`define EXE_LW_OP 8'b11100011
`define EXE_SB_OP 8'b11101000
`define EXE_SW_OP 8'b11101011

`define EXE_NOP_OP 8'b00000000

//AluSel
`define EXE_RES_LOGIC 3'b001
`define EXE_RES_SHIFT 3'b010
`define EXE_RES_ARITHMETIC 3'b100	
`define EXE_RES_MUL 3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE 3'b111

`define EXE_RES_NOP 3'b000


//********************* 与 指 令 存 储 器 ROM 有 关 的 宏 定 义 **********************
`define InstAddrBus 31:0 //ROM的地址总线宽度
`define InstBus 31:0 //ROM的数据总线宽度
`define InstMemNum 4194304 //ROM的实际大小为128KB
`define InstMemNumLog2 22 //ROM实际使用的地址线宽度


//********************* 与 通 用 寄 存 器 Regfile 有 关 的 宏 定 义 *******************
`define RegAddrBus 4:0 //Regfile模块的地址线宽度
`define RegBus 31:0 //Regfile模块的数据线宽度
`define RegWidth 32 //通用寄存器的宽度
`define DoubleRegWidth 64 //两倍的通用寄存器的宽度
`define DoubleRegBus 63:0 //两倍的通用寄存器的数据线宽度
`define RegNum 32 //通用寄存器的数量
`define RegNumLog2 5 //寻址通用寄存器使用的地址位数
`define NOPRegAddr 5'b00000

//数据存储器data_ram
`define DataAddrBus 31:0
`define DataBus 31:0
`define DataMemNum 4194304
`define DataMemNumLog2 22
`define ByteWidth 7:0

//********************** 与 串 口 控 制 器 有 关 的 宏 定 义**************************
`define SerialState 32'hBFD003FC
`define SerialData 32'hBFD003F8
