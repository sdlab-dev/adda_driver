led_off:
KC705上のLED(7)を消灯します．

led_on:
KC705上のLED(7)を点灯します．

bram_read:
BRAMのデータを1024バイト読み出します．

bram_write_test <data>:
BRAMにデータを1024バイト書き出します．
dataが指定された場合はその値を，指定されない場合にはカウンタ値を書き出します．

ddr_write_test addr <data>:
BRAMにDDRアクセス用のヘッダと1024Byteのデータを書き，さらに，その1024ByteのデータをDDRに転送します．
 addr: 書き込み先のDDRメモリのアドレス．64Byte単位で指定してください．
 data: 書き込むデータ．この引数を省略した場合，カウンタ値を書き出します．

ddr_read addr:
DDRメモリの指定したアドレスから1024バイトのデータをBRAMに読み出します．
 addr: 読み出すDDRメモリのアドレス．64Byte単位で指定してください．

adc_on:
ADCから1M(=1024*1024)サンプルのデータを読みだし，DDRのアドレス0番地から順に書きます．

dac_on:
DDRのアドレス0番地から順に1M(=1024*1024)サンプルのデータを読みだしDACに出力します．


