#ifndef DOUBLES_ARG_H_INCLUDED
#define DOUBLES_ARG_H_INCLUDED

int get_normal_double_arg(char *double_buffer, int double_buffer_size, double double_arg);
int get_double_printf_arg_C_func(char *double_buffer, int double_buffer_size, double double_arg);

const double MIN_DOUBLE_VALUE   = 0.001;
const int MAX_DOUBLE_VALUE      = 1e6;
const int DEFAULT_PRECISION     = 3;

#endif