`timescale 1ns/1ps

module tb12;

  parameter DATA_WIDTH = 8;
  parameter CMD_WIDTH  = 4;

    // ================= COMMAND DEFINITIONS =================
  // Arithmetic mode (M = 1)
  localparam CMD_ADD      = 4'd0;
  localparam CMD_SUB      = 4'd1;
  localparam CMD_ADD_CIN  = 4'd2;
  localparam CMD_SUB_CIN  = 4'd3;
  localparam CMD_INC_A    = 4'd4;
  localparam CMD_DEC_A    = 4'd5;
  localparam CMD_INC_B    = 4'd6;
  localparam CMD_DEC_B    = 4'd7;
  localparam CMD_CMP      = 4'd8;
  localparam CMD_MUL1     = 4'd9;
  localparam CMD_MUL2     = 4'd10;
  localparam CMD_SADD     = 4'd11;
  localparam CMD_SSUB     = 4'd12;

  // Logic mode (M = 0)
  localparam LOGIC_AND    = 4'd0;
  localparam LOGIC_NAND   = 4'd1;
  localparam LOGIC_OR     = 4'd2;
  localparam LOGIC_NOR    = 4'd3;
  localparam LOGIC_XOR    = 4'd4;
  localparam LOGIC_XNOR   = 4'd5;
  localparam LOGIC_NOT_A  = 4'd6;
  localparam LOGIC_NOT_B  = 4'd7;
  localparam LOGIC_SHR_A  = 4'd8;
  localparam LOGIC_SHL_A  = 4'd9;
  localparam LOGIC_SHR_B  = 4'd10;
  localparam LOGIC_SHL_B  = 4'd11;
  localparam LOGIC_ROL    = 4'd12;
  localparam LOGIC_ROR    = 4'd13;


  reg clk;
  reg rst;
  reg [DATA_WIDTH-1:0] opa;
  reg [DATA_WIDTH-1:0] opb;
  reg                  cin;
  reg                  ce;
  reg                  mode;
  reg [1:0]            inp_valid;
  reg [CMD_WIDTH-1:0]  cmd;

  // DUT outputs
  wire [2*DATA_WIDTH-1:0] res;
  wire oflow, cout, g, l, e, err;

  // REF outputs
  wire [15:0] ref_res;
  wire ref_oflow, ref_cout, ref_g, ref_l, ref_e, ref_err;

  // ================= DUT =================
  alu11 #(.WIDTH(DATA_WIDTH)) dut (
    .clk(clk),
    .rst(rst),
    .C_En(ce),
    .M(mode),
    .C_in(cin),
    .Op_A(opa),
    .Op_B(opb),
    .In_V(inp_valid),
    .Cmd(cmd),
    .Res(res),
    .OFlow(oflow),
    .C_out(cout),
    .G(g),
    .L(l),
    .E(e),
    .Err(err)
  );

  // ================= REF MODEL =================
  alu1 #(.WIDTH(DATA_WIDTH)) ref_model (
    .clk(clk),
    .rst(rst),
    .ce(ce),
    .mode(mode),
    .cin(cin),
    .opa(opa),
    .opb(opb),
    .inp_valid(inp_valid),
    .cmd(cmd),
    .res(ref_res),
    .oflow(ref_oflow),
    .cout(ref_cout),
    .g(ref_g),
    .l(ref_l),
    .e(ref_e),
    .err(ref_err)
  );

  // ================= CLOCK =================
  initial clk = 0;
  always #5 clk = ~clk;

  // ================= RESET =================
  task do_reset;
  begin
    rst = 1; ce = 0;
    opa=0; opb=0; cin=0; mode=0; inp_valid=0; cmd=0;

    repeat(3) @(posedge clk);
    rst = 0;
    @(posedge clk);
  end
  endtask

  // ================= COMMON CHECK =================
  task compare_all;
    input [50*8:0] name;
    input [15:0] exp_res;
    input exp_cout, exp_oflow, exp_g, exp_l, exp_e, exp_err;
  begin
    // Expected check
    if(res !== exp_res)
      $display("FAIL_EXP %s RES got=%h exp=%h", name, res, exp_res);
    else
      $display("PASS_EXP %s", name);

    // REF check
    if(res !== ref_res)
      $display("FAIL_REF %s RES dut=%h ref=%h", name, res, ref_res);

    if(cout !== ref_cout)
      $display("FAIL_REF %s COUT dut=%b ref=%b", name, cout, ref_cout);

    if(oflow !== ref_oflow)
      $display("FAIL_REF %s OFLOW dut=%b ref=%b", name, oflow, ref_oflow);

    if(g !== ref_g)
      $display("FAIL_REF %s G dut=%b ref=%b", name, g, ref_g);

    if(l !== ref_l)
      $display("FAIL_REF %s L dut=%b ref=%b", name, l, ref_l);

    if(e !== ref_e)
      $display("FAIL_REF %s E dut=%b ref=%b", name, e, ref_e);

    if(err !== ref_err)
      $display("FAIL_REF %s ERR dut=%b ref=%b", name, err, ref_err);
  end
  endtask

  // ================= 1-CYCLE TASK =================
  task drive_1cyc;
    input [7:0] a,b;
    input cin_i,mode_i;
    input [1:0] valid;
    input [3:0] cmd_i;
    input [15:0] exp_res;
    input exp_cout, exp_oflow, exp_g, exp_l, exp_e, exp_err;
    input [50*8:0] name;
  begin
    opa=a; opb=b; cin=cin_i;
    mode=mode_i; inp_valid=valid; cmd=cmd_i;
    ce=1;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk); #1;

    compare_all(name, exp_res, exp_cout, exp_oflow, exp_g, exp_l, exp_e, exp_err);
  end
  endtask

  // ================= 2-CYCLE TASK =================
  task drive_2cyc;
    input [7:0] a,b;
    input [1:0] valid;
    input [3:0] cmd_i;
    input [15:0] exp_res;
    input exp_err;
    input [50*8:0] name;
  begin
    opa=a; opb=b;
    mode=1; inp_valid=valid; cmd=cmd_i;
    ce=1;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk); #1;

    if(res !== exp_res)
      $display("FAIL_EXP %s RES got=%h exp=%h", name, res, exp_res);
    else
      $display("PASS_EXP %s", name);

    if(res !== ref_res)
      $display("FAIL_REF %s RES dut=%h ref=%h", name, res, ref_res);

    if(err !== ref_err)
      $display("FAIL_REF %s ERR dut=%b ref=%b", name, err, ref_err);
  end
  endtask

  // ================= TESTS =================
  initial begin
    do_reset;
    $display("\n========== FULL ARITHMETIC MODE TESTING (M=1) ==========");
    
    $display("\n---- ADD (CMD=0) ----");
    drive_1cyc(8'd5,8'd3,0,1,2'b11,CMD_ADD,16'd8,0,0,0,0,0,0,"ADD_VALID");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_ADD,0,0,0,0,0,0,1,"ADD_INV_VALID_00");
    drive_1cyc(8'd5,8'd3,0,1,2'b01,CMD_ADD,0,0,0,0,0,0,1,"ADD_INV_VALID_01");
    drive_1cyc(8'd5,8'd3,0,1,2'b10,CMD_ADD,0,0,0,0,0,0,1,"ADD_INV_VALID_10");
    drive_1cyc(8'hFF,8'h01,0,1,2'b11,CMD_ADD,16'h100,1,0,0,0,0,0,"ADD_COUT");
    drive_1cyc(8'hFF,8'hFF,0,1,2'b11,CMD_ADD,16'h1FE,1,0,0,0,0,0,"ADD_MAX_MAX");
    
    $display("\n---- SUB (CMD=1) ----");
    drive_1cyc(8'd10,8'd3,0,1,2'b11,CMD_SUB,16'd7,0,0,0,0,0,0,"SUB_VALID");
    drive_1cyc(8'd3,8'd10,0,1,2'b11,CMD_SUB,16'hFFF9,0,1,0,0,0,0,"SUB_UNDERFLOW");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_SUB,0,0,0,0,0,0,1,"SUB_INV_VALID");
    
    $display("\n---- ADD WITH CIN (CMD=2) ----");
    drive_1cyc(8'd10,8'd5,1,1,2'b11,CMD_ADD_CIN,16'd16,0,0,0,0,0,0,"ADD_CIN_1");
    drive_1cyc(8'd10,8'd5,0,1,2'b11,CMD_ADD_CIN,16'd15,0,0,0,0,0,0,"ADD_CIN_0");
    drive_1cyc(8'hFF,8'hFF,1,1,2'b11,CMD_ADD_CIN,16'h1FF,1,0,0,0,0,0,"ADD_CIN_MAX");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_ADD_CIN,0,0,0,0,0,0,1,"ADD_CIN_INV");
    
    $display("\n---- SUB WITH CIN (CMD=3) ----");
    drive_1cyc(8'd10,8'd3,1,1,2'b11,CMD_SUB_CIN,16'd6,0,0,0,0,0,0,"SUB_CIN_1");
    drive_1cyc(8'd3,8'd10,1,1,2'b11,CMD_SUB_CIN,16'hFFF8,0,1,0,0,0,0,"SUB_CIN_UNDER");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_SUB_CIN,0,0,0,0,0,0,1,"SUB_CIN_INV");
    
    $display("\n---- INC A (CMD=4) ----");
    drive_1cyc(8'd10,0,0,1,2'b11,CMD_INC_A,16'd11,0,0,0,0,0,0,"INC_A_11");
    drive_1cyc(8'd10,0,0,1,2'b01,CMD_INC_A,16'd11,0,0,0,0,0,0,"INC_A_01");
    drive_1cyc(8'hFF,0,0,1,2'b01,CMD_INC_A,16'h00,1,0,0,0,0,0,"INC_A_WRAP");
    drive_1cyc(8'd10,0,0,1,2'b00,CMD_INC_A,0,0,0,0,0,0,1,"INC_A_INV_00");
    drive_1cyc(8'd10,0,0,1,2'b10,CMD_INC_A,0,0,0,0,0,0,1,"INC_A_INV_10");
    
    $display("\n---- DEC A (CMD=5) ----");
    drive_1cyc(8'd10,0,0,1,2'b11,CMD_DEC_A,16'd9,0,0,0,0,0,0,"DEC_A_11");
    drive_1cyc(8'd10,0,0,1,2'b01,CMD_DEC_A,16'd9,0,0,0,0,0,0,"DEC_A_01");
    drive_1cyc(8'd0,0,0,1,2'b01,CMD_DEC_A,16'hFF,0,0,0,0,0,0,"DEC_A_WRAP");
    drive_1cyc(8'd10,0,0,1,2'b00,CMD_DEC_A,0,0,0,0,0,0,1,"DEC_A_INV");
    
    $display("\n---- INC B (CMD=6) ----");
    drive_1cyc(0,8'd10,0,1,2'b11,CMD_INC_B,16'd11,0,0,0,0,0,0,"INC_B_11");
    drive_1cyc(0,8'd10,0,1,2'b10,CMD_INC_B,16'd11,0,0,0,0,0,0,"INC_B_10");
    drive_1cyc(0,8'hFF,0,1,2'b10,CMD_INC_B,16'h00,1,0,0,0,0,0,"INC_B_WRAP");
    drive_1cyc(0,8'd10,0,1,2'b00,CMD_INC_B,0,0,0,0,0,0,1,"INC_B_INV");
    
    $display("\n---- DEC B (CMD=7) ----");
    drive_1cyc(0,8'd10,0,1,2'b11,CMD_DEC_B,16'd9,0,0,0,0,0,0,"DEC_B_11");
    drive_1cyc(0,8'd10,0,1,2'b10,CMD_DEC_B,16'd9,0,0,0,0,0,0,"DEC_B_10");
    drive_1cyc(0,8'd0,0,1,2'b10,CMD_DEC_B,16'hFF,0,0,0,0,0,0,"DEC_B_WRAP");
    drive_1cyc(0,8'd10,0,1,2'b00,CMD_DEC_B,0,0,0,0,0,0,1,"DEC_B_INV");
    
    $display("\n---- COMPARE (CMD=8) ----");
    drive_1cyc(8'd10,8'd5,0,1,2'b11,CMD_CMP,0,0,0,1,0,0,0,"CMP_GT");
    drive_1cyc(8'd5,8'd10,0,1,2'b11,CMD_CMP,0,0,0,0,1,0,0,"CMP_LT");
    drive_1cyc(8'd10,8'd10,0,1,2'b11,CMD_CMP,0,0,0,0,0,1,0,"CMP_EQ");
    drive_1cyc(8'd10,8'd5,0,1,2'b00,CMD_CMP,0,0,0,0,0,0,1,"CMP_INV");
    
    $display("\n---- MULTIPLY 1 (CMD=9) ----");
    drive_2cyc(8'd3,8'd4,2'b11,CMD_MUL1,16'd20,0,"MUL1_BASIC");
    drive_2cyc(8'd0,8'd5,2'b11,CMD_MUL1,16'd0,0,"MUL1_ZERO");
    drive_2cyc(8'd5,8'd0,2'b11,CMD_MUL1,16'd0,0,"MUL1_ZERO_B");
    drive_2cyc(8'd1,8'd1,2'b11,CMD_MUL1,16'd4,0,"MUL1_ONE");
    drive_2cyc(8'd3,8'd4,2'b00,CMD_MUL1,0,1,"MUL1_INV_VALID");
    
    $display("\n---- MULTIPLY 2 (CMD=10) ----");
    drive_2cyc(8'd3,8'd4,2'b11,CMD_MUL2,16'd24,0,"MUL2_BASIC");
    drive_2cyc(8'd0,8'd5,2'b11,CMD_MUL2,16'd0,0,"MUL2_ZERO");
    drive_2cyc(8'd5,8'd0,2'b11,CMD_MUL2,16'd0,0,"MUL2_ZERO_B");
    drive_2cyc(8'd1,8'd1,2'b11,CMD_MUL2,16'd8,0,"MUL2_ONE");
    
    $display("\n---- SIGNED ADD (CMD=11) ----");
    drive_1cyc(8'd5,8'd3,0,1,2'b11,CMD_SADD,16'd8,0,1,0,0,0,0,"SADD_POS_POS");
    drive_1cyc(8'h80,8'h80,0,1,2'b11,CMD_SADD,16'h00,0,1,0,0,0,0,"SADD_NEG_NEG");
    drive_1cyc(8'd5,8'hFF,0,1,2'b11,CMD_SADD,16'd4,0,0,0,0,0,0,"SADD_POS_NEG");
    drive_1cyc(8'h80,8'd5,0,1,2'b11,CMD_SADD,16'h85,0,0,0,0,0,0,"SADD_NEG_POS");
    drive_1cyc(8'h7F,8'd1,0,1,2'b11,CMD_SADD,16'h80,0,1,0,0,0,0,"SADD_OVERFLOW");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_SADD,0,0,0,0,0,0,1,"SADD_INV");
    
    $display("\n---- SIGNED SUB (CMD=12) ----");
    drive_1cyc(8'd10,8'd3,0,1,2'b11,CMD_SSUB,16'd7,0,1,0,0,0,0,"SSUB_POS_POS");
    drive_1cyc(8'd10,8'hFF,0,1,2'b11,CMD_SSUB,16'd11,0,1,0,0,0,0,"SSUB_POS_NEG");
    drive_1cyc(8'h80,8'd5,0,1,2'b11,CMD_SSUB,16'h7B,0,0,0,0,0,0,"SSUB_NEG_POS");
    drive_1cyc(8'd5,8'd10,0,1,2'b11,CMD_SSUB,16'hFB,0,1,0,0,0,0,"SSUB_UNDERFLOW");
    drive_1cyc(8'h80,8'h80,0,1,2'b11,CMD_SSUB,16'h00,0,0,0,0,0,0,"SSUB_NEG_NEG");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_SSUB,0,0,0,0,0,0,1,"SSUB_INV");
    
    $display("\n---- INVALID CMD (default) ----");
    drive_1cyc(8'd5,8'd3,0,1,2'b11,4'd15,0,0,0,0,0,0,1,"INV_CMD_15");
    drive_1cyc(8'd5,8'd3,0,1,2'b11,4'd14,0,0,0,0,0,0,1,"INV_CMD_14");
    
    $display("\n========== FULL LOGIC MODE TESTING (M=0) ==========");
    
    $display("\n---- AND (CMD=0) ----");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_AND,16'h00,0,0,0,0,0,0,"AND");
    drive_1cyc(8'hFF,8'hF0,0,0,2'b11,LOGIC_AND,16'hF0,0,0,0,0,0,0,"AND_MASK");
    drive_1cyc(8'hAA,8'h55,0,0,2'b00,LOGIC_AND,0,0,0,0,0,0,1,"AND_INV");
    
    $display("\n---- NAND (CMD=1) ----");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_NAND,16'hFF,0,0,0,0,0,0,"NAND");
    drive_1cyc(8'hFF,8'hF0,0,0,2'b11,LOGIC_NAND,16'h0F,0,0,0,0,0,0,"NAND_MASK");
    drive_1cyc(8'hAA,8'h55,0,0,2'b00,LOGIC_NAND,0,0,0,0,0,0,1,"NAND_INV");
    
    $display("\n---- OR (CMD=2) ----");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_OR,16'hFF,0,0,0,0,0,0,"OR");
    drive_1cyc(8'hF0,8'h0F,0,0,2'b11,LOGIC_OR,16'hFF,0,0,0,0,0,0,"OR_ALL");
    drive_1cyc(8'hAA,8'h55,0,0,2'b00,LOGIC_OR,0,0,0,0,0,0,1,"OR_INV");
    
    $display("\n---- NOR (CMD=3) ----");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_NOR,16'h00,0,0,0,0,0,0,"NOR");
    drive_1cyc(8'hF0,8'h0F,0,0,2'b11,LOGIC_NOR,16'h00,0,0,0,0,0,0,"NOR_ALL");
    drive_1cyc(8'hAA,8'h55,0,0,2'b00,LOGIC_NOR,0,0,0,0,0,0,1,"NOR_INV");
    
    $display("\n---- XOR (CMD=4) ----");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_XOR,16'hFF,0,0,0,0,0,0,"XOR");
    drive_1cyc(8'hAA,8'hAA,0,0,2'b11,LOGIC_XOR,16'h00,0,0,0,0,0,0,"XOR_SAME");
    drive_1cyc(8'hAA,8'h55,0,0,2'b00,LOGIC_XOR,0,0,0,0,0,0,1,"XOR_INV");
    
    $display("\n---- XNOR (CMD=5) ----");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_XNOR,16'h00,0,0,0,0,0,0,"XNOR");
    drive_1cyc(8'hAA,8'hAA,0,0,2'b11,LOGIC_XNOR,16'hFF,0,0,0,0,0,0,"XNOR_SAME");
    
    $display("\n---- NOT A (CMD=6) ----");
    drive_1cyc(8'hAA,0,0,0,2'b11,LOGIC_NOT_A,16'h55,0,0,0,0,0,0,"NOT_A_11");
    drive_1cyc(8'hAA,0,0,0,2'b01,LOGIC_NOT_A,16'h55,0,0,0,0,0,0,"NOT_A_01");
    drive_1cyc(8'hAA,0,0,0,2'b00,LOGIC_NOT_A,0,0,0,0,0,0,1,"NOT_A_INV_00");
    drive_1cyc(8'hAA,0,0,0,2'b10,LOGIC_NOT_A,0,0,0,0,0,0,1,"NOT_A_INV_10");
    
    $display("\n---- NOT B (CMD=7) ----");
    drive_1cyc(0,8'hAA,0,0,2'b11,LOGIC_NOT_B,16'h55,0,0,0,0,0,0,"NOT_B_11");
    drive_1cyc(0,8'hAA,0,0,2'b10,LOGIC_NOT_B,16'h55,0,0,0,0,0,0,"NOT_B_10");
    drive_1cyc(0,8'hAA,0,0,2'b00,LOGIC_NOT_B,0,0,0,0,0,0,1,"NOT_B_INV");
    
    $display("\n---- SHIFT RIGHT A (CMD=8) ----");
    drive_1cyc(8'hAA,0,0,0,2'b11,LOGIC_SHR_A,16'h55,0,0,0,0,0,0,"SHR_A_11");
    drive_1cyc(8'hAA,0,0,0,2'b01,LOGIC_SHR_A,16'h55,0,0,0,0,0,0,"SHR_A_01");
    drive_1cyc(8'h80,0,0,0,2'b01,LOGIC_SHR_A,16'h40,0,0,0,0,0,0,"SHR_A_MSB");
    drive_1cyc(8'hAA,0,0,0,2'b00,LOGIC_SHR_A,0,0,0,0,0,0,1,"SHR_A_INV");
    
    $display("\n---- SHIFT LEFT A (CMD=9) ----");
    drive_1cyc(8'h55,0,0,0,2'b11,LOGIC_SHL_A,16'hAA,0,0,0,0,0,0,"SHL_A_11");
    drive_1cyc(8'h55,0,0,0,2'b01,LOGIC_SHL_A,16'hAA,0,0,0,0,0,0,"SHL_A_01");
    drive_1cyc(8'h80,0,0,0,2'b01,LOGIC_SHL_A,16'h00,0,0,0,0,0,0,"SHL_A_MSB_LOSS");
    drive_1cyc(8'h55,0,0,0,2'b00,LOGIC_SHL_A,0,0,0,0,0,0,1,"SHL_A_INV");
    
    $display("\n---- SHIFT RIGHT B (CMD=10) ----");
    drive_1cyc(0,8'hAA,0,0,2'b11,LOGIC_SHR_B,16'h55,0,0,0,0,0,0,"SHR_B_11");
    drive_1cyc(0,8'hAA,0,0,2'b10,LOGIC_SHR_B,16'h55,0,0,0,0,0,0,"SHR_B_10");
    drive_1cyc(0,8'h80,0,0,2'b10,LOGIC_SHR_B,16'h40,0,0,0,0,0,0,"SHR_B_MSB");
    drive_1cyc(0,8'hAA,0,0,2'b00,LOGIC_SHR_B,0,0,0,0,0,0,1,"SHR_B_INV");
    
    $display("\n---- SHIFT LEFT B (CMD=11) ----");
    drive_1cyc(0,8'h55,0,0,2'b11,LOGIC_SHL_B,16'hAA,0,0,0,0,0,0,"SHL_B_11");
    drive_1cyc(0,8'h55,0,0,2'b10,LOGIC_SHL_B,16'hAA,0,0,0,0,0,0,"SHL_B_10");
    drive_1cyc(0,8'h80,0,0,2'b10,LOGIC_SHL_B,16'h00,0,0,0,0,0,0,"SHL_B_MSB_LOSS");
    
    $display("\n---- ROTATE LEFT (CMD=12) ----");
    drive_1cyc(8'hAA,8'd1,0,0,2'b11,LOGIC_ROL,16'h55,0,0,0,0,0,0,"ROL_1");
    drive_1cyc(8'hAA,8'd2,0,0,2'b11,LOGIC_ROL,16'hAA,0,0,0,0,0,0,"ROL_2");
    drive_1cyc(8'hAA,8'd4,0,0,2'b11,LOGIC_ROL,16'hAA,0,0,0,0,0,0,"ROL_4");
    drive_1cyc(8'hAA,8'd0,0,0,2'b11,LOGIC_ROL,16'hAA,0,0,0,0,0,0,"ROL_0");
    drive_1cyc(8'hAA,8'hFF,0,0,2'b11,LOGIC_ROL,0,0,0,0,0,0,1,"ROL_INV_UPPER");
    drive_1cyc(8'hAA,8'd1,0,0,2'b00,LOGIC_ROL,0,0,0,0,0,0,1,"ROL_INV_VALID");
    
    $display("\n---- ROTATE RIGHT (CMD=13) ----");
    drive_1cyc(8'h55,8'd1,0,0,2'b11,LOGIC_ROR,16'hAA,0,0,0,0,0,0,"ROR_1");
    drive_1cyc(8'h55,8'd2,0,0,2'b11,LOGIC_ROR,16'h55,0,0,0,0,0,0,"ROR_2");
    drive_1cyc(8'h55,8'd4,0,0,2'b11,LOGIC_ROR,16'h55,0,0,0,0,0,0,"ROR_4");
    drive_1cyc(8'h55,8'd0,0,0,2'b11,LOGIC_ROR,16'h55,0,0,0,0,0,0,"ROR_0");
    drive_1cyc(8'h55,8'hFF,0,0,2'b11,LOGIC_ROR,0,0,0,0,0,0,1,"ROR_INV_UPPER");
    drive_1cyc(8'h55,8'd1,0,0,2'b00,LOGIC_ROR,0,0,0,0,0,0,1,"ROR_INV_VALID");
    
    $display("\n---- MODE TRANSITION TESTS ----");
    drive_1cyc(8'd5,8'd3,0,1,2'b11,CMD_ADD,16'd8,0,0,0,0,0,0,"MODE_ADD");
    drive_1cyc(8'hAA,8'h55,0,0,2'b11,LOGIC_AND,16'h00,0,0,0,0,0,0,"MODE_AND");

    $display("\n---- C_OUT and OFLOW COVERAGE ----");
    drive_1cyc(8'hFF,8'h01,0,1,2'b11,CMD_ADD,16'h100,1,0,0,0,0,0,"COUT_ADD");
    drive_1cyc(8'hFF,8'hFF,1,1,2'b11,CMD_ADD_CIN,16'h1FF,1,0,0,0,0,0,"COUT_ADD_CIN");
    drive_1cyc(8'd3,8'd5,0,1,2'b11,CMD_SUB,16'hFFFE,0,1,0,0,0,0,"OFLOW_SUB");
    drive_1cyc(8'h7F,8'd1,0,1,2'b11,CMD_SADD,16'h80,0,1,0,0,0,0,"OFLOW_SADD");
    drive_1cyc(8'd10,8'hFF,0,1,2'b11,CMD_SSUB,16'd11,0,1,0,0,0,0,"OFLOW_SSUB");
  
    $display("\n---- IN_V COMBINATION COVERAGE ----");
    drive_1cyc(8'd5,8'd3,0,1,2'b11,CMD_ADD,16'd8,0,0,0,0,0,0,"INV_11_ADD");
    drive_1cyc(8'd5,8'd3,0,1,2'b01,CMD_ADD,0,0,0,0,0,0,1,"INV_01_ADD");
    drive_1cyc(8'd5,8'd3,0,1,2'b10,CMD_ADD,0,0,0,0,0,0,1,"INV_10_ADD");
    drive_1cyc(8'd5,8'd3,0,1,2'b00,CMD_ADD,0,0,0,0,0,0,1,"INV_00_ADD");
   
    drive_1cyc(8'd10,0,0,1,2'b11,CMD_INC_A,16'd11,0,0,0,0,0,0,"INV_11_INC");
    drive_1cyc(8'd10,0,0,1,2'b01,CMD_INC_A,16'd11,0,0,0,0,0,0,"INV_01_INC");
    drive_1cyc(8'd10,0,0,1,2'b10,CMD_INC_A,0,0,0,0,0,0,1,"INV_10_INC");
  
    drive_1cyc(0,8'd10,0,1,2'b11,CMD_INC_B,16'd11,0,0,0,0,0,0,"INV_11_INCB");
    drive_1cyc(0,8'd10,0,1,2'b10,CMD_INC_B,16'd11,0,0,0,0,0,0,"INV_10_INCB");
    drive_1cyc(0,8'd10,0,1,2'b01,CMD_INC_B,0,0,0,0,0,0,1,"INV_01_INCB");
    
    $display("\n========== ALL TESTS COMPLETE ==========");

    $finish;
  end

endmodule
