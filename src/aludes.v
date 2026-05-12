`timescale 1ns / 1ps
module alu1 #(parameter WIDTH=4)(opa,opb,cin,clk,rst,ce,mode,inp_valid,cmd,res,oflow,cout,g,l,e,err);
input wire [7:0]opa;
input wire  [7:0]opb;
input wire cin,clk,rst,ce,mode;
input wire [1:0]inp_valid;
input  wire [WIDTH-1:0]cmd;
output reg[15:0]res;
output reg oflow,cout,g,l,e,err;
wire clk_en;
assign clk_en=clk&ce;
reg[3:0]cnt;

always@(posedge clk_en or posedge rst) begin
if(rst)
cnt<=0;
else if(mode&&cmd==9 || mode&&cmd==10)
cnt<=cnt+1;
else
cnt<=0;
end

always@(posedge clk_en or posedge rst) begin
if(rst) begin
  res<=0;
  oflow<=0;
  cout<=0;
  g<=0; l<=0; e<=0;
  err<=0; end
else if(mode) begin
   case(cmd)
     
    4'b0000:
if(inp_valid==2'b11) begin
res<=opa+opb;
cout<=res[9]; end
else begin
err<=1;
res<=0; end
     
    4'b0001:
if(inp_valid==2'b11) begin
res<=opa-opb;
cout<=res[9]; end
else begin
err<=1;
res<=0; end
     
    4'b0010:
if(inp_valid==2'b11) begin
res<=opa+opb+cin;
cout<=res[9]; end
else begin
err<=1;
res<=0; end
     
    4'b0011:
if(inp_valid==2'b11) begin
res<=opa-opb-cin;
cout<=res[9]; end
else begin
err<=1;
res<=0; end
     
    4'b0100:
if(inp_valid)
res<=opa+1;
else begin
err<=1;
res<=0; end
     
    4'b0101:
if(inp_valid)
res<=opa-1;
else begin
err<=1;
res<=0; end
     
    4'b0110:
if(inp_valid==2'b10)
res<=opb+1;
else begin
err<=1;
res<=0; end
     
    4'b0111:
if(inp_valid==2'b10)
res<=opb-1;
else begin
err<=1;
res<=0; end
     
    4'b1000:
if(inp_valid==2'b11) begin
       if(opa>opb)
         g<=1;
       else if(opa<opb)
 l<=1;
       else
         e<=1; end
   else begin
      err<=1;
      res<=0; end
     
    4'b1001:
if(inp_valid==2'b11) begin
 if(cnt==3)
 res<=(opa+1)*(opb+1);
 else res<=0; end
else
 begin
err<=1;
res<=0; end

    4'b1010:
if(inp_valid)
res<=(opa<<1)*opb;
else begin
err<=1;
res<=0; end
     
    4'b1011:
if(inp_valid==2'b11) begin
res<=$signed(opa)+$signed(opb);
if(res[9]==1)
oflow<=1;
else oflow<=0; end
else begin
err<=1;
res<=0; end
     
    4'b1100:
if(inp_valid==2'b11) begin
res<=$signed(opa)-$signed(opb);
if(res[9]==1)
oflow<=1;
else oflow<=0; end
else begin
err<=1;
res<=0; end
endcase
end

else begin
   case(cmd)
    4'b0000:
if(inp_valid==2'b11)
res<=opa&opb;
else begin
err<=1;
res<=0; end
     
    4'b0001:
if(inp_valid==2'b11)
res<=~(opa&opb);
else begin
err<=1;
res<=0; end
     
    4'b0010:
if(inp_valid==2'b11)
res<=opa|opb;
else begin
err<=1;
res<=0; end
     
    4'b0011:
if(inp_valid==2'b11)
res<=~(opa|opb);
else begin
err<=1;
res<=0; end
     
    4'b0100:
if(inp_valid==2'b11)
res<=opa^opb;
else begin
err<=1;
res<=0; end
     
    4'b0101:
if(inp_valid==2'b11)
res<=~(opa^opb);
else begin
err<=1;
res<=0; end
     
    4'b0110:
if(inp_valid==2'b01)
res<=~opa;
else begin
err<=1;
res<=0; end
     
    4'b0111:
if(inp_valid==2'b10)
res<=~opb;
else begin
err<=1;
res<=0; end
     
    4'b1000:
if(inp_valid==2'b01)
res<=opa>>1;
else begin
err<=1;
res<=0; end
     
    4'b1001:
if(inp_valid==2'b01)
res<=opa<<1;
else begin
err<=1;
res<=0; end
     
    4'b1010:
if(inp_valid==2'b10)
res<=opb>>1;
else begin
err<=1;
res<=0; end
     
    4'b1011:
if(inp_valid==2'b10)
res<=opb<<1;
else begin
err<=1;
res<=0; end
     
    4'b1100:
if(inp_valid==2'b11) begin
      casex(opb) 
       8'b0000x000:res=opa;
       8'b0000x001:res={opa[6:0],opa[7]};
       8'b0000x010:res={opa[5:0],opa[7:6]};
       8'b0000x011:res={opa[4:0],opa[7:5]};
       8'b0000x100:res={opa[3:0],opa[7:4]};
       8'b0000x101:res={opa[2:0],opa[7:3]};
       8'b0000x110:res={opa[1:0],opa[7:2]};
       8'b0000x111:res={opa[0],opa[7:1]};
       default:err=1;
      endcase end
else begin
err<=1;
res<=0; end
     
    4'b1101:
if(inp_valid==2'b11) begin
      casex(opb) 
       8'b0000x000:res=opa;
       8'b0000x001:res={opa[0],opa[7:1]};
       8'b0000x010:res={opa[1:0],opa[7:2]};
       8'b0000x011:res={opa[2:0],opa[7:3]};
       8'b0000x100:res={opa[3:0],opa[7:4]};
       8'b0000x101:res={opa[4:0],opa[7:5]};
       8'b0000x110:res={opa[5:0],opa[7:6]};
       8'b0000x111:res={opa[6:0],opa[7]};
       default:err=1;
      endcase end
else begin
err<=1;
res<=0; end
    default:res=0; 
  endcase 
 end
 end
endmodule

