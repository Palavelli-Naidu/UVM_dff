// Code your design here






// Code your design here

module D_ff(input clk,input reset,input D,output reg Q);
  
  always @(posedge clk)
    begin
      if(reset==1)
        Q=1'b0;
      else
         Q=D;
    end
  
endmodule





interface IF;
  logic clk;
  logic reset;
  logic D;
  logic Q;
endinterface
  
  
