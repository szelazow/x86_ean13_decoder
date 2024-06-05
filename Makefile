main:	main.o ean13_reader.o
	gcc -m32 -o main main.o ean13_reader.o -no-pie

main.o: main.c
	gcc -m32 -c main.c -no-pie

ean13_reader.o: ean13_reader.s
	nasm -f elf32 ean13_reader.s

clean:
	rm -f *.o