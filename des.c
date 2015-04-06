/* Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@cryptsoft.com).
 * The implementation was written so as to conform with Netscapes SSL.
 *
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to. The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code. The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@cryptsoft.com).
 *
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgment:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@cryptsoft.com)"
 *    The word 'cryptographic' can be left out if the routines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from
 *    the apps directory (application code) you must include an acknowledgment:
 *    "This product includes software written by Tim Hudson(tjh@cryptsoft.com)"
 *
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * The license and distribution terms for any publically available version or
 * derivative of this code cannot be changed. i.e. this code cannot simply be
 * copied and put under another distribution license
 * [including the GNU Public License.]
 */

/*  Clean up and minor changes by L. Padilla (e-mail: padilla at domain "gae ucm es") 2003/05/02  */

#define DES_LONG  unsigned int
#define des_cblock  unsigned char
#define des_key_schedule  DES_LONG *

#define C2L(c,l)  (l  = ((DES_LONG) (* ((c)++)))    , \
                   l |= ((DES_LONG) (* ((c)++)))<< 8, \
                   l |= ((DES_LONG) (* ((c)++)))<<16, \
                   l |= ((DES_LONG) (* ((c)++)))<<24)

#define ROTATE(a,n)  (((a)>>(n)) + ((a)<<(32 - (n))))

#define LOAD_DATA(R,S,u,t,E0,E1,tmp)  u = R^s[S    ]; \
                                      t = R^s[S + 1]

#define LOAD_DATA_tmp(a,b,c,d,e,f)  LOAD_DATA(a, b, c, d, e, f, g)

/* The changes to this macro may help or hinder, depending on the
 * compiler and the architecture. gcc2 always seems to do well :-).
 * Inspired by Dana How <how@isl.stanford.edu>
 * DO NOT use the alternative version on machines with 8 byte longs.
 * It does not seem to work on the Alpha, even when DES_LONG is 4
 * bytes, probably an issue of accessing non-word aligned objects :-(  */

#ifdef DES_PTR

/* It recently occurred to me that 0^0^0^0^0^0^0 == 0, so there
 * is no reason to not xor all the sub items together. This potentially
 * saves a register since things can be xored directly into L            */

#if defined(DES_RISC1) || defined(DES_RISC2)

/* This helps C compiler generate the correct code for multiple functional
 * units. It reduces register dependencies at the expense of 2 more
 * registers                                                                */

#ifdef DES_RISC1

#define D_ENCRYPT(LL,R,S)                                         \
{                                                                 \
    unsigned int u1, u2, u3;                                      \
                                                                  \
    LOAD_DATA(R, S, u, t, E0, E1, u1);                            \
    u2 = (int) u>>8;                                              \
    u1 = (int) u & 0xFC;                                          \
    u2 &= 0xFC;                                                   \
    t = ROTATE(t, 4);                                             \
    u >>= 16;                                                     \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP         + u1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x200 + u2); \
    u3 = (int) (u>>8);                                            \
    u1 = (int) u & 0xFC;                                          \
    u3 &= 0xFC;                                                   \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x400 + u1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x600 + u3); \
    u2 = (int) t>>8;                                              \
    u1 = (int) t & 0xFC;                                          \
    u2 &= 0xFC;                                                   \
    t >>= 16;                                                     \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x100 + u1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x300 + u2); \
    u3 = (int) t>>8;                                              \
    u1 = (int) t & 0xFC;                                          \
    u3 &= 0xFC;                                                   \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x500 + u1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x700 + u3); \
}
#endif

#ifdef DES_RISC2

#define D_ENCRYPT(LL,R,S)                                         \
{                                                                 \
    unsigned int u1, u2, s1, s2;                                  \
                                                                  \
    LOAD_DATA(R, S, u, t, E0, E1, u1);                            \
    u2 = (int) u>>8;                                              \
    u1 = (int) u & 0xFC;                                          \
    u2 &= 0xFC;                                                   \
    t = ROTATE(t, 4);                                             \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP         + u1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x200 + u2); \
    s1 = (int) (u>>16);                                           \
    s2 = (int) (u>>24);                                           \
    s1 &= 0xFC;                                                   \
    s2 &= 0xFC;                                                   \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x400 + s1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x600 + s2); \
    u2 = (int) t>>8;                                              \
    u1 = (int) t & 0xFC;                                          \
    u2 &= 0xFC;                                                   \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x100 + u1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x300 + u2); \
    s1 = (int) (t>>16);                                           \
    s2 = (int) (t>>24);                                           \
    s1 &= 0xFC;                                                   \
    s2 &= 0xFC;                                                   \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x500 + s1); \
    LL ^= * (DES_LONG *) ((unsigned char *) des_SP + 0x700 + s2); \
 }
#endif

#else

#define D_ENCRYPT(LL,R,S)                                                     \
{                                                                             \
    LOAD_DATA_tmp(R, S, u, t, E0, E1);                                        \
    t = ROTATE(t, 4);                                                         \
    LL ^=                                                                     \
        * (DES_LONG *) ((unsigned char *) des_SP         + ((u    ) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x200 + ((u>> 8) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x400 + ((u>>16) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x600 + ((u>>24) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x100 + ((t    ) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x300 + ((t>> 8) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x500 + ((t>>16) & 0xFC))^ \
        * (DES_LONG *) ((unsigned char *) des_SP + 0x700 + ((t>>24) & 0xFC)); \
}
#endif

#else  /*  Original version  */

#if defined(DES_RISC1) || defined(DES_RISC2)

#ifdef DES_RISC1

#define D_ENCRYPT(LL,R,S)              \
{                                      \
    unsigned int u1, u2, u3;           \
                                       \
    LOAD_DATA(R, S, u, t, E0, E1, u1); \
    u >>= 2;                           \
    t = ROTATE(t, 6);                  \
    u2 = (int) u>>8;                   \
    u1 = (int) u & 0x3F;               \
    u2 &= 0x3F;                        \
    u >>= 16;                          \
    LL ^= des_SPtrans[0][u1];          \
    LL ^= des_SPtrans[2][u2];          \
    u3 = (int) u>>8;                   \
    u1 = (int) u &0x3F;                \
    u3 &= 0x3F;                        \
    LL ^= des_SPtrans[4][u1];          \
    LL ^= des_SPtrans[6][u3];          \
    u2 = (int) t>>8;                   \
    u1 = (int) t & 0x3F;               \
    u2 &= 0x3F;                        \
    t >>= 16;                          \
    LL ^= des_SPtrans[1][u1];          \
    LL ^= des_SPtrans[3][u2];          \
    u3 = (int) t>>8;                   \
    u1 = (int) t & 0x3F;               \
    u3 &= 0x3F;                        \
    LL ^= des_SPtrans[5][u1];          \
    LL ^= des_SPtrans[7][u3];          \
}
#endif

#ifdef DES_RISC2

#define D_ENCRYPT(LL,R,S)              \
{                                      \
    unsigned int u1, u2, s1, s2;       \
                                       \
    LOAD_DATA(R, S, u, t, E0, E1, u1); \
    u >>= 2;                           \
    t = ROTATE(t, 6);                  \
    u2 = (int) u>>8;                   \
    u1 = (int) u & 0x3F;               \
    u2 &= 0x3F;                        \
    LL ^= des_SPtrans[0][u1];          \
    LL ^= des_SPtrans[2][u2];          \
    s1 = (int) u>>16;                  \
    s2 = (int) u>>24;                  \
    s1 &= 0x3F;                        \
    s2 &= 0x3F;                        \
    LL ^= des_SPtrans[4][s1];          \
    LL ^= des_SPtrans[6][s2];          \
    u2 = (int) t>>8;                   \
    u1 = (int) t & 0x3F;               \
    u2 &= 0x3F;                        \
    LL ^= des_SPtrans[1][u1];          \
    LL ^= des_SPtrans[3][u2];          \
    s1 = (int) t>>16;                  \
    s2 = (int) t>>24;                  \
    s1 &= 0x3F;                        \
    s2 &= 0x3F;                        \
    LL ^= des_SPtrans[5][s1];          \
    LL ^= des_SPtrans[7][s2];          \
}
#endif

#else

#define D_ENCRYPT(LL,R,S)                 \
{                                         \
    LOAD_DATA_tmp(R, S, u, t, E0, E1);    \
    t = ROTATE(t, 4);                     \
    LL ^= des_SPtrans[0][(u>> 2) & 0x3F]^ \
          des_SPtrans[2][(u>>10) & 0x3F]^ \
          des_SPtrans[4][(u>>18) & 0x3F]^ \
          des_SPtrans[6][(u>>26) & 0x3F]^ \
          des_SPtrans[1][(t>> 2) & 0x3F]^ \
          des_SPtrans[3][(t>>10) & 0x3F]^ \
          des_SPtrans[5][(t>>18) & 0x3F]^ \
          des_SPtrans[7][(t>>26) & 0x3F]; \
}
#endif
#endif

        /* IP and FP
         * The problem is more of a geometric problem that random bit fiddling.
         0  1  2  3  4  5  6  7      62 54 46 38 30 22 14  6
         8  9 10 11 12 13 14 15      60 52 44 36 28 20 12  4
        16 17 18 19 20 21 22 23      58 50 42 34 26 18 10  2
        24 25 26 27 28 29 30 31  to  56 48 40 32 24 16  8  0
        32 33 34 35 36 37 38 39      63 55 47 39 31 23 15  7
        40 41 42 43 44 45 46 47      61 53 45 37 29 21 13  5
        48 49 50 51 52 53 54 55      59 51 43 35 27 19 11  3
        56 57 58 59 60 61 62 63      57 49 41 33 25 17  9  1

        The output has been subject to swaps of the form
        0 1 -> 3 1 but the odd and even bits have been put into
        2 3    2 0
        different words. The main trick is to remember that
        t=((l>>size)^r)&(mask);
        r^=t;
        l^=(t<<size);
        can be used to swap and move bits between words.

        So l =  0  1  2  3  r = 16 17 18 19
                4  5  6  7      20 21 22 23
                8  9 10 11      24 25 26 27
               12 13 14 15      28 29 30 31
        becomes (for size == 2 and mask == 0x3333)
           t =   2^16  3^17 -- --   l =  0  1 16 17  r =  2  3 18 19
                 6^20  7^21 -- --        4  5 20 21       6  7 22 23
                10^24 11^25 -- --        8  9 24 25      10 11 24 25
                14^28 15^29 -- --       12 13 28 29      14 15 28 29

        Thanks for hints from Richard Outerbridge - he told me IP&FP
        could be done in 15 xor, 10 shifts and 5 ands.
        When I finally started to think of the problem in 2D
        I first got ~42 operations without xors. When I remembered
        how to use xors :-) I got it to its final state.
                                                                    */

#define PERM_OP(a,b,t,n,m)  ((t) = ((((a)>>(n)) ^ (b)) & (m)), \
                             (b) ^= (t),                       \
                             (a) ^= ((t)<<(n)))

#define IP(l,r)                        \
{                                      \
    register DES_LONG tt;              \
                                       \
    PERM_OP(r, l, tt,  4, 0x0F0F0F0F); \
    PERM_OP(l, r, tt, 16, 0x0000FFFF); \
    PERM_OP(r, l, tt,  2, 0x33333333); \
    PERM_OP(l, r, tt,  8, 0x00FF00FF); \
    PERM_OP(r, l, tt,  1, 0x55555555); \
}

#define FP(l,r)                        \
{                                      \
    register DES_LONG tt;              \
                                       \
    PERM_OP(l, r, tt,  1, 0x55555555); \
    PERM_OP(r, l, tt,  8, 0x00FF00FF); \
    PERM_OP(l, r, tt,  2, 0x33333333); \
    PERM_OP(r, l, tt, 16, 0x0000FFFF); \
    PERM_OP(l, r, tt,  4, 0x0F0F0F0F); \
}


const DES_LONG des_SPtrans[8][64] =
{{
0x02080800, 0x00080000, 0x02000002, 0x02080802,
0x02000000, 0x00080802, 0x00080002, 0x02000002,
0x00080802, 0x02080800, 0x02080000, 0x00000802,
0x02000802, 0x02000000, 0x00000000, 0x00080002,
0x00080000, 0x00000002, 0x02000800, 0x00080800,
0x02080802, 0x02080000, 0x00000802, 0x02000800,
0x00000002, 0x00000800, 0x00080800, 0x02080002,
0x00000800, 0x02000802, 0x02080002, 0x00000000,
0x00000000, 0x02080802, 0x02000800, 0x00080002,
0x02080800, 0x00080000, 0x00000802, 0x02000800,
0x02080002, 0x00000800, 0x00080800, 0x02000002,
0x00080802, 0x00000002, 0x02000002, 0x02080000,
0x02080802, 0x00080800, 0x02080000, 0x02000802,
0x02000000, 0x00000802, 0x00080002, 0x00000000,
0x00080000, 0x02000000, 0x02000802, 0x02080800,
0x00000002, 0x02080002, 0x00000800, 0x00080802,
}, {
0x40108010, 0x00000000, 0x00108000, 0x40100000,
0x40000010, 0x00008010, 0x40008000, 0x00108000,
0x00008000, 0x40100010, 0x00000010, 0x40008000,
0x00100010, 0x40108000, 0x40100000, 0x00000010,
0x00100000, 0x40008010, 0x40100010, 0x00008000,
0x00108010, 0x40000000, 0x00000000, 0x00100010,
0x40008010, 0x00108010, 0x40108000, 0x40000010,
0x40000000, 0x00100000, 0x00008010, 0x40108010,
0x00100010, 0x40108000, 0x40008000, 0x00108010,
0x40108010, 0x00100010, 0x40000010, 0x00000000,
0x40000000, 0x00008010, 0x00100000, 0x40100010,
0x00008000, 0x40000000, 0x00108010, 0x40008010,
0x40108000, 0x00008000, 0x00000000, 0x40000010,
0x00000010, 0x40108010, 0x00108000, 0x40100000,
0x40100010, 0x00100000, 0x00008010, 0x40008000,
0x40008010, 0x00000010, 0x40100000, 0x00108000,
}, {
0x04000001, 0x04040100, 0x00000100, 0x04000101,
0x00040001, 0x04000000, 0x04000101, 0x00040100,
0x04000100, 0x00040000, 0x04040000, 0x00000001,
0x04040101, 0x00000101, 0x00000001, 0x04040001,
0x00000000, 0x00040001, 0x04040100, 0x00000100,
0x00000101, 0x04040101, 0x00040000, 0x04000001,
0x04040001, 0x04000100, 0x00040101, 0x04040000,
0x00040100, 0x00000000, 0x04000000, 0x00040101,
0x04040100, 0x00000100, 0x00000001, 0x00040000,
0x00000101, 0x00040001, 0x04040000, 0x04000101,
0x00000000, 0x04040100, 0x00040100, 0x04040001,
0x00040001, 0x04000000, 0x04040101, 0x00000001,
0x00040101, 0x04000001, 0x04000000, 0x04040101,
0x00040000, 0x04000100, 0x04000101, 0x00040100,
0x04000100, 0x00000000, 0x04040001, 0x00000101,
0x04000001, 0x00040101, 0x00000100, 0x04040000,
}, {
0x00401008, 0x10001000, 0x00000008, 0x10401008,
0x00000000, 0x10400000, 0x10001008, 0x00400008,
0x10401000, 0x10000008, 0x10000000, 0x00001008,
0x10000008, 0x00401008, 0x00400000, 0x10000000,
0x10400008, 0x00401000, 0x00001000, 0x00000008,
0x00401000, 0x10001008, 0x10400000, 0x00001000,
0x00001008, 0x00000000, 0x00400008, 0x10401000,
0x10001000, 0x10400008, 0x10401008, 0x00400000,
0x10400008, 0x00001008, 0x00400000, 0x10000008,
0x00401000, 0x10001000, 0x00000008, 0x10400000,
0x10001008, 0x00000000, 0x00001000, 0x00400008,
0x00000000, 0x10400008, 0x10401000, 0x00001000,
0x10000000, 0x10401008, 0x00401008, 0x00400000,
0x10401008, 0x00000008, 0x10001000, 0x00401008,
0x00400008, 0x00401000, 0x10400000, 0x10001008,
0x00001008, 0x10000000, 0x10000008, 0x10401000,
}, {
0x08000000, 0x00010000, 0x00000400, 0x08010420,
0x08010020, 0x08000400, 0x00010420, 0x08010000,
0x00010000, 0x00000020, 0x08000020, 0x00010400,
0x08000420, 0x08010020, 0x08010400, 0x00000000,
0x00010400, 0x08000000, 0x00010020, 0x00000420,
0x08000400, 0x00010420, 0x00000000, 0x08000020,
0x00000020, 0x08000420, 0x08010420, 0x00010020,
0x08010000, 0x00000400, 0x00000420, 0x08010400,
0x08010400, 0x08000420, 0x00010020, 0x08010000,
0x00010000, 0x00000020, 0x08000020, 0x08000400,
0x08000000, 0x00010400, 0x08010420, 0x00000000,
0x00010420, 0x08000000, 0x00000400, 0x00010020,
0x08000420, 0x00000400, 0x00000000, 0x08010420,
0x08010020, 0x08010400, 0x00000420, 0x00010000,
0x00010400, 0x08010020, 0x08000400, 0x00000420,
0x00000020, 0x00010420, 0x08010000, 0x08000020,
}, {
0x80000040, 0x00200040, 0x00000000, 0x80202000,
0x00200040, 0x00002000, 0x80002040, 0x00200000,
0x00002040, 0x80202040, 0x00202000, 0x80000000,
0x80002000, 0x80000040, 0x80200000, 0x00202040,
0x00200000, 0x80002040, 0x80200040, 0x00000000,
0x00002000, 0x00000040, 0x80202000, 0x80200040,
0x80202040, 0x80200000, 0x80000000, 0x00002040,
0x00000040, 0x00202000, 0x00202040, 0x80002000,
0x00002040, 0x80000000, 0x80002000, 0x00202040,
0x80202000, 0x00200040, 0x00000000, 0x80002000,
0x80000000, 0x00002000, 0x80200040, 0x00200000,
0x00200040, 0x80202040, 0x00202000, 0x00000040,
0x80202040, 0x00202000, 0x00200000, 0x80002040,
0x80000040, 0x80200000, 0x00202040, 0x00000000,
0x00002000, 0x80000040, 0x80002040, 0x80202000,
0x80200000, 0x00002040, 0x00000040, 0x80200040,
}, {
0x00004000, 0x00000200, 0x01000200, 0x01000004,
0x01004204, 0x00004004, 0x00004200, 0x00000000,
0x01000000, 0x01000204, 0x00000204, 0x01004000,
0x00000004, 0x01004200, 0x01004000, 0x00000204,
0x01000204, 0x00004000, 0x00004004, 0x01004204,
0x00000000, 0x01000200, 0x01000004, 0x00004200,
0x01004004, 0x00004204, 0x01004200, 0x00000004,
0x00004204, 0x01004004, 0x00000200, 0x01000000,
0x00004204, 0x01004000, 0x01004004, 0x00000204,
0x00004000, 0x00000200, 0x01000000, 0x01004004,
0x01000204, 0x00004204, 0x00004200, 0x00000000,
0x00000200, 0x01000004, 0x00000004, 0x01000200,
0x00000000, 0x01000204, 0x01000200, 0x00004200,
0x00000204, 0x00004000, 0x01004204, 0x01000000,
0x01004200, 0x00000004, 0x00004004, 0x01004204,
0x01000004, 0x01004200, 0x01004000, 0x00004004,
}, {
0x20800080, 0x20820000, 0x00020080, 0x00000000,
0x20020000, 0x00800080, 0x20800000, 0x20820080,
0x00000080, 0x20000000, 0x00820000, 0x00020080,
0x00820080, 0x20020080, 0x20000080, 0x20800000,
0x00020000, 0x00820080, 0x00800080, 0x20020000,
0x20820080, 0x20000080, 0x00000000, 0x00820000,
0x20000000, 0x00800000, 0x20020080, 0x20800080,
0x00800000, 0x00020000, 0x20820000, 0x00000080,
0x00800000, 0x00020000, 0x20000080, 0x20820080,
0x00020080, 0x20000000, 0x00000000, 0x00820000,
0x20800080, 0x20020080, 0x20020000, 0x00800080,
0x20820000, 0x00000080, 0x00800080, 0x20020000,
0x20820080, 0x00800000, 0x20800000, 0x20000080,
0x00820000, 0x00020080, 0x20020080, 0x20800000,
0x00000080, 0x20820000, 0x00820080, 0x00000000,
0x20000000, 0x20800080, 0x00020000, 0x00820080,
}};


void init_encrypt (des_cblock * tsp, DES_LONG * ptsp)
{
    C2L(tsp, ptsp[0]);
    C2L(tsp, ptsp[1]);

    IP(ptsp[0], ptsp[1]);

    ptsp[0] = ROTATE(ptsp[0], 29) & 0xFFFFFFFF;
    ptsp[1] = ROTATE(ptsp[1], 29) & 0xFFFFFFFF;


    return;
}


#ifndef ASM

void encrypt (DES_LONG * data, DES_LONG * output, des_key_schedule ks)
{
#ifdef DES_PTR

    register unsigned char * des_SP = (unsigned char *) des_SPtrans;

#endif

#ifndef DES_UNROLL

    register int i;

#endif

    register DES_LONG l, r, t, u, * s;


    s = (DES_LONG *) ks;

#ifdef __linux__

    if (s) /* Absurd, but helps gcc to optimize a lot, don't ask me why (LP) */

#endif
    {

    r = data[0];
    l = data[1];

/*  I don't know if it is worth the effort of loop unrolling the inner loop  */

#ifdef DES_UNROLL

    D_ENCRYPT(l, r,  0);
    D_ENCRYPT(r, l,  2);
    D_ENCRYPT(l, r,  4);
    D_ENCRYPT(r, l,  6);
    D_ENCRYPT(l, r,  8);
    D_ENCRYPT(r, l, 10);
    D_ENCRYPT(l, r, 12);
    D_ENCRYPT(r, l, 14);
    D_ENCRYPT(l, r, 16);
    D_ENCRYPT(r, l, 18);
    D_ENCRYPT(l, r, 20);
    D_ENCRYPT(r, l, 22);
    D_ENCRYPT(l, r, 24);
    D_ENCRYPT(r, l, 26);
    D_ENCRYPT(l, r, 28);
    D_ENCRYPT(r, l, 30);

#else

    for (i = 0; i < 32; i += 8)
    {
        D_ENCRYPT(l, r, i + 0);
        D_ENCRYPT(r, l, i + 2);
        D_ENCRYPT(l, r, i + 4);
        D_ENCRYPT(r, l, i + 6);
    }

#endif

    l = ROTATE(l, 3);
    r = ROTATE(r, 3);

    FP(r, l);

    output[0] = l;
    output[1] = r;

    }


    return;
}
#endif