#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <arpa/inet.h>

#include "sdlab_utils.h"

int main(int argc, char** argv)
{
  int nPoints = argc > 1 ? atoi(argv[1]) : 1*1024*1024;
  nPoints = nPoints < 0 ? 0 : nPoints;
  nPoints = nPoints > 128*1024*1024 ? 128*1024*1024 : nPoints;
  uint32_t sbuf[2];
  sbuf[0] = htonl(0x00000007);
  sbuf[1] = htonl(nPoints);
  char buf[1024];

  sdlab_sendrecv((char*)"10.0.0.1", 0x4000, (char*)sbuf, 8, (char*)buf, 4);

  printf("%08x\n", ntohl(*(int*)buf));

}
