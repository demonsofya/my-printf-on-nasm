#include <stdio.h>

extern "C" { int _my_printf(const char *format, ...) __attribute__ ((format (printf, 1, 2))); };

int main() {

    _my_printf("aboba");
    return 0;
}