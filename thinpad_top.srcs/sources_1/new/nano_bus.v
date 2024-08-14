module nano_bus (
    input wire clk,
    input wire clk_50M,
    input wire rst,

    // if阶段输入的信息和指令
    input  wire [31:0] rom_addr_i,  // 读取指令的地址
    input  wire        rom_ce_i,    // 指令存储器的使能信号
    output reg  [31:0] inst_o,      // 获取到的指令

    // mem阶段传递的信息和数据
    input  wire [31:0] mem_addr_i,  // 读写地址
    input  wire [31:0] mem_data_i,  // 写入的数据
    input  wire        mem_we_n,    // 写使能，低有效
    input  wire [ 3:0] mem_sel_n,   // 字节选择信号
    input  wire        mem_ce_i,    // 片选信号
    output reg  [31:0] ram_data_o,  // 读取的数据

    // BaseRam信号
    inout  wire [31:0] base_ram_data,  // BaseRam数据
    output reg  [19:0] base_ram_addr,  // BaseRam地址
    output reg  [ 3:0] base_ram_be_n,  // BaseRam字节使能
    output reg         base_ram_ce_n,  // BaseRam片选
    output reg         base_ram_oe_n,  // BaseRam读使能
    output reg         base_ram_we_n,  // BaseRam写使能

    // ExtRam信号
    inout  wire [31:0] ext_ram_data,  // ExtRam数据
    output reg  [19:0] ext_ram_addr,  // ExtRam地址
    output reg  [ 3:0] ext_ram_be_n,  // ExtRam字节使能
    output reg         ext_ram_ce_n,  // ExtRam片选
    output reg         ext_ram_oe_n,  // ExtRam读使能
    output reg         ext_ram_we_n,  // ExtRam写使能

    // 串口信号
    output wire       txd,   // 串口发射端
    input  wire       rxd,   // 串口接收端
    output wire [1:0] state  // 串口状态
);

  wire [7:0] RxD_data;
  wire [7:0] TxD_data;
  wire       RxD_data_ready;
  wire       TxD_busy;
  wire       TxD_start;
  wire       RxD_clear;

  wire       RxD_FIFO_wr_en;
  wire       RxD_FIFO_full;
  wire [7:0] RxD_FIFO_din;
  reg        RxD_FIFO_rd_en;
  wire       RxD_FIFO_empty;
  wire [7:0] RxD_FIFO_dout;

  reg        TxD_FIFO_wr_en;
  wire       TxD_FIFO_full;
  reg  [7:0] TxD_FIFO_din;
  wire       TxD_FIFO_rd_en;
  wire       TxD_FIFO_empty;
  wire [7:0] TxD_FIFO_dout;

  // 串口实例化，波特率9600
  async_receiver #(
      .ClkFrequency(50000000),
      .Baud(9600)
  ) ext_uart_r (
      .clk(clk_50M),
      .RxD(rxd),
      .RxD_data_ready(RxD_data_ready),
      .RxD_clear(RxD_clear),
      .RxD_data(RxD_data)
  );

  async_transmitter #(
      .ClkFrequency(50000000),
      .Baud(9600)
  ) ext_uart_t (
      .clk(clk_50M),
      .TxD(txd),
      .TxD_busy(TxD_busy),
      .TxD_start(TxD_start),
      .TxD_data(TxD_data)
  );

  // fifo接收模块
  fifo_generator_0 RDX_FIFO (
      .rst  (rst),
      .wr_clk(clk_50M),
      .rd_clk(clk),
      .wr_en(RxD_FIFO_wr_en),  // 写使能
      .din  (RxD_FIFO_din),    // 接收到的数据
      .full (RxD_FIFO_full),   // 判满标志

      .rd_en(RxD_FIFO_rd_en),  // 读使能
      .dout (RxD_FIFO_dout),   // 传递给mem阶段读出的数据
      .empty(RxD_FIFO_empty)   // 判空标志
  );

  fifo_generator_0 TDX_FIFO (
      .rst  (rst),
      .wr_clk(clk),
      .rd_clk(clk_50M),
      .wr_en(TxD_FIFO_wr_en),
      .din  (TxD_FIFO_din),
      .full (TxD_FIFO_full),

      .rd_en(TxD_FIFO_rd_en),
      .dout (TxD_FIFO_dout),
      .empty(TxD_FIFO_empty)
  );

  // 内存映射
  wire is_SerialState = (mem_addr_i == `SerialState);
  wire is_SerialData = (mem_addr_i == `SerialData);
  wire is_base_ram = (mem_addr_i >= 32'h80000000) && (mem_addr_i <= 32'h803FFFFF);
  wire is_ext_ram = (mem_addr_i >= 32'h80400000) && (mem_addr_i <= 32'h807FFFFF);

  reg [31:0] serial_o;
  wire [31:0] base_ram_o;
  wire [31:0] ext_ram_o;

  assign state = {!RxD_FIFO_empty, !TxD_FIFO_full};

  assign TxD_FIFO_rd_en = TxD_start;
  assign TxD_start = (!TxD_busy) && (!TxD_FIFO_empty);
  assign TxD_data = TxD_FIFO_dout;

  assign RxD_FIFO_wr_en = RxD_data_ready;
  assign RxD_FIFO_din = RxD_data;
  assign RxD_clear = RxD_data_ready && (!RxD_FIFO_full);

  always @(*) begin
    TxD_FIFO_wr_en = `WriteDisable;
    TxD_FIFO_din = 8'h00;
    RxD_FIFO_rd_en = `ReadEnable;
    serial_o = `ZeroWord;
    if (is_SerialState) begin
      TxD_FIFO_wr_en = `WriteDisable;
      TxD_FIFO_din = 8'h00;
      RxD_FIFO_rd_en = `ReadDisable;
      serial_o = {{30{1'b0}}, state};
    end else if (is_SerialData) begin
      if (mem_we_n == `WriteDisable_n) begin
        TxD_FIFO_wr_en = `WriteDisable;
        TxD_FIFO_din = 8'h00;
        RxD_FIFO_rd_en = `ReadEnable;
        serial_o = {{24{1'b0}}, RxD_FIFO_dout};
      end else begin
        TxD_FIFO_wr_en = `WriteEnable;
        TxD_FIFO_din = mem_data_i[7:0];
        RxD_FIFO_rd_en = `ReadDisable;
        serial_o = `ZeroWord;
      end
    end else begin
      TxD_FIFO_wr_en = `WriteDisable;
      TxD_FIFO_din = 8'h00;
      RxD_FIFO_rd_en = `ReadDisable;
      serial_o = `ZeroWord;
    end
  end

  // 处理BaseRam
  assign base_ram_data = is_base_ram ? ((mem_we_n == `WriteEnable_n) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
  assign base_ram_o = base_ram_data;

  // 当mem阶段需要向BaseRam的地址写入或读取数据时，发生结构冒险
  always @(*) begin
    if (is_base_ram) begin
      base_ram_addr = mem_addr_i[21:2];
      base_ram_be_n = mem_sel_n;
      base_ram_ce_n = 1'b0;
      base_ram_oe_n = !mem_we_n;
      base_ram_we_n = mem_we_n;
      inst_o = `ZeroWord;
    end else begin
      base_ram_addr = rom_addr_i[21:2];
      base_ram_be_n = 4'b0000;
      base_ram_ce_n = 1'b0;
      base_ram_oe_n = 1'b0;
      base_ram_we_n = 1'b1;
      inst_o = base_ram_o;
    end
  end

  // 处理ExtRam
  assign ext_ram_data = is_ext_ram ? ((mem_we_n == `WriteEnable_n) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
  assign ext_ram_o = ext_ram_data;

  always @(*) begin
    if (is_ext_ram) begin
      ext_ram_addr = mem_addr_i[21:2];
      ext_ram_be_n = mem_sel_n;
      ext_ram_ce_n = 1'b0;
      ext_ram_oe_n = !mem_we_n;
      ext_ram_we_n = mem_we_n;
    end else begin
      ext_ram_addr = 20'h00000;
      ext_ram_be_n = 4'b0000;
      ext_ram_ce_n = 1'b0;
      ext_ram_oe_n = 1'b1;
      ext_ram_we_n = 1'b1;
    end
  end

  //确认输出的数据
  always @(*) begin
    ram_data_o = `ZeroWord;
    if (is_SerialState || is_SerialData) begin
      ram_data_o = serial_o;
    end else if (is_base_ram) begin
      case (mem_sel_n)
        4'b1110: begin
          ram_data_o = {{24{base_ram_o[7]}}, base_ram_o[7:0]};
        end
        4'b1101: begin
          ram_data_o = {{24{base_ram_o[15]}}, base_ram_o[15:8]};
        end
        4'b1011: begin
          ram_data_o = {{24{base_ram_o[23]}}, base_ram_o[23:16]};
        end
        4'b0111: begin
          ram_data_o = {{24{base_ram_o[31]}}, base_ram_o[31:24]};
        end
        4'b0000: begin
          ram_data_o = base_ram_o;
        end
        default: begin
          ram_data_o = base_ram_o;
        end
      endcase
    end else if (is_ext_ram) begin
      case (mem_sel_n)
        4'b1110: begin
          ram_data_o = {{24{ext_ram_o[7]}}, ext_ram_o[7:0]};
        end
        4'b1101: begin
          ram_data_o = {{24{ext_ram_o[15]}}, ext_ram_o[15:8]};
        end
        4'b1011: begin
          ram_data_o = {{24{ext_ram_o[23]}}, ext_ram_o[23:16]};
        end
        4'b0111: begin
          ram_data_o = {{24{ext_ram_o[31]}}, ext_ram_o[31:24]};
        end
        4'b0000: begin
          ram_data_o = ext_ram_o;
        end
        default: begin
          ram_data_o = ext_ram_o;
        end
      endcase
    end else begin
      ram_data_o = `ZeroWord;
    end
  end

endmodule
