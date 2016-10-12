import socket
import time
import struct
import random

import matplotlib.pyplot as plt

import udp_utils

class udp_plot:
    TARGET_HOST = "10.0.0.1"
    TARGET_PORT = 16385

if __name__ == '__main__':

    plt.ion()
    fig = plt.figure()
    ax0 = fig.add_subplot(111)
    ax0.set_autoscaley_on(False)
    ax0.set_ylim([-32768, 32768])
    ax0.set_xlim([0, 256])

    u = udp_utils.udp_utils()
    while True:
        d = u.send_recv('10.0.0.1', 16385, struct.pack('>I', 0))
        r = struct.unpack('>'+'h'*512, d)
        ax0.plot(r[0::2])
        ax0.plot(r[1::2])
        plt.draw()
        plt.pause(0.1)
        ax0.clear()
        ax0.set_ylim([-32768, 32768])
        ax0.set_xlim([0, 256])
        
    u.close()
