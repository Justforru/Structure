module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,        //字节使能：对st.w指令，应为4'b1111.
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

reg         reset;
always @(posedge clk) reset <= ~resetn;

reg valid;
always @(posedge clk) begin
    if (reset) begin
        valid <= 1'b0;
    end
    else begin
        valid <= 1'b1;
    end
end

//Fetch Stage
wire [31:0] seq_pc;
wire [31:0] nextpc;
wire [31:0] inst;
reg  [31:0] pc;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1c000000;
    end
    else begin
        pc <= nextpc;
    end
end

assign inst_sram_en = 1'b1;
assign inst_sram_we = 4'b0000;
assign inst_sram_addr = pc;
assign inst_sram_wdata = 32'b0;
assign inst = (pc == 32'h1c000000) ? 32'h 0 : inst_sram_rdata;
//传递到译码的指令和pc
wire [31:0] instD;
wire [31:0] pcD;


//F-D 
//inst_ram是同步读，这里instD直接传递可以减少同步读延后的时钟周期
assign instD = (reset == 1'b0) ? inst : 32'h0;
Dtrigger #(32) z1 (.clk(clk),.reset(reset),.clear(1'b0),.d(pc),.q(pcD));


//Decode Stage    
wire br_taken;
wire [31:0] br_target;    
wire [11:0] alu_op;
wire src1_is_pc;
wire src2_is_imm;
wire res_from_mem;
wire dst_is_r1;    
wire src_reg_is_rd;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] br_offs;
wire [31:0] jirl_offs;
    
wire need_ui5;
wire need_si12;
wire need_si16;
wire need_si20;
wire need_si26;
wire src2_is_4;    
 
wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire rf_we;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire [3:0] data_sram_weD;
wire data_sram_enD,equal_jump,nequal_jump,jump,base_pc_jump;    
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

assign rd   = instD[ 4: 0];
assign rj   = instD[ 9: 5];
assign rk   = instD[14:10];
assign i12  = instD[21:10];
assign i20  = instD[24: 5];
assign i16  = instD[25:10];
assign i26  = {instD[9: 0], instD[25:10]};

Controller c(.instD(instD),.valid(valid),.rf_we(rf_we),.res_from_mem(res_from_mem),
             .alu_op(alu_op),.data_sram_weD(data_sram_weD),.data_sram_enD(data_sram_enD),
             .dst_is_r1(dst_is_r1),.src_reg_is_rd(src_reg_is_rd),
             .src1_is_pc(src1_is_pc),.src2_is_imm(src2_is_imm),.need_ui5(need_ui5),.need_si12(need_si12),
             .need_si16(need_si16),.need_si20(need_si20),.need_si26(need_si26),.src2_is_4(src2_is_4),
             .equal_jump(equal_jump),.nequal_jump(nequal_jump),.jump(jump),
             .base_pc_jump(base_pc_jump));
             
wire [31:0] imm_lu12i = { i20, 12'b0};
wire [31:0] imm;
assign imm = src2_is_4 ? 32'h4 : need_si20 ? imm_lu12i : need_ui5  ? {{27{rk[4]}},rk[4:0]} : need_si12 ? {{20{i12[11]}}, i12[11:0]} : 32'h0;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0],2'b00} : {{14{i16[15]}}, i16[15:0],2'b00} ;
                         
assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

//写回阶段的信号和地址
wire [4:0] destW;
wire rfW;
wire [31:0] final_result;
assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;
regfile y1(
    .clk    (clk      ),
    .reset  (reset    ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
	.we     (rfW    ),
    .waddr  (destW ),
    .wdata  (final_result)
     );

wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire rj_eq_rd;

assign rj_value  = rf_rdata1;
assign rkd_value = rf_rdata2;
assign rj_eq_rd = (rj_value == rkd_value);
assign br_taken = (nequal_jump & ~rj_eq_rd) | (equal_jump &  rj_eq_rd) | jump;
assign br_target = (base_pc_jump) ? (pcD + br_offs) : (rj_value + jirl_offs);                                                   
assign dest          = dst_is_r1 ? 5'd1 : rd;
assign alu_src1 = src1_is_pc  ? pcD[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

assign seq_pc       = pc + 3'h4;
assign nextpc       = br_taken ? br_target : seq_pc;


//D-E
wire rfE,res_from_memE,data_sram_enE,dst_is_r1E;
wire [4:0] destE;
wire [31:0] pcE;
wire [11:0] alu_opE;
wire [3:0] data_sram_weE;
wire [31:0] rkd_valueE;
wire [31:0] alu_src1E;
wire [31:0] alu_src2E;
Dtrigger #(32) z2(.clk(clk),.reset(reset),.clear(1'b0),.d(pcD),.q(pcE));//1
Dtrigger #(1) z3(.clk(clk),.reset(reset),.clear(1'b0),.d(rf_we),.q(rfE));
Dtrigger #(5) z4(.clk(clk),.reset(reset),.clear(1'b0),.d(dest),.q(destE));
Dtrigger #(1) z5(.clk(clk),.reset(reset),.clear(1'b0),.d(res_from_mem),.q(res_from_memE));
Dtrigger #(12) z6(.clk(clk),.reset(reset),.clear(1'b0),.d(alu_op),.q(alu_opE));
Dtrigger #(1) z7(.clk(clk),.reset(reset),.clear(1'b0),.d(data_sram_enD),.q(data_sram_enE));
Dtrigger #(4) z8(.clk(clk),.reset(reset),.clear(1'b0),.d(data_sram_weD),.q(data_sram_weE));
Dtrigger #(32) z9(.clk(clk),.reset(reset),.clear(1'b0),.d(rkd_value),.q(rkd_valueE));
Dtrigger #(1) z10(.clk(clk),.reset(reset),.clear(1'b0),.d(dst_is_r1),.q(dst_is_r1E));
Dtrigger #(32) z11(.clk(clk),.reset(reset),.clear(1'b0),.d(alu_src1),.q(alu_src1E));
Dtrigger #(32) z12(.clk(clk),.reset(reset),.clear(1'b0),.d(alu_src2),.q(alu_src2E));


//Exe stage
wire [31:0] alu_result;
wire [4:0] destM;
wire [31:0] pcM;
wire rfM,res_from_memM,dst_is_r1M,data_sram_enM;
wire [3:0] data_sram_weM;
wire [31:0] rkd_valueM;
wire [31:0] alu_resultM;
alu u_alu(
    .alu_control(alu_opE   ),
    .alu_src1   (alu_src1E  ),
    .alu_src2   (alu_src2E  ),
    .alu_result (alu_result)
     );


//E-M
Dtrigger #(32) l1(.clk(clk),.reset(reset),.clear(1'b0),.d(pcE),.q(pcM));//2
Dtrigger #(5) l2(.clk(clk),.reset(reset),.clear(1'b0),.d(destE),.q(destM));
Dtrigger #(1) l3(.clk(clk),.reset(reset),.clear(1'b0),.d(rfE),.q(rfM));
Dtrigger #(1) l4(.clk(clk),.reset(reset),.clear(1'b0),.d(res_from_memE),.q(res_from_memM));
Dtrigger #(32) l5(.clk(clk),.reset(reset),.clear(1'b0),.d(alu_result),.q(alu_resultM));
Dtrigger #(32) l6(.clk(clk),.reset(reset),.clear(1'b0),.d(rkd_valueE),.q(rkd_valueM));
Dtrigger #(1) l7(.clk(clk),.reset(reset),.clear(1'b0),.d(dst_is_r1E),.q(dst_is_r1M));
Dtrigger #(1) l8(.clk(clk),.reset(reset),.clear(1'b0),.d(data_sram_enE),.q(data_sram_enM));
Dtrigger #(4) l9(.clk(clk),.reset(reset),.clear(1'b0),.d(data_sram_weE),.q(data_sram_weM));


//MEM stage
wire [31:0] mem_result;
wire dst_is_r1W,res_from_memW;
wire [31:0] alu_resultW;
wire [31:0] mem_resultW;
wire [31:0] pcW;
wire [31:0] final_resultW;
assign data_sram_en = data_sram_enM;
assign data_sram_we = data_sram_weM;
assign data_sram_addr  = alu_resultM;
assign data_sram_wdata = rkd_valueM;
assign mem_result  = data_sram_rdata;


//M-W
assign mem_resultW = mem_result;
Dtrigger #(32) y2(.clk(clk),.reset(reset),.clear(1'b0),.d(pcM),.q(pcW));//3
Dtrigger #(1) y3(.clk(clk),.reset(reset),.clear(1'b0),.d(rfM),.q(rfW));
Dtrigger #(5) y4(.clk(clk),.reset(reset),.clear(1'b0),.d(destM),.q(destW));
Dtrigger #(32) y5(.clk(clk),.reset(reset),.clear(1'b0),.d(alu_resultM),.q(alu_resultW));
Dtrigger #(1) y6(.clk(clk),.reset(reset),.clear(1'b0),.d(res_from_memM),.q(res_from_memW));
Dtrigger #(1) y7(.clk(clk),.reset(reset),.clear(1'b0),.d(dst_is_r1M),.q(dst_is_r1W));


//Write stage
assign final_result =  dst_is_r1W ? pcW + 3'h4 :
                        res_from_memW ? mem_result : alu_resultW;


//Debug stage
assign debug_wb_pc       = pcW;
assign debug_wb_rf_we   = {4{rfW}};
assign debug_wb_rf_wnum  = destW;//和pcD差个时钟周期
assign debug_wb_rf_wdata = final_result;

endmodule

