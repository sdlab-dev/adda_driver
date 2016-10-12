#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>

int sdlab_sendrecv(char *dst, int port, char* buf, int size, char *rbuf, int recv_size)
{
  int sock, ret;
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

  if((ret = recv(sock, rbuf, recv_size, 0)) < 0) {
    perror("recv");
    return -1;
  }

  // ソケットのクローズ
  close(sock);

  return ret;
}

