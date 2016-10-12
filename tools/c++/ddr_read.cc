#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <arpa/inet.h>


#include "sdlab_utils.h"

int main(int argc, char** argv)
{
  uint32_t x = htonl(CMD_BRAM_WRITE);
  char buf[2048];
  char *p = (char*)&x;

  if(argc < 2){
    printf("usage: %s address <data>\n", argv[0]);
    exit(1);
  }

  uint64_t addr = strtol(argv[1], NULL, 0);

  int v;
  if(argc > 2) v = atoi(argv[1]);

  buf[0] = p[0];
  buf[1] = p[1];
  buf[2] = p[2];
  buf[3] = p[3];

  //for command_reserve 48bit
  buf[4] = 0x00;
  buf[5] = 0x00;
  buf[6] = 0x00;
  buf[7] = 0x00;

  buf[8] = 0x00;
  buf[9] = 0x00;

  //for command 8bit
  buf[10] = 0x01; // e7MemIface READ COMMAND

  //for length
  buf[11] = 0x20;

  //for address
  buf[12] = (addr >> 56) & 0xFF;
  buf[13] = (addr >> 48) & 0xFF;
  buf[14] = (addr >> 40) & 0xFF;
  buf[15] = (addr >> 32) & 0xFF;
  buf[16] = (addr >> 24) & 0xFF;
  buf[17] = (addr >> 16) & 0xFF;
  buf[18] = (addr >>  8) & 0xFF;
  buf[19] = (addr >>  0) & 0xFF;

  sdlab_sendrecv((char*)"10.0.0.1", 0x4000, (char*)buf, 20, buf, 4);
  printf("%08x\n", ntohl(*(int*)buf));

  x = htonl(CMD_KICK_DRAMREAD);
  sdlab_sendrecv((char*)"10.0.0.1", 0x4000, (char*)&x, 4, buf, 4);
  printf("%08x\n", ntohl(*(int*)buf));

}
