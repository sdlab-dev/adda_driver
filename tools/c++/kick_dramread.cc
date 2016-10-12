#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>


int sdlab_send(char *dst, int port, char* buf, int size)
{
  int sock;
  struct sockaddr_in addr;

  if((sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
    perror("socket");
    return -1;
  }


  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = inet_addr(dst);

  connect(sock, (struct sockaddr *)&addr, sizeof(addr));

  // パケットをUDPで送信
  if(send(sock, buf, size, 0) < 0) {
    perror("send");
    return -1;
  }

  uint32_t cmd;
  if(recv(sock, &cmd, sizeof(cmd), 0) < 0) {
    perror("recv");
    return -1;
  }

  cmd = ntohl(cmd);

  // ソケットのクローズ
  close(sock);

  // 受信データの出力
  printf("%d\n", cmd);

  return 0;
}

int main(int argc, char** argv)
{
  uint32_t x = htonl(0x00000005);
  char buf[1024];
  char *p = (char*)&x;

  buf[0] = p[0];
  buf[1] = p[1];
  buf[2] = p[2];
  buf[3] = p[3];

  sdlab_send((char*)"10.0.0.1", 0x4000, (char*)buf, 4);
}
