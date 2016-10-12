#include <stdio.h>
#include <stdlib.h>

#include "sdlab_utils.h"

int main(int argc, char** argv)
{
  uint32_t x = htonl(0x00000004);
  char buf[2048];

  int ret = sdlab_sendrecv((char*)"10.0.0.1", 0x4000, (char*)&x, 4, (char*)buf, 2048);

  // 受信データの出力
  printf("cmd = %08x\n", ntohl(*(int*)buf));

  printf("data (length = %d)\n", ret);
  for(int i = 4; i < ret; i++){
    if((i - 4) % 16 == 0) printf("%08x:", (i - 4) / 16 * 16);
    printf(" %02x", (int)(buf[i] & 0xFF));
    if((i - 4) % 16 == 15) printf("\n");
  }
  printf("\n");

}
