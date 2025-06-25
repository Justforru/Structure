`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/20 16:15:20
// Design Name: 
// Module Name: Controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Controller(
    input wire [31:0] instD,
    input wire valid,
    output wire rf_we,
    output wire res_from_mem,
    output wire [11:0] alu_op,
    output wire [3:0] data_sram_weD,
    output wire data_sram_enD,
    output wire dst_is_r1,
    output wire src_reg_is_rd,
    output wire src1_is_pc,
    output wire src2_is_imm,
    output wire need_ui5,
    output wire need_si12,
    output wire need_si16,
    output wire need_si20,
    output wire need_si26,
    output wire src2_is_4,
    output wire equal_jump,
    output wire nequal_jump,
    output wire jump,
    output wire base_pc_jump
    );
    
    wire [ 5:0] op_31_26;
    wire [ 3:0] op_25_22;
    wire [ 1:0] op_21_20;
    wire [ 4:0] op_19_15;
    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [ 3:0] op_21_20_d;
    wire [31:0] op_19_15_d;
     
    assign op_31_26  = instD[31:26];
    assign op_25_22  = instD[25:22];
    assign op_21_20  = instD[21:20];
    assign op_19_15  = instD[19:15];
   
    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));
    
    //译码20种指令的信号
    wire        inst_add_w;
    wire        inst_sub_w;
    wire        inst_slt;
    wire        inst_sltu;
    wire        inst_nor;
    wire        inst_and;
    wire        inst_or;
    wire        inst_xor;
    wire        inst_slli_w;
    wire        inst_srli_w;
    wire        inst_srai_w;
    wire        inst_addi_w;
    wire        inst_ld_w;
    wire        inst_st_w;
    wire        inst_jirl;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_lu12i_w;
    
    assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
    assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6] ;
    assign inst_bne    = op_31_26_d[6'h17];
    assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h2];
    assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h4];
    assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h5];
    assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h9];
    assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'ha];
    assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h8];
    assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'hb];
    assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h1];
    assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h9];
    assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    assign inst_lu12i_w  = op_31_26_d[6'h05] & (instD[25] == 1'b0);
    assign inst_jirl   = op_31_26_d[6'h13];
    assign inst_b      = op_31_26_d[6'h14];
    assign inst_bl     = op_31_26_d[6'h15];
    assign inst_beq    = op_31_26_d[6'h16];
       
    //产生输出的控制信号
    assign rf_we = inst_add_w | inst_ld_w | inst_addi_w | inst_sub_w | inst_slt | inst_sltu | inst_and | inst_or | inst_nor | inst_xor | inst_slli_w
                        | inst_srli_w | inst_srai_w | inst_lu12i_w | inst_jirl | inst_bl;
    assign res_from_mem  = inst_ld_w;
    assign alu_op = {inst_lu12i_w,inst_srai_w,inst_srli_w,inst_slli_w,inst_xor,
                      inst_or,inst_nor,inst_and,inst_sltu,inst_slt,inst_sub_w,
                      inst_add_w | inst_addi_w | inst_ld_w | inst_st_w | inst_bl |
                      inst_jirl};
    assign data_sram_weD = (inst_st_w == 1'b1) ? 4'b1111 : 4'b0000;
    assign data_sram_enD = inst_ld_w;
    assign dst_is_r1 = inst_bl;
    assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w ;
    assign src1_is_pc = inst_jirl | inst_bl;
    assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |					   
                       inst_addi_w |					   
					   inst_st_w   |
					   inst_lu12i_w|
                       inst_bl | inst_ld_w     ;                   
    assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
    assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w;
    assign need_si16  =  inst_jirl | inst_beq | inst_bne;
    assign need_si20  =  inst_lu12i_w;
    assign need_si26  =  inst_b | inst_bl;
    assign src2_is_4  =  inst_jirl | inst_bl;
    
    assign equal_jump = inst_beq;
    assign nequal_jump = inst_bne;
    assign jump = inst_b | inst_bl | inst_jirl;
    assign base_pc_jump = inst_beq | inst_bne | inst_b | inst_bl;
    
endmodule
