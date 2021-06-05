//============================================================================
//  FPGAGen port to MiSTer
//  Copyright (c) 2017-2019 Sorgelig
//
//  YM2612 implementation by Jose Tejada Gomez. Twitter: @topapate
//  Original Genesis code: Copyright (c) 2010-2013 Gregory Estrade (greg@torlus.com) 
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS,
	
	inout [35:0] GPIO_0,
	inout [35:0] GPIO_1	
);

assign ADC_BUS  = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign BUTTONS   = osd_btn;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

always_comb begin
	if (status[10]) begin
		VIDEO_ARX = 8'd16;
		VIDEO_ARY = 8'd9;
	end else begin
		case(res) // {V30, H40}
			2'b00: begin // 256 x 224
				VIDEO_ARX = 8'd64;
				VIDEO_ARY = 8'd49;
			end

			2'b01: begin // 320 x 224
				VIDEO_ARX = status[30] ? 8'd10: 8'd64;
				VIDEO_ARY = status[30] ? 8'd7 : 8'd49;
			end

			2'b10: begin // 256 x 240
				VIDEO_ARX = 8'd128;
				VIDEO_ARY = 8'd105;
			end

			2'b11: begin // 320 x 240
				VIDEO_ARX = status[30] ? 8'd4 : 8'd128;
				VIDEO_ARY = status[30] ? 8'd3 : 8'd105;
			end
		endcase
	end
end

//assign VIDEO_ARX = status[10] ? 8'd16 : ((status[30] && wide_ar) ? 8'd10 : 8'd64);
//assign VIDEO_ARY = status[10] ? 8'd9  : ((status[30] && wide_ar) ? 8'd7  : 8'd49);

assign AUDIO_S = 1;
assign AUDIO_MIX = 0;

assign LED_DISK  = 0;
assign LED_POWER = 0;
assign LED_USER  = cart_download | sav_pending;


// Status Bit Map:
//             Upper                             Lower              
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// XXXXXXXXXXXX XXXXXXXXXXXXXXXXXXX XX XXXXXXXXXXXXX               

`include "build_id.v"
localparam CONF_STR = {
	"Genesis;;",
	"FS,32xBINGENMD ;",
	"-;",
	"O67,Region,JP,US,EU;",
	"O89,Auto Region,File Ext,Header,Disabled;",
	"D2ORS,Priority,US>EU>JP,EU>US>JP,US>JP>EU,JP>US>EU;",
	"-;",
	"C,Cheats;",
	"H1OO,Cheats Enabled,Yes,No;",
	"-;",
	"D0RG,Load Backup RAM;",
	"D0RH,Save Backup RAM;",
	"D0OD,Autosave,Off,On;",
	"-;",

	"P1,Audio & Video;",
	"P1-;",
	"P1OA,Aspect Ratio,4:3,16:9;",
	"P1OU,320x224 Aspect,Original,Corrected;",
	"P1O13,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1-;",
	"P1OT,Border,No,Yes;",
	"P1oEF,Composite Blend,Off,On,Adaptive;",
	"P1-;",
	"P1OEF,Audio Filter,Model 1,Model 2,Minimal,No Filter;",
	"P1OB,FM Chip,YM2612,YM3438;",
	"P1ON,HiFi PCM,No,Yes;",

	"P2,Input;",
	"P2-;",
	"P2O4,Swap Joysticks,No,Yes;",
	"P2O5,6 Buttons Mode,No,Yes;",
	"P2o57,Multitap,Disabled,4-Way,TeamPlayer: Port1,TeamPlayer: Port2,J-Cart;",
	"P2-;",
	"P2OIJ,Mouse,None,Port1,Port2;",
	"P2OK,Mouse Flip Y,No,Yes;",
	"P2-;",
	"P2oD,Serial,OFF,SNAC;",
	"P2-;",
	"P2o89,Gun Control,Disabled,Joy1,Joy2,Mouse;",
	"D4P2oA,Gun Fire,Joy,Mouse;",
	"D4P2oBC,Cross,Small,Medium,Big,None;",

	"P3,Miscellaneous;",
	"P3-;",
	
	//"P3o34,ROM Storage,Auto,SDRAM,DDR3;",
	"P3-;",
	
	"P3-;",
	"P3OPQ,CPU Turbo,None,Medium,High;",
	"P3OV,Sprite Limit,Normal,High;",
	"P3-;",

	"-;",
	"H3o0,Enable FM,Yes,No;",
	"H3o1,Enable PSG,Yes,No;",
	"H3-;",
	"R0,Reset;",
	"J1,A,B,C,Start,Mode,X,Y,Z;",
	"jn,A,B,R,Start,Select,X,Y,L;", // name map to SNES layout.
	"jp,Y,B,A,Start,Select,L,X,R;", // positional map to SNES layout (3 button friendly) 
	"V,v",`BUILD_DATE
};

wire [63:0] status;
wire  [1:0] buttons;
wire [11:0] joystick_0,joystick_1,joystick_2,joystick_3,joystick_4;
wire  [7:0] joy0_x,joy0_y,joy1_x,joy1_y;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_data;
wire  [7:0] ioctl_index;
reg         ioctl_wait;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [7:0] sd_buff_addr;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire        forced_scandoubler;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire [21:0] gamma_bus;
wire [15:0] sdram_sz;

hps_io #(.STRLEN($size(CONF_STR)>>3), .WIDE(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	.joystick_4(joystick_4),
	.joystick_analog_0({joy0_y, joy0_x}),
	.joystick_analog_1({joy1_y, joy1_x}),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.new_vmode(new_vmode),

	.status(status),
	.status_in({status[63:8],region_req,status[5:0]}),
	.status_set(region_set),
	.status_menumask({!gun_mode,~dbg_menu,~status[8],~gg_available,~bk_ena}),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	.ioctl_wait(ioctl_wait),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.gamma_bus(gamma_bus),
	.sdram_sz(sdram_sz),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse)
);

wire [1:0] gun_mode = status[41:40];
wire       gun_btn_mode = status[42];

wire code_index = &ioctl_index;
wire cart_download = ioctl_download & ~code_index;
wire code_download = ioctl_download & code_index;

reg osd_btn = 0;
always @(posedge clk_sys) begin
	integer timeout = 0;
	reg     has_bootrom = 0;
	reg     last_rst = 0;

	if (RESET) last_rst = 0;
	if (status[0]) last_rst = 1;

	if (cart_download & ioctl_wr & status[0]) has_bootrom <= 1;

	if(last_rst & ~status[0]) begin
		osd_btn <= 0;
		if(timeout < 24000000) begin
			timeout <= timeout + 1;
			osd_btn <= ~has_bootrom;
		end
	end
end
///////////////////////////////////////////////////
wire clk_sys, clk_ram, locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_ram),
	.outclk_2(clk_26m),
	.locked(locked)
);

///////////////////////////////////////////////////
// Code loading for WIDE IO (16 bit)
reg [128:0] gg_code;
wire        gg_available;

// Code layout:
// {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

always_ff @(posedge clk_sys) begin
	gg_code[128] <= 1'b0;

	if (code_download & ioctl_wr) begin
		case (ioctl_addr[3:0])
			0:  gg_code[111:96]  <= ioctl_data; // Flags Bottom Word
			2:  gg_code[127:112] <= ioctl_data; // Flags Top Word
			4:  gg_code[79:64]   <= ioctl_data; // Address Bottom Word
			6:  gg_code[95:80]   <= ioctl_data; // Address Top Word
			8:  gg_code[47:32]   <= ioctl_data; // Compare Bottom Word
			10: gg_code[63:48]   <= ioctl_data; // Compare top Word
			12: gg_code[15:0]    <= ioctl_data; // Replace Bottom Word
			14: begin
				gg_code[31:16]   <= ioctl_data; // Replace Top Word
				gg_code[128]     <=  1'b1;      // Clock it in
			end
		endcase
	end
end

///////////////////////////////////////////////////
wire [3:0] r, g, b;
wire vs,hs;
wire ce_pix;
wire hblank, vblank;

wire interlace;

wire [1:0] resolution;

wire reset = RESET | status[0] | buttons[1] | region_set | bk_loading;

wire [7:0] color_lut[16] = '{
	8'd0,   8'd27,  8'd49,  8'd71,
	8'd87,  8'd103, 8'd119, 8'd130,
	8'd146, 8'd157, 8'd174, 8'd190,
	8'd206, 8'd228, 8'd255, 8'd255
};

system system
(
	.RESET_N(~reset),
	.MCLK(clk_sys),

	.LOADING(cart_download),
	.EXPORT(|status[7:6]),
	.PAL(PAL),
	.SRAM_QUIRK(sram_quirk),
	.EEPROM_QUIRK(eeprom_quirk),
	.NORAM_QUIRK(noram_quirk),
	.PIER_QUIRK(pier_quirk),
	.FMBUSY_QUIRK(fmbusy_quirk),

	.DAC_LDATA(AUDIO_L),
	.DAC_RDATA(AUDIO_R),
	
	.TURBO(status[26:25]),

	.RED(r),
	.GREEN(g),
	.BLUE(b),
	.VS(vs),
	.HS(hs),
	.HBL(hblank),
	.VBL(vblank),
	.BORDER(status[29]),
	.CE_PIX(ce_pix),
	.FIELD(VGA_F1),
	.INTERLACE(interlace),
	.RESOLUTION(resolution),
	.FAST_FIFO(fifo_quirk),
	.SVP_QUIRK(svp_quirk),
	.SCHAN_QUIRK(schan_quirk),
	
	.GG_RESET(code_download && ioctl_wr && !ioctl_addr),
	.GG_EN(status[24]),
	.GG_CODE(gg_code),
	.GG_AVAILABLE(gg_available),

	.J3BUT(~status[5]),
	.JOY_1(status[4] ? joystick_1 : joystick_0),
	.JOY_2(status[4] ? joystick_0 : joystick_1),
	.JOY_3(joystick_2),
	.JOY_4(joystick_3),
	.JOY_5(joystick_4),
	.MULTITAP(status[39:37]),

	.MOUSE(ps2_mouse),
	.MOUSE_OPT(status[20:18]),
	
	.GUN_OPT(|gun_mode),
	.GUN_TYPE(gun_type),
	.GUN_SENSOR(lg_sensor),
	.GUN_A(lg_a),
	.GUN_B(lg_b),
	.GUN_C(lg_c),
	.GUN_START(lg_start),

	.SERJOYSTICK_IN(SERJOYSTICK_IN),
	.SERJOYSTICK_OUT(SERJOYSTICK_OUT),
	.SER_OPT(SER_OPT),

	.ENABLE_FM(~dbg_menu | ~status[32]),
	.ENABLE_PSG(~dbg_menu | ~status[33]),
	.EN_HIFI_PCM(status[23]), // Option "N"
	.LADDER(~status[11]),
	.LPF_MODE(status[15:14]),

	.OBJ_LIMIT_HIGH(status[31]),

	.BRAM_A({sd_lba[6:0],sd_buff_addr}),
	.BRAM_DI(sd_buff_dout),
	.BRAM_DO(sd_buff_din),
	.BRAM_WE(sd_buff_wr & sd_ack),
	.BRAM_CHANGE(bk_change),

	.ROMSZ(rom_sz[24:1]),
	.ROM_ADDR(rom_addr),
	//.ROM_DATA(/*use_sdr ? sdrom_data : */ddrom_data),
	.ROM_DATA( MBUS_DI ),
	.ROM_WDATA(rom_wdata),
	.ROM_WE(rom_we),
	.ROM_BE(rom_be),
	.ROM_REQ(rom_req),
	.ROM_ACK(/*use_sdr ? sdrom_rdack : */ddrom_rdack),
	
	//.ROM_REQ(rom_req_gen),
	//.ROM_ACK(rom_ack_gen),

	//.ROM_ADDR2(rom_addr2),
	//.ROM_DATA2(rom_data2),
	//.ROM_REQ2(rom_rd2),
	//.ROM_ACK2(rom_rdack2),

	.TRANSP_DETECT(TRANSP_DETECT),
	
	.MBUS_A_OUT(MBUS_A),
	.MBUS_DO_OUT(MBUS_DO),
	
	.MBUS_RNW_OUT(MBUS_RNW),
	
	.MBUS_UDS_N_OUT(MBUS_UDS_N),
	.MBUS_LDS_N_OUT(MBUS_LDS_N),
	
	.M68K_AS_N_OUT(MD_AS_N),
	
	.MARS_DTACK_N(MARS_DTACK_N),
	
	.MARS_SEL_OUT(MARS_SEL)
);



// 32X VDP logic.
//
// ElectronAsh. 18-6-20.
//
//
wire MRESET_N = !reset;

wire [3:0] KEY_32X = ~joystick_0[3:0];
wire [9:0] SW_32X = 10'b0111101100;

vdp_core vdp_core_inst
(
	.RESET_N( MRESET_N ) ,	// input  RESET_N
	
	.CLOCK( clk_26m ) ,		// input  CLOCK
	
	.KEY( KEY_32X ) ,			// input [3:0] KEY
	.SW( SW_32X ) ,			// input [9:0] SW
	
	.SHA( GPIO_1[35:15] ) ,	// input [21:1] SHA
	
	.SHD( {GPIO_0[20], GPIO_0[21], GPIO_0[22], GPIO_0[23], GPIO_0[24], GPIO_0[25], GPIO_0[26], GPIO_0[27],
						 GPIO_0[28], GPIO_0[29], GPIO_0[30], GPIO_0[31], GPIO_0[32], GPIO_0[33], GPIO_0[34], GPIO_0[35]}) ,	// inout [15:0] SHD
	
	.SHSIRL1_N( GPIO_1[0] ) ,	// output  SHSIRL1_N
	.SHSIRL2_N( GPIO_1[1] ) ,	// output  SHSIRL2_N
	.SHSIRL3_N( GPIO_1[2] ) ,	// output  SHSIRL3_N
	
	.SHBS_N( GPIO_1[3] ) ,		// input  SHBS_N

	.SHRESM_N( GPIO_1[4] ) ,	// output  SHRESM_N
	.SHRESS_N( GPIO_0[2] ) ,	// output  SHRESS_N
	
	//.SHWAIT_N( GPIO_1[11] ) ,	// output  SHWAIT_N
	
	.SHCS1_N( GPIO_1[5] ) ,		// input  SHCS1_N
	.SHCS2_N( GPIO_1[6] ) ,		// input  SHCS2_N
	.SHCS3_N( GPIO_1[7] ) ,		// input  SHCS3_N
	.SHCS0S_N( GPIO_1[8] ) ,	// input  SHCS0S_N
	.SHCS0M_N( GPIO_1[9] ) ,	// input  SHCS0M_N
	
	.SHBREQS_N( GPIO_1[10] ) ,	// input  SHBREQS_N
	
	.SHRD_N( GPIO_1[12] ) ,	// input  SHRD_N
	
	.SHDQMLL_N( GPIO_1[13] ) ,	// input  SHDQMLL_N
	.SHDQMLU_N( GPIO_1[14] ) ,	// input  SHDQMLU_N
	
	.SHCLK( GPIO_0[0] ) ,	// output  SHCLK
	.SHCKE( GPIO_0[1] ) ,	// input  SHCKE
	
	.SHDREQ0_N( GPIO_0[3] ) ,	// output  SHDREQ0_N
	.SHDREQ1_N( GPIO_0[4] ) ,	// output  SHDREQ1_N
	
	.NMI_S( GPIO_0[6] ) ,	// input  NMI_S
	
	.SCK( GPIO_0[7] ) ,	// input  SCK
	.TXDS( GPIO_0[8] ) ,	// input  TXDS
	.TXDM( GPIO_0[9] ) ,	// input  TXDM
	
	.BACKS_N( GPIO_0[10] ) ,	// input  BACKS_N
	
	.SHMIRL1_N( GPIO_0[11] ) ,	// input  SHMIRL1_N
	.SHMIRL2_N( GPIO_0[12] ) ,	// input  SHMIRL2_N
	.SHMIRL3_N( GPIO_0[13] ) ,	// input  SHMIRL3_N
	
	.NMI_M( GPIO_0[14] ) ,	// input  NMI_M
	
	.FT0B_M( GPIO_0[15] ) ,	// input  FT0B_M
	
	.BACKM_N( GPIO_0[16] ) ,	// input  BACKM_N
	
	.SHCAS_N( GPIO_0[17] ) ,	// input  SHCAS_N
	.SHRAS_N( GPIO_0[18] ) ,	// input  SHRAS_N
	
	.SHRDWR( GPIO_0[19] ) ,	// input  SHRDWR
	
	.BIOS_CS( BIOS_CS ),		//  output BIOS_CS
	.REGS_CS( REGS_CS ),		//  output REGS_CS
	.COMS_CS( COMS_CS ),		//  output COMS_CS
	.PWM_CS( PWM_CS ),		//  output PWM_CS
	.VDP_CS( VDP_CS ),		//  output VDP_CS
	.CRAM_CS( CRAM_CS ),		//  output CRAM_CS
	.CART_CS( CART_CS ),		//  output CART_CS
	.FB_CS( FB_CS ),			//  output FB_CS
	.FB_OVR_CS( FB_OVR_CS ),//  output FB_OVR_CS
	.SDRAM_CS( SDRAM_CS ),	//  output SDRAM_CS
	
	.HSYNC( hs ),
	.VSYNC( vs ),
	
//	.LEDG( LEDG ),
	
	.AUD_L( AUD_L_32X ),
	.AUD_R( AUD_R_32X ),
	
	.FB_SWAP( FB_SWAP ),
	
	.FB_MODE( FB_MODE ),
	
	.VDP_LSHIFT( VDP_LSHIFT ),
	
	.READ_PULSE_OUT( READ_PULSE ),

	.WRITE_PULSE_OUT( WRITE_PULSE ),
	

	// VA19 (A2) and VA18 (B25) are NOT connected on the Mega-CD / Sega-CD, nor the expansion adapter!
	// Only VD17:VD1 are connected, so the Mega-CD / Sega-CD relies on the FDC_N and other signals for decoding the addresses.
	//
	// But - all address bits are available on the cart slot, and all needed for doing the address decoding for the 32x.
	
	//.MD_ADDR( {MBUS_A, 1'b0} ),					// From MD core to 32x core.
	.MD_ADDR( {rom_addr, 1'b0} ),					// From MD core to 32x core.

	.MBUS_DO( MBUS_DO ),					// From MD core to 32x core.
	.MBUS_DI( MBUS_DI ),					// From 32x core to MD core.
		
	.MD_AS_N( MD_AS_N ),					//  input
	.MBUS_RNW( MBUS_RNW ),				//  input
	.MBUS_UDS_N( MBUS_UDS_N ),			//  input
	.MBUS_LDS_N( MBUS_LDS_N ),			//  input
	
	.MARS_DTACK_N( MARS_DTACK_N ),   //  output
	.MARS_SEL( MARS_SEL ),				//  input
	
	//.CART_DI( ddrom_data )	
	.CART_DI( rom_data2 ),
);

wire [23:1] MBUS_A;
wire [15:0] MBUS_DO;
wire [15:0] MBUS_DI;


//(*keep*) wire [15:0] MD_DATA = {GPIO_3[7:0], GPIO_2[35:28]};


wire [15:0] AUD_L_32X;
wire [15:0] AUD_R_32X;

wire READ_PULSE;
wire WRITE_PULSE;

wire VDP_LSHIFT;

wire FB_SWAP;
wire [1:0] FB_MODE;

(*keep*) wire [21:0] SH_ADDR = {GPIO_1[35:15], 1'b0};

(*keep*) wire [15:0] MY_SHD = {GPIO_0[20], GPIO_0[21], GPIO_0[22], GPIO_0[23], GPIO_0[24], GPIO_0[25], GPIO_0[26], GPIO_0[27],
										 GPIO_0[28], GPIO_0[29], GPIO_0[30], GPIO_0[31], GPIO_0[32], GPIO_0[33], GPIO_0[34], GPIO_0[35]};

wire SHDQMLU_N = GPIO_1[14];
wire SHDQMLL_N = GPIO_1[13];

wire SHBS_N = GPIO_1[3];

										 
reg SHBS_N_1;
wire SHBS_N_RISING = (!SHBS_N_1 & SHBS_N);

reg SHWAIT_N_REG;

//wire rom_req_gen;
//reg rom_ack_gen;

//reg rom_req;
//assign GPIO_1[11] = !cart_read_pend_sh2;	// SHWAIT_N pin.
//wire [15:0] CART_DI = ddrom_data;

assign GPIO_1[11] = !rom_rd2;	// SHWAIT_N pin.
assign rom_addr2 = {3'b000, GPIO_1[35:15]};	// WORD address!


reg cart_read_pend_sh2;
reg cart_read_pend_gen;

reg [3:0] cart_state;
always @(posedge clk_26m or posedge RESET)
if (RESET) begin
	cart_state <= 4'd0;
	//rom_req <= 1'b0;
	//rom_ack_gen <= 1'b0;
	
	cart_read_pend_sh2 <= 1'b0;
	cart_read_pend_gen <= 1'b0;
end
else begin
	SHBS_N_1 <= SHBS_N;
	
	if (CART_CS && READ_PULSE) rom_rd2 <= 1'b1;
	if (rom_rdack2) rom_rd2 <= 1'b0;

	/*	
	if (CART_CS && READ_PULSE) cart_read_pend_sh2 <= 1'b1;
	if (rom_rdack2) cart_read_pend_sh2 <= 1'b0;

	if (rom_req_gen) cart_read_pend_gen <= 1'b1;

	rom_ack_gen <= 1'b0;

	case (cart_state)
		0: begin
			if (cart_read_pend_sh2) begin
				rom_addr <= {3'b000, GPIO_1[35:15]};	// From the SH2s. WORD address.
				rom_req <= 1'b1;
				cart_state <= cart_state + 1;
			end			
			else if (cart_read_pend_gen) begin			// <- Else if. To give the SH2s priority over cart reads.
				rom_addr <= rom_addr_gen;					// From the Genesis core.
				rom_req <= 1'b1;
				cart_state <= cart_state + 1;
			end
		end
		
		1: begin
			if (ddrom_rdack) begin
				if (cart_read_pend_sh2) begin
					cart_read_pend_sh2 <= 1'b0;
					rom_req <= 1'b0;
					cart_state <= 4'd0;
				end
				else begin
					cart_read_pend_gen <= 1'b0;
					rom_ack_gen <= 1'b1;
					rom_req <= 1'b0;
					cart_state <= 4'd0;
				end
			end
		end
		
		default:;
	endcase
	*/
	
	if (CRAM_CS && WRITE_PULSE) begin	// Needs to be in the SH2 clock domain.
		CRAM[ SH_ADDR[8:1] ] <= MY_SHD;	// 0x4200. Handle CRAM (palette) reg writes.
	end	
end



wire TRANSP_DETECT;
wire cofi_enable = status[46] || (status[47] && TRANSP_DETECT);

wire PAL = status[7];

reg new_vmode;
always @(posedge clk_sys) begin
	reg old_pal;
	int to;
	
	if(~(reset | cart_download)) begin
		old_pal <= PAL;
		if(old_pal != PAL) to <= 5000000;
	end
	else to <= 5000000;
	
	if(to) begin
		to <= to - 1;
		if(to == 1) new_vmode <= ~new_vmode;
	end
end

reg dbg_menu = 0;
always @(posedge clk_sys) begin
	reg old_stb;
	reg enter = 0;
	reg esc = 0;
	
	old_stb <= ps2_key[10];
	if(old_stb ^ ps2_key[10]) begin
		if(ps2_key[7:0] == 'h5A) enter <= ps2_key[9];
		if(ps2_key[7:0] == 'h76) esc   <= ps2_key[9];
	end
	
	if(enter & esc) begin
		dbg_menu <= ~dbg_menu;
		enter <= 0;
		esc <= 0;
	end
end

//lock resolution for the whole frame.
reg [1:0] res;
always @(posedge clk_sys) begin
	reg old_vbl;
	
	old_vbl <= vblank;
	if(old_vbl & ~vblank) res <= resolution;
end

wire [2:0] scale = status[3:1];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

assign CLK_VIDEO = clk_ram;
assign VGA_SL = {~interlace,~interlace}&sl[1:0];

reg old_ce_pix;
always @(posedge CLK_VIDEO) old_ce_pix <= ce_pix;

wire [7:0] red, green, blue;

/*
cofi coffee (
	.clk(clk_sys),
	.pix_ce(ce_pix),
	.enable(cofi_enable),

	.hblank(hblank),
	.vblank(vblank),
	.hs(hs),
	.vs(vs),
	
	//.red(color_lut[r]),
	//.green(color_lut[g]),
	//.blue(color_lut[b]),
	
	.red( {VGA_R_REG,4'b0000} ),
	.green( {VGA_G_REG,4'b0000} ),
	.blue( {VGA_B_REG,4'b0000} ),

	.hblank_out(hblank_c),
	.vblank_out(vblank_c),
	.hs_out(hs_c),
	.vs_out(vs_c),
	.red_out(red),
	.green_out(green),
	.blue_out(blue)
);
wire hs_c,vs_c,hblank_c,vblank_c;
*/

video_mixer #(.LINE_LENGTH(320), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.*,

	.clk_vid(CLK_VIDEO),
	.ce_pix(~old_ce_pix & ce_pix),
	.ce_pix_out(CE_PIXEL),

	.scanlines(0),
	.scandoubler(~interlace && (scale || forced_scandoubler)),
	.hq2x(scale==1),

	.mono(0),

	//.R((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[0]}} : red),
	//.G((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[1]}} : green),
	//.B((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[2]}} : blue),

	.R( {VGA_R_REG,3'b000} ),	// 5 bits per colour from the 32x.
	.G( {VGA_G_REG,3'b000} ),
	.B( {VGA_B_REG,3'b000} ),
	
	// Positive pulses.
	//.HSync(hs_c),
	//.VSync(vs_c),
	//.HBlank(hblank_c),
	//.VBlank(vblank_c)
	
	.HSync(hs),
	.VSync(vs),
	.HBlank(hblank),
	.VBlank(vblank)
);

wire [2:0] lg_target;
wire       lg_sensor;
wire       lg_a;
wire       lg_b;
wire       lg_c;
wire       lg_start;

lightgun lightgun
(
	.CLK(clk_sys),
	.RESET(reset),

	.MOUSE(ps2_mouse),
	.MOUSE_XY(&gun_mode),

	.JOY_X(gun_mode[0] ? joy0_x : joy1_x),
	.JOY_Y(gun_mode[0] ? joy0_y : joy1_y),
	.JOY(gun_mode[0] ? joystick_0 : joystick_1),

	.RELOAD(gun_type),

	.HDE(~hblank_c),
	.VDE(~vblank_c),
	.CE_PIX(ce_pix),
	.H40(res[0]),

	.BTN_MODE(gun_btn_mode),
	.SIZE(status[44:43]),
	.SENSOR_DELAY(gun_sensor_delay),

	.TARGET(lg_target),
	.SENSOR(lg_sensor),
	.BTN_A(lg_a),
	.BTN_B(lg_b),
	.BTN_C(lg_c),
	.BTN_START(lg_start)
);

///////////////////////////////////////////////////
sdram sdram
(
	.*,
	.init(~locked),
	.clk(clk_ram),

	.addr0(ioctl_addr[24:1]),
	.din0({ioctl_data[7:0],ioctl_data[15:8]}),
	.dout0(),
	.wrl0(1),
	.wrh0(1),
	.req0(rom_wr),
	.ack0(sdrom_wrack),

	.addr1(rom_addr),
	.din1(rom_wdata),
	.dout1(sdrom_data),
	.wrl1(rom_we & rom_be[0]),
	.wrh1(rom_we & rom_be[1]),
	.req1(rom_req),
	.ack1(sdrom_rdack),

	.addr2(0),
	.din2(0),
	.dout2(),
	.wrl2(0),
	.wrh2(0),
	.req2(0),
	.ack2()
);

wire [24:1] rom_addr;
wire [24:1] rom_addr2;
wire [24:1] rom_addr_gen;
wire [15:0] sdrom_data, ddrom_data, rom_data2, rom_wdata;
wire  [1:0] rom_be;
wire rom_req;
wire sdrom_rdack, ddrom_rdack, rom_rd2, rom_rdack2, rom_we;

assign DDRAM_CLK = clk_ram;
ddram ddram
(
	.*,
	.wraddr(ioctl_addr[24:1]),
	.din({ioctl_data[7:0],ioctl_data[15:8]}),
	.we_req(rom_wr),
	.we_ack(ddrom_wrack),

	.rdaddr(rom_addr),
	.dout(ddrom_data),
	.rom_din(rom_wdata),
	.rom_be(rom_be),
	.rom_we(rom_we),
	
	//.rom_be(2'b11),
	//.rom_we(1'b0),
	
	.rom_req(rom_req),
	.rom_ack(ddrom_rdack),

	.rdaddr2(rom_addr2),
	.dout2(rom_data2),
	.rd_req2(rom_rd2),
	.rd_ack2(rom_rdack2) 
);

//reg use_sdr;
//always @(posedge clk_sys) use_sdr <= (!status[36:35]) ? |sdram_sz[2:0] : status[35];
wire use_sdr = 1'b0;


reg  rom_wr = 0;
wire sdrom_wrack, ddrom_wrack;
reg [24:0] rom_sz;
always @(posedge clk_sys) begin
	reg old_download, old_reset;
	old_download <= cart_download;
	old_reset <= reset;

	if(~old_reset && reset) ioctl_wait <= 0;
	if (old_download & ~cart_download) rom_sz <= ioctl_addr[24:0];

	if (cart_download & ioctl_wr) begin
		ioctl_wait <= 1;
		rom_wr <= ~rom_wr;
	end else if(ioctl_wait && (rom_wr == sdrom_wrack) && (rom_wr == ddrom_wrack)) begin
		ioctl_wait <= 0;
	end
end

reg  [1:0] region_req;
reg        region_set = 0;

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state, old_ready = 0;
	old_state <= ps2_key[10];

	if(old_state != ps2_key[10]) begin
		casex(code)
			'h005: begin region_req <= 0; region_set <= pressed; end // F1
			'h006: begin region_req <= 1; region_set <= pressed; end // F2
			'h004: begin region_req <= 2; region_set <= pressed; end // F3
		endcase
	end

	old_ready <= cart_hdr_ready;
	if(~status[9] & ~old_ready & cart_hdr_ready) begin
		if(status[8]) begin
			region_set <= 1;
			case(status[28:27])
				0: if(hdr_u) region_req <= 1;
					else if(hdr_e) region_req <= 2;
					else if(hdr_j) region_req <= 0;
					else region_req <= 1;
				
				1: if(hdr_e) region_req <= 2;
					else if(hdr_u) region_req <= 1;
					else if(hdr_j) region_req <= 0;
					else region_req <= 2;
				
				2: if(hdr_u) region_req <= 1;
					else if(hdr_j) region_req <= 0;
					else if(hdr_e) region_req <= 2;
					else region_req <= 1;

				3: if(hdr_j) region_req <= 0;
					else if(hdr_u) region_req <= 1;
					else if(hdr_e) region_req <= 2;
					else region_req <= 0;
			endcase
		end
		else begin
			region_set <= |ioctl_index;
			region_req <= ioctl_index[7:6];
		end
	end

	if(old_ready & ~cart_hdr_ready) region_set <= 0;
end

reg cart_hdr_ready = 0;
reg hdr_j=0,hdr_u=0,hdr_e=0;
always @(posedge clk_sys) begin
	reg old_download;
	old_download <= cart_download;

	if(~old_download && cart_download) {hdr_j,hdr_u,hdr_e} <= 0;
	if(old_download && ~cart_download) cart_hdr_ready <= 0;

	if(ioctl_wr & cart_download) begin
		if(ioctl_addr == 'h1F0 || ioctl_addr == 'h1F2) begin
			if(ioctl_data[7:0] == "J") hdr_j <= 1;
			else if(ioctl_data[7:0] == "U") hdr_u <= 1;
			else if(ioctl_data[7:0] >= "0" && ioctl_data[7:0] <= "Z") hdr_e <= 1;
		end
		if(ioctl_addr == 'h1F0) begin
			if(ioctl_data[15:8] == "J") hdr_j <= 1;
			else if(ioctl_data[15:8] == "U") hdr_u <= 1;
			else if(ioctl_data[15:8] >= "0" && ioctl_data[7:0] <= "Z") hdr_e <= 1;
		end
		if(ioctl_addr == 'h200) cart_hdr_ready <= 1;
	end
end

reg sram_quirk = 0;
reg eeprom_quirk = 0;
reg fifo_quirk = 0;
reg noram_quirk = 0;
reg pier_quirk = 0;
reg svp_quirk = 0;
reg fmbusy_quirk = 0;
reg schan_quirk = 0;
reg gun_type = 0;
reg [7:0] gun_sensor_delay = 8'd44;
always @(posedge clk_sys) begin
	reg [63:0] cart_id;
	reg old_download;
	old_download <= cart_download;

	if(~old_download && cart_download) {fifo_quirk,eeprom_quirk,sram_quirk,noram_quirk,pier_quirk,svp_quirk,fmbusy_quirk,schan_quirk} <= 0;

	if(ioctl_wr & cart_download) begin
		if(ioctl_addr == 'h182) cart_id[63:56] <= ioctl_data[15:8];
		if(ioctl_addr == 'h184) cart_id[55:40] <= {ioctl_data[7:0],ioctl_data[15:8]};
		if(ioctl_addr == 'h186) cart_id[39:24] <= {ioctl_data[7:0],ioctl_data[15:8]};
		if(ioctl_addr == 'h188) cart_id[23:08] <= {ioctl_data[7:0],ioctl_data[15:8]};
		if(ioctl_addr == 'h18A) cart_id[07:00] <= ioctl_data[7:0];
		if(ioctl_addr == 'h18C) begin
			     if(cart_id == "T-081276") sram_quirk   <= 1; // NFL Quarterback Club
			else if(cart_id == "T-81406 ") sram_quirk   <= 1; // NBA Jam TE
			else if(cart_id == "T-081586") sram_quirk   <= 1; // NFL Quarterback Club '96
			else if(cart_id == "T-81576 ") sram_quirk   <= 1; // College Slam
			else if(cart_id == "T-81476 ") sram_quirk   <= 1; // Frank Thomas Big Hurt Baseball
			else if(cart_id == "MK-1215 ") eeprom_quirk <= 1; // Evander Real Deal Holyfield's Boxing
			else if(cart_id == "G-4060  ") eeprom_quirk <= 1; // Wonder Boy
			else if(cart_id == "00001211") eeprom_quirk <= 1; // Sports Talk Baseball
			else if(cart_id == "MK-1228 ") eeprom_quirk <= 1; // Greatest Heavyweights
			else if(cart_id == "G-5538  ") eeprom_quirk <= 1; // Greatest Heavyweights JP
			else if(cart_id == "00004076") eeprom_quirk <= 1; // Honoo no Toukyuuji Dodge Danpei
			else if(cart_id == "T-12046 ") eeprom_quirk <= 1; // Mega Man - The Wily Wars 
			else if(cart_id == "T-12053 ") eeprom_quirk <= 1; // Rockman Mega World 
			else if(cart_id == "G-4524  ") eeprom_quirk <= 1; // Ninja Burai Densetsu
			else if(cart_id == "T-113016") noram_quirk  <= 1; // Puggsy fake ram check
			else if(cart_id == "T-89016 ") fifo_quirk   <= 1; // Clue
			else if(cart_id == "T-574023") pier_quirk   <= 1; // Pier Solar Reprint
			else if(cart_id == "T-574013") pier_quirk   <= 1; // Pier Solar 1st Edition
			else if(cart_id == "MK-1229 ") svp_quirk    <= 1; // Virtua Racing EU/US
			else if(cart_id == "G-7001  ") svp_quirk    <= 1; // Virtua Racing JP
			else if(cart_id == "T-35036 ") fmbusy_quirk <= 1; // Hellfire US
			else if(cart_id == "T-25073 ") fmbusy_quirk <= 1; // Hellfire JP
			else if(cart_id == "MK-1137-") fmbusy_quirk <= 1; // Hellfire EU
			else if(cart_id == "T-68???-") schan_quirk  <= 1; // Game no Kanzume Otokuyou
			
			// Lightgun device and timing offsets
			if(cart_id == "MK-1533 ") begin						  // Body Count
				gun_type  <= 0;
				gun_sensor_delay <= 8'd100;
			end
			else if(cart_id == "T-95096-") begin				  // Lethal Enforcers
				gun_type  <= 1;
				gun_sensor_delay <= 8'd52;
			end
			else if(cart_id == "T-95136-") begin				  // Lethal Enforcers II
				gun_type  <= 1;
				gun_sensor_delay <= 8'd30;
			end
			else if(cart_id == "MK-1658 ") begin				  // Menacer 6-in-1
				gun_type  <= 0;
				gun_sensor_delay <= 8'd120;
			end
			else if(cart_id == "T-081156") begin				  // T2: The Arcade Game
				gun_type  <= 0;
				gun_sensor_delay <= 8'd126;
			end
			else begin
				gun_type  <= 0;
				gun_sensor_delay <= 8'd44;
			end
		end
	end
end

/////////////////////////  BRAM SAVE/LOAD  /////////////////////////////


wire downloading = cart_download;

reg bk_ena = 0;
reg sav_pending = 0;
wire bk_change;

always @(posedge clk_sys) begin
	reg old_downloading = 0;
	reg old_change = 0;

	old_downloading <= downloading;
	if(~old_downloading & downloading) bk_ena <= 0;

	//Save file always mounted in the end of downloading state.
	if(downloading && img_mounted && !img_readonly && ~svp_quirk) bk_ena <= 1;

	old_change <= bk_change;
	if (~old_change & bk_change & ~OSD_STATUS) sav_pending <= status[13];
	else if (bk_state) sav_pending <= 0;
end

wire bk_load    = status[16];
wire bk_save    = status[17] | (sav_pending & OSD_STATUS);
reg  bk_loading = 0;
reg  bk_state   = 0;

always @(posedge clk_sys) begin
	reg old_downloading = 0;
	reg old_load = 0, old_save = 0, old_ack;

	old_downloading <= downloading;

	old_load <= bk_load;
	old_save <= bk_save;
	old_ack  <= sd_ack;

	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

	if(!bk_state) begin
		if(bk_ena & ((~old_load & bk_load) | (~old_save & bk_save))) begin
			bk_state <= 1;
			bk_loading <= bk_load;
			sd_lba <= 0;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
		if(old_downloading & ~downloading & |img_size & bk_ena) begin
			bk_state <= 1;
			bk_loading <= 1;
			sd_lba <= 0;
			sd_rd <= 1;
			sd_wr <= 0;
		end
	end else begin
		if(old_ack & ~sd_ack) begin
			if(&sd_lba[6:0]) begin
				bk_loading <= 0;
				bk_state <= 0;
			end else begin
				sd_lba <= sd_lba + 1'd1;
				sd_rd  <=  bk_loading;
				sd_wr  <= ~bk_loading;
			end
		end
	end
end

wire [7:0] SERJOYSTICK_IN;
wire [7:0] SERJOYSTICK_OUT;
wire [1:0] SER_OPT;

always @(posedge clk_sys) begin
	if (status[45]) begin
		SERJOYSTICK_IN[0] <= USER_IN[1];//up
		SERJOYSTICK_IN[1] <= USER_IN[0];//down	
		SERJOYSTICK_IN[2] <= USER_IN[5];//left	
		SERJOYSTICK_IN[3] <= USER_IN[3];//right
		SERJOYSTICK_IN[4] <= USER_IN[2];//b TL		
		SERJOYSTICK_IN[5] <= USER_IN[6];//c TR GPIO7			
		SERJOYSTICK_IN[6] <= USER_IN[4];//  TH
		SERJOYSTICK_IN[7] <= 0;
		SER_OPT[0] <= status[4];
		SER_OPT[1] <= ~status[4];
		USER_OUT[1] <= SERJOYSTICK_OUT[0];
		USER_OUT[0] <= SERJOYSTICK_OUT[1];
		USER_OUT[5] <= SERJOYSTICK_OUT[2];
		USER_OUT[3] <= SERJOYSTICK_OUT[3];
		USER_OUT[2] <= SERJOYSTICK_OUT[4];
		USER_OUT[6] <= SERJOYSTICK_OUT[5];
		USER_OUT[4] <= SERJOYSTICK_OUT[6];
	end else begin
		SER_OPT  <= 0;
		USER_OUT <= '1;
	end
end


reg [15:0] CRAM [0:255];


parameter WINDOW_X = 40;
parameter WINDOW_Y = 30;

wire [10:0] WINDOW_WIDTH = 320;
parameter WINDOW_HEIGHT = 224;

reg [9:0] X_OUT;
reg [9:0] Y_OUT;

reg PS1_WINDOW;
reg PS1_WINDOW_1;
reg [8:0] PS1_PIX;
reg [8:0] PS1_LINE;

reg [15:0] LINE_START_ADDR;	// WORD addressed!

reg [8:0] RLE_PIX;
reg [7:0] LENGTH;

reg hs_1;

reg [15:0] SRAM_PIXEL_DATA;
always @(posedge ce_pix or posedge reset)
if (reset) begin


end
else begin
	PS1_WINDOW_1 <= PS1_WINDOW;
	
	hs_1 <= hs;
	
	if (vs) begin
		PS1_LINE <= 0;
		PS1_PIX <= 0;
		Y_OUT <= 0;
	end
	else begin
		if (!hs_1 & hs) begin
			Y_OUT <= Y_OUT + 1;
			X_OUT <= 10'd0;
		end
		else X_OUT <= X_OUT + 1;
	
		if (PS1_WINDOW_1 & !PS1_WINDOW) begin
			PS1_PIX <= 0;
			RLE_PIX <= 0;
			PS1_LINE <= PS1_LINE + 1;
			LENGTH <= 0;
		end
		else if (PS1_WINDOW) begin
			PS1_PIX <= PS1_PIX + 1;
		end
		else begin		// PS1_WINDOW is LOW. Grab the line start address (until PS1_WINDOW goes High again).
			//LINE_START_ADDR <= SRAM_DQ;
			LINE_START_ADDR <= fb_dout;
		end
	end
	
	PS1_WINDOW <= (X_OUT>=WINDOW_X && X_OUT<=WINDOW_X+WINDOW_WIDTH-1 && Y_OUT>=WINDOW_Y && Y_OUT<=WINDOW_Y+WINDOW_HEIGHT-1);
	
	case (FB_MODE)
	0: begin		// BLANK.					// Supposed to disable the display, but we're spying here atm.
		//SRAM_PIXEL_DATA <= SRAM_DQ;
		SRAM_PIXEL_DATA <= fb_dout;
	end
	
	1: begin		// PACKED pixel mode.
		//if (!PS1_PIX[0]) SRAM_PIXEL_DATA <= CRAM[ SRAM_DQ[15:8] ];	// Priority pixel gets written to SRAM_PIXEL_DATA[15] too, but we'll probably need that later.
		//else SRAM_PIXEL_DATA <= CRAM[ SRAM_DQ[7:0] ];
		
		if (!PS1_PIX[0]) SRAM_PIXEL_DATA <= CRAM[ fb_dout[15:8] ];	// Priority pixel gets written to SRAM_PIXEL_DATA[15] too, but we'll probably need that later.
		else SRAM_PIXEL_DATA <= CRAM[ fb_dout[7:0] ];
	end
	
	2: begin		// DIRECT pixel mode.
		//SRAM_PIXEL_DATA <= SRAM_DQ;
		SRAM_PIXEL_DATA <= fb_dout;
	end
	
	3: begin		// RLE pixel mode.
		if (PS1_WINDOW) begin
			if (LENGTH==0) begin									// Length==0 from VRAM also means "skip to the next address", so basically 1 pixel.
				//LENGTH <= SRAM_DQ[15:8];						// Grab the Length value from VRAM. If 0, then we skip to the next VRAM address. If > 0 then we display the new colour, and decrement.
				//SRAM_PIXEL_DATA <= CRAM[ SRAM_DQ[7:0] ];	// Grab the colour index from VRAM, and use it to look up the colour value from CRAM.
				
				LENGTH <= fb_dout[15:8];						// Grab the Length value from VRAM. If 0, then we skip to the next VRAM address. If > 0 then we display the new colour, and decrement.
				SRAM_PIXEL_DATA <= CRAM[ fb_dout[7:0] ];	// Grab the colour index from VRAM, and use it to look up the colour value from CRAM.

				RLE_PIX <= RLE_PIX + 1;							// Go to next VRAM WORD (on the NEXT clock).
			end
			else LENGTH <= LENGTH - 1;	// Length is greater than 0, so we just decrement while displaying the new pixel colour.
		end
	end
	
	default:;
	endcase
	
	//VGA_R_REG <= (PS1_WINDOW) ? SRAM_PIXEL_DATA[4:0]   : 5'b00000;
	//VGA_G_REG <= (PS1_WINDOW) ? SRAM_PIXEL_DATA[9:5]   : 5'b00000;
	//VGA_B_REG <= (PS1_WINDOW) ? SRAM_PIXEL_DATA[14:10] : 5'b00000;
	
	VGA_R_REG <= SRAM_PIXEL_DATA[4:0];
	VGA_G_REG <= SRAM_PIXEL_DATA[9:5];
	VGA_B_REG <= SRAM_PIXEL_DATA[14:10];
end


reg [4:0] VGA_R_REG;
reg [4:0] VGA_G_REG;
reg [4:0] VGA_B_REG;


//assign VGA_R = VGA_R_REG;
//assign VGA_G = VGA_G_REG;
//assign VGA_B = VGA_B_REG;

//assign VGA_HS = PATT_HS_N;
//assign VGA_VS = PATT_VS_N;

// Info from Chilly Willy, on Discord...
//
// 0 can never be written as a byte, be it the normal frame buffer or the overwrite.
// In the normal frame buffer, BYTE writes of 0 are ignored, while WORD writes of 0 work.
// In the overwrite buffer, BYTE or WORD writes of 0 are ignored.
//
// And...
//
// FB: WORD write -> either or both bytes can be 0.
// So for fb, if both (DQMs) are asserted, disable (byte==0) check.
//

wire OVR_WRITE_U = FB_OVR_CS && WRITE_PULSE && MY_SHD[15:8]!=8'h00 && !SHDQMLU_N;	// SHDQMLU_N.
wire OVR_WRITE_L = FB_OVR_CS && WRITE_PULSE && MY_SHD[7:0] !=8'h00 && !SHDQMLL_N;	// SHDQMLL_N.


wire SRAM_UB_N = (FB_CS && WRITE_PULSE) ? SHDQMLU_N : 
						 (OVR_WRITE_U) ? 1'b0 :
												1'b0;
						 
wire SRAM_LB_N = (FB_CS && WRITE_PULSE) ? SHDQMLL_N :
						 (OVR_WRITE_L) ? 1'b0 :
												1'b0;

//wire SRAM_WRITE_FORCE = ((FB_CS | FB_OVR_CS) && WRITE_PULSE) | !MRESET_N;
wire SRAM_WRITE_FORCE = (FB_CS | FB_OVR_CS) && WRITE_PULSE;

//wire SRAM_WE_N = !SRAM_WRITE_FORCE;
//wire SRAM_OE_N = SRAM_WRITE_FORCE;

// TODO - figure out how to add VDP_LSHIFT to the address for PACKED Pixel mode.


// WORD addresses!...
wire [8:0] PIX_OFFSET = (FB_MODE==0) ? PS1_PIX :		// VDP_MODE[1:0]==2'b00. OFF (but we're forcing it on atm).
								(FB_MODE==1) ? PS1_PIX[8:1] :	// VDP_MODE[1:0]==2'b01. PACKED pixel. Each WORD equals TWO pixels. (8-bit colour).
								(FB_MODE==2) ? PS1_PIX :		// VDP_MODE[1:0]==2'b10. DIRECT mode. 15-bit colour.
													RLE_PIX;			// VDP_MODE[1:0]==2'b11. RLE encoded.

// 16-bit address here, so we can access 128KB of Framebufer VRAM.
wire [15:0] VRAM_READ_ADDR = (!PS1_WINDOW) ? PS1_LINE :		// Allow the line address to be grabbed from the table when outside of the FB window.
										LINE_START_ADDR + PIX_OFFSET;	// Else, use the Line address, plus pixel offset.

//wire [16:0] MY_SRAM_ADDR = /*(!MRESET_N) ? RESET_CNT :*/									// For clearing the VRAM display during Reset.
									//(FB_CS) 		? {FB_SWAP,SH_ADDR[16:1]} :					// For Writes. (or CPU Framebuffer read access.)
									//(FB_OVR_CS) ? {FB_SWAP,SH_ADDR[16:1]} :					// For Writes. (or CPU Framebuffer read access.)
													 //{!FB_SWAP,VRAM_READ_ADDR};					// For display output reads. FB_SWAP bit gets inverted relative to writes.

//wire [18:0] SRAM_ADDR = {1'b0,MY_SRAM_ADDR};	// SRAM_ADDR is 18 bits [17:0].

//wire [15:0] SRAM_DQ = (!MRESET_N)			? 16'h4000 :	// Colour value used for clearing VRAM during Reset.
//							(SRAM_WRITE_FORCE)	? MY_SHD :		// Assert SH2 CPU Data bus onto SRAM (VRAM) during Writes.
//														16'hzzzz;		// Else, High-Z (for reads / display output).
																	
fb_32x	fb_32x_inst (
	.wrclock ( clk_26m ),
	.wraddress ( SH_ADDR[16:1] ),
	.byteena_a ( {!SRAM_UB_N, !SRAM_LB_N} ),
	.wren ( SRAM_WRITE_FORCE ),
	.data ( MY_SHD ),
	
	.rdaddress ( VRAM_READ_ADDR ),
	//.rdclock ( ce_pix ),
	.rdclock ( clk_26m ),
	
	.q ( fb_dout )
);
wire [15:0] fb_dout;	

						 
endmodule
