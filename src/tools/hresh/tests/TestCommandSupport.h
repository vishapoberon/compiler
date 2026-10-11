#ifndef VOC_TEST_COMMAND_SUPPORT_H
#define VOC_TEST_COMMAND_SUPPORT_H

void VOC_TestInterrupt(void);
void VOC_TestNativeCallback(void (*callback)(void));
int VOC_TestNativeReturned(void);
void VOC_TestSignalHandler(int install);
int VOC_TestPreviousSignals(void);
int VOC_TestInterruptingCondition(void);
int VOC_TestStartInterrupt(void);
int VOC_TestWaitInterrupt(void);
int VOC_TestListen(void);
int VOC_TestAccept(int fd);
void VOC_TestClose(int fd);
int VOC_TestListenerClosed(void);
void VOC_TestBlockInterrupt(int block);

#endif
