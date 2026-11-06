#define T template<L
#define TC template<class
#define C class
#define V struct
#define G enum
#define K static constexpr
#define U using
#define Y typename
#define L long
#define S(x)decltype(x""_)
#define R(s)s*16807%2147483647
#define B(x)"[38;5;60m" x"[m"
#define D_(x)"[38;5;244m" x"[m"
#define A(i)(unsigned(i-y)<4?(m>>12*(i-y)&4095)*(p+1)<<3*x>>12:0)
#define Bt(j)|B::w[b+j]&(u>>12*j&4095)<<3*a
#define Ky(k,a)S(_3"[1m" k"[m  "D_(a))
#define Fd Fi<B,p,r,x,y+1>::v
#define Cq(c)S("[38;5;" c"m██[m")
#define Q4(x)x x x x
#define Q5(x)Q4(x)x
#define _3"   "
#define V_(e,...)T z>V E<e,z>:__VA_ARGS__{G{d=1};};
#include<unistd.h>
T...>V I{};T n>U X=I<__integer_pack(n)...>;T b,C P,C Q>V F{U t=P;};TC P,C Q>V F<0,P,Q>{U t=Q;};template<char...c>V Z{char s[sizeof...(c)]={c...};};TC H,H...c>Z<c...>operator""_();T,C P>V N{P s;};TC,C...>V J;T...i,C...P>V J<I<i...>,P...>:N<i,P>...{};TC...P>U W=J<X<sizeof...(P)>,P...>;T v>V D:W<Y F<(v>9),D<v/10>,Z<>>::t,Z<48+v%10>>{};T...v>U Cm=W<W<Z<44>,D<v>>...>;constexpr L M[]={240,17476,3840,8738,102,102,102,102,114,610,624,562,54,1122,864,561,99,612,1584,306,113,550,1136,802,116,1570,368,547},P[]={0,40,100,300,1200};T m,C=X<16>>V H;T m,L...i>V H<m,I<i...>>{G:L{v=(0|...|((m>>i&1)<<3*i))};};U Rs=S("[m");T i,C P>P g(N<i,P>);U Cz=W<S("[38;5;237m ·[m"),Cq("51"),Cq("226"),Cq("135"),Cq("46"),Cq("196"),Cq("33"),Cq("208"),S("  ")>;T v,L e=0,C=X<10>>V Cs;T v,L e,L...j>V Cs<v,e,I<j...>>:W<decltype(g<(v>>3*j&7?:e)>(Cz{}))...>{};T e,L...j>V Cs<-1,e,I<j...>>:S("[1;7m     GAME  OVER     [m"){};T q,L b>U Nx=W<S(_3 B("│")_3),Cs<(H<M[q*4]>::v>>12*b&4095)*(q+1),8,X<4>>,S(_3 B("│"))>;U Bx=S(_3 B("│")"              "B("│"));T q,L c,L l>U Pt=W<S(_3 B("╭──")" "D_("next")" "B(Q5("─")"─╮")),Bx,Nx<q,0>,Nx<q,1>,Nx<q,2>,Nx<q,3>,Bx,S(_3 B("╰"Q5("─")Q5("─")Q4("─")"╯")),Z<>,S(_3 D_("score")),W<S(_3"[1m"),D<c>,Rs>,W<S(_3 D_("level")" [1m"),D<l/10+1>,S("[m  "D_("lines")" [1m"),D<l>,Rs>,Z<>,S(_3 D_("controls")),Ky("← a","move left"),Ky("→ d","move right"),Ky("↑ w","rotate"),Ky("↓ s","soft drop"),Ky("␣ z","hard drop"),Ky("  q","quit")>;T v,C P>V Ln:W<S(" "B("║")),Cs<v>,S(B("║")),P,S("[K\n")>{};T n,L...j>V O{G{N=n};K L w[]={(j|j>>1|j>>2|~0x9249249l)*4096|4095 ...,-1,-1,-1,-1};};TC B,L p,L h,L a,L b,L u=H<M[p*4+h]>::v>V Fi{G{v=!(0 Bt(0)Bt(1)Bt(2)Bt(3))};};TC B,L x,L y,L r,L k,L s,L c,L l,L p,L q,L o=0>V Q{U t=Q;G{Ov=o};G:L{m=H<M[p*4+r]>::v};TC,L...>V Cl;TC b>V Cl<b>{U t=Q<b,7,0,0,0,R(s),c+P[b::N]*(l/10+1),l+b::N,q,R(s)%7,!Fi<b,q,0,7,0>::v>;};T n,L...j,L h,L...v>V Cl<O<n,j...>,h,v...>:F<!(~(h|h>>1|h>>2)&0x9249249),Cl<O<n+1,0,j...>,v...>,Cl<O<n,j...,h>,v...>>::t{};T a,L b,L h,L u=k>U Mv=Q<B,a,b,h,u,s,c,l,p,q>;TC=B,C=Pt<q,c,l>>V Ix;T n,L...j,L...i,C...P>V Ix<O<n,j...>,J<I<i...>,P...>>{V Lk:Cl<O<0>,(j|A(i))...>{};V Fr:W<S("[H  [1;38;5;75mC P P T R I S[m[K\n "B("╔"Q4(Q5("═"))"╗")"[K\n"),Ln<o?i-9?j:-1:j|A(i),P>...,S(" "B("╚"Q4(Q5("═"))"╝")"[K\n")>{};V Sv:W<S("using S0=Q<O<"),D<n>,Cm<j...>,S(">"),Cm<x,y,r,k,s,c,l,p,q>,S(">;\n")>{};};T u>V Dn:F<Fd,Mv<x,y+1,r,u>,Y Ix<>::Lk>::t{};V Dr:F<Fd,Y Mv<x,y+1,r>::Dr,Y Ix<>::Lk>::t{};T h,L...>V Tr:Q{};T h,L a,L...z>V Tr<h,a,z...>:F<Fi<B,p,h,x+a,y>::v,Mv<x+a,y,h>,Tr<h,z...>>::t{};T e,L z=(k+l/10>8)>V E:Q{G{d=0};};T z>V E<0,z>:F<z,Dn<0>,Mv<x,y,r,k+1>>::t{G{d=z};};V_(1,Tr<r,-1>)V_(2,Tr<r,1>)V_(3,Tr<r+1&3,0,-1,1,-2,2>)V_(4,Dn<k>)V_(5,Dr)};T z,L a=R(z),L b=R(a)>U Init=Q<O<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>,7,0,0,0,b,0,0,a%7,b%7>;TC S,L,C>V Nd{U Lt=S;};TC,C...>V Fl;TC...P>V Fl<void,P...>{U t=W<Z<>,P...>;};TC a,L d,C R,C...P>V Fl<Nd<a,d,R>,P...>:Fl<R,Y F<d,Y a::template Ix<>::Fr,Z<>>::t,P...>{};TC P,L e,C S=Y P::Lt,C N=Y S::template E<S::Ov?9:e>>Nd<Y N::t,N::d,P>operator<<(P,I<e>);TC S,L f,L...e>U Batch=decltype((Nd<S,f,void>{}<<...<<I<e>{}));
#include "state.hpp"
#include "events.hpp"
int main(){K Fl<Game>::t o{};K Game::Lt::Ix<>::Sv v{};write(1,&o,sizeof o);write(3,&v,sizeof v);return Game::Lt::Ov;}
