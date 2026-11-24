#include "../../runtime/SYSTEM.c"

int main(int argc, char **argv)
{
    const uintptr_t low = 32 * 1024 * 1024, high = low + 8 * 1024 * 1024;
    uintptr_t actualLow, actualHigh;
    setupAutomaticSegfaultHandler();
    Modules_Init(argc, (ADDRESS)&argv);
    if (!VOC_STACK_CONTEXT_SUPPORTED) return 78;
    if (!readStackBounds(&actualLow, &actualHigh)) return 77;
    stackAnchor = high - 1024;
    SYSTEM_SetStackBounds(low, high);
    if (!readStackBounds(&actualLow, &actualHigh) || actualLow != low || actualHigh != high) return 12;
    if (!stackFaultMatches(low - 128, low - 120)) return 1;
    if (!stackFaultMatches(low - 1024 * 1024, low - 1024 * 1024 + 32)) return 2;
    if (stackFaultMatches(high - 1024, 1)) return 3;
    if (stackFaultMatches(low + 1024, low - 1)) return 4;
    if (stackFaultMatches(low + 1, low + 1)) return 5;
    if (stackFaultMatches(low - 16 * 1024 * 1024 - 1, low - 16 * 1024 * 1024)) return 6;
    if (stackFaultMatches(0, low - 1) || stackFaultMatches(low, 0)) return 7;
    if (stackFaultMatches(high, high - 1)) return 8;
    if (stackFaultMatches(low - 1, low - 65538)) return 9;
    if (isStackOverflow(NULL, NULL)) return 10;
    SYSTEM_SetStackBounds(0, 0);
    if (stackFaultMatches(low - 128, low - 120)) return 11;
    return 0;
}
