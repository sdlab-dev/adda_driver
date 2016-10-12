#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <arpa/inet.h>

#include "sdlab_utils.h"

int main(int argc, char** argv)
{
  uint32_t x = htonl(0x00000001);
  char buf[1024];

  sdlab_sendrecv((char*)"10.0.0.1", 0x4000, (char*)&x, 4, (char*)buf, 4);

  printf("%08x\n", ntohl(*(int*)buf));

}
