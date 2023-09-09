RGBASM_FLAGS = -Weverything -Werror -H
RGBFIX_FLAGS = -c -s -l 0x33 -i dlpe -t "gb-dlp " -v -p 0xFF
RGBGFX_FLAGS = -d 1
RGBLINK_FLAGS = -t -p 0xFF

all: client.gb host.gb

client.gb: chicago8x8.tiledata client.o
	rgblink $(RGBLINK_FLAGS) -o client.gb client.o
	rgbfix $(RGBFIX_FLAGS) client.gb

chicago8x8.tiledata: chicago8x8.png
	rgbgfx $(RGBGFX_FLAGS) -o chicago8x8.tiledata chicago8x8.png

client.o: client.asm common.asm chicago8x8.tiledata
	rgbasm $(RGBASM_FLAGS) -o client.o client.asm

host.gb: host.o
	rgblink $(RGBLINK_FLAGS) -o host.gb host.o
	rgbfix -c -s -l 0x33 -i HOST -t "HOST " -v -p 0xFF host.gb

host.o: host.asm common.asm
	rgbasm $(RGBASM_FLAGS) -o host.o host.asm

clean:
	rm -f *.gb *.o *.tiledata
