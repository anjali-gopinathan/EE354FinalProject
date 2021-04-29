`timescale 1ns / 1ps

module vga_top_tb;

    // Inputs
    reg ClkPort;
	reg BtnC;
	reg BtnU;
	reg BtnR;
	reg BtnL;
	reg BtnD;

	//VGA signal
	wire hSync; 
    wire vSync;
	wire [3:0] vgaR, vgaG, vgaB;
	
	//SSD signal 
	wire An0, An1, An2, An3, An4, An5, An6, An7;
	wire Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	
	wire MemOE, MemWR, RamCS, QuadSpiFlashCS;

    // Instantiate the Unit Under Test (UUT)
    vga_top vga_top_uut(
        .ClkPort(ClkPort),
        .BtnC(BtnC),
        .BtnU(BtnU),
        .BtnR(BtnR),
        .BtnL(BtnL),
        .BtnD(BtnD),
        .hSync(hSync),
        .vSync(vSync),
        .vgaR(vgaR),
        .vgaG(vgaG),
        .vgaB(vgaB),
        .An0(An0), .An1(An1), .An2(An2), .An3(An3), .An4(An4), .An5(An5), .An6(An6), .An7(An7),
        .Ca(Ca), .Cb(Cb), .Cc(Cc), .Cd(Cd), .Ce(Ce), .Cf(Cf), .Cg(Cg), .Dp(Dp),
        .MemOE(MemOE), .MemWR(MemWR), .RamCS(RamCS), .QuadSpiFlashCS(QuadSpiFlashCS)
    );

    always  begin #5; ClkPort = ~ ClkPort; end

    initial begin
        ClkPort = 0;
        BtnC = 0;
        #15
        BtnC = 1;
        #15
        BtnC = 0;
    end

endmodule