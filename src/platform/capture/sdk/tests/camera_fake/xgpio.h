#include <stdint.h>
typedef struct {uint32_t BaseAddress;} XGpio_Config;
typedef struct {uint32_t BaseAddress;} XGpio;
#define XST_SUCCESS 0
XGpio_Config *XGpio_LookupConfig(int id);
int XGpio_CfgInitialize(XGpio *p,XGpio_Config *c,uint32_t base);
void XGpio_DiscreteWrite(XGpio *p,unsigned channel,uint32_t value);
void XGpio_SetDataDirection(XGpio *p,unsigned channel,uint32_t value);
uint32_t XGpio_DiscreteRead(XGpio *p,unsigned channel);
