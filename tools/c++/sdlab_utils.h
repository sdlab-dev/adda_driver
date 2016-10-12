#ifndef __SDLAB_UTILS_H__
#define __SDLAB_UTILS_H__

const int CMD_NULL           (0x000000000);
const int CMD_LED_ON         (0x000000001);
const int CMD_LED_OFF        (0x000000002);
const int CMD_BRAM_WRITE     (0x000000003);
const int CMD_BRAM_READ      (0x000000004);
const int CMD_KICK_DRAMREAD  (0x000000005);
const int CMD_KICK_DRAMWRITE (0x000000006);
const int CMD_KICK_ADC       (0x000000007);


int sdlab_sendrecv(char *dst, int port, char* buf, int size, char *rbuf, int rsize);

#endif /* __SDLAB_UTILS_H__ */

