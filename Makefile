main:	main.o ean13_reader.o
	cc -m32 -o main main.o ean13_reader.o

main.o: main.c
	cc -m32 -c main.c

ean13_reader.o: ean13_reader.s
	nasm -f elf32 ean13_reader.s

clean:
	rm -f *.o