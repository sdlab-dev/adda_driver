APP = led_off led_on bram_read bram_write_test ddr_write_test ddr_read adc_on dac_on

all: $(APP)

.cc.o:
	gcc -c $<

led_off: led_off.o sdlab_utils.o
	gcc -o $@ $^

led_on: led_on.o sdlab_utils.o
	gcc -o $@ $^

adc_on: adc_on.o sdlab_utils.o
	gcc -o $@ $^

dac_on: dac_on.o sdlab_utils.o
	gcc -o $@ $^

bram_read: bram_read.o sdlab_utils.o
	gcc -o $@ $^

bram_write_test: bram_write_test.o sdlab_utils.o
	gcc -o $@ $^

ddr_read: ddr_read.o sdlab_utils.o
	gcc -o $@ $^

ddr_write_test: ddr_write_test.o sdlab_utils.o
	gcc -o $@ $^


clean:
	-rm -f *.o
	-rm -f $(APP)
