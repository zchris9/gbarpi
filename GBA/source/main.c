#include <stdio.h>
#include <string.h>
#include <tonc.h>

// Sound flags
#define SND_ENABLED           0x0080
#define SND_OUTPUT_RATIO_25   0x0000
#define SND_OUTPUT_RATIO_50   0x0001
#define SND_OUTPUT_RATIO_100  0x0002
#define DSA_OUTPUT_RATIO_50   0x0000
#define DSA_OUTPUT_RATIO_100  0x0004
#define DSA_OUTPUT_TO_RIGHT   0x0100
#define DSA_OUTPUT_TO_LEFT    0x0200
#define DSA_OUTPUT_TO_BOTH    0x0300
#define DSA_TIMER0            0x0000
#define DSA_TIMER1            0x0400
#define DSA_FIFO_RESET        0x0800
#define DSB_OUTPUT_RATIO_50   0x0000
#define DSB_OUTPUT_RATIO_100  0x0008
#define DSB_OUTPUT_TO_RIGHT   0x1000
#define DSB_OUTPUT_TO_LEFT    0x2000
#define DSB_OUTPUT_TO_BOTH    0x3000
#define DSB_TIMER0            0x0000
#define DSB_TIMER1            0x4000
#define DSB_FIFO_RESET        0x8000

// DMA flags
#define WORD_DMA            0x04000000
#define HALF_WORD_DMA       0x00000000
#define ENABLE_DMA          0x80000000
#define START_ON_FIFO_EMPTY 0x30000000
#define DMA_REPEAT          0x02000000
#define DEST_REG_SAME       0x00400000
#define SRC_REG_SAME        0x01000000

// Timer flags
#define TIMER_ENABLED       0x0080

#define DMA_TRANSFER(_dst, _src, count, ch, mode)   \
do {                                            \
    REG_DMA[ch].cnt= 0;                         \
    REG_DMA[ch].src= (const void*)(_src);       \
    REG_DMA[ch].dst= (void*)(_dst);             \
    REG_DMA[ch].cnt= (count) | (mode);          \
} while(0)

#define CODE_IN_IWRAM __attribute__ ((section (".iwram"), long_call))

CODE_IN_IWRAM
int main()
{
	// Write into the I/O registers, setting video display parameters.
	volatile unsigned char *ioram = (unsigned char *)0x04000000;
	ioram[0] = 0x03; // Set the 'video mode' to 3 (in which BG2 is a 16 bpp bitmap in VRAM)
	ioram[1] = 0x04; // Enable BG2 (BG0 = 1, BG1 = 2, BG2 = 4, ...)

	volatile unsigned short *vram = (unsigned short *)0x06000000; // GBA VRAM
	volatile unsigned short *fbuf = (unsigned short *)0x09000000; // cartridge RAM
	volatile unsigned char *sram = (unsigned char *)0x0E000000; // cartridge FPGA RAM



	REG_WAITCNT = 0x0018; // fast game pak ROM access
	REG_WAITCNT = 0x0800; // enable clock output

	REG_SOUNDBIAS |= 0x00000000;

	REG_SOUNDCNT_L = 0;
	REG_SOUNDCNT_H = SND_OUTPUT_RATIO_100 |
	                 DSA_OUTPUT_RATIO_100 |
	                 DSA_OUTPUT_TO_BOTH |
	                 DSA_TIMER0 |
	                 DSA_FIFO_RESET;
	REG_SOUNDCNT_X = SND_ENABLED;

	REG_DMA1SAD = 0x08FFFF00;
	REG_DMA1DAD = 0x040000a0;
	REG_DMA1CNT = ENABLE_DMA | START_ON_FIFO_EMPTY | WORD_DMA | DMA_REPEAT | SRC_REG_SAME;

	REG_TM0D = 65155;
	//REG_TM0D = 65155; // 44100 Hz Audio
	//REG_TM0D = 65024; //32768 Hz Audio
	REG_TM0CNT = TIMER_ENABLED;


	unsigned int i;

	for(i=0; i<38400; i++)
	{
		vram[i] = 0x7C50; 
	}

	//DMA_TRANSFER(vram, fbuf, 38400, 3, 0x92600000);

	while(1)
	{
		while (REG_VCOUNT < 160);

		//REG_DISPCNT |= 0x0080;
		DMA_TRANSFER(vram, fbuf, 38400, 3, 0x80000000); // copy a frame from the cartridge RAM to the GBA VRAM
		//REG_DISPCNT &= ~0x0080;

		sram[0] = (unsigned char)(REG_KEYINPUT&0x00FF); // copy gamepad input to the FPGA
		sram[1] = (unsigned char)((REG_KEYINPUT>>8)&0x00FF); // copy gamepad input to the FPGA


		while (REG_VCOUNT > 160); 
	}
	
	return 0;
}
