`include "defines.v"
module regfile (
    input wire clk,
    input wire rst,

    //写端口
    input wire we,
    input wire [`RegAddrBus] waddr,
    input wire [`RegBus] wdata,

    //读端口1
    input wire re1,
    input wire [`RegAddrBus] raddr1,
    output reg [`RegBus] rdata1,

    //读端口2
    input wire re2,
    input wire [`RegAddrBus] raddr2,
    output reg [`RegBus] rdata2
);

  /****************************************************************
*********** 第一段：定义32个32位寄存器 *********
*****************************************************************/

  reg [`RegBus] regs[0:`RegNum-1];

  /****************************************************************
*********** 第二段：写操作 *********
*****************************************************************/

  always @(posedge clk) begin
    if (rst == `RstDisable) begin
      if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin  //不要写入X0
        regs[waddr] <= wdata;
      end
    end
  end

  /****************************************************************
*********** 第三段：读端口1的读操作 *********
*****************************************************************/

  always @(*) begin
    if (rst == `RstEnable) begin
      rdata1 <= `ZeroWord;
    end else if (raddr1 == `RegNumLog2'h0) begin  //读取X0
      rdata1 <= `ZeroWord;
      //读取地址和写入地址相同且读取写入都使能，在一个时钟周期内
    end else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
      rdata1 <= wdata;
    end else if (re1 == `ReadEnable) begin  //读取寄存器
      rdata1 <= regs[raddr1];
    end else begin  //读取内容默认为零
      rdata1 <= `ZeroWord;
    end
  end

  /****************************************************************
*********** 第四段：读端口2的读操作 *********
*****************************************************************/

  always @(*) begin
    if (rst == `RstEnable) begin
      rdata2 <= `ZeroWord;
    end else if (raddr2 == `RegNumLog2'h0) begin  //读取X0
      rdata2 <= `ZeroWord;
    end else if ( (raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin //读取地址和写入地址相同且读取写入都使能
      rdata2 <= wdata;
    end else if (re2 == `ReadEnable) begin  //读取寄存器
      rdata2 <= regs[raddr2];
    end else begin  //读取内容默认为零
      rdata2 <= `ZeroWord;
    end
  end

endmodule
