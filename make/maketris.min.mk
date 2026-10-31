U:=[
F:=$() 
O:=$F$F$F
define N


endef
p:=x x x x x x x x
e:=$(foreach a,$p $p,$p)
u=$(wordlist 1,$1,$e)
r=$(wordlist 2,999,$1)
B:=1 2 3 4 5 6 7 8 9 10
L:=$B 11 12 13 14 15 16 17 18 19 20
g0:=$(B:%=0)
Ct:=$(foreach i,$B,x xx xxxx) x
h=$(eval a:=$1)$(foreach d,0 $B,$(eval a:=$(subst $d,$d ,$a)))$a
w=$(if $1,$(call w,$(call r,$1)) $(firstword $1))
g=$(call u,$(firstword $1 0)) $(call u,$(firstword $2 0)) $3
Be=$(if $(strip $1$2$3),$(words $(subst $(call u,10),,$(strip $g))) $(call Be,$(call r,$1),$(call r,$2),$(if $(word 10,$g),x)))
y=$(filter 1,$(firstword $1) $(firstword $2) $3)
j=$(if $(strip $1$2$3),$(word $(words x $y),0 1 0 1) $(call j,$(call r,$1),$(call r,$2),$(word 2,$y)))
z=$(call j,$(wordlist 1,31,$1),$(wordlist 32,999,$1))
I:=1.2 2.2 3.2 4.2 2.1 3.1 2.2 3.2 2.1 1.2 2.2 3.2 2.1 3.1 1.2 2.2 1.1 2.1 2.2 3.2 1.1 1.2 2.2 3.2 3.1 1.2 2.2 3.2
$(foreach p,1 2 3 4 5 6 7,$(eval q:=$(wordlist 1,4,$I)$NI:=$(wordlist 5,99,$I))$(foreach r,1 2 3 4,$(eval D$p$r:=$q)$(if $(filter 2,$p),,$(eval q:=$(foreach c,$q,$(word $(subst .,,$(suffix $c)),$(if $(filter 1,$p),4) 3 2 1).$(basename $c))))))
Bc=$(words $1 $(call u,$(basename $2)))
Bb=$(words $1 $(call u,$(subst .,,$(suffix $2))))
o=$(word 4,$(foreach c,$(D$P$3),$(filter 0,$(word $(call Bc,$1,$c),1 1 1 1 1 $(g$(call Bb,$2,$c))))))
Cs=$(eval g$2:=$(wordlist 6,15,$(foreach v,$L,$(if $(filter $v,$1),$3,$(word $v,1 1 1 1 1 $(g$2))))))
m=$(foreach c,$(D$P$R),$(call Cs,$(call Bc,$Q,$c),$(call Bb,$W,$c),$1))
k=$(eval a:=$A)$(foreach s,1 2 5 7 8 14,$(eval a:=$(call j,$a,$(call u,$s) $A)))$(eval A:=$(wordlist 1,31,$(call z,$(call z,$a)) $e))$(eval t:=$(words x $(subst x,x ,$(subst xxxxxxx,,$(subst $F1,,$F$(filter 1%,$(join $A,$(Ct))))))))
n=$(eval P:=$t)$k$(eval Q:=$p$NW:=$NR:=1$NT:=$NH:=$(if $(call o,$p,,1),,1))
l=$(call m,$P)$(eval K:=$(foreach r,$L,$(if $(filter 0,$(g$r)),$r)))$(eval f:=$(wordlist $(words x $K),20,$e))$(foreach i,$(call w,$L),$(eval g$i:=$(g$(word $i,$(f:x=0) $K))))$(if $f,$(eval S:=$(call Be,$S,0 $(call w,$(call h,$(words $(foreach i,$(call u,$(word $(words $f),4 10 30 120)),$G))))))$(eval D+=$f)$(eval G:=x $(filter y,$(subst $(call u,10),y,$D))))$n
x=$(call o,$Q,$W x,$R)
E0=$(eval T+=x)$(if $(word 11,$T $G),$(eval T:=)$(E4),n)
E4=$(if $x,$(eval W+=x),$l)
E5=$(if $x,$(eval W+=x)$(call E5),$l)
M=$(if $1,$(eval q:=$(wordlist $(firstword $1),999,$Q x x))$(if $(call o,$q,$W,$2),$(eval Q:=$q$NR:=$2),$(call M,$(call r,$1),$2)))
E1=$(call M,4,$R)
E2=$(call M,2,$R)
E3=$(call M,3 4 2 5 1,$(word $R,2 3 4 1))
C:=$Um
X:=$U38;5;60m
Y:=$U38;5;244m
Z:=$U1m
l0:=$U38;5;237m@·$C
$(foreach v,1 2 3 4 5 6 7,$(eval l$v:=$U38;5;$(word $v,51 226 135 46 196 33 208)m██$C))
Cx:=$U1;7m     GAME  OVER     $C
V1:=$O$X╭──$C $Ynext$C $X──────╮$C
V2:=$O$X│$C              $X│$C
V7:=$(V2)
V8:=$O$X╰──────────────╯$C
V10:=$O$Yscore$C
V14:=$O$Ycontrols$C
V15:=$O$Z← a$C  $Ymove left$C
V16:=$O$Z→ d$C  $Ymove right$C
V17:=$O$Z↑ w$C  $Yrotate$C
V18:=$O$Z↓ s$C  $Ysoft drop$C
V19:=$O$Z␣ z$C  $Yhard drop$C
V20:=$O$Z  q$C  $Yquit$C
V11=$O$Z$(subst $F,,$(call w,$S))$C
V12=$O$Ylevel$C $Z$(words $G)$C  $Ylines$C $Z$(words $D)$C
V3=$(call V,1)
V4=$(call V,2)
V5=$(call V,3)
V6=$(call V,4)
V=$O$X│$C   $(subst _,  ,$(subst $F,,$(foreach c,1 2 3 4,$(if $(filter $c.$1,$(D$t1)),$(l$t),_))))   $X│$C
Bj=$(if $H,,$(call m,$P))$(info $(if $(MAKE_RESTARTS),$UJ)$UH  $U1;38;5;75mM A K E T R I S$C$UK$N $X╔════════════════════╗$C$UK$N $(foreach i,$L,$X║$C$(if $(filter 1_10,$H_$i),$(Cx),$(subst @, ,$(subst $F,,$(foreach v,$(g$i),$(l$v)))))$X║$C$(V$i)$UK$N) $X╚════════════════════╝$C$UK)$(if $H,,$(call m,0))
-include $(STATE)
J:=$(file <$(FIFO).$(or $(MAKE_RESTARTS),0))
$(if $S,$(if $(value E$J),$(if $(strip $(E$J)),,$(Bj))),$(foreach d,$(call h,$J),$(eval b:=$(call j,0 $b,0 0 0 $b))$(foreach i,$(call u,$d),$(eval b:=$(call j,$b,1))))$(eval A:=$(wordlist 1,31,$b $e)$NS:=0$NG:=x$NJ:=$(J:9=s)$N$(foreach r,$L,g$r:=$(g0)$N))$k$n$(Bj))
all:;
$(if $H$(filter 9,$(or $J,9)),$(info $UJ),$(STATE)):all;$(file >$(STATE),$(foreach v,A P t Q W R T G D S $(L:%=g%),$v:=$($v)$N)):
