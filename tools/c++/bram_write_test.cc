#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <arpa/inet.h>

#include "sdlab_utils.h"

int main(int argc, char** argv)
{
  uint32_t x = htonl(0x00000003);
  char buf[2048];
  char *p = (char*)&x;

  int v = 0;
  if(argc > 1) v = atoi(argv[1]);

  buf[0] = p[0];
  buf[1] = p[1];
  buf[2] = p[2];
  buf[3] = p[3];

  for(int i = 0; i < 1024; i++){
    buf[i+4] = (argc > 1 ? v : i) & 0x000000FF;
  }

  sdlab_sendrecv((char*)"10.0.0.1", 0x4000, (char*)buf, 1024 + 4, (char*)buf, 4);

  printf("%08x\n", ntohl(*(int*)buf));

}
