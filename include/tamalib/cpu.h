#ifndef TAMALIB_CPU_H
#define TAMALIB_CPU_H

#define MEM_RAM_ADDR      0x000
#define MEM_RAM_SIZE      0x300 // 768 x 4 bits of RAM
#define MEM_DISPLAY1_ADDR 0xE00
#define MEM_DISPLAY1_SIZE 0x066 // 102 x 4 bits of RAM
#define MEM_DISPLAY2_ADDR 0xE80
#define MEM_DISPLAY2_SIZE 0x066 // 102 x 4 bits of RAM
#define MEM_IO_ADDR       0xF00
#define MEM_IO_SIZE       0x080

#define MEM_SIZE          4096 // 4096 x 4 bits
#define MEM_BUFFER_SIZE   (MEM_SIZE / 2)

#define SET_RAM_MEMORY(buffer, n, v)   SET_MEMORY(buffer, n, v)
#define SET_DISP1_MEMORY(buffer, n, v) SET_MEMORY(buffer, n, v)
#define SET_DISP2_MEMORY(buffer, n, v) SET_MEMORY(buffer, n, v)
#define SET_IO_MEMORY(buffer, n, v)    SET_MEMORY(buffer, n, v)

#define GET_RAM_MEMORY(buffer, n)   GET_MEMORY(buffer, n)
#define GET_DISP1_MEMORY(buffer, n) GET_MEMORY(buffer, n)
#define GET_DISP2_MEMORY(buffer, n) GET_MEMORY(buffer, n)
#define GET_IO_MEMORY(buffer, n)    GET_MEMORY(buffer, n)

#endif // TAMALIB_CPU_H
