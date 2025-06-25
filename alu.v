module alu(
  input  wire [11:0] alu_control,
  input  wire signed [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output reg  [31:0] alu_result
);

    wire sub_en = (alu_control[1] == 1'b1) || (alu_control[2] == 1'b1) || (alu_control[3] == 1'b1) ;     //小于置位都需要减法信号
    wire [31:0] data1 = alu_src1;    wire [31:0] data2 = sub_en ? ~alu_src2 : alu_src2;
    wire cin = sub_en ? 1'b1 : 1'b0; wire [31:0] result;
    wire cout;       	
    adder adder_module(.operand1(data1),.operand2(data2),.cin(cin),.result(result),.cout(cout));
    always @(*) begin
        if(alu_control[0] == 1'b1 || alu_control[1] == 1'b1)
            alu_result <= result;
        else if(alu_control[2] == 1'b1)
            begin
                if(alu_src1[31] != alu_src2[31])
                    alu_result <= {31'b0,data1[31]};
                else
                    alu_result <= {31'b0,result[31]};
             end
        else  if(alu_control[3] == 1'b1)
            alu_result <= {31'b0,~cout};                                                                 
        else if(alu_control[4] == 1'b1)
            alu_result <= alu_src1 & alu_src2;
        else if(alu_control[5] == 1'b1)
            alu_result <= ~(alu_src1 | alu_src2);
        else if(alu_control[6] == 1'b1)
            alu_result <= alu_src1 | alu_src2;
        else if(alu_control[7] == 1'b1)
            alu_result <= alu_src1^alu_src2;
        else if(alu_control[8] == 1'b1)
            alu_result <= alu_src1 << alu_src2[4:0];
        else if(alu_control[9] == 1'b1) 
            alu_result <= alu_src1 >> alu_src2[4:0];
        else if(alu_control[10] == 1'b1)
            alu_result <= alu_src1 >>> alu_src2[4:0];
        else if(alu_control[11] == 1'b1)
            alu_result <= alu_src2;
        else
            alu_result <= 32'h0;
    end    
    assign mid_result = result;
endmodule
