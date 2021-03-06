#!/usr/bin/env perl

# ====================================================================
# Written by Andy Polyakov <appro@fy.chalmers.se> for the OpenSSL
# project. The module is, however, dual licensed under OpenSSL and
# CRYPTOGAMS licenses depending on where you obtain it. For further
# details see http://www.openssl.org/~appro/cryptogams/.
# ====================================================================

# SHA512 block procedure for ARMv4. September 2007.

# This code is ~4.5 (four and a half) times faster than code generated
# by gcc 3.4 and it spends ~72 clock cycles per byte. 

# Byte order [in]dependence. =========================================
#
# Caller is expected to maintain specific *dword* order in h[0-7],
# namely with most significant dword at *lower* address, which is
# reflected in below two parameters. *Byte* order within these dwords
# in turn is whatever *native* byte order on current platform.
$hi=0;
$lo=4;
# ====================================================================

$output=shift;
open STDOUT,">$output";

$ctx="r0";
$inp="r1";
$len="r2";
$Tlo="r3";
$Thi="r4";
$Alo="r5";
$Ahi="r6";
$Elo="r7";
$Ehi="r8";
$t0="r9";
$t1="r10";
$t2="r11";
$t3="r12";
############	r13 is stack pointer
$Ktbl="r14";
############	r15 is program counter

$Aoff=8*0;
$Boff=8*1;
$Coff=8*2;
$Doff=8*3;
$Eoff=8*4;
$Foff=8*5;
$Goff=8*6;
$Hoff=8*7;
$Xoff=8*8;

sub BODY_00_15() {
my $magic = shift;
$code.=<<___;
	ldr	$t2,[sp,#$Hoff+0]	@ h.lo
	ldr	$t3,[sp,#$Hoff+4]	@ h.hi
	@ Sigma1(x)	(ROTR((x),14) ^ ROTR((x),18)  ^ ROTR((x),41))
	@ LO		lo>>14^hi<<18 ^ lo>>18^hi<<14 ^ hi>>9^lo<<23
	@ HI		hi>>14^lo<<18 ^ hi>>18^lo<<14 ^ lo>>9^hi<<23
	mov	$t0,$Elo,lsr#14
	mov	$t1,$Ehi,lsr#14
	eor	$t0,$t0,$Ehi,lsl#18
	eor	$t1,$t1,$Elo,lsl#18
	eor	$t0,$t0,$Elo,lsr#18
	eor	$t1,$t1,$Ehi,lsr#18
	eor	$t0,$t0,$Ehi,lsl#14
	eor	$t1,$t1,$Elo,lsl#14
	eor	$t0,$t0,$Ehi,lsr#9
	eor	$t1,$t1,$Elo,lsr#9
	eor	$t0,$t0,$Elo,lsl#23
	eor	$t1,$t1,$Ehi,lsl#23	@ Sigma1(e)
	adds	$Tlo,$Tlo,$t0
	adc	$Thi,$Thi,$t1		@ T += Sigma1(e)
	adds	$Tlo,$Tlo,$t2
	adc	$Thi,$Thi,$t3		@ T += h

	ldr	$t0,[sp,#$Foff+0]	@ f.lo
	ldr	$t1,[sp,#$Foff+4]	@ f.hi
	ldr	$t2,[sp,#$Goff+0]	@ g.lo
	ldr	$t3,[sp,#$Goff+4]	@ g.hi
	str	$Elo,[sp,#$Eoff+0]
	str	$Ehi,[sp,#$Eoff+4]
	str	$Alo,[sp,#$Aoff+0]
	str	$Ahi,[sp,#$Aoff+4]

	eor	$t0,$t0,$t2
	eor	$t1,$t1,$t3
	and	$t0,$t0,$Elo
	and	$t1,$t1,$Ehi
	eor	$t0,$t0,$t2
	eor	$t1,$t1,$t3		@ Ch(e,f,g)

	ldr	$t2,[$Ktbl,#4]		@ K[i].lo
	ldr	$t3,[$Ktbl,#0]		@ K[i].hi
	ldr	$Elo,[sp,#$Doff+0]	@ d.lo
	ldr	$Ehi,[sp,#$Doff+4]	@ d.hi

	adds	$Tlo,$Tlo,$t0
	adc	$Thi,$Thi,$t1		@ T += Ch(e,f,g)
	adds	$Tlo,$Tlo,$t2
	adc	$Thi,$Thi,$t3		@ T += K[i]
	adds	$Elo,$Elo,$Tlo
	adc	$Ehi,$Ehi,$Thi		@ d += T

	and	$t0,$t2,#0xff
	teq	$t0,#$magic
	orreq	$Ktbl,$Ktbl,#1

	ldr	$t2,[sp,#$Boff+0]	@ b.lo
	ldr	$t3,[sp,#$Coff+0]	@ c.lo
	@ Sigma0(x)	(ROTR((x),28) ^ ROTR((x),34) ^ ROTR((x),39))
	@ LO		lo>>28^hi<<4  ^ hi>>2^lo<<30 ^ hi>>7^lo<<25
	@ HI		hi>>28^lo<<4  ^ lo>>2^hi<<30 ^ lo>>7^hi<<25
	mov	$t0,$Alo,lsr#28
	mov	$t1,$Ahi,lsr#28
	eor	$t0,$t0,$Ahi,lsl#4
	eor	$t1,$t1,$Alo,lsl#4
	eor	$t0,$t0,$Ahi,lsr#2
	eor	$t1,$t1,$Alo,lsr#2
	eor	$t0,$t0,$Alo,lsl#30
	eor	$t1,$t1,$Ahi,lsl#30
	eor	$t0,$t0,$Ahi,lsr#7
	eor	$t1,$t1,$Alo,lsr#7
	eor	$t0,$t0,$Alo,lsl#25
	eor	$t1,$t1,$Ahi,lsl#25	@ Sigma0(a)
	adds	$Tlo,$Tlo,$t0
	adc	$Thi,$Thi,$t1		@ T += Sigma0(a)

	and	$t0,$Alo,$t2
	orr	$Alo,$Alo,$t2
	ldr	$t1,[sp,#$Boff+4]	@ b.hi
	ldr	$t2,[sp,#$Coff+4]	@ c.hi
	and	$Alo,$Alo,$t3
	orr	$Alo,$Alo,$t0		@ Maj(a,b,c).lo
	and	$t3,$Ahi,$t1
	orr	$Ahi,$Ahi,$t1
	and	$Ahi,$Ahi,$t2
	orr	$Ahi,$Ahi,$t3		@ Maj(a,b,c).hi
	adds	$Alo,$Alo,$Tlo
	adc	$Ahi,$Ahi,$Thi		@ h += T

	sub	sp,sp,#8
	add	$Ktbl,$Ktbl,#8
___
}
$code=<<___;
.text
.code	32
.type	K512,%object
.align	5
K512:
.word	0x428a2f98,0xd728ae22, 0x71374491,0x23ef65cd
.word	0xb5c0fbcf,0xec4d3b2f, 0xe9b5dba5,0x8189dbbc
.word	0x3956c25b,0xf348b538, 0x59f111f1,0xb605d019
.word	0x923f82a4,0xaf194f9b, 0xab1c5ed5,0xda6d8118
.word	0xd807aa98,0xa3030242, 0x12835b01,0x45706fbe
.word	0x243185be,0x4ee4b28c, 0x550c7dc3,0xd5ffb4e2
.word	0x72be5d74,0xf27b896f, 0x80deb1fe,0x3b1696b1
.word	0x9bdc06a7,0x25c71235, 0xc19bf174,0xcf692694
.word	0xe49b69c1,0x9ef14ad2, 0xefbe4786,0x384f25e3
.word	0x0fc19dc6,0x8b8cd5b5, 0x240ca1cc,0x77ac9c65
.word	0x2de92c6f,0x592b0275, 0x4a7484aa,0x6ea6e483
.word	0x5cb0a9dc,0xbd41fbd4, 0x76f988da,0x831153b5
.word	0x983e5152,0xee66dfab, 0xa831c66d,0x2db43210
.word	0xb00327c8,0x98fb213f, 0xbf597fc7,0xbeef0ee4
.word	0xc6e00bf3,0x3da88fc2, 0xd5a79147,0x930aa725
.word	0x06ca6351,0xe003826f, 0x14292967,0x0a0e6e70
.word	0x27b70a85,0x46d22ffc, 0x2e1b2138,0x5c26c926
.word	0x4d2c6dfc,0x5ac42aed, 0x53380d13,0x9d95b3df
.word	0x650a7354,0x8baf63de, 0x766a0abb,0x3c77b2a8
.word	0x81c2c92e,0x47edaee6, 0x92722c85,0x1482353b
.word	0xa2bfe8a1,0x4cf10364, 0xa81a664b,0xbc423001
.word	0xc24b8b70,0xd0f89791, 0xc76c51a3,0x0654be30
.word	0xd192e819,0xd6ef5218, 0xd6990624,0x5565a910
.word	0xf40e3585,0x5771202a, 0x106aa070,0x32bbd1b8
.word	0x19a4c116,0xb8d2d0c8, 0x1e376c08,0x5141ab53
.word	0x2748774c,0xdf8eeb99, 0x34b0bcb5,0xe19b48a8
.word	0x391c0cb3,0xc5c95a63, 0x4ed8aa4a,0xe3418acb
.word	0x5b9cca4f,0x7763e373, 0x682e6ff3,0xd6b2b8a3
.word	0x748f82ee,0x5defb2fc, 0x78a5636f,0x43172f60
.word	0x84c87814,0xa1f0ab72, 0x8cc70208,0x1a6439ec
.word	0x90befffa,0x23631e28, 0xa4506ceb,0xde82bde9
.word	0xbef9a3f7,0xb2c67915, 0xc67178f2,0xe372532b
.word	0xca273ece,0xea26619c, 0xd186b8c7,0x21c0c207
.word	0xeada7dd6,0xcde0eb1e, 0xf57d4f7f,0xee6ed178
.word	0x06f067aa,0x72176fba, 0x0a637dc5,0xa2c898a6
.word	0x113f9804,0xbef90dae, 0x1b710b35,0x131c471b
.word	0x28db77f5,0x23047d84, 0x32caab7b,0x40c72493
.word	0x3c9ebe0a,0x15c9bebc, 0x431d67c4,0x9c100d4c
.word	0x4cc5d4be,0xcb3e42b6, 0x597f299c,0xfc657e2a
.word	0x5fcb6fab,0x3ad6faec, 0x6c44198c,0x4a475817
.size	K512,.-K512

.global	sha512_block_data_order
.type	sha512_block_data_order,%function
sha512_block_data_order:
	sub	r3,pc,#8		@ sha512_block_data_order
	add	$len,$inp,$len,lsl#7	@ len to point at the end of inp
	stmdb	sp!,{r4-r12,lr}
	sub	$Ktbl,r3,#640		@ K512
	sub	sp,sp,#9*8

	ldr	$Elo,[$ctx,#$Eoff+$lo]
	ldr	$Ehi,[$ctx,#$Eoff+$hi]
	ldr	$t0, [$ctx,#$Goff+$lo]
	ldr	$t1, [$ctx,#$Goff+$hi]
	ldr	$t2, [$ctx,#$Hoff+$lo]
	ldr	$t3, [$ctx,#$Hoff+$hi]
.Loop:
	str	$t0, [sp,#$Goff+0]
	str	$t1, [sp,#$Goff+4]
	str	$t2, [sp,#$Hoff+0]
	str	$t3, [sp,#$Hoff+4]
	ldr	$Alo,[$ctx,#$Aoff+$lo]
	ldr	$Ahi,[$ctx,#$Aoff+$hi]
	ldr	$Tlo,[$ctx,#$Boff+$lo]
	ldr	$Thi,[$ctx,#$Boff+$hi]
	ldr	$t0, [$ctx,#$Coff+$lo]
	ldr	$t1, [$ctx,#$Coff+$hi]
	ldr	$t2, [$ctx,#$Doff+$lo]
	ldr	$t3, [$ctx,#$Doff+$hi]
	str	$Tlo,[sp,#$Boff+0]
	str	$Thi,[sp,#$Boff+4]
	str	$t0, [sp,#$Coff+0]
	str	$t1, [sp,#$Coff+4]
	str	$t2, [sp,#$Doff+0]
	str	$t3, [sp,#$Doff+4]
	ldr	$Tlo,[$ctx,#$Foff+$lo]
	ldr	$Thi,[$ctx,#$Foff+$hi]
	str	$Tlo,[sp,#$Foff+0]
	str	$Thi,[sp,#$Foff+4]

.L00_15:
	ldrb	$Tlo,[$inp,#7]
	ldrb	$t0, [$inp,#6]
	ldrb	$t1, [$inp,#5]
	ldrb	$t2, [$inp,#4]
	ldrb	$Thi,[$inp,#3]
	ldrb	$t3, [$inp,#2]
	orr	$Tlo,$Tlo,$t0,lsl#8
	ldrb	$t0, [$inp,#1]
	orr	$Tlo,$Tlo,$t1,lsl#16
	ldrb	$t1, [$inp],#8
	orr	$Tlo,$Tlo,$t2,lsl#24
	orr	$Thi,$Thi,$t3,lsl#8
	orr	$Thi,$Thi,$t0,lsl#16
	orr	$Thi,$Thi,$t1,lsl#24
	str	$Tlo,[sp,#$Xoff+0]
	str	$Thi,[sp,#$Xoff+4]
___
	&BODY_00_15(0x94);
$code.=<<___;
	tst	$Ktbl,#1
	beq	.L00_15
	bic	$Ktbl,$Ktbl,#1

.L16_79:
	ldr	$t0,[sp,#`$Xoff+8*(16-1)`+0]
	ldr	$t1,[sp,#`$Xoff+8*(16-1)`+4]
	ldr	$t2,[sp,#`$Xoff+8*(16-14)`+0]
	ldr	$t3,[sp,#`$Xoff+8*(16-14)`+4]

	@ sigma0(x)	(ROTR((x),1)  ^ ROTR((x),8)  ^ ((x)>>7))
	@ LO		lo>>1^hi<<31  ^ lo>>8^hi<<24 ^ lo>>7^hi<<25
	@ HI		hi>>1^lo<<31  ^ hi>>8^lo<<24 ^ hi>>7
	mov	$Tlo,$t0,lsr#1
	mov	$Thi,$t1,lsr#1
	eor	$Tlo,$Tlo,$t1,lsl#31
	eor	$Thi,$Thi,$t0,lsl#31
	eor	$Tlo,$Tlo,$t0,lsr#8
	eor	$Thi,$Thi,$t1,lsr#8
	eor	$Tlo,$Tlo,$t1,lsl#24
	eor	$Thi,$Thi,$t0,lsl#24
	eor	$Tlo,$Tlo,$t0,lsr#7
	eor	$Thi,$Thi,$t1,lsr#7
	eor	$Tlo,$Tlo,$t1,lsl#25

	@ sigma1(x)	(ROTR((x),19) ^ ROTR((x),61) ^ ((x)>>6))
	@ LO		lo>>19^hi<<13 ^ hi>>29^lo<<3 ^ lo>>6^hi<<26
	@ HI		hi>>19^lo<<13 ^ lo>>29^hi<<3 ^ hi>>6
	mov	$t0,$t2,lsr#19
	mov	$t1,$t3,lsr#19
	eor	$t0,$t0,$t3,lsl#13
	eor	$t1,$t1,$t2,lsl#13
	eor	$t0,$t0,$t3,lsr#29
	eor	$t1,$t1,$t2,lsr#29
	eor	$t0,$t0,$t2,lsl#3
	eor	$t1,$t1,$t3,lsl#3
	eor	$t0,$t0,$t2,lsr#6
	eor	$t1,$t1,$t3,lsr#6
	eor	$t0,$t0,$t3,lsl#26

	ldr	$t2,[sp,#`$Xoff+8*(16-9)`+0]
	ldr	$t3,[sp,#`$Xoff+8*(16-9)`+4]
	adds	$Tlo,$Tlo,$t0
	adc	$Thi,$Thi,$t1

	ldr	$t0,[sp,#`$Xoff+8*16`+0]
	ldr	$t1,[sp,#`$Xoff+8*16`+4]
	adds	$Tlo,$Tlo,$t2
	adc	$Thi,$Thi,$t3
	adds	$Tlo,$Tlo,$t0
	adc	$Thi,$Thi,$t1
	str	$Tlo,[sp,#$Xoff+0]
	str	$Thi,[sp,#$Xoff+4]
___
	&BODY_00_15(0x17);
$code.=<<___;
	tst	$Ktbl,#1
	beq	.L16_79
	bic	$Ktbl,$Ktbl,#1

	ldr	$Tlo,[sp,#$Boff+0]
	ldr	$Thi,[sp,#$Boff+4]
	ldr	$t0, [$ctx,#$Aoff+$lo]
	ldr	$t1, [$ctx,#$Aoff+$hi]
	ldr	$t2, [$ctx,#$Boff+$lo]
	ldr	$t3, [$ctx,#$Boff+$hi]
	adds	$t0,$Alo,$t0
	adc	$t1,$Ahi,$t1
	adds	$t2,$Tlo,$t2
	adc	$t3,$Thi,$t3
	str	$t0, [$ctx,#$Aoff+$lo]
	str	$t1, [$ctx,#$Aoff+$hi]
	str	$t2, [$ctx,#$Boff+$lo]
	str	$t3, [$ctx,#$Boff+$hi]

	ldr	$Alo,[sp,#$Coff+0]
	ldr	$Ahi,[sp,#$Coff+4]
	ldr	$Tlo,[sp,#$Doff+0]
	ldr	$Thi,[sp,#$Doff+4]
	ldr	$t0, [$ctx,#$Coff+$lo]
	ldr	$t1, [$ctx,#$Coff+$hi]
	ldr	$t2, [$ctx,#$Doff+$lo]
	ldr	$t3, [$ctx,#$Doff+$hi]
	adds	$t0,$Alo,$t0
	adc	$t1,$Ahi,$t1
	adds	$t2,$Tlo,$t2
	adc	$t3,$Thi,$t3
	str	$t0, [$ctx,#$Coff+$lo]
	str	$t1, [$ctx,#$Coff+$hi]
	str	$t2, [$ctx,#$Doff+$lo]
	str	$t3, [$ctx,#$Doff+$hi]

	ldr	$Tlo,[sp,#$Foff+0]
	ldr	$Thi,[sp,#$Foff+4]
	ldr	$t0, [$ctx,#$Eoff+$lo]
	ldr	$t1, [$ctx,#$Eoff+$hi]
	ldr	$t2, [$ctx,#$Foff+$lo]
	ldr	$t3, [$ctx,#$Foff+$hi]
	adds	$Elo,$Elo,$t0
	adc	$Ehi,$Ehi,$t1
	adds	$t2,$Tlo,$t2
	adc	$t3,$Thi,$t3
	str	$Elo,[$ctx,#$Eoff+$lo]
	str	$Ehi,[$ctx,#$Eoff+$hi]
	str	$t2, [$ctx,#$Foff+$lo]
	str	$t3, [$ctx,#$Foff+$hi]

	ldr	$Alo,[sp,#$Goff+0]
	ldr	$Ahi,[sp,#$Goff+4]
	ldr	$Tlo,[sp,#$Hoff+0]
	ldr	$Thi,[sp,#$Hoff+4]
	ldr	$t0, [$ctx,#$Goff+$lo]
	ldr	$t1, [$ctx,#$Goff+$hi]
	ldr	$t2, [$ctx,#$Hoff+$lo]
	ldr	$t3, [$ctx,#$Hoff+$hi]
	adds	$t0,$Alo,$t0
	adc	$t1,$Ahi,$t1
	adds	$t2,$Tlo,$t2
	adc	$t3,$Thi,$t3
	str	$t0, [$ctx,#$Goff+$lo]
	str	$t1, [$ctx,#$Goff+$hi]
	str	$t2, [$ctx,#$Hoff+$lo]
	str	$t3, [$ctx,#$Hoff+$hi]

	add	sp,sp,#640
	sub	$Ktbl,$Ktbl,#640

	teq	$inp,$len
	bne	.Loop

	add	sp,sp,#8*9		@ destroy frame
	ldmia	sp!,{r4-r12,lr}
	tst	lr,#1
	moveq	pc,lr			@ be binary compatible with V4, yet
	bx	lr			@ interoperable with Thumb ISA:-)
.size   sha512_block_data_order,.-sha512_block_data_order
.asciz  "SHA512 block transform for ARMv4, CRYPTOGAMS by <appro\@openssl.org>"
___

$code =~ s/\`([^\`]*)\`/eval $1/gem;
$code =~ s/\bbx\s+lr\b/.word\t0xe12fff1e/gm;	# make it possible to compile with -march=armv4
print $code;
close STDOUT; # enforce flush
