# 1.理想流水线（不考虑冲突冒险）

​	1.数据存储器data_ram的4位字节写使能信号。

​	2.取指阶段，inst_ram是时钟信号同步读，所以inst晚于pc一个周期，会造成instD和pcD不同步，这里instD的传递采用组合逻辑。

​	3.alu设计时，算术右移时高位要补符号位，这是需要把操作数1声明为wire signed。

​	4.data_ram也是同步读，因此mem_result天然也会落后于data_sram_addr一个周期，因此写回阶段mem_resultW也采用组合逻辑。