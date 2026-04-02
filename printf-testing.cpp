#include <stdio.h>
#include <math.h>
#include <string.h>
#include <assert.h>

//#include "doubles_arg.h"

extern "C" { int _my_printf(const char *format, ...) __attribute__ ((format (printf, 1, 2))); };

int get_normal_double_arg(char *double_buffer, int double_buffer_size, double double_arg);
int get_double_printf_arg_C_func(char *double_buffer, int double_buffer_size, double double_arg);

const double MIN_DOUBLE_VALUE   = 0.001;
const int MAX_DOUBLE_VALUE      = 1e6;
const int DEFAULT_PRECISION     = 3;

int get_normal_double_arg(char *double_buffer, int double_buffer_size, double double_arg) {
    assert(double_buffer);

    long long int_arg_part = floor(double_arg);
    
    double double_arg_part = double_arg -  floor(double_arg);
    
    char int_part_buffer[100] = "";
    int int_buffer_pos = 0, buffer_pos = 0;

    while (int_buffer_pos < double_buffer_size) {
        int_part_buffer[int_buffer_pos++] = int_arg_part % 10 + '0';

        int_arg_part = int_arg_part / 10;

        if (int_arg_part == 0)
            break;
    }

    while (int_buffer_pos > 0 && buffer_pos < double_buffer_size)
        double_buffer[buffer_pos++] =  int_part_buffer[--int_buffer_pos];
        
    if (double_arg_part == 0)
        return --buffer_pos;

    double_buffer[buffer_pos++] = '.';
    int curr_digit = 0;
       
    for (int i = 0; i < DEFAULT_PRECISION; i++)  {
        double_arg_part = double_arg_part * 10;
        
        curr_digit = floor(double_arg_part);      // curr number because.
        double_arg_part = double_arg_part - curr_digit;
        
        double_buffer[buffer_pos++] = '0' + curr_digit;

        if (double_arg_part == 0 || buffer_pos >= double_buffer_size)
            break;
    }

    double_buffer[buffer_pos] = 0;
    
    return --buffer_pos;
}

int get_double_printf_arg_C_func(char *double_buffer, int double_buffer_size, double double_arg) {
    assert(double_buffer);

    //if (isnan(double_arg) || isinf(double_arg)) {
        //const char *double_type = (isnan(double_arg) ? "nan" : "inf");  
    //    const char *double_type = NULL;
    //    if (isnan(double_arg))
    //        double_type = "nan";
    //    else
    //        double_type = "inf";
    //
    //    strncpy(double_buffer, double_type, double_buffer_size);
    //    return strlen(double_type);    
    //}

    if (isnan(double_arg)) {
        strncpy(double_buffer, "nan", double_buffer_size - 1);
        return 3;
    }
    
    if (isinf(double_arg)) {
        strncpy(double_buffer, "inf", double_buffer_size - 1);
        return 3;
    }

    if (isnormal(double_arg) == 0 || isfinite(double_arg) == 0 || double_arg < MIN_DOUBLE_VALUE || double_arg >= MAX_DOUBLE_VALUE) {
        return snprintf(double_buffer, double_buffer_size, "%g", double_arg);
    }

    return get_normal_double_arg(double_buffer, double_buffer_size, double_arg);
}

int main() {
    //printf("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b | original 'C' printf\n", -1, "love", 3802, 100, 33, -1, "love", 3802, 100, 33, 30);
    
    //printf("aboba |%s|%c|%c|%c|%c|%c| aboba %x %o %b %d %d aboba\n", "aboba", 'a', 'b', 'o', 'b', 'a', 123, 123, 123, -123);

    _my_printf("aboba |%s|%c|%c|%c|%c|%c| aboba %x %o %d %d aboba\n", "aboba", 'a', 'b', 'o', 'b', 'a', 123, 123, 123, -123);

    //_my_printf ("%d %s %x %d%%%c \n%d %s %x %d%%%c%b | my printf\n", -1, "love", 3802, 100, 33, -1, "love", 3802, 100, 33, 30);

    //_my_printf("%d %f %f %f %f %f\n%g %g %g %g %g\n", 123, NAN, INFINITY, 123.456789, 123.0e+300, 0.000001, NAN, INFINITY, 123.456789, 123.0e+300, 0.000001);

    //_my_printf ("%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b | my printf\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b | my printf\n", -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30, -1, "love", 3802, 100, 33, 30);
    //char double_buffer[100] = "";
    //get_double_printf_arg_C_func(double_buffer, 1e12, 100);
    //printf("%s \n %g", double_buffer,  1e6);
    return 0;
}