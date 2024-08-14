`include "defines.v"
module stall_ctrl (
    input wire rst,
    input wire stallreq_from_id,
    input wire stallreq_from_baseram,
    output reg [5:0] stall
);

  always @(*) begin
    if (rst == `RstEnable) begin
      stall <= 6'b0;      
    end
    else if (stallreq_from_id) begin
      stall <= 6'b000111;
    end
    else if (stallreq_from_baseram) begin
      stall <= 6'b001111;
    end else begin
      stall <= 6'b0;
    end
  end

endmodule
