#include <stdio.h>
#include <stdlib.h>

extern void decode_ean13(char *out, void *img);

int main(int argc, char* argv[]){                                          //argv[1] - file path
    int  offset, bpp, width, height;
    char* output = malloc(sizeof(char) * 13);
    FILE *img;
    if (argc != 2) {
        printf("ERROR 1: Please input the BMP file's name");
        return 1;
    }
    img = fopen(argv[1], "rb");
    if(img == NULL){
        printf("ERROR 2: file not found");
        return 2;
    }

    fseek(img, 10, SEEK_SET);
    fread(&offset, 4, 1, img);
    fseek(img, 18, SEEK_SET);
    fread(&width, 4, 1, img);
    fseek(img, 28, SEEK_SET);
    fread(&bpp, 2, 1, img);                                             //loading test data    fseek(img, fsize - offset, SEEK_SET)

    void *first_line = malloc(width);
    fseek(img, offset, SEEK_SET);
    fread(first_line, 1, width, img);
    decode_ean13(output, img);
    printf("%p", first_line);
    fclose(img);

    return 0;
}