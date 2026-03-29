#include <stdio.h>

extern "C" { int _my_printf(const char *format, ...) __attribute__ ((format (printf, 1, 2))); };

int main() {
    //printf("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b | original 'C' printf\n", -1, "love", 3802, 100, 33, -1, "love", 3802, 100, 33, 30);
    
    //printf("aboba |%s|%c|%c|%c|%c|%c| aboba %x %o %b %d %d aboba\n", "aboba", 'a', 'b', 'o', 'b', 'a', 123, 123, 123, -123);

    //_my_printf("aboba |%s|%c|%c|%c|%c|%c| aboba %x %o %d %d aboba\n", "aboba", 'a', 'b', 'o', 'b', 'a', 123, 123, 123, -123);

    //_my_printf ("%d %s %x %d%%%c \n%d %s %x %d%%%c%b | my printf\n", -1, "love", 3802, 100, 33, -1, "love", 3802, 100, 33, 30);

    _my_printf("%d %d %d %f \n", 123, 123, 123, 123.456789);

    //_my_printf ("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b | my printf\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b | my printf\n", -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30);

    return 0;
}