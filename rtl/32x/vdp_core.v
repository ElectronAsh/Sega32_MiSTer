module vdp_core (
	input RESET_N,
	
	input CLOCK,
	
	input [3:0] KEY,
	
	input [9:0] SW,

	input [21:1] SHA,
	
	inout [15:0] SHD,
	
	output SHSIRL1_N,
	output SHSIRL2_N,
	output SHSIRL3_N,
	
	input SHBS_N,
	
	output SHRESM_N,
	output SHRESS_N,
	
	output SHWAIT_N,
	
	input SHCS1_N,
	input SHCS2_N,
	input SHCS3_N,
	
	input SHCS0S_N,
	input SHCS0M_N,
	
	input SHBREQS_N,
	
	input SHRD_N,
	
	input SHDQMLL_N,
	input SHDQMLU_N,

	output SHCLK,
	
	input SHCKE,
	
	output SHDREQ0_N,
	output SHDREQ1_N,

	output NMI_S,
	
	input SCK,
	input TXDS,
	input TXDM,
	
	inout BACKS_N,
	
	output SHMIRL1_N,
	output SHMIRL2_N,
	output SHMIRL3_N,
	
	output NMI_M,
	
	input FT0B_M,
	
	input BACKM_N,
	
	input SHCAS_N,
	input SHRAS_N,
	input SHRDWR,
	
	output wire BIOS_CS,
	output wire REGS_CS,
	output wire COMS_CS,
	output wire PWM_CS,
	output wire VDP_CS,
	output wire CRAM_CS,
	output wire CART_CS,
	output wire FB_CS,
	output wire FB_OVR_CS,
	output wire SDRAM_CS,
	
	input HSYNC,
	input VSYNC,
	
	output [7:0] LEDG,

	output [15:0] AUD_L,
	output [15:0] AUD_R,
	
	output FB_SWAP,
	
	output [1:0] FB_MODE,
	
	output VDP_LSHIFT,
	
	output READ_PULSE_OUT,
	output WRITE_PULSE_OUT,
	
	input [23:0] MD_ADDR,
	input [15:0] MBUS_DO,			// From the MD core TO the 32x VDP.
	output wire [15:0] MBUS_DI,	// From the 32x VDP TO the MD core.
	
	input MD_AS_N,
	input MBUS_RNW,
	input MBUS_UDS_N,
	input MBUS_LDS_N,

	output wire MARS_DTACK_N,
	input MARS_SEL,
	
	input [15:0] CART_DI
);

assign MARS_DTACK_N = 1'b0;


(*keep*) wire MD_LWR_N	= !(!MBUS_RNW & !MBUS_UDS_N);
(*keep*) wire MD_UWR_N	= !(!MBUS_RNW & !MBUS_LDS_N);

wire MD_CART_CS = (MD_ADDR>=24'h000000 && MD_ADDR<=24'h3FFFFF);
wire MD_MIRR_CS = (MD_ADDR>=24'h900000 && MD_ADDR<=24'h9FFFFF);
													
wire MD_MARS_CS = (MD_ADDR>=24'hA130EC && MD_ADDR<=24'hA130EF);

wire MD_CON_CS  = (MD_ADDR>=24'hA15100 && MD_ADDR<=24'hA15101);
wire MD_INTC_CS = (MD_ADDR>=24'hA15102 && MD_ADDR<=24'hA15103);
wire MD_BANK_CS = (MD_ADDR>=24'hA15104 && MD_ADDR<=24'hA15105);
wire MD_DREQ_CS = (MD_ADDR>=24'hA15106 && MD_ADDR<=24'hA15107);
wire MD_COMS_CS = (MD_ADDR>=24'hA15120 && MD_ADDR<=24'hA1512F);

// MD core Data IN mux...
assign MBUS_DI = (MD_CART_CS | MD_MIRR_CS) ? CART_DI : 
					  (MD_MARS_CS && !MD_ADDR[1]) ? "MA" :
					  (MD_MARS_CS && MD_ADDR[1])  ? "RS" :
					  //(MD_CON_CS)					  ? 16'h0081 :
					  (MD_CON_CS)					    ? 16'h0181 :
					  (MD_COMS_CS) ? COMMS_DO :
					  16'hFFFF;


/*
reg MD_AS_N_1;
reg MD_CE0_N_1;
reg MD_UWR_N_1;
reg MD_LWR_N_1;

reg [23:0] MD_ADDR_PREV;
initial MD_ADDR_PREV <= 24'hDEDBAD;

wire MD_AS_N_FALLING = (MD_AS_N_1 && !MD_AS_N);
wire MD_UWR_N_FALLING = (MD_UWR_N_1 && !MD_UWR_N);
wire MD_LWR_N_FALLING = (MD_LWR_N_1 && !MD_LWR_N);
wire MD_ADDR_CHANGED = (MD_ADDR != MD_ADDR_PREV);

always @(posedge clk_sys or posedge reset)
if (reset) begin

end
else begin
	MD_AS_N_1 <= MD_AS_N;
	MD_UWR_N_1 <= MD_UWR_N;
	MD_LWR_N_1 <= MD_LWR_N;
	MD_ADDR_PREV <= MD_ADDR;
end
*/

assign READ_PULSE_OUT = READ_PULSE;
assign WRITE_PULSE_OUT = WRITE_PULSE;

assign VDP_LSHIFT = VDP_SHIFT[0];

assign FB_MODE = VDP_MODE[1:0];

assign FB_SWAP = VDP_FB_CONT[0];	// This bit selects which Framebuffer (DRAM) will be displayed.

assign SHDREQ0_N = SW[8] & FAKE_PWM;	// Shouldn't really use "FAKE_PWM" here, as DMA chan 0 is meant for 68K <> SH2 transfers.
assign SHDREQ1_N = SW[7] & FAKE_PWM;

assign COMMS_0 = COMMS_4020;
assign COMMS_1 = COMMS_4022;
assign COMMS_2 = COMMS_4024;
assign COMMS_3 = COMMS_4026;


assign SHCLK = CLOCK;

assign SHRESM_N = RESET_N;
assign SHRESS_N = RESET_N;

assign SHWAIT_N = 1'b1;


assign NMI_M = 1'b1;
assign NMI_S = 1'b1;

// Set SWITCH 1 High to DISABLE the Slave SH2!
//assign BACKS_N = (!SW[1]) ? BACKM_N : 1'b1;
assign BACKS_N = BACKM_N;


wire [15:0] MS_BIOS_DATA;
sh2_master_rom	sh2_master_rom_inst (
	.address ( SHA[10:1] ),
	.clock ( CLOCK ),
	.q ( MS_BIOS_DATA )
);

wire [15:0] SL_BIOS_DATA;
sh2_slave_rom	sh2_slave_rom_inst (
	.address ( SHA[10:1] ),
	.clock ( CLOCK ),
	.q ( SL_BIOS_DATA )
);


wire [21:0] SH_ADDR = {SHA,1'b0}/*synthesis keep*/;

wire CS0 = !SHCS0M_N | !SHCS0S_N;
wire CS1 = !SHCS1_N;
wire CS2 = !SHCS2_N;


wire LEFT_FIFO_WRITE  = PWM_CS && SHA[3:1]==3'd2 && WRITE_PULSE;
wire RIGHT_FIFO_WRITE = PWM_CS && SHA[3:1]==3'd3 && WRITE_PULSE;
wire MONO_FIFO_WRITE  = PWM_CS && SHA[3:1]==3'd4 && WRITE_PULSE;


pwm_fifo	pwm_fifo_left (
	.clock ( CLOCK ),
	.data ( SHD ),
	.wrreq ( LEFT_FIFO_WRITE | MONO_FIFO_WRITE ),
	.empty ( LEFT_FIFO_EMPTY ),
	.full ( LEFT_FIFO_FULL ),
	.rdreq ( !LEFT_FIFO_EMPTY & FAKE_PWM ),
	.q ( AUD_L )
//	.usedw ( usedw )
);

pwm_fifo	pwm_fifo_right (
	.clock ( CLOCK ),
	.data ( SHD ),
	.wrreq ( RIGHT_FIFO_WRITE | MONO_FIFO_WRITE ),
	.empty ( RIGHT_FIFO_EMPTY ),
	.full ( RIGHT_FIFO_FULL ),
	.rdreq ( !RIGHT_FIFO_EMPTY & FAKE_PWM ),
	.q ( AUD_R )
//	.usedw ( usedw )
);

// Not sure how to handle these yet?...
wire MONO_FIFO_FULL = LEFT_FIFO_FULL;
wire MONO_FIFO_EMPTY = LEFT_FIFO_EMPTY;


// CS0 is the 0x00000000 to 0x001FFFFF memory range...
assign BIOS_CS  = CS0 && (SH_ADDR >= 22'h000000 && SH_ADDR <= 22'h0007FF)/*synthesis keep*/;
assign REGS_CS  = CS0 && (SH_ADDR >= 22'h004000 && SH_ADDR <= 22'h00401F)/*synthesis keep*/;
assign COMS_CS  = CS0 && (SH_ADDR >= 22'h004020 && SH_ADDR <= 22'h00402F)/*synthesis keep*/;
assign PWM_CS	 = CS0 && (SH_ADDR >= 22'h004030 && SH_ADDR <= 22'h00403F)/*synthesis keep*/;
assign VDP_CS   = CS0 && (SH_ADDR >= 22'h004100 && SH_ADDR <= 22'h0041FF)/*synthesis keep*/;
assign CRAM_CS  = CS0 && (SH_ADDR >= 22'h004200 && SH_ADDR <= 22'h0043FF)/*synthesis keep*/;	// Colour Palette.

// CS1 is the 0x02000000 to 0x021FFFFF memory range (maybe more, but haven't checked)...
assign CART_CS  = CS1 && (SH_ADDR >= 22'h000000 && SH_ADDR <= 22'h3FFFFF)/*synthesis keep*/;

// CS2 is the 0x04000000 to 0x041FFFFF memory range (maybe more, but haven't checked)...
assign FB_CS   	= CS2 && (SH_ADDR >= 22'h000000 && SH_ADDR <= 22'h01FFFF)/*synthesis keep*/;
assign FB_OVR_CS	= CS2 && (SH_ADDR >= 22'h020000 && SH_ADDR <= 22'h03FFFF)/*synthesis keep*/;

// CS3 is the 0x06000000 to 0x061FFFFF memory range (maybe more, but haven't checked)...
// SDRAM is also an external chip on the Dual SH2 adapter now. OzOnE.
assign SDRAM_CS = !SHCS3_N;



wire [15:0] LEFT_FIFO_STAT  = {LEFT_FIFO_FULL, LEFT_FIFO_EMPTY, 14'h0000};
wire [15:0] RIGHT_FIFO_STAT = {RIGHT_FIFO_FULL, RIGHT_FIFO_EMPTY, 14'h0000};
wire [15:0] MONO_FIFO_STAT  = {MONO_FIFO_FULL, MONO_FIFO_EMPTY, 14'h0000};


assign SHD =
				(BIOS_CS && !SHRD_N && !SHCS0M_N) ? {MS_BIOS_DATA[7:0],MS_BIOS_DATA[15:8]} :
				(BIOS_CS && !SHRD_N && !SHCS0S_N) ? {SL_BIOS_DATA[7:0],SL_BIOS_DATA[15:8]} :
										
				(REGS_CS && !SHRD_N && !SHCS0M_N && SHA[4:1]==4'd0)  ? {INT_CONT[15:4],INT_CONT_NIB_M} :			// 0x4000
				(REGS_CS && !SHRD_N && !SHCS0S_N && SHA[4:1]==4'd0)  ? {INT_CONT[15:4],INT_CONT_NIB_S} :			// 0x4000
				
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd1)  ? STANDBY_CHANGE :	// 0x4002
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd2)  ? H_COUNT :			// 0x4004
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd3)  ? MONO_FIFO_STAT /*DREQ_CONT*/ : // 0x4006.
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd4)  ? DREQ_SRC_HIGH :	// 0x4008
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd5)  ? DREQ_SRC_LOW :		// 0x400A
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd6)  ? DREQ_DEST_HIGH :	// 0x400C
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd7)  ? DREQ_DEST_LOW :	// 0x400E
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd8)  ? DREQ_LEN :			// 0x4010
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd9)  ? FIFO_REG :			// 0x4012
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd10) ? VRES_INT_CLEAR :	// 0x4014
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd11) ? VINT_CLEAR :		// 0x4016
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd12) ? HINT_CLEAR :		// 0x4018
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd13) ? CINT_CLEAR :		// 0x401A
				(REGS_CS && !SHRD_N && SHA[4:1]==4'd14) ? PINT_CLEAR :		// 0x401C
				
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd0) ? COMMS_4020 :			// 0x4020
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd1) ? COMMS_4022 :			// 0x4022
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd2) ? COMMS_4024 :			// 0x4024
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd3) ? COMMS_4026 :			// 0x4026
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd4) ? COMMS_4028 :  		// 0x4028
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd5) ? COMMS_402A :  		// 0x402A
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd6) ? COMMS_402C :  		// 0x402C
				(COMS_CS && !SHRD_N && SHA[3:1]==3'd7) ? COMMS_402E :  		// 0x402E
			
				(PWM_CS && !SHRD_N && SHA[3:1]==3'd0) ? PWM_CONT :							// 0x4030.
				(PWM_CS && !SHRD_N && SHA[3:1]==3'd1) ? PWM_CYCLE :						// 0x4032.
				(PWM_CS && !SHRD_N && SHA[3:1]==3'd2) ? LEFT_FIFO_STAT /*PWM_LCH_WIDTH*/  :	// 0x4034.
				(PWM_CS && !SHRD_N && SHA[3:1]==3'd3) ? RIGHT_FIFO_STAT /*PWM_RCH_WIDTH*/ :	// 0x4036.
				(PWM_CS && !SHRD_N && SHA[3:1]==3'd4) ? MONO_FIFO_STAT /*PWM_MONO_WIDTH*/ :	// 0x4038.
				
				(VDP_CS && !SHRD_N && SHA[3:1]==3'd0) ? VDP_MODE :			// 0x4100
				(VDP_CS && !SHRD_N && SHA[3:1]==3'd1) ? VDP_SHIFT :		// 0x4102
				(VDP_CS && !SHRD_N && SHA[3:1]==3'd2) ? VDP_FILL_LEN :	// 0x4104
				(VDP_CS && !SHRD_N && SHA[3:1]==3'd3) ? VDP_FILL_START :	// 0x4106
				(VDP_CS && !SHRD_N && SHA[3:1]==3'd4) ? VDP_FILL_DATA :	// 0x4108
				(VDP_CS && !SHRD_N && SHA[3:1]==3'd5) ? VDP_FB_CONT :		// 0x410A

				// These patches all relate to the Kolibri (World) ROM!...
				//(SDRAM_CS && SH_ADDR>=22'h00095E && SH_ADDR<=22'h000961) ? 16'h0009 :	// NOP out the "SLAV" check.
				//(SDRAM_CS && SH_ADDR>=22'h0015A0 && SH_ADDR<=22'h0015AB) ? 16'h0009 :	// NOP out another check. Checks a value in SDRAM at 0x26000802.
				//(SDRAM_CS && SH_ADDR>=22'h00166E && SH_ADDR<=22'h00166F) ? 16'h0009 :	// NOP out another check.
				//(SDRAM_CS && SH_ADDR>=22'h000B1A && SH_ADDR<=22'h000B1E) ? 16'h0009 :	// NOP out a loop / check.
				//(SDRAM_CS && SH_ADDR>=22'h000B36 && SH_ADDR<=22'h000B39) ? 16'h0009 :	// NOP out a loop / check.
				//(SDRAM_CS && SH_ADDR>=22'h001622 && SH_ADDR<=22'h001625) ? 16'h0009 :	// NOP out a loop / check.
				
				// 32x BIOS patches (for debugging)...
				//(SH_ADDR>=32'h000001F0 && SH_ADDR<=32'h000001F6) ? 16'h0009 :	// NOP out the SDRAM test!
				
				(CART_CS && !SHRD_N) ? CART_DI :				// 0x02000000.
				
				16'hzzzz;

// M_OK = 0x4D5F4F4B
// S_OK = 0x535F4F4B
// SLAV = 0x534C4156


// Not sure about these? They were described in Dr Devster's doc, but not sure yet if the MAME source uses them? OzOnE.
//
// Ohhhhhhhh - they are the MD / Genesis side registers. doh!
// I'll figure these out later.
//
//wire [31:0] BUS_ARB_HIGH	= 32'h02000000;	// 0x00
//wire [31:0] BUS_ARB_LOW 	= 33'h00000000;	// 0x01
//wire [31:0] CART_BANK		= 32'h00000000;	// 0x04
//wire [31:0] TV_FIFO		= 32'h00000000;	// 0x12


// Interrupt levels (from the 32x hardware manual)...
//
// IRL 14	VRES		Interrupt when the MD reset button has been pressed.
// IRL 12	VINT		V Blank Interrupt.
// IRL 10	HINT		H Blank Interrupt.
// IRL 8		CMD_INT	Interrupt through register set from MD side.
// IRL 6		PWM_TMR	Interrupt through PWM synchronous timer.
//


reg HSYNC_1;
reg VSYNC_1;

wire HSYNC_FALLING = (HSYNC_1 & !HSYNC);
wire VSYNC_FALLING = (VSYNC_1 & !VSYNC);

reg VRES_TRIG_M;
reg VSYNC_TRIG_M;
reg HSYNC_TRIG_M;
reg CINT_TRIG_M;
reg PINT_TRIG_M;

reg VRES_TRIG_S;
reg VSYNC_TRIG_S;
reg HSYNC_TRIG_S;
reg CINT_TRIG_S;
reg PINT_TRIG_S;

// Master...
wire VINT_ENA_M = INT_CONT_NIB_M[3];	// VBlank Interrupt Mask. 0=Mask. 1=Valid.
wire HINT_ENA_M = INT_CONT_NIB_M[2];	// HBlank Interrupt Mask. 0=Mask. 1=Valid.
wire CINT_ENA_M = INT_CONT_NIB_M[1];	// Command Interrupt Mask. 0=Mask. 1=Valid.
wire PINT_ENA_M = INT_CONT_NIB_M[0];	// PWM Timer Interrupt Mask. 0=Mask. 1=Valid.


// Slave...
wire VINT_ENA_S = INT_CONT_NIB_S[3];	// VBlank Interrupt Mask. 0=Mask. 1=Valid.
wire HINT_ENA_S = INT_CONT_NIB_S[2];	// HBlank Interrupt Mask. 0=Mask. 1=Valid.
wire CINT_ENA_S = INT_CONT_NIB_S[1];	// Command Interrupt Mask. 0=Mask. 1=Valid.
wire PINT_ENA_S = INT_CONT_NIB_S[0];	// PWM Timer Interrupt Mask. 0=Mask. 1=Valid.

reg [11:0] PWM_COUNT;

reg [18:0] CLK_DIV;
always @(posedge CLOCK or negedge RESET_N)
if (!RESET_N) begin
	VRES_TRIG_M <= 1'b0;
	VSYNC_TRIG_M <= 1'b0;
	HSYNC_TRIG_M <= 1'b0;
	CINT_TRIG_M <= 1'b0;
	PINT_TRIG_M <= 1'b0;
	
	VRES_TRIG_S <= 1'b0;
	VSYNC_TRIG_S <= 1'b0;
	HSYNC_TRIG_S <= 1'b0;
	CINT_TRIG_S <= 1'b0;
	PINT_TRIG_S <= 1'b0;
end
else begin
	CLK_DIV <= CLK_DIV + 1;
	
	if (PWM_COUNT==0) PWM_COUNT <= PWM_CYCLE[11:0];
	else PWM_COUNT <= PWM_COUNT - 1;

	HSYNC_1 <= HSYNC;
	VSYNC_1 <= VSYNC;

	// Master...
	if (!SHCS0M_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h14 && SH_ADDR[7:0]<=8'h15) VRES_TRIG_M <= 1'b0;		// VRES_CLEAR. 0x4014.
	if (!SHCS0M_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h16 && SH_ADDR[7:0]<=8'h17) VSYNC_TRIG_M <= 1'b0;	// VINT_CLEAR. 0x4016
	if (!SHCS0M_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h18 && SH_ADDR[7:0]<=8'h19) HSYNC_TRIG_M <= 1'b0;	// HINT_CLEAR. 0x4018.
	if (!SHCS0M_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h1A && SH_ADDR[7:0]<=8'h1B) CINT_TRIG_M <= 1'b0;		// CINT_CLEAR. 0x401A.
	if (!SHCS0M_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h1C && SH_ADDR[7:0]<=8'h1D) PINT_TRIG_M <= 1'b0;		// PINT_CLEAR. 0x401C.

	VRES_TRIG_M <= SW[1];
	if (FAKE_VBLANK) VSYNC_TRIG_M <= SW[2] && VINT_ENA_M;
	if (FAKE_HBLANK) HSYNC_TRIG_M <= SW[3] && HINT_ENA_M;
	if (FAKE_VBLANK) CINT_TRIG_M  <= SW[4] && CINT_ENA_M;
	if (FAKE_PWM) 	  PINT_TRIG_M  <= SW[5] && PINT_ENA_M;


	// Slave...
	if (!SHCS0S_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h14 && SH_ADDR[7:0]<=8'h15) VRES_TRIG_S <= 1'b0;		// VRES_CLEAR. 0x4014.
	if (!SHCS0S_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h16 && SH_ADDR[7:0]<=8'h17) VSYNC_TRIG_S <= 1'b0;	// VINT_CLEAR. 0x4016
	if (!SHCS0S_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h18 && SH_ADDR[7:0]<=8'h19) HSYNC_TRIG_S <= 1'b0;	// HINT_CLEAR. 0x4018.
	if (!SHCS0S_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h1A && SH_ADDR[7:0]<=8'h1B) CINT_TRIG_S <= 1'b0;		// CINT_CLEAR. 0x401A.
	if (!SHCS0S_N && REGS_CS && WRITE_PULSE && SH_ADDR[7:0]>=8'h1C && SH_ADDR[7:0]<=8'h1D) PINT_TRIG_S <= 1'b0;		// PINT_CLEAR. 0x401C.
	
	VRES_TRIG_S <= SW[1];
	if (FAKE_VBLANK) VSYNC_TRIG_S <= SW[2] && VINT_ENA_S;
	if (FAKE_HBLANK) HSYNC_TRIG_S <= SW[3] && HINT_ENA_S;
	if (FAKE_VBLANK) CINT_TRIG_S  <= SW[4] && CINT_ENA_S;
	if (FAKE_PWM) 	  PINT_TRIG_S  <= SW[5] && PINT_ENA_S;
end

wire FAKE_VBLANK = CLK_DIV[18:0]==0;
wire FAKE_HBLANK = CLK_DIV[10:0]==0;
wire FAKE_PWM	  = PWM_COUNT==0;



// NOTE: On both SH2 CPUs, the FT0A output pin is tied directly to their IPL0_N inputs. (on each respective SH2)
//
// So, the interrupt levels will generally be mapped at both their Odd and Even priority numbers.
// (since the FT0A signal forms the LSB bit of IPL_N, and may be High or Low at any given time.)
//
// eg. The following interrupt level table was taken from the Sega 32x "Technical Information Attachment 1" PDF...
//
// noret,	; Illegal Interrupt
// noret,	; Level 1
// noret,	; Level 2
// noret,	; Level 3
// noret,	; Level 4
// noret,	; Level 5
// pwmint,	; Level 6
// pwmint,	; Level 7
// cmdint,	; Level 8
// cmdint,	; Level 9
// hint,		; Level 10
// hint,		; Level 11
// vint,		; Level 12
// vint,		; Level 13
// vresint,	; Level 14
// vresint,	; Level 15
// 
// AFAIK it looks like the Interrupt Level does go to both SH2s, but I don't quite know yet why
// the IPL_N signals for each SH2 still have separate outputs from the 32x main ASIC? OzOnE.
//

// IRL = Interrupt Level...
//
// TODO - Each SH2 has it's own Interrupt Enables! OzOnE.

// MASTER...
wire VRES_INT_M = VRES_TRIG_M;
wire VINT_M		 = VSYNC_TRIG_M;
wire HINT_M		 = HSYNC_TRIG_M;
wire CINT_M		 = CINT_TRIG_M;
wire PINT_M		 = PINT_TRIG_M;

wire [3:0] IRL_M = (VRES_INT_M)	? 4'd14 :// Vector number 71.
						 (VINT_M)		? 4'd12 :// Vector number 70.
						 (HINT_M)		? 4'd10 :// Vector number 69.
						 (CINT_M)		? 4'd8 :	// Vector number 68.
						 (PINT_M)		? 4'd6 :	// Vector number 67.
											  4'd0;	// Idle. (no interrupt).
assign SHMIRL1_N = !IRL_M[1];
assign SHMIRL2_N = !IRL_M[2];
assign SHMIRL3_N = !IRL_M[3];


// SLAVE...
wire VRES_INT_S = VRES_TRIG_S;
wire VINT_S		 = VSYNC_TRIG_S;
wire HINT_S		 = HSYNC_TRIG_S;
wire CINT_S		 = CINT_TRIG_S;
wire PINT_S		 = PINT_TRIG_S;

wire [3:0] IRL_S = (VRES_INT_S)	? 4'd14 :// Vector number 71.
						 (VINT_S)		? 4'd12 :// Vector number 70.
						 (HINT_S)		? 4'd10 :// Vector number 69.
						 (CINT_S)		? 4'd8 :	// Vector number 68.
						 (PINT_S)		? 4'd6 :	// Vector number 67.
											  4'd0;	// Idle. (no interrupt).

assign SHSIRL1_N = !IRL_S[1];
assign SHSIRL2_N = !IRL_S[2];
assign SHSIRL3_N = !IRL_S[3];


// This is only really for the benefit of SignalTap and the LEDs,
// since we now have separate Interrupt Enable nibbles for the Master and Slave SH2...
wire CONT_FM	= INT_CONT[15];// VDP Access. 0=MD. 1=SH2.
wire CONT_ADEN	= INT_CONT[9];	// Adapter Enable. 0=32x use prohibited. 1=32x use allowed.
wire CONT_CART	= INT_CONT[8];	// 0=Cart Inserted. 1=Cart NOT inserted. (Active-LOW!)
wire CONT_HEN	= INT_CONT[7];	// H INT approval within VBLANK.
// Interrupt Enables...
wire CONT_V		= INT_CONT_NIB_M[3];
wire CONT_H		= INT_CONT_NIB_M[2];
wire CONT_CMD	= INT_CONT_NIB_M[1];
wire CONT_PWM	= INT_CONT_NIB_M[0];

//INT_CONT		= {CONT_FM, 5'b00000, CONT_ADEN, CONT_CART, CONT_HEN, 3'b000, CONT_V, CONT_H, CONT_CMD, CONT_PWM};

assign LEDG = {CONT_FM, CONT_ADEN, CONT_CART, CONT_HEN, CONT_V, CONT_H, CONT_CMD, CONT_PWM};	// Bits are NOT contiguous! OzOnE.

reg [3:0] INT_CONT_NIB_M;
reg [3:0] INT_CONT_NIB_S;

// 32x ASIC regs...
reg [15:0] INT_CONT;			// 0x4000
reg [15:0] STANDBY_CHANGE;	// 0x4002
reg [15:0] H_COUNT;			// 0x4004
reg [15:0] DREQ_CONT;		// 0x4006
reg [15:0] DREQ_SRC_HIGH;	// 0x4008
reg [15:0] DREQ_SRC_LOW;	// 0x400A
reg [15:0] DREQ_DEST_HIGH;	// 0x400C
reg [15:0] DREQ_DEST_LOW;	// 0x400E
reg [15:0] DREQ_LEN;			// 0x4010
reg [15:0] FIFO_REG;			// 0x4012
reg [15:0] VRES_INT_CLEAR;	// 0x4014
reg [15:0] VINT_CLEAR;		// 0x4016
reg [15:0] HINT_CLEAR;		// 0x4018
reg [15:0] CINT_CLEAR;		// 0x401A
reg [15:0] PINT_CLEAR;		// 0x401C

reg [15:0] COMMS_4020/*synthesis noprune*/;
reg [15:0] COMMS_4022/*synthesis noprune*/;
reg [15:0] COMMS_4024/*synthesis noprune*/;
reg [15:0] COMMS_4026/*synthesis noprune*/;
reg [15:0] COMMS_4028/*synthesis noprune*/;
reg [15:0] COMMS_402A/*synthesis noprune*/;
reg [15:0] COMMS_402C/*synthesis noprune*/;
reg [15:0] COMMS_402E/*synthesis noprune*/;

reg [15:0] PWM_CONT;			// 0x4030
reg [15:0] PWM_CYCLE;		// 0x4032
reg [15:0] PWM_LCH_WIDTH;	// 0x4034
reg [15:0] PWM_RCH_WIDTH;	// 0x4036
reg [15:0] PWM_MONO_WIDTH; // 0x4038


// 32x VDP regs.
reg [15:0] VDP_MODE;			// 0x4100
reg [15:0] VDP_SHIFT;		// 0x4102
reg [15:0] VDP_FILL_LEN;	// 0x4104
reg [15:0] VDP_FILL_START;	// 0x4106
reg [15:0] VDP_FILL_DATA;	// 0x4108
reg [15:0] VDP_FB_CONT;		// 0x410A

//reg [15:0] CRAM [0:255];

reg [3:0] DOOM_STATE;

reg SHBS_N_1;
wire SHBS_N_RISING = (!SHBS_N_1 & SHBS_N);

wire READ_PULSE  = SHBS_N_RISING & !SHRD_N;
wire WRITE_PULSE = SHBS_N_RISING & SHRD_N;

reg KEY_1;
reg KEY_2;
reg KEY_3;

reg [7:0] STATE;
always @(posedge CLOCK or negedge RESET_N)
if (!RESET_N) begin
	STATE <= 8'd0;
	
	DOOM_STATE <= 4'h0;
	
	KEY_1 <= 1'b0;
	KEY_2 <= 1'b0;
	KEY_3 <= 1'b0;
	
	INT_CONT_NIB_M <= 4'h0;
	INT_CONT_NIB_S <= 4'h0;
	
	//INT_CONT		= {CONT_FM, 5'b00000, CONT_ADEN, CONT_CART, CONT_HEN, 3'b000, CONT_V, CONT_H, CONT_CMD, CONT_PWM};
	INT_CONT <= {1'b1, 5'b00000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0}; // 0x4000
	STANDBY_CHANGE	<= 16'h0000; // 0x4002
	H_COUNT			<= 16'h0000; // 0x4004
	DREQ_CONT		<= 16'h0000; // 0x4006
	DREQ_SRC_HIGH	<= 16'h0000; // 0x4008
	DREQ_SRC_LOW	<= 16'h0000; // 0x400A
	DREQ_DEST_HIGH	<= 16'h0000; // 0x400C
	DREQ_DEST_LOW	<= 16'h0000; // 0x400E
	DREQ_LEN			<= 16'h0000; // 0x4010
	FIFO_REG			<= 16'h0000; // 0x4012
	VRES_INT_CLEAR	<= 16'h0000; // 0x4014
	VINT_CLEAR    	<= 16'h0000; // 0x4016
	HINT_CLEAR     <= 16'h0000; // 0x4018
	CINT_CLEAR		<= 16'h0000; // 0x401A
	PINT_CLEAR		<= 16'h0000; // 0x401C
	
	COMMS_4020		<= 16'h0000; // 0x4020
	COMMS_4022		<= 16'h0000; // 0x4022
	COMMS_4024		<= 16'h0000; // 0x4024
	COMMS_4026		<= 16'h0000; // 0x4026
	COMMS_4028		<= 16'h0000; // 0x4028
	COMMS_402A		<= 16'h0000; // 0x402A
	COMMS_402C		<= 16'h0000; // 0x402C
	COMMS_402E		<= 16'h0000; // 0x402E
	
	PWM_CONT			<= 16'h0000; // 0x4030
	PWM_CYCLE		<= 16'h0000; // 0x4032
	PWM_LCH_WIDTH	<= 16'h4000; // 0x4034
	PWM_RCH_WIDTH	<= 16'h4000; // 0x4036
	PWM_MONO_WIDTH	<= 16'h4000; // 0x4038
	
	VDP_MODE			<= 16'h0000; // 0x4100
	VDP_SHIFT		<= 16'h0000; // 0x4102
	VDP_FILL_LEN	<= 16'h0000; // 0x4104
	VDP_FILL_START <= 16'h0000; // 0x4106
	VDP_FILL_DATA	<= 16'h0000; // 0x4108
	VDP_FB_CONT		<= 16'h0000; // 0x410A
	
	SHBS_N_1 <= 1'b0;
end
else begin
	SHBS_N_1 <= SHBS_N;

	// Main Reg writes...
	if (REGS_CS && WRITE_PULSE) begin // 0x4000.
		case (SHA[4:1])
		0: begin
			if (!SHDQMLU_N) INT_CONT[15:8] <= SHD[15:8];
					
			if (!SHDQMLL_N) begin
				INT_CONT[7:0] <= SHD[7:0];
				if (!SHCS0M_N) INT_CONT_NIB_M <= SHD[3:0];
				if (!SHCS0S_N) INT_CONT_NIB_S <= SHD[3:0];
			end
		end
		
		1: begin if (!SHDQMLU_N) STANDBY_CHANGE[15:8] <= SHD[15:8]; if (!SHDQMLL_N) STANDBY_CHANGE[7:0] <= SHD[7:0]; end	// 0x4002.
		2: begin if (!SHDQMLU_N) H_COUNT[15:8]			 <= SHD[15:8]; if (!SHDQMLL_N) H_COUNT[7:0]			<= SHD[7:0]; end	// 0x4004.
		3: begin if (!SHDQMLU_N) DREQ_CONT[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) DREQ_CONT[7:0]		<= SHD[7:0]; end	// 0x4006.
		4: begin if (!SHDQMLU_N) DREQ_SRC_HIGH[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) DREQ_SRC_HIGH[7:0]  <= SHD[7:0]; end	// 0x4008.
		5: begin if (!SHDQMLU_N) DREQ_SRC_LOW[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) DREQ_SRC_LOW[7:0]	<= SHD[7:0]; end	// 0x400A.
		6: begin if (!SHDQMLU_N) DREQ_DEST_HIGH[15:8] <= SHD[15:8]; if (!SHDQMLL_N) DREQ_DEST_HIGH[7:0] <= SHD[7:0]; end	// 0x400C.
		7: begin if (!SHDQMLU_N) DREQ_DEST_LOW[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) DREQ_DEST_LOW[7:0]  <= SHD[7:0]; end	// 0x400E.
		8: begin if (!SHDQMLU_N) DREQ_LEN[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) DREQ_LEN[7:0]			<= SHD[7:0]; end	// 0x4010.
		9: begin if (!SHDQMLU_N) FIFO_REG[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) FIFO_REG[7:0]			<= SHD[7:0]; end	// 0x4012.
		10: begin if (!SHDQMLU_N) VRES_INT_CLEAR[15:8] <= SHD[15:8]; if (!SHDQMLL_N) VRES_INT_CLEAR[7:0] <= SHD[7:0]; end	// 0x4014.
		11: begin if (!SHDQMLU_N) VINT_CLEAR[15:8] 	 <= SHD[15:8]; if (!SHDQMLL_N) VINT_CLEAR[7:0]  	<= SHD[7:0]; end	// 0x4016.
		12: begin if (!SHDQMLU_N) HINT_CLEAR[15:8] 	 <= SHD[15:8]; if (!SHDQMLL_N) HINT_CLEAR[7:0]  	<= SHD[7:0]; end	// 0x4018.
		13: begin if (!SHDQMLU_N) CINT_CLEAR[15:8] 	 <= SHD[15:8]; if (!SHDQMLL_N) CINT_CLEAR[7:0]  	<= SHD[7:0]; end	// 0x401A.
		14: begin if (!SHDQMLU_N) PINT_CLEAR[15:8] 	 <= SHD[15:8]; if (!SHDQMLL_N) PINT_CLEAR[7:0]  	<= SHD[7:0]; end	// 0x401C.
		default:;
		endcase
	end
	
	// 32x COMS Reg writes...
	if (COMS_CS && WRITE_PULSE) begin
		case (SHA[3:1])
		0: begin if (!SHDQMLU_N) COMMS_4020[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_4020[7:0]  <= SHD[7:0]; end	// 0x4020.
		1: begin if (!SHDQMLU_N) COMMS_4022[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_4022[7:0]  <= SHD[7:0]; end	// 0x4022.
		2: begin if (!SHDQMLU_N) COMMS_4024[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_4024[7:0]  <= SHD[7:0]; end	// 0x4024.
		3: begin if (!SHDQMLU_N) COMMS_4026[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_4026[7:0]  <= SHD[7:0]; end	// 0x4026.
		4: begin if (!SHDQMLU_N) COMMS_4028[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_4028[7:0]  <= SHD[7:0]; end	// 0x4028.
		5: begin if (!SHDQMLU_N) COMMS_402A[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_402A[7:0]  <= SHD[7:0]; end	// 0x402A.
		6: begin if (!SHDQMLU_N) COMMS_402C[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_402C[7:0]  <= SHD[7:0]; end	// 0x402C.
		7: begin if (!SHDQMLU_N) COMMS_402E[15:8] <= SHD[15:8]; if (!SHDQMLL_N) COMMS_402E[7:0]  <= SHD[7:0]; end	// 0x402E.
		default:;
		endcase
	end

	// MD COMS reg writes...
	if (MD_ADDR[23:8]==16'hA151 && !MBUS_RNW && !MD_AS_N) begin
		case (MD_ADDR[7:0])
		8'h20: begin if (!MBUS_UDS_N) COMMS_4020[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_4020[7:0]  <= MBUS_DO[7:0]; end	// 0x4020.
		8'h22: begin if (!MBUS_UDS_N) COMMS_4022[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_4022[7:0]  <= MBUS_DO[7:0]; end	// 0x4022.
		8'h24: begin if (!MBUS_UDS_N) COMMS_4024[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_4024[7:0]  <= MBUS_DO[7:0]; end	// 0x4024.
		8'h26: begin if (!MBUS_UDS_N) COMMS_4026[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_4026[7:0]  <= MBUS_DO[7:0]; end	// 0x4026.
		8'h28: begin if (!MBUS_UDS_N) COMMS_4028[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_4028[7:0]  <= MBUS_DO[7:0]; end	// 0x4028.
		8'h2A: begin if (!MBUS_UDS_N) COMMS_402A[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_402A[7:0]  <= MBUS_DO[7:0]; end	// 0x402A.
		8'h2C: begin if (!MBUS_UDS_N) COMMS_402C[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_402C[7:0]  <= MBUS_DO[7:0]; end	// 0x402C.
		8'h2E: begin if (!MBUS_UDS_N) COMMS_402E[15:8] <= MBUS_DO[15:8]; if (!MBUS_LDS_N) COMMS_402E[7:0]  <= MBUS_DO[7:0]; end	// 0x402E.
		default:;
		endcase
	end

	// PWM Reg writes...
	if (PWM_CS && WRITE_PULSE) begin
		case (SHA[3:1])
		0: begin if (!SHDQMLU_N) PWM_CONT[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) PWM_CONT[7:0]			<= SHD[7:0]; end	// 0x4030.
		1: begin if (!SHDQMLU_N) PWM_CYCLE[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) PWM_CYCLE[7:0]		<= SHD[7:0]; end	// 0x4032.
		2: begin if (!SHDQMLU_N) PWM_LCH_WIDTH[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) PWM_LCH_WIDTH[7:0]  <= SHD[7:0]; end	// 0x4034.
		3: begin if (!SHDQMLU_N) PWM_RCH_WIDTH[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) PWM_RCH_WIDTH[7:0]  <= SHD[7:0]; end	// 0x4036.
		4: begin if (!SHDQMLU_N) PWM_MONO_WIDTH[15:8] <= SHD[15:8]; if (!SHDQMLL_N) PWM_MONO_WIDTH[7:0] <= SHD[7:0]; end	// 0x4038.
		default:;
		endcase
	end
	
	// VDP Reg writes...
	if (VDP_CS && WRITE_PULSE) begin
		case (SHA[3:1])
		0: begin if (!SHDQMLU_N) VDP_MODE[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) VDP_MODE[7:0]			<= SHD[7:0]; end	// 0x4100.
		1: begin if (!SHDQMLU_N) VDP_SHIFT[15:8]		 <= SHD[15:8]; if (!SHDQMLL_N) VDP_SHIFT[7:0]		<= SHD[7:0]; end	// 0x4102.
		2: begin if (!SHDQMLU_N) VDP_FILL_LEN[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) VDP_FILL_LEN[7:0]	<= SHD[7:0]; end	// 0x4104.
		3: begin if (!SHDQMLU_N) VDP_FILL_START[15:8] <= SHD[15:8]; if (!SHDQMLL_N) VDP_FILL_START[7:0] <= SHD[7:0]; end	// 0x4106.
		4: begin if (!SHDQMLU_N) VDP_FILL_DATA[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) VDP_FILL_DATA[7:0]	<= SHD[7:0]; end	// 0x4108.
		5: begin if (!SHDQMLU_N) VDP_FB_CONT[15:8]	 <= SHD[15:8]; if (!SHDQMLL_N) VDP_FB_CONT[7:0]		<= SHD[7:0]; end	// 0x410A.
		default:;
		endcase
	end
	

/*
	if (!KEY[1] && SHBS_N_RISING) begin
		COMMS_4020 <= 16'h0000;
		COMMS_4022 <= 16'h0000;
		COMMS_4024 <= 16'h0000;
		COMMS_4026 <= 16'h0000;
	end
*/
/*
	// Virtua Racing. SEGA Logo. (doesn't work, yet).
	if (!KEY[1] && SHBS_N_RISING) begin
		COMMS_4020 <= 16'h0106;
		COMMS_4022 <= 16'h0000;
		COMMS_4024 <= 16'h0000;
		COMMS_4026 <= 16'h0000;
	end
*/
	// For Shadow Squadron. (Still not working. Needs more commands.)...
	/*
	if (!KEY[1] && SHBS_N_RISING) begin
		COMMS_4020 <= 16'h8000;
		COMMS_4022 <= 16'h0000;
		COMMS_4024 <= 16'hDFFF;
		COMMS_4026 <= 16'hDFFF;
	end
	*/
	
	// BC Racers...
	/*
	if (!KEY[1] && SHBS_N_RISING) begin
		COMMS_402A <= 16'h0202;
	end
	*/
	
	// T-Mek...
	/*
	if (!KEY[1] && SHBS_N_RISING) begin
		COMMS_402A <= 16'hFF00;
	end
	*/
	
	// For DOOM...
	/*
	if (!KEY_1) begin
		if (!KEY[1] && SHBS_N_RISING) begin
			COMMS_4020 <= 16'h0000;
			COMMS_4022 <= 16'hDEAF;
			COMMS_4024 <= 16'hBEEF;
			COMMS_4026 <= 16'h0000;
			KEY_1 <= 1'b0;
		end
	end
	else if (KEY[1] && SHBS_N_RISING) KEY_1 <= 1'b0;
	if (!KEY_2) begin
		if (!KEY[2] && SHBS_N_RISING) begin
			COMMS_402C <= 16'h3638;	// "68" (for DOOM, BC Racers, and possibly Darxide?)
			COMMS_402E <= 16'h5550;	// "UP" (for DOOM, BC Racers, and possibly Darxide?)
			COMMS_4028 <= 16'h534C;	// "SL"
			COMMS_402A <= 16'h4156;	// "AV"
			KEY_2 <= 1'b0;
		end
	end
	else if (KEY[2] && SHBS_N_RISING) KEY_2 <= 1'b0;
	*/
	
	/*
	if (!KEY_3) begin
		if (!KEY[3] && SHBS_N_RISING) begin
			COMMS_4020 <= 16'h0000;
			COMMS_4022 <= 16'h0000;
			COMMS_4024 <= 16'h0000;
			COMMS_4026 <= 16'h0000;
			COMMS_4028 <= 16'h534C;		// "SL"
			COMMS_402A <= 16'h4156;		// "AV"
			COMMS_402C <= 16'h000A;
			COMMS_402E <= 16'h2150;
			KEY_3 <= 1'b0;
		end
	end
	else if (KEY[3] && SHBS_N_RISING) KEY_3 <= 1'b0;
	*/
	
	// BC Racers !!!!... Do NOT change!!!
	if (!KEY_1) begin
		if (!KEY[1] && SHBS_N_RISING) begin
			COMMS_4020 <= 16'h0000;
			COMMS_4022 <= 16'hDEAF;
			COMMS_4024 <= 16'hBEEF;
			COMMS_4026 <= 16'h0000;
			KEY_1 <= 1'b0;
		end
	end
	else if (KEY[1] && SHBS_N_RISING) KEY_1 <= 1'b0;
	
	if (!KEY_2) begin
		if (!KEY[2] && SHBS_N_RISING) begin
			COMMS_402C <= 16'h3638;	// "68" (for DOOM, BC Racers, and possibly Darxide?)
			COMMS_402E <= 16'h5550;	// "UP" (for DOOM, BC Racers, and possibly Darxide?)
			COMMS_4028 <= 16'h534C;	// "SL"
			COMMS_402A <= 16'h4156;	// "AV"
			KEY_2 <= 1'b0;
		end
	end
	else if (KEY[2] && SHBS_N_RISING) KEY_2 <= 1'b0;
	
	if (!KEY_3) begin
		if (!KEY[3] && SHBS_N_RISING) begin
			COMMS_4020 <= 16'h0000;
			COMMS_4022 <= 16'h0000;
			COMMS_4024 <= 16'h0000;
			COMMS_4026 <= 16'h0000;
			COMMS_4028 <= 16'h0000;
			COMMS_402A <= 16'h0002;
			COMMS_402C <= 16'h0000;
			COMMS_402E <= 16'h0000;
			KEY_3 <= 1'b0;
		end
	end
	else if (KEY[3] && SHBS_N_RISING) KEY_3 <= 1'b0;
	
	
	/*
	if (!KEY[3] && SHBS_N_RISING) begin
		COMMS_4020 <= 16'h0000;
		COMMS_4022 <= 16'h0000;
		COMMS_4024 <= 16'h0000;
		COMMS_4026 <= 16'h0000;
		COMMS_4028 <= 16'h0000;
		COMMS_402A <= 16'h0000;
		COMMS_402C <= 16'h0000;
		COMMS_402E <= 16'h0000;
	end
	*/
	
	// Auto DOOOMMMMMM!!!
	
	/*
	case (DOOM_STATE)
	
	0: begin
		COMMS_4020 <= 16'h0000;
		COMMS_4022 <= 16'h0000;
		COMMS_4024 <= 16'h0000;
		COMMS_4026 <= 16'h0000;
		COMMS_4028 <= 16'h534C;
		COMMS_402A <= 16'h4156;
		COMMS_402C <= 16'h3638;
		COMMS_402E <= 16'h5550;
		DOOM_STATE <= DOOM_STATE + 1;
	end
	
	1: begin
		//if (COMMS_4020==16'h4D5F && COMMS_4022==16'h4F4B) begin	// Wait for "M_OK" from Master SH2...
		//	COMMS_402C <= 16'h3638;	// "68"
		//	COMMS_402E <= 16'h5550;	// "UP"
			DOOM_STATE <= DOOM_STATE + 1;
		//end
	end
	
	1: begin
		//COMMS_4020 <= 16'h0000;
		//COMMS_4022 <= 16'h0000;
		//COMMS_4024 <= 16'h0000;
		//COMMS_4026 <= 16'h0000;
		//COMMS_4028 <= 16'h0000;
		//COMMS_402A <= 16'h0000;
		DOOM_STATE <= DOOM_STATE + 1;
	end

	2: begin
		//COMMS_4020 <= 16'h0000;
		//COMMS_4022 <= 16'h0000;
		//COMMS_4024 <= 16'h0000;
		//COMMS_4026 <= 16'h0000;
		//COMMS_4028 <= 16'h0000;
		//COMMS_402A <= 16'h0000;
		COMMS_4020 <= 16'h0000;
		COMMS_4022 <= 16'h0000;
		COMMS_4024 <= 16'h0000;
		COMMS_4026 <= 16'h0000;
		COMMS_4028 <= 16'h0000;
		COMMS_402A <= 16'h0000;
		COMMS_402C <= 16'h0000;
		COMMS_402E <= 16'h0000;
		DOOM_STATE <= DOOM_STATE + 1;
	end
	
	3: begin
		if (COMMS_4022==16'hBEEF) DOOM_STATE <= DOOM_STATE + 1;
		DOOM_STATE <= DOOM_STATE + 1;
	end
	
	4: begin
		COMMS_4020 <= 16'h0000;
		COMMS_4022 <= 16'hDEAF;
		DOOM_STATE <= DOOM_STATE + 1;
	end
	
	5: begin
	
	end
	
	default:;
	endcase
	*/
	
//	if (CRAM_CS && WRITE_PULSE) begin
//		CRAM[ SHA[8:1] ] <= SHD;	// 0x4200. Handle CRAM (palette) reg writes.
//	end

	VDP_FB_CONT[15] <= CLK_DIV[18:0]>=0 && CLK_DIV[18:0]<=99;	// VBLANK Flag. (should be for 38 LINES for NTSC, but TODO.)
	VDP_FB_CONT[14] <= CLK_DIV[10:0]>=0 && CLK_DIV[10:0]<=99;	// HBLANK Flag.
	
	VDP_FB_CONT[13] <= 1'b1;	// PEN (Palette Access Approved when == 1).
	
	VDP_FB_CONT[1] <= 1'b0;		// FEN (Framebuffer Access Approved when == 0).	
end


wire [15:0] COMMS_DO = (MD_ADDR==24'hA15120) ? COMMS_4020 : // A15120 (MD). 0x4020 (32x).
							  (MD_ADDR==24'hA15122) ? COMMS_4022 : // A15122 (MD). 0x4022 (32x).
							  (MD_ADDR==24'hA15124) ? COMMS_4024 : // A15124 (MD). 0x4024 (32x).
							  (MD_ADDR==24'hA15126) ? COMMS_4026 : // A15126 (MD). 0x4026 (32x).
							  (MD_ADDR==24'hA15128) ? COMMS_4028 : // A15128 (MD). 0x4028 (32x).
							  (MD_ADDR==24'hA1512A) ? COMMS_402A : // A1512A (MD). 0x402A (32x).
							  (MD_ADDR==24'hA1512C) ? COMMS_402C : // A1512C (MD). 0x402C (32x).
							  (MD_ADDR==24'hA1512E) ? COMMS_402E : // A1512E (MD). 0x402E (32x).
							  16'hFFFF;


endmodule
