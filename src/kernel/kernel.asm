
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	f0e78793          	addi	a5,a5,-242 # 80005f70 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb25f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3e0080e7          	jalr	992(ra) # 8000250a <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	18c080e7          	jalr	396(ra) # 80002354 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	eca080e7          	jalr	-310(ra) # 800020a0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2a2080e7          	jalr	674(ra) # 800024b4 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	26e080e7          	jalr	622(ra) # 80002560 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cbe080e7          	jalr	-834(ra) # 80002104 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	f9078793          	addi	a5,a5,-112 # 80022408 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07aa23          	sw	zero,1492(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	36f72023          	sw	a5,864(a4) # 800088e0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	564dad83          	lw	s11,1380(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	50e50513          	addi	a0,a0,1294 # 80010b08 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3b050513          	addi	a0,a0,944 # 80010b08 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	39448493          	addi	s1,s1,916 # 80010b08 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	35450513          	addi	a0,a0,852 # 80010b28 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0e07a783          	lw	a5,224(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0b07b783          	ld	a5,176(a5) # 800088e8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0b073703          	ld	a4,176(a4) # 800088f0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2c6a0a13          	addi	s4,s4,710 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	07e48493          	addi	s1,s1,126 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	07e98993          	addi	s3,s3,126 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	870080e7          	jalr	-1936(ra) # 80002104 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	25850513          	addi	a0,a0,600 # 80010b28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0007a783          	lw	a5,0(a5) # 800088e0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	00673703          	ld	a4,6(a4) # 800088f0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	ff67b783          	ld	a5,-10(a5) # 800088e8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	22a98993          	addi	s3,s3,554 # 80010b28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fe248493          	addi	s1,s1,-30 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fe290913          	addi	s2,s2,-30 # 800088f0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	782080e7          	jalr	1922(ra) # 800020a0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1f448493          	addi	s1,s1,500 # 80010b28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7b423          	sd	a4,-88(a5) # 800088f0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	16e48493          	addi	s1,s1,366 # 80010b28 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00023797          	auipc	a5,0x23
    80000a00:	ba478793          	addi	a5,a5,-1116 # 800235a0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	14490913          	addi	s2,s2,324 # 80010b60 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00023517          	auipc	a0,0x23
    80000ad2:	ad250513          	addi	a0,a0,-1326 # 800235a0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdba61>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	98e080e7          	jalr	-1650(ra) # 8000284c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	0ea080e7          	jalr	234(ra) # 80005fb0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	020080e7          	jalr	32(ra) # 80001eee <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8ee080e7          	jalr	-1810(ra) # 80002824 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	90e080e7          	jalr	-1778(ra) # 8000284c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	054080e7          	jalr	84(ra) # 80005f9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	062080e7          	jalr	98(ra) # 80005fb0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	204080e7          	jalr	516(ra) # 8000315a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8a4080e7          	jalr	-1884(ra) # 80003802 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	84a080e7          	jalr	-1974(ra) # 800047b0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	14a080e7          	jalr	330(ra) # 800060b8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d5a080e7          	jalr	-678(ra) # 80001cd0 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdba57>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdba60>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	f7448493          	addi	s1,s1,-140 # 800117c0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00017a17          	auipc	s4,0x17
    8000186a:	95aa0a13          	addi	s4,s4,-1702 # 800181c0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a848493          	addi	s1,s1,424
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	29850513          	addi	a0,a0,664 # 80010b80 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	29850513          	addi	a0,a0,664 # 80010b98 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	00010497          	auipc	s1,0x10
    80001914:	eb048493          	addi	s1,s1,-336 # 800117c0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00017997          	auipc	s3,0x17
    80001936:	88e98993          	addi	s3,s3,-1906 # 800181c0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a848493          	addi	s1,s1,424
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	21450513          	addi	a0,a0,532 # 80010bb0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1bc70713          	addi	a4,a4,444 # 80010b80 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e5e080e7          	jalr	-418(ra) # 80002864 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	d62080e7          	jalr	-670(ra) # 80003782 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	14a90913          	addi	s2,s2,330 # 80010b80 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	00010497          	auipc	s1,0x10
    80001bc6:	bfe48493          	addi	s1,s1,-1026 # 800117c0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	5f690913          	addi	s2,s2,1526 # 800181c0 <tickslock>
    p->cur_ticks = 0;
    80001bd2:	1804a223          	sw	zero,388(s1)
    p->alarm_on = 0;
    80001bd6:	1804a823          	sw	zero,400(s1)
    acquire(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	ffa080e7          	jalr	-6(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001be4:	4c9c                	lw	a5,24(s1)
    80001be6:	cf81                	beqz	a5,80001bfe <allocproc+0x48>
      release(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	0a0080e7          	jalr	160(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf2:	1a848493          	addi	s1,s1,424
    80001bf6:	fd249ee3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bfa:	4481                	li	s1,0
    80001bfc:	a859                	j	80001c92 <allocproc+0xdc>
  p->pid = allocpid();
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e2c080e7          	jalr	-468(ra) # 80001a2a <allocpid>
    80001c06:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c08:	4785                	li	a5,1
    80001c0a:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	eda080e7          	jalr	-294(ra) # 80000ae6 <kalloc>
    80001c14:	892a                	mv	s2,a0
    80001c16:	eca8                	sd	a0,88(s1)
    80001c18:	c541                	beqz	a0,80001ca0 <allocproc+0xea>
  p->pagetable = proc_pagetable(p);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e54080e7          	jalr	-428(ra) # 80001a70 <proc_pagetable>
    80001c24:	892a                	mv	s2,a0
    80001c26:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c28:	c941                	beqz	a0,80001cb8 <allocproc+0x102>
  memset(&p->context, 0, sizeof(p->context));
    80001c2a:	07000613          	li	a2,112
    80001c2e:	4581                	li	a1,0
    80001c30:	06048513          	addi	a0,s1,96
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	09e080e7          	jalr	158(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c3c:	00000797          	auipc	a5,0x0
    80001c40:	da878793          	addi	a5,a5,-600 # 800019e4 <forkret>
    80001c44:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c46:	60bc                	ld	a5,64(s1)
    80001c48:	6705                	lui	a4,0x1
    80001c4a:	97ba                	add	a5,a5,a4
    80001c4c:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c4e:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c52:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c56:	00007797          	auipc	a5,0x7
    80001c5a:	cba7a783          	lw	a5,-838(a5) # 80008910 <ticks>
    80001c5e:	16f4a623          	sw	a5,364(s1)
  p->priority=0;
    80001c62:	1804aa23          	sw	zero,404(s1)
  p->wait_time=0;
    80001c66:	1804ac23          	sw	zero,408(s1)
  priorities[0][priority_count[0]++] = p;
    80001c6a:	0000f717          	auipc	a4,0xf
    80001c6e:	f1670713          	addi	a4,a4,-234 # 80010b80 <pid_lock>
    80001c72:	43072783          	lw	a5,1072(a4)
    80001c76:	0017869b          	addiw	a3,a5,1
    80001c7a:	42d72823          	sw	a3,1072(a4)
    80001c7e:	02079713          	slli	a4,a5,0x20
    80001c82:	01d75793          	srli	a5,a4,0x1d
    80001c86:	0000f717          	auipc	a4,0xf
    80001c8a:	33a70713          	addi	a4,a4,826 # 80010fc0 <priorities>
    80001c8e:	97ba                	add	a5,a5,a4
    80001c90:	e384                	sd	s1,0(a5)
}
    80001c92:	8526                	mv	a0,s1
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6902                	ld	s2,0(sp)
    80001c9c:	6105                	addi	sp,sp,32
    80001c9e:	8082                	ret
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ebc080e7          	jalr	-324(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fde080e7          	jalr	-34(ra) # 80000c8a <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	bff1                	j	80001c92 <allocproc+0xdc>
    freeproc(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	ea4080e7          	jalr	-348(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	fc6080e7          	jalr	-58(ra) # 80000c8a <release>
    return 0;
    80001ccc:	84ca                	mv	s1,s2
    80001cce:	b7d1                	j	80001c92 <allocproc+0xdc>

0000000080001cd0 <userinit>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	edc080e7          	jalr	-292(ra) # 80001bb6 <allocproc>
    80001ce2:	84aa                	mv	s1,a0
  initproc = p;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	c2a7b223          	sd	a0,-988(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cec:	03400613          	li	a2,52
    80001cf0:	00007597          	auipc	a1,0x7
    80001cf4:	b8058593          	addi	a1,a1,-1152 # 80008870 <initcode>
    80001cf8:	6928                	ld	a0,80(a0)
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	65c080e7          	jalr	1628(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d02:	6785                	lui	a5,0x1
    80001d04:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d06:	6cb8                	ld	a4,88(s1)
    80001d08:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d10:	4641                	li	a2,16
    80001d12:	00006597          	auipc	a1,0x6
    80001d16:	4ee58593          	addi	a1,a1,1262 # 80008200 <digits+0x1c0>
    80001d1a:	15848513          	addi	a0,s1,344
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	0fe080e7          	jalr	254(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d26:	00006517          	auipc	a0,0x6
    80001d2a:	4ea50513          	addi	a0,a0,1258 # 80008210 <digits+0x1d0>
    80001d2e:	00002097          	auipc	ra,0x2
    80001d32:	47e080e7          	jalr	1150(ra) # 800041ac <namei>
    80001d36:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3a:	478d                	li	a5,3
    80001d3c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f4a080e7          	jalr	-182(ra) # 80000c8a <release>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <growproc>:
{
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	c4c080e7          	jalr	-948(ra) # 800019ac <myproc>
    80001d68:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d6a:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d6c:	01204c63          	bgtz	s2,80001d84 <growproc+0x32>
  else if (n < 0)
    80001d70:	02094663          	bltz	s2,80001d9c <growproc+0x4a>
  p->sz = sz;
    80001d74:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d76:	4501                	li	a0,0
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6902                	ld	s2,0(sp)
    80001d80:	6105                	addi	sp,sp,32
    80001d82:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d84:	4691                	li	a3,4
    80001d86:	00b90633          	add	a2,s2,a1
    80001d8a:	6928                	ld	a0,80(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	684080e7          	jalr	1668(ra) # 80001410 <uvmalloc>
    80001d94:	85aa                	mv	a1,a0
    80001d96:	fd79                	bnez	a0,80001d74 <growproc+0x22>
      return -1;
    80001d98:	557d                	li	a0,-1
    80001d9a:	bff9                	j	80001d78 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9c:	00b90633          	add	a2,s2,a1
    80001da0:	6928                	ld	a0,80(a0)
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	626080e7          	jalr	1574(ra) # 800013c8 <uvmdealloc>
    80001daa:	85aa                	mv	a1,a0
    80001dac:	b7e1                	j	80001d74 <growproc+0x22>

0000000080001dae <fork>:
{
    80001dae:	7139                	addi	sp,sp,-64
    80001db0:	fc06                	sd	ra,56(sp)
    80001db2:	f822                	sd	s0,48(sp)
    80001db4:	f426                	sd	s1,40(sp)
    80001db6:	f04a                	sd	s2,32(sp)
    80001db8:	ec4e                	sd	s3,24(sp)
    80001dba:	e852                	sd	s4,16(sp)
    80001dbc:	e456                	sd	s5,8(sp)
    80001dbe:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	bec080e7          	jalr	-1044(ra) # 800019ac <myproc>
    80001dc8:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	dec080e7          	jalr	-532(ra) # 80001bb6 <allocproc>
    80001dd2:	10050c63          	beqz	a0,80001eea <fork+0x13c>
    80001dd6:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd8:	048ab603          	ld	a2,72(s5)
    80001ddc:	692c                	ld	a1,80(a0)
    80001dde:	050ab503          	ld	a0,80(s5)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	786080e7          	jalr	1926(ra) # 80001568 <uvmcopy>
    80001dea:	04054863          	bltz	a0,80001e3a <fork+0x8c>
  np->sz = p->sz;
    80001dee:	048ab783          	ld	a5,72(s5)
    80001df2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df6:	058ab683          	ld	a3,88(s5)
    80001dfa:	87b6                	mv	a5,a3
    80001dfc:	058a3703          	ld	a4,88(s4)
    80001e00:	12068693          	addi	a3,a3,288
    80001e04:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e08:	6788                	ld	a0,8(a5)
    80001e0a:	6b8c                	ld	a1,16(a5)
    80001e0c:	6f90                	ld	a2,24(a5)
    80001e0e:	01073023          	sd	a6,0(a4)
    80001e12:	e708                	sd	a0,8(a4)
    80001e14:	eb0c                	sd	a1,16(a4)
    80001e16:	ef10                	sd	a2,24(a4)
    80001e18:	02078793          	addi	a5,a5,32
    80001e1c:	02070713          	addi	a4,a4,32
    80001e20:	fed792e3          	bne	a5,a3,80001e04 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e24:	058a3783          	ld	a5,88(s4)
    80001e28:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e2c:	0d0a8493          	addi	s1,s5,208
    80001e30:	0d0a0913          	addi	s2,s4,208
    80001e34:	150a8993          	addi	s3,s5,336
    80001e38:	a00d                	j	80001e5a <fork+0xac>
    freeproc(np);
    80001e3a:	8552                	mv	a0,s4
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	d22080e7          	jalr	-734(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e44:	8552                	mv	a0,s4
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
    return -1;
    80001e4e:	597d                	li	s2,-1
    80001e50:	a059                	j	80001ed6 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e52:	04a1                	addi	s1,s1,8
    80001e54:	0921                	addi	s2,s2,8
    80001e56:	01348b63          	beq	s1,s3,80001e6c <fork+0xbe>
    if (p->ofile[i])
    80001e5a:	6088                	ld	a0,0(s1)
    80001e5c:	d97d                	beqz	a0,80001e52 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5e:	00003097          	auipc	ra,0x3
    80001e62:	9e4080e7          	jalr	-1564(ra) # 80004842 <filedup>
    80001e66:	00a93023          	sd	a0,0(s2)
    80001e6a:	b7e5                	j	80001e52 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e6c:	150ab503          	ld	a0,336(s5)
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	b52080e7          	jalr	-1198(ra) # 800039c2 <idup>
    80001e78:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7c:	4641                	li	a2,16
    80001e7e:	158a8593          	addi	a1,s5,344
    80001e82:	158a0513          	addi	a0,s4,344
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	f96080e7          	jalr	-106(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e8e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e92:	8552                	mv	a0,s4
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	df6080e7          	jalr	-522(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e9c:	0000f497          	auipc	s1,0xf
    80001ea0:	cfc48493          	addi	s1,s1,-772 # 80010b98 <wait_lock>
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d30080e7          	jalr	-720(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001eae:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	dd6080e7          	jalr	-554(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d18080e7          	jalr	-744(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ec6:	478d                	li	a5,3
    80001ec8:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ecc:	8552                	mv	a0,s4
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dbc080e7          	jalr	-580(ra) # 80000c8a <release>
}
    80001ed6:	854a                	mv	a0,s2
    80001ed8:	70e2                	ld	ra,56(sp)
    80001eda:	7442                	ld	s0,48(sp)
    80001edc:	74a2                	ld	s1,40(sp)
    80001ede:	7902                	ld	s2,32(sp)
    80001ee0:	69e2                	ld	s3,24(sp)
    80001ee2:	6a42                	ld	s4,16(sp)
    80001ee4:	6aa2                	ld	s5,8(sp)
    80001ee6:	6121                	addi	sp,sp,64
    80001ee8:	8082                	ret
    return -1;
    80001eea:	597d                	li	s2,-1
    80001eec:	b7ed                	j	80001ed6 <fork+0x128>

0000000080001eee <scheduler>:
{
    80001eee:	7139                	addi	sp,sp,-64
    80001ef0:	fc06                	sd	ra,56(sp)
    80001ef2:	f822                	sd	s0,48(sp)
    80001ef4:	f426                	sd	s1,40(sp)
    80001ef6:	f04a                	sd	s2,32(sp)
    80001ef8:	ec4e                	sd	s3,24(sp)
    80001efa:	e852                	sd	s4,16(sp)
    80001efc:	e456                	sd	s5,8(sp)
    80001efe:	e05a                	sd	s6,0(sp)
    80001f00:	0080                	addi	s0,sp,64
    80001f02:	8792                	mv	a5,tp
  int id = r_tp();
    80001f04:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f06:	00779a93          	slli	s5,a5,0x7
    80001f0a:	0000f717          	auipc	a4,0xf
    80001f0e:	c7670713          	addi	a4,a4,-906 # 80010b80 <pid_lock>
    80001f12:	9756                	add	a4,a4,s5
    80001f14:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f18:	0000f717          	auipc	a4,0xf
    80001f1c:	ca070713          	addi	a4,a4,-864 # 80010bb8 <cpus+0x8>
    80001f20:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f22:	498d                	li	s3,3
        p->state = RUNNING;
    80001f24:	4b11                	li	s6,4
        c->proc = p;
    80001f26:	079e                	slli	a5,a5,0x7
    80001f28:	0000fa17          	auipc	s4,0xf
    80001f2c:	c58a0a13          	addi	s4,s4,-936 # 80010b80 <pid_lock>
    80001f30:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f32:	00016917          	auipc	s2,0x16
    80001f36:	28e90913          	addi	s2,s2,654 # 800181c0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f42:	10079073          	csrw	sstatus,a5
    80001f46:	00010497          	auipc	s1,0x10
    80001f4a:	87a48493          	addi	s1,s1,-1926 # 800117c0 <proc>
    80001f4e:	a811                	j	80001f62 <scheduler+0x74>
      release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d38080e7          	jalr	-712(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f5a:	1a848493          	addi	s1,s1,424
    80001f5e:	fd248ee3          	beq	s1,s2,80001f3a <scheduler+0x4c>
      acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c72080e7          	jalr	-910(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f6c:	4c9c                	lw	a5,24(s1)
    80001f6e:	ff3791e3          	bne	a5,s3,80001f50 <scheduler+0x62>
        p->state = RUNNING;
    80001f72:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f76:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f7a:	06048593          	addi	a1,s1,96
    80001f7e:	8556                	mv	a0,s5
    80001f80:	00001097          	auipc	ra,0x1
    80001f84:	83a080e7          	jalr	-1990(ra) # 800027ba <swtch>
        c->proc = 0;
    80001f88:	020a3823          	sd	zero,48(s4)
    80001f8c:	b7d1                	j	80001f50 <scheduler+0x62>

0000000080001f8e <sched>:
{
    80001f8e:	7179                	addi	sp,sp,-48
    80001f90:	f406                	sd	ra,40(sp)
    80001f92:	f022                	sd	s0,32(sp)
    80001f94:	ec26                	sd	s1,24(sp)
    80001f96:	e84a                	sd	s2,16(sp)
    80001f98:	e44e                	sd	s3,8(sp)
    80001f9a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	a10080e7          	jalr	-1520(ra) # 800019ac <myproc>
    80001fa4:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	bb6080e7          	jalr	-1098(ra) # 80000b5c <holding>
    80001fae:	c93d                	beqz	a0,80002024 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb0:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	0000f717          	auipc	a4,0xf
    80001fba:	bca70713          	addi	a4,a4,-1078 # 80010b80 <pid_lock>
    80001fbe:	97ba                	add	a5,a5,a4
    80001fc0:	0a87a703          	lw	a4,168(a5)
    80001fc4:	4785                	li	a5,1
    80001fc6:	06f71763          	bne	a4,a5,80002034 <sched+0xa6>
  if (p->state == RUNNING)
    80001fca:	4c98                	lw	a4,24(s1)
    80001fcc:	4791                	li	a5,4
    80001fce:	06f70b63          	beq	a4,a5,80002044 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fd6:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fd8:	efb5                	bnez	a5,80002054 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fda:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fdc:	0000f917          	auipc	s2,0xf
    80001fe0:	ba490913          	addi	s2,s2,-1116 # 80010b80 <pid_lock>
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	97ca                	add	a5,a5,s2
    80001fea:	0ac7a983          	lw	s3,172(a5)
    80001fee:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	0000f597          	auipc	a1,0xf
    80001ff8:	bc458593          	addi	a1,a1,-1084 # 80010bb8 <cpus+0x8>
    80001ffc:	95be                	add	a1,a1,a5
    80001ffe:	06048513          	addi	a0,s1,96
    80002002:	00000097          	auipc	ra,0x0
    80002006:	7b8080e7          	jalr	1976(ra) # 800027ba <swtch>
    8000200a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	993e                	add	s2,s2,a5
    80002012:	0b392623          	sw	s3,172(s2)
}
    80002016:	70a2                	ld	ra,40(sp)
    80002018:	7402                	ld	s0,32(sp)
    8000201a:	64e2                	ld	s1,24(sp)
    8000201c:	6942                	ld	s2,16(sp)
    8000201e:	69a2                	ld	s3,8(sp)
    80002020:	6145                	addi	sp,sp,48
    80002022:	8082                	ret
    panic("sched p->lock");
    80002024:	00006517          	auipc	a0,0x6
    80002028:	1f450513          	addi	a0,a0,500 # 80008218 <digits+0x1d8>
    8000202c:	ffffe097          	auipc	ra,0xffffe
    80002030:	514080e7          	jalr	1300(ra) # 80000540 <panic>
    panic("sched locks");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	1f450513          	addi	a0,a0,500 # 80008228 <digits+0x1e8>
    8000203c:	ffffe097          	auipc	ra,0xffffe
    80002040:	504080e7          	jalr	1284(ra) # 80000540 <panic>
    panic("sched running");
    80002044:	00006517          	auipc	a0,0x6
    80002048:	1f450513          	addi	a0,a0,500 # 80008238 <digits+0x1f8>
    8000204c:	ffffe097          	auipc	ra,0xffffe
    80002050:	4f4080e7          	jalr	1268(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	1f450513          	addi	a0,a0,500 # 80008248 <digits+0x208>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>

0000000080002064 <yield>:
{
    80002064:	1101                	addi	sp,sp,-32
    80002066:	ec06                	sd	ra,24(sp)
    80002068:	e822                	sd	s0,16(sp)
    8000206a:	e426                	sd	s1,8(sp)
    8000206c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	93e080e7          	jalr	-1730(ra) # 800019ac <myproc>
    80002076:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	b5e080e7          	jalr	-1186(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002080:	478d                	li	a5,3
    80002082:	cc9c                	sw	a5,24(s1)
  sched();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	f0a080e7          	jalr	-246(ra) # 80001f8e <sched>
  release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	bfc080e7          	jalr	-1028(ra) # 80000c8a <release>
}
    80002096:	60e2                	ld	ra,24(sp)
    80002098:	6442                	ld	s0,16(sp)
    8000209a:	64a2                	ld	s1,8(sp)
    8000209c:	6105                	addi	sp,sp,32
    8000209e:	8082                	ret

00000000800020a0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020a0:	7179                	addi	sp,sp,-48
    800020a2:	f406                	sd	ra,40(sp)
    800020a4:	f022                	sd	s0,32(sp)
    800020a6:	ec26                	sd	s1,24(sp)
    800020a8:	e84a                	sd	s2,16(sp)
    800020aa:	e44e                	sd	s3,8(sp)
    800020ac:	1800                	addi	s0,sp,48
    800020ae:	89aa                	mv	s3,a0
    800020b0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	8fa080e7          	jalr	-1798(ra) # 800019ac <myproc>
    800020ba:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
  release(lk);
    800020c4:	854a                	mv	a0,s2
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bc4080e7          	jalr	-1084(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020ce:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d2:	4789                	li	a5,2
    800020d4:	cc9c                	sw	a5,24(s1)

  sched();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	eb8080e7          	jalr	-328(ra) # 80001f8e <sched>

  // Tidy up.
  p->chan = 0;
    800020de:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  acquire(lk);
    800020ec:	854a                	mv	a0,s2
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	ae8080e7          	jalr	-1304(ra) # 80000bd6 <acquire>
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret

0000000080002104 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002104:	7139                	addi	sp,sp,-64
    80002106:	fc06                	sd	ra,56(sp)
    80002108:	f822                	sd	s0,48(sp)
    8000210a:	f426                	sd	s1,40(sp)
    8000210c:	f04a                	sd	s2,32(sp)
    8000210e:	ec4e                	sd	s3,24(sp)
    80002110:	e852                	sd	s4,16(sp)
    80002112:	e456                	sd	s5,8(sp)
    80002114:	0080                	addi	s0,sp,64
    80002116:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002118:	0000f497          	auipc	s1,0xf
    8000211c:	6a848493          	addi	s1,s1,1704 # 800117c0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002120:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002122:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002124:	00016917          	auipc	s2,0x16
    80002128:	09c90913          	addi	s2,s2,156 # 800181c0 <tickslock>
    8000212c:	a811                	j	80002140 <wakeup+0x3c>
      }
      release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b5a080e7          	jalr	-1190(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002138:	1a848493          	addi	s1,s1,424
    8000213c:	03248663          	beq	s1,s2,80002168 <wakeup+0x64>
    if (p != myproc())
    80002140:	00000097          	auipc	ra,0x0
    80002144:	86c080e7          	jalr	-1940(ra) # 800019ac <myproc>
    80002148:	fea488e3          	beq	s1,a0,80002138 <wakeup+0x34>
      acquire(&p->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	a88080e7          	jalr	-1400(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002156:	4c9c                	lw	a5,24(s1)
    80002158:	fd379be3          	bne	a5,s3,8000212e <wakeup+0x2a>
    8000215c:	709c                	ld	a5,32(s1)
    8000215e:	fd4798e3          	bne	a5,s4,8000212e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002162:	0154ac23          	sw	s5,24(s1)
    80002166:	b7e1                	j	8000212e <wakeup+0x2a>
    }
  }
}
    80002168:	70e2                	ld	ra,56(sp)
    8000216a:	7442                	ld	s0,48(sp)
    8000216c:	74a2                	ld	s1,40(sp)
    8000216e:	7902                	ld	s2,32(sp)
    80002170:	69e2                	ld	s3,24(sp)
    80002172:	6a42                	ld	s4,16(sp)
    80002174:	6aa2                	ld	s5,8(sp)
    80002176:	6121                	addi	sp,sp,64
    80002178:	8082                	ret

000000008000217a <reparent>:
{
    8000217a:	7179                	addi	sp,sp,-48
    8000217c:	f406                	sd	ra,40(sp)
    8000217e:	f022                	sd	s0,32(sp)
    80002180:	ec26                	sd	s1,24(sp)
    80002182:	e84a                	sd	s2,16(sp)
    80002184:	e44e                	sd	s3,8(sp)
    80002186:	e052                	sd	s4,0(sp)
    80002188:	1800                	addi	s0,sp,48
    8000218a:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000218c:	0000f497          	auipc	s1,0xf
    80002190:	63448493          	addi	s1,s1,1588 # 800117c0 <proc>
      pp->parent = initproc;
    80002194:	00006a17          	auipc	s4,0x6
    80002198:	774a0a13          	addi	s4,s4,1908 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000219c:	00016997          	auipc	s3,0x16
    800021a0:	02498993          	addi	s3,s3,36 # 800181c0 <tickslock>
    800021a4:	a029                	j	800021ae <reparent+0x34>
    800021a6:	1a848493          	addi	s1,s1,424
    800021aa:	01348d63          	beq	s1,s3,800021c4 <reparent+0x4a>
    if (pp->parent == p)
    800021ae:	7c9c                	ld	a5,56(s1)
    800021b0:	ff279be3          	bne	a5,s2,800021a6 <reparent+0x2c>
      pp->parent = initproc;
    800021b4:	000a3503          	ld	a0,0(s4)
    800021b8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	f4a080e7          	jalr	-182(ra) # 80002104 <wakeup>
    800021c2:	b7d5                	j	800021a6 <reparent+0x2c>
}
    800021c4:	70a2                	ld	ra,40(sp)
    800021c6:	7402                	ld	s0,32(sp)
    800021c8:	64e2                	ld	s1,24(sp)
    800021ca:	6942                	ld	s2,16(sp)
    800021cc:	69a2                	ld	s3,8(sp)
    800021ce:	6a02                	ld	s4,0(sp)
    800021d0:	6145                	addi	sp,sp,48
    800021d2:	8082                	ret

00000000800021d4 <exit>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	7c6080e7          	jalr	1990(ra) # 800019ac <myproc>
    800021ee:	89aa                	mv	s3,a0
  if (p == initproc)
    800021f0:	00006797          	auipc	a5,0x6
    800021f4:	7187b783          	ld	a5,1816(a5) # 80008908 <initproc>
    800021f8:	0d050493          	addi	s1,a0,208
    800021fc:	15050913          	addi	s2,a0,336
    80002200:	02a79363          	bne	a5,a0,80002226 <exit+0x52>
    panic("init exiting");
    80002204:	00006517          	auipc	a0,0x6
    80002208:	05c50513          	addi	a0,a0,92 # 80008260 <digits+0x220>
    8000220c:	ffffe097          	auipc	ra,0xffffe
    80002210:	334080e7          	jalr	820(ra) # 80000540 <panic>
      fileclose(f);
    80002214:	00002097          	auipc	ra,0x2
    80002218:	680080e7          	jalr	1664(ra) # 80004894 <fileclose>
      p->ofile[fd] = 0;
    8000221c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002220:	04a1                	addi	s1,s1,8
    80002222:	01248563          	beq	s1,s2,8000222c <exit+0x58>
    if (p->ofile[fd])
    80002226:	6088                	ld	a0,0(s1)
    80002228:	f575                	bnez	a0,80002214 <exit+0x40>
    8000222a:	bfdd                	j	80002220 <exit+0x4c>
  begin_op();
    8000222c:	00002097          	auipc	ra,0x2
    80002230:	1a0080e7          	jalr	416(ra) # 800043cc <begin_op>
  iput(p->cwd);
    80002234:	1509b503          	ld	a0,336(s3)
    80002238:	00002097          	auipc	ra,0x2
    8000223c:	982080e7          	jalr	-1662(ra) # 80003bba <iput>
  end_op();
    80002240:	00002097          	auipc	ra,0x2
    80002244:	20a080e7          	jalr	522(ra) # 8000444a <end_op>
  p->cwd = 0;
    80002248:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000224c:	0000f497          	auipc	s1,0xf
    80002250:	94c48493          	addi	s1,s1,-1716 # 80010b98 <wait_lock>
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	980080e7          	jalr	-1664(ra) # 80000bd6 <acquire>
  reparent(p);
    8000225e:	854e                	mv	a0,s3
    80002260:	00000097          	auipc	ra,0x0
    80002264:	f1a080e7          	jalr	-230(ra) # 8000217a <reparent>
  wakeup(p->parent);
    80002268:	0389b503          	ld	a0,56(s3)
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	e98080e7          	jalr	-360(ra) # 80002104 <wakeup>
  acquire(&p->lock);
    80002274:	854e                	mv	a0,s3
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	960080e7          	jalr	-1696(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000227e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002282:	4795                	li	a5,5
    80002284:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002288:	00006797          	auipc	a5,0x6
    8000228c:	6887a783          	lw	a5,1672(a5) # 80008910 <ticks>
    80002290:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	9f4080e7          	jalr	-1548(ra) # 80000c8a <release>
  sched();
    8000229e:	00000097          	auipc	ra,0x0
    800022a2:	cf0080e7          	jalr	-784(ra) # 80001f8e <sched>
  panic("zombie exit");
    800022a6:	00006517          	auipc	a0,0x6
    800022aa:	fca50513          	addi	a0,a0,-54 # 80008270 <digits+0x230>
    800022ae:	ffffe097          	auipc	ra,0xffffe
    800022b2:	292080e7          	jalr	658(ra) # 80000540 <panic>

00000000800022b6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	1800                	addi	s0,sp,48
    800022c4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022c6:	0000f497          	auipc	s1,0xf
    800022ca:	4fa48493          	addi	s1,s1,1274 # 800117c0 <proc>
    800022ce:	00016997          	auipc	s3,0x16
    800022d2:	ef298993          	addi	s3,s3,-270 # 800181c0 <tickslock>
  {
    acquire(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	8fe080e7          	jalr	-1794(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022e0:	589c                	lw	a5,48(s1)
    800022e2:	01278d63          	beq	a5,s2,800022fc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9a2080e7          	jalr	-1630(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022f0:	1a848493          	addi	s1,s1,424
    800022f4:	ff3491e3          	bne	s1,s3,800022d6 <kill+0x20>
  }
  return -1;
    800022f8:	557d                	li	a0,-1
    800022fa:	a829                	j	80002314 <kill+0x5e>
      p->killed = 1;
    800022fc:	4785                	li	a5,1
    800022fe:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002300:	4c98                	lw	a4,24(s1)
    80002302:	4789                	li	a5,2
    80002304:	00f70f63          	beq	a4,a5,80002322 <kill+0x6c>
      release(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
      return 0;
    80002312:	4501                	li	a0,0
}
    80002314:	70a2                	ld	ra,40(sp)
    80002316:	7402                	ld	s0,32(sp)
    80002318:	64e2                	ld	s1,24(sp)
    8000231a:	6942                	ld	s2,16(sp)
    8000231c:	69a2                	ld	s3,8(sp)
    8000231e:	6145                	addi	sp,sp,48
    80002320:	8082                	ret
        p->state = RUNNABLE;
    80002322:	478d                	li	a5,3
    80002324:	cc9c                	sw	a5,24(s1)
    80002326:	b7cd                	j	80002308 <kill+0x52>

0000000080002328 <setkilled>:

void setkilled(struct proc *p)
{
    80002328:	1101                	addi	sp,sp,-32
    8000232a:	ec06                	sd	ra,24(sp)
    8000232c:	e822                	sd	s0,16(sp)
    8000232e:	e426                	sd	s1,8(sp)
    80002330:	1000                	addi	s0,sp,32
    80002332:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	8a2080e7          	jalr	-1886(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000233c:	4785                	li	a5,1
    8000233e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	948080e7          	jalr	-1720(ra) # 80000c8a <release>
}
    8000234a:	60e2                	ld	ra,24(sp)
    8000234c:	6442                	ld	s0,16(sp)
    8000234e:	64a2                	ld	s1,8(sp)
    80002350:	6105                	addi	sp,sp,32
    80002352:	8082                	ret

0000000080002354 <killed>:

int killed(struct proc *p)
{
    80002354:	1101                	addi	sp,sp,-32
    80002356:	ec06                	sd	ra,24(sp)
    80002358:	e822                	sd	s0,16(sp)
    8000235a:	e426                	sd	s1,8(sp)
    8000235c:	e04a                	sd	s2,0(sp)
    8000235e:	1000                	addi	s0,sp,32
    80002360:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000236a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	91a080e7          	jalr	-1766(ra) # 80000c8a <release>
  return k;
}
    80002378:	854a                	mv	a0,s2
    8000237a:	60e2                	ld	ra,24(sp)
    8000237c:	6442                	ld	s0,16(sp)
    8000237e:	64a2                	ld	s1,8(sp)
    80002380:	6902                	ld	s2,0(sp)
    80002382:	6105                	addi	sp,sp,32
    80002384:	8082                	ret

0000000080002386 <wait>:
{
    80002386:	715d                	addi	sp,sp,-80
    80002388:	e486                	sd	ra,72(sp)
    8000238a:	e0a2                	sd	s0,64(sp)
    8000238c:	fc26                	sd	s1,56(sp)
    8000238e:	f84a                	sd	s2,48(sp)
    80002390:	f44e                	sd	s3,40(sp)
    80002392:	f052                	sd	s4,32(sp)
    80002394:	ec56                	sd	s5,24(sp)
    80002396:	e85a                	sd	s6,16(sp)
    80002398:	e45e                	sd	s7,8(sp)
    8000239a:	e062                	sd	s8,0(sp)
    8000239c:	0880                	addi	s0,sp,80
    8000239e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	60c080e7          	jalr	1548(ra) # 800019ac <myproc>
    800023a8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023aa:	0000e517          	auipc	a0,0xe
    800023ae:	7ee50513          	addi	a0,a0,2030 # 80010b98 <wait_lock>
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	824080e7          	jalr	-2012(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023ba:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023bc:	4a15                	li	s4,5
        havekids = 1;
    800023be:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023c0:	00016997          	auipc	s3,0x16
    800023c4:	e0098993          	addi	s3,s3,-512 # 800181c0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023c8:	0000ec17          	auipc	s8,0xe
    800023cc:	7d0c0c13          	addi	s8,s8,2000 # 80010b98 <wait_lock>
    havekids = 0;
    800023d0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023d2:	0000f497          	auipc	s1,0xf
    800023d6:	3ee48493          	addi	s1,s1,1006 # 800117c0 <proc>
    800023da:	a0bd                	j	80002448 <wait+0xc2>
          pid = pp->pid;
    800023dc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023e0:	000b0e63          	beqz	s6,800023fc <wait+0x76>
    800023e4:	4691                	li	a3,4
    800023e6:	02c48613          	addi	a2,s1,44
    800023ea:	85da                	mv	a1,s6
    800023ec:	05093503          	ld	a0,80(s2)
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	27c080e7          	jalr	636(ra) # 8000166c <copyout>
    800023f8:	02054563          	bltz	a0,80002422 <wait+0x9c>
          freeproc(pp);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	760080e7          	jalr	1888(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
          release(&wait_lock);
    80002410:	0000e517          	auipc	a0,0xe
    80002414:	78850513          	addi	a0,a0,1928 # 80010b98 <wait_lock>
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	872080e7          	jalr	-1934(ra) # 80000c8a <release>
          return pid;
    80002420:	a0b5                	j	8000248c <wait+0x106>
            release(&pp->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	866080e7          	jalr	-1946(ra) # 80000c8a <release>
            release(&wait_lock);
    8000242c:	0000e517          	auipc	a0,0xe
    80002430:	76c50513          	addi	a0,a0,1900 # 80010b98 <wait_lock>
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	856080e7          	jalr	-1962(ra) # 80000c8a <release>
            return -1;
    8000243c:	59fd                	li	s3,-1
    8000243e:	a0b9                	j	8000248c <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002440:	1a848493          	addi	s1,s1,424
    80002444:	03348463          	beq	s1,s3,8000246c <wait+0xe6>
      if (pp->parent == p)
    80002448:	7c9c                	ld	a5,56(s1)
    8000244a:	ff279be3          	bne	a5,s2,80002440 <wait+0xba>
        acquire(&pp->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	786080e7          	jalr	1926(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002458:	4c9c                	lw	a5,24(s1)
    8000245a:	f94781e3          	beq	a5,s4,800023dc <wait+0x56>
        release(&pp->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	82a080e7          	jalr	-2006(ra) # 80000c8a <release>
        havekids = 1;
    80002468:	8756                	mv	a4,s5
    8000246a:	bfd9                	j	80002440 <wait+0xba>
    if (!havekids || killed(p))
    8000246c:	c719                	beqz	a4,8000247a <wait+0xf4>
    8000246e:	854a                	mv	a0,s2
    80002470:	00000097          	auipc	ra,0x0
    80002474:	ee4080e7          	jalr	-284(ra) # 80002354 <killed>
    80002478:	c51d                	beqz	a0,800024a6 <wait+0x120>
      release(&wait_lock);
    8000247a:	0000e517          	auipc	a0,0xe
    8000247e:	71e50513          	addi	a0,a0,1822 # 80010b98 <wait_lock>
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	808080e7          	jalr	-2040(ra) # 80000c8a <release>
      return -1;
    8000248a:	59fd                	li	s3,-1
}
    8000248c:	854e                	mv	a0,s3
    8000248e:	60a6                	ld	ra,72(sp)
    80002490:	6406                	ld	s0,64(sp)
    80002492:	74e2                	ld	s1,56(sp)
    80002494:	7942                	ld	s2,48(sp)
    80002496:	79a2                	ld	s3,40(sp)
    80002498:	7a02                	ld	s4,32(sp)
    8000249a:	6ae2                	ld	s5,24(sp)
    8000249c:	6b42                	ld	s6,16(sp)
    8000249e:	6ba2                	ld	s7,8(sp)
    800024a0:	6c02                	ld	s8,0(sp)
    800024a2:	6161                	addi	sp,sp,80
    800024a4:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024a6:	85e2                	mv	a1,s8
    800024a8:	854a                	mv	a0,s2
    800024aa:	00000097          	auipc	ra,0x0
    800024ae:	bf6080e7          	jalr	-1034(ra) # 800020a0 <sleep>
    havekids = 0;
    800024b2:	bf39                	j	800023d0 <wait+0x4a>

00000000800024b4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024b4:	7179                	addi	sp,sp,-48
    800024b6:	f406                	sd	ra,40(sp)
    800024b8:	f022                	sd	s0,32(sp)
    800024ba:	ec26                	sd	s1,24(sp)
    800024bc:	e84a                	sd	s2,16(sp)
    800024be:	e44e                	sd	s3,8(sp)
    800024c0:	e052                	sd	s4,0(sp)
    800024c2:	1800                	addi	s0,sp,48
    800024c4:	84aa                	mv	s1,a0
    800024c6:	892e                	mv	s2,a1
    800024c8:	89b2                	mv	s3,a2
    800024ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	4e0080e7          	jalr	1248(ra) # 800019ac <myproc>
  if (user_dst)
    800024d4:	c08d                	beqz	s1,800024f6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024d6:	86d2                	mv	a3,s4
    800024d8:	864e                	mv	a2,s3
    800024da:	85ca                	mv	a1,s2
    800024dc:	6928                	ld	a0,80(a0)
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	18e080e7          	jalr	398(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e6:	70a2                	ld	ra,40(sp)
    800024e8:	7402                	ld	s0,32(sp)
    800024ea:	64e2                	ld	s1,24(sp)
    800024ec:	6942                	ld	s2,16(sp)
    800024ee:	69a2                	ld	s3,8(sp)
    800024f0:	6a02                	ld	s4,0(sp)
    800024f2:	6145                	addi	sp,sp,48
    800024f4:	8082                	ret
    memmove((char *)dst, src, len);
    800024f6:	000a061b          	sext.w	a2,s4
    800024fa:	85ce                	mv	a1,s3
    800024fc:	854a                	mv	a0,s2
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	830080e7          	jalr	-2000(ra) # 80000d2e <memmove>
    return 0;
    80002506:	8526                	mv	a0,s1
    80002508:	bff9                	j	800024e6 <either_copyout+0x32>

000000008000250a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000250a:	7179                	addi	sp,sp,-48
    8000250c:	f406                	sd	ra,40(sp)
    8000250e:	f022                	sd	s0,32(sp)
    80002510:	ec26                	sd	s1,24(sp)
    80002512:	e84a                	sd	s2,16(sp)
    80002514:	e44e                	sd	s3,8(sp)
    80002516:	e052                	sd	s4,0(sp)
    80002518:	1800                	addi	s0,sp,48
    8000251a:	892a                	mv	s2,a0
    8000251c:	84ae                	mv	s1,a1
    8000251e:	89b2                	mv	s3,a2
    80002520:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	48a080e7          	jalr	1162(ra) # 800019ac <myproc>
  if (user_src)
    8000252a:	c08d                	beqz	s1,8000254c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000252c:	86d2                	mv	a3,s4
    8000252e:	864e                	mv	a2,s3
    80002530:	85ca                	mv	a1,s2
    80002532:	6928                	ld	a0,80(a0)
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	1c4080e7          	jalr	452(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000253c:	70a2                	ld	ra,40(sp)
    8000253e:	7402                	ld	s0,32(sp)
    80002540:	64e2                	ld	s1,24(sp)
    80002542:	6942                	ld	s2,16(sp)
    80002544:	69a2                	ld	s3,8(sp)
    80002546:	6a02                	ld	s4,0(sp)
    80002548:	6145                	addi	sp,sp,48
    8000254a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000254c:	000a061b          	sext.w	a2,s4
    80002550:	85ce                	mv	a1,s3
    80002552:	854a                	mv	a0,s2
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	7da080e7          	jalr	2010(ra) # 80000d2e <memmove>
    return 0;
    8000255c:	8526                	mv	a0,s1
    8000255e:	bff9                	j	8000253c <either_copyin+0x32>

0000000080002560 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002560:	715d                	addi	sp,sp,-80
    80002562:	e486                	sd	ra,72(sp)
    80002564:	e0a2                	sd	s0,64(sp)
    80002566:	fc26                	sd	s1,56(sp)
    80002568:	f84a                	sd	s2,48(sp)
    8000256a:	f44e                	sd	s3,40(sp)
    8000256c:	f052                	sd	s4,32(sp)
    8000256e:	ec56                	sd	s5,24(sp)
    80002570:	e85a                	sd	s6,16(sp)
    80002572:	e45e                	sd	s7,8(sp)
    80002574:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002576:	00006517          	auipc	a0,0x6
    8000257a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	00c080e7          	jalr	12(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002586:	0000f497          	auipc	s1,0xf
    8000258a:	39248493          	addi	s1,s1,914 # 80011918 <proc+0x158>
    8000258e:	00016917          	auipc	s2,0x16
    80002592:	d8a90913          	addi	s2,s2,-630 # 80018318 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002596:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002598:	00006997          	auipc	s3,0x6
    8000259c:	ce898993          	addi	s3,s3,-792 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025a0:	00006a97          	auipc	s5,0x6
    800025a4:	ce8a8a93          	addi	s5,s5,-792 # 80008288 <digits+0x248>
    printf("\n");
    800025a8:	00006a17          	auipc	s4,0x6
    800025ac:	b20a0a13          	addi	s4,s4,-1248 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b0:	00006b97          	auipc	s7,0x6
    800025b4:	d18b8b93          	addi	s7,s7,-744 # 800082c8 <states.0>
    800025b8:	a00d                	j	800025da <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ba:	ed86a583          	lw	a1,-296(a3)
    800025be:	8556                	mv	a0,s5
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	fca080e7          	jalr	-54(ra) # 8000058a <printf>
    printf("\n");
    800025c8:	8552                	mv	a0,s4
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fc0080e7          	jalr	-64(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025d2:	1a848493          	addi	s1,s1,424
    800025d6:	03248263          	beq	s1,s2,800025fa <procdump+0x9a>
    if (p->state == UNUSED)
    800025da:	86a6                	mv	a3,s1
    800025dc:	ec04a783          	lw	a5,-320(s1)
    800025e0:	dbed                	beqz	a5,800025d2 <procdump+0x72>
      state = "???";
    800025e2:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	fcfb6be3          	bltu	s6,a5,800025ba <procdump+0x5a>
    800025e8:	02079713          	slli	a4,a5,0x20
    800025ec:	01d75793          	srli	a5,a4,0x1d
    800025f0:	97de                	add	a5,a5,s7
    800025f2:	6390                	ld	a2,0(a5)
    800025f4:	f279                	bnez	a2,800025ba <procdump+0x5a>
      state = "???";
    800025f6:	864e                	mv	a2,s3
    800025f8:	b7c9                	j	800025ba <procdump+0x5a>
  }
}
    800025fa:	60a6                	ld	ra,72(sp)
    800025fc:	6406                	ld	s0,64(sp)
    800025fe:	74e2                	ld	s1,56(sp)
    80002600:	7942                	ld	s2,48(sp)
    80002602:	79a2                	ld	s3,40(sp)
    80002604:	7a02                	ld	s4,32(sp)
    80002606:	6ae2                	ld	s5,24(sp)
    80002608:	6b42                	ld	s6,16(sp)
    8000260a:	6ba2                	ld	s7,8(sp)
    8000260c:	6161                	addi	sp,sp,80
    8000260e:	8082                	ret

0000000080002610 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002610:	711d                	addi	sp,sp,-96
    80002612:	ec86                	sd	ra,88(sp)
    80002614:	e8a2                	sd	s0,80(sp)
    80002616:	e4a6                	sd	s1,72(sp)
    80002618:	e0ca                	sd	s2,64(sp)
    8000261a:	fc4e                	sd	s3,56(sp)
    8000261c:	f852                	sd	s4,48(sp)
    8000261e:	f456                	sd	s5,40(sp)
    80002620:	f05a                	sd	s6,32(sp)
    80002622:	ec5e                	sd	s7,24(sp)
    80002624:	e862                	sd	s8,16(sp)
    80002626:	e466                	sd	s9,8(sp)
    80002628:	e06a                	sd	s10,0(sp)
    8000262a:	1080                	addi	s0,sp,96
    8000262c:	8b2a                	mv	s6,a0
    8000262e:	8bae                	mv	s7,a1
    80002630:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	37a080e7          	jalr	890(ra) # 800019ac <myproc>
    8000263a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000263c:	0000e517          	auipc	a0,0xe
    80002640:	55c50513          	addi	a0,a0,1372 # 80010b98 <wait_lock>
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	592080e7          	jalr	1426(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000264c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000264e:	4a15                	li	s4,5
        havekids = 1;
    80002650:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002652:	00016997          	auipc	s3,0x16
    80002656:	b6e98993          	addi	s3,s3,-1170 # 800181c0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000265a:	0000ed17          	auipc	s10,0xe
    8000265e:	53ed0d13          	addi	s10,s10,1342 # 80010b98 <wait_lock>
    havekids = 0;
    80002662:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002664:	0000f497          	auipc	s1,0xf
    80002668:	15c48493          	addi	s1,s1,348 # 800117c0 <proc>
    8000266c:	a059                	j	800026f2 <waitx+0xe2>
          pid = np->pid;
    8000266e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002672:	1684a783          	lw	a5,360(s1)
    80002676:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000267a:	16c4a703          	lw	a4,364(s1)
    8000267e:	9f3d                	addw	a4,a4,a5
    80002680:	1704a783          	lw	a5,368(s1)
    80002684:	9f99                	subw	a5,a5,a4
    80002686:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000268a:	000b0e63          	beqz	s6,800026a6 <waitx+0x96>
    8000268e:	4691                	li	a3,4
    80002690:	02c48613          	addi	a2,s1,44
    80002694:	85da                	mv	a1,s6
    80002696:	05093503          	ld	a0,80(s2)
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	fd2080e7          	jalr	-46(ra) # 8000166c <copyout>
    800026a2:	02054563          	bltz	a0,800026cc <waitx+0xbc>
          freeproc(np);
    800026a6:	8526                	mv	a0,s1
    800026a8:	fffff097          	auipc	ra,0xfffff
    800026ac:	4b6080e7          	jalr	1206(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800026b0:	8526                	mv	a0,s1
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	5d8080e7          	jalr	1496(ra) # 80000c8a <release>
          release(&wait_lock);
    800026ba:	0000e517          	auipc	a0,0xe
    800026be:	4de50513          	addi	a0,a0,1246 # 80010b98 <wait_lock>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5c8080e7          	jalr	1480(ra) # 80000c8a <release>
          return pid;
    800026ca:	a09d                	j	80002730 <waitx+0x120>
            release(&np->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	5bc080e7          	jalr	1468(ra) # 80000c8a <release>
            release(&wait_lock);
    800026d6:	0000e517          	auipc	a0,0xe
    800026da:	4c250513          	addi	a0,a0,1218 # 80010b98 <wait_lock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5ac080e7          	jalr	1452(ra) # 80000c8a <release>
            return -1;
    800026e6:	59fd                	li	s3,-1
    800026e8:	a0a1                	j	80002730 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026ea:	1a848493          	addi	s1,s1,424
    800026ee:	03348463          	beq	s1,s3,80002716 <waitx+0x106>
      if (np->parent == p)
    800026f2:	7c9c                	ld	a5,56(s1)
    800026f4:	ff279be3          	bne	a5,s2,800026ea <waitx+0xda>
        acquire(&np->lock);
    800026f8:	8526                	mv	a0,s1
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	4dc080e7          	jalr	1244(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002702:	4c9c                	lw	a5,24(s1)
    80002704:	f74785e3          	beq	a5,s4,8000266e <waitx+0x5e>
        release(&np->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	580080e7          	jalr	1408(ra) # 80000c8a <release>
        havekids = 1;
    80002712:	8756                	mv	a4,s5
    80002714:	bfd9                	j	800026ea <waitx+0xda>
    if (!havekids || p->killed)
    80002716:	c701                	beqz	a4,8000271e <waitx+0x10e>
    80002718:	02892783          	lw	a5,40(s2)
    8000271c:	cb8d                	beqz	a5,8000274e <waitx+0x13e>
      release(&wait_lock);
    8000271e:	0000e517          	auipc	a0,0xe
    80002722:	47a50513          	addi	a0,a0,1146 # 80010b98 <wait_lock>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	564080e7          	jalr	1380(ra) # 80000c8a <release>
      return -1;
    8000272e:	59fd                	li	s3,-1
  }
}
    80002730:	854e                	mv	a0,s3
    80002732:	60e6                	ld	ra,88(sp)
    80002734:	6446                	ld	s0,80(sp)
    80002736:	64a6                	ld	s1,72(sp)
    80002738:	6906                	ld	s2,64(sp)
    8000273a:	79e2                	ld	s3,56(sp)
    8000273c:	7a42                	ld	s4,48(sp)
    8000273e:	7aa2                	ld	s5,40(sp)
    80002740:	7b02                	ld	s6,32(sp)
    80002742:	6be2                	ld	s7,24(sp)
    80002744:	6c42                	ld	s8,16(sp)
    80002746:	6ca2                	ld	s9,8(sp)
    80002748:	6d02                	ld	s10,0(sp)
    8000274a:	6125                	addi	sp,sp,96
    8000274c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000274e:	85ea                	mv	a1,s10
    80002750:	854a                	mv	a0,s2
    80002752:	00000097          	auipc	ra,0x0
    80002756:	94e080e7          	jalr	-1714(ra) # 800020a0 <sleep>
    havekids = 0;
    8000275a:	b721                	j	80002662 <waitx+0x52>

000000008000275c <update_time>:

void update_time()
{
    8000275c:	7179                	addi	sp,sp,-48
    8000275e:	f406                	sd	ra,40(sp)
    80002760:	f022                	sd	s0,32(sp)
    80002762:	ec26                	sd	s1,24(sp)
    80002764:	e84a                	sd	s2,16(sp)
    80002766:	e44e                	sd	s3,8(sp)
    80002768:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000276a:	0000f497          	auipc	s1,0xf
    8000276e:	05648493          	addi	s1,s1,86 # 800117c0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002772:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002774:	00016917          	auipc	s2,0x16
    80002778:	a4c90913          	addi	s2,s2,-1460 # 800181c0 <tickslock>
    8000277c:	a811                	j	80002790 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000277e:	8526                	mv	a0,s1
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	50a080e7          	jalr	1290(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002788:	1a848493          	addi	s1,s1,424
    8000278c:	03248063          	beq	s1,s2,800027ac <update_time+0x50>
    acquire(&p->lock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	444080e7          	jalr	1092(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000279a:	4c9c                	lw	a5,24(s1)
    8000279c:	ff3791e3          	bne	a5,s3,8000277e <update_time+0x22>
      p->rtime++;
    800027a0:	1684a783          	lw	a5,360(s1)
    800027a4:	2785                	addiw	a5,a5,1
    800027a6:	16f4a423          	sw	a5,360(s1)
    800027aa:	bfd1                	j	8000277e <update_time+0x22>
  }
    800027ac:	70a2                	ld	ra,40(sp)
    800027ae:	7402                	ld	s0,32(sp)
    800027b0:	64e2                	ld	s1,24(sp)
    800027b2:	6942                	ld	s2,16(sp)
    800027b4:	69a2                	ld	s3,8(sp)
    800027b6:	6145                	addi	sp,sp,48
    800027b8:	8082                	ret

00000000800027ba <swtch>:
    800027ba:	00153023          	sd	ra,0(a0)
    800027be:	00253423          	sd	sp,8(a0)
    800027c2:	e900                	sd	s0,16(a0)
    800027c4:	ed04                	sd	s1,24(a0)
    800027c6:	03253023          	sd	s2,32(a0)
    800027ca:	03353423          	sd	s3,40(a0)
    800027ce:	03453823          	sd	s4,48(a0)
    800027d2:	03553c23          	sd	s5,56(a0)
    800027d6:	05653023          	sd	s6,64(a0)
    800027da:	05753423          	sd	s7,72(a0)
    800027de:	05853823          	sd	s8,80(a0)
    800027e2:	05953c23          	sd	s9,88(a0)
    800027e6:	07a53023          	sd	s10,96(a0)
    800027ea:	07b53423          	sd	s11,104(a0)
    800027ee:	0005b083          	ld	ra,0(a1)
    800027f2:	0085b103          	ld	sp,8(a1)
    800027f6:	6980                	ld	s0,16(a1)
    800027f8:	6d84                	ld	s1,24(a1)
    800027fa:	0205b903          	ld	s2,32(a1)
    800027fe:	0285b983          	ld	s3,40(a1)
    80002802:	0305ba03          	ld	s4,48(a1)
    80002806:	0385ba83          	ld	s5,56(a1)
    8000280a:	0405bb03          	ld	s6,64(a1)
    8000280e:	0485bb83          	ld	s7,72(a1)
    80002812:	0505bc03          	ld	s8,80(a1)
    80002816:	0585bc83          	ld	s9,88(a1)
    8000281a:	0605bd03          	ld	s10,96(a1)
    8000281e:	0685bd83          	ld	s11,104(a1)
    80002822:	8082                	ret

0000000080002824 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002824:	1141                	addi	sp,sp,-16
    80002826:	e406                	sd	ra,8(sp)
    80002828:	e022                	sd	s0,0(sp)
    8000282a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000282c:	00006597          	auipc	a1,0x6
    80002830:	acc58593          	addi	a1,a1,-1332 # 800082f8 <states.0+0x30>
    80002834:	00016517          	auipc	a0,0x16
    80002838:	98c50513          	addi	a0,a0,-1652 # 800181c0 <tickslock>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	30a080e7          	jalr	778(ra) # 80000b46 <initlock>
}
    80002844:	60a2                	ld	ra,8(sp)
    80002846:	6402                	ld	s0,0(sp)
    80002848:	0141                	addi	sp,sp,16
    8000284a:	8082                	ret

000000008000284c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000284c:	1141                	addi	sp,sp,-16
    8000284e:	e422                	sd	s0,8(sp)
    80002850:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002852:	00003797          	auipc	a5,0x3
    80002856:	68e78793          	addi	a5,a5,1678 # 80005ee0 <kernelvec>
    8000285a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000285e:	6422                	ld	s0,8(sp)
    80002860:	0141                	addi	sp,sp,16
    80002862:	8082                	ret

0000000080002864 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002864:	1141                	addi	sp,sp,-16
    80002866:	e406                	sd	ra,8(sp)
    80002868:	e022                	sd	s0,0(sp)
    8000286a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	140080e7          	jalr	320(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002874:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002878:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000287a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000287e:	00004697          	auipc	a3,0x4
    80002882:	78268693          	addi	a3,a3,1922 # 80007000 <_trampoline>
    80002886:	00004717          	auipc	a4,0x4
    8000288a:	77a70713          	addi	a4,a4,1914 # 80007000 <_trampoline>
    8000288e:	8f15                	sub	a4,a4,a3
    80002890:	040007b7          	lui	a5,0x4000
    80002894:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002896:	07b2                	slli	a5,a5,0xc
    80002898:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000289a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000289e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028a0:	18002673          	csrr	a2,satp
    800028a4:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028a6:	6d30                	ld	a2,88(a0)
    800028a8:	6138                	ld	a4,64(a0)
    800028aa:	6585                	lui	a1,0x1
    800028ac:	972e                	add	a4,a4,a1
    800028ae:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028b0:	6d38                	ld	a4,88(a0)
    800028b2:	00000617          	auipc	a2,0x0
    800028b6:	13e60613          	addi	a2,a2,318 # 800029f0 <usertrap>
    800028ba:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028bc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028be:	8612                	mv	a2,tp
    800028c0:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c2:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028c6:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028ca:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ce:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028d2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028d4:	6f18                	ld	a4,24(a4)
    800028d6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028da:	6928                	ld	a0,80(a0)
    800028dc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028de:	00004717          	auipc	a4,0x4
    800028e2:	7be70713          	addi	a4,a4,1982 # 8000709c <userret>
    800028e6:	8f15                	sub	a4,a4,a3
    800028e8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028ea:	577d                	li	a4,-1
    800028ec:	177e                	slli	a4,a4,0x3f
    800028ee:	8d59                	or	a0,a0,a4
    800028f0:	9782                	jalr	a5
}
    800028f2:	60a2                	ld	ra,8(sp)
    800028f4:	6402                	ld	s0,0(sp)
    800028f6:	0141                	addi	sp,sp,16
    800028f8:	8082                	ret

00000000800028fa <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028fa:	1101                	addi	sp,sp,-32
    800028fc:	ec06                	sd	ra,24(sp)
    800028fe:	e822                	sd	s0,16(sp)
    80002900:	e426                	sd	s1,8(sp)
    80002902:	e04a                	sd	s2,0(sp)
    80002904:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002906:	00016917          	auipc	s2,0x16
    8000290a:	8ba90913          	addi	s2,s2,-1862 # 800181c0 <tickslock>
    8000290e:	854a                	mv	a0,s2
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	2c6080e7          	jalr	710(ra) # 80000bd6 <acquire>
  ticks++;
    80002918:	00006497          	auipc	s1,0x6
    8000291c:	ff848493          	addi	s1,s1,-8 # 80008910 <ticks>
    80002920:	409c                	lw	a5,0(s1)
    80002922:	2785                	addiw	a5,a5,1
    80002924:	c09c                	sw	a5,0(s1)
  update_time();
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	e36080e7          	jalr	-458(ra) # 8000275c <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000292e:	8526                	mv	a0,s1
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	7d4080e7          	jalr	2004(ra) # 80002104 <wakeup>
  release(&tickslock);
    80002938:	854a                	mv	a0,s2
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	350080e7          	jalr	848(ra) # 80000c8a <release>
}
    80002942:	60e2                	ld	ra,24(sp)
    80002944:	6442                	ld	s0,16(sp)
    80002946:	64a2                	ld	s1,8(sp)
    80002948:	6902                	ld	s2,0(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret

000000008000294e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    8000294e:	1101                	addi	sp,sp,-32
    80002950:	ec06                	sd	ra,24(sp)
    80002952:	e822                	sd	s0,16(sp)
    80002954:	e426                	sd	s1,8(sp)
    80002956:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002958:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    8000295c:	00074d63          	bltz	a4,80002976 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002960:	57fd                	li	a5,-1
    80002962:	17fe                	slli	a5,a5,0x3f
    80002964:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002966:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002968:	06f70363          	beq	a4,a5,800029ce <devintr+0x80>
  }
}
    8000296c:	60e2                	ld	ra,24(sp)
    8000296e:	6442                	ld	s0,16(sp)
    80002970:	64a2                	ld	s1,8(sp)
    80002972:	6105                	addi	sp,sp,32
    80002974:	8082                	ret
      (scause & 0xff) == 9)
    80002976:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    8000297a:	46a5                	li	a3,9
    8000297c:	fed792e3          	bne	a5,a3,80002960 <devintr+0x12>
    int irq = plic_claim();
    80002980:	00003097          	auipc	ra,0x3
    80002984:	668080e7          	jalr	1640(ra) # 80005fe8 <plic_claim>
    80002988:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000298a:	47a9                	li	a5,10
    8000298c:	02f50763          	beq	a0,a5,800029ba <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002990:	4785                	li	a5,1
    80002992:	02f50963          	beq	a0,a5,800029c4 <devintr+0x76>
    return 1;
    80002996:	4505                	li	a0,1
    else if (irq)
    80002998:	d8f1                	beqz	s1,8000296c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000299a:	85a6                	mv	a1,s1
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	96450513          	addi	a0,a0,-1692 # 80008300 <states.0+0x38>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	be6080e7          	jalr	-1050(ra) # 8000058a <printf>
      plic_complete(irq);
    800029ac:	8526                	mv	a0,s1
    800029ae:	00003097          	auipc	ra,0x3
    800029b2:	65e080e7          	jalr	1630(ra) # 8000600c <plic_complete>
    return 1;
    800029b6:	4505                	li	a0,1
    800029b8:	bf55                	j	8000296c <devintr+0x1e>
      uartintr();
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	fde080e7          	jalr	-34(ra) # 80000998 <uartintr>
    800029c2:	b7ed                	j	800029ac <devintr+0x5e>
      virtio_disk_intr();
    800029c4:	00004097          	auipc	ra,0x4
    800029c8:	b10080e7          	jalr	-1264(ra) # 800064d4 <virtio_disk_intr>
    800029cc:	b7c5                	j	800029ac <devintr+0x5e>
    if (cpuid() == 0)
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	fb2080e7          	jalr	-78(ra) # 80001980 <cpuid>
    800029d6:	c901                	beqz	a0,800029e6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029d8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029dc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029de:	14479073          	csrw	sip,a5
    return 2;
    800029e2:	4509                	li	a0,2
    800029e4:	b761                	j	8000296c <devintr+0x1e>
      clockintr();
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	f14080e7          	jalr	-236(ra) # 800028fa <clockintr>
    800029ee:	b7ed                	j	800029d8 <devintr+0x8a>

00000000800029f0 <usertrap>:
{
    800029f0:	1101                	addi	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	e04a                	sd	s2,0(sp)
    800029fa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a00:	1007f793          	andi	a5,a5,256
    80002a04:	e7bd                	bnez	a5,80002a72 <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a06:	00003797          	auipc	a5,0x3
    80002a0a:	4da78793          	addi	a5,a5,1242 # 80005ee0 <kernelvec>
    80002a0e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	f9a080e7          	jalr	-102(ra) # 800019ac <myproc>
    80002a1a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a1c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	14102773          	csrr	a4,sepc
    80002a22:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a24:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a28:	47a1                	li	a5,8
    80002a2a:	04f70c63          	beq	a4,a5,80002a82 <usertrap+0x92>
  else if ((which_dev = devintr()) != 0)
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	f20080e7          	jalr	-224(ra) # 8000294e <devintr>
    80002a36:	892a                	mv	s2,a0
    80002a38:	c561                	beqz	a0,80002b00 <usertrap+0x110>
    if (which_dev == 2 && p->alarm_on == 0)
    80002a3a:	4789                	li	a5,2
    80002a3c:	06f51763          	bne	a0,a5,80002aaa <usertrap+0xba>
    80002a40:	1904a783          	lw	a5,400(s1)
    80002a44:	ef81                	bnez	a5,80002a5c <usertrap+0x6c>
      p->cur_ticks++;
    80002a46:	1844a783          	lw	a5,388(s1)
    80002a4a:	2785                	addiw	a5,a5,1
    80002a4c:	0007871b          	sext.w	a4,a5
    80002a50:	18f4a223          	sw	a5,388(s1)
      if (p->cur_ticks == p->ticks)
    80002a54:	1804a783          	lw	a5,384(s1)
    80002a58:	06e78f63          	beq	a5,a4,80002ad6 <usertrap+0xe6>
  if (killed(p))
    80002a5c:	8526                	mv	a0,s1
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	8f6080e7          	jalr	-1802(ra) # 80002354 <killed>
    80002a66:	e17d                	bnez	a0,80002b4c <usertrap+0x15c>
    yield();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	5fc080e7          	jalr	1532(ra) # 80002064 <yield>
    80002a70:	a099                	j	80002ab6 <usertrap+0xc6>
    panic("usertrap: not from user mode");
    80002a72:	00006517          	auipc	a0,0x6
    80002a76:	8ae50513          	addi	a0,a0,-1874 # 80008320 <states.0+0x58>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	ac6080e7          	jalr	-1338(ra) # 80000540 <panic>
    if (killed(p))
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	8d2080e7          	jalr	-1838(ra) # 80002354 <killed>
    80002a8a:	e121                	bnez	a0,80002aca <usertrap+0xda>
    p->trapframe->epc += 4;
    80002a8c:	6cb8                	ld	a4,88(s1)
    80002a8e:	6f1c                	ld	a5,24(a4)
    80002a90:	0791                	addi	a5,a5,4
    80002a92:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a9c:	10079073          	csrw	sstatus,a5
    syscall();
    80002aa0:	00000097          	auipc	ra,0x0
    80002aa4:	302080e7          	jalr	770(ra) # 80002da2 <syscall>
  int which_dev = 0;
    80002aa8:	4901                	li	s2,0
  if (killed(p))
    80002aaa:	8526                	mv	a0,s1
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	8a8080e7          	jalr	-1880(ra) # 80002354 <killed>
    80002ab4:	e159                	bnez	a0,80002b3a <usertrap+0x14a>
  usertrapret();
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	dae080e7          	jalr	-594(ra) # 80002864 <usertrapret>
}
    80002abe:	60e2                	ld	ra,24(sp)
    80002ac0:	6442                	ld	s0,16(sp)
    80002ac2:	64a2                	ld	s1,8(sp)
    80002ac4:	6902                	ld	s2,0(sp)
    80002ac6:	6105                	addi	sp,sp,32
    80002ac8:	8082                	ret
      exit(-1);
    80002aca:	557d                	li	a0,-1
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	708080e7          	jalr	1800(ra) # 800021d4 <exit>
    80002ad4:	bf65                	j	80002a8c <usertrap+0x9c>
        p->alarm_on = 1;
    80002ad6:	4785                	li	a5,1
    80002ad8:	18f4a823          	sw	a5,400(s1)
        struct trapframe *tf = kalloc();
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	00a080e7          	jalr	10(ra) # 80000ae6 <kalloc>
    80002ae4:	892a                	mv	s2,a0
        memmove(tf, p->trapframe, PGSIZE);
    80002ae6:	6605                	lui	a2,0x1
    80002ae8:	6cac                	ld	a1,88(s1)
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	244080e7          	jalr	580(ra) # 80000d2e <memmove>
        p->alarm_tf = tf;
    80002af2:	1924b423          	sd	s2,392(s1)
        p->trapframe->epc = p->handler;
    80002af6:	6cbc                	ld	a5,88(s1)
    80002af8:	1784b703          	ld	a4,376(s1)
    80002afc:	ef98                	sd	a4,24(a5)
    80002afe:	bfb9                	j	80002a5c <usertrap+0x6c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b00:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b04:	5890                	lw	a2,48(s1)
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	83a50513          	addi	a0,a0,-1990 # 80008340 <states.0+0x78>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a7c080e7          	jalr	-1412(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b16:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b1a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b1e:	00006517          	auipc	a0,0x6
    80002b22:	85250513          	addi	a0,a0,-1966 # 80008370 <states.0+0xa8>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	a64080e7          	jalr	-1436(ra) # 8000058a <printf>
    setkilled(p);
    80002b2e:	8526                	mv	a0,s1
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	7f8080e7          	jalr	2040(ra) # 80002328 <setkilled>
    80002b38:	bf8d                	j	80002aaa <usertrap+0xba>
    exit(-1);
    80002b3a:	557d                	li	a0,-1
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	698080e7          	jalr	1688(ra) # 800021d4 <exit>
  if (which_dev == 2)
    80002b44:	4789                	li	a5,2
    80002b46:	f6f918e3          	bne	s2,a5,80002ab6 <usertrap+0xc6>
    80002b4a:	bf39                	j	80002a68 <usertrap+0x78>
    exit(-1);
    80002b4c:	557d                	li	a0,-1
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	686080e7          	jalr	1670(ra) # 800021d4 <exit>
  if (which_dev == 2)
    80002b56:	bf09                	j	80002a68 <usertrap+0x78>

0000000080002b58 <kerneltrap>:
{
    80002b58:	7179                	addi	sp,sp,-48
    80002b5a:	f406                	sd	ra,40(sp)
    80002b5c:	f022                	sd	s0,32(sp)
    80002b5e:	ec26                	sd	s1,24(sp)
    80002b60:	e84a                	sd	s2,16(sp)
    80002b62:	e44e                	sd	s3,8(sp)
    80002b64:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b66:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b72:	1004f793          	andi	a5,s1,256
    80002b76:	cb85                	beqz	a5,80002ba6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b7c:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b7e:	ef85                	bnez	a5,80002bb6 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	dce080e7          	jalr	-562(ra) # 8000294e <devintr>
    80002b88:	cd1d                	beqz	a0,80002bc6 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b8a:	4789                	li	a5,2
    80002b8c:	06f50a63          	beq	a0,a5,80002c00 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b90:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b94:	10049073          	csrw	sstatus,s1
}
    80002b98:	70a2                	ld	ra,40(sp)
    80002b9a:	7402                	ld	s0,32(sp)
    80002b9c:	64e2                	ld	s1,24(sp)
    80002b9e:	6942                	ld	s2,16(sp)
    80002ba0:	69a2                	ld	s3,8(sp)
    80002ba2:	6145                	addi	sp,sp,48
    80002ba4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ba6:	00005517          	auipc	a0,0x5
    80002baa:	7ea50513          	addi	a0,a0,2026 # 80008390 <states.0+0xc8>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	992080e7          	jalr	-1646(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bb6:	00006517          	auipc	a0,0x6
    80002bba:	80250513          	addi	a0,a0,-2046 # 800083b8 <states.0+0xf0>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	982080e7          	jalr	-1662(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002bc6:	85ce                	mv	a1,s3
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	81050513          	addi	a0,a0,-2032 # 800083d8 <states.0+0x110>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	9ba080e7          	jalr	-1606(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bdc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002be0:	00006517          	auipc	a0,0x6
    80002be4:	80850513          	addi	a0,a0,-2040 # 800083e8 <states.0+0x120>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	9a2080e7          	jalr	-1630(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002bf0:	00006517          	auipc	a0,0x6
    80002bf4:	81050513          	addi	a0,a0,-2032 # 80008400 <states.0+0x138>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	948080e7          	jalr	-1720(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	dac080e7          	jalr	-596(ra) # 800019ac <myproc>
    80002c08:	d541                	beqz	a0,80002b90 <kerneltrap+0x38>
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	da2080e7          	jalr	-606(ra) # 800019ac <myproc>
    80002c12:	4d18                	lw	a4,24(a0)
    80002c14:	4791                	li	a5,4
    80002c16:	f6f71de3          	bne	a4,a5,80002b90 <kerneltrap+0x38>
    yield();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	44a080e7          	jalr	1098(ra) # 80002064 <yield>
    80002c22:	b7bd                	j	80002b90 <kerneltrap+0x38>

0000000080002c24 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	d7c080e7          	jalr	-644(ra) # 800019ac <myproc>
  switch (n) {
    80002c38:	4795                	li	a5,5
    80002c3a:	0497e163          	bltu	a5,s1,80002c7c <argraw+0x58>
    80002c3e:	048a                	slli	s1,s1,0x2
    80002c40:	00005717          	auipc	a4,0x5
    80002c44:	7f870713          	addi	a4,a4,2040 # 80008438 <states.0+0x170>
    80002c48:	94ba                	add	s1,s1,a4
    80002c4a:	409c                	lw	a5,0(s1)
    80002c4c:	97ba                	add	a5,a5,a4
    80002c4e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c50:	6d3c                	ld	a5,88(a0)
    80002c52:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	64a2                	ld	s1,8(sp)
    80002c5a:	6105                	addi	sp,sp,32
    80002c5c:	8082                	ret
    return p->trapframe->a1;
    80002c5e:	6d3c                	ld	a5,88(a0)
    80002c60:	7fa8                	ld	a0,120(a5)
    80002c62:	bfcd                	j	80002c54 <argraw+0x30>
    return p->trapframe->a2;
    80002c64:	6d3c                	ld	a5,88(a0)
    80002c66:	63c8                	ld	a0,128(a5)
    80002c68:	b7f5                	j	80002c54 <argraw+0x30>
    return p->trapframe->a3;
    80002c6a:	6d3c                	ld	a5,88(a0)
    80002c6c:	67c8                	ld	a0,136(a5)
    80002c6e:	b7dd                	j	80002c54 <argraw+0x30>
    return p->trapframe->a4;
    80002c70:	6d3c                	ld	a5,88(a0)
    80002c72:	6bc8                	ld	a0,144(a5)
    80002c74:	b7c5                	j	80002c54 <argraw+0x30>
    return p->trapframe->a5;
    80002c76:	6d3c                	ld	a5,88(a0)
    80002c78:	6fc8                	ld	a0,152(a5)
    80002c7a:	bfe9                	j	80002c54 <argraw+0x30>
  panic("argraw");
    80002c7c:	00005517          	auipc	a0,0x5
    80002c80:	79450513          	addi	a0,a0,1940 # 80008410 <states.0+0x148>
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	8bc080e7          	jalr	-1860(ra) # 80000540 <panic>

0000000080002c8c <fetchaddr>:
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	e426                	sd	s1,8(sp)
    80002c94:	e04a                	sd	s2,0(sp)
    80002c96:	1000                	addi	s0,sp,32
    80002c98:	84aa                	mv	s1,a0
    80002c9a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d10080e7          	jalr	-752(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ca4:	653c                	ld	a5,72(a0)
    80002ca6:	02f4f863          	bgeu	s1,a5,80002cd6 <fetchaddr+0x4a>
    80002caa:	00848713          	addi	a4,s1,8
    80002cae:	02e7e663          	bltu	a5,a4,80002cda <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cb2:	46a1                	li	a3,8
    80002cb4:	8626                	mv	a2,s1
    80002cb6:	85ca                	mv	a1,s2
    80002cb8:	6928                	ld	a0,80(a0)
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	a3e080e7          	jalr	-1474(ra) # 800016f8 <copyin>
    80002cc2:	00a03533          	snez	a0,a0
    80002cc6:	40a00533          	neg	a0,a0
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6902                	ld	s2,0(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret
    return -1;
    80002cd6:	557d                	li	a0,-1
    80002cd8:	bfcd                	j	80002cca <fetchaddr+0x3e>
    80002cda:	557d                	li	a0,-1
    80002cdc:	b7fd                	j	80002cca <fetchaddr+0x3e>

0000000080002cde <fetchstr>:
{
    80002cde:	7179                	addi	sp,sp,-48
    80002ce0:	f406                	sd	ra,40(sp)
    80002ce2:	f022                	sd	s0,32(sp)
    80002ce4:	ec26                	sd	s1,24(sp)
    80002ce6:	e84a                	sd	s2,16(sp)
    80002ce8:	e44e                	sd	s3,8(sp)
    80002cea:	1800                	addi	s0,sp,48
    80002cec:	892a                	mv	s2,a0
    80002cee:	84ae                	mv	s1,a1
    80002cf0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	cba080e7          	jalr	-838(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cfa:	86ce                	mv	a3,s3
    80002cfc:	864a                	mv	a2,s2
    80002cfe:	85a6                	mv	a1,s1
    80002d00:	6928                	ld	a0,80(a0)
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	a84080e7          	jalr	-1404(ra) # 80001786 <copyinstr>
    80002d0a:	00054e63          	bltz	a0,80002d26 <fetchstr+0x48>
  return strlen(buf);
    80002d0e:	8526                	mv	a0,s1
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	13e080e7          	jalr	318(ra) # 80000e4e <strlen>
}
    80002d18:	70a2                	ld	ra,40(sp)
    80002d1a:	7402                	ld	s0,32(sp)
    80002d1c:	64e2                	ld	s1,24(sp)
    80002d1e:	6942                	ld	s2,16(sp)
    80002d20:	69a2                	ld	s3,8(sp)
    80002d22:	6145                	addi	sp,sp,48
    80002d24:	8082                	ret
    return -1;
    80002d26:	557d                	li	a0,-1
    80002d28:	bfc5                	j	80002d18 <fetchstr+0x3a>

0000000080002d2a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d2a:	1101                	addi	sp,sp,-32
    80002d2c:	ec06                	sd	ra,24(sp)
    80002d2e:	e822                	sd	s0,16(sp)
    80002d30:	e426                	sd	s1,8(sp)
    80002d32:	1000                	addi	s0,sp,32
    80002d34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	eee080e7          	jalr	-274(ra) # 80002c24 <argraw>
    80002d3e:	c088                	sw	a0,0(s1)
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret

0000000080002d4a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	1000                	addi	s0,sp,32
    80002d54:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	ece080e7          	jalr	-306(ra) # 80002c24 <argraw>
    80002d5e:	e088                	sd	a0,0(s1)
}
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	64a2                	ld	s1,8(sp)
    80002d66:	6105                	addi	sp,sp,32
    80002d68:	8082                	ret

0000000080002d6a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d6a:	7179                	addi	sp,sp,-48
    80002d6c:	f406                	sd	ra,40(sp)
    80002d6e:	f022                	sd	s0,32(sp)
    80002d70:	ec26                	sd	s1,24(sp)
    80002d72:	e84a                	sd	s2,16(sp)
    80002d74:	1800                	addi	s0,sp,48
    80002d76:	84ae                	mv	s1,a1
    80002d78:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d7a:	fd840593          	addi	a1,s0,-40
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	fcc080e7          	jalr	-52(ra) # 80002d4a <argaddr>
  return fetchstr(addr, buf, max);
    80002d86:	864a                	mv	a2,s2
    80002d88:	85a6                	mv	a1,s1
    80002d8a:	fd843503          	ld	a0,-40(s0)
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	f50080e7          	jalr	-176(ra) # 80002cde <fetchstr>
}
    80002d96:	70a2                	ld	ra,40(sp)
    80002d98:	7402                	ld	s0,32(sp)
    80002d9a:	64e2                	ld	s1,24(sp)
    80002d9c:	6942                	ld	s2,16(sp)
    80002d9e:	6145                	addi	sp,sp,48
    80002da0:	8082                	ret

0000000080002da2 <syscall>:
};

int read_count=0;
void
syscall(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	e426                	sd	s1,8(sp)
    80002daa:	e04a                	sd	s2,0(sp)
    80002dac:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	bfe080e7          	jalr	-1026(ra) # 800019ac <myproc>
    80002db6:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002db8:	05853903          	ld	s2,88(a0)
    80002dbc:	0a893783          	ld	a5,168(s2)
    80002dc0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dc4:	37fd                	addiw	a5,a5,-1
    80002dc6:	4761                	li	a4,24
    80002dc8:	02f76a63          	bltu	a4,a5,80002dfc <syscall+0x5a>
    80002dcc:	00369713          	slli	a4,a3,0x3
    80002dd0:	00005797          	auipc	a5,0x5
    80002dd4:	68078793          	addi	a5,a5,1664 # 80008450 <syscalls>
    80002dd8:	97ba                	add	a5,a5,a4
    80002dda:	639c                	ld	a5,0(a5)
    80002ddc:	c385                	beqz	a5,80002dfc <syscall+0x5a>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    if(num == SYS_read)
    80002dde:	4715                	li	a4,5
    80002de0:	00e68663          	beq	a3,a4,80002dec <syscall+0x4a>
        read_count++;
    p->trapframe->a0 = syscalls[num]();
    80002de4:	9782                	jalr	a5
    80002de6:	06a93823          	sd	a0,112(s2)
    80002dea:	a03d                	j	80002e18 <syscall+0x76>
        read_count++;
    80002dec:	00006697          	auipc	a3,0x6
    80002df0:	b2868693          	addi	a3,a3,-1240 # 80008914 <read_count>
    80002df4:	4298                	lw	a4,0(a3)
    80002df6:	2705                	addiw	a4,a4,1
    80002df8:	c298                	sw	a4,0(a3)
    80002dfa:	b7ed                	j	80002de4 <syscall+0x42>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dfc:	15848613          	addi	a2,s1,344
    80002e00:	588c                	lw	a1,48(s1)
    80002e02:	00005517          	auipc	a0,0x5
    80002e06:	61650513          	addi	a0,a0,1558 # 80008418 <states.0+0x150>
    80002e0a:	ffffd097          	auipc	ra,0xffffd
    80002e0e:	780080e7          	jalr	1920(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e12:	6cbc                	ld	a5,88(s1)
    80002e14:	577d                	li	a4,-1
    80002e16:	fbb8                	sd	a4,112(a5)
  }
}
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	64a2                	ld	s1,8(sp)
    80002e1e:	6902                	ld	s2,0(sp)
    80002e20:	6105                	addi	sp,sp,32
    80002e22:	8082                	ret

0000000080002e24 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e24:	1101                	addi	sp,sp,-32
    80002e26:	ec06                	sd	ra,24(sp)
    80002e28:	e822                	sd	s0,16(sp)
    80002e2a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e2c:	fec40593          	addi	a1,s0,-20
    80002e30:	4501                	li	a0,0
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	ef8080e7          	jalr	-264(ra) # 80002d2a <argint>
  exit(n);
    80002e3a:	fec42503          	lw	a0,-20(s0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	396080e7          	jalr	918(ra) # 800021d4 <exit>
  return 0; // not reached
}
    80002e46:	4501                	li	a0,0
    80002e48:	60e2                	ld	ra,24(sp)
    80002e4a:	6442                	ld	s0,16(sp)
    80002e4c:	6105                	addi	sp,sp,32
    80002e4e:	8082                	ret

0000000080002e50 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e50:	1141                	addi	sp,sp,-16
    80002e52:	e406                	sd	ra,8(sp)
    80002e54:	e022                	sd	s0,0(sp)
    80002e56:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	b54080e7          	jalr	-1196(ra) # 800019ac <myproc>
}
    80002e60:	5908                	lw	a0,48(a0)
    80002e62:	60a2                	ld	ra,8(sp)
    80002e64:	6402                	ld	s0,0(sp)
    80002e66:	0141                	addi	sp,sp,16
    80002e68:	8082                	ret

0000000080002e6a <sys_fork>:

uint64
sys_fork(void)
{
    80002e6a:	1141                	addi	sp,sp,-16
    80002e6c:	e406                	sd	ra,8(sp)
    80002e6e:	e022                	sd	s0,0(sp)
    80002e70:	0800                	addi	s0,sp,16
  return fork();
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	f3c080e7          	jalr	-196(ra) # 80001dae <fork>
}
    80002e7a:	60a2                	ld	ra,8(sp)
    80002e7c:	6402                	ld	s0,0(sp)
    80002e7e:	0141                	addi	sp,sp,16
    80002e80:	8082                	ret

0000000080002e82 <sys_wait>:

uint64
sys_wait(void)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e8a:	fe840593          	addi	a1,s0,-24
    80002e8e:	4501                	li	a0,0
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	eba080e7          	jalr	-326(ra) # 80002d4a <argaddr>
  return wait(p);
    80002e98:	fe843503          	ld	a0,-24(s0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	4ea080e7          	jalr	1258(ra) # 80002386 <wait>
}
    80002ea4:	60e2                	ld	ra,24(sp)
    80002ea6:	6442                	ld	s0,16(sp)
    80002ea8:	6105                	addi	sp,sp,32
    80002eaa:	8082                	ret

0000000080002eac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002eac:	7179                	addi	sp,sp,-48
    80002eae:	f406                	sd	ra,40(sp)
    80002eb0:	f022                	sd	s0,32(sp)
    80002eb2:	ec26                	sd	s1,24(sp)
    80002eb4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002eb6:	fdc40593          	addi	a1,s0,-36
    80002eba:	4501                	li	a0,0
    80002ebc:	00000097          	auipc	ra,0x0
    80002ec0:	e6e080e7          	jalr	-402(ra) # 80002d2a <argint>
  addr = myproc()->sz;
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	ae8080e7          	jalr	-1304(ra) # 800019ac <myproc>
    80002ecc:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002ece:	fdc42503          	lw	a0,-36(s0)
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	e80080e7          	jalr	-384(ra) # 80001d52 <growproc>
    80002eda:	00054863          	bltz	a0,80002eea <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ede:	8526                	mv	a0,s1
    80002ee0:	70a2                	ld	ra,40(sp)
    80002ee2:	7402                	ld	s0,32(sp)
    80002ee4:	64e2                	ld	s1,24(sp)
    80002ee6:	6145                	addi	sp,sp,48
    80002ee8:	8082                	ret
    return -1;
    80002eea:	54fd                	li	s1,-1
    80002eec:	bfcd                	j	80002ede <sys_sbrk+0x32>

0000000080002eee <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eee:	7139                	addi	sp,sp,-64
    80002ef0:	fc06                	sd	ra,56(sp)
    80002ef2:	f822                	sd	s0,48(sp)
    80002ef4:	f426                	sd	s1,40(sp)
    80002ef6:	f04a                	sd	s2,32(sp)
    80002ef8:	ec4e                	sd	s3,24(sp)
    80002efa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002efc:	fcc40593          	addi	a1,s0,-52
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	e28080e7          	jalr	-472(ra) # 80002d2a <argint>
  acquire(&tickslock);
    80002f0a:	00015517          	auipc	a0,0x15
    80002f0e:	2b650513          	addi	a0,a0,694 # 800181c0 <tickslock>
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	cc4080e7          	jalr	-828(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002f1a:	00006917          	auipc	s2,0x6
    80002f1e:	9f692903          	lw	s2,-1546(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    80002f22:	fcc42783          	lw	a5,-52(s0)
    80002f26:	cf9d                	beqz	a5,80002f64 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f28:	00015997          	auipc	s3,0x15
    80002f2c:	29898993          	addi	s3,s3,664 # 800181c0 <tickslock>
    80002f30:	00006497          	auipc	s1,0x6
    80002f34:	9e048493          	addi	s1,s1,-1568 # 80008910 <ticks>
    if (killed(myproc()))
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	a74080e7          	jalr	-1420(ra) # 800019ac <myproc>
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	414080e7          	jalr	1044(ra) # 80002354 <killed>
    80002f48:	ed15                	bnez	a0,80002f84 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f4a:	85ce                	mv	a1,s3
    80002f4c:	8526                	mv	a0,s1
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	152080e7          	jalr	338(ra) # 800020a0 <sleep>
  while (ticks - ticks0 < n)
    80002f56:	409c                	lw	a5,0(s1)
    80002f58:	412787bb          	subw	a5,a5,s2
    80002f5c:	fcc42703          	lw	a4,-52(s0)
    80002f60:	fce7ece3          	bltu	a5,a4,80002f38 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f64:	00015517          	auipc	a0,0x15
    80002f68:	25c50513          	addi	a0,a0,604 # 800181c0 <tickslock>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	d1e080e7          	jalr	-738(ra) # 80000c8a <release>
  return 0;
    80002f74:	4501                	li	a0,0
}
    80002f76:	70e2                	ld	ra,56(sp)
    80002f78:	7442                	ld	s0,48(sp)
    80002f7a:	74a2                	ld	s1,40(sp)
    80002f7c:	7902                	ld	s2,32(sp)
    80002f7e:	69e2                	ld	s3,24(sp)
    80002f80:	6121                	addi	sp,sp,64
    80002f82:	8082                	ret
      release(&tickslock);
    80002f84:	00015517          	auipc	a0,0x15
    80002f88:	23c50513          	addi	a0,a0,572 # 800181c0 <tickslock>
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	cfe080e7          	jalr	-770(ra) # 80000c8a <release>
      return -1;
    80002f94:	557d                	li	a0,-1
    80002f96:	b7c5                	j	80002f76 <sys_sleep+0x88>

0000000080002f98 <sys_kill>:

uint64
sys_kill(void)
{
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002fa0:	fec40593          	addi	a1,s0,-20
    80002fa4:	4501                	li	a0,0
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	d84080e7          	jalr	-636(ra) # 80002d2a <argint>
  return kill(pid);
    80002fae:	fec42503          	lw	a0,-20(s0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	304080e7          	jalr	772(ra) # 800022b6 <kill>
}
    80002fba:	60e2                	ld	ra,24(sp)
    80002fbc:	6442                	ld	s0,16(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fc2:	1101                	addi	sp,sp,-32
    80002fc4:	ec06                	sd	ra,24(sp)
    80002fc6:	e822                	sd	s0,16(sp)
    80002fc8:	e426                	sd	s1,8(sp)
    80002fca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fcc:	00015517          	auipc	a0,0x15
    80002fd0:	1f450513          	addi	a0,a0,500 # 800181c0 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	c02080e7          	jalr	-1022(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fdc:	00006497          	auipc	s1,0x6
    80002fe0:	9344a483          	lw	s1,-1740(s1) # 80008910 <ticks>
  release(&tickslock);
    80002fe4:	00015517          	auipc	a0,0x15
    80002fe8:	1dc50513          	addi	a0,a0,476 # 800181c0 <tickslock>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	c9e080e7          	jalr	-866(ra) # 80000c8a <release>
  return xticks;
}
    80002ff4:	02049513          	slli	a0,s1,0x20
    80002ff8:	9101                	srli	a0,a0,0x20
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003004:	7139                	addi	sp,sp,-64
    80003006:	fc06                	sd	ra,56(sp)
    80003008:	f822                	sd	s0,48(sp)
    8000300a:	f426                	sd	s1,40(sp)
    8000300c:	f04a                	sd	s2,32(sp)
    8000300e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003010:	fd840593          	addi	a1,s0,-40
    80003014:	4501                	li	a0,0
    80003016:	00000097          	auipc	ra,0x0
    8000301a:	d34080e7          	jalr	-716(ra) # 80002d4a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000301e:	fd040593          	addi	a1,s0,-48
    80003022:	4505                	li	a0,1
    80003024:	00000097          	auipc	ra,0x0
    80003028:	d26080e7          	jalr	-730(ra) # 80002d4a <argaddr>
  argaddr(2, &addr2);
    8000302c:	fc840593          	addi	a1,s0,-56
    80003030:	4509                	li	a0,2
    80003032:	00000097          	auipc	ra,0x0
    80003036:	d18080e7          	jalr	-744(ra) # 80002d4a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000303a:	fc040613          	addi	a2,s0,-64
    8000303e:	fc440593          	addi	a1,s0,-60
    80003042:	fd843503          	ld	a0,-40(s0)
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	5ca080e7          	jalr	1482(ra) # 80002610 <waitx>
    8000304e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	95c080e7          	jalr	-1700(ra) # 800019ac <myproc>
    80003058:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000305a:	4691                	li	a3,4
    8000305c:	fc440613          	addi	a2,s0,-60
    80003060:	fd043583          	ld	a1,-48(s0)
    80003064:	6928                	ld	a0,80(a0)
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	606080e7          	jalr	1542(ra) # 8000166c <copyout>
    return -1;
    8000306e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003070:	00054f63          	bltz	a0,8000308e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003074:	4691                	li	a3,4
    80003076:	fc040613          	addi	a2,s0,-64
    8000307a:	fc843583          	ld	a1,-56(s0)
    8000307e:	68a8                	ld	a0,80(s1)
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	5ec080e7          	jalr	1516(ra) # 8000166c <copyout>
    80003088:	00054a63          	bltz	a0,8000309c <sys_waitx+0x98>
    return -1;
  return ret;
    8000308c:	87ca                	mv	a5,s2
}
    8000308e:	853e                	mv	a0,a5
    80003090:	70e2                	ld	ra,56(sp)
    80003092:	7442                	ld	s0,48(sp)
    80003094:	74a2                	ld	s1,40(sp)
    80003096:	7902                	ld	s2,32(sp)
    80003098:	6121                	addi	sp,sp,64
    8000309a:	8082                	ret
    return -1;
    8000309c:	57fd                	li	a5,-1
    8000309e:	bfc5                	j	8000308e <sys_waitx+0x8a>

00000000800030a0 <sys_getreadcount>:
extern int read_count;
uint64
sys_getreadcount(void)
{
    800030a0:	1141                	addi	sp,sp,-16
    800030a2:	e422                	sd	s0,8(sp)
    800030a4:	0800                	addi	s0,sp,16
  return read_count;
}
    800030a6:	00006517          	auipc	a0,0x6
    800030aa:	86e52503          	lw	a0,-1938(a0) # 80008914 <read_count>
    800030ae:	6422                	ld	s0,8(sp)
    800030b0:	0141                	addi	sp,sp,16
    800030b2:	8082                	ret

00000000800030b4 <sys_sigalarm>:
uint64 sys_sigalarm(void)
{
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks;

  argint(0, &ticks);
    800030bc:	fe440593          	addi	a1,s0,-28
    800030c0:	4501                	li	a0,0
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	c68080e7          	jalr	-920(ra) # 80002d2a <argint>
  argaddr(1, &addr);
    800030ca:	fe840593          	addi	a1,s0,-24
    800030ce:	4505                	li	a0,1
    800030d0:	00000097          	auipc	ra,0x0
    800030d4:	c7a080e7          	jalr	-902(ra) # 80002d4a <argaddr>
   
  myproc()->alarm_on = 0;
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	8d4080e7          	jalr	-1836(ra) # 800019ac <myproc>
    800030e0:	18052823          	sw	zero,400(a0)
  myproc()->ticks = ticks;
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	8c8080e7          	jalr	-1848(ra) # 800019ac <myproc>
    800030ec:	fe442783          	lw	a5,-28(s0)
    800030f0:	18f52023          	sw	a5,384(a0)
  myproc()->handler = addr;
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800030fc:	fe843783          	ld	a5,-24(s0)
    80003100:	16f53c23          	sd	a5,376(a0)

  return 0;
}
    80003104:	4501                	li	a0,0
    80003106:	60e2                	ld	ra,24(sp)
    80003108:	6442                	ld	s0,16(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret

000000008000310e <sys_sigreturn>:
uint64 sys_sigreturn(void)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	1000                	addi	s0,sp,32

  struct proc *p = myproc();
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	894080e7          	jalr	-1900(ra) # 800019ac <myproc>
  if(p->alarm_on){
    80003120:	19052783          	lw	a5,400(a0)
    80003124:	e799                	bnez	a5,80003132 <sys_sigreturn+0x24>
    p->alarm_on = 0;
    p->cur_ticks = 0;
  
  }
return 0;
    80003126:	4501                	li	a0,0
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret
    80003132:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_tf, PGSIZE);
    80003134:	6605                	lui	a2,0x1
    80003136:	18853583          	ld	a1,392(a0)
    8000313a:	6d28                	ld	a0,88(a0)
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	bf2080e7          	jalr	-1038(ra) # 80000d2e <memmove>
    kfree(p->alarm_tf);
    80003144:	1884b503          	ld	a0,392(s1)
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	8a0080e7          	jalr	-1888(ra) # 800009e8 <kfree>
    p->alarm_on = 0;
    80003150:	1804a823          	sw	zero,400(s1)
    p->cur_ticks = 0;
    80003154:	1804a223          	sw	zero,388(s1)
    80003158:	b7f9                	j	80003126 <sys_sigreturn+0x18>

000000008000315a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	e052                	sd	s4,0(sp)
    80003168:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000316a:	00005597          	auipc	a1,0x5
    8000316e:	3b658593          	addi	a1,a1,950 # 80008520 <syscalls+0xd0>
    80003172:	00015517          	auipc	a0,0x15
    80003176:	06650513          	addi	a0,a0,102 # 800181d8 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	9cc080e7          	jalr	-1588(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003182:	0001d797          	auipc	a5,0x1d
    80003186:	05678793          	addi	a5,a5,86 # 800201d8 <bcache+0x8000>
    8000318a:	0001d717          	auipc	a4,0x1d
    8000318e:	2b670713          	addi	a4,a4,694 # 80020440 <bcache+0x8268>
    80003192:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003196:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000319a:	00015497          	auipc	s1,0x15
    8000319e:	05648493          	addi	s1,s1,86 # 800181f0 <bcache+0x18>
    b->next = bcache.head.next;
    800031a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031a6:	00005a17          	auipc	s4,0x5
    800031aa:	382a0a13          	addi	s4,s4,898 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800031ae:	2b893783          	ld	a5,696(s2)
    800031b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031b8:	85d2                	mv	a1,s4
    800031ba:	01048513          	addi	a0,s1,16
    800031be:	00001097          	auipc	ra,0x1
    800031c2:	4c8080e7          	jalr	1224(ra) # 80004686 <initsleeplock>
    bcache.head.next->prev = b;
    800031c6:	2b893783          	ld	a5,696(s2)
    800031ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031d0:	45848493          	addi	s1,s1,1112
    800031d4:	fd349de3          	bne	s1,s3,800031ae <binit+0x54>
  }
}
    800031d8:	70a2                	ld	ra,40(sp)
    800031da:	7402                	ld	s0,32(sp)
    800031dc:	64e2                	ld	s1,24(sp)
    800031de:	6942                	ld	s2,16(sp)
    800031e0:	69a2                	ld	s3,8(sp)
    800031e2:	6a02                	ld	s4,0(sp)
    800031e4:	6145                	addi	sp,sp,48
    800031e6:	8082                	ret

00000000800031e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031e8:	7179                	addi	sp,sp,-48
    800031ea:	f406                	sd	ra,40(sp)
    800031ec:	f022                	sd	s0,32(sp)
    800031ee:	ec26                	sd	s1,24(sp)
    800031f0:	e84a                	sd	s2,16(sp)
    800031f2:	e44e                	sd	s3,8(sp)
    800031f4:	1800                	addi	s0,sp,48
    800031f6:	892a                	mv	s2,a0
    800031f8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031fa:	00015517          	auipc	a0,0x15
    800031fe:	fde50513          	addi	a0,a0,-34 # 800181d8 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	9d4080e7          	jalr	-1580(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000320a:	0001d497          	auipc	s1,0x1d
    8000320e:	2864b483          	ld	s1,646(s1) # 80020490 <bcache+0x82b8>
    80003212:	0001d797          	auipc	a5,0x1d
    80003216:	22e78793          	addi	a5,a5,558 # 80020440 <bcache+0x8268>
    8000321a:	02f48f63          	beq	s1,a5,80003258 <bread+0x70>
    8000321e:	873e                	mv	a4,a5
    80003220:	a021                	j	80003228 <bread+0x40>
    80003222:	68a4                	ld	s1,80(s1)
    80003224:	02e48a63          	beq	s1,a4,80003258 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003228:	449c                	lw	a5,8(s1)
    8000322a:	ff279ce3          	bne	a5,s2,80003222 <bread+0x3a>
    8000322e:	44dc                	lw	a5,12(s1)
    80003230:	ff3799e3          	bne	a5,s3,80003222 <bread+0x3a>
      b->refcnt++;
    80003234:	40bc                	lw	a5,64(s1)
    80003236:	2785                	addiw	a5,a5,1
    80003238:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000323a:	00015517          	auipc	a0,0x15
    8000323e:	f9e50513          	addi	a0,a0,-98 # 800181d8 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	a48080e7          	jalr	-1464(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000324a:	01048513          	addi	a0,s1,16
    8000324e:	00001097          	auipc	ra,0x1
    80003252:	472080e7          	jalr	1138(ra) # 800046c0 <acquiresleep>
      return b;
    80003256:	a8b9                	j	800032b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003258:	0001d497          	auipc	s1,0x1d
    8000325c:	2304b483          	ld	s1,560(s1) # 80020488 <bcache+0x82b0>
    80003260:	0001d797          	auipc	a5,0x1d
    80003264:	1e078793          	addi	a5,a5,480 # 80020440 <bcache+0x8268>
    80003268:	00f48863          	beq	s1,a5,80003278 <bread+0x90>
    8000326c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000326e:	40bc                	lw	a5,64(s1)
    80003270:	cf81                	beqz	a5,80003288 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003272:	64a4                	ld	s1,72(s1)
    80003274:	fee49de3          	bne	s1,a4,8000326e <bread+0x86>
  panic("bget: no buffers");
    80003278:	00005517          	auipc	a0,0x5
    8000327c:	2b850513          	addi	a0,a0,696 # 80008530 <syscalls+0xe0>
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	2c0080e7          	jalr	704(ra) # 80000540 <panic>
      b->dev = dev;
    80003288:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000328c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003290:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003294:	4785                	li	a5,1
    80003296:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003298:	00015517          	auipc	a0,0x15
    8000329c:	f4050513          	addi	a0,a0,-192 # 800181d8 <bcache>
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	9ea080e7          	jalr	-1558(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032a8:	01048513          	addi	a0,s1,16
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	414080e7          	jalr	1044(ra) # 800046c0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032b4:	409c                	lw	a5,0(s1)
    800032b6:	cb89                	beqz	a5,800032c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032b8:	8526                	mv	a0,s1
    800032ba:	70a2                	ld	ra,40(sp)
    800032bc:	7402                	ld	s0,32(sp)
    800032be:	64e2                	ld	s1,24(sp)
    800032c0:	6942                	ld	s2,16(sp)
    800032c2:	69a2                	ld	s3,8(sp)
    800032c4:	6145                	addi	sp,sp,48
    800032c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800032c8:	4581                	li	a1,0
    800032ca:	8526                	mv	a0,s1
    800032cc:	00003097          	auipc	ra,0x3
    800032d0:	fd6080e7          	jalr	-42(ra) # 800062a2 <virtio_disk_rw>
    b->valid = 1;
    800032d4:	4785                	li	a5,1
    800032d6:	c09c                	sw	a5,0(s1)
  return b;
    800032d8:	b7c5                	j	800032b8 <bread+0xd0>

00000000800032da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032da:	1101                	addi	sp,sp,-32
    800032dc:	ec06                	sd	ra,24(sp)
    800032de:	e822                	sd	s0,16(sp)
    800032e0:	e426                	sd	s1,8(sp)
    800032e2:	1000                	addi	s0,sp,32
    800032e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032e6:	0541                	addi	a0,a0,16
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	472080e7          	jalr	1138(ra) # 8000475a <holdingsleep>
    800032f0:	cd01                	beqz	a0,80003308 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032f2:	4585                	li	a1,1
    800032f4:	8526                	mv	a0,s1
    800032f6:	00003097          	auipc	ra,0x3
    800032fa:	fac080e7          	jalr	-84(ra) # 800062a2 <virtio_disk_rw>
}
    800032fe:	60e2                	ld	ra,24(sp)
    80003300:	6442                	ld	s0,16(sp)
    80003302:	64a2                	ld	s1,8(sp)
    80003304:	6105                	addi	sp,sp,32
    80003306:	8082                	ret
    panic("bwrite");
    80003308:	00005517          	auipc	a0,0x5
    8000330c:	24050513          	addi	a0,a0,576 # 80008548 <syscalls+0xf8>
    80003310:	ffffd097          	auipc	ra,0xffffd
    80003314:	230080e7          	jalr	560(ra) # 80000540 <panic>

0000000080003318 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003318:	1101                	addi	sp,sp,-32
    8000331a:	ec06                	sd	ra,24(sp)
    8000331c:	e822                	sd	s0,16(sp)
    8000331e:	e426                	sd	s1,8(sp)
    80003320:	e04a                	sd	s2,0(sp)
    80003322:	1000                	addi	s0,sp,32
    80003324:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003326:	01050913          	addi	s2,a0,16
    8000332a:	854a                	mv	a0,s2
    8000332c:	00001097          	auipc	ra,0x1
    80003330:	42e080e7          	jalr	1070(ra) # 8000475a <holdingsleep>
    80003334:	c92d                	beqz	a0,800033a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003336:	854a                	mv	a0,s2
    80003338:	00001097          	auipc	ra,0x1
    8000333c:	3de080e7          	jalr	990(ra) # 80004716 <releasesleep>

  acquire(&bcache.lock);
    80003340:	00015517          	auipc	a0,0x15
    80003344:	e9850513          	addi	a0,a0,-360 # 800181d8 <bcache>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	88e080e7          	jalr	-1906(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003350:	40bc                	lw	a5,64(s1)
    80003352:	37fd                	addiw	a5,a5,-1
    80003354:	0007871b          	sext.w	a4,a5
    80003358:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000335a:	eb05                	bnez	a4,8000338a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000335c:	68bc                	ld	a5,80(s1)
    8000335e:	64b8                	ld	a4,72(s1)
    80003360:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003362:	64bc                	ld	a5,72(s1)
    80003364:	68b8                	ld	a4,80(s1)
    80003366:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003368:	0001d797          	auipc	a5,0x1d
    8000336c:	e7078793          	addi	a5,a5,-400 # 800201d8 <bcache+0x8000>
    80003370:	2b87b703          	ld	a4,696(a5)
    80003374:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003376:	0001d717          	auipc	a4,0x1d
    8000337a:	0ca70713          	addi	a4,a4,202 # 80020440 <bcache+0x8268>
    8000337e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003380:	2b87b703          	ld	a4,696(a5)
    80003384:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003386:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000338a:	00015517          	auipc	a0,0x15
    8000338e:	e4e50513          	addi	a0,a0,-434 # 800181d8 <bcache>
    80003392:	ffffe097          	auipc	ra,0xffffe
    80003396:	8f8080e7          	jalr	-1800(ra) # 80000c8a <release>
}
    8000339a:	60e2                	ld	ra,24(sp)
    8000339c:	6442                	ld	s0,16(sp)
    8000339e:	64a2                	ld	s1,8(sp)
    800033a0:	6902                	ld	s2,0(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret
    panic("brelse");
    800033a6:	00005517          	auipc	a0,0x5
    800033aa:	1aa50513          	addi	a0,a0,426 # 80008550 <syscalls+0x100>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	192080e7          	jalr	402(ra) # 80000540 <panic>

00000000800033b6 <bpin>:

void
bpin(struct buf *b) {
    800033b6:	1101                	addi	sp,sp,-32
    800033b8:	ec06                	sd	ra,24(sp)
    800033ba:	e822                	sd	s0,16(sp)
    800033bc:	e426                	sd	s1,8(sp)
    800033be:	1000                	addi	s0,sp,32
    800033c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033c2:	00015517          	auipc	a0,0x15
    800033c6:	e1650513          	addi	a0,a0,-490 # 800181d8 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	80c080e7          	jalr	-2036(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800033d2:	40bc                	lw	a5,64(s1)
    800033d4:	2785                	addiw	a5,a5,1
    800033d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d8:	00015517          	auipc	a0,0x15
    800033dc:	e0050513          	addi	a0,a0,-512 # 800181d8 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <bunpin>:

void
bunpin(struct buf *b) {
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	e426                	sd	s1,8(sp)
    800033fa:	1000                	addi	s0,sp,32
    800033fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033fe:	00015517          	auipc	a0,0x15
    80003402:	dda50513          	addi	a0,a0,-550 # 800181d8 <bcache>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	7d0080e7          	jalr	2000(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000340e:	40bc                	lw	a5,64(s1)
    80003410:	37fd                	addiw	a5,a5,-1
    80003412:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003414:	00015517          	auipc	a0,0x15
    80003418:	dc450513          	addi	a0,a0,-572 # 800181d8 <bcache>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	86e080e7          	jalr	-1938(ra) # 80000c8a <release>
}
    80003424:	60e2                	ld	ra,24(sp)
    80003426:	6442                	ld	s0,16(sp)
    80003428:	64a2                	ld	s1,8(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret

000000008000342e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000342e:	1101                	addi	sp,sp,-32
    80003430:	ec06                	sd	ra,24(sp)
    80003432:	e822                	sd	s0,16(sp)
    80003434:	e426                	sd	s1,8(sp)
    80003436:	e04a                	sd	s2,0(sp)
    80003438:	1000                	addi	s0,sp,32
    8000343a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000343c:	00d5d59b          	srliw	a1,a1,0xd
    80003440:	0001d797          	auipc	a5,0x1d
    80003444:	4747a783          	lw	a5,1140(a5) # 800208b4 <sb+0x1c>
    80003448:	9dbd                	addw	a1,a1,a5
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	d9e080e7          	jalr	-610(ra) # 800031e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003452:	0074f713          	andi	a4,s1,7
    80003456:	4785                	li	a5,1
    80003458:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000345c:	14ce                	slli	s1,s1,0x33
    8000345e:	90d9                	srli	s1,s1,0x36
    80003460:	00950733          	add	a4,a0,s1
    80003464:	05874703          	lbu	a4,88(a4)
    80003468:	00e7f6b3          	and	a3,a5,a4
    8000346c:	c69d                	beqz	a3,8000349a <bfree+0x6c>
    8000346e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003470:	94aa                	add	s1,s1,a0
    80003472:	fff7c793          	not	a5,a5
    80003476:	8f7d                	and	a4,a4,a5
    80003478:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	126080e7          	jalr	294(ra) # 800045a2 <log_write>
  brelse(bp);
    80003484:	854a                	mv	a0,s2
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	e92080e7          	jalr	-366(ra) # 80003318 <brelse>
}
    8000348e:	60e2                	ld	ra,24(sp)
    80003490:	6442                	ld	s0,16(sp)
    80003492:	64a2                	ld	s1,8(sp)
    80003494:	6902                	ld	s2,0(sp)
    80003496:	6105                	addi	sp,sp,32
    80003498:	8082                	ret
    panic("freeing free block");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	0be50513          	addi	a0,a0,190 # 80008558 <syscalls+0x108>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	09e080e7          	jalr	158(ra) # 80000540 <panic>

00000000800034aa <balloc>:
{
    800034aa:	711d                	addi	sp,sp,-96
    800034ac:	ec86                	sd	ra,88(sp)
    800034ae:	e8a2                	sd	s0,80(sp)
    800034b0:	e4a6                	sd	s1,72(sp)
    800034b2:	e0ca                	sd	s2,64(sp)
    800034b4:	fc4e                	sd	s3,56(sp)
    800034b6:	f852                	sd	s4,48(sp)
    800034b8:	f456                	sd	s5,40(sp)
    800034ba:	f05a                	sd	s6,32(sp)
    800034bc:	ec5e                	sd	s7,24(sp)
    800034be:	e862                	sd	s8,16(sp)
    800034c0:	e466                	sd	s9,8(sp)
    800034c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034c4:	0001d797          	auipc	a5,0x1d
    800034c8:	3d87a783          	lw	a5,984(a5) # 8002089c <sb+0x4>
    800034cc:	cff5                	beqz	a5,800035c8 <balloc+0x11e>
    800034ce:	8baa                	mv	s7,a0
    800034d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034d2:	0001db17          	auipc	s6,0x1d
    800034d6:	3c6b0b13          	addi	s6,s6,966 # 80020898 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034e0:	6c89                	lui	s9,0x2
    800034e2:	a061                	j	8000356a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034e4:	97ca                	add	a5,a5,s2
    800034e6:	8e55                	or	a2,a2,a3
    800034e8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034ec:	854a                	mv	a0,s2
    800034ee:	00001097          	auipc	ra,0x1
    800034f2:	0b4080e7          	jalr	180(ra) # 800045a2 <log_write>
        brelse(bp);
    800034f6:	854a                	mv	a0,s2
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	e20080e7          	jalr	-480(ra) # 80003318 <brelse>
  bp = bread(dev, bno);
    80003500:	85a6                	mv	a1,s1
    80003502:	855e                	mv	a0,s7
    80003504:	00000097          	auipc	ra,0x0
    80003508:	ce4080e7          	jalr	-796(ra) # 800031e8 <bread>
    8000350c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000350e:	40000613          	li	a2,1024
    80003512:	4581                	li	a1,0
    80003514:	05850513          	addi	a0,a0,88
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	7ba080e7          	jalr	1978(ra) # 80000cd2 <memset>
  log_write(bp);
    80003520:	854a                	mv	a0,s2
    80003522:	00001097          	auipc	ra,0x1
    80003526:	080080e7          	jalr	128(ra) # 800045a2 <log_write>
  brelse(bp);
    8000352a:	854a                	mv	a0,s2
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	dec080e7          	jalr	-532(ra) # 80003318 <brelse>
}
    80003534:	8526                	mv	a0,s1
    80003536:	60e6                	ld	ra,88(sp)
    80003538:	6446                	ld	s0,80(sp)
    8000353a:	64a6                	ld	s1,72(sp)
    8000353c:	6906                	ld	s2,64(sp)
    8000353e:	79e2                	ld	s3,56(sp)
    80003540:	7a42                	ld	s4,48(sp)
    80003542:	7aa2                	ld	s5,40(sp)
    80003544:	7b02                	ld	s6,32(sp)
    80003546:	6be2                	ld	s7,24(sp)
    80003548:	6c42                	ld	s8,16(sp)
    8000354a:	6ca2                	ld	s9,8(sp)
    8000354c:	6125                	addi	sp,sp,96
    8000354e:	8082                	ret
    brelse(bp);
    80003550:	854a                	mv	a0,s2
    80003552:	00000097          	auipc	ra,0x0
    80003556:	dc6080e7          	jalr	-570(ra) # 80003318 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000355a:	015c87bb          	addw	a5,s9,s5
    8000355e:	00078a9b          	sext.w	s5,a5
    80003562:	004b2703          	lw	a4,4(s6)
    80003566:	06eaf163          	bgeu	s5,a4,800035c8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000356a:	41fad79b          	sraiw	a5,s5,0x1f
    8000356e:	0137d79b          	srliw	a5,a5,0x13
    80003572:	015787bb          	addw	a5,a5,s5
    80003576:	40d7d79b          	sraiw	a5,a5,0xd
    8000357a:	01cb2583          	lw	a1,28(s6)
    8000357e:	9dbd                	addw	a1,a1,a5
    80003580:	855e                	mv	a0,s7
    80003582:	00000097          	auipc	ra,0x0
    80003586:	c66080e7          	jalr	-922(ra) # 800031e8 <bread>
    8000358a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000358c:	004b2503          	lw	a0,4(s6)
    80003590:	000a849b          	sext.w	s1,s5
    80003594:	8762                	mv	a4,s8
    80003596:	faa4fde3          	bgeu	s1,a0,80003550 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000359a:	00777693          	andi	a3,a4,7
    8000359e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035a2:	41f7579b          	sraiw	a5,a4,0x1f
    800035a6:	01d7d79b          	srliw	a5,a5,0x1d
    800035aa:	9fb9                	addw	a5,a5,a4
    800035ac:	4037d79b          	sraiw	a5,a5,0x3
    800035b0:	00f90633          	add	a2,s2,a5
    800035b4:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800035b8:	00c6f5b3          	and	a1,a3,a2
    800035bc:	d585                	beqz	a1,800034e4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035be:	2705                	addiw	a4,a4,1
    800035c0:	2485                	addiw	s1,s1,1
    800035c2:	fd471ae3          	bne	a4,s4,80003596 <balloc+0xec>
    800035c6:	b769                	j	80003550 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800035c8:	00005517          	auipc	a0,0x5
    800035cc:	fa850513          	addi	a0,a0,-88 # 80008570 <syscalls+0x120>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	fba080e7          	jalr	-70(ra) # 8000058a <printf>
  return 0;
    800035d8:	4481                	li	s1,0
    800035da:	bfa9                	j	80003534 <balloc+0x8a>

00000000800035dc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035dc:	7179                	addi	sp,sp,-48
    800035de:	f406                	sd	ra,40(sp)
    800035e0:	f022                	sd	s0,32(sp)
    800035e2:	ec26                	sd	s1,24(sp)
    800035e4:	e84a                	sd	s2,16(sp)
    800035e6:	e44e                	sd	s3,8(sp)
    800035e8:	e052                	sd	s4,0(sp)
    800035ea:	1800                	addi	s0,sp,48
    800035ec:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035ee:	47ad                	li	a5,11
    800035f0:	02b7e863          	bltu	a5,a1,80003620 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035f4:	02059793          	slli	a5,a1,0x20
    800035f8:	01e7d593          	srli	a1,a5,0x1e
    800035fc:	00b504b3          	add	s1,a0,a1
    80003600:	0504a903          	lw	s2,80(s1)
    80003604:	06091e63          	bnez	s2,80003680 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003608:	4108                	lw	a0,0(a0)
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	ea0080e7          	jalr	-352(ra) # 800034aa <balloc>
    80003612:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003616:	06090563          	beqz	s2,80003680 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000361a:	0524a823          	sw	s2,80(s1)
    8000361e:	a08d                	j	80003680 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003620:	ff45849b          	addiw	s1,a1,-12
    80003624:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003628:	0ff00793          	li	a5,255
    8000362c:	08e7e563          	bltu	a5,a4,800036b6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003630:	08052903          	lw	s2,128(a0)
    80003634:	00091d63          	bnez	s2,8000364e <bmap+0x72>
      addr = balloc(ip->dev);
    80003638:	4108                	lw	a0,0(a0)
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	e70080e7          	jalr	-400(ra) # 800034aa <balloc>
    80003642:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003646:	02090d63          	beqz	s2,80003680 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000364a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000364e:	85ca                	mv	a1,s2
    80003650:	0009a503          	lw	a0,0(s3)
    80003654:	00000097          	auipc	ra,0x0
    80003658:	b94080e7          	jalr	-1132(ra) # 800031e8 <bread>
    8000365c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000365e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003662:	02049713          	slli	a4,s1,0x20
    80003666:	01e75593          	srli	a1,a4,0x1e
    8000366a:	00b784b3          	add	s1,a5,a1
    8000366e:	0004a903          	lw	s2,0(s1)
    80003672:	02090063          	beqz	s2,80003692 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003676:	8552                	mv	a0,s4
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	ca0080e7          	jalr	-864(ra) # 80003318 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003680:	854a                	mv	a0,s2
    80003682:	70a2                	ld	ra,40(sp)
    80003684:	7402                	ld	s0,32(sp)
    80003686:	64e2                	ld	s1,24(sp)
    80003688:	6942                	ld	s2,16(sp)
    8000368a:	69a2                	ld	s3,8(sp)
    8000368c:	6a02                	ld	s4,0(sp)
    8000368e:	6145                	addi	sp,sp,48
    80003690:	8082                	ret
      addr = balloc(ip->dev);
    80003692:	0009a503          	lw	a0,0(s3)
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	e14080e7          	jalr	-492(ra) # 800034aa <balloc>
    8000369e:	0005091b          	sext.w	s2,a0
      if(addr){
    800036a2:	fc090ae3          	beqz	s2,80003676 <bmap+0x9a>
        a[bn] = addr;
    800036a6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036aa:	8552                	mv	a0,s4
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	ef6080e7          	jalr	-266(ra) # 800045a2 <log_write>
    800036b4:	b7c9                	j	80003676 <bmap+0x9a>
  panic("bmap: out of range");
    800036b6:	00005517          	auipc	a0,0x5
    800036ba:	ed250513          	addi	a0,a0,-302 # 80008588 <syscalls+0x138>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	e82080e7          	jalr	-382(ra) # 80000540 <panic>

00000000800036c6 <iget>:
{
    800036c6:	7179                	addi	sp,sp,-48
    800036c8:	f406                	sd	ra,40(sp)
    800036ca:	f022                	sd	s0,32(sp)
    800036cc:	ec26                	sd	s1,24(sp)
    800036ce:	e84a                	sd	s2,16(sp)
    800036d0:	e44e                	sd	s3,8(sp)
    800036d2:	e052                	sd	s4,0(sp)
    800036d4:	1800                	addi	s0,sp,48
    800036d6:	89aa                	mv	s3,a0
    800036d8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036da:	0001d517          	auipc	a0,0x1d
    800036de:	1de50513          	addi	a0,a0,478 # 800208b8 <itable>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	4f4080e7          	jalr	1268(ra) # 80000bd6 <acquire>
  empty = 0;
    800036ea:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ec:	0001d497          	auipc	s1,0x1d
    800036f0:	1e448493          	addi	s1,s1,484 # 800208d0 <itable+0x18>
    800036f4:	0001f697          	auipc	a3,0x1f
    800036f8:	c6c68693          	addi	a3,a3,-916 # 80022360 <log>
    800036fc:	a039                	j	8000370a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036fe:	02090b63          	beqz	s2,80003734 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003702:	08848493          	addi	s1,s1,136
    80003706:	02d48a63          	beq	s1,a3,8000373a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000370a:	449c                	lw	a5,8(s1)
    8000370c:	fef059e3          	blez	a5,800036fe <iget+0x38>
    80003710:	4098                	lw	a4,0(s1)
    80003712:	ff3716e3          	bne	a4,s3,800036fe <iget+0x38>
    80003716:	40d8                	lw	a4,4(s1)
    80003718:	ff4713e3          	bne	a4,s4,800036fe <iget+0x38>
      ip->ref++;
    8000371c:	2785                	addiw	a5,a5,1
    8000371e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003720:	0001d517          	auipc	a0,0x1d
    80003724:	19850513          	addi	a0,a0,408 # 800208b8 <itable>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	562080e7          	jalr	1378(ra) # 80000c8a <release>
      return ip;
    80003730:	8926                	mv	s2,s1
    80003732:	a03d                	j	80003760 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003734:	f7f9                	bnez	a5,80003702 <iget+0x3c>
    80003736:	8926                	mv	s2,s1
    80003738:	b7e9                	j	80003702 <iget+0x3c>
  if(empty == 0)
    8000373a:	02090c63          	beqz	s2,80003772 <iget+0xac>
  ip->dev = dev;
    8000373e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003742:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003746:	4785                	li	a5,1
    80003748:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000374c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003750:	0001d517          	auipc	a0,0x1d
    80003754:	16850513          	addi	a0,a0,360 # 800208b8 <itable>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	532080e7          	jalr	1330(ra) # 80000c8a <release>
}
    80003760:	854a                	mv	a0,s2
    80003762:	70a2                	ld	ra,40(sp)
    80003764:	7402                	ld	s0,32(sp)
    80003766:	64e2                	ld	s1,24(sp)
    80003768:	6942                	ld	s2,16(sp)
    8000376a:	69a2                	ld	s3,8(sp)
    8000376c:	6a02                	ld	s4,0(sp)
    8000376e:	6145                	addi	sp,sp,48
    80003770:	8082                	ret
    panic("iget: no inodes");
    80003772:	00005517          	auipc	a0,0x5
    80003776:	e2e50513          	addi	a0,a0,-466 # 800085a0 <syscalls+0x150>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	dc6080e7          	jalr	-570(ra) # 80000540 <panic>

0000000080003782 <fsinit>:
fsinit(int dev) {
    80003782:	7179                	addi	sp,sp,-48
    80003784:	f406                	sd	ra,40(sp)
    80003786:	f022                	sd	s0,32(sp)
    80003788:	ec26                	sd	s1,24(sp)
    8000378a:	e84a                	sd	s2,16(sp)
    8000378c:	e44e                	sd	s3,8(sp)
    8000378e:	1800                	addi	s0,sp,48
    80003790:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003792:	4585                	li	a1,1
    80003794:	00000097          	auipc	ra,0x0
    80003798:	a54080e7          	jalr	-1452(ra) # 800031e8 <bread>
    8000379c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000379e:	0001d997          	auipc	s3,0x1d
    800037a2:	0fa98993          	addi	s3,s3,250 # 80020898 <sb>
    800037a6:	02000613          	li	a2,32
    800037aa:	05850593          	addi	a1,a0,88
    800037ae:	854e                	mv	a0,s3
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	57e080e7          	jalr	1406(ra) # 80000d2e <memmove>
  brelse(bp);
    800037b8:	8526                	mv	a0,s1
    800037ba:	00000097          	auipc	ra,0x0
    800037be:	b5e080e7          	jalr	-1186(ra) # 80003318 <brelse>
  if(sb.magic != FSMAGIC)
    800037c2:	0009a703          	lw	a4,0(s3)
    800037c6:	102037b7          	lui	a5,0x10203
    800037ca:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037ce:	02f71263          	bne	a4,a5,800037f2 <fsinit+0x70>
  initlog(dev, &sb);
    800037d2:	0001d597          	auipc	a1,0x1d
    800037d6:	0c658593          	addi	a1,a1,198 # 80020898 <sb>
    800037da:	854a                	mv	a0,s2
    800037dc:	00001097          	auipc	ra,0x1
    800037e0:	b4a080e7          	jalr	-1206(ra) # 80004326 <initlog>
}
    800037e4:	70a2                	ld	ra,40(sp)
    800037e6:	7402                	ld	s0,32(sp)
    800037e8:	64e2                	ld	s1,24(sp)
    800037ea:	6942                	ld	s2,16(sp)
    800037ec:	69a2                	ld	s3,8(sp)
    800037ee:	6145                	addi	sp,sp,48
    800037f0:	8082                	ret
    panic("invalid file system");
    800037f2:	00005517          	auipc	a0,0x5
    800037f6:	dbe50513          	addi	a0,a0,-578 # 800085b0 <syscalls+0x160>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d46080e7          	jalr	-698(ra) # 80000540 <panic>

0000000080003802 <iinit>:
{
    80003802:	7179                	addi	sp,sp,-48
    80003804:	f406                	sd	ra,40(sp)
    80003806:	f022                	sd	s0,32(sp)
    80003808:	ec26                	sd	s1,24(sp)
    8000380a:	e84a                	sd	s2,16(sp)
    8000380c:	e44e                	sd	s3,8(sp)
    8000380e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003810:	00005597          	auipc	a1,0x5
    80003814:	db858593          	addi	a1,a1,-584 # 800085c8 <syscalls+0x178>
    80003818:	0001d517          	auipc	a0,0x1d
    8000381c:	0a050513          	addi	a0,a0,160 # 800208b8 <itable>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	326080e7          	jalr	806(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003828:	0001d497          	auipc	s1,0x1d
    8000382c:	0b848493          	addi	s1,s1,184 # 800208e0 <itable+0x28>
    80003830:	0001f997          	auipc	s3,0x1f
    80003834:	b4098993          	addi	s3,s3,-1216 # 80022370 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003838:	00005917          	auipc	s2,0x5
    8000383c:	d9890913          	addi	s2,s2,-616 # 800085d0 <syscalls+0x180>
    80003840:	85ca                	mv	a1,s2
    80003842:	8526                	mv	a0,s1
    80003844:	00001097          	auipc	ra,0x1
    80003848:	e42080e7          	jalr	-446(ra) # 80004686 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000384c:	08848493          	addi	s1,s1,136
    80003850:	ff3498e3          	bne	s1,s3,80003840 <iinit+0x3e>
}
    80003854:	70a2                	ld	ra,40(sp)
    80003856:	7402                	ld	s0,32(sp)
    80003858:	64e2                	ld	s1,24(sp)
    8000385a:	6942                	ld	s2,16(sp)
    8000385c:	69a2                	ld	s3,8(sp)
    8000385e:	6145                	addi	sp,sp,48
    80003860:	8082                	ret

0000000080003862 <ialloc>:
{
    80003862:	715d                	addi	sp,sp,-80
    80003864:	e486                	sd	ra,72(sp)
    80003866:	e0a2                	sd	s0,64(sp)
    80003868:	fc26                	sd	s1,56(sp)
    8000386a:	f84a                	sd	s2,48(sp)
    8000386c:	f44e                	sd	s3,40(sp)
    8000386e:	f052                	sd	s4,32(sp)
    80003870:	ec56                	sd	s5,24(sp)
    80003872:	e85a                	sd	s6,16(sp)
    80003874:	e45e                	sd	s7,8(sp)
    80003876:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003878:	0001d717          	auipc	a4,0x1d
    8000387c:	02c72703          	lw	a4,44(a4) # 800208a4 <sb+0xc>
    80003880:	4785                	li	a5,1
    80003882:	04e7fa63          	bgeu	a5,a4,800038d6 <ialloc+0x74>
    80003886:	8aaa                	mv	s5,a0
    80003888:	8bae                	mv	s7,a1
    8000388a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000388c:	0001da17          	auipc	s4,0x1d
    80003890:	00ca0a13          	addi	s4,s4,12 # 80020898 <sb>
    80003894:	00048b1b          	sext.w	s6,s1
    80003898:	0044d593          	srli	a1,s1,0x4
    8000389c:	018a2783          	lw	a5,24(s4)
    800038a0:	9dbd                	addw	a1,a1,a5
    800038a2:	8556                	mv	a0,s5
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	944080e7          	jalr	-1724(ra) # 800031e8 <bread>
    800038ac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038ae:	05850993          	addi	s3,a0,88
    800038b2:	00f4f793          	andi	a5,s1,15
    800038b6:	079a                	slli	a5,a5,0x6
    800038b8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038ba:	00099783          	lh	a5,0(s3)
    800038be:	c3a1                	beqz	a5,800038fe <ialloc+0x9c>
    brelse(bp);
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	a58080e7          	jalr	-1448(ra) # 80003318 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038c8:	0485                	addi	s1,s1,1
    800038ca:	00ca2703          	lw	a4,12(s4)
    800038ce:	0004879b          	sext.w	a5,s1
    800038d2:	fce7e1e3          	bltu	a5,a4,80003894 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038d6:	00005517          	auipc	a0,0x5
    800038da:	d0250513          	addi	a0,a0,-766 # 800085d8 <syscalls+0x188>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	cac080e7          	jalr	-852(ra) # 8000058a <printf>
  return 0;
    800038e6:	4501                	li	a0,0
}
    800038e8:	60a6                	ld	ra,72(sp)
    800038ea:	6406                	ld	s0,64(sp)
    800038ec:	74e2                	ld	s1,56(sp)
    800038ee:	7942                	ld	s2,48(sp)
    800038f0:	79a2                	ld	s3,40(sp)
    800038f2:	7a02                	ld	s4,32(sp)
    800038f4:	6ae2                	ld	s5,24(sp)
    800038f6:	6b42                	ld	s6,16(sp)
    800038f8:	6ba2                	ld	s7,8(sp)
    800038fa:	6161                	addi	sp,sp,80
    800038fc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038fe:	04000613          	li	a2,64
    80003902:	4581                	li	a1,0
    80003904:	854e                	mv	a0,s3
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	3cc080e7          	jalr	972(ra) # 80000cd2 <memset>
      dip->type = type;
    8000390e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003912:	854a                	mv	a0,s2
    80003914:	00001097          	auipc	ra,0x1
    80003918:	c8e080e7          	jalr	-882(ra) # 800045a2 <log_write>
      brelse(bp);
    8000391c:	854a                	mv	a0,s2
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	9fa080e7          	jalr	-1542(ra) # 80003318 <brelse>
      return iget(dev, inum);
    80003926:	85da                	mv	a1,s6
    80003928:	8556                	mv	a0,s5
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	d9c080e7          	jalr	-612(ra) # 800036c6 <iget>
    80003932:	bf5d                	j	800038e8 <ialloc+0x86>

0000000080003934 <iupdate>:
{
    80003934:	1101                	addi	sp,sp,-32
    80003936:	ec06                	sd	ra,24(sp)
    80003938:	e822                	sd	s0,16(sp)
    8000393a:	e426                	sd	s1,8(sp)
    8000393c:	e04a                	sd	s2,0(sp)
    8000393e:	1000                	addi	s0,sp,32
    80003940:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003942:	415c                	lw	a5,4(a0)
    80003944:	0047d79b          	srliw	a5,a5,0x4
    80003948:	0001d597          	auipc	a1,0x1d
    8000394c:	f685a583          	lw	a1,-152(a1) # 800208b0 <sb+0x18>
    80003950:	9dbd                	addw	a1,a1,a5
    80003952:	4108                	lw	a0,0(a0)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	894080e7          	jalr	-1900(ra) # 800031e8 <bread>
    8000395c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395e:	05850793          	addi	a5,a0,88
    80003962:	40d8                	lw	a4,4(s1)
    80003964:	8b3d                	andi	a4,a4,15
    80003966:	071a                	slli	a4,a4,0x6
    80003968:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000396a:	04449703          	lh	a4,68(s1)
    8000396e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003972:	04649703          	lh	a4,70(s1)
    80003976:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000397a:	04849703          	lh	a4,72(s1)
    8000397e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003982:	04a49703          	lh	a4,74(s1)
    80003986:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000398a:	44f8                	lw	a4,76(s1)
    8000398c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000398e:	03400613          	li	a2,52
    80003992:	05048593          	addi	a1,s1,80
    80003996:	00c78513          	addi	a0,a5,12
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	394080e7          	jalr	916(ra) # 80000d2e <memmove>
  log_write(bp);
    800039a2:	854a                	mv	a0,s2
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	bfe080e7          	jalr	-1026(ra) # 800045a2 <log_write>
  brelse(bp);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	96a080e7          	jalr	-1686(ra) # 80003318 <brelse>
}
    800039b6:	60e2                	ld	ra,24(sp)
    800039b8:	6442                	ld	s0,16(sp)
    800039ba:	64a2                	ld	s1,8(sp)
    800039bc:	6902                	ld	s2,0(sp)
    800039be:	6105                	addi	sp,sp,32
    800039c0:	8082                	ret

00000000800039c2 <idup>:
{
    800039c2:	1101                	addi	sp,sp,-32
    800039c4:	ec06                	sd	ra,24(sp)
    800039c6:	e822                	sd	s0,16(sp)
    800039c8:	e426                	sd	s1,8(sp)
    800039ca:	1000                	addi	s0,sp,32
    800039cc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ce:	0001d517          	auipc	a0,0x1d
    800039d2:	eea50513          	addi	a0,a0,-278 # 800208b8 <itable>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	200080e7          	jalr	512(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039de:	449c                	lw	a5,8(s1)
    800039e0:	2785                	addiw	a5,a5,1
    800039e2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039e4:	0001d517          	auipc	a0,0x1d
    800039e8:	ed450513          	addi	a0,a0,-300 # 800208b8 <itable>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	29e080e7          	jalr	670(ra) # 80000c8a <release>
}
    800039f4:	8526                	mv	a0,s1
    800039f6:	60e2                	ld	ra,24(sp)
    800039f8:	6442                	ld	s0,16(sp)
    800039fa:	64a2                	ld	s1,8(sp)
    800039fc:	6105                	addi	sp,sp,32
    800039fe:	8082                	ret

0000000080003a00 <ilock>:
{
    80003a00:	1101                	addi	sp,sp,-32
    80003a02:	ec06                	sd	ra,24(sp)
    80003a04:	e822                	sd	s0,16(sp)
    80003a06:	e426                	sd	s1,8(sp)
    80003a08:	e04a                	sd	s2,0(sp)
    80003a0a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a0c:	c115                	beqz	a0,80003a30 <ilock+0x30>
    80003a0e:	84aa                	mv	s1,a0
    80003a10:	451c                	lw	a5,8(a0)
    80003a12:	00f05f63          	blez	a5,80003a30 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a16:	0541                	addi	a0,a0,16
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	ca8080e7          	jalr	-856(ra) # 800046c0 <acquiresleep>
  if(ip->valid == 0){
    80003a20:	40bc                	lw	a5,64(s1)
    80003a22:	cf99                	beqz	a5,80003a40 <ilock+0x40>
}
    80003a24:	60e2                	ld	ra,24(sp)
    80003a26:	6442                	ld	s0,16(sp)
    80003a28:	64a2                	ld	s1,8(sp)
    80003a2a:	6902                	ld	s2,0(sp)
    80003a2c:	6105                	addi	sp,sp,32
    80003a2e:	8082                	ret
    panic("ilock");
    80003a30:	00005517          	auipc	a0,0x5
    80003a34:	bc050513          	addi	a0,a0,-1088 # 800085f0 <syscalls+0x1a0>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	b08080e7          	jalr	-1272(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a40:	40dc                	lw	a5,4(s1)
    80003a42:	0047d79b          	srliw	a5,a5,0x4
    80003a46:	0001d597          	auipc	a1,0x1d
    80003a4a:	e6a5a583          	lw	a1,-406(a1) # 800208b0 <sb+0x18>
    80003a4e:	9dbd                	addw	a1,a1,a5
    80003a50:	4088                	lw	a0,0(s1)
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	796080e7          	jalr	1942(ra) # 800031e8 <bread>
    80003a5a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a5c:	05850593          	addi	a1,a0,88
    80003a60:	40dc                	lw	a5,4(s1)
    80003a62:	8bbd                	andi	a5,a5,15
    80003a64:	079a                	slli	a5,a5,0x6
    80003a66:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a68:	00059783          	lh	a5,0(a1)
    80003a6c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a70:	00259783          	lh	a5,2(a1)
    80003a74:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a78:	00459783          	lh	a5,4(a1)
    80003a7c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a80:	00659783          	lh	a5,6(a1)
    80003a84:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a88:	459c                	lw	a5,8(a1)
    80003a8a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a8c:	03400613          	li	a2,52
    80003a90:	05b1                	addi	a1,a1,12
    80003a92:	05048513          	addi	a0,s1,80
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	298080e7          	jalr	664(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a9e:	854a                	mv	a0,s2
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	878080e7          	jalr	-1928(ra) # 80003318 <brelse>
    ip->valid = 1;
    80003aa8:	4785                	li	a5,1
    80003aaa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003aac:	04449783          	lh	a5,68(s1)
    80003ab0:	fbb5                	bnez	a5,80003a24 <ilock+0x24>
      panic("ilock: no type");
    80003ab2:	00005517          	auipc	a0,0x5
    80003ab6:	b4650513          	addi	a0,a0,-1210 # 800085f8 <syscalls+0x1a8>
    80003aba:	ffffd097          	auipc	ra,0xffffd
    80003abe:	a86080e7          	jalr	-1402(ra) # 80000540 <panic>

0000000080003ac2 <iunlock>:
{
    80003ac2:	1101                	addi	sp,sp,-32
    80003ac4:	ec06                	sd	ra,24(sp)
    80003ac6:	e822                	sd	s0,16(sp)
    80003ac8:	e426                	sd	s1,8(sp)
    80003aca:	e04a                	sd	s2,0(sp)
    80003acc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ace:	c905                	beqz	a0,80003afe <iunlock+0x3c>
    80003ad0:	84aa                	mv	s1,a0
    80003ad2:	01050913          	addi	s2,a0,16
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	00001097          	auipc	ra,0x1
    80003adc:	c82080e7          	jalr	-894(ra) # 8000475a <holdingsleep>
    80003ae0:	cd19                	beqz	a0,80003afe <iunlock+0x3c>
    80003ae2:	449c                	lw	a5,8(s1)
    80003ae4:	00f05d63          	blez	a5,80003afe <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ae8:	854a                	mv	a0,s2
    80003aea:	00001097          	auipc	ra,0x1
    80003aee:	c2c080e7          	jalr	-980(ra) # 80004716 <releasesleep>
}
    80003af2:	60e2                	ld	ra,24(sp)
    80003af4:	6442                	ld	s0,16(sp)
    80003af6:	64a2                	ld	s1,8(sp)
    80003af8:	6902                	ld	s2,0(sp)
    80003afa:	6105                	addi	sp,sp,32
    80003afc:	8082                	ret
    panic("iunlock");
    80003afe:	00005517          	auipc	a0,0x5
    80003b02:	b0a50513          	addi	a0,a0,-1270 # 80008608 <syscalls+0x1b8>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	a3a080e7          	jalr	-1478(ra) # 80000540 <panic>

0000000080003b0e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b0e:	7179                	addi	sp,sp,-48
    80003b10:	f406                	sd	ra,40(sp)
    80003b12:	f022                	sd	s0,32(sp)
    80003b14:	ec26                	sd	s1,24(sp)
    80003b16:	e84a                	sd	s2,16(sp)
    80003b18:	e44e                	sd	s3,8(sp)
    80003b1a:	e052                	sd	s4,0(sp)
    80003b1c:	1800                	addi	s0,sp,48
    80003b1e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b20:	05050493          	addi	s1,a0,80
    80003b24:	08050913          	addi	s2,a0,128
    80003b28:	a021                	j	80003b30 <itrunc+0x22>
    80003b2a:	0491                	addi	s1,s1,4
    80003b2c:	01248d63          	beq	s1,s2,80003b46 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b30:	408c                	lw	a1,0(s1)
    80003b32:	dde5                	beqz	a1,80003b2a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b34:	0009a503          	lw	a0,0(s3)
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	8f6080e7          	jalr	-1802(ra) # 8000342e <bfree>
      ip->addrs[i] = 0;
    80003b40:	0004a023          	sw	zero,0(s1)
    80003b44:	b7dd                	j	80003b2a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b46:	0809a583          	lw	a1,128(s3)
    80003b4a:	e185                	bnez	a1,80003b6a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b4c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b50:	854e                	mv	a0,s3
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	de2080e7          	jalr	-542(ra) # 80003934 <iupdate>
}
    80003b5a:	70a2                	ld	ra,40(sp)
    80003b5c:	7402                	ld	s0,32(sp)
    80003b5e:	64e2                	ld	s1,24(sp)
    80003b60:	6942                	ld	s2,16(sp)
    80003b62:	69a2                	ld	s3,8(sp)
    80003b64:	6a02                	ld	s4,0(sp)
    80003b66:	6145                	addi	sp,sp,48
    80003b68:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b6a:	0009a503          	lw	a0,0(s3)
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	67a080e7          	jalr	1658(ra) # 800031e8 <bread>
    80003b76:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b78:	05850493          	addi	s1,a0,88
    80003b7c:	45850913          	addi	s2,a0,1112
    80003b80:	a021                	j	80003b88 <itrunc+0x7a>
    80003b82:	0491                	addi	s1,s1,4
    80003b84:	01248b63          	beq	s1,s2,80003b9a <itrunc+0x8c>
      if(a[j])
    80003b88:	408c                	lw	a1,0(s1)
    80003b8a:	dde5                	beqz	a1,80003b82 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b8c:	0009a503          	lw	a0,0(s3)
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	89e080e7          	jalr	-1890(ra) # 8000342e <bfree>
    80003b98:	b7ed                	j	80003b82 <itrunc+0x74>
    brelse(bp);
    80003b9a:	8552                	mv	a0,s4
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	77c080e7          	jalr	1916(ra) # 80003318 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ba4:	0809a583          	lw	a1,128(s3)
    80003ba8:	0009a503          	lw	a0,0(s3)
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	882080e7          	jalr	-1918(ra) # 8000342e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bb4:	0809a023          	sw	zero,128(s3)
    80003bb8:	bf51                	j	80003b4c <itrunc+0x3e>

0000000080003bba <iput>:
{
    80003bba:	1101                	addi	sp,sp,-32
    80003bbc:	ec06                	sd	ra,24(sp)
    80003bbe:	e822                	sd	s0,16(sp)
    80003bc0:	e426                	sd	s1,8(sp)
    80003bc2:	e04a                	sd	s2,0(sp)
    80003bc4:	1000                	addi	s0,sp,32
    80003bc6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bc8:	0001d517          	auipc	a0,0x1d
    80003bcc:	cf050513          	addi	a0,a0,-784 # 800208b8 <itable>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	006080e7          	jalr	6(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd8:	4498                	lw	a4,8(s1)
    80003bda:	4785                	li	a5,1
    80003bdc:	02f70363          	beq	a4,a5,80003c02 <iput+0x48>
  ip->ref--;
    80003be0:	449c                	lw	a5,8(s1)
    80003be2:	37fd                	addiw	a5,a5,-1
    80003be4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003be6:	0001d517          	auipc	a0,0x1d
    80003bea:	cd250513          	addi	a0,a0,-814 # 800208b8 <itable>
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
}
    80003bf6:	60e2                	ld	ra,24(sp)
    80003bf8:	6442                	ld	s0,16(sp)
    80003bfa:	64a2                	ld	s1,8(sp)
    80003bfc:	6902                	ld	s2,0(sp)
    80003bfe:	6105                	addi	sp,sp,32
    80003c00:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c02:	40bc                	lw	a5,64(s1)
    80003c04:	dff1                	beqz	a5,80003be0 <iput+0x26>
    80003c06:	04a49783          	lh	a5,74(s1)
    80003c0a:	fbf9                	bnez	a5,80003be0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c0c:	01048913          	addi	s2,s1,16
    80003c10:	854a                	mv	a0,s2
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	aae080e7          	jalr	-1362(ra) # 800046c0 <acquiresleep>
    release(&itable.lock);
    80003c1a:	0001d517          	auipc	a0,0x1d
    80003c1e:	c9e50513          	addi	a0,a0,-866 # 800208b8 <itable>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	068080e7          	jalr	104(ra) # 80000c8a <release>
    itrunc(ip);
    80003c2a:	8526                	mv	a0,s1
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	ee2080e7          	jalr	-286(ra) # 80003b0e <itrunc>
    ip->type = 0;
    80003c34:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c38:	8526                	mv	a0,s1
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	cfa080e7          	jalr	-774(ra) # 80003934 <iupdate>
    ip->valid = 0;
    80003c42:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c46:	854a                	mv	a0,s2
    80003c48:	00001097          	auipc	ra,0x1
    80003c4c:	ace080e7          	jalr	-1330(ra) # 80004716 <releasesleep>
    acquire(&itable.lock);
    80003c50:	0001d517          	auipc	a0,0x1d
    80003c54:	c6850513          	addi	a0,a0,-920 # 800208b8 <itable>
    80003c58:	ffffd097          	auipc	ra,0xffffd
    80003c5c:	f7e080e7          	jalr	-130(ra) # 80000bd6 <acquire>
    80003c60:	b741                	j	80003be0 <iput+0x26>

0000000080003c62 <iunlockput>:
{
    80003c62:	1101                	addi	sp,sp,-32
    80003c64:	ec06                	sd	ra,24(sp)
    80003c66:	e822                	sd	s0,16(sp)
    80003c68:	e426                	sd	s1,8(sp)
    80003c6a:	1000                	addi	s0,sp,32
    80003c6c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	e54080e7          	jalr	-428(ra) # 80003ac2 <iunlock>
  iput(ip);
    80003c76:	8526                	mv	a0,s1
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	f42080e7          	jalr	-190(ra) # 80003bba <iput>
}
    80003c80:	60e2                	ld	ra,24(sp)
    80003c82:	6442                	ld	s0,16(sp)
    80003c84:	64a2                	ld	s1,8(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret

0000000080003c8a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c8a:	1141                	addi	sp,sp,-16
    80003c8c:	e422                	sd	s0,8(sp)
    80003c8e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c90:	411c                	lw	a5,0(a0)
    80003c92:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c94:	415c                	lw	a5,4(a0)
    80003c96:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c98:	04451783          	lh	a5,68(a0)
    80003c9c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ca0:	04a51783          	lh	a5,74(a0)
    80003ca4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ca8:	04c56783          	lwu	a5,76(a0)
    80003cac:	e99c                	sd	a5,16(a1)
}
    80003cae:	6422                	ld	s0,8(sp)
    80003cb0:	0141                	addi	sp,sp,16
    80003cb2:	8082                	ret

0000000080003cb4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cb4:	457c                	lw	a5,76(a0)
    80003cb6:	0ed7e963          	bltu	a5,a3,80003da8 <readi+0xf4>
{
    80003cba:	7159                	addi	sp,sp,-112
    80003cbc:	f486                	sd	ra,104(sp)
    80003cbe:	f0a2                	sd	s0,96(sp)
    80003cc0:	eca6                	sd	s1,88(sp)
    80003cc2:	e8ca                	sd	s2,80(sp)
    80003cc4:	e4ce                	sd	s3,72(sp)
    80003cc6:	e0d2                	sd	s4,64(sp)
    80003cc8:	fc56                	sd	s5,56(sp)
    80003cca:	f85a                	sd	s6,48(sp)
    80003ccc:	f45e                	sd	s7,40(sp)
    80003cce:	f062                	sd	s8,32(sp)
    80003cd0:	ec66                	sd	s9,24(sp)
    80003cd2:	e86a                	sd	s10,16(sp)
    80003cd4:	e46e                	sd	s11,8(sp)
    80003cd6:	1880                	addi	s0,sp,112
    80003cd8:	8b2a                	mv	s6,a0
    80003cda:	8bae                	mv	s7,a1
    80003cdc:	8a32                	mv	s4,a2
    80003cde:	84b6                	mv	s1,a3
    80003ce0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ce2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ce4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ce6:	0ad76063          	bltu	a4,a3,80003d86 <readi+0xd2>
  if(off + n > ip->size)
    80003cea:	00e7f463          	bgeu	a5,a4,80003cf2 <readi+0x3e>
    n = ip->size - off;
    80003cee:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf2:	0a0a8963          	beqz	s5,80003da4 <readi+0xf0>
    80003cf6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cfc:	5c7d                	li	s8,-1
    80003cfe:	a82d                	j	80003d38 <readi+0x84>
    80003d00:	020d1d93          	slli	s11,s10,0x20
    80003d04:	020ddd93          	srli	s11,s11,0x20
    80003d08:	05890613          	addi	a2,s2,88
    80003d0c:	86ee                	mv	a3,s11
    80003d0e:	963a                	add	a2,a2,a4
    80003d10:	85d2                	mv	a1,s4
    80003d12:	855e                	mv	a0,s7
    80003d14:	ffffe097          	auipc	ra,0xffffe
    80003d18:	7a0080e7          	jalr	1952(ra) # 800024b4 <either_copyout>
    80003d1c:	05850d63          	beq	a0,s8,80003d76 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d20:	854a                	mv	a0,s2
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	5f6080e7          	jalr	1526(ra) # 80003318 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2a:	013d09bb          	addw	s3,s10,s3
    80003d2e:	009d04bb          	addw	s1,s10,s1
    80003d32:	9a6e                	add	s4,s4,s11
    80003d34:	0559f763          	bgeu	s3,s5,80003d82 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d38:	00a4d59b          	srliw	a1,s1,0xa
    80003d3c:	855a                	mv	a0,s6
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	89e080e7          	jalr	-1890(ra) # 800035dc <bmap>
    80003d46:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d4a:	cd85                	beqz	a1,80003d82 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d4c:	000b2503          	lw	a0,0(s6)
    80003d50:	fffff097          	auipc	ra,0xfffff
    80003d54:	498080e7          	jalr	1176(ra) # 800031e8 <bread>
    80003d58:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5a:	3ff4f713          	andi	a4,s1,1023
    80003d5e:	40ec87bb          	subw	a5,s9,a4
    80003d62:	413a86bb          	subw	a3,s5,s3
    80003d66:	8d3e                	mv	s10,a5
    80003d68:	2781                	sext.w	a5,a5
    80003d6a:	0006861b          	sext.w	a2,a3
    80003d6e:	f8f679e3          	bgeu	a2,a5,80003d00 <readi+0x4c>
    80003d72:	8d36                	mv	s10,a3
    80003d74:	b771                	j	80003d00 <readi+0x4c>
      brelse(bp);
    80003d76:	854a                	mv	a0,s2
    80003d78:	fffff097          	auipc	ra,0xfffff
    80003d7c:	5a0080e7          	jalr	1440(ra) # 80003318 <brelse>
      tot = -1;
    80003d80:	59fd                	li	s3,-1
  }
  return tot;
    80003d82:	0009851b          	sext.w	a0,s3
}
    80003d86:	70a6                	ld	ra,104(sp)
    80003d88:	7406                	ld	s0,96(sp)
    80003d8a:	64e6                	ld	s1,88(sp)
    80003d8c:	6946                	ld	s2,80(sp)
    80003d8e:	69a6                	ld	s3,72(sp)
    80003d90:	6a06                	ld	s4,64(sp)
    80003d92:	7ae2                	ld	s5,56(sp)
    80003d94:	7b42                	ld	s6,48(sp)
    80003d96:	7ba2                	ld	s7,40(sp)
    80003d98:	7c02                	ld	s8,32(sp)
    80003d9a:	6ce2                	ld	s9,24(sp)
    80003d9c:	6d42                	ld	s10,16(sp)
    80003d9e:	6da2                	ld	s11,8(sp)
    80003da0:	6165                	addi	sp,sp,112
    80003da2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003da4:	89d6                	mv	s3,s5
    80003da6:	bff1                	j	80003d82 <readi+0xce>
    return 0;
    80003da8:	4501                	li	a0,0
}
    80003daa:	8082                	ret

0000000080003dac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dac:	457c                	lw	a5,76(a0)
    80003dae:	10d7e863          	bltu	a5,a3,80003ebe <writei+0x112>
{
    80003db2:	7159                	addi	sp,sp,-112
    80003db4:	f486                	sd	ra,104(sp)
    80003db6:	f0a2                	sd	s0,96(sp)
    80003db8:	eca6                	sd	s1,88(sp)
    80003dba:	e8ca                	sd	s2,80(sp)
    80003dbc:	e4ce                	sd	s3,72(sp)
    80003dbe:	e0d2                	sd	s4,64(sp)
    80003dc0:	fc56                	sd	s5,56(sp)
    80003dc2:	f85a                	sd	s6,48(sp)
    80003dc4:	f45e                	sd	s7,40(sp)
    80003dc6:	f062                	sd	s8,32(sp)
    80003dc8:	ec66                	sd	s9,24(sp)
    80003dca:	e86a                	sd	s10,16(sp)
    80003dcc:	e46e                	sd	s11,8(sp)
    80003dce:	1880                	addi	s0,sp,112
    80003dd0:	8aaa                	mv	s5,a0
    80003dd2:	8bae                	mv	s7,a1
    80003dd4:	8a32                	mv	s4,a2
    80003dd6:	8936                	mv	s2,a3
    80003dd8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dda:	00e687bb          	addw	a5,a3,a4
    80003dde:	0ed7e263          	bltu	a5,a3,80003ec2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003de2:	00043737          	lui	a4,0x43
    80003de6:	0ef76063          	bltu	a4,a5,80003ec6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dea:	0c0b0863          	beqz	s6,80003eba <writei+0x10e>
    80003dee:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003df0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003df4:	5c7d                	li	s8,-1
    80003df6:	a091                	j	80003e3a <writei+0x8e>
    80003df8:	020d1d93          	slli	s11,s10,0x20
    80003dfc:	020ddd93          	srli	s11,s11,0x20
    80003e00:	05848513          	addi	a0,s1,88
    80003e04:	86ee                	mv	a3,s11
    80003e06:	8652                	mv	a2,s4
    80003e08:	85de                	mv	a1,s7
    80003e0a:	953a                	add	a0,a0,a4
    80003e0c:	ffffe097          	auipc	ra,0xffffe
    80003e10:	6fe080e7          	jalr	1790(ra) # 8000250a <either_copyin>
    80003e14:	07850263          	beq	a0,s8,80003e78 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e18:	8526                	mv	a0,s1
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	788080e7          	jalr	1928(ra) # 800045a2 <log_write>
    brelse(bp);
    80003e22:	8526                	mv	a0,s1
    80003e24:	fffff097          	auipc	ra,0xfffff
    80003e28:	4f4080e7          	jalr	1268(ra) # 80003318 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e2c:	013d09bb          	addw	s3,s10,s3
    80003e30:	012d093b          	addw	s2,s10,s2
    80003e34:	9a6e                	add	s4,s4,s11
    80003e36:	0569f663          	bgeu	s3,s6,80003e82 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e3a:	00a9559b          	srliw	a1,s2,0xa
    80003e3e:	8556                	mv	a0,s5
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	79c080e7          	jalr	1948(ra) # 800035dc <bmap>
    80003e48:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e4c:	c99d                	beqz	a1,80003e82 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e4e:	000aa503          	lw	a0,0(s5)
    80003e52:	fffff097          	auipc	ra,0xfffff
    80003e56:	396080e7          	jalr	918(ra) # 800031e8 <bread>
    80003e5a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5c:	3ff97713          	andi	a4,s2,1023
    80003e60:	40ec87bb          	subw	a5,s9,a4
    80003e64:	413b06bb          	subw	a3,s6,s3
    80003e68:	8d3e                	mv	s10,a5
    80003e6a:	2781                	sext.w	a5,a5
    80003e6c:	0006861b          	sext.w	a2,a3
    80003e70:	f8f674e3          	bgeu	a2,a5,80003df8 <writei+0x4c>
    80003e74:	8d36                	mv	s10,a3
    80003e76:	b749                	j	80003df8 <writei+0x4c>
      brelse(bp);
    80003e78:	8526                	mv	a0,s1
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	49e080e7          	jalr	1182(ra) # 80003318 <brelse>
  }

  if(off > ip->size)
    80003e82:	04caa783          	lw	a5,76(s5)
    80003e86:	0127f463          	bgeu	a5,s2,80003e8e <writei+0xe2>
    ip->size = off;
    80003e8a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e8e:	8556                	mv	a0,s5
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	aa4080e7          	jalr	-1372(ra) # 80003934 <iupdate>

  return tot;
    80003e98:	0009851b          	sext.w	a0,s3
}
    80003e9c:	70a6                	ld	ra,104(sp)
    80003e9e:	7406                	ld	s0,96(sp)
    80003ea0:	64e6                	ld	s1,88(sp)
    80003ea2:	6946                	ld	s2,80(sp)
    80003ea4:	69a6                	ld	s3,72(sp)
    80003ea6:	6a06                	ld	s4,64(sp)
    80003ea8:	7ae2                	ld	s5,56(sp)
    80003eaa:	7b42                	ld	s6,48(sp)
    80003eac:	7ba2                	ld	s7,40(sp)
    80003eae:	7c02                	ld	s8,32(sp)
    80003eb0:	6ce2                	ld	s9,24(sp)
    80003eb2:	6d42                	ld	s10,16(sp)
    80003eb4:	6da2                	ld	s11,8(sp)
    80003eb6:	6165                	addi	sp,sp,112
    80003eb8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eba:	89da                	mv	s3,s6
    80003ebc:	bfc9                	j	80003e8e <writei+0xe2>
    return -1;
    80003ebe:	557d                	li	a0,-1
}
    80003ec0:	8082                	ret
    return -1;
    80003ec2:	557d                	li	a0,-1
    80003ec4:	bfe1                	j	80003e9c <writei+0xf0>
    return -1;
    80003ec6:	557d                	li	a0,-1
    80003ec8:	bfd1                	j	80003e9c <writei+0xf0>

0000000080003eca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003eca:	1141                	addi	sp,sp,-16
    80003ecc:	e406                	sd	ra,8(sp)
    80003ece:	e022                	sd	s0,0(sp)
    80003ed0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ed2:	4639                	li	a2,14
    80003ed4:	ffffd097          	auipc	ra,0xffffd
    80003ed8:	ece080e7          	jalr	-306(ra) # 80000da2 <strncmp>
}
    80003edc:	60a2                	ld	ra,8(sp)
    80003ede:	6402                	ld	s0,0(sp)
    80003ee0:	0141                	addi	sp,sp,16
    80003ee2:	8082                	ret

0000000080003ee4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ee4:	7139                	addi	sp,sp,-64
    80003ee6:	fc06                	sd	ra,56(sp)
    80003ee8:	f822                	sd	s0,48(sp)
    80003eea:	f426                	sd	s1,40(sp)
    80003eec:	f04a                	sd	s2,32(sp)
    80003eee:	ec4e                	sd	s3,24(sp)
    80003ef0:	e852                	sd	s4,16(sp)
    80003ef2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ef4:	04451703          	lh	a4,68(a0)
    80003ef8:	4785                	li	a5,1
    80003efa:	00f71a63          	bne	a4,a5,80003f0e <dirlookup+0x2a>
    80003efe:	892a                	mv	s2,a0
    80003f00:	89ae                	mv	s3,a1
    80003f02:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f04:	457c                	lw	a5,76(a0)
    80003f06:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f08:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0a:	e79d                	bnez	a5,80003f38 <dirlookup+0x54>
    80003f0c:	a8a5                	j	80003f84 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f0e:	00004517          	auipc	a0,0x4
    80003f12:	70250513          	addi	a0,a0,1794 # 80008610 <syscalls+0x1c0>
    80003f16:	ffffc097          	auipc	ra,0xffffc
    80003f1a:	62a080e7          	jalr	1578(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003f1e:	00004517          	auipc	a0,0x4
    80003f22:	70a50513          	addi	a0,a0,1802 # 80008628 <syscalls+0x1d8>
    80003f26:	ffffc097          	auipc	ra,0xffffc
    80003f2a:	61a080e7          	jalr	1562(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f2e:	24c1                	addiw	s1,s1,16
    80003f30:	04c92783          	lw	a5,76(s2)
    80003f34:	04f4f763          	bgeu	s1,a5,80003f82 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f38:	4741                	li	a4,16
    80003f3a:	86a6                	mv	a3,s1
    80003f3c:	fc040613          	addi	a2,s0,-64
    80003f40:	4581                	li	a1,0
    80003f42:	854a                	mv	a0,s2
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	d70080e7          	jalr	-656(ra) # 80003cb4 <readi>
    80003f4c:	47c1                	li	a5,16
    80003f4e:	fcf518e3          	bne	a0,a5,80003f1e <dirlookup+0x3a>
    if(de.inum == 0)
    80003f52:	fc045783          	lhu	a5,-64(s0)
    80003f56:	dfe1                	beqz	a5,80003f2e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f58:	fc240593          	addi	a1,s0,-62
    80003f5c:	854e                	mv	a0,s3
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	f6c080e7          	jalr	-148(ra) # 80003eca <namecmp>
    80003f66:	f561                	bnez	a0,80003f2e <dirlookup+0x4a>
      if(poff)
    80003f68:	000a0463          	beqz	s4,80003f70 <dirlookup+0x8c>
        *poff = off;
    80003f6c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f70:	fc045583          	lhu	a1,-64(s0)
    80003f74:	00092503          	lw	a0,0(s2)
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	74e080e7          	jalr	1870(ra) # 800036c6 <iget>
    80003f80:	a011                	j	80003f84 <dirlookup+0xa0>
  return 0;
    80003f82:	4501                	li	a0,0
}
    80003f84:	70e2                	ld	ra,56(sp)
    80003f86:	7442                	ld	s0,48(sp)
    80003f88:	74a2                	ld	s1,40(sp)
    80003f8a:	7902                	ld	s2,32(sp)
    80003f8c:	69e2                	ld	s3,24(sp)
    80003f8e:	6a42                	ld	s4,16(sp)
    80003f90:	6121                	addi	sp,sp,64
    80003f92:	8082                	ret

0000000080003f94 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f94:	711d                	addi	sp,sp,-96
    80003f96:	ec86                	sd	ra,88(sp)
    80003f98:	e8a2                	sd	s0,80(sp)
    80003f9a:	e4a6                	sd	s1,72(sp)
    80003f9c:	e0ca                	sd	s2,64(sp)
    80003f9e:	fc4e                	sd	s3,56(sp)
    80003fa0:	f852                	sd	s4,48(sp)
    80003fa2:	f456                	sd	s5,40(sp)
    80003fa4:	f05a                	sd	s6,32(sp)
    80003fa6:	ec5e                	sd	s7,24(sp)
    80003fa8:	e862                	sd	s8,16(sp)
    80003faa:	e466                	sd	s9,8(sp)
    80003fac:	e06a                	sd	s10,0(sp)
    80003fae:	1080                	addi	s0,sp,96
    80003fb0:	84aa                	mv	s1,a0
    80003fb2:	8b2e                	mv	s6,a1
    80003fb4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fb6:	00054703          	lbu	a4,0(a0)
    80003fba:	02f00793          	li	a5,47
    80003fbe:	02f70363          	beq	a4,a5,80003fe4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fc2:	ffffe097          	auipc	ra,0xffffe
    80003fc6:	9ea080e7          	jalr	-1558(ra) # 800019ac <myproc>
    80003fca:	15053503          	ld	a0,336(a0)
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	9f4080e7          	jalr	-1548(ra) # 800039c2 <idup>
    80003fd6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003fd8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003fdc:	4cb5                	li	s9,13
  len = path - s;
    80003fde:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fe0:	4c05                	li	s8,1
    80003fe2:	a87d                	j	800040a0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003fe4:	4585                	li	a1,1
    80003fe6:	4505                	li	a0,1
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	6de080e7          	jalr	1758(ra) # 800036c6 <iget>
    80003ff0:	8a2a                	mv	s4,a0
    80003ff2:	b7dd                	j	80003fd8 <namex+0x44>
      iunlockput(ip);
    80003ff4:	8552                	mv	a0,s4
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	c6c080e7          	jalr	-916(ra) # 80003c62 <iunlockput>
      return 0;
    80003ffe:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004000:	8552                	mv	a0,s4
    80004002:	60e6                	ld	ra,88(sp)
    80004004:	6446                	ld	s0,80(sp)
    80004006:	64a6                	ld	s1,72(sp)
    80004008:	6906                	ld	s2,64(sp)
    8000400a:	79e2                	ld	s3,56(sp)
    8000400c:	7a42                	ld	s4,48(sp)
    8000400e:	7aa2                	ld	s5,40(sp)
    80004010:	7b02                	ld	s6,32(sp)
    80004012:	6be2                	ld	s7,24(sp)
    80004014:	6c42                	ld	s8,16(sp)
    80004016:	6ca2                	ld	s9,8(sp)
    80004018:	6d02                	ld	s10,0(sp)
    8000401a:	6125                	addi	sp,sp,96
    8000401c:	8082                	ret
      iunlock(ip);
    8000401e:	8552                	mv	a0,s4
    80004020:	00000097          	auipc	ra,0x0
    80004024:	aa2080e7          	jalr	-1374(ra) # 80003ac2 <iunlock>
      return ip;
    80004028:	bfe1                	j	80004000 <namex+0x6c>
      iunlockput(ip);
    8000402a:	8552                	mv	a0,s4
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	c36080e7          	jalr	-970(ra) # 80003c62 <iunlockput>
      return 0;
    80004034:	8a4e                	mv	s4,s3
    80004036:	b7e9                	j	80004000 <namex+0x6c>
  len = path - s;
    80004038:	40998633          	sub	a2,s3,s1
    8000403c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004040:	09acd863          	bge	s9,s10,800040d0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004044:	4639                	li	a2,14
    80004046:	85a6                	mv	a1,s1
    80004048:	8556                	mv	a0,s5
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	ce4080e7          	jalr	-796(ra) # 80000d2e <memmove>
    80004052:	84ce                	mv	s1,s3
  while(*path == '/')
    80004054:	0004c783          	lbu	a5,0(s1)
    80004058:	01279763          	bne	a5,s2,80004066 <namex+0xd2>
    path++;
    8000405c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000405e:	0004c783          	lbu	a5,0(s1)
    80004062:	ff278de3          	beq	a5,s2,8000405c <namex+0xc8>
    ilock(ip);
    80004066:	8552                	mv	a0,s4
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	998080e7          	jalr	-1640(ra) # 80003a00 <ilock>
    if(ip->type != T_DIR){
    80004070:	044a1783          	lh	a5,68(s4)
    80004074:	f98790e3          	bne	a5,s8,80003ff4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004078:	000b0563          	beqz	s6,80004082 <namex+0xee>
    8000407c:	0004c783          	lbu	a5,0(s1)
    80004080:	dfd9                	beqz	a5,8000401e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004082:	865e                	mv	a2,s7
    80004084:	85d6                	mv	a1,s5
    80004086:	8552                	mv	a0,s4
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	e5c080e7          	jalr	-420(ra) # 80003ee4 <dirlookup>
    80004090:	89aa                	mv	s3,a0
    80004092:	dd41                	beqz	a0,8000402a <namex+0x96>
    iunlockput(ip);
    80004094:	8552                	mv	a0,s4
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	bcc080e7          	jalr	-1076(ra) # 80003c62 <iunlockput>
    ip = next;
    8000409e:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040a0:	0004c783          	lbu	a5,0(s1)
    800040a4:	01279763          	bne	a5,s2,800040b2 <namex+0x11e>
    path++;
    800040a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040aa:	0004c783          	lbu	a5,0(s1)
    800040ae:	ff278de3          	beq	a5,s2,800040a8 <namex+0x114>
  if(*path == 0)
    800040b2:	cb9d                	beqz	a5,800040e8 <namex+0x154>
  while(*path != '/' && *path != 0)
    800040b4:	0004c783          	lbu	a5,0(s1)
    800040b8:	89a6                	mv	s3,s1
  len = path - s;
    800040ba:	8d5e                	mv	s10,s7
    800040bc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040be:	01278963          	beq	a5,s2,800040d0 <namex+0x13c>
    800040c2:	dbbd                	beqz	a5,80004038 <namex+0xa4>
    path++;
    800040c4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040c6:	0009c783          	lbu	a5,0(s3)
    800040ca:	ff279ce3          	bne	a5,s2,800040c2 <namex+0x12e>
    800040ce:	b7ad                	j	80004038 <namex+0xa4>
    memmove(name, s, len);
    800040d0:	2601                	sext.w	a2,a2
    800040d2:	85a6                	mv	a1,s1
    800040d4:	8556                	mv	a0,s5
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	c58080e7          	jalr	-936(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040de:	9d56                	add	s10,s10,s5
    800040e0:	000d0023          	sb	zero,0(s10)
    800040e4:	84ce                	mv	s1,s3
    800040e6:	b7bd                	j	80004054 <namex+0xc0>
  if(nameiparent){
    800040e8:	f00b0ce3          	beqz	s6,80004000 <namex+0x6c>
    iput(ip);
    800040ec:	8552                	mv	a0,s4
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	acc080e7          	jalr	-1332(ra) # 80003bba <iput>
    return 0;
    800040f6:	4a01                	li	s4,0
    800040f8:	b721                	j	80004000 <namex+0x6c>

00000000800040fa <dirlink>:
{
    800040fa:	7139                	addi	sp,sp,-64
    800040fc:	fc06                	sd	ra,56(sp)
    800040fe:	f822                	sd	s0,48(sp)
    80004100:	f426                	sd	s1,40(sp)
    80004102:	f04a                	sd	s2,32(sp)
    80004104:	ec4e                	sd	s3,24(sp)
    80004106:	e852                	sd	s4,16(sp)
    80004108:	0080                	addi	s0,sp,64
    8000410a:	892a                	mv	s2,a0
    8000410c:	8a2e                	mv	s4,a1
    8000410e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004110:	4601                	li	a2,0
    80004112:	00000097          	auipc	ra,0x0
    80004116:	dd2080e7          	jalr	-558(ra) # 80003ee4 <dirlookup>
    8000411a:	e93d                	bnez	a0,80004190 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411c:	04c92483          	lw	s1,76(s2)
    80004120:	c49d                	beqz	s1,8000414e <dirlink+0x54>
    80004122:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004124:	4741                	li	a4,16
    80004126:	86a6                	mv	a3,s1
    80004128:	fc040613          	addi	a2,s0,-64
    8000412c:	4581                	li	a1,0
    8000412e:	854a                	mv	a0,s2
    80004130:	00000097          	auipc	ra,0x0
    80004134:	b84080e7          	jalr	-1148(ra) # 80003cb4 <readi>
    80004138:	47c1                	li	a5,16
    8000413a:	06f51163          	bne	a0,a5,8000419c <dirlink+0xa2>
    if(de.inum == 0)
    8000413e:	fc045783          	lhu	a5,-64(s0)
    80004142:	c791                	beqz	a5,8000414e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004144:	24c1                	addiw	s1,s1,16
    80004146:	04c92783          	lw	a5,76(s2)
    8000414a:	fcf4ede3          	bltu	s1,a5,80004124 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000414e:	4639                	li	a2,14
    80004150:	85d2                	mv	a1,s4
    80004152:	fc240513          	addi	a0,s0,-62
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	c88080e7          	jalr	-888(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000415e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004162:	4741                	li	a4,16
    80004164:	86a6                	mv	a3,s1
    80004166:	fc040613          	addi	a2,s0,-64
    8000416a:	4581                	li	a1,0
    8000416c:	854a                	mv	a0,s2
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	c3e080e7          	jalr	-962(ra) # 80003dac <writei>
    80004176:	1541                	addi	a0,a0,-16
    80004178:	00a03533          	snez	a0,a0
    8000417c:	40a00533          	neg	a0,a0
}
    80004180:	70e2                	ld	ra,56(sp)
    80004182:	7442                	ld	s0,48(sp)
    80004184:	74a2                	ld	s1,40(sp)
    80004186:	7902                	ld	s2,32(sp)
    80004188:	69e2                	ld	s3,24(sp)
    8000418a:	6a42                	ld	s4,16(sp)
    8000418c:	6121                	addi	sp,sp,64
    8000418e:	8082                	ret
    iput(ip);
    80004190:	00000097          	auipc	ra,0x0
    80004194:	a2a080e7          	jalr	-1494(ra) # 80003bba <iput>
    return -1;
    80004198:	557d                	li	a0,-1
    8000419a:	b7dd                	j	80004180 <dirlink+0x86>
      panic("dirlink read");
    8000419c:	00004517          	auipc	a0,0x4
    800041a0:	49c50513          	addi	a0,a0,1180 # 80008638 <syscalls+0x1e8>
    800041a4:	ffffc097          	auipc	ra,0xffffc
    800041a8:	39c080e7          	jalr	924(ra) # 80000540 <panic>

00000000800041ac <namei>:

struct inode*
namei(char *path)
{
    800041ac:	1101                	addi	sp,sp,-32
    800041ae:	ec06                	sd	ra,24(sp)
    800041b0:	e822                	sd	s0,16(sp)
    800041b2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041b4:	fe040613          	addi	a2,s0,-32
    800041b8:	4581                	li	a1,0
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	dda080e7          	jalr	-550(ra) # 80003f94 <namex>
}
    800041c2:	60e2                	ld	ra,24(sp)
    800041c4:	6442                	ld	s0,16(sp)
    800041c6:	6105                	addi	sp,sp,32
    800041c8:	8082                	ret

00000000800041ca <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041ca:	1141                	addi	sp,sp,-16
    800041cc:	e406                	sd	ra,8(sp)
    800041ce:	e022                	sd	s0,0(sp)
    800041d0:	0800                	addi	s0,sp,16
    800041d2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041d4:	4585                	li	a1,1
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	dbe080e7          	jalr	-578(ra) # 80003f94 <namex>
}
    800041de:	60a2                	ld	ra,8(sp)
    800041e0:	6402                	ld	s0,0(sp)
    800041e2:	0141                	addi	sp,sp,16
    800041e4:	8082                	ret

00000000800041e6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041e6:	1101                	addi	sp,sp,-32
    800041e8:	ec06                	sd	ra,24(sp)
    800041ea:	e822                	sd	s0,16(sp)
    800041ec:	e426                	sd	s1,8(sp)
    800041ee:	e04a                	sd	s2,0(sp)
    800041f0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041f2:	0001e917          	auipc	s2,0x1e
    800041f6:	16e90913          	addi	s2,s2,366 # 80022360 <log>
    800041fa:	01892583          	lw	a1,24(s2)
    800041fe:	02892503          	lw	a0,40(s2)
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	fe6080e7          	jalr	-26(ra) # 800031e8 <bread>
    8000420a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000420c:	02c92683          	lw	a3,44(s2)
    80004210:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004212:	02d05863          	blez	a3,80004242 <write_head+0x5c>
    80004216:	0001e797          	auipc	a5,0x1e
    8000421a:	17a78793          	addi	a5,a5,378 # 80022390 <log+0x30>
    8000421e:	05c50713          	addi	a4,a0,92
    80004222:	36fd                	addiw	a3,a3,-1
    80004224:	02069613          	slli	a2,a3,0x20
    80004228:	01e65693          	srli	a3,a2,0x1e
    8000422c:	0001e617          	auipc	a2,0x1e
    80004230:	16860613          	addi	a2,a2,360 # 80022394 <log+0x34>
    80004234:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004236:	4390                	lw	a2,0(a5)
    80004238:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000423a:	0791                	addi	a5,a5,4
    8000423c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000423e:	fed79ce3          	bne	a5,a3,80004236 <write_head+0x50>
  }
  bwrite(buf);
    80004242:	8526                	mv	a0,s1
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	096080e7          	jalr	150(ra) # 800032da <bwrite>
  brelse(buf);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	0ca080e7          	jalr	202(ra) # 80003318 <brelse>
}
    80004256:	60e2                	ld	ra,24(sp)
    80004258:	6442                	ld	s0,16(sp)
    8000425a:	64a2                	ld	s1,8(sp)
    8000425c:	6902                	ld	s2,0(sp)
    8000425e:	6105                	addi	sp,sp,32
    80004260:	8082                	ret

0000000080004262 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004262:	0001e797          	auipc	a5,0x1e
    80004266:	12a7a783          	lw	a5,298(a5) # 8002238c <log+0x2c>
    8000426a:	0af05d63          	blez	a5,80004324 <install_trans+0xc2>
{
    8000426e:	7139                	addi	sp,sp,-64
    80004270:	fc06                	sd	ra,56(sp)
    80004272:	f822                	sd	s0,48(sp)
    80004274:	f426                	sd	s1,40(sp)
    80004276:	f04a                	sd	s2,32(sp)
    80004278:	ec4e                	sd	s3,24(sp)
    8000427a:	e852                	sd	s4,16(sp)
    8000427c:	e456                	sd	s5,8(sp)
    8000427e:	e05a                	sd	s6,0(sp)
    80004280:	0080                	addi	s0,sp,64
    80004282:	8b2a                	mv	s6,a0
    80004284:	0001ea97          	auipc	s5,0x1e
    80004288:	10ca8a93          	addi	s5,s5,268 # 80022390 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000428e:	0001e997          	auipc	s3,0x1e
    80004292:	0d298993          	addi	s3,s3,210 # 80022360 <log>
    80004296:	a00d                	j	800042b8 <install_trans+0x56>
    brelse(lbuf);
    80004298:	854a                	mv	a0,s2
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	07e080e7          	jalr	126(ra) # 80003318 <brelse>
    brelse(dbuf);
    800042a2:	8526                	mv	a0,s1
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	074080e7          	jalr	116(ra) # 80003318 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ac:	2a05                	addiw	s4,s4,1
    800042ae:	0a91                	addi	s5,s5,4
    800042b0:	02c9a783          	lw	a5,44(s3)
    800042b4:	04fa5e63          	bge	s4,a5,80004310 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042b8:	0189a583          	lw	a1,24(s3)
    800042bc:	014585bb          	addw	a1,a1,s4
    800042c0:	2585                	addiw	a1,a1,1
    800042c2:	0289a503          	lw	a0,40(s3)
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	f22080e7          	jalr	-222(ra) # 800031e8 <bread>
    800042ce:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042d0:	000aa583          	lw	a1,0(s5)
    800042d4:	0289a503          	lw	a0,40(s3)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	f10080e7          	jalr	-240(ra) # 800031e8 <bread>
    800042e0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042e2:	40000613          	li	a2,1024
    800042e6:	05890593          	addi	a1,s2,88
    800042ea:	05850513          	addi	a0,a0,88
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	a40080e7          	jalr	-1472(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042f6:	8526                	mv	a0,s1
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	fe2080e7          	jalr	-30(ra) # 800032da <bwrite>
    if(recovering == 0)
    80004300:	f80b1ce3          	bnez	s6,80004298 <install_trans+0x36>
      bunpin(dbuf);
    80004304:	8526                	mv	a0,s1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	0ec080e7          	jalr	236(ra) # 800033f2 <bunpin>
    8000430e:	b769                	j	80004298 <install_trans+0x36>
}
    80004310:	70e2                	ld	ra,56(sp)
    80004312:	7442                	ld	s0,48(sp)
    80004314:	74a2                	ld	s1,40(sp)
    80004316:	7902                	ld	s2,32(sp)
    80004318:	69e2                	ld	s3,24(sp)
    8000431a:	6a42                	ld	s4,16(sp)
    8000431c:	6aa2                	ld	s5,8(sp)
    8000431e:	6b02                	ld	s6,0(sp)
    80004320:	6121                	addi	sp,sp,64
    80004322:	8082                	ret
    80004324:	8082                	ret

0000000080004326 <initlog>:
{
    80004326:	7179                	addi	sp,sp,-48
    80004328:	f406                	sd	ra,40(sp)
    8000432a:	f022                	sd	s0,32(sp)
    8000432c:	ec26                	sd	s1,24(sp)
    8000432e:	e84a                	sd	s2,16(sp)
    80004330:	e44e                	sd	s3,8(sp)
    80004332:	1800                	addi	s0,sp,48
    80004334:	892a                	mv	s2,a0
    80004336:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004338:	0001e497          	auipc	s1,0x1e
    8000433c:	02848493          	addi	s1,s1,40 # 80022360 <log>
    80004340:	00004597          	auipc	a1,0x4
    80004344:	30858593          	addi	a1,a1,776 # 80008648 <syscalls+0x1f8>
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffc097          	auipc	ra,0xffffc
    8000434e:	7fc080e7          	jalr	2044(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004352:	0149a583          	lw	a1,20(s3)
    80004356:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004358:	0109a783          	lw	a5,16(s3)
    8000435c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000435e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004362:	854a                	mv	a0,s2
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	e84080e7          	jalr	-380(ra) # 800031e8 <bread>
  log.lh.n = lh->n;
    8000436c:	4d34                	lw	a3,88(a0)
    8000436e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004370:	02d05663          	blez	a3,8000439c <initlog+0x76>
    80004374:	05c50793          	addi	a5,a0,92
    80004378:	0001e717          	auipc	a4,0x1e
    8000437c:	01870713          	addi	a4,a4,24 # 80022390 <log+0x30>
    80004380:	36fd                	addiw	a3,a3,-1
    80004382:	02069613          	slli	a2,a3,0x20
    80004386:	01e65693          	srli	a3,a2,0x1e
    8000438a:	06050613          	addi	a2,a0,96
    8000438e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004390:	4390                	lw	a2,0(a5)
    80004392:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004394:	0791                	addi	a5,a5,4
    80004396:	0711                	addi	a4,a4,4
    80004398:	fed79ce3          	bne	a5,a3,80004390 <initlog+0x6a>
  brelse(buf);
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	f7c080e7          	jalr	-132(ra) # 80003318 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043a4:	4505                	li	a0,1
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	ebc080e7          	jalr	-324(ra) # 80004262 <install_trans>
  log.lh.n = 0;
    800043ae:	0001e797          	auipc	a5,0x1e
    800043b2:	fc07af23          	sw	zero,-34(a5) # 8002238c <log+0x2c>
  write_head(); // clear the log
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	e30080e7          	jalr	-464(ra) # 800041e6 <write_head>
}
    800043be:	70a2                	ld	ra,40(sp)
    800043c0:	7402                	ld	s0,32(sp)
    800043c2:	64e2                	ld	s1,24(sp)
    800043c4:	6942                	ld	s2,16(sp)
    800043c6:	69a2                	ld	s3,8(sp)
    800043c8:	6145                	addi	sp,sp,48
    800043ca:	8082                	ret

00000000800043cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	e04a                	sd	s2,0(sp)
    800043d6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043d8:	0001e517          	auipc	a0,0x1e
    800043dc:	f8850513          	addi	a0,a0,-120 # 80022360 <log>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	7f6080e7          	jalr	2038(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043e8:	0001e497          	auipc	s1,0x1e
    800043ec:	f7848493          	addi	s1,s1,-136 # 80022360 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043f0:	4979                	li	s2,30
    800043f2:	a039                	j	80004400 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043f4:	85a6                	mv	a1,s1
    800043f6:	8526                	mv	a0,s1
    800043f8:	ffffe097          	auipc	ra,0xffffe
    800043fc:	ca8080e7          	jalr	-856(ra) # 800020a0 <sleep>
    if(log.committing){
    80004400:	50dc                	lw	a5,36(s1)
    80004402:	fbed                	bnez	a5,800043f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004404:	5098                	lw	a4,32(s1)
    80004406:	2705                	addiw	a4,a4,1
    80004408:	0007069b          	sext.w	a3,a4
    8000440c:	0027179b          	slliw	a5,a4,0x2
    80004410:	9fb9                	addw	a5,a5,a4
    80004412:	0017979b          	slliw	a5,a5,0x1
    80004416:	54d8                	lw	a4,44(s1)
    80004418:	9fb9                	addw	a5,a5,a4
    8000441a:	00f95963          	bge	s2,a5,8000442c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000441e:	85a6                	mv	a1,s1
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	c7e080e7          	jalr	-898(ra) # 800020a0 <sleep>
    8000442a:	bfd9                	j	80004400 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000442c:	0001e517          	auipc	a0,0x1e
    80004430:	f3450513          	addi	a0,a0,-204 # 80022360 <log>
    80004434:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	854080e7          	jalr	-1964(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000444a:	7139                	addi	sp,sp,-64
    8000444c:	fc06                	sd	ra,56(sp)
    8000444e:	f822                	sd	s0,48(sp)
    80004450:	f426                	sd	s1,40(sp)
    80004452:	f04a                	sd	s2,32(sp)
    80004454:	ec4e                	sd	s3,24(sp)
    80004456:	e852                	sd	s4,16(sp)
    80004458:	e456                	sd	s5,8(sp)
    8000445a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000445c:	0001e497          	auipc	s1,0x1e
    80004460:	f0448493          	addi	s1,s1,-252 # 80022360 <log>
    80004464:	8526                	mv	a0,s1
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	770080e7          	jalr	1904(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000446e:	509c                	lw	a5,32(s1)
    80004470:	37fd                	addiw	a5,a5,-1
    80004472:	0007891b          	sext.w	s2,a5
    80004476:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004478:	50dc                	lw	a5,36(s1)
    8000447a:	e7b9                	bnez	a5,800044c8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000447c:	04091e63          	bnez	s2,800044d8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004480:	0001e497          	auipc	s1,0x1e
    80004484:	ee048493          	addi	s1,s1,-288 # 80022360 <log>
    80004488:	4785                	li	a5,1
    8000448a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	7fc080e7          	jalr	2044(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004496:	54dc                	lw	a5,44(s1)
    80004498:	06f04763          	bgtz	a5,80004506 <end_op+0xbc>
    acquire(&log.lock);
    8000449c:	0001e497          	auipc	s1,0x1e
    800044a0:	ec448493          	addi	s1,s1,-316 # 80022360 <log>
    800044a4:	8526                	mv	a0,s1
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	730080e7          	jalr	1840(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800044ae:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044b2:	8526                	mv	a0,s1
    800044b4:	ffffe097          	auipc	ra,0xffffe
    800044b8:	c50080e7          	jalr	-944(ra) # 80002104 <wakeup>
    release(&log.lock);
    800044bc:	8526                	mv	a0,s1
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7cc080e7          	jalr	1996(ra) # 80000c8a <release>
}
    800044c6:	a03d                	j	800044f4 <end_op+0xaa>
    panic("log.committing");
    800044c8:	00004517          	auipc	a0,0x4
    800044cc:	18850513          	addi	a0,a0,392 # 80008650 <syscalls+0x200>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	070080e7          	jalr	112(ra) # 80000540 <panic>
    wakeup(&log);
    800044d8:	0001e497          	auipc	s1,0x1e
    800044dc:	e8848493          	addi	s1,s1,-376 # 80022360 <log>
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffe097          	auipc	ra,0xffffe
    800044e6:	c22080e7          	jalr	-990(ra) # 80002104 <wakeup>
  release(&log.lock);
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	79e080e7          	jalr	1950(ra) # 80000c8a <release>
}
    800044f4:	70e2                	ld	ra,56(sp)
    800044f6:	7442                	ld	s0,48(sp)
    800044f8:	74a2                	ld	s1,40(sp)
    800044fa:	7902                	ld	s2,32(sp)
    800044fc:	69e2                	ld	s3,24(sp)
    800044fe:	6a42                	ld	s4,16(sp)
    80004500:	6aa2                	ld	s5,8(sp)
    80004502:	6121                	addi	sp,sp,64
    80004504:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004506:	0001ea97          	auipc	s5,0x1e
    8000450a:	e8aa8a93          	addi	s5,s5,-374 # 80022390 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000450e:	0001ea17          	auipc	s4,0x1e
    80004512:	e52a0a13          	addi	s4,s4,-430 # 80022360 <log>
    80004516:	018a2583          	lw	a1,24(s4)
    8000451a:	012585bb          	addw	a1,a1,s2
    8000451e:	2585                	addiw	a1,a1,1
    80004520:	028a2503          	lw	a0,40(s4)
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	cc4080e7          	jalr	-828(ra) # 800031e8 <bread>
    8000452c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000452e:	000aa583          	lw	a1,0(s5)
    80004532:	028a2503          	lw	a0,40(s4)
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	cb2080e7          	jalr	-846(ra) # 800031e8 <bread>
    8000453e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004540:	40000613          	li	a2,1024
    80004544:	05850593          	addi	a1,a0,88
    80004548:	05848513          	addi	a0,s1,88
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	7e2080e7          	jalr	2018(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004554:	8526                	mv	a0,s1
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	d84080e7          	jalr	-636(ra) # 800032da <bwrite>
    brelse(from);
    8000455e:	854e                	mv	a0,s3
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	db8080e7          	jalr	-584(ra) # 80003318 <brelse>
    brelse(to);
    80004568:	8526                	mv	a0,s1
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	dae080e7          	jalr	-594(ra) # 80003318 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004572:	2905                	addiw	s2,s2,1
    80004574:	0a91                	addi	s5,s5,4
    80004576:	02ca2783          	lw	a5,44(s4)
    8000457a:	f8f94ee3          	blt	s2,a5,80004516 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000457e:	00000097          	auipc	ra,0x0
    80004582:	c68080e7          	jalr	-920(ra) # 800041e6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004586:	4501                	li	a0,0
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	cda080e7          	jalr	-806(ra) # 80004262 <install_trans>
    log.lh.n = 0;
    80004590:	0001e797          	auipc	a5,0x1e
    80004594:	de07ae23          	sw	zero,-516(a5) # 8002238c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004598:	00000097          	auipc	ra,0x0
    8000459c:	c4e080e7          	jalr	-946(ra) # 800041e6 <write_head>
    800045a0:	bdf5                	j	8000449c <end_op+0x52>

00000000800045a2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	e04a                	sd	s2,0(sp)
    800045ac:	1000                	addi	s0,sp,32
    800045ae:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045b0:	0001e917          	auipc	s2,0x1e
    800045b4:	db090913          	addi	s2,s2,-592 # 80022360 <log>
    800045b8:	854a                	mv	a0,s2
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	61c080e7          	jalr	1564(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045c2:	02c92603          	lw	a2,44(s2)
    800045c6:	47f5                	li	a5,29
    800045c8:	06c7c563          	blt	a5,a2,80004632 <log_write+0x90>
    800045cc:	0001e797          	auipc	a5,0x1e
    800045d0:	db07a783          	lw	a5,-592(a5) # 8002237c <log+0x1c>
    800045d4:	37fd                	addiw	a5,a5,-1
    800045d6:	04f65e63          	bge	a2,a5,80004632 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045da:	0001e797          	auipc	a5,0x1e
    800045de:	da67a783          	lw	a5,-602(a5) # 80022380 <log+0x20>
    800045e2:	06f05063          	blez	a5,80004642 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045e6:	4781                	li	a5,0
    800045e8:	06c05563          	blez	a2,80004652 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045ec:	44cc                	lw	a1,12(s1)
    800045ee:	0001e717          	auipc	a4,0x1e
    800045f2:	da270713          	addi	a4,a4,-606 # 80022390 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045f6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045f8:	4314                	lw	a3,0(a4)
    800045fa:	04b68c63          	beq	a3,a1,80004652 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045fe:	2785                	addiw	a5,a5,1
    80004600:	0711                	addi	a4,a4,4
    80004602:	fef61be3          	bne	a2,a5,800045f8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004606:	0621                	addi	a2,a2,8
    80004608:	060a                	slli	a2,a2,0x2
    8000460a:	0001e797          	auipc	a5,0x1e
    8000460e:	d5678793          	addi	a5,a5,-682 # 80022360 <log>
    80004612:	97b2                	add	a5,a5,a2
    80004614:	44d8                	lw	a4,12(s1)
    80004616:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004618:	8526                	mv	a0,s1
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	d9c080e7          	jalr	-612(ra) # 800033b6 <bpin>
    log.lh.n++;
    80004622:	0001e717          	auipc	a4,0x1e
    80004626:	d3e70713          	addi	a4,a4,-706 # 80022360 <log>
    8000462a:	575c                	lw	a5,44(a4)
    8000462c:	2785                	addiw	a5,a5,1
    8000462e:	d75c                	sw	a5,44(a4)
    80004630:	a82d                	j	8000466a <log_write+0xc8>
    panic("too big a transaction");
    80004632:	00004517          	auipc	a0,0x4
    80004636:	02e50513          	addi	a0,a0,46 # 80008660 <syscalls+0x210>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	f06080e7          	jalr	-250(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004642:	00004517          	auipc	a0,0x4
    80004646:	03650513          	addi	a0,a0,54 # 80008678 <syscalls+0x228>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004652:	00878693          	addi	a3,a5,8
    80004656:	068a                	slli	a3,a3,0x2
    80004658:	0001e717          	auipc	a4,0x1e
    8000465c:	d0870713          	addi	a4,a4,-760 # 80022360 <log>
    80004660:	9736                	add	a4,a4,a3
    80004662:	44d4                	lw	a3,12(s1)
    80004664:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004666:	faf609e3          	beq	a2,a5,80004618 <log_write+0x76>
  }
  release(&log.lock);
    8000466a:	0001e517          	auipc	a0,0x1e
    8000466e:	cf650513          	addi	a0,a0,-778 # 80022360 <log>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	618080e7          	jalr	1560(ra) # 80000c8a <release>
}
    8000467a:	60e2                	ld	ra,24(sp)
    8000467c:	6442                	ld	s0,16(sp)
    8000467e:	64a2                	ld	s1,8(sp)
    80004680:	6902                	ld	s2,0(sp)
    80004682:	6105                	addi	sp,sp,32
    80004684:	8082                	ret

0000000080004686 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004686:	1101                	addi	sp,sp,-32
    80004688:	ec06                	sd	ra,24(sp)
    8000468a:	e822                	sd	s0,16(sp)
    8000468c:	e426                	sd	s1,8(sp)
    8000468e:	e04a                	sd	s2,0(sp)
    80004690:	1000                	addi	s0,sp,32
    80004692:	84aa                	mv	s1,a0
    80004694:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004696:	00004597          	auipc	a1,0x4
    8000469a:	00258593          	addi	a1,a1,2 # 80008698 <syscalls+0x248>
    8000469e:	0521                	addi	a0,a0,8
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	4a6080e7          	jalr	1190(ra) # 80000b46 <initlock>
  lk->name = name;
    800046a8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b0:	0204a423          	sw	zero,40(s1)
}
    800046b4:	60e2                	ld	ra,24(sp)
    800046b6:	6442                	ld	s0,16(sp)
    800046b8:	64a2                	ld	s1,8(sp)
    800046ba:	6902                	ld	s2,0(sp)
    800046bc:	6105                	addi	sp,sp,32
    800046be:	8082                	ret

00000000800046c0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046c0:	1101                	addi	sp,sp,-32
    800046c2:	ec06                	sd	ra,24(sp)
    800046c4:	e822                	sd	s0,16(sp)
    800046c6:	e426                	sd	s1,8(sp)
    800046c8:	e04a                	sd	s2,0(sp)
    800046ca:	1000                	addi	s0,sp,32
    800046cc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ce:	00850913          	addi	s2,a0,8
    800046d2:	854a                	mv	a0,s2
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	502080e7          	jalr	1282(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046dc:	409c                	lw	a5,0(s1)
    800046de:	cb89                	beqz	a5,800046f0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046e0:	85ca                	mv	a1,s2
    800046e2:	8526                	mv	a0,s1
    800046e4:	ffffe097          	auipc	ra,0xffffe
    800046e8:	9bc080e7          	jalr	-1604(ra) # 800020a0 <sleep>
  while (lk->locked) {
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	fbed                	bnez	a5,800046e0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046f0:	4785                	li	a5,1
    800046f2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	2b8080e7          	jalr	696(ra) # 800019ac <myproc>
    800046fc:	591c                	lw	a5,48(a0)
    800046fe:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004700:	854a                	mv	a0,s2
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	588080e7          	jalr	1416(ra) # 80000c8a <release>
}
    8000470a:	60e2                	ld	ra,24(sp)
    8000470c:	6442                	ld	s0,16(sp)
    8000470e:	64a2                	ld	s1,8(sp)
    80004710:	6902                	ld	s2,0(sp)
    80004712:	6105                	addi	sp,sp,32
    80004714:	8082                	ret

0000000080004716 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004716:	1101                	addi	sp,sp,-32
    80004718:	ec06                	sd	ra,24(sp)
    8000471a:	e822                	sd	s0,16(sp)
    8000471c:	e426                	sd	s1,8(sp)
    8000471e:	e04a                	sd	s2,0(sp)
    80004720:	1000                	addi	s0,sp,32
    80004722:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004724:	00850913          	addi	s2,a0,8
    80004728:	854a                	mv	a0,s2
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	4ac080e7          	jalr	1196(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004732:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004736:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffe097          	auipc	ra,0xffffe
    80004740:	9c8080e7          	jalr	-1592(ra) # 80002104 <wakeup>
  release(&lk->lk);
    80004744:	854a                	mv	a0,s2
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
}
    8000474e:	60e2                	ld	ra,24(sp)
    80004750:	6442                	ld	s0,16(sp)
    80004752:	64a2                	ld	s1,8(sp)
    80004754:	6902                	ld	s2,0(sp)
    80004756:	6105                	addi	sp,sp,32
    80004758:	8082                	ret

000000008000475a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000475a:	7179                	addi	sp,sp,-48
    8000475c:	f406                	sd	ra,40(sp)
    8000475e:	f022                	sd	s0,32(sp)
    80004760:	ec26                	sd	s1,24(sp)
    80004762:	e84a                	sd	s2,16(sp)
    80004764:	e44e                	sd	s3,8(sp)
    80004766:	1800                	addi	s0,sp,48
    80004768:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000476a:	00850913          	addi	s2,a0,8
    8000476e:	854a                	mv	a0,s2
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	466080e7          	jalr	1126(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004778:	409c                	lw	a5,0(s1)
    8000477a:	ef99                	bnez	a5,80004798 <holdingsleep+0x3e>
    8000477c:	4481                	li	s1,0
  release(&lk->lk);
    8000477e:	854a                	mv	a0,s2
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	50a080e7          	jalr	1290(ra) # 80000c8a <release>
  return r;
}
    80004788:	8526                	mv	a0,s1
    8000478a:	70a2                	ld	ra,40(sp)
    8000478c:	7402                	ld	s0,32(sp)
    8000478e:	64e2                	ld	s1,24(sp)
    80004790:	6942                	ld	s2,16(sp)
    80004792:	69a2                	ld	s3,8(sp)
    80004794:	6145                	addi	sp,sp,48
    80004796:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004798:	0284a983          	lw	s3,40(s1)
    8000479c:	ffffd097          	auipc	ra,0xffffd
    800047a0:	210080e7          	jalr	528(ra) # 800019ac <myproc>
    800047a4:	5904                	lw	s1,48(a0)
    800047a6:	413484b3          	sub	s1,s1,s3
    800047aa:	0014b493          	seqz	s1,s1
    800047ae:	bfc1                	j	8000477e <holdingsleep+0x24>

00000000800047b0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047b0:	1141                	addi	sp,sp,-16
    800047b2:	e406                	sd	ra,8(sp)
    800047b4:	e022                	sd	s0,0(sp)
    800047b6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047b8:	00004597          	auipc	a1,0x4
    800047bc:	ef058593          	addi	a1,a1,-272 # 800086a8 <syscalls+0x258>
    800047c0:	0001e517          	auipc	a0,0x1e
    800047c4:	ce850513          	addi	a0,a0,-792 # 800224a8 <ftable>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	37e080e7          	jalr	894(ra) # 80000b46 <initlock>
}
    800047d0:	60a2                	ld	ra,8(sp)
    800047d2:	6402                	ld	s0,0(sp)
    800047d4:	0141                	addi	sp,sp,16
    800047d6:	8082                	ret

00000000800047d8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047d8:	1101                	addi	sp,sp,-32
    800047da:	ec06                	sd	ra,24(sp)
    800047dc:	e822                	sd	s0,16(sp)
    800047de:	e426                	sd	s1,8(sp)
    800047e0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047e2:	0001e517          	auipc	a0,0x1e
    800047e6:	cc650513          	addi	a0,a0,-826 # 800224a8 <ftable>
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	3ec080e7          	jalr	1004(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047f2:	0001e497          	auipc	s1,0x1e
    800047f6:	cce48493          	addi	s1,s1,-818 # 800224c0 <ftable+0x18>
    800047fa:	0001f717          	auipc	a4,0x1f
    800047fe:	c6670713          	addi	a4,a4,-922 # 80023460 <disk>
    if(f->ref == 0){
    80004802:	40dc                	lw	a5,4(s1)
    80004804:	cf99                	beqz	a5,80004822 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004806:	02848493          	addi	s1,s1,40
    8000480a:	fee49ce3          	bne	s1,a4,80004802 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000480e:	0001e517          	auipc	a0,0x1e
    80004812:	c9a50513          	addi	a0,a0,-870 # 800224a8 <ftable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	474080e7          	jalr	1140(ra) # 80000c8a <release>
  return 0;
    8000481e:	4481                	li	s1,0
    80004820:	a819                	j	80004836 <filealloc+0x5e>
      f->ref = 1;
    80004822:	4785                	li	a5,1
    80004824:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004826:	0001e517          	auipc	a0,0x1e
    8000482a:	c8250513          	addi	a0,a0,-894 # 800224a8 <ftable>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	45c080e7          	jalr	1116(ra) # 80000c8a <release>
}
    80004836:	8526                	mv	a0,s1
    80004838:	60e2                	ld	ra,24(sp)
    8000483a:	6442                	ld	s0,16(sp)
    8000483c:	64a2                	ld	s1,8(sp)
    8000483e:	6105                	addi	sp,sp,32
    80004840:	8082                	ret

0000000080004842 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004842:	1101                	addi	sp,sp,-32
    80004844:	ec06                	sd	ra,24(sp)
    80004846:	e822                	sd	s0,16(sp)
    80004848:	e426                	sd	s1,8(sp)
    8000484a:	1000                	addi	s0,sp,32
    8000484c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000484e:	0001e517          	auipc	a0,0x1e
    80004852:	c5a50513          	addi	a0,a0,-934 # 800224a8 <ftable>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	380080e7          	jalr	896(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000485e:	40dc                	lw	a5,4(s1)
    80004860:	02f05263          	blez	a5,80004884 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004864:	2785                	addiw	a5,a5,1
    80004866:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004868:	0001e517          	auipc	a0,0x1e
    8000486c:	c4050513          	addi	a0,a0,-960 # 800224a8 <ftable>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	41a080e7          	jalr	1050(ra) # 80000c8a <release>
  return f;
}
    80004878:	8526                	mv	a0,s1
    8000487a:	60e2                	ld	ra,24(sp)
    8000487c:	6442                	ld	s0,16(sp)
    8000487e:	64a2                	ld	s1,8(sp)
    80004880:	6105                	addi	sp,sp,32
    80004882:	8082                	ret
    panic("filedup");
    80004884:	00004517          	auipc	a0,0x4
    80004888:	e2c50513          	addi	a0,a0,-468 # 800086b0 <syscalls+0x260>
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	cb4080e7          	jalr	-844(ra) # 80000540 <panic>

0000000080004894 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004894:	7139                	addi	sp,sp,-64
    80004896:	fc06                	sd	ra,56(sp)
    80004898:	f822                	sd	s0,48(sp)
    8000489a:	f426                	sd	s1,40(sp)
    8000489c:	f04a                	sd	s2,32(sp)
    8000489e:	ec4e                	sd	s3,24(sp)
    800048a0:	e852                	sd	s4,16(sp)
    800048a2:	e456                	sd	s5,8(sp)
    800048a4:	0080                	addi	s0,sp,64
    800048a6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048a8:	0001e517          	auipc	a0,0x1e
    800048ac:	c0050513          	addi	a0,a0,-1024 # 800224a8 <ftable>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	326080e7          	jalr	806(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048b8:	40dc                	lw	a5,4(s1)
    800048ba:	06f05163          	blez	a5,8000491c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048be:	37fd                	addiw	a5,a5,-1
    800048c0:	0007871b          	sext.w	a4,a5
    800048c4:	c0dc                	sw	a5,4(s1)
    800048c6:	06e04363          	bgtz	a4,8000492c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048ca:	0004a903          	lw	s2,0(s1)
    800048ce:	0094ca83          	lbu	s5,9(s1)
    800048d2:	0104ba03          	ld	s4,16(s1)
    800048d6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048da:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048de:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048e2:	0001e517          	auipc	a0,0x1e
    800048e6:	bc650513          	addi	a0,a0,-1082 # 800224a8 <ftable>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	3a0080e7          	jalr	928(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048f2:	4785                	li	a5,1
    800048f4:	04f90d63          	beq	s2,a5,8000494e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048f8:	3979                	addiw	s2,s2,-2
    800048fa:	4785                	li	a5,1
    800048fc:	0527e063          	bltu	a5,s2,8000493c <fileclose+0xa8>
    begin_op();
    80004900:	00000097          	auipc	ra,0x0
    80004904:	acc080e7          	jalr	-1332(ra) # 800043cc <begin_op>
    iput(ff.ip);
    80004908:	854e                	mv	a0,s3
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	2b0080e7          	jalr	688(ra) # 80003bba <iput>
    end_op();
    80004912:	00000097          	auipc	ra,0x0
    80004916:	b38080e7          	jalr	-1224(ra) # 8000444a <end_op>
    8000491a:	a00d                	j	8000493c <fileclose+0xa8>
    panic("fileclose");
    8000491c:	00004517          	auipc	a0,0x4
    80004920:	d9c50513          	addi	a0,a0,-612 # 800086b8 <syscalls+0x268>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	c1c080e7          	jalr	-996(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000492c:	0001e517          	auipc	a0,0x1e
    80004930:	b7c50513          	addi	a0,a0,-1156 # 800224a8 <ftable>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	356080e7          	jalr	854(ra) # 80000c8a <release>
  }
}
    8000493c:	70e2                	ld	ra,56(sp)
    8000493e:	7442                	ld	s0,48(sp)
    80004940:	74a2                	ld	s1,40(sp)
    80004942:	7902                	ld	s2,32(sp)
    80004944:	69e2                	ld	s3,24(sp)
    80004946:	6a42                	ld	s4,16(sp)
    80004948:	6aa2                	ld	s5,8(sp)
    8000494a:	6121                	addi	sp,sp,64
    8000494c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000494e:	85d6                	mv	a1,s5
    80004950:	8552                	mv	a0,s4
    80004952:	00000097          	auipc	ra,0x0
    80004956:	34c080e7          	jalr	844(ra) # 80004c9e <pipeclose>
    8000495a:	b7cd                	j	8000493c <fileclose+0xa8>

000000008000495c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000495c:	715d                	addi	sp,sp,-80
    8000495e:	e486                	sd	ra,72(sp)
    80004960:	e0a2                	sd	s0,64(sp)
    80004962:	fc26                	sd	s1,56(sp)
    80004964:	f84a                	sd	s2,48(sp)
    80004966:	f44e                	sd	s3,40(sp)
    80004968:	0880                	addi	s0,sp,80
    8000496a:	84aa                	mv	s1,a0
    8000496c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000496e:	ffffd097          	auipc	ra,0xffffd
    80004972:	03e080e7          	jalr	62(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004976:	409c                	lw	a5,0(s1)
    80004978:	37f9                	addiw	a5,a5,-2
    8000497a:	4705                	li	a4,1
    8000497c:	04f76763          	bltu	a4,a5,800049ca <filestat+0x6e>
    80004980:	892a                	mv	s2,a0
    ilock(f->ip);
    80004982:	6c88                	ld	a0,24(s1)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	07c080e7          	jalr	124(ra) # 80003a00 <ilock>
    stati(f->ip, &st);
    8000498c:	fb840593          	addi	a1,s0,-72
    80004990:	6c88                	ld	a0,24(s1)
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	2f8080e7          	jalr	760(ra) # 80003c8a <stati>
    iunlock(f->ip);
    8000499a:	6c88                	ld	a0,24(s1)
    8000499c:	fffff097          	auipc	ra,0xfffff
    800049a0:	126080e7          	jalr	294(ra) # 80003ac2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049a4:	46e1                	li	a3,24
    800049a6:	fb840613          	addi	a2,s0,-72
    800049aa:	85ce                	mv	a1,s3
    800049ac:	05093503          	ld	a0,80(s2)
    800049b0:	ffffd097          	auipc	ra,0xffffd
    800049b4:	cbc080e7          	jalr	-836(ra) # 8000166c <copyout>
    800049b8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049bc:	60a6                	ld	ra,72(sp)
    800049be:	6406                	ld	s0,64(sp)
    800049c0:	74e2                	ld	s1,56(sp)
    800049c2:	7942                	ld	s2,48(sp)
    800049c4:	79a2                	ld	s3,40(sp)
    800049c6:	6161                	addi	sp,sp,80
    800049c8:	8082                	ret
  return -1;
    800049ca:	557d                	li	a0,-1
    800049cc:	bfc5                	j	800049bc <filestat+0x60>

00000000800049ce <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049ce:	7179                	addi	sp,sp,-48
    800049d0:	f406                	sd	ra,40(sp)
    800049d2:	f022                	sd	s0,32(sp)
    800049d4:	ec26                	sd	s1,24(sp)
    800049d6:	e84a                	sd	s2,16(sp)
    800049d8:	e44e                	sd	s3,8(sp)
    800049da:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049dc:	00854783          	lbu	a5,8(a0)
    800049e0:	c3d5                	beqz	a5,80004a84 <fileread+0xb6>
    800049e2:	84aa                	mv	s1,a0
    800049e4:	89ae                	mv	s3,a1
    800049e6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049e8:	411c                	lw	a5,0(a0)
    800049ea:	4705                	li	a4,1
    800049ec:	04e78963          	beq	a5,a4,80004a3e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049f0:	470d                	li	a4,3
    800049f2:	04e78d63          	beq	a5,a4,80004a4c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049f6:	4709                	li	a4,2
    800049f8:	06e79e63          	bne	a5,a4,80004a74 <fileread+0xa6>
    ilock(f->ip);
    800049fc:	6d08                	ld	a0,24(a0)
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	002080e7          	jalr	2(ra) # 80003a00 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a06:	874a                	mv	a4,s2
    80004a08:	5094                	lw	a3,32(s1)
    80004a0a:	864e                	mv	a2,s3
    80004a0c:	4585                	li	a1,1
    80004a0e:	6c88                	ld	a0,24(s1)
    80004a10:	fffff097          	auipc	ra,0xfffff
    80004a14:	2a4080e7          	jalr	676(ra) # 80003cb4 <readi>
    80004a18:	892a                	mv	s2,a0
    80004a1a:	00a05563          	blez	a0,80004a24 <fileread+0x56>
      f->off += r;
    80004a1e:	509c                	lw	a5,32(s1)
    80004a20:	9fa9                	addw	a5,a5,a0
    80004a22:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a24:	6c88                	ld	a0,24(s1)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	09c080e7          	jalr	156(ra) # 80003ac2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a2e:	854a                	mv	a0,s2
    80004a30:	70a2                	ld	ra,40(sp)
    80004a32:	7402                	ld	s0,32(sp)
    80004a34:	64e2                	ld	s1,24(sp)
    80004a36:	6942                	ld	s2,16(sp)
    80004a38:	69a2                	ld	s3,8(sp)
    80004a3a:	6145                	addi	sp,sp,48
    80004a3c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a3e:	6908                	ld	a0,16(a0)
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	3c6080e7          	jalr	966(ra) # 80004e06 <piperead>
    80004a48:	892a                	mv	s2,a0
    80004a4a:	b7d5                	j	80004a2e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a4c:	02451783          	lh	a5,36(a0)
    80004a50:	03079693          	slli	a3,a5,0x30
    80004a54:	92c1                	srli	a3,a3,0x30
    80004a56:	4725                	li	a4,9
    80004a58:	02d76863          	bltu	a4,a3,80004a88 <fileread+0xba>
    80004a5c:	0792                	slli	a5,a5,0x4
    80004a5e:	0001e717          	auipc	a4,0x1e
    80004a62:	9aa70713          	addi	a4,a4,-1622 # 80022408 <devsw>
    80004a66:	97ba                	add	a5,a5,a4
    80004a68:	639c                	ld	a5,0(a5)
    80004a6a:	c38d                	beqz	a5,80004a8c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a6c:	4505                	li	a0,1
    80004a6e:	9782                	jalr	a5
    80004a70:	892a                	mv	s2,a0
    80004a72:	bf75                	j	80004a2e <fileread+0x60>
    panic("fileread");
    80004a74:	00004517          	auipc	a0,0x4
    80004a78:	c5450513          	addi	a0,a0,-940 # 800086c8 <syscalls+0x278>
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	ac4080e7          	jalr	-1340(ra) # 80000540 <panic>
    return -1;
    80004a84:	597d                	li	s2,-1
    80004a86:	b765                	j	80004a2e <fileread+0x60>
      return -1;
    80004a88:	597d                	li	s2,-1
    80004a8a:	b755                	j	80004a2e <fileread+0x60>
    80004a8c:	597d                	li	s2,-1
    80004a8e:	b745                	j	80004a2e <fileread+0x60>

0000000080004a90 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a90:	715d                	addi	sp,sp,-80
    80004a92:	e486                	sd	ra,72(sp)
    80004a94:	e0a2                	sd	s0,64(sp)
    80004a96:	fc26                	sd	s1,56(sp)
    80004a98:	f84a                	sd	s2,48(sp)
    80004a9a:	f44e                	sd	s3,40(sp)
    80004a9c:	f052                	sd	s4,32(sp)
    80004a9e:	ec56                	sd	s5,24(sp)
    80004aa0:	e85a                	sd	s6,16(sp)
    80004aa2:	e45e                	sd	s7,8(sp)
    80004aa4:	e062                	sd	s8,0(sp)
    80004aa6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004aa8:	00954783          	lbu	a5,9(a0)
    80004aac:	10078663          	beqz	a5,80004bb8 <filewrite+0x128>
    80004ab0:	892a                	mv	s2,a0
    80004ab2:	8b2e                	mv	s6,a1
    80004ab4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ab6:	411c                	lw	a5,0(a0)
    80004ab8:	4705                	li	a4,1
    80004aba:	02e78263          	beq	a5,a4,80004ade <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004abe:	470d                	li	a4,3
    80004ac0:	02e78663          	beq	a5,a4,80004aec <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ac4:	4709                	li	a4,2
    80004ac6:	0ee79163          	bne	a5,a4,80004ba8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004aca:	0ac05d63          	blez	a2,80004b84 <filewrite+0xf4>
    int i = 0;
    80004ace:	4981                	li	s3,0
    80004ad0:	6b85                	lui	s7,0x1
    80004ad2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ad6:	6c05                	lui	s8,0x1
    80004ad8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004adc:	a861                	j	80004b74 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ade:	6908                	ld	a0,16(a0)
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	22e080e7          	jalr	558(ra) # 80004d0e <pipewrite>
    80004ae8:	8a2a                	mv	s4,a0
    80004aea:	a045                	j	80004b8a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aec:	02451783          	lh	a5,36(a0)
    80004af0:	03079693          	slli	a3,a5,0x30
    80004af4:	92c1                	srli	a3,a3,0x30
    80004af6:	4725                	li	a4,9
    80004af8:	0cd76263          	bltu	a4,a3,80004bbc <filewrite+0x12c>
    80004afc:	0792                	slli	a5,a5,0x4
    80004afe:	0001e717          	auipc	a4,0x1e
    80004b02:	90a70713          	addi	a4,a4,-1782 # 80022408 <devsw>
    80004b06:	97ba                	add	a5,a5,a4
    80004b08:	679c                	ld	a5,8(a5)
    80004b0a:	cbdd                	beqz	a5,80004bc0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b0c:	4505                	li	a0,1
    80004b0e:	9782                	jalr	a5
    80004b10:	8a2a                	mv	s4,a0
    80004b12:	a8a5                	j	80004b8a <filewrite+0xfa>
    80004b14:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b18:	00000097          	auipc	ra,0x0
    80004b1c:	8b4080e7          	jalr	-1868(ra) # 800043cc <begin_op>
      ilock(f->ip);
    80004b20:	01893503          	ld	a0,24(s2)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	edc080e7          	jalr	-292(ra) # 80003a00 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b2c:	8756                	mv	a4,s5
    80004b2e:	02092683          	lw	a3,32(s2)
    80004b32:	01698633          	add	a2,s3,s6
    80004b36:	4585                	li	a1,1
    80004b38:	01893503          	ld	a0,24(s2)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	270080e7          	jalr	624(ra) # 80003dac <writei>
    80004b44:	84aa                	mv	s1,a0
    80004b46:	00a05763          	blez	a0,80004b54 <filewrite+0xc4>
        f->off += r;
    80004b4a:	02092783          	lw	a5,32(s2)
    80004b4e:	9fa9                	addw	a5,a5,a0
    80004b50:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b54:	01893503          	ld	a0,24(s2)
    80004b58:	fffff097          	auipc	ra,0xfffff
    80004b5c:	f6a080e7          	jalr	-150(ra) # 80003ac2 <iunlock>
      end_op();
    80004b60:	00000097          	auipc	ra,0x0
    80004b64:	8ea080e7          	jalr	-1814(ra) # 8000444a <end_op>

      if(r != n1){
    80004b68:	009a9f63          	bne	s5,s1,80004b86 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b6c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b70:	0149db63          	bge	s3,s4,80004b86 <filewrite+0xf6>
      int n1 = n - i;
    80004b74:	413a04bb          	subw	s1,s4,s3
    80004b78:	0004879b          	sext.w	a5,s1
    80004b7c:	f8fbdce3          	bge	s7,a5,80004b14 <filewrite+0x84>
    80004b80:	84e2                	mv	s1,s8
    80004b82:	bf49                	j	80004b14 <filewrite+0x84>
    int i = 0;
    80004b84:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b86:	013a1f63          	bne	s4,s3,80004ba4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b8a:	8552                	mv	a0,s4
    80004b8c:	60a6                	ld	ra,72(sp)
    80004b8e:	6406                	ld	s0,64(sp)
    80004b90:	74e2                	ld	s1,56(sp)
    80004b92:	7942                	ld	s2,48(sp)
    80004b94:	79a2                	ld	s3,40(sp)
    80004b96:	7a02                	ld	s4,32(sp)
    80004b98:	6ae2                	ld	s5,24(sp)
    80004b9a:	6b42                	ld	s6,16(sp)
    80004b9c:	6ba2                	ld	s7,8(sp)
    80004b9e:	6c02                	ld	s8,0(sp)
    80004ba0:	6161                	addi	sp,sp,80
    80004ba2:	8082                	ret
    ret = (i == n ? n : -1);
    80004ba4:	5a7d                	li	s4,-1
    80004ba6:	b7d5                	j	80004b8a <filewrite+0xfa>
    panic("filewrite");
    80004ba8:	00004517          	auipc	a0,0x4
    80004bac:	b3050513          	addi	a0,a0,-1232 # 800086d8 <syscalls+0x288>
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	990080e7          	jalr	-1648(ra) # 80000540 <panic>
    return -1;
    80004bb8:	5a7d                	li	s4,-1
    80004bba:	bfc1                	j	80004b8a <filewrite+0xfa>
      return -1;
    80004bbc:	5a7d                	li	s4,-1
    80004bbe:	b7f1                	j	80004b8a <filewrite+0xfa>
    80004bc0:	5a7d                	li	s4,-1
    80004bc2:	b7e1                	j	80004b8a <filewrite+0xfa>

0000000080004bc4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bc4:	7179                	addi	sp,sp,-48
    80004bc6:	f406                	sd	ra,40(sp)
    80004bc8:	f022                	sd	s0,32(sp)
    80004bca:	ec26                	sd	s1,24(sp)
    80004bcc:	e84a                	sd	s2,16(sp)
    80004bce:	e44e                	sd	s3,8(sp)
    80004bd0:	e052                	sd	s4,0(sp)
    80004bd2:	1800                	addi	s0,sp,48
    80004bd4:	84aa                	mv	s1,a0
    80004bd6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bd8:	0005b023          	sd	zero,0(a1)
    80004bdc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	bf8080e7          	jalr	-1032(ra) # 800047d8 <filealloc>
    80004be8:	e088                	sd	a0,0(s1)
    80004bea:	c551                	beqz	a0,80004c76 <pipealloc+0xb2>
    80004bec:	00000097          	auipc	ra,0x0
    80004bf0:	bec080e7          	jalr	-1044(ra) # 800047d8 <filealloc>
    80004bf4:	00aa3023          	sd	a0,0(s4)
    80004bf8:	c92d                	beqz	a0,80004c6a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	eec080e7          	jalr	-276(ra) # 80000ae6 <kalloc>
    80004c02:	892a                	mv	s2,a0
    80004c04:	c125                	beqz	a0,80004c64 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c06:	4985                	li	s3,1
    80004c08:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c0c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c10:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c14:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c18:	00004597          	auipc	a1,0x4
    80004c1c:	ad058593          	addi	a1,a1,-1328 # 800086e8 <syscalls+0x298>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	f26080e7          	jalr	-218(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c28:	609c                	ld	a5,0(s1)
    80004c2a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c2e:	609c                	ld	a5,0(s1)
    80004c30:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c34:	609c                	ld	a5,0(s1)
    80004c36:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c3a:	609c                	ld	a5,0(s1)
    80004c3c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c40:	000a3783          	ld	a5,0(s4)
    80004c44:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c48:	000a3783          	ld	a5,0(s4)
    80004c4c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c50:	000a3783          	ld	a5,0(s4)
    80004c54:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c58:	000a3783          	ld	a5,0(s4)
    80004c5c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c60:	4501                	li	a0,0
    80004c62:	a025                	j	80004c8a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c64:	6088                	ld	a0,0(s1)
    80004c66:	e501                	bnez	a0,80004c6e <pipealloc+0xaa>
    80004c68:	a039                	j	80004c76 <pipealloc+0xb2>
    80004c6a:	6088                	ld	a0,0(s1)
    80004c6c:	c51d                	beqz	a0,80004c9a <pipealloc+0xd6>
    fileclose(*f0);
    80004c6e:	00000097          	auipc	ra,0x0
    80004c72:	c26080e7          	jalr	-986(ra) # 80004894 <fileclose>
  if(*f1)
    80004c76:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c7a:	557d                	li	a0,-1
  if(*f1)
    80004c7c:	c799                	beqz	a5,80004c8a <pipealloc+0xc6>
    fileclose(*f1);
    80004c7e:	853e                	mv	a0,a5
    80004c80:	00000097          	auipc	ra,0x0
    80004c84:	c14080e7          	jalr	-1004(ra) # 80004894 <fileclose>
  return -1;
    80004c88:	557d                	li	a0,-1
}
    80004c8a:	70a2                	ld	ra,40(sp)
    80004c8c:	7402                	ld	s0,32(sp)
    80004c8e:	64e2                	ld	s1,24(sp)
    80004c90:	6942                	ld	s2,16(sp)
    80004c92:	69a2                	ld	s3,8(sp)
    80004c94:	6a02                	ld	s4,0(sp)
    80004c96:	6145                	addi	sp,sp,48
    80004c98:	8082                	ret
  return -1;
    80004c9a:	557d                	li	a0,-1
    80004c9c:	b7fd                	j	80004c8a <pipealloc+0xc6>

0000000080004c9e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c9e:	1101                	addi	sp,sp,-32
    80004ca0:	ec06                	sd	ra,24(sp)
    80004ca2:	e822                	sd	s0,16(sp)
    80004ca4:	e426                	sd	s1,8(sp)
    80004ca6:	e04a                	sd	s2,0(sp)
    80004ca8:	1000                	addi	s0,sp,32
    80004caa:	84aa                	mv	s1,a0
    80004cac:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	f28080e7          	jalr	-216(ra) # 80000bd6 <acquire>
  if(writable){
    80004cb6:	02090d63          	beqz	s2,80004cf0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cba:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cbe:	21848513          	addi	a0,s1,536
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	442080e7          	jalr	1090(ra) # 80002104 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cca:	2204b783          	ld	a5,544(s1)
    80004cce:	eb95                	bnez	a5,80004d02 <pipeclose+0x64>
    release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fb8080e7          	jalr	-72(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	d0c080e7          	jalr	-756(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004ce4:	60e2                	ld	ra,24(sp)
    80004ce6:	6442                	ld	s0,16(sp)
    80004ce8:	64a2                	ld	s1,8(sp)
    80004cea:	6902                	ld	s2,0(sp)
    80004cec:	6105                	addi	sp,sp,32
    80004cee:	8082                	ret
    pi->readopen = 0;
    80004cf0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cf4:	21c48513          	addi	a0,s1,540
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	40c080e7          	jalr	1036(ra) # 80002104 <wakeup>
    80004d00:	b7e9                	j	80004cca <pipeclose+0x2c>
    release(&pi->lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	f86080e7          	jalr	-122(ra) # 80000c8a <release>
}
    80004d0c:	bfe1                	j	80004ce4 <pipeclose+0x46>

0000000080004d0e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d0e:	711d                	addi	sp,sp,-96
    80004d10:	ec86                	sd	ra,88(sp)
    80004d12:	e8a2                	sd	s0,80(sp)
    80004d14:	e4a6                	sd	s1,72(sp)
    80004d16:	e0ca                	sd	s2,64(sp)
    80004d18:	fc4e                	sd	s3,56(sp)
    80004d1a:	f852                	sd	s4,48(sp)
    80004d1c:	f456                	sd	s5,40(sp)
    80004d1e:	f05a                	sd	s6,32(sp)
    80004d20:	ec5e                	sd	s7,24(sp)
    80004d22:	e862                	sd	s8,16(sp)
    80004d24:	1080                	addi	s0,sp,96
    80004d26:	84aa                	mv	s1,a0
    80004d28:	8aae                	mv	s5,a1
    80004d2a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d2c:	ffffd097          	auipc	ra,0xffffd
    80004d30:	c80080e7          	jalr	-896(ra) # 800019ac <myproc>
    80004d34:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	e9e080e7          	jalr	-354(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d40:	0b405663          	blez	s4,80004dec <pipewrite+0xde>
  int i = 0;
    80004d44:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d46:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d48:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d4c:	21c48b93          	addi	s7,s1,540
    80004d50:	a089                	j	80004d92 <pipewrite+0x84>
      release(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	f36080e7          	jalr	-202(ra) # 80000c8a <release>
      return -1;
    80004d5c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d5e:	854a                	mv	a0,s2
    80004d60:	60e6                	ld	ra,88(sp)
    80004d62:	6446                	ld	s0,80(sp)
    80004d64:	64a6                	ld	s1,72(sp)
    80004d66:	6906                	ld	s2,64(sp)
    80004d68:	79e2                	ld	s3,56(sp)
    80004d6a:	7a42                	ld	s4,48(sp)
    80004d6c:	7aa2                	ld	s5,40(sp)
    80004d6e:	7b02                	ld	s6,32(sp)
    80004d70:	6be2                	ld	s7,24(sp)
    80004d72:	6c42                	ld	s8,16(sp)
    80004d74:	6125                	addi	sp,sp,96
    80004d76:	8082                	ret
      wakeup(&pi->nread);
    80004d78:	8562                	mv	a0,s8
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	38a080e7          	jalr	906(ra) # 80002104 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d82:	85a6                	mv	a1,s1
    80004d84:	855e                	mv	a0,s7
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	31a080e7          	jalr	794(ra) # 800020a0 <sleep>
  while(i < n){
    80004d8e:	07495063          	bge	s2,s4,80004dee <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d92:	2204a783          	lw	a5,544(s1)
    80004d96:	dfd5                	beqz	a5,80004d52 <pipewrite+0x44>
    80004d98:	854e                	mv	a0,s3
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	5ba080e7          	jalr	1466(ra) # 80002354 <killed>
    80004da2:	f945                	bnez	a0,80004d52 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004da4:	2184a783          	lw	a5,536(s1)
    80004da8:	21c4a703          	lw	a4,540(s1)
    80004dac:	2007879b          	addiw	a5,a5,512
    80004db0:	fcf704e3          	beq	a4,a5,80004d78 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004db4:	4685                	li	a3,1
    80004db6:	01590633          	add	a2,s2,s5
    80004dba:	faf40593          	addi	a1,s0,-81
    80004dbe:	0509b503          	ld	a0,80(s3)
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	936080e7          	jalr	-1738(ra) # 800016f8 <copyin>
    80004dca:	03650263          	beq	a0,s6,80004dee <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dce:	21c4a783          	lw	a5,540(s1)
    80004dd2:	0017871b          	addiw	a4,a5,1
    80004dd6:	20e4ae23          	sw	a4,540(s1)
    80004dda:	1ff7f793          	andi	a5,a5,511
    80004dde:	97a6                	add	a5,a5,s1
    80004de0:	faf44703          	lbu	a4,-81(s0)
    80004de4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004de8:	2905                	addiw	s2,s2,1
    80004dea:	b755                	j	80004d8e <pipewrite+0x80>
  int i = 0;
    80004dec:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dee:	21848513          	addi	a0,s1,536
    80004df2:	ffffd097          	auipc	ra,0xffffd
    80004df6:	312080e7          	jalr	786(ra) # 80002104 <wakeup>
  release(&pi->lock);
    80004dfa:	8526                	mv	a0,s1
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	e8e080e7          	jalr	-370(ra) # 80000c8a <release>
  return i;
    80004e04:	bfa9                	j	80004d5e <pipewrite+0x50>

0000000080004e06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e06:	715d                	addi	sp,sp,-80
    80004e08:	e486                	sd	ra,72(sp)
    80004e0a:	e0a2                	sd	s0,64(sp)
    80004e0c:	fc26                	sd	s1,56(sp)
    80004e0e:	f84a                	sd	s2,48(sp)
    80004e10:	f44e                	sd	s3,40(sp)
    80004e12:	f052                	sd	s4,32(sp)
    80004e14:	ec56                	sd	s5,24(sp)
    80004e16:	e85a                	sd	s6,16(sp)
    80004e18:	0880                	addi	s0,sp,80
    80004e1a:	84aa                	mv	s1,a0
    80004e1c:	892e                	mv	s2,a1
    80004e1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	b8c080e7          	jalr	-1140(ra) # 800019ac <myproc>
    80004e28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	daa080e7          	jalr	-598(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e34:	2184a703          	lw	a4,536(s1)
    80004e38:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e3c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e40:	02f71763          	bne	a4,a5,80004e6e <piperead+0x68>
    80004e44:	2244a783          	lw	a5,548(s1)
    80004e48:	c39d                	beqz	a5,80004e6e <piperead+0x68>
    if(killed(pr)){
    80004e4a:	8552                	mv	a0,s4
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	508080e7          	jalr	1288(ra) # 80002354 <killed>
    80004e54:	e949                	bnez	a0,80004ee6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e56:	85a6                	mv	a1,s1
    80004e58:	854e                	mv	a0,s3
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	246080e7          	jalr	582(ra) # 800020a0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e62:	2184a703          	lw	a4,536(s1)
    80004e66:	21c4a783          	lw	a5,540(s1)
    80004e6a:	fcf70de3          	beq	a4,a5,80004e44 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e70:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e72:	05505463          	blez	s5,80004eba <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e76:	2184a783          	lw	a5,536(s1)
    80004e7a:	21c4a703          	lw	a4,540(s1)
    80004e7e:	02f70e63          	beq	a4,a5,80004eba <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e82:	0017871b          	addiw	a4,a5,1
    80004e86:	20e4ac23          	sw	a4,536(s1)
    80004e8a:	1ff7f793          	andi	a5,a5,511
    80004e8e:	97a6                	add	a5,a5,s1
    80004e90:	0187c783          	lbu	a5,24(a5)
    80004e94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e98:	4685                	li	a3,1
    80004e9a:	fbf40613          	addi	a2,s0,-65
    80004e9e:	85ca                	mv	a1,s2
    80004ea0:	050a3503          	ld	a0,80(s4)
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	7c8080e7          	jalr	1992(ra) # 8000166c <copyout>
    80004eac:	01650763          	beq	a0,s6,80004eba <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb0:	2985                	addiw	s3,s3,1
    80004eb2:	0905                	addi	s2,s2,1
    80004eb4:	fd3a91e3          	bne	s5,s3,80004e76 <piperead+0x70>
    80004eb8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eba:	21c48513          	addi	a0,s1,540
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	246080e7          	jalr	582(ra) # 80002104 <wakeup>
  release(&pi->lock);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	dc2080e7          	jalr	-574(ra) # 80000c8a <release>
  return i;
}
    80004ed0:	854e                	mv	a0,s3
    80004ed2:	60a6                	ld	ra,72(sp)
    80004ed4:	6406                	ld	s0,64(sp)
    80004ed6:	74e2                	ld	s1,56(sp)
    80004ed8:	7942                	ld	s2,48(sp)
    80004eda:	79a2                	ld	s3,40(sp)
    80004edc:	7a02                	ld	s4,32(sp)
    80004ede:	6ae2                	ld	s5,24(sp)
    80004ee0:	6b42                	ld	s6,16(sp)
    80004ee2:	6161                	addi	sp,sp,80
    80004ee4:	8082                	ret
      release(&pi->lock);
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	da2080e7          	jalr	-606(ra) # 80000c8a <release>
      return -1;
    80004ef0:	59fd                	li	s3,-1
    80004ef2:	bff9                	j	80004ed0 <piperead+0xca>

0000000080004ef4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ef4:	1141                	addi	sp,sp,-16
    80004ef6:	e422                	sd	s0,8(sp)
    80004ef8:	0800                	addi	s0,sp,16
    80004efa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004efc:	8905                	andi	a0,a0,1
    80004efe:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f00:	8b89                	andi	a5,a5,2
    80004f02:	c399                	beqz	a5,80004f08 <flags2perm+0x14>
      perm |= PTE_W;
    80004f04:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f08:	6422                	ld	s0,8(sp)
    80004f0a:	0141                	addi	sp,sp,16
    80004f0c:	8082                	ret

0000000080004f0e <exec>:

int
exec(char *path, char **argv)
{
    80004f0e:	de010113          	addi	sp,sp,-544
    80004f12:	20113c23          	sd	ra,536(sp)
    80004f16:	20813823          	sd	s0,528(sp)
    80004f1a:	20913423          	sd	s1,520(sp)
    80004f1e:	21213023          	sd	s2,512(sp)
    80004f22:	ffce                	sd	s3,504(sp)
    80004f24:	fbd2                	sd	s4,496(sp)
    80004f26:	f7d6                	sd	s5,488(sp)
    80004f28:	f3da                	sd	s6,480(sp)
    80004f2a:	efde                	sd	s7,472(sp)
    80004f2c:	ebe2                	sd	s8,464(sp)
    80004f2e:	e7e6                	sd	s9,456(sp)
    80004f30:	e3ea                	sd	s10,448(sp)
    80004f32:	ff6e                	sd	s11,440(sp)
    80004f34:	1400                	addi	s0,sp,544
    80004f36:	892a                	mv	s2,a0
    80004f38:	dea43423          	sd	a0,-536(s0)
    80004f3c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f40:	ffffd097          	auipc	ra,0xffffd
    80004f44:	a6c080e7          	jalr	-1428(ra) # 800019ac <myproc>
    80004f48:	84aa                	mv	s1,a0

  begin_op();
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	482080e7          	jalr	1154(ra) # 800043cc <begin_op>

  if((ip = namei(path)) == 0){
    80004f52:	854a                	mv	a0,s2
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	258080e7          	jalr	600(ra) # 800041ac <namei>
    80004f5c:	c93d                	beqz	a0,80004fd2 <exec+0xc4>
    80004f5e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	aa0080e7          	jalr	-1376(ra) # 80003a00 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f68:	04000713          	li	a4,64
    80004f6c:	4681                	li	a3,0
    80004f6e:	e5040613          	addi	a2,s0,-432
    80004f72:	4581                	li	a1,0
    80004f74:	8556                	mv	a0,s5
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	d3e080e7          	jalr	-706(ra) # 80003cb4 <readi>
    80004f7e:	04000793          	li	a5,64
    80004f82:	00f51a63          	bne	a0,a5,80004f96 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f86:	e5042703          	lw	a4,-432(s0)
    80004f8a:	464c47b7          	lui	a5,0x464c4
    80004f8e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f92:	04f70663          	beq	a4,a5,80004fde <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f96:	8556                	mv	a0,s5
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	cca080e7          	jalr	-822(ra) # 80003c62 <iunlockput>
    end_op();
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	4aa080e7          	jalr	1194(ra) # 8000444a <end_op>
  }
  return -1;
    80004fa8:	557d                	li	a0,-1
}
    80004faa:	21813083          	ld	ra,536(sp)
    80004fae:	21013403          	ld	s0,528(sp)
    80004fb2:	20813483          	ld	s1,520(sp)
    80004fb6:	20013903          	ld	s2,512(sp)
    80004fba:	79fe                	ld	s3,504(sp)
    80004fbc:	7a5e                	ld	s4,496(sp)
    80004fbe:	7abe                	ld	s5,488(sp)
    80004fc0:	7b1e                	ld	s6,480(sp)
    80004fc2:	6bfe                	ld	s7,472(sp)
    80004fc4:	6c5e                	ld	s8,464(sp)
    80004fc6:	6cbe                	ld	s9,456(sp)
    80004fc8:	6d1e                	ld	s10,448(sp)
    80004fca:	7dfa                	ld	s11,440(sp)
    80004fcc:	22010113          	addi	sp,sp,544
    80004fd0:	8082                	ret
    end_op();
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	478080e7          	jalr	1144(ra) # 8000444a <end_op>
    return -1;
    80004fda:	557d                	li	a0,-1
    80004fdc:	b7f9                	j	80004faa <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fde:	8526                	mv	a0,s1
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	a90080e7          	jalr	-1392(ra) # 80001a70 <proc_pagetable>
    80004fe8:	8b2a                	mv	s6,a0
    80004fea:	d555                	beqz	a0,80004f96 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fec:	e7042783          	lw	a5,-400(s0)
    80004ff0:	e8845703          	lhu	a4,-376(s0)
    80004ff4:	c735                	beqz	a4,80005060 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ff6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ffc:	6a05                	lui	s4,0x1
    80004ffe:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005002:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005006:	6d85                	lui	s11,0x1
    80005008:	7d7d                	lui	s10,0xfffff
    8000500a:	ac3d                	j	80005248 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000500c:	00003517          	auipc	a0,0x3
    80005010:	6e450513          	addi	a0,a0,1764 # 800086f0 <syscalls+0x2a0>
    80005014:	ffffb097          	auipc	ra,0xffffb
    80005018:	52c080e7          	jalr	1324(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000501c:	874a                	mv	a4,s2
    8000501e:	009c86bb          	addw	a3,s9,s1
    80005022:	4581                	li	a1,0
    80005024:	8556                	mv	a0,s5
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	c8e080e7          	jalr	-882(ra) # 80003cb4 <readi>
    8000502e:	2501                	sext.w	a0,a0
    80005030:	1aa91963          	bne	s2,a0,800051e2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005034:	009d84bb          	addw	s1,s11,s1
    80005038:	013d09bb          	addw	s3,s10,s3
    8000503c:	1f74f663          	bgeu	s1,s7,80005228 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005040:	02049593          	slli	a1,s1,0x20
    80005044:	9181                	srli	a1,a1,0x20
    80005046:	95e2                	add	a1,a1,s8
    80005048:	855a                	mv	a0,s6
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	012080e7          	jalr	18(ra) # 8000105c <walkaddr>
    80005052:	862a                	mv	a2,a0
    if(pa == 0)
    80005054:	dd45                	beqz	a0,8000500c <exec+0xfe>
      n = PGSIZE;
    80005056:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005058:	fd49f2e3          	bgeu	s3,s4,8000501c <exec+0x10e>
      n = sz - i;
    8000505c:	894e                	mv	s2,s3
    8000505e:	bf7d                	j	8000501c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005060:	4901                	li	s2,0
  iunlockput(ip);
    80005062:	8556                	mv	a0,s5
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	bfe080e7          	jalr	-1026(ra) # 80003c62 <iunlockput>
  end_op();
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	3de080e7          	jalr	990(ra) # 8000444a <end_op>
  p = myproc();
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	938080e7          	jalr	-1736(ra) # 800019ac <myproc>
    8000507c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000507e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005082:	6785                	lui	a5,0x1
    80005084:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005086:	97ca                	add	a5,a5,s2
    80005088:	777d                	lui	a4,0xfffff
    8000508a:	8ff9                	and	a5,a5,a4
    8000508c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005090:	4691                	li	a3,4
    80005092:	6609                	lui	a2,0x2
    80005094:	963e                	add	a2,a2,a5
    80005096:	85be                	mv	a1,a5
    80005098:	855a                	mv	a0,s6
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	376080e7          	jalr	886(ra) # 80001410 <uvmalloc>
    800050a2:	8c2a                	mv	s8,a0
  ip = 0;
    800050a4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050a6:	12050e63          	beqz	a0,800051e2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050aa:	75f9                	lui	a1,0xffffe
    800050ac:	95aa                	add	a1,a1,a0
    800050ae:	855a                	mv	a0,s6
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	58a080e7          	jalr	1418(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800050b8:	7afd                	lui	s5,0xfffff
    800050ba:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050bc:	df043783          	ld	a5,-528(s0)
    800050c0:	6388                	ld	a0,0(a5)
    800050c2:	c925                	beqz	a0,80005132 <exec+0x224>
    800050c4:	e9040993          	addi	s3,s0,-368
    800050c8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050cc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ce:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	d7e080e7          	jalr	-642(ra) # 80000e4e <strlen>
    800050d8:	0015079b          	addiw	a5,a0,1
    800050dc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050e0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050e4:	13596663          	bltu	s2,s5,80005210 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050e8:	df043d83          	ld	s11,-528(s0)
    800050ec:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050f0:	8552                	mv	a0,s4
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	d5c080e7          	jalr	-676(ra) # 80000e4e <strlen>
    800050fa:	0015069b          	addiw	a3,a0,1
    800050fe:	8652                	mv	a2,s4
    80005100:	85ca                	mv	a1,s2
    80005102:	855a                	mv	a0,s6
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	568080e7          	jalr	1384(ra) # 8000166c <copyout>
    8000510c:	10054663          	bltz	a0,80005218 <exec+0x30a>
    ustack[argc] = sp;
    80005110:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005114:	0485                	addi	s1,s1,1
    80005116:	008d8793          	addi	a5,s11,8
    8000511a:	def43823          	sd	a5,-528(s0)
    8000511e:	008db503          	ld	a0,8(s11)
    80005122:	c911                	beqz	a0,80005136 <exec+0x228>
    if(argc >= MAXARG)
    80005124:	09a1                	addi	s3,s3,8
    80005126:	fb3c95e3          	bne	s9,s3,800050d0 <exec+0x1c2>
  sz = sz1;
    8000512a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000512e:	4a81                	li	s5,0
    80005130:	a84d                	j	800051e2 <exec+0x2d4>
  sp = sz;
    80005132:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005134:	4481                	li	s1,0
  ustack[argc] = 0;
    80005136:	00349793          	slli	a5,s1,0x3
    8000513a:	f9078793          	addi	a5,a5,-112
    8000513e:	97a2                	add	a5,a5,s0
    80005140:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005144:	00148693          	addi	a3,s1,1
    80005148:	068e                	slli	a3,a3,0x3
    8000514a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000514e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005152:	01597663          	bgeu	s2,s5,8000515e <exec+0x250>
  sz = sz1;
    80005156:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000515a:	4a81                	li	s5,0
    8000515c:	a059                	j	800051e2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000515e:	e9040613          	addi	a2,s0,-368
    80005162:	85ca                	mv	a1,s2
    80005164:	855a                	mv	a0,s6
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	506080e7          	jalr	1286(ra) # 8000166c <copyout>
    8000516e:	0a054963          	bltz	a0,80005220 <exec+0x312>
  p->trapframe->a1 = sp;
    80005172:	058bb783          	ld	a5,88(s7)
    80005176:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000517a:	de843783          	ld	a5,-536(s0)
    8000517e:	0007c703          	lbu	a4,0(a5)
    80005182:	cf11                	beqz	a4,8000519e <exec+0x290>
    80005184:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005186:	02f00693          	li	a3,47
    8000518a:	a039                	j	80005198 <exec+0x28a>
      last = s+1;
    8000518c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005190:	0785                	addi	a5,a5,1
    80005192:	fff7c703          	lbu	a4,-1(a5)
    80005196:	c701                	beqz	a4,8000519e <exec+0x290>
    if(*s == '/')
    80005198:	fed71ce3          	bne	a4,a3,80005190 <exec+0x282>
    8000519c:	bfc5                	j	8000518c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000519e:	4641                	li	a2,16
    800051a0:	de843583          	ld	a1,-536(s0)
    800051a4:	158b8513          	addi	a0,s7,344
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	c74080e7          	jalr	-908(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051b0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800051b4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800051b8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051bc:	058bb783          	ld	a5,88(s7)
    800051c0:	e6843703          	ld	a4,-408(s0)
    800051c4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051c6:	058bb783          	ld	a5,88(s7)
    800051ca:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051ce:	85ea                	mv	a1,s10
    800051d0:	ffffd097          	auipc	ra,0xffffd
    800051d4:	93c080e7          	jalr	-1732(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051d8:	0004851b          	sext.w	a0,s1
    800051dc:	b3f9                	j	80004faa <exec+0x9c>
    800051de:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051e2:	df843583          	ld	a1,-520(s0)
    800051e6:	855a                	mv	a0,s6
    800051e8:	ffffd097          	auipc	ra,0xffffd
    800051ec:	924080e7          	jalr	-1756(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051f0:	da0a93e3          	bnez	s5,80004f96 <exec+0x88>
  return -1;
    800051f4:	557d                	li	a0,-1
    800051f6:	bb55                	j	80004faa <exec+0x9c>
    800051f8:	df243c23          	sd	s2,-520(s0)
    800051fc:	b7dd                	j	800051e2 <exec+0x2d4>
    800051fe:	df243c23          	sd	s2,-520(s0)
    80005202:	b7c5                	j	800051e2 <exec+0x2d4>
    80005204:	df243c23          	sd	s2,-520(s0)
    80005208:	bfe9                	j	800051e2 <exec+0x2d4>
    8000520a:	df243c23          	sd	s2,-520(s0)
    8000520e:	bfd1                	j	800051e2 <exec+0x2d4>
  sz = sz1;
    80005210:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005214:	4a81                	li	s5,0
    80005216:	b7f1                	j	800051e2 <exec+0x2d4>
  sz = sz1;
    80005218:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000521c:	4a81                	li	s5,0
    8000521e:	b7d1                	j	800051e2 <exec+0x2d4>
  sz = sz1;
    80005220:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005224:	4a81                	li	s5,0
    80005226:	bf75                	j	800051e2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005228:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000522c:	e0843783          	ld	a5,-504(s0)
    80005230:	0017869b          	addiw	a3,a5,1
    80005234:	e0d43423          	sd	a3,-504(s0)
    80005238:	e0043783          	ld	a5,-512(s0)
    8000523c:	0387879b          	addiw	a5,a5,56
    80005240:	e8845703          	lhu	a4,-376(s0)
    80005244:	e0e6dfe3          	bge	a3,a4,80005062 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005248:	2781                	sext.w	a5,a5
    8000524a:	e0f43023          	sd	a5,-512(s0)
    8000524e:	03800713          	li	a4,56
    80005252:	86be                	mv	a3,a5
    80005254:	e1840613          	addi	a2,s0,-488
    80005258:	4581                	li	a1,0
    8000525a:	8556                	mv	a0,s5
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	a58080e7          	jalr	-1448(ra) # 80003cb4 <readi>
    80005264:	03800793          	li	a5,56
    80005268:	f6f51be3          	bne	a0,a5,800051de <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000526c:	e1842783          	lw	a5,-488(s0)
    80005270:	4705                	li	a4,1
    80005272:	fae79de3          	bne	a5,a4,8000522c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005276:	e4043483          	ld	s1,-448(s0)
    8000527a:	e3843783          	ld	a5,-456(s0)
    8000527e:	f6f4ede3          	bltu	s1,a5,800051f8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005282:	e2843783          	ld	a5,-472(s0)
    80005286:	94be                	add	s1,s1,a5
    80005288:	f6f4ebe3          	bltu	s1,a5,800051fe <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000528c:	de043703          	ld	a4,-544(s0)
    80005290:	8ff9                	and	a5,a5,a4
    80005292:	fbad                	bnez	a5,80005204 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005294:	e1c42503          	lw	a0,-484(s0)
    80005298:	00000097          	auipc	ra,0x0
    8000529c:	c5c080e7          	jalr	-932(ra) # 80004ef4 <flags2perm>
    800052a0:	86aa                	mv	a3,a0
    800052a2:	8626                	mv	a2,s1
    800052a4:	85ca                	mv	a1,s2
    800052a6:	855a                	mv	a0,s6
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	168080e7          	jalr	360(ra) # 80001410 <uvmalloc>
    800052b0:	dea43c23          	sd	a0,-520(s0)
    800052b4:	d939                	beqz	a0,8000520a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052b6:	e2843c03          	ld	s8,-472(s0)
    800052ba:	e2042c83          	lw	s9,-480(s0)
    800052be:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052c2:	f60b83e3          	beqz	s7,80005228 <exec+0x31a>
    800052c6:	89de                	mv	s3,s7
    800052c8:	4481                	li	s1,0
    800052ca:	bb9d                	j	80005040 <exec+0x132>

00000000800052cc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052cc:	7179                	addi	sp,sp,-48
    800052ce:	f406                	sd	ra,40(sp)
    800052d0:	f022                	sd	s0,32(sp)
    800052d2:	ec26                	sd	s1,24(sp)
    800052d4:	e84a                	sd	s2,16(sp)
    800052d6:	1800                	addi	s0,sp,48
    800052d8:	892e                	mv	s2,a1
    800052da:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052dc:	fdc40593          	addi	a1,s0,-36
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	a4a080e7          	jalr	-1462(ra) # 80002d2a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052e8:	fdc42703          	lw	a4,-36(s0)
    800052ec:	47bd                	li	a5,15
    800052ee:	02e7eb63          	bltu	a5,a4,80005324 <argfd+0x58>
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	6ba080e7          	jalr	1722(ra) # 800019ac <myproc>
    800052fa:	fdc42703          	lw	a4,-36(s0)
    800052fe:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdba7a>
    80005302:	078e                	slli	a5,a5,0x3
    80005304:	953e                	add	a0,a0,a5
    80005306:	611c                	ld	a5,0(a0)
    80005308:	c385                	beqz	a5,80005328 <argfd+0x5c>
    return -1;
  if(pfd)
    8000530a:	00090463          	beqz	s2,80005312 <argfd+0x46>
    *pfd = fd;
    8000530e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005312:	4501                	li	a0,0
  if(pf)
    80005314:	c091                	beqz	s1,80005318 <argfd+0x4c>
    *pf = f;
    80005316:	e09c                	sd	a5,0(s1)
}
    80005318:	70a2                	ld	ra,40(sp)
    8000531a:	7402                	ld	s0,32(sp)
    8000531c:	64e2                	ld	s1,24(sp)
    8000531e:	6942                	ld	s2,16(sp)
    80005320:	6145                	addi	sp,sp,48
    80005322:	8082                	ret
    return -1;
    80005324:	557d                	li	a0,-1
    80005326:	bfcd                	j	80005318 <argfd+0x4c>
    80005328:	557d                	li	a0,-1
    8000532a:	b7fd                	j	80005318 <argfd+0x4c>

000000008000532c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000532c:	1101                	addi	sp,sp,-32
    8000532e:	ec06                	sd	ra,24(sp)
    80005330:	e822                	sd	s0,16(sp)
    80005332:	e426                	sd	s1,8(sp)
    80005334:	1000                	addi	s0,sp,32
    80005336:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005338:	ffffc097          	auipc	ra,0xffffc
    8000533c:	674080e7          	jalr	1652(ra) # 800019ac <myproc>
    80005340:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005342:	0d050793          	addi	a5,a0,208
    80005346:	4501                	li	a0,0
    80005348:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000534a:	6398                	ld	a4,0(a5)
    8000534c:	cb19                	beqz	a4,80005362 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000534e:	2505                	addiw	a0,a0,1
    80005350:	07a1                	addi	a5,a5,8
    80005352:	fed51ce3          	bne	a0,a3,8000534a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005356:	557d                	li	a0,-1
}
    80005358:	60e2                	ld	ra,24(sp)
    8000535a:	6442                	ld	s0,16(sp)
    8000535c:	64a2                	ld	s1,8(sp)
    8000535e:	6105                	addi	sp,sp,32
    80005360:	8082                	ret
      p->ofile[fd] = f;
    80005362:	01a50793          	addi	a5,a0,26
    80005366:	078e                	slli	a5,a5,0x3
    80005368:	963e                	add	a2,a2,a5
    8000536a:	e204                	sd	s1,0(a2)
      return fd;
    8000536c:	b7f5                	j	80005358 <fdalloc+0x2c>

000000008000536e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000536e:	715d                	addi	sp,sp,-80
    80005370:	e486                	sd	ra,72(sp)
    80005372:	e0a2                	sd	s0,64(sp)
    80005374:	fc26                	sd	s1,56(sp)
    80005376:	f84a                	sd	s2,48(sp)
    80005378:	f44e                	sd	s3,40(sp)
    8000537a:	f052                	sd	s4,32(sp)
    8000537c:	ec56                	sd	s5,24(sp)
    8000537e:	e85a                	sd	s6,16(sp)
    80005380:	0880                	addi	s0,sp,80
    80005382:	8b2e                	mv	s6,a1
    80005384:	89b2                	mv	s3,a2
    80005386:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005388:	fb040593          	addi	a1,s0,-80
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	e3e080e7          	jalr	-450(ra) # 800041ca <nameiparent>
    80005394:	84aa                	mv	s1,a0
    80005396:	14050f63          	beqz	a0,800054f4 <create+0x186>
    return 0;

  ilock(dp);
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	666080e7          	jalr	1638(ra) # 80003a00 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053a2:	4601                	li	a2,0
    800053a4:	fb040593          	addi	a1,s0,-80
    800053a8:	8526                	mv	a0,s1
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	b3a080e7          	jalr	-1222(ra) # 80003ee4 <dirlookup>
    800053b2:	8aaa                	mv	s5,a0
    800053b4:	c931                	beqz	a0,80005408 <create+0x9a>
    iunlockput(dp);
    800053b6:	8526                	mv	a0,s1
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	8aa080e7          	jalr	-1878(ra) # 80003c62 <iunlockput>
    ilock(ip);
    800053c0:	8556                	mv	a0,s5
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	63e080e7          	jalr	1598(ra) # 80003a00 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053ca:	000b059b          	sext.w	a1,s6
    800053ce:	4789                	li	a5,2
    800053d0:	02f59563          	bne	a1,a5,800053fa <create+0x8c>
    800053d4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdbaa4>
    800053d8:	37f9                	addiw	a5,a5,-2
    800053da:	17c2                	slli	a5,a5,0x30
    800053dc:	93c1                	srli	a5,a5,0x30
    800053de:	4705                	li	a4,1
    800053e0:	00f76d63          	bltu	a4,a5,800053fa <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053e4:	8556                	mv	a0,s5
    800053e6:	60a6                	ld	ra,72(sp)
    800053e8:	6406                	ld	s0,64(sp)
    800053ea:	74e2                	ld	s1,56(sp)
    800053ec:	7942                	ld	s2,48(sp)
    800053ee:	79a2                	ld	s3,40(sp)
    800053f0:	7a02                	ld	s4,32(sp)
    800053f2:	6ae2                	ld	s5,24(sp)
    800053f4:	6b42                	ld	s6,16(sp)
    800053f6:	6161                	addi	sp,sp,80
    800053f8:	8082                	ret
    iunlockput(ip);
    800053fa:	8556                	mv	a0,s5
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	866080e7          	jalr	-1946(ra) # 80003c62 <iunlockput>
    return 0;
    80005404:	4a81                	li	s5,0
    80005406:	bff9                	j	800053e4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005408:	85da                	mv	a1,s6
    8000540a:	4088                	lw	a0,0(s1)
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	456080e7          	jalr	1110(ra) # 80003862 <ialloc>
    80005414:	8a2a                	mv	s4,a0
    80005416:	c539                	beqz	a0,80005464 <create+0xf6>
  ilock(ip);
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	5e8080e7          	jalr	1512(ra) # 80003a00 <ilock>
  ip->major = major;
    80005420:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005424:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005428:	4905                	li	s2,1
    8000542a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000542e:	8552                	mv	a0,s4
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	504080e7          	jalr	1284(ra) # 80003934 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005438:	000b059b          	sext.w	a1,s6
    8000543c:	03258b63          	beq	a1,s2,80005472 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005440:	004a2603          	lw	a2,4(s4)
    80005444:	fb040593          	addi	a1,s0,-80
    80005448:	8526                	mv	a0,s1
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	cb0080e7          	jalr	-848(ra) # 800040fa <dirlink>
    80005452:	06054f63          	bltz	a0,800054d0 <create+0x162>
  iunlockput(dp);
    80005456:	8526                	mv	a0,s1
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	80a080e7          	jalr	-2038(ra) # 80003c62 <iunlockput>
  return ip;
    80005460:	8ad2                	mv	s5,s4
    80005462:	b749                	j	800053e4 <create+0x76>
    iunlockput(dp);
    80005464:	8526                	mv	a0,s1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	7fc080e7          	jalr	2044(ra) # 80003c62 <iunlockput>
    return 0;
    8000546e:	8ad2                	mv	s5,s4
    80005470:	bf95                	j	800053e4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005472:	004a2603          	lw	a2,4(s4)
    80005476:	00003597          	auipc	a1,0x3
    8000547a:	29a58593          	addi	a1,a1,666 # 80008710 <syscalls+0x2c0>
    8000547e:	8552                	mv	a0,s4
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	c7a080e7          	jalr	-902(ra) # 800040fa <dirlink>
    80005488:	04054463          	bltz	a0,800054d0 <create+0x162>
    8000548c:	40d0                	lw	a2,4(s1)
    8000548e:	00003597          	auipc	a1,0x3
    80005492:	28a58593          	addi	a1,a1,650 # 80008718 <syscalls+0x2c8>
    80005496:	8552                	mv	a0,s4
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	c62080e7          	jalr	-926(ra) # 800040fa <dirlink>
    800054a0:	02054863          	bltz	a0,800054d0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800054a4:	004a2603          	lw	a2,4(s4)
    800054a8:	fb040593          	addi	a1,s0,-80
    800054ac:	8526                	mv	a0,s1
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c4c080e7          	jalr	-948(ra) # 800040fa <dirlink>
    800054b6:	00054d63          	bltz	a0,800054d0 <create+0x162>
    dp->nlink++;  // for ".."
    800054ba:	04a4d783          	lhu	a5,74(s1)
    800054be:	2785                	addiw	a5,a5,1
    800054c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	46e080e7          	jalr	1134(ra) # 80003934 <iupdate>
    800054ce:	b761                	j	80005456 <create+0xe8>
  ip->nlink = 0;
    800054d0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054d4:	8552                	mv	a0,s4
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	45e080e7          	jalr	1118(ra) # 80003934 <iupdate>
  iunlockput(ip);
    800054de:	8552                	mv	a0,s4
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	782080e7          	jalr	1922(ra) # 80003c62 <iunlockput>
  iunlockput(dp);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	778080e7          	jalr	1912(ra) # 80003c62 <iunlockput>
  return 0;
    800054f2:	bdcd                	j	800053e4 <create+0x76>
    return 0;
    800054f4:	8aaa                	mv	s5,a0
    800054f6:	b5fd                	j	800053e4 <create+0x76>

00000000800054f8 <sys_dup>:
{
    800054f8:	7179                	addi	sp,sp,-48
    800054fa:	f406                	sd	ra,40(sp)
    800054fc:	f022                	sd	s0,32(sp)
    800054fe:	ec26                	sd	s1,24(sp)
    80005500:	e84a                	sd	s2,16(sp)
    80005502:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005504:	fd840613          	addi	a2,s0,-40
    80005508:	4581                	li	a1,0
    8000550a:	4501                	li	a0,0
    8000550c:	00000097          	auipc	ra,0x0
    80005510:	dc0080e7          	jalr	-576(ra) # 800052cc <argfd>
    return -1;
    80005514:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005516:	02054363          	bltz	a0,8000553c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000551a:	fd843903          	ld	s2,-40(s0)
    8000551e:	854a                	mv	a0,s2
    80005520:	00000097          	auipc	ra,0x0
    80005524:	e0c080e7          	jalr	-500(ra) # 8000532c <fdalloc>
    80005528:	84aa                	mv	s1,a0
    return -1;
    8000552a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000552c:	00054863          	bltz	a0,8000553c <sys_dup+0x44>
  filedup(f);
    80005530:	854a                	mv	a0,s2
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	310080e7          	jalr	784(ra) # 80004842 <filedup>
  return fd;
    8000553a:	87a6                	mv	a5,s1
}
    8000553c:	853e                	mv	a0,a5
    8000553e:	70a2                	ld	ra,40(sp)
    80005540:	7402                	ld	s0,32(sp)
    80005542:	64e2                	ld	s1,24(sp)
    80005544:	6942                	ld	s2,16(sp)
    80005546:	6145                	addi	sp,sp,48
    80005548:	8082                	ret

000000008000554a <sys_read>:
{
    8000554a:	7179                	addi	sp,sp,-48
    8000554c:	f406                	sd	ra,40(sp)
    8000554e:	f022                	sd	s0,32(sp)
    80005550:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005552:	fd840593          	addi	a1,s0,-40
    80005556:	4505                	li	a0,1
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	7f2080e7          	jalr	2034(ra) # 80002d4a <argaddr>
  argint(2, &n);
    80005560:	fe440593          	addi	a1,s0,-28
    80005564:	4509                	li	a0,2
    80005566:	ffffd097          	auipc	ra,0xffffd
    8000556a:	7c4080e7          	jalr	1988(ra) # 80002d2a <argint>
  if(argfd(0, 0, &f) < 0)
    8000556e:	fe840613          	addi	a2,s0,-24
    80005572:	4581                	li	a1,0
    80005574:	4501                	li	a0,0
    80005576:	00000097          	auipc	ra,0x0
    8000557a:	d56080e7          	jalr	-682(ra) # 800052cc <argfd>
    8000557e:	87aa                	mv	a5,a0
    return -1;
    80005580:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005582:	0007cc63          	bltz	a5,8000559a <sys_read+0x50>
  return fileread(f, p, n);
    80005586:	fe442603          	lw	a2,-28(s0)
    8000558a:	fd843583          	ld	a1,-40(s0)
    8000558e:	fe843503          	ld	a0,-24(s0)
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	43c080e7          	jalr	1084(ra) # 800049ce <fileread>
}
    8000559a:	70a2                	ld	ra,40(sp)
    8000559c:	7402                	ld	s0,32(sp)
    8000559e:	6145                	addi	sp,sp,48
    800055a0:	8082                	ret

00000000800055a2 <sys_write>:
{
    800055a2:	7179                	addi	sp,sp,-48
    800055a4:	f406                	sd	ra,40(sp)
    800055a6:	f022                	sd	s0,32(sp)
    800055a8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055aa:	fd840593          	addi	a1,s0,-40
    800055ae:	4505                	li	a0,1
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	79a080e7          	jalr	1946(ra) # 80002d4a <argaddr>
  argint(2, &n);
    800055b8:	fe440593          	addi	a1,s0,-28
    800055bc:	4509                	li	a0,2
    800055be:	ffffd097          	auipc	ra,0xffffd
    800055c2:	76c080e7          	jalr	1900(ra) # 80002d2a <argint>
  if(argfd(0, 0, &f) < 0)
    800055c6:	fe840613          	addi	a2,s0,-24
    800055ca:	4581                	li	a1,0
    800055cc:	4501                	li	a0,0
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	cfe080e7          	jalr	-770(ra) # 800052cc <argfd>
    800055d6:	87aa                	mv	a5,a0
    return -1;
    800055d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055da:	0007cc63          	bltz	a5,800055f2 <sys_write+0x50>
  return filewrite(f, p, n);
    800055de:	fe442603          	lw	a2,-28(s0)
    800055e2:	fd843583          	ld	a1,-40(s0)
    800055e6:	fe843503          	ld	a0,-24(s0)
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	4a6080e7          	jalr	1190(ra) # 80004a90 <filewrite>
}
    800055f2:	70a2                	ld	ra,40(sp)
    800055f4:	7402                	ld	s0,32(sp)
    800055f6:	6145                	addi	sp,sp,48
    800055f8:	8082                	ret

00000000800055fa <sys_close>:
{
    800055fa:	1101                	addi	sp,sp,-32
    800055fc:	ec06                	sd	ra,24(sp)
    800055fe:	e822                	sd	s0,16(sp)
    80005600:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005602:	fe040613          	addi	a2,s0,-32
    80005606:	fec40593          	addi	a1,s0,-20
    8000560a:	4501                	li	a0,0
    8000560c:	00000097          	auipc	ra,0x0
    80005610:	cc0080e7          	jalr	-832(ra) # 800052cc <argfd>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005616:	02054463          	bltz	a0,8000563e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000561a:	ffffc097          	auipc	ra,0xffffc
    8000561e:	392080e7          	jalr	914(ra) # 800019ac <myproc>
    80005622:	fec42783          	lw	a5,-20(s0)
    80005626:	07e9                	addi	a5,a5,26
    80005628:	078e                	slli	a5,a5,0x3
    8000562a:	953e                	add	a0,a0,a5
    8000562c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005630:	fe043503          	ld	a0,-32(s0)
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	260080e7          	jalr	608(ra) # 80004894 <fileclose>
  return 0;
    8000563c:	4781                	li	a5,0
}
    8000563e:	853e                	mv	a0,a5
    80005640:	60e2                	ld	ra,24(sp)
    80005642:	6442                	ld	s0,16(sp)
    80005644:	6105                	addi	sp,sp,32
    80005646:	8082                	ret

0000000080005648 <sys_fstat>:
{
    80005648:	1101                	addi	sp,sp,-32
    8000564a:	ec06                	sd	ra,24(sp)
    8000564c:	e822                	sd	s0,16(sp)
    8000564e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005650:	fe040593          	addi	a1,s0,-32
    80005654:	4505                	li	a0,1
    80005656:	ffffd097          	auipc	ra,0xffffd
    8000565a:	6f4080e7          	jalr	1780(ra) # 80002d4a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000565e:	fe840613          	addi	a2,s0,-24
    80005662:	4581                	li	a1,0
    80005664:	4501                	li	a0,0
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	c66080e7          	jalr	-922(ra) # 800052cc <argfd>
    8000566e:	87aa                	mv	a5,a0
    return -1;
    80005670:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005672:	0007ca63          	bltz	a5,80005686 <sys_fstat+0x3e>
  return filestat(f, st);
    80005676:	fe043583          	ld	a1,-32(s0)
    8000567a:	fe843503          	ld	a0,-24(s0)
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	2de080e7          	jalr	734(ra) # 8000495c <filestat>
}
    80005686:	60e2                	ld	ra,24(sp)
    80005688:	6442                	ld	s0,16(sp)
    8000568a:	6105                	addi	sp,sp,32
    8000568c:	8082                	ret

000000008000568e <sys_link>:
{
    8000568e:	7169                	addi	sp,sp,-304
    80005690:	f606                	sd	ra,296(sp)
    80005692:	f222                	sd	s0,288(sp)
    80005694:	ee26                	sd	s1,280(sp)
    80005696:	ea4a                	sd	s2,272(sp)
    80005698:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569a:	08000613          	li	a2,128
    8000569e:	ed040593          	addi	a1,s0,-304
    800056a2:	4501                	li	a0,0
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	6c6080e7          	jalr	1734(ra) # 80002d6a <argstr>
    return -1;
    800056ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ae:	10054e63          	bltz	a0,800057ca <sys_link+0x13c>
    800056b2:	08000613          	li	a2,128
    800056b6:	f5040593          	addi	a1,s0,-176
    800056ba:	4505                	li	a0,1
    800056bc:	ffffd097          	auipc	ra,0xffffd
    800056c0:	6ae080e7          	jalr	1710(ra) # 80002d6a <argstr>
    return -1;
    800056c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c6:	10054263          	bltz	a0,800057ca <sys_link+0x13c>
  begin_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	d02080e7          	jalr	-766(ra) # 800043cc <begin_op>
  if((ip = namei(old)) == 0){
    800056d2:	ed040513          	addi	a0,s0,-304
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	ad6080e7          	jalr	-1322(ra) # 800041ac <namei>
    800056de:	84aa                	mv	s1,a0
    800056e0:	c551                	beqz	a0,8000576c <sys_link+0xde>
  ilock(ip);
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	31e080e7          	jalr	798(ra) # 80003a00 <ilock>
  if(ip->type == T_DIR){
    800056ea:	04449703          	lh	a4,68(s1)
    800056ee:	4785                	li	a5,1
    800056f0:	08f70463          	beq	a4,a5,80005778 <sys_link+0xea>
  ip->nlink++;
    800056f4:	04a4d783          	lhu	a5,74(s1)
    800056f8:	2785                	addiw	a5,a5,1
    800056fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	234080e7          	jalr	564(ra) # 80003934 <iupdate>
  iunlock(ip);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	3b8080e7          	jalr	952(ra) # 80003ac2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005712:	fd040593          	addi	a1,s0,-48
    80005716:	f5040513          	addi	a0,s0,-176
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	ab0080e7          	jalr	-1360(ra) # 800041ca <nameiparent>
    80005722:	892a                	mv	s2,a0
    80005724:	c935                	beqz	a0,80005798 <sys_link+0x10a>
  ilock(dp);
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	2da080e7          	jalr	730(ra) # 80003a00 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000572e:	00092703          	lw	a4,0(s2)
    80005732:	409c                	lw	a5,0(s1)
    80005734:	04f71d63          	bne	a4,a5,8000578e <sys_link+0x100>
    80005738:	40d0                	lw	a2,4(s1)
    8000573a:	fd040593          	addi	a1,s0,-48
    8000573e:	854a                	mv	a0,s2
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	9ba080e7          	jalr	-1606(ra) # 800040fa <dirlink>
    80005748:	04054363          	bltz	a0,8000578e <sys_link+0x100>
  iunlockput(dp);
    8000574c:	854a                	mv	a0,s2
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	514080e7          	jalr	1300(ra) # 80003c62 <iunlockput>
  iput(ip);
    80005756:	8526                	mv	a0,s1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	462080e7          	jalr	1122(ra) # 80003bba <iput>
  end_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	cea080e7          	jalr	-790(ra) # 8000444a <end_op>
  return 0;
    80005768:	4781                	li	a5,0
    8000576a:	a085                	j	800057ca <sys_link+0x13c>
    end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	cde080e7          	jalr	-802(ra) # 8000444a <end_op>
    return -1;
    80005774:	57fd                	li	a5,-1
    80005776:	a891                	j	800057ca <sys_link+0x13c>
    iunlockput(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	4e8080e7          	jalr	1256(ra) # 80003c62 <iunlockput>
    end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	cc8080e7          	jalr	-824(ra) # 8000444a <end_op>
    return -1;
    8000578a:	57fd                	li	a5,-1
    8000578c:	a83d                	j	800057ca <sys_link+0x13c>
    iunlockput(dp);
    8000578e:	854a                	mv	a0,s2
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	4d2080e7          	jalr	1234(ra) # 80003c62 <iunlockput>
  ilock(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	266080e7          	jalr	614(ra) # 80003a00 <ilock>
  ip->nlink--;
    800057a2:	04a4d783          	lhu	a5,74(s1)
    800057a6:	37fd                	addiw	a5,a5,-1
    800057a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	186080e7          	jalr	390(ra) # 80003934 <iupdate>
  iunlockput(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	4aa080e7          	jalr	1194(ra) # 80003c62 <iunlockput>
  end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	c8a080e7          	jalr	-886(ra) # 8000444a <end_op>
  return -1;
    800057c8:	57fd                	li	a5,-1
}
    800057ca:	853e                	mv	a0,a5
    800057cc:	70b2                	ld	ra,296(sp)
    800057ce:	7412                	ld	s0,288(sp)
    800057d0:	64f2                	ld	s1,280(sp)
    800057d2:	6952                	ld	s2,272(sp)
    800057d4:	6155                	addi	sp,sp,304
    800057d6:	8082                	ret

00000000800057d8 <sys_unlink>:
{
    800057d8:	7151                	addi	sp,sp,-240
    800057da:	f586                	sd	ra,232(sp)
    800057dc:	f1a2                	sd	s0,224(sp)
    800057de:	eda6                	sd	s1,216(sp)
    800057e0:	e9ca                	sd	s2,208(sp)
    800057e2:	e5ce                	sd	s3,200(sp)
    800057e4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057e6:	08000613          	li	a2,128
    800057ea:	f3040593          	addi	a1,s0,-208
    800057ee:	4501                	li	a0,0
    800057f0:	ffffd097          	auipc	ra,0xffffd
    800057f4:	57a080e7          	jalr	1402(ra) # 80002d6a <argstr>
    800057f8:	18054163          	bltz	a0,8000597a <sys_unlink+0x1a2>
  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	bd0080e7          	jalr	-1072(ra) # 800043cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005804:	fb040593          	addi	a1,s0,-80
    80005808:	f3040513          	addi	a0,s0,-208
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	9be080e7          	jalr	-1602(ra) # 800041ca <nameiparent>
    80005814:	84aa                	mv	s1,a0
    80005816:	c979                	beqz	a0,800058ec <sys_unlink+0x114>
  ilock(dp);
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	1e8080e7          	jalr	488(ra) # 80003a00 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005820:	00003597          	auipc	a1,0x3
    80005824:	ef058593          	addi	a1,a1,-272 # 80008710 <syscalls+0x2c0>
    80005828:	fb040513          	addi	a0,s0,-80
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	69e080e7          	jalr	1694(ra) # 80003eca <namecmp>
    80005834:	14050a63          	beqz	a0,80005988 <sys_unlink+0x1b0>
    80005838:	00003597          	auipc	a1,0x3
    8000583c:	ee058593          	addi	a1,a1,-288 # 80008718 <syscalls+0x2c8>
    80005840:	fb040513          	addi	a0,s0,-80
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	686080e7          	jalr	1670(ra) # 80003eca <namecmp>
    8000584c:	12050e63          	beqz	a0,80005988 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005850:	f2c40613          	addi	a2,s0,-212
    80005854:	fb040593          	addi	a1,s0,-80
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	68a080e7          	jalr	1674(ra) # 80003ee4 <dirlookup>
    80005862:	892a                	mv	s2,a0
    80005864:	12050263          	beqz	a0,80005988 <sys_unlink+0x1b0>
  ilock(ip);
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	198080e7          	jalr	408(ra) # 80003a00 <ilock>
  if(ip->nlink < 1)
    80005870:	04a91783          	lh	a5,74(s2)
    80005874:	08f05263          	blez	a5,800058f8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005878:	04491703          	lh	a4,68(s2)
    8000587c:	4785                	li	a5,1
    8000587e:	08f70563          	beq	a4,a5,80005908 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005882:	4641                	li	a2,16
    80005884:	4581                	li	a1,0
    80005886:	fc040513          	addi	a0,s0,-64
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	448080e7          	jalr	1096(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005892:	4741                	li	a4,16
    80005894:	f2c42683          	lw	a3,-212(s0)
    80005898:	fc040613          	addi	a2,s0,-64
    8000589c:	4581                	li	a1,0
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	50c080e7          	jalr	1292(ra) # 80003dac <writei>
    800058a8:	47c1                	li	a5,16
    800058aa:	0af51563          	bne	a0,a5,80005954 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058ae:	04491703          	lh	a4,68(s2)
    800058b2:	4785                	li	a5,1
    800058b4:	0af70863          	beq	a4,a5,80005964 <sys_unlink+0x18c>
  iunlockput(dp);
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	3a8080e7          	jalr	936(ra) # 80003c62 <iunlockput>
  ip->nlink--;
    800058c2:	04a95783          	lhu	a5,74(s2)
    800058c6:	37fd                	addiw	a5,a5,-1
    800058c8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	066080e7          	jalr	102(ra) # 80003934 <iupdate>
  iunlockput(ip);
    800058d6:	854a                	mv	a0,s2
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	38a080e7          	jalr	906(ra) # 80003c62 <iunlockput>
  end_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	b6a080e7          	jalr	-1174(ra) # 8000444a <end_op>
  return 0;
    800058e8:	4501                	li	a0,0
    800058ea:	a84d                	j	8000599c <sys_unlink+0x1c4>
    end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	b5e080e7          	jalr	-1186(ra) # 8000444a <end_op>
    return -1;
    800058f4:	557d                	li	a0,-1
    800058f6:	a05d                	j	8000599c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058f8:	00003517          	auipc	a0,0x3
    800058fc:	e2850513          	addi	a0,a0,-472 # 80008720 <syscalls+0x2d0>
    80005900:	ffffb097          	auipc	ra,0xffffb
    80005904:	c40080e7          	jalr	-960(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005908:	04c92703          	lw	a4,76(s2)
    8000590c:	02000793          	li	a5,32
    80005910:	f6e7f9e3          	bgeu	a5,a4,80005882 <sys_unlink+0xaa>
    80005914:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005918:	4741                	li	a4,16
    8000591a:	86ce                	mv	a3,s3
    8000591c:	f1840613          	addi	a2,s0,-232
    80005920:	4581                	li	a1,0
    80005922:	854a                	mv	a0,s2
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	390080e7          	jalr	912(ra) # 80003cb4 <readi>
    8000592c:	47c1                	li	a5,16
    8000592e:	00f51b63          	bne	a0,a5,80005944 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005932:	f1845783          	lhu	a5,-232(s0)
    80005936:	e7a1                	bnez	a5,8000597e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005938:	29c1                	addiw	s3,s3,16
    8000593a:	04c92783          	lw	a5,76(s2)
    8000593e:	fcf9ede3          	bltu	s3,a5,80005918 <sys_unlink+0x140>
    80005942:	b781                	j	80005882 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005944:	00003517          	auipc	a0,0x3
    80005948:	df450513          	addi	a0,a0,-524 # 80008738 <syscalls+0x2e8>
    8000594c:	ffffb097          	auipc	ra,0xffffb
    80005950:	bf4080e7          	jalr	-1036(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005954:	00003517          	auipc	a0,0x3
    80005958:	dfc50513          	addi	a0,a0,-516 # 80008750 <syscalls+0x300>
    8000595c:	ffffb097          	auipc	ra,0xffffb
    80005960:	be4080e7          	jalr	-1052(ra) # 80000540 <panic>
    dp->nlink--;
    80005964:	04a4d783          	lhu	a5,74(s1)
    80005968:	37fd                	addiw	a5,a5,-1
    8000596a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	fc4080e7          	jalr	-60(ra) # 80003934 <iupdate>
    80005978:	b781                	j	800058b8 <sys_unlink+0xe0>
    return -1;
    8000597a:	557d                	li	a0,-1
    8000597c:	a005                	j	8000599c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000597e:	854a                	mv	a0,s2
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	2e2080e7          	jalr	738(ra) # 80003c62 <iunlockput>
  iunlockput(dp);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	2d8080e7          	jalr	728(ra) # 80003c62 <iunlockput>
  end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	ab8080e7          	jalr	-1352(ra) # 8000444a <end_op>
  return -1;
    8000599a:	557d                	li	a0,-1
}
    8000599c:	70ae                	ld	ra,232(sp)
    8000599e:	740e                	ld	s0,224(sp)
    800059a0:	64ee                	ld	s1,216(sp)
    800059a2:	694e                	ld	s2,208(sp)
    800059a4:	69ae                	ld	s3,200(sp)
    800059a6:	616d                	addi	sp,sp,240
    800059a8:	8082                	ret

00000000800059aa <sys_open>:

uint64
sys_open(void)
{
    800059aa:	7131                	addi	sp,sp,-192
    800059ac:	fd06                	sd	ra,184(sp)
    800059ae:	f922                	sd	s0,176(sp)
    800059b0:	f526                	sd	s1,168(sp)
    800059b2:	f14a                	sd	s2,160(sp)
    800059b4:	ed4e                	sd	s3,152(sp)
    800059b6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059b8:	f4c40593          	addi	a1,s0,-180
    800059bc:	4505                	li	a0,1
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	36c080e7          	jalr	876(ra) # 80002d2a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059c6:	08000613          	li	a2,128
    800059ca:	f5040593          	addi	a1,s0,-176
    800059ce:	4501                	li	a0,0
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	39a080e7          	jalr	922(ra) # 80002d6a <argstr>
    800059d8:	87aa                	mv	a5,a0
    return -1;
    800059da:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059dc:	0a07c963          	bltz	a5,80005a8e <sys_open+0xe4>

  begin_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	9ec080e7          	jalr	-1556(ra) # 800043cc <begin_op>

  if(omode & O_CREATE){
    800059e8:	f4c42783          	lw	a5,-180(s0)
    800059ec:	2007f793          	andi	a5,a5,512
    800059f0:	cfc5                	beqz	a5,80005aa8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059f2:	4681                	li	a3,0
    800059f4:	4601                	li	a2,0
    800059f6:	4589                	li	a1,2
    800059f8:	f5040513          	addi	a0,s0,-176
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	972080e7          	jalr	-1678(ra) # 8000536e <create>
    80005a04:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a06:	c959                	beqz	a0,80005a9c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a08:	04449703          	lh	a4,68(s1)
    80005a0c:	478d                	li	a5,3
    80005a0e:	00f71763          	bne	a4,a5,80005a1c <sys_open+0x72>
    80005a12:	0464d703          	lhu	a4,70(s1)
    80005a16:	47a5                	li	a5,9
    80005a18:	0ce7ed63          	bltu	a5,a4,80005af2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	dbc080e7          	jalr	-580(ra) # 800047d8 <filealloc>
    80005a24:	89aa                	mv	s3,a0
    80005a26:	10050363          	beqz	a0,80005b2c <sys_open+0x182>
    80005a2a:	00000097          	auipc	ra,0x0
    80005a2e:	902080e7          	jalr	-1790(ra) # 8000532c <fdalloc>
    80005a32:	892a                	mv	s2,a0
    80005a34:	0e054763          	bltz	a0,80005b22 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a38:	04449703          	lh	a4,68(s1)
    80005a3c:	478d                	li	a5,3
    80005a3e:	0cf70563          	beq	a4,a5,80005b08 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a42:	4789                	li	a5,2
    80005a44:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a48:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a4c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a50:	f4c42783          	lw	a5,-180(s0)
    80005a54:	0017c713          	xori	a4,a5,1
    80005a58:	8b05                	andi	a4,a4,1
    80005a5a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a5e:	0037f713          	andi	a4,a5,3
    80005a62:	00e03733          	snez	a4,a4
    80005a66:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a6a:	4007f793          	andi	a5,a5,1024
    80005a6e:	c791                	beqz	a5,80005a7a <sys_open+0xd0>
    80005a70:	04449703          	lh	a4,68(s1)
    80005a74:	4789                	li	a5,2
    80005a76:	0af70063          	beq	a4,a5,80005b16 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	046080e7          	jalr	70(ra) # 80003ac2 <iunlock>
  end_op();
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	9c6080e7          	jalr	-1594(ra) # 8000444a <end_op>

  return fd;
    80005a8c:	854a                	mv	a0,s2
}
    80005a8e:	70ea                	ld	ra,184(sp)
    80005a90:	744a                	ld	s0,176(sp)
    80005a92:	74aa                	ld	s1,168(sp)
    80005a94:	790a                	ld	s2,160(sp)
    80005a96:	69ea                	ld	s3,152(sp)
    80005a98:	6129                	addi	sp,sp,192
    80005a9a:	8082                	ret
      end_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	9ae080e7          	jalr	-1618(ra) # 8000444a <end_op>
      return -1;
    80005aa4:	557d                	li	a0,-1
    80005aa6:	b7e5                	j	80005a8e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005aa8:	f5040513          	addi	a0,s0,-176
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	700080e7          	jalr	1792(ra) # 800041ac <namei>
    80005ab4:	84aa                	mv	s1,a0
    80005ab6:	c905                	beqz	a0,80005ae6 <sys_open+0x13c>
    ilock(ip);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	f48080e7          	jalr	-184(ra) # 80003a00 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ac0:	04449703          	lh	a4,68(s1)
    80005ac4:	4785                	li	a5,1
    80005ac6:	f4f711e3          	bne	a4,a5,80005a08 <sys_open+0x5e>
    80005aca:	f4c42783          	lw	a5,-180(s0)
    80005ace:	d7b9                	beqz	a5,80005a1c <sys_open+0x72>
      iunlockput(ip);
    80005ad0:	8526                	mv	a0,s1
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	190080e7          	jalr	400(ra) # 80003c62 <iunlockput>
      end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	970080e7          	jalr	-1680(ra) # 8000444a <end_op>
      return -1;
    80005ae2:	557d                	li	a0,-1
    80005ae4:	b76d                	j	80005a8e <sys_open+0xe4>
      end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	964080e7          	jalr	-1692(ra) # 8000444a <end_op>
      return -1;
    80005aee:	557d                	li	a0,-1
    80005af0:	bf79                	j	80005a8e <sys_open+0xe4>
    iunlockput(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	16e080e7          	jalr	366(ra) # 80003c62 <iunlockput>
    end_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	94e080e7          	jalr	-1714(ra) # 8000444a <end_op>
    return -1;
    80005b04:	557d                	li	a0,-1
    80005b06:	b761                	j	80005a8e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b08:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b0c:	04649783          	lh	a5,70(s1)
    80005b10:	02f99223          	sh	a5,36(s3)
    80005b14:	bf25                	j	80005a4c <sys_open+0xa2>
    itrunc(ip);
    80005b16:	8526                	mv	a0,s1
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	ff6080e7          	jalr	-10(ra) # 80003b0e <itrunc>
    80005b20:	bfa9                	j	80005a7a <sys_open+0xd0>
      fileclose(f);
    80005b22:	854e                	mv	a0,s3
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	d70080e7          	jalr	-656(ra) # 80004894 <fileclose>
    iunlockput(ip);
    80005b2c:	8526                	mv	a0,s1
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	134080e7          	jalr	308(ra) # 80003c62 <iunlockput>
    end_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	914080e7          	jalr	-1772(ra) # 8000444a <end_op>
    return -1;
    80005b3e:	557d                	li	a0,-1
    80005b40:	b7b9                	j	80005a8e <sys_open+0xe4>

0000000080005b42 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b42:	7175                	addi	sp,sp,-144
    80005b44:	e506                	sd	ra,136(sp)
    80005b46:	e122                	sd	s0,128(sp)
    80005b48:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	882080e7          	jalr	-1918(ra) # 800043cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b52:	08000613          	li	a2,128
    80005b56:	f7040593          	addi	a1,s0,-144
    80005b5a:	4501                	li	a0,0
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	20e080e7          	jalr	526(ra) # 80002d6a <argstr>
    80005b64:	02054963          	bltz	a0,80005b96 <sys_mkdir+0x54>
    80005b68:	4681                	li	a3,0
    80005b6a:	4601                	li	a2,0
    80005b6c:	4585                	li	a1,1
    80005b6e:	f7040513          	addi	a0,s0,-144
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	7fc080e7          	jalr	2044(ra) # 8000536e <create>
    80005b7a:	cd11                	beqz	a0,80005b96 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	0e6080e7          	jalr	230(ra) # 80003c62 <iunlockput>
  end_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	8c6080e7          	jalr	-1850(ra) # 8000444a <end_op>
  return 0;
    80005b8c:	4501                	li	a0,0
}
    80005b8e:	60aa                	ld	ra,136(sp)
    80005b90:	640a                	ld	s0,128(sp)
    80005b92:	6149                	addi	sp,sp,144
    80005b94:	8082                	ret
    end_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	8b4080e7          	jalr	-1868(ra) # 8000444a <end_op>
    return -1;
    80005b9e:	557d                	li	a0,-1
    80005ba0:	b7fd                	j	80005b8e <sys_mkdir+0x4c>

0000000080005ba2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ba2:	7135                	addi	sp,sp,-160
    80005ba4:	ed06                	sd	ra,152(sp)
    80005ba6:	e922                	sd	s0,144(sp)
    80005ba8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	822080e7          	jalr	-2014(ra) # 800043cc <begin_op>
  argint(1, &major);
    80005bb2:	f6c40593          	addi	a1,s0,-148
    80005bb6:	4505                	li	a0,1
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	172080e7          	jalr	370(ra) # 80002d2a <argint>
  argint(2, &minor);
    80005bc0:	f6840593          	addi	a1,s0,-152
    80005bc4:	4509                	li	a0,2
    80005bc6:	ffffd097          	auipc	ra,0xffffd
    80005bca:	164080e7          	jalr	356(ra) # 80002d2a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bce:	08000613          	li	a2,128
    80005bd2:	f7040593          	addi	a1,s0,-144
    80005bd6:	4501                	li	a0,0
    80005bd8:	ffffd097          	auipc	ra,0xffffd
    80005bdc:	192080e7          	jalr	402(ra) # 80002d6a <argstr>
    80005be0:	02054b63          	bltz	a0,80005c16 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005be4:	f6841683          	lh	a3,-152(s0)
    80005be8:	f6c41603          	lh	a2,-148(s0)
    80005bec:	458d                	li	a1,3
    80005bee:	f7040513          	addi	a0,s0,-144
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	77c080e7          	jalr	1916(ra) # 8000536e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bfa:	cd11                	beqz	a0,80005c16 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	066080e7          	jalr	102(ra) # 80003c62 <iunlockput>
  end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	846080e7          	jalr	-1978(ra) # 8000444a <end_op>
  return 0;
    80005c0c:	4501                	li	a0,0
}
    80005c0e:	60ea                	ld	ra,152(sp)
    80005c10:	644a                	ld	s0,144(sp)
    80005c12:	610d                	addi	sp,sp,160
    80005c14:	8082                	ret
    end_op();
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	834080e7          	jalr	-1996(ra) # 8000444a <end_op>
    return -1;
    80005c1e:	557d                	li	a0,-1
    80005c20:	b7fd                	j	80005c0e <sys_mknod+0x6c>

0000000080005c22 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c22:	7135                	addi	sp,sp,-160
    80005c24:	ed06                	sd	ra,152(sp)
    80005c26:	e922                	sd	s0,144(sp)
    80005c28:	e526                	sd	s1,136(sp)
    80005c2a:	e14a                	sd	s2,128(sp)
    80005c2c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c2e:	ffffc097          	auipc	ra,0xffffc
    80005c32:	d7e080e7          	jalr	-642(ra) # 800019ac <myproc>
    80005c36:	892a                	mv	s2,a0
  
  begin_op();
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	794080e7          	jalr	1940(ra) # 800043cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c40:	08000613          	li	a2,128
    80005c44:	f6040593          	addi	a1,s0,-160
    80005c48:	4501                	li	a0,0
    80005c4a:	ffffd097          	auipc	ra,0xffffd
    80005c4e:	120080e7          	jalr	288(ra) # 80002d6a <argstr>
    80005c52:	04054b63          	bltz	a0,80005ca8 <sys_chdir+0x86>
    80005c56:	f6040513          	addi	a0,s0,-160
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	552080e7          	jalr	1362(ra) # 800041ac <namei>
    80005c62:	84aa                	mv	s1,a0
    80005c64:	c131                	beqz	a0,80005ca8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	d9a080e7          	jalr	-614(ra) # 80003a00 <ilock>
  if(ip->type != T_DIR){
    80005c6e:	04449703          	lh	a4,68(s1)
    80005c72:	4785                	li	a5,1
    80005c74:	04f71063          	bne	a4,a5,80005cb4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c78:	8526                	mv	a0,s1
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	e48080e7          	jalr	-440(ra) # 80003ac2 <iunlock>
  iput(p->cwd);
    80005c82:	15093503          	ld	a0,336(s2)
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	f34080e7          	jalr	-204(ra) # 80003bba <iput>
  end_op();
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	7bc080e7          	jalr	1980(ra) # 8000444a <end_op>
  p->cwd = ip;
    80005c96:	14993823          	sd	s1,336(s2)
  return 0;
    80005c9a:	4501                	li	a0,0
}
    80005c9c:	60ea                	ld	ra,152(sp)
    80005c9e:	644a                	ld	s0,144(sp)
    80005ca0:	64aa                	ld	s1,136(sp)
    80005ca2:	690a                	ld	s2,128(sp)
    80005ca4:	610d                	addi	sp,sp,160
    80005ca6:	8082                	ret
    end_op();
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	7a2080e7          	jalr	1954(ra) # 8000444a <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	b7ed                	j	80005c9c <sys_chdir+0x7a>
    iunlockput(ip);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	fac080e7          	jalr	-84(ra) # 80003c62 <iunlockput>
    end_op();
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	78c080e7          	jalr	1932(ra) # 8000444a <end_op>
    return -1;
    80005cc6:	557d                	li	a0,-1
    80005cc8:	bfd1                	j	80005c9c <sys_chdir+0x7a>

0000000080005cca <sys_exec>:

uint64
sys_exec(void)
{
    80005cca:	7145                	addi	sp,sp,-464
    80005ccc:	e786                	sd	ra,456(sp)
    80005cce:	e3a2                	sd	s0,448(sp)
    80005cd0:	ff26                	sd	s1,440(sp)
    80005cd2:	fb4a                	sd	s2,432(sp)
    80005cd4:	f74e                	sd	s3,424(sp)
    80005cd6:	f352                	sd	s4,416(sp)
    80005cd8:	ef56                	sd	s5,408(sp)
    80005cda:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cdc:	e3840593          	addi	a1,s0,-456
    80005ce0:	4505                	li	a0,1
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	068080e7          	jalr	104(ra) # 80002d4a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cea:	08000613          	li	a2,128
    80005cee:	f4040593          	addi	a1,s0,-192
    80005cf2:	4501                	li	a0,0
    80005cf4:	ffffd097          	auipc	ra,0xffffd
    80005cf8:	076080e7          	jalr	118(ra) # 80002d6a <argstr>
    80005cfc:	87aa                	mv	a5,a0
    return -1;
    80005cfe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d00:	0c07c363          	bltz	a5,80005dc6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005d04:	10000613          	li	a2,256
    80005d08:	4581                	li	a1,0
    80005d0a:	e4040513          	addi	a0,s0,-448
    80005d0e:	ffffb097          	auipc	ra,0xffffb
    80005d12:	fc4080e7          	jalr	-60(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d16:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d1a:	89a6                	mv	s3,s1
    80005d1c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d1e:	02000a13          	li	s4,32
    80005d22:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d26:	00391513          	slli	a0,s2,0x3
    80005d2a:	e3040593          	addi	a1,s0,-464
    80005d2e:	e3843783          	ld	a5,-456(s0)
    80005d32:	953e                	add	a0,a0,a5
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	f58080e7          	jalr	-168(ra) # 80002c8c <fetchaddr>
    80005d3c:	02054a63          	bltz	a0,80005d70 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d40:	e3043783          	ld	a5,-464(s0)
    80005d44:	c3b9                	beqz	a5,80005d8a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d46:	ffffb097          	auipc	ra,0xffffb
    80005d4a:	da0080e7          	jalr	-608(ra) # 80000ae6 <kalloc>
    80005d4e:	85aa                	mv	a1,a0
    80005d50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d54:	cd11                	beqz	a0,80005d70 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d56:	6605                	lui	a2,0x1
    80005d58:	e3043503          	ld	a0,-464(s0)
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	f82080e7          	jalr	-126(ra) # 80002cde <fetchstr>
    80005d64:	00054663          	bltz	a0,80005d70 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d68:	0905                	addi	s2,s2,1
    80005d6a:	09a1                	addi	s3,s3,8
    80005d6c:	fb491be3          	bne	s2,s4,80005d22 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d70:	f4040913          	addi	s2,s0,-192
    80005d74:	6088                	ld	a0,0(s1)
    80005d76:	c539                	beqz	a0,80005dc4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d78:	ffffb097          	auipc	ra,0xffffb
    80005d7c:	c70080e7          	jalr	-912(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d80:	04a1                	addi	s1,s1,8
    80005d82:	ff2499e3          	bne	s1,s2,80005d74 <sys_exec+0xaa>
  return -1;
    80005d86:	557d                	li	a0,-1
    80005d88:	a83d                	j	80005dc6 <sys_exec+0xfc>
      argv[i] = 0;
    80005d8a:	0a8e                	slli	s5,s5,0x3
    80005d8c:	fc0a8793          	addi	a5,s5,-64
    80005d90:	00878ab3          	add	s5,a5,s0
    80005d94:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d98:	e4040593          	addi	a1,s0,-448
    80005d9c:	f4040513          	addi	a0,s0,-192
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	16e080e7          	jalr	366(ra) # 80004f0e <exec>
    80005da8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005daa:	f4040993          	addi	s3,s0,-192
    80005dae:	6088                	ld	a0,0(s1)
    80005db0:	c901                	beqz	a0,80005dc0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005db2:	ffffb097          	auipc	ra,0xffffb
    80005db6:	c36080e7          	jalr	-970(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dba:	04a1                	addi	s1,s1,8
    80005dbc:	ff3499e3          	bne	s1,s3,80005dae <sys_exec+0xe4>
  return ret;
    80005dc0:	854a                	mv	a0,s2
    80005dc2:	a011                	j	80005dc6 <sys_exec+0xfc>
  return -1;
    80005dc4:	557d                	li	a0,-1
}
    80005dc6:	60be                	ld	ra,456(sp)
    80005dc8:	641e                	ld	s0,448(sp)
    80005dca:	74fa                	ld	s1,440(sp)
    80005dcc:	795a                	ld	s2,432(sp)
    80005dce:	79ba                	ld	s3,424(sp)
    80005dd0:	7a1a                	ld	s4,416(sp)
    80005dd2:	6afa                	ld	s5,408(sp)
    80005dd4:	6179                	addi	sp,sp,464
    80005dd6:	8082                	ret

0000000080005dd8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dd8:	7139                	addi	sp,sp,-64
    80005dda:	fc06                	sd	ra,56(sp)
    80005ddc:	f822                	sd	s0,48(sp)
    80005dde:	f426                	sd	s1,40(sp)
    80005de0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005de2:	ffffc097          	auipc	ra,0xffffc
    80005de6:	bca080e7          	jalr	-1078(ra) # 800019ac <myproc>
    80005dea:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dec:	fd840593          	addi	a1,s0,-40
    80005df0:	4501                	li	a0,0
    80005df2:	ffffd097          	auipc	ra,0xffffd
    80005df6:	f58080e7          	jalr	-168(ra) # 80002d4a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dfa:	fc840593          	addi	a1,s0,-56
    80005dfe:	fd040513          	addi	a0,s0,-48
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	dc2080e7          	jalr	-574(ra) # 80004bc4 <pipealloc>
    return -1;
    80005e0a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e0c:	0c054463          	bltz	a0,80005ed4 <sys_pipe+0xfc>
  fd0 = -1;
    80005e10:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e14:	fd043503          	ld	a0,-48(s0)
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	514080e7          	jalr	1300(ra) # 8000532c <fdalloc>
    80005e20:	fca42223          	sw	a0,-60(s0)
    80005e24:	08054b63          	bltz	a0,80005eba <sys_pipe+0xe2>
    80005e28:	fc843503          	ld	a0,-56(s0)
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	500080e7          	jalr	1280(ra) # 8000532c <fdalloc>
    80005e34:	fca42023          	sw	a0,-64(s0)
    80005e38:	06054863          	bltz	a0,80005ea8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e3c:	4691                	li	a3,4
    80005e3e:	fc440613          	addi	a2,s0,-60
    80005e42:	fd843583          	ld	a1,-40(s0)
    80005e46:	68a8                	ld	a0,80(s1)
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	824080e7          	jalr	-2012(ra) # 8000166c <copyout>
    80005e50:	02054063          	bltz	a0,80005e70 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e54:	4691                	li	a3,4
    80005e56:	fc040613          	addi	a2,s0,-64
    80005e5a:	fd843583          	ld	a1,-40(s0)
    80005e5e:	0591                	addi	a1,a1,4
    80005e60:	68a8                	ld	a0,80(s1)
    80005e62:	ffffc097          	auipc	ra,0xffffc
    80005e66:	80a080e7          	jalr	-2038(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e6a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e6c:	06055463          	bgez	a0,80005ed4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e70:	fc442783          	lw	a5,-60(s0)
    80005e74:	07e9                	addi	a5,a5,26
    80005e76:	078e                	slli	a5,a5,0x3
    80005e78:	97a6                	add	a5,a5,s1
    80005e7a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e7e:	fc042783          	lw	a5,-64(s0)
    80005e82:	07e9                	addi	a5,a5,26
    80005e84:	078e                	slli	a5,a5,0x3
    80005e86:	94be                	add	s1,s1,a5
    80005e88:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e8c:	fd043503          	ld	a0,-48(s0)
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	a04080e7          	jalr	-1532(ra) # 80004894 <fileclose>
    fileclose(wf);
    80005e98:	fc843503          	ld	a0,-56(s0)
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	9f8080e7          	jalr	-1544(ra) # 80004894 <fileclose>
    return -1;
    80005ea4:	57fd                	li	a5,-1
    80005ea6:	a03d                	j	80005ed4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ea8:	fc442783          	lw	a5,-60(s0)
    80005eac:	0007c763          	bltz	a5,80005eba <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005eb0:	07e9                	addi	a5,a5,26
    80005eb2:	078e                	slli	a5,a5,0x3
    80005eb4:	97a6                	add	a5,a5,s1
    80005eb6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005eba:	fd043503          	ld	a0,-48(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	9d6080e7          	jalr	-1578(ra) # 80004894 <fileclose>
    fileclose(wf);
    80005ec6:	fc843503          	ld	a0,-56(s0)
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	9ca080e7          	jalr	-1590(ra) # 80004894 <fileclose>
    return -1;
    80005ed2:	57fd                	li	a5,-1
}
    80005ed4:	853e                	mv	a0,a5
    80005ed6:	70e2                	ld	ra,56(sp)
    80005ed8:	7442                	ld	s0,48(sp)
    80005eda:	74a2                	ld	s1,40(sp)
    80005edc:	6121                	addi	sp,sp,64
    80005ede:	8082                	ret

0000000080005ee0 <kernelvec>:
    80005ee0:	7111                	addi	sp,sp,-256
    80005ee2:	e006                	sd	ra,0(sp)
    80005ee4:	e40a                	sd	sp,8(sp)
    80005ee6:	e80e                	sd	gp,16(sp)
    80005ee8:	ec12                	sd	tp,24(sp)
    80005eea:	f016                	sd	t0,32(sp)
    80005eec:	f41a                	sd	t1,40(sp)
    80005eee:	f81e                	sd	t2,48(sp)
    80005ef0:	fc22                	sd	s0,56(sp)
    80005ef2:	e0a6                	sd	s1,64(sp)
    80005ef4:	e4aa                	sd	a0,72(sp)
    80005ef6:	e8ae                	sd	a1,80(sp)
    80005ef8:	ecb2                	sd	a2,88(sp)
    80005efa:	f0b6                	sd	a3,96(sp)
    80005efc:	f4ba                	sd	a4,104(sp)
    80005efe:	f8be                	sd	a5,112(sp)
    80005f00:	fcc2                	sd	a6,120(sp)
    80005f02:	e146                	sd	a7,128(sp)
    80005f04:	e54a                	sd	s2,136(sp)
    80005f06:	e94e                	sd	s3,144(sp)
    80005f08:	ed52                	sd	s4,152(sp)
    80005f0a:	f156                	sd	s5,160(sp)
    80005f0c:	f55a                	sd	s6,168(sp)
    80005f0e:	f95e                	sd	s7,176(sp)
    80005f10:	fd62                	sd	s8,184(sp)
    80005f12:	e1e6                	sd	s9,192(sp)
    80005f14:	e5ea                	sd	s10,200(sp)
    80005f16:	e9ee                	sd	s11,208(sp)
    80005f18:	edf2                	sd	t3,216(sp)
    80005f1a:	f1f6                	sd	t4,224(sp)
    80005f1c:	f5fa                	sd	t5,232(sp)
    80005f1e:	f9fe                	sd	t6,240(sp)
    80005f20:	c39fc0ef          	jal	ra,80002b58 <kerneltrap>
    80005f24:	6082                	ld	ra,0(sp)
    80005f26:	6122                	ld	sp,8(sp)
    80005f28:	61c2                	ld	gp,16(sp)
    80005f2a:	7282                	ld	t0,32(sp)
    80005f2c:	7322                	ld	t1,40(sp)
    80005f2e:	73c2                	ld	t2,48(sp)
    80005f30:	7462                	ld	s0,56(sp)
    80005f32:	6486                	ld	s1,64(sp)
    80005f34:	6526                	ld	a0,72(sp)
    80005f36:	65c6                	ld	a1,80(sp)
    80005f38:	6666                	ld	a2,88(sp)
    80005f3a:	7686                	ld	a3,96(sp)
    80005f3c:	7726                	ld	a4,104(sp)
    80005f3e:	77c6                	ld	a5,112(sp)
    80005f40:	7866                	ld	a6,120(sp)
    80005f42:	688a                	ld	a7,128(sp)
    80005f44:	692a                	ld	s2,136(sp)
    80005f46:	69ca                	ld	s3,144(sp)
    80005f48:	6a6a                	ld	s4,152(sp)
    80005f4a:	7a8a                	ld	s5,160(sp)
    80005f4c:	7b2a                	ld	s6,168(sp)
    80005f4e:	7bca                	ld	s7,176(sp)
    80005f50:	7c6a                	ld	s8,184(sp)
    80005f52:	6c8e                	ld	s9,192(sp)
    80005f54:	6d2e                	ld	s10,200(sp)
    80005f56:	6dce                	ld	s11,208(sp)
    80005f58:	6e6e                	ld	t3,216(sp)
    80005f5a:	7e8e                	ld	t4,224(sp)
    80005f5c:	7f2e                	ld	t5,232(sp)
    80005f5e:	7fce                	ld	t6,240(sp)
    80005f60:	6111                	addi	sp,sp,256
    80005f62:	10200073          	sret
    80005f66:	00000013          	nop
    80005f6a:	00000013          	nop
    80005f6e:	0001                	nop

0000000080005f70 <timervec>:
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	e10c                	sd	a1,0(a0)
    80005f76:	e510                	sd	a2,8(a0)
    80005f78:	e914                	sd	a3,16(a0)
    80005f7a:	6d0c                	ld	a1,24(a0)
    80005f7c:	7110                	ld	a2,32(a0)
    80005f7e:	6194                	ld	a3,0(a1)
    80005f80:	96b2                	add	a3,a3,a2
    80005f82:	e194                	sd	a3,0(a1)
    80005f84:	4589                	li	a1,2
    80005f86:	14459073          	csrw	sip,a1
    80005f8a:	6914                	ld	a3,16(a0)
    80005f8c:	6510                	ld	a2,8(a0)
    80005f8e:	610c                	ld	a1,0(a0)
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	30200073          	mret
	...

0000000080005f9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f9a:	1141                	addi	sp,sp,-16
    80005f9c:	e422                	sd	s0,8(sp)
    80005f9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fa0:	0c0007b7          	lui	a5,0xc000
    80005fa4:	4705                	li	a4,1
    80005fa6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fa8:	c3d8                	sw	a4,4(a5)
}
    80005faa:	6422                	ld	s0,8(sp)
    80005fac:	0141                	addi	sp,sp,16
    80005fae:	8082                	ret

0000000080005fb0 <plicinithart>:

void
plicinithart(void)
{
    80005fb0:	1141                	addi	sp,sp,-16
    80005fb2:	e406                	sd	ra,8(sp)
    80005fb4:	e022                	sd	s0,0(sp)
    80005fb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	9c8080e7          	jalr	-1592(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fc0:	0085171b          	slliw	a4,a0,0x8
    80005fc4:	0c0027b7          	lui	a5,0xc002
    80005fc8:	97ba                	add	a5,a5,a4
    80005fca:	40200713          	li	a4,1026
    80005fce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fd2:	00d5151b          	slliw	a0,a0,0xd
    80005fd6:	0c2017b7          	lui	a5,0xc201
    80005fda:	97aa                	add	a5,a5,a0
    80005fdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fe0:	60a2                	ld	ra,8(sp)
    80005fe2:	6402                	ld	s0,0(sp)
    80005fe4:	0141                	addi	sp,sp,16
    80005fe6:	8082                	ret

0000000080005fe8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fe8:	1141                	addi	sp,sp,-16
    80005fea:	e406                	sd	ra,8(sp)
    80005fec:	e022                	sd	s0,0(sp)
    80005fee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ff0:	ffffc097          	auipc	ra,0xffffc
    80005ff4:	990080e7          	jalr	-1648(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ff8:	00d5151b          	slliw	a0,a0,0xd
    80005ffc:	0c2017b7          	lui	a5,0xc201
    80006000:	97aa                	add	a5,a5,a0
  return irq;
}
    80006002:	43c8                	lw	a0,4(a5)
    80006004:	60a2                	ld	ra,8(sp)
    80006006:	6402                	ld	s0,0(sp)
    80006008:	0141                	addi	sp,sp,16
    8000600a:	8082                	ret

000000008000600c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000600c:	1101                	addi	sp,sp,-32
    8000600e:	ec06                	sd	ra,24(sp)
    80006010:	e822                	sd	s0,16(sp)
    80006012:	e426                	sd	s1,8(sp)
    80006014:	1000                	addi	s0,sp,32
    80006016:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	968080e7          	jalr	-1688(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006020:	00d5151b          	slliw	a0,a0,0xd
    80006024:	0c2017b7          	lui	a5,0xc201
    80006028:	97aa                	add	a5,a5,a0
    8000602a:	c3c4                	sw	s1,4(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	addi	sp,sp,32
    80006034:	8082                	ret

0000000080006036 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006036:	1141                	addi	sp,sp,-16
    80006038:	e406                	sd	ra,8(sp)
    8000603a:	e022                	sd	s0,0(sp)
    8000603c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000603e:	479d                	li	a5,7
    80006040:	04a7cc63          	blt	a5,a0,80006098 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006044:	0001d797          	auipc	a5,0x1d
    80006048:	41c78793          	addi	a5,a5,1052 # 80023460 <disk>
    8000604c:	97aa                	add	a5,a5,a0
    8000604e:	0187c783          	lbu	a5,24(a5)
    80006052:	ebb9                	bnez	a5,800060a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006054:	00451693          	slli	a3,a0,0x4
    80006058:	0001d797          	auipc	a5,0x1d
    8000605c:	40878793          	addi	a5,a5,1032 # 80023460 <disk>
    80006060:	6398                	ld	a4,0(a5)
    80006062:	9736                	add	a4,a4,a3
    80006064:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006068:	6398                	ld	a4,0(a5)
    8000606a:	9736                	add	a4,a4,a3
    8000606c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006070:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006074:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006078:	97aa                	add	a5,a5,a0
    8000607a:	4705                	li	a4,1
    8000607c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006080:	0001d517          	auipc	a0,0x1d
    80006084:	3f850513          	addi	a0,a0,1016 # 80023478 <disk+0x18>
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	07c080e7          	jalr	124(ra) # 80002104 <wakeup>
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret
    panic("free_desc 1");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6c850513          	addi	a0,a0,1736 # 80008760 <syscalls+0x310>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a0080e7          	jalr	1184(ra) # 80000540 <panic>
    panic("free_desc 2");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	6c850513          	addi	a0,a0,1736 # 80008770 <syscalls+0x320>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	490080e7          	jalr	1168(ra) # 80000540 <panic>

00000000800060b8 <virtio_disk_init>:
{
    800060b8:	1101                	addi	sp,sp,-32
    800060ba:	ec06                	sd	ra,24(sp)
    800060bc:	e822                	sd	s0,16(sp)
    800060be:	e426                	sd	s1,8(sp)
    800060c0:	e04a                	sd	s2,0(sp)
    800060c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060c4:	00002597          	auipc	a1,0x2
    800060c8:	6bc58593          	addi	a1,a1,1724 # 80008780 <syscalls+0x330>
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	4bc50513          	addi	a0,a0,1212 # 80023588 <disk+0x128>
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	a72080e7          	jalr	-1422(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060dc:	100017b7          	lui	a5,0x10001
    800060e0:	4398                	lw	a4,0(a5)
    800060e2:	2701                	sext.w	a4,a4
    800060e4:	747277b7          	lui	a5,0x74727
    800060e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ec:	14f71b63          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f0:	100017b7          	lui	a5,0x10001
    800060f4:	43dc                	lw	a5,4(a5)
    800060f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f8:	4709                	li	a4,2
    800060fa:	14e79463          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	479c                	lw	a5,8(a5)
    80006104:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006106:	12e79e63          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000610a:	100017b7          	lui	a5,0x10001
    8000610e:	47d8                	lw	a4,12(a5)
    80006110:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006112:	554d47b7          	lui	a5,0x554d4
    80006116:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000611a:	12f71463          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006126:	4705                	li	a4,1
    80006128:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612a:	470d                	li	a4,3
    8000612c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000612e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006130:	c7ffe6b7          	lui	a3,0xc7ffe
    80006134:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb1bf>
    80006138:	8f75                	and	a4,a4,a3
    8000613a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613c:	472d                	li	a4,11
    8000613e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006140:	5bbc                	lw	a5,112(a5)
    80006142:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006146:	8ba1                	andi	a5,a5,8
    80006148:	10078563          	beqz	a5,80006252 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006154:	43fc                	lw	a5,68(a5)
    80006156:	2781                	sext.w	a5,a5
    80006158:	10079563          	bnez	a5,80006262 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	5bdc                	lw	a5,52(a5)
    80006162:	2781                	sext.w	a5,a5
  if(max == 0)
    80006164:	10078763          	beqz	a5,80006272 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006168:	471d                	li	a4,7
    8000616a:	10f77c63          	bgeu	a4,a5,80006282 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	978080e7          	jalr	-1672(ra) # 80000ae6 <kalloc>
    80006176:	0001d497          	auipc	s1,0x1d
    8000617a:	2ea48493          	addi	s1,s1,746 # 80023460 <disk>
    8000617e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	966080e7          	jalr	-1690(ra) # 80000ae6 <kalloc>
    80006188:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	95c080e7          	jalr	-1700(ra) # 80000ae6 <kalloc>
    80006192:	87aa                	mv	a5,a0
    80006194:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006196:	6088                	ld	a0,0(s1)
    80006198:	cd6d                	beqz	a0,80006292 <virtio_disk_init+0x1da>
    8000619a:	0001d717          	auipc	a4,0x1d
    8000619e:	2ce73703          	ld	a4,718(a4) # 80023468 <disk+0x8>
    800061a2:	cb65                	beqz	a4,80006292 <virtio_disk_init+0x1da>
    800061a4:	c7fd                	beqz	a5,80006292 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061a6:	6605                	lui	a2,0x1
    800061a8:	4581                	li	a1,0
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	b28080e7          	jalr	-1240(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061b2:	0001d497          	auipc	s1,0x1d
    800061b6:	2ae48493          	addi	s1,s1,686 # 80023460 <disk>
    800061ba:	6605                	lui	a2,0x1
    800061bc:	4581                	li	a1,0
    800061be:	6488                	ld	a0,8(s1)
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	b12080e7          	jalr	-1262(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061c8:	6605                	lui	a2,0x1
    800061ca:	4581                	li	a1,0
    800061cc:	6888                	ld	a0,16(s1)
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	b04080e7          	jalr	-1276(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061d6:	100017b7          	lui	a5,0x10001
    800061da:	4721                	li	a4,8
    800061dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061de:	4098                	lw	a4,0(s1)
    800061e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061e4:	40d8                	lw	a4,4(s1)
    800061e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ea:	6498                	ld	a4,8(s1)
    800061ec:	0007069b          	sext.w	a3,a4
    800061f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061f4:	9701                	srai	a4,a4,0x20
    800061f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061fa:	6898                	ld	a4,16(s1)
    800061fc:	0007069b          	sext.w	a3,a4
    80006200:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006204:	9701                	srai	a4,a4,0x20
    80006206:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000620a:	4705                	li	a4,1
    8000620c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000620e:	00e48c23          	sb	a4,24(s1)
    80006212:	00e48ca3          	sb	a4,25(s1)
    80006216:	00e48d23          	sb	a4,26(s1)
    8000621a:	00e48da3          	sb	a4,27(s1)
    8000621e:	00e48e23          	sb	a4,28(s1)
    80006222:	00e48ea3          	sb	a4,29(s1)
    80006226:	00e48f23          	sb	a4,30(s1)
    8000622a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000622e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006232:	0727a823          	sw	s2,112(a5)
}
    80006236:	60e2                	ld	ra,24(sp)
    80006238:	6442                	ld	s0,16(sp)
    8000623a:	64a2                	ld	s1,8(sp)
    8000623c:	6902                	ld	s2,0(sp)
    8000623e:	6105                	addi	sp,sp,32
    80006240:	8082                	ret
    panic("could not find virtio disk");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	54e50513          	addi	a0,a0,1358 # 80008790 <syscalls+0x340>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	55e50513          	addi	a0,a0,1374 # 800087b0 <syscalls+0x360>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	56e50513          	addi	a0,a0,1390 # 800087d0 <syscalls+0x380>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d6080e7          	jalr	726(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	57e50513          	addi	a0,a0,1406 # 800087f0 <syscalls+0x3a0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	58e50513          	addi	a0,a0,1422 # 80008810 <syscalls+0x3c0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b6080e7          	jalr	694(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	59e50513          	addi	a0,a0,1438 # 80008830 <syscalls+0x3e0>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a6080e7          	jalr	678(ra) # 80000540 <panic>

00000000800062a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062a2:	7119                	addi	sp,sp,-128
    800062a4:	fc86                	sd	ra,120(sp)
    800062a6:	f8a2                	sd	s0,112(sp)
    800062a8:	f4a6                	sd	s1,104(sp)
    800062aa:	f0ca                	sd	s2,96(sp)
    800062ac:	ecce                	sd	s3,88(sp)
    800062ae:	e8d2                	sd	s4,80(sp)
    800062b0:	e4d6                	sd	s5,72(sp)
    800062b2:	e0da                	sd	s6,64(sp)
    800062b4:	fc5e                	sd	s7,56(sp)
    800062b6:	f862                	sd	s8,48(sp)
    800062b8:	f466                	sd	s9,40(sp)
    800062ba:	f06a                	sd	s10,32(sp)
    800062bc:	ec6e                	sd	s11,24(sp)
    800062be:	0100                	addi	s0,sp,128
    800062c0:	8aaa                	mv	s5,a0
    800062c2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062c4:	00c52d03          	lw	s10,12(a0)
    800062c8:	001d1d1b          	slliw	s10,s10,0x1
    800062cc:	1d02                	slli	s10,s10,0x20
    800062ce:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800062d2:	0001d517          	auipc	a0,0x1d
    800062d6:	2b650513          	addi	a0,a0,694 # 80023588 <disk+0x128>
    800062da:	ffffb097          	auipc	ra,0xffffb
    800062de:	8fc080e7          	jalr	-1796(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062e2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062e6:	0001db97          	auipc	s7,0x1d
    800062ea:	17ab8b93          	addi	s7,s7,378 # 80023460 <disk>
  for(int i = 0; i < 3; i++){
    800062ee:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062f0:	0001dc97          	auipc	s9,0x1d
    800062f4:	298c8c93          	addi	s9,s9,664 # 80023588 <disk+0x128>
    800062f8:	a08d                	j	8000635a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062fa:	00fb8733          	add	a4,s7,a5
    800062fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006302:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006304:	0207c563          	bltz	a5,8000632e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006308:	2905                	addiw	s2,s2,1
    8000630a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000630c:	05690c63          	beq	s2,s6,80006364 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006310:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006312:	0001d717          	auipc	a4,0x1d
    80006316:	14e70713          	addi	a4,a4,334 # 80023460 <disk>
    8000631a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000631c:	01874683          	lbu	a3,24(a4)
    80006320:	fee9                	bnez	a3,800062fa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006322:	2785                	addiw	a5,a5,1
    80006324:	0705                	addi	a4,a4,1
    80006326:	fe979be3          	bne	a5,s1,8000631c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000632a:	57fd                	li	a5,-1
    8000632c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000632e:	01205d63          	blez	s2,80006348 <virtio_disk_rw+0xa6>
    80006332:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006334:	000a2503          	lw	a0,0(s4)
    80006338:	00000097          	auipc	ra,0x0
    8000633c:	cfe080e7          	jalr	-770(ra) # 80006036 <free_desc>
      for(int j = 0; j < i; j++)
    80006340:	2d85                	addiw	s11,s11,1
    80006342:	0a11                	addi	s4,s4,4
    80006344:	ff2d98e3          	bne	s11,s2,80006334 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006348:	85e6                	mv	a1,s9
    8000634a:	0001d517          	auipc	a0,0x1d
    8000634e:	12e50513          	addi	a0,a0,302 # 80023478 <disk+0x18>
    80006352:	ffffc097          	auipc	ra,0xffffc
    80006356:	d4e080e7          	jalr	-690(ra) # 800020a0 <sleep>
  for(int i = 0; i < 3; i++){
    8000635a:	f8040a13          	addi	s4,s0,-128
{
    8000635e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006360:	894e                	mv	s2,s3
    80006362:	b77d                	j	80006310 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006364:	f8042503          	lw	a0,-128(s0)
    80006368:	00a50713          	addi	a4,a0,10
    8000636c:	0712                	slli	a4,a4,0x4

  if(write)
    8000636e:	0001d797          	auipc	a5,0x1d
    80006372:	0f278793          	addi	a5,a5,242 # 80023460 <disk>
    80006376:	00e786b3          	add	a3,a5,a4
    8000637a:	01803633          	snez	a2,s8
    8000637e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006380:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006384:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006388:	f6070613          	addi	a2,a4,-160
    8000638c:	6394                	ld	a3,0(a5)
    8000638e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006390:	00870593          	addi	a1,a4,8
    80006394:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006396:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006398:	0007b803          	ld	a6,0(a5)
    8000639c:	9642                	add	a2,a2,a6
    8000639e:	46c1                	li	a3,16
    800063a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063a2:	4585                	li	a1,1
    800063a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063a8:	f8442683          	lw	a3,-124(s0)
    800063ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063b0:	0692                	slli	a3,a3,0x4
    800063b2:	9836                	add	a6,a6,a3
    800063b4:	058a8613          	addi	a2,s5,88
    800063b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063bc:	0007b803          	ld	a6,0(a5)
    800063c0:	96c2                	add	a3,a3,a6
    800063c2:	40000613          	li	a2,1024
    800063c6:	c690                	sw	a2,8(a3)
  if(write)
    800063c8:	001c3613          	seqz	a2,s8
    800063cc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063d0:	00166613          	ori	a2,a2,1
    800063d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063d8:	f8842603          	lw	a2,-120(s0)
    800063dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063e0:	00250693          	addi	a3,a0,2
    800063e4:	0692                	slli	a3,a3,0x4
    800063e6:	96be                	add	a3,a3,a5
    800063e8:	58fd                	li	a7,-1
    800063ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063ee:	0612                	slli	a2,a2,0x4
    800063f0:	9832                	add	a6,a6,a2
    800063f2:	f9070713          	addi	a4,a4,-112
    800063f6:	973e                	add	a4,a4,a5
    800063f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063fc:	6398                	ld	a4,0(a5)
    800063fe:	9732                	add	a4,a4,a2
    80006400:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006402:	4609                	li	a2,2
    80006404:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006408:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000640c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006410:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006414:	6794                	ld	a3,8(a5)
    80006416:	0026d703          	lhu	a4,2(a3)
    8000641a:	8b1d                	andi	a4,a4,7
    8000641c:	0706                	slli	a4,a4,0x1
    8000641e:	96ba                	add	a3,a3,a4
    80006420:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006428:	6798                	ld	a4,8(a5)
    8000642a:	00275783          	lhu	a5,2(a4)
    8000642e:	2785                	addiw	a5,a5,1
    80006430:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006434:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006438:	100017b7          	lui	a5,0x10001
    8000643c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006440:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006444:	0001d917          	auipc	s2,0x1d
    80006448:	14490913          	addi	s2,s2,324 # 80023588 <disk+0x128>
  while(b->disk == 1) {
    8000644c:	4485                	li	s1,1
    8000644e:	00b79c63          	bne	a5,a1,80006466 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006452:	85ca                	mv	a1,s2
    80006454:	8556                	mv	a0,s5
    80006456:	ffffc097          	auipc	ra,0xffffc
    8000645a:	c4a080e7          	jalr	-950(ra) # 800020a0 <sleep>
  while(b->disk == 1) {
    8000645e:	004aa783          	lw	a5,4(s5)
    80006462:	fe9788e3          	beq	a5,s1,80006452 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006466:	f8042903          	lw	s2,-128(s0)
    8000646a:	00290713          	addi	a4,s2,2
    8000646e:	0712                	slli	a4,a4,0x4
    80006470:	0001d797          	auipc	a5,0x1d
    80006474:	ff078793          	addi	a5,a5,-16 # 80023460 <disk>
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000647e:	0001d997          	auipc	s3,0x1d
    80006482:	fe298993          	addi	s3,s3,-30 # 80023460 <disk>
    80006486:	00491713          	slli	a4,s2,0x4
    8000648a:	0009b783          	ld	a5,0(s3)
    8000648e:	97ba                	add	a5,a5,a4
    80006490:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006494:	854a                	mv	a0,s2
    80006496:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	b9c080e7          	jalr	-1124(ra) # 80006036 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064a2:	8885                	andi	s1,s1,1
    800064a4:	f0ed                	bnez	s1,80006486 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064a6:	0001d517          	auipc	a0,0x1d
    800064aa:	0e250513          	addi	a0,a0,226 # 80023588 <disk+0x128>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
}
    800064b6:	70e6                	ld	ra,120(sp)
    800064b8:	7446                	ld	s0,112(sp)
    800064ba:	74a6                	ld	s1,104(sp)
    800064bc:	7906                	ld	s2,96(sp)
    800064be:	69e6                	ld	s3,88(sp)
    800064c0:	6a46                	ld	s4,80(sp)
    800064c2:	6aa6                	ld	s5,72(sp)
    800064c4:	6b06                	ld	s6,64(sp)
    800064c6:	7be2                	ld	s7,56(sp)
    800064c8:	7c42                	ld	s8,48(sp)
    800064ca:	7ca2                	ld	s9,40(sp)
    800064cc:	7d02                	ld	s10,32(sp)
    800064ce:	6de2                	ld	s11,24(sp)
    800064d0:	6109                	addi	sp,sp,128
    800064d2:	8082                	ret

00000000800064d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064d4:	1101                	addi	sp,sp,-32
    800064d6:	ec06                	sd	ra,24(sp)
    800064d8:	e822                	sd	s0,16(sp)
    800064da:	e426                	sd	s1,8(sp)
    800064dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064de:	0001d497          	auipc	s1,0x1d
    800064e2:	f8248493          	addi	s1,s1,-126 # 80023460 <disk>
    800064e6:	0001d517          	auipc	a0,0x1d
    800064ea:	0a250513          	addi	a0,a0,162 # 80023588 <disk+0x128>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	6e8080e7          	jalr	1768(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064f6:	10001737          	lui	a4,0x10001
    800064fa:	533c                	lw	a5,96(a4)
    800064fc:	8b8d                	andi	a5,a5,3
    800064fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006500:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006504:	689c                	ld	a5,16(s1)
    80006506:	0204d703          	lhu	a4,32(s1)
    8000650a:	0027d783          	lhu	a5,2(a5)
    8000650e:	04f70863          	beq	a4,a5,8000655e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006512:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006516:	6898                	ld	a4,16(s1)
    80006518:	0204d783          	lhu	a5,32(s1)
    8000651c:	8b9d                	andi	a5,a5,7
    8000651e:	078e                	slli	a5,a5,0x3
    80006520:	97ba                	add	a5,a5,a4
    80006522:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006524:	00278713          	addi	a4,a5,2
    80006528:	0712                	slli	a4,a4,0x4
    8000652a:	9726                	add	a4,a4,s1
    8000652c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006530:	e721                	bnez	a4,80006578 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006532:	0789                	addi	a5,a5,2
    80006534:	0792                	slli	a5,a5,0x4
    80006536:	97a6                	add	a5,a5,s1
    80006538:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000653a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000653e:	ffffc097          	auipc	ra,0xffffc
    80006542:	bc6080e7          	jalr	-1082(ra) # 80002104 <wakeup>

    disk.used_idx += 1;
    80006546:	0204d783          	lhu	a5,32(s1)
    8000654a:	2785                	addiw	a5,a5,1
    8000654c:	17c2                	slli	a5,a5,0x30
    8000654e:	93c1                	srli	a5,a5,0x30
    80006550:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006554:	6898                	ld	a4,16(s1)
    80006556:	00275703          	lhu	a4,2(a4)
    8000655a:	faf71ce3          	bne	a4,a5,80006512 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000655e:	0001d517          	auipc	a0,0x1d
    80006562:	02a50513          	addi	a0,a0,42 # 80023588 <disk+0x128>
    80006566:	ffffa097          	auipc	ra,0xffffa
    8000656a:	724080e7          	jalr	1828(ra) # 80000c8a <release>
}
    8000656e:	60e2                	ld	ra,24(sp)
    80006570:	6442                	ld	s0,16(sp)
    80006572:	64a2                	ld	s1,8(sp)
    80006574:	6105                	addi	sp,sp,32
    80006576:	8082                	ret
      panic("virtio_disk_intr status");
    80006578:	00002517          	auipc	a0,0x2
    8000657c:	2d050513          	addi	a0,a0,720 # 80008848 <syscalls+0x3f8>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	fc0080e7          	jalr	-64(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
