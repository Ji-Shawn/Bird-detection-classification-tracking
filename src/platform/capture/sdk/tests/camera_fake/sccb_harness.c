#include <stdint.h>
#include <string.h>
#include "xgpio.h"
static uint32_t out,dir,elapsed;
static unsigned char regs[65536],bytes[8],acc;
static unsigned nbits,nbytes,read_bits,ack_read;
static unsigned address;
static int active,mode;
XGpio_Config *XGpio_LookupConfig(int id) {static XGpio_Config c={0};return &c;}
int XGpio_CfgInitialize(XGpio *p,XGpio_Config *c,uint32_t b){return 0;}
void usleep(unsigned int us){elapsed+=us;}
void XGpio_SetDataDirection(XGpio *p,unsigned c,uint32_t v){dir=v;}
void XGpio_DiscreteWrite(XGpio *p,unsigned c,uint32_t v){
    if((out&1) && (v&1) && ((out^v)&2) && !(dir&2)) {
        if(!(v&2)) {active=1;nbits=nbytes=read_bits=ack_read=0;acc=0;}
        else if(active) {
            if(nbytes>=3 && bytes[0]==0x78) {
                address=((unsigned)bytes[1]<<8)|bytes[2];
                if(nbytes==4) regs[address]=bytes[3];
            }
            active=0;
        }
    }
    if(active && !(out&1) && (v&1) && !(dir&2)) {
        acc=(acc<<1)|((v>>1)&1);nbits++;
        if(nbits==8){if(nbytes<8)bytes[nbytes++]=acc;nbits=0;acc=0;}
    }
    out=v;
}
uint32_t XGpio_DiscreteRead(XGpio *p,unsigned c){
    unsigned value;
    if(mode==1) return 2;
    if(nbytes==1 && bytes[0]==0x79) {
        if(!ack_read){ack_read=1;return 0;}
        value=regs[address];
        if(mode==2 && address==0x4300)value^=1;
        if(mode==3 && address==0x4740)value^=0x20;
        return ((value>>(7-(read_bits++%8)))&1)<<1;
    }
    return 0;
}
int ov5640_camera_init(void);
int ov5640_camera_prepare(void);
int ov5640_camera_start(void);
__declspec(dllexport) int camera_prepare(void){return ov5640_camera_prepare();}
__declspec(dllexport) int camera_start(void){return ov5640_camera_start();}
int ov5640_diagnostic_phase(unsigned mode);
__declspec(dllexport) int camera_phase(unsigned phase){return ov5640_diagnostic_phase(phase);}
__declspec(dllexport) int run_camera(int failure){
    out=dir=elapsed=0;active=0;mode=failure;memset(regs,0,sizeof(regs));
    regs[0x300a]=0x56;regs[0x300b]=0x40;
    return ov5640_camera_init();
}
__declspec(dllexport) unsigned camera_register(unsigned a){return regs[a];}
__declspec(dllexport) unsigned camera_output(void){return out;}
__declspec(dllexport) unsigned camera_elapsed(void){return elapsed;}
