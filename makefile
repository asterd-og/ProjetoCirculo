all:
	nasm -felf32 src/main.asm -o src/main.o
	nasm -felf32 src/mmu.asm -o src/mmu.o
	gcc -m32 src/main.o src/mmu.o -o out/circulo
	rm src/main.o src/mmu.o
	./out/circulo