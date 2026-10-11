#ifndef VOC_TEST_TERMINAL_SUPPORT_H
#define VOC_TEST_TERMINAL_SUPPORT_H

#include "SYSTEM.h"

INT32 VOCTest_open_terminal(void);
void VOCTest_close_terminal(INT32 fd);
INT32 VOCTest_terminal_settings(INT32 fd, INT32 raw, INT32 timed);
INT32 VOCTest_terminal_dimensions(INT32 fd);

#endif
