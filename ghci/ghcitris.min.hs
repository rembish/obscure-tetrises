{-# LANGUAGE DataKinds,TypeFamilies,UndecidableInstances,TypeOperators,NoStarIsType #-}
module G where
import GHC.TypeLits
data M=Q|W|Ended
data Game=K Nat Nat Nat Nat Nat Nat Nat Nat Nat Nat M
type R b y=Mod(Div b(8^(10*y)))(8^10)
type Ms p r=Mod(Div 6066663571551187584208939960950951792284689729191195176214656840774641292497116137753767622443593734046163567127777203936475943796976(2^(16*(4*p+r))))65536
type Cs p r=C(Ms p r)0
type Rd s=Mod(s*16807)2147483647
type family H r n where{H r 0='False;H r n=H1(Mod r 8)(Div r 8)(n-1)}
type family H1 d r n where{H1 0 r n='True;H1 d r n=H r n}
type family C m i where{C 0 i='[];C m i=C1(Mod m 2)m i}
type family C1 d m i where{C1 1 m i='(Mod i 4,Div i 4):C(Div m 2)(i+1);C1 d m i=C(Div m 2)(i+1)}
type family F b c x y where{F b '[] x y='True;F b('(u,v):c)x y=F1(E(4<=?x+u)(x+u<=?13)(y+v<=?19)b(x+u)(y+v))b c x y}
type family F1 o b c x y where{F1 'False b c x y='False;F1 o b c x y=F b c x y}
type family E a c d b u v where{E 'True 'True 'True b u v=Z(Mod(Div b(8^(v*10+u-4)))8);E a c d b u v='False}
type family Z n where{Z 0='True;Z n='False}
type family T g x y r where T('K s p n a e o t c l b m)x y r=T1(F b(Cs p r)x y)('K s p n x y r t c l b 'W)
type family T1 f g where{T1 'True g='Just g;T1 f g='Nothing}
type family O j g where{O('Just g)d=g;O j d=d}
type family V g where V('K s p n x y r t c l b m)='K s p n x y r t c l b 'W
type family Step g e where{Step('K s p n x y r t c l b m)0=Tk(10<=?t+1+Div l 10)('K s p n x y r(t+1)c l b 'Q);Step g 1=Mv g 0;Step g 2=Mv g 2;Step('K s p n x y r t c l b m)3=Kk('K s p n x y r t c l b m)(Mod(r+1)4)'[2,1,3,0,4];Step g 4=Dn 'False g;Step g 5=Dn 'True g;Step('K s p n x y r t c l b m)e='K s p n x y r t c l b 'Q}
type family Mv g d where Mv('K s p n x y r t c l b m)d=O(T('K s p n x y r t c l b m)(x+d-1)y r)('K s p n x y r t c l b 'W)
type family Tk f g where{Tk 'True('K s p n x y r t c l b m)=Dn 'False('K s p n x y r 0 c l b m);Tk f g=g}
type family Kk g r k where{Kk g r '[]=V g;Kk('K s p n x y o t c l b m)r(k:q)=Kk1(T('K s p n x y o t c l b m)(x+k-2)y r)('K s p n x y o t c l b m)r q}
type family Kk1 j g r k where{Kk1('Just h)g r k=h;Kk1 j g r k=Kk g r k}
type family Dn h g where Dn h('K s p n x y r t c l b m)=Dn1(T('K s p n x y r t c l b m)x(y+1)r)h('K s p n x y r t c l b m)
type family Dn1 j h g where{Dn1('Just g)'True d=Dn 'True g;Dn1('Just g)h d=g;Dn1 j h('K s p n x y r t c l b m)=Cl s n c l(X(St b(Cs p r)x y(p+1))19 19 0 20)}
type family St b c x y v where{St b '[] x y v=b;St b('(u,w):c)x y v=St(b+v*8^((y+w)*10+x+u-4))c x y v}
type family X b f o k n where X b f o k n=X1(H(R b f)10)b f o k n
type family X1 s b f o k n where{X1 'True b 0 o k n='(k+R b 0*8^(10*o),n-1);X1 s b 0 o k n='(k,n);X1 'True b f o k n=X b(f-1)(o-1)(k+R b f*8^(10*o))(n-1);X1 s b f o k n=X b(f-1)o k n}
type family Cl s n c l bk where Cl s n c l '(b,k)=Sp s n(c+Mod(Div 12000300010000400000(10000^k))10000*(Div l 10+1))(l+k)b
type family Sp s p c l b where Sp s p c l b=Sp1(F b(Cs p 0)7 0)('K(Rd s)p(Mod(Rd s)7)7 0 0 0 c l b 'W)
type family Sp1 f g where{Sp1 'True g=g;Sp1 f('K s p n x y r t c l b m)='K s p n x y r t c l b 'Ended}
type Start s=Sp(Rd s)(Mod(Rd s)7)0 0 0
type family J s where{J '[]="";J(a:s)=AppendSymbol a(J s)}
type family N n where N n=N1(n<=?9)n
type family N1 f n where{N1 'True n=ConsSymbol(NatToChar(48+n))"";N1 f n=AppendSymbol(N(Div n 10))(N1 'True(Mod n 10))}
type family Ce v where{Ce 0="\ESC[38;5;237m ·\ESC[m";Ce 1="\ESC[38;5;51m██\ESC[m";Ce 2="\ESC[38;5;226m██\ESC[m";Ce 3="\ESC[38;5;135m██\ESC[m";Ce 4="\ESC[38;5;46m██\ESC[m";Ce 5="\ESC[38;5;196m██\ESC[m";Ce 6="\ESC[38;5;33m██\ESC[m";Ce 7="\ESC[38;5;208m██\ESC[m"}
type family Rc r n where{Rc r 0="";Rc r n=AppendSymbol(Ce(Mod r 8))(Rc(Div r 8)(n-1))}
type family Pv m v n where{Pv m v 0="";Pv m v n=AppendSymbol(Pc(Mod m 2)v)(Pv(Div m 2)v(n-1))}
type family Pc d v where{Pc 1 v=Ce v;Pc d v="  "}
type B s=J '["\ESC[38;5;60m",s,"\ESC[m"]
type D s=J '["\ESC[38;5;244m",s,"\ESC[m"]
type Y s=J '["   ",B "│",s,B "│"]
type P n r=Y(J '["   ",Pv(Div(Ms n 0)(16^r))(n+1)4,"   "])
type U k w=J '["   \ESC[1m",k,"\ESC[m  ",D w]
type family Pn i n c l where{Pn 0 n c l=J '["   ",B "╭──"," ",D "next"," ",B "──────╮"];Pn 2 n c l=P n 0;Pn 3 n c l=P n 1;Pn 7 n c l=J '["   ",B "╰──────────────╯"];Pn 8 n c l="";Pn 9 n c l=J '["   ",D "score"];Pn 10 n c l=J '["   \ESC[1m",N c,"\ESC[m"];Pn 11 n c l=J '["   ",D "level"," \ESC[1m",N(Div l 10+1),"\ESC[m  ",D "lines"," \ESC[1m",N l,"\ESC[m"];Pn 12 n c l="";Pn 13 n c l=J '["   ",D "controls"];Pn 14 n c l=U "← a" "move left";Pn 15 n c l=U "→ d" "move right";Pn 16 n c l=U "↑ w" "rotate";Pn 17 n c l=U "↓ s" "soft drop";Pn 18 n c l=U "␣ z" "hard drop";Pn 19 n c l=U "  q" "quit";Pn i n c l=Y "              "}
type family Frame g where{Frame('K s p n x y r t c l b 'Q)="";Frame('K s p n x y r t c l b 'W)=Pi(St b(Cs p r)x y(p+1))'False n c l;Frame('K s p n x y r t c l b m)=Pi b 'True n c l}
type Pi b o n c l=J("\ESC[H  \ESC[1;38;5;75mG H C I T R I S\ESC[m\ESC[K\n":" \ESC[38;5;60m╔════════════════════╗\ESC[m\ESC[K\n":Rw b 0 o n c l)
type family Rw b i o n c l where{Rw b 20 o n c l='[" \ESC[38;5;60m╚════════════════════╝\ESC[m\ESC[K\n"];Rw b i o n c l=J '[" \ESC[38;5;60m║\ESC[m",Bd b i o,"\ESC[38;5;60m║\ESC[m",Pn i n c l,"\ESC[K\n"]:Rw b(i+1)o n c l}
type family Bd b i o where{Bd b 9 'True="\ESC[1;7m     GAME  OVER     \ESC[m";Bd b i o=Rc(R b i)10}
