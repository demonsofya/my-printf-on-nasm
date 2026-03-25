//#include "Txlib.h"
#include <stdio.h>

extern "C" { int _my_printf(const char *format, ...) __attribute__ ((format (printf, 1, 2))); };

int main() {

    _my_printf("aboba |%s|%c|%c|%c|%c|%c| aboba %x %o aboba\n", "aboba", 'a', 'b', 'o', 'b', 'a', 123, 123);

    printf("x2aboba");
    return 0;
}