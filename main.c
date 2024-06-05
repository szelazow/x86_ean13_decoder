#include <stdio.h>
#include <stdlib.h>

extern void decode_ean13(char *out, void *img);

int main(int argc, char* argv[]){                                          //argv[1] - file path
    int  bmpsize, offset, bpp, width, height;
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

    fseek(img, 2, SEEK_SET);
    fread(&bmpsize, 4, 1, img);
    fseek(img, 10, SEEK_SET);
    fread(&offset, 4, 1, img);
    fseek(img, 18, SEEK_SET);
    fread(&width, 4, 1, img);
    fseek(img, 28, SEEK_SET);
    fread(&bpp, 2, 1, img);                                             //loading test data    fseek(img, fsize - offset, SEEK_SET)

    void *loaded_image = malloc(bmpsize);
    fseek(img, 0, SEEK_SET);
    fread(loaded_image, 1, bmpsize, img);
    void *map = loaded_image + offset;  

    decode_ean13(output, map);
    printf("Code: ");
    for(int i = 0; i < 13; i++){
        printf("%d ", output[i]);
    }
    printf("\n");
    free(loaded_image);
    fclose(img);
    return 0;
}