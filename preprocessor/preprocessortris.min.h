#if!defined(V)&&!defined(k)&&!defined(u)&&!defined(Z)
#ifndef PARTS
#define PARTS __FILE__
#endif
#define J PARTS
#define E() 
#define r() E()[m
#define b() E()[38;5;60m
#define m() E()[38;5;244m
#define o() E()[1m
#define e() E()[K
#define t() E()[1;38;5;75m
#define W(x) x
#define M(p,r) (((p)<1?2459544840317436144:(p)<2?28710885717835878:(p)<3?158191617010958450:(p)<4?157911172859953206:(p)<5?86138146141765731:(p)<6?225747810440839281:153968392911585396)>>(r)*16&65535)
#define I(m,i) ((m)>>(i)&1)
#define p(e) ((e)<1?1:(e)<2?10:(e)<3?100:(e)<4?1000:(e)<5?10000:(e)<6?100000:(e)<7?1000000:(e)<8?10000000:(e)<9?100000000:1000000000)
#define g(d) (V()/Q%10==d)
#define w(k) ((k)==0?A0():(k)==1?A1():(k)==2?A2():(k)==3?A3():(k)==4?A4():(k)==5?A5():(k)==6?A6():(k)==7?A7():(k)==8?A8():(k)==9?A9():(k)==10?A10():(k)==11?A11():(k)==12?A12():(k)==13?A13():(k)==14?A14():(k)==15?A15():(k)==16?A16():(k)==17?A17():(k)==18?A18():A19())
#define d(r,x) ((r)/p(9-(x))%10)
#define c(y,x) ((y)<0||(y)>19||(x)<0||(x)>9?9:d(w(y),x))
#define s(m,i,x,y) (!I(m,i)||!c((y)+(i)/4,(x)+(i)%4))
#define f(m,x,y) (s(m,0,x,y)&&s(m,1,x,y)&&s(m,2,x,y)&&s(m,3,x,y)&&s(m,4,x,y)&&s(m,5,x,y)&&s(m,6,x,y)&&s(m,7,x,y)&&s(m,8,x,y)&&s(m,9,x,y)&&s(m,10,x,y)&&s(m,11,x,y)&&s(m,12,x,y)&&s(m,13,x,y)&&s(m,14,x,y)&&s(m,15,x,y))
#define n(m,x,y,a,b) ((a)>=(y)&&(a)<(y)+4&&(b)>=(x)&&(b)<(x)+4&&I(m,((a)-(y))*4+(b)-(x)))
#define l(m,x,y,a,i) n(m,x,y,a,i)*p(9-(i))
#define v(z,a,m,x,y,q) ((z)+(q)*(l(m,x,y,a,0)+l(m,x,y,a,1)+l(m,x,y,a,2)+l(m,x,y,a,3)+l(m,x,y,a,4)+l(m,x,y,a,5)+l(m,x,y,a,6)+l(m,x,y,a,7)+l(m,x,y,a,8)+l(m,x,y,a,9)))
#define x (X()-3)
#define Mc() M(C(),R())
#define O()
#define KP(k) @A/**/k A/**/k()
#define RW(F) F(0)F(1)F(2)F(3)F(4)F(5)F(6)F(7)F(8)F(9)F(10)F(11)F(12)F(13)F(14)F(15)F(16)F(17)F(18)F(19)
#define nC() C()
#define nN() N()
#define nX() X()
#define nY() Y()
#define nR() R()
#define nT() T()
#define nQ() 0
#define Rc 0
#define Bd 0
#define Ed 0
#define F0() 0
#define F1() 1
#define F2() 2
#define F3() 3
#define F4() 4
#define F5() 5
#define F6() 6
#define F7() 7
#define F8() 8
#define F9() 9
#ifdef START
#define V() ((START())*16807%2147483647)
#include J
@S D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()@N ((START())*16807%2147483647%7)@C 0@X 6@Y 0@R 0@T 0@P 0@L 0@G 1@PHASE 2
#define EM(k) @A/**/k 10000000000
RW(EM)
#else
#if PHASE()==0
#if EV==0&&T()+G()<10
#define nT() (T()+1)
#elif EV==0||EV==4
#if f(Mc(),x,Y()+1)
#define nY() (Y()+1)
#define Bd 1
#else
#define nQ() 1
#define Rc 1
#endif
#if EV==0
#define nT() 0
#endif
#elif EV==1||EV==2
#if f(Mc(),x+2*EV-3,Y())
#define nX() (X()+2*EV-3)
#endif
#define Bd 1
#elif EV==3
#define Rm() M(C(),(R()+1)%4)
#if f(Rm(),x+0,Y())
#define Kk 0
#elif f(Rm(),x-1,Y())
#define Kk -1
#elif f(Rm(),x+1,Y())
#define Kk 1
#elif f(Rm(),x-2,Y())
#define Kk -2
#elif f(Rm(),x+2,Y())
#define Kk 2
#endif
#ifdef Kk
#define nX() (X()+Kk)
#define nR() ((R()+1)%4)
#endif
#define Bd 1
#elif EV==5
#define H(n) !f(Mc(),x,Y()+n)
#if H(1)
#define nY() Y()
#elif H(2)
#define nY() (Y()+1)
#elif H(3)
#define nY() (Y()+2)
#elif H(4)
#define nY() (Y()+3)
#elif H(5)
#define nY() (Y()+4)
#elif H(6)
#define nY() (Y()+5)
#elif H(7)
#define nY() (Y()+6)
#elif H(8)
#define nY() (Y()+7)
#elif H(9)
#define nY() (Y()+8)
#elif H(10)
#define nY() (Y()+9)
#elif H(11)
#define nY() (Y()+10)
#elif H(12)
#define nY() (Y()+11)
#elif H(13)
#define nY() (Y()+12)
#elif H(14)
#define nY() (Y()+13)
#elif H(15)
#define nY() (Y()+14)
#elif H(16)
#define nY() (Y()+15)
#elif H(17)
#define nY() (Y()+16)
#elif H(18)
#define nY() (Y()+17)
#elif H(19)
#define nY() (Y()+18)
#else
#define nY() (Y()+19)
#endif
#define nQ() 1
#define Rc 1
#endif
#define Z() Mc()
#include J
#define Lm U
#define NW(k) v(w(k),k,Lm,x,nY(),C()+1)
#define CH(k) ((k)>=nY()&&(k)<=nY()+3)
#elif PHASE()==1
#define FR(r) (d(r,0)&&d(r,1)&&d(r,2)&&d(r,3)&&d(r,4)&&d(r,5)&&d(r,6)&&d(r,7)&&d(r,8)&&d(r,9))
#if Y()+0<20&&FR(w(Y()+0))
#define f0 1
#else
#define f0 0
#endif
#if Y()+1<20&&FR(w(Y()+1))
#define f1 1
#else
#define f1 0
#endif
#if Y()+2<20&&FR(w(Y()+2))
#define f2 1
#else
#define f2 0
#endif
#if Y()+3<20&&FR(w(Y()+3))
#define f3 1
#else
#define f3 0
#endif
#define FU(k) ((k)==Y()?f0:(k)==Y()+1?f1:(k)==Y()+2?f2:(k)==Y()+3?f3:0)
#define BL(s) (((s)<Y())*f0+((s)<Y()+1)*f1+((s)<Y()+2)*f2+((s)<Y()+3)*f3)
#define FM(j,m) ((j)-(m)>=0&&!FU((j)-(m))&&BL((j)-(m))==(m))
#define NW(j) (FM(j,0)?w(j):FM(j,1)?w((j)-1):FM(j,2)?w((j)-2):FM(j,3)?w((j)-3):FM(j,4)?w((j)-4):10000000000)
#define CL (f0+f1+f2+f3)
#define CH(k) ((k)<=Y()+3)
#define nQ() 2
#if CL
#define Rc 1
#endif
#else
#define nC() N()
#define nN() (S()*16807%2147483647%7)
#define nX() 6
#define nY() 0
#define nR() 0
#define nT() 0
#define Bd 1
#if!f(M(N(),0),3,0)
#define Ed 1
#endif
#endif
#if Bd
#define Z() M(nC(),nR())
#include J
#define Sm U
#define NB(b,i) I(M(nN(),0),(b)*4+(i))
#define F0() E()[38;5;237m ·r()
#define F1() E()[38;5;51m██r()
#define F2() E()[38;5;226m██r()
#define F3() E()[38;5;135m██r()
#define F4() E()[38;5;46m██r()
#define F5() E()[38;5;196m██r()
#define F6() E()[38;5;33m██r()
#define F7() E()[38;5;208m██r()
#if nN()==0
#define Nb() F1()
#elif nN()==1
#define Nb() F2()
#elif nN()==2
#define Nb() F3()
#elif nN()==3
#define Nb() F4()
#elif nN()==4
#define Nb() F5()
#elif nN()==5
#define Nb() F6()
#else
#define Nb() F7()
#endif
E()[H  t()W(P R E P R O C E S S O R T R I S)r()e()
 b()╔════════════════════╗r()e()
#define j 1
#define u
#include J
#undef u
 b()╚════════════════════╝r()e()
#endif
#if!Ed
#define F0() 0
#define F1() 1
#define F2() 2
#define F3() 3
#define F4() 4
#define F5() 5
#define F6() 6
#define F7() 7
#define F8() 8
#define F9() 9
@C nC()@N nN()@X nX()@Y nY()@R nR()@T nT()@PHASE nQ()
#if PHASE()==2
#define V() (S()*16807%2147483647)
#include J
@S D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#else
@S S()
#endif
#if PHASE()==1&&CL
#define V() (P()+(CL==1?40:CL==2?100:CL==3?300:1200)*G())
#include J
@P D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#define V() (L()+CL)
#include J
@L D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#define V() ((L()+CL)/10+1)
#include J
@G D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#else
@P P()@L L()@G G()
#endif
#if Rc
#define j 2
#define u
#include J
#undef u
#else
RW(KP)
#endif
#endif
#endif
#else
/*{*/
#ifdef Z
#if Z()==54
#define U 54
#elif Z()==99
#define U 99
#elif Z()==102
#define U 102
#elif Z()==113
#define U 113
#elif Z()==114
#define U 114
#elif Z()==116
#define U 116
#elif Z()==240
#define U 240
#elif Z()==306
#define U 306
#elif Z()==368
#define U 368
#elif Z()==547
#define U 547
#elif Z()==550
#define U 550
#elif Z()==561
#define U 561
#elif Z()==562
#define U 562
#elif Z()==610
#define U 610
#elif Z()==612
#define U 612
#elif Z()==624
#define U 624
#elif Z()==802
#define U 802
#elif Z()==864
#define U 864
#elif Z()==1122
#define U 1122
#elif Z()==1136
#define U 1136
#elif Z()==1570
#define U 1570
#elif Z()==1584
#define U 1584
#elif Z()==3840
#define U 3840
#elif Z()==8738
#define U 8738
#elif Z()==17476
#define U 17476
#endif
#undef Z
#elif defined(V)
#define Q 1000000000
#if V()<Q
#define D9 O
#elif g(0)
#define D9 F0
#elif g(1)
#define D9 F1
#elif g(2)
#define D9 F2
#elif g(3)
#define D9 F3
#elif g(4)
#define D9 F4
#elif g(5)
#define D9 F5
#elif g(6)
#define D9 F6
#elif g(7)
#define D9 F7
#elif g(8)
#define D9 F8
#else
#define D9 F9
#endif
#define Q 100000000
#if V()<Q
#define D8 O
#elif g(0)
#define D8 F0
#elif g(1)
#define D8 F1
#elif g(2)
#define D8 F2
#elif g(3)
#define D8 F3
#elif g(4)
#define D8 F4
#elif g(5)
#define D8 F5
#elif g(6)
#define D8 F6
#elif g(7)
#define D8 F7
#elif g(8)
#define D8 F8
#else
#define D8 F9
#endif
#define Q 10000000
#if V()<Q
#define D7 O
#elif g(0)
#define D7 F0
#elif g(1)
#define D7 F1
#elif g(2)
#define D7 F2
#elif g(3)
#define D7 F3
#elif g(4)
#define D7 F4
#elif g(5)
#define D7 F5
#elif g(6)
#define D7 F6
#elif g(7)
#define D7 F7
#elif g(8)
#define D7 F8
#else
#define D7 F9
#endif
#define Q 1000000
#if V()<Q
#define D6 O
#elif g(0)
#define D6 F0
#elif g(1)
#define D6 F1
#elif g(2)
#define D6 F2
#elif g(3)
#define D6 F3
#elif g(4)
#define D6 F4
#elif g(5)
#define D6 F5
#elif g(6)
#define D6 F6
#elif g(7)
#define D6 F7
#elif g(8)
#define D6 F8
#else
#define D6 F9
#endif
#define Q 100000
#if V()<Q
#define D5 O
#elif g(0)
#define D5 F0
#elif g(1)
#define D5 F1
#elif g(2)
#define D5 F2
#elif g(3)
#define D5 F3
#elif g(4)
#define D5 F4
#elif g(5)
#define D5 F5
#elif g(6)
#define D5 F6
#elif g(7)
#define D5 F7
#elif g(8)
#define D5 F8
#else
#define D5 F9
#endif
#define Q 10000
#if V()<Q
#define D4 O
#elif g(0)
#define D4 F0
#elif g(1)
#define D4 F1
#elif g(2)
#define D4 F2
#elif g(3)
#define D4 F3
#elif g(4)
#define D4 F4
#elif g(5)
#define D4 F5
#elif g(6)
#define D4 F6
#elif g(7)
#define D4 F7
#elif g(8)
#define D4 F8
#else
#define D4 F9
#endif
#define Q 1000
#if V()<Q
#define D3 O
#elif g(0)
#define D3 F0
#elif g(1)
#define D3 F1
#elif g(2)
#define D3 F2
#elif g(3)
#define D3 F3
#elif g(4)
#define D3 F4
#elif g(5)
#define D3 F5
#elif g(6)
#define D3 F6
#elif g(7)
#define D3 F7
#elif g(8)
#define D3 F8
#else
#define D3 F9
#endif
#define Q 100
#if V()<Q
#define D2 O
#elif g(0)
#define D2 F0
#elif g(1)
#define D2 F1
#elif g(2)
#define D2 F2
#elif g(3)
#define D2 F3
#elif g(4)
#define D2 F4
#elif g(5)
#define D2 F5
#elif g(6)
#define D2 F6
#elif g(7)
#define D2 F7
#elif g(8)
#define D2 F8
#else
#define D2 F9
#endif
#define Q 10
#if V()<Q
#define D1 O
#elif g(0)
#define D1 F0
#elif g(1)
#define D1 F1
#elif g(2)
#define D1 F2
#elif g(3)
#define D1 F3
#elif g(4)
#define D1 F4
#elif g(5)
#define D1 F5
#elif g(6)
#define D1 F6
#elif g(7)
#define D1 F7
#elif g(8)
#define D1 F8
#else
#define D1 F9
#endif
#define Q 1
#if g(0)
#define D0 F0
#elif g(1)
#define D0 F1
#elif g(2)
#define D0 F2
#elif g(3)
#define D0 F3
#elif g(4)
#define D0 F4
#elif g(5)
#define D0 F5
#elif g(6)
#define D0 F6
#elif g(7)
#define D0 F7
#elif g(8)
#define D0 F8
#else
#define D0 F9
#endif
#undef V
#elif defined(k)
#if j==1
#if!Ed&&k>=nY()&&k<nY()+4
#define V() v(h(),k,Sm,nX()-3,nY(),nC()+1)
#else
#define V() h()
#endif
#include J
#if k==0
#define Pn() W()   b()╭──r() m()W(next)r() b()──────╮r()
#elif k==1||k==6
#define Pn() W()   b()│r()              b()│r()
#elif k==7
#define Pn() W()   b()╰──────────────╯r()
#elif k==9
#define Pn() W()   m()W(score)r()
#elif k==10
#define Pn() W()   o()P()r()
#elif k==11
#define Pn() W()   m()W(level)r() o()G()r()  m()W(lines)r() o()L()r()
#elif k==13
#define Pn() W()   m()W(controls)r()
#elif k==14
#define Pn() W()   o()W(← a)r()  m()W(move left)r()
#elif k==15
#define Pn() W()   o()W(→ d)r()  m()W(move right)r()
#elif k==16
#define Pn() W()   o()W(↑ w)r()  m()W(rotate)r()
#elif k==17
#define Pn() W()   o()W(↓ s)r()  m()W(soft drop)r()
#elif k==18
#define Pn() W()   o()W(␣ z)r()  m()W(hard drop)r()
#elif k==19
#define Pn() W()   o()W(  q)r()  m()W(quit)r()
#elif k>1&&k<6
#define Pn() W()   b()│r()   Q0()Q1()Q2()Q3()   b()│r()
#if NB(k-2,0)
#define Q0() Nb()
#else
#define Q0() W(  )
#endif
#if NB(k-2,1)
#define Q1() Nb()
#else
#define Q1() W(  )
#endif
#if NB(k-2,2)
#define Q2() Nb()
#else
#define Q2() W(  )
#endif
#if NB(k-2,3)
#define Q3() Nb()
#else
#define Q3() W(  )
#endif
#else
#define Pn()
#endif
#if Ed&&k==9
 b()║r()E()[1;7m     GAME  OVER     r()b()║r()Pn()e()
#else
 b()║r()D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()b()║r()Pn()e()
#endif
#elif CH(k)
#define V() NW(k)
#include J
@h W(1)D9()D8()D7()D6()D5()D4()D3()D2()D1()D0()
#else
@h h()
#endif
#undef k
#undef h
#else
#define k 0
#define h A0
#include J
#define k 1
#define h A1
#include J
#define k 2
#define h A2
#include J
#define k 3
#define h A3
#include J
#define k 4
#define h A4
#include J
#define k 5
#define h A5
#include J
#define k 6
#define h A6
#include J
#define k 7
#define h A7
#include J
#define k 8
#define h A8
#include J
#define k 9
#define h A9
#include J
#define k 10
#define h A10
#include J
#define k 11
#define h A11
#include J
#define k 12
#define h A12
#include J
#define k 13
#define h A13
#include J
#define k 14
#define h A14
#include J
#define k 15
#define h A15
#include J
#define k 16
#define h A16
#include J
#define k 17
#define h A17
#include J
#define k 18
#define h A18
#include J
#define k 19
#define h A19
#include J
#endif
/*}*/
#endif
