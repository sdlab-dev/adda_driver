import socket
import time
import struct
import random
from datetime import datetime

class udp_utils:

    CMD_NULL           = struct.pack('>I', 0x000000000)
    CMD_LED_ON         = struct.pack('>I', 0x000000001);
    CMD_LED_OFF        = struct.pack('>I', 0x000000002);
    CMD_BRAM_WRITE     = struct.pack('>I', 0x000000003);
    CMD_BRAM_READ      = struct.pack('>I', 0x000000004);
    CMD_KICK_DRAMREAD  = struct.pack('>I', 0x000000005);
    CMD_KICK_DRAMWRITE = struct.pack('>I', 0x000000006);
    CMD_KICK_ADC       = struct.pack('>I', 0x000000007);
    CMD_KICK_DAC       = struct.pack('>I', 0x000000008);
    CMD_KICK_DAC_ADC   = struct.pack('>I', 0x000000009);

    E7MEMIFACE_WRITE = 4
    E7MEMIFACE_READ = 1

    TARGET_PORT = 16384

    def __init__(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def send_recv(self, host, port, b):
        self.sock.sendto(b, (socket.gethostbyname(host), port))
        data, addr = self.sock.recvfrom(1500)
        return data

    def led_on(self, host):
        self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_LED_ON)

    def led_off(self, host):
        self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_LED_OFF)

    def adc_on(self, host):
        self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_KICK_ADC)
        
    def dac_on(self, host):
        d = self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_KICK_DAC)
        
    def dac_adc_on(self, host):
        d = self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_KICK_DAC_ADC)

    def adc_addr_reset(self, host):
        self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_NULL)
        
    def ddr3_write_1KB(self, host, addr, data):
        # command (4Byte)
        b = udp_utils.CMD_BRAM_WRITE
        # header padding (6Byte)
        b += struct.pack('>IH', 0, 0)
        # e7MemIface write comand(1Byte)
        b += struct.pack('>B', udp_utils.E7MEMIFACE_WRITE)
        # length (1Byte)
        b += struct.pack('>B', 0x20)
        # address (8Byte)
        b += struct.pack('>Q', addr)
        # data copy ( <= 1024Byte)
        b += data
        # padding data
        for d in range(1024-len(data)):
            b += struct.pack('>B', 0)

        # copy command packet data into BRAM
        self.send_recv(host, udp_utils.TARGET_PORT, b)
        # kick DRAM WRITE
        self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_KICK_DRAMWRITE)

    def ddr3_read_1KB(self, host, addr):
        # command (4Byte)
        b = udp_utils.CMD_BRAM_WRITE
        # header padding (6Byte)
        b += struct.pack('>IH', 0, 0)
        # e7MemIface read comand(1Byte)
        b += struct.pack('>B', udp_utils.E7MEMIFACE_READ)
        # length (1Byte)
        b += struct.pack('>B', 0x20)
        # address (8Byte)
        b += struct.pack('>Q', addr)

        # copy command packet data into BRAM
        self.send_recv(host, udp_utils.TARGET_PORT, b)
        # kick DRAM READ
        self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_KICK_DRAMREAD)
        # copy data from BRAM
        d = self.send_recv(host, udp_utils.TARGET_PORT, udp_utils.CMD_BRAM_READ)
        return d

    def ddr3_check(self, host, addr):
        a = [random.randint(0,255) for i in range(1024)]
        u.ddr3_write_1KB("10.0.0.1", addr, bytearray(a))
        b = u.ddr3_read_1KB("10.0.0.1", addr)
        f = True
        for i in range(1024):
            if a[i] != b[i+4]:
                f = False
                print("error")
        return f

    def close(self):
        self.sock.close()


    def split_ch(self, d):
        a = list(sum(zip(d[0::8], d[2::8]), ()))
        b = list(sum(zip(d[1::8], d[3::8]), ()))
        ch0 = list(sum(zip(a, b), ()))
        a = list(sum(zip(d[4::8], d[6::8]), ()))
        b = list(sum(zip(d[5::8], d[7::8]), ()))
        ch1 = list(sum(zip(a, b), ()))
        return ch0, ch1

def gen_dummy_pulse():
    b = b''
    flag = False
    v0 = 2**15-1
    v1 = 2**15
    div = 32
    for i in range(1024//div):
        if flag:
            for j in range(div//16):
                b += struct.pack('>HHHH', v0, v0, v0, v0) # ch C
                b += struct.pack('>HHHH', v0, v0, v0, v0) # ch D
                flag = False
        else:
            for j in range(div//16):
                b += struct.pack('>HHHH', v1, v1, v1, v1) # ch C
                b += struct.pack('>HHHH', v1, v1, v1, v1) # ch D
                flag = True
    return b

def gen_all_high():
    d = [2**15-1 for _ in range(1024//2)]
    return struct.pack('>'+'H'*512, *d)

def dump_adc_result(dest, ch0, ch1):
    f = open(dest, 'w')
    f.write("## data ch0\n")
    for i in ch0:
        f.write(str(i) + '\n')
    f.write('\n\n')
    f.write("## data ch1\n")
    for i in ch1:
        f.write(str(i) + '\n')
    f.close()

if __name__ == '__main__':
    host = "10.0.0.1"
    u = udp_utils()
    print("led on and off (1Hz), 3 times")
    for i in range(3):
        u.led_on(host)
        time.sleep(0.5)
        u.led_off(host)
        time.sleep(0.5)
    print("DDR write/read check")
    if u.ddr3_check(host, 16384) == True:
        print("ddr3 write/read success")
    else:
        print("ddr3 write/read failure")
        
    print("ADC check")
    u.adc_on(host)
    ch0 = []
    ch1 = []
    for i in range(4096):
        d = u.ddr3_read_1KB(host, i*1024)
        r = struct.unpack('>'+'h'*512, d[4:])
        c0, c1 = u.split_ch(r)
        ch0 += c0
        ch1 += c1
    adcdat = 'adc-' + datetime.now().strftime('%Y-%m-%d-%M-%H-%S') + '.dat'
    dump_adc_result(adcdat, ch0, ch1)

    for i in range(4096):
        u.ddr3_write_1KB(host, 512*1024*1024+i*1024, gen_dummy_pulse())
        
    print("DAC/ADC check")
    u.adc_addr_reset(host)
    for _ in range(128):
        u.dac_adc_on(host)
    ch0 = []
    ch1 = []
    for i in range(4096):
        d = u.ddr3_read_1KB(host, i*1024)
        r = struct.unpack('>'+'h'*512, d[4:])
        c0, c1 = u.split_ch(r)
        ch0 += c0
        ch1 += c1
    adcdacdat = 'adcdac-' + datetime.now().strftime('%Y-%m-%d-%M-%H-%S') + '.dat'
    dump_adc_result(adcdacdat, ch0, ch1)
        
    u.close()
    print("Done")
    print("ADC check result = " + adcdat)
    print("ADC/DAC check result = " + adcdacdat)
