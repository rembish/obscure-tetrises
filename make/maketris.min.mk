U := 
Bh :=
F := $(Bh) $(Bh)
O := $F$F$F
define Cl


endef
As := x x
p := $(As) $(As) $(As) $(As)
P := $p $p $p $p $p $p $p $p
Ba := $P $P $P $P $P $P $P $P $P $P $P $P $P $P $P $P
u = $(wordlist 1,$1,$(Ba))
$(foreach k,$(wordlist 1,201,$(Ba)),$(eval Ak.$(words $(Ap)) := $(words $(Ap) x))$(eval Ae.$(words $(Ap) x) := $(words $(Ap)))$(eval Ap += x))
Bi := 1 2 3 4 5 6 7 8 9 10
Aa := $(Bi) 11 12 13 14 15 16 17 18 19 20
Cz := $(Aa) 21 22 23 24 25 26 27 28 29 30 31
Cq := e e e e e e e e e e e e e e e e e e e e
Bw := 0 0 0 0 0 0 0 0 0 0
Ah = $(strip $(subst 9,9 ,$(subst 8,8 ,$(subst 7,7 ,$(subst 6,6 ,$(subst 5,5 ,$(subst 4,4 ,$(subst 3,3 ,$(subst 2,2 ,$(subst 1,1 ,$(subst 0,0 ,$1)))))))))))
Aw = $(if $1,$(call Aw,$(wordlist 2,999,$1)) $(firstword $1))
Am = $(subst $F,,$(strip $1))
Bv = $(call u,$(or $(firstword $1),0)) $(call u,$(or $(firstword $2),0)) $3
Cj = $(if $(word 10,$1),$(words $(wordlist 11,99,$1)),$(words $1))
Be = $(if $(strip $1$2$3),$(call Cj,$(call Bv,$1,$2,$3)) $(call Be,$(wordlist 2,999,$1),$(wordlist 2,999,$2),$(if $(word 10,$(call Bv,$1,$2,$3)),x)))
Bf = $(call Am,$(call Aw,$(call Be,$(call Aw,$(call Ah,$1)),$(call Aw,$(call Ah,$2)),)))
Bt = $(or $(call Am,$(wordlist 1,$(Ae.$(words $(call Ah,$1))),$(call Ah,$1))),0)
Au.0 := 0
Au.1 := 1
Au.2 := 0 1
Au.3 := 1 1
Br = $(Au.$(words $(filter 1,$(firstword $1) $(firstword $2) $3)))
j = $(if $(strip $1$2$3),$(firstword $(call Br,$1,$2,$3)) $(call j,$(wordlist 2,999,$1),$(wordlist 2,999,$2),$(word 2,$(call Br,$1,$2,$3))))
Dd := 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
Bq = $(wordlist 1,31,$1 $(Dd))
Da = $(call j,$1,$(call j,0 $1,$(call j,0 0 $1,$(call j,0 0 0 0 0 $1,$(call j,0 0 0 0 0 0 0 $1,$(call j,0 0 0 0 0 0 0 0 $1,0 0 0 0 0 0 0 0 0 0 0 0 0 0 $1))))))
Bz = $(call j,$(wordlist 1,31,$1),$(wordlist 32,999,$1))
Cf = $(call Bq,$(call Bz,$(call Bz,$(call Da,$1))))
Ct := 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1
Ck := $(foreach k,1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19,0 1 2 3 4 5 6)
Dc = $(word $(Ak.$(words $(foreach i,$(Cz),$(if $(filter 1,$(word $i,$1)),$(call u,$(word $i,$(Ct))))))),$(Ck))
L.0.0 := 0 0
L.0.1 := 0 1
L.0.2 := 1 0
L.0.3 := 1 1
L.0.4 := 2 0
L.0.5 := 2 1
L.0.6 := 3 0
L.0.7 := 3 1
L.0.8 := 4 0
L.0.9 := 4 1
L.1.0 := 5 0
L.1.1 := 5 1
L.1.2 := 6 0
L.1.3 := 6 1
L.1.4 := 7 0
L.1.5 := 7 1
L.1.6 := 8 0
L.1.7 := 8 1
L.1.8 := 9 0
L.1.9 := 9 1
Ay = $(if $1,$(word 1,$(L.$2.$(firstword $1))) $(call Ay,$(wordlist 2,999,$1),$(word 2,$(L.$2.$(firstword $1)))),R$2)
Cb = $(if $(filter-out 0,$1),$(patsubst R%,%,$(lastword $(call Ay,$1,0))) $(call Cb,$(filter-out R%,$(call Ay,$1,0))))
D.0.0 := 0.1 1.1 2.1 3.1
D.0.1 := 2.0 2.1 2.2 2.3
D.0.2 := 0.2 1.2 2.2 3.2
D.0.3 := 1.0 1.1 1.2 1.3
D.1.0 := 1.0 2.0 1.1 2.1
D.1.1 := 1.0 2.0 1.1 2.1
D.1.2 := 1.0 2.0 1.1 2.1
D.1.3 := 1.0 2.0 1.1 2.1
D.2.0 := 1.0 0.1 1.1 2.1
D.2.1 := 1.0 1.1 2.1 1.2
D.2.2 := 0.1 1.1 2.1 1.2
D.2.3 := 1.0 0.1 1.1 1.2
D.3.0 := 1.0 2.0 0.1 1.1
D.3.1 := 1.0 1.1 2.1 2.2
D.3.2 := 1.1 2.1 0.2 1.2
D.3.3 := 0.0 0.1 1.1 1.2
D.4.0 := 0.0 1.0 1.1 2.1
D.4.1 := 2.0 1.1 2.1 1.2
D.4.2 := 0.1 1.1 1.2 2.2
D.4.3 := 1.0 0.1 1.1 0.2
D.5.0 := 0.0 0.1 1.1 2.1
D.5.1 := 1.0 2.0 1.1 1.2
D.5.2 := 0.1 1.1 2.1 2.2
D.5.3 := 1.0 1.1 0.2 1.2
D.6.0 := 2.0 0.1 1.1 2.1
D.6.1 := 1.0 1.1 1.2 2.2
D.6.2 := 0.1 1.1 2.1 0.2
D.6.3 := 0.0 1.0 1.1 1.2
h.0 := 1
h.1 := 2
h.2 := 3
h.3 := 4
h.4 := 5
h.5 := 6
h.6 := 7
Aq.0 := 1
Aq.1 := 2
Aq.2 := 3
Aq.3 := 0
Bd = $(firstword $(subst ., ,$1))
Az = $(lastword $(subst ., ,$1))
Bc = $(words $(wordlist 5,999,$1 $(call u,$2)))
Bb = $(words $1 $(call u,$2) x)
Cg = $(if $(filter $1,$(Bi)),$(if $(filter $2,$(Aa)),$(filter 0,$(word $1,$(g$2)))))
o = $(filter 4,$(words $(foreach c,$(D.$(Af).$3),$(call Cg,$(call Bc,$1,$(call Bd,$c)),$(call Bb,$2,$(call Az,$c))))))
Cs = $(eval g$2 := $(wordlist 1,$(Ae.$1),$(g$2)) $3 $(wordlist $(Ak.$1),10,$(g$2)))
Ax = $(foreach c,$(D.$(Af).$(Ab)),$(call Cs,$(call Bc,$Q,$(call Bd,$c)),$(call Bb,$W,$(call Az,$c)),$1))
Bg = $(eval Av := $(call Cf,$(Av)))$(eval Ai := $(call Dc,$(Av)))
Bl = $(eval Q := $(call u,8))$(eval W :=)$(eval Ab := 0)$(eval T :=)$(if $(call o,$Q,$W,0),,$(eval OVER := 1))
By = $(eval K := $(foreach r,$(Aa),$(if $(filter 0,$(g$r)),$r)))$(eval Aj := $(wordlist $(Ak.$(words $K)),20,$(Ba)))$(foreach r,$(Aa),$(eval Ch$r := $(g$r)))$(eval Bs := $(wordlist 1,$(words $(Aj)),$(Cq)) $K)$(foreach i,$(Aa),$(eval g$i := $(if $(filter e,$(word $i,$(Bs))),$(Bw),$(Ch$(word $i,$(Bs))))))
Df1 = $(words $G $G $G $G)0
Df2 = $(words $G)00
Df3 = $(words $G $G $G)00
Df4 = $(words $G $G $G $G $G $G $G $G $G $G $G $G)00
De = $(if $(Aj),$(eval An := $(call Bf,$(An),$(call Df$(words $(Aj))))))
Ce = $(eval G := x $(call u,$(call Bt,$(words $(Ao)))))
Bk = $(call Ax,$(h.$(Af)))$(call By)$(call De)$(eval Ao += $(Aj))$(call Ce)$(eval Af := $(Ai))$(call Bg)$(call Bl)
Bx = $(if $(call o,$Q,$W x,$(Ab)),$(eval W += x),$(call Bk))
left = $(if $(call o,$(wordlist 2,999,$Q),$W,$(Ab)),$(eval Q := $(wordlist 2,999,$Q)))
right = $(if $(call o,$Q x,$W,$(Ab)),$(eval Q += x))
Ad.0 = $1
Ad.m1 = $(wordlist 2,999,$1)
Ad.p1 = $1 x
Ad.m2 = $(wordlist 3,999,$1)
Ad.p2 = $1 x x
rotate = $(eval Bo := $(Aq.$(Ab)))$(eval Cc :=)$(foreach k,0 m1 p1 m2 p2,$(if $(Cc),,$(if $(call o,$(call Ad.$k,$Q),$W,$(Bo)),$(eval Q := $(call Ad.$k,$Q))$(eval Ab := $(Bo))$(eval Cc := 1))))
hard = $(if $(call o,$Q,$W x,$(Ab)),$(eval W += x)$(call hard),$(call Bk))
Ci = $(eval T += x)$(if $(word 11,$T $G),$(eval T :=)$(call Bx),$(eval Bu :=))
Ag.0 = $(call Ci)
Ag.1 = $(call left)
Ag.2 = $(call right)
Ag.3 = $(call rotate)
Ag.4 = $(call Bx)
Ag.5 = $(call hard)
Db = $(if $(At),,$(if $(filter 9,$1),$(eval At := 1),$(if $(filter 0 1 2 3 4 5,$1),$(eval Bu := 1)$(call Ag.$1)$(if $(Bu),$(call Bj))$(if $(OVER),$(eval At := 1)))))
C := $U[m
X := $U[38;5;60m
Y := $U[38;5;244m
Z := $U[1m
Ar := $U[K
Cv := $U[38;5;237m ·$C
Ac.1 := 51
Ac.2 := 226
Ac.3 := 135
Ac.4 := 46
Ac.5 := 196
Ac.6 := 33
Ac.7 := 208
$(foreach v,1 2 3 4 5 6 7,$(eval l.$v := $U[38;5;$(Ac.$v)m██$C))
Cx := $U[1;7m     GAME  OVER     $C
Cy := $F$F$U[1;38;5;75mM A K E T R I S$C$(Ar)
Cp := $F$X╔════════════════════╗$C$(Ar)
Cw := $F$X╚════════════════════╝$C$(Ar)
V.1 := $O$X╭──$C $Ynext$C $X──────╮$C
V.2 := $O$X│$C              $X│$C
V.7 := $(V.2)
V.8 := $O$X╰──────────────╯$C
V.10 := $O$Yscore$C
V.14 := $O$Ycontrols$C
V.15 := $O$Z← a$C$F$F$Ymove left$C
V.16 := $O$Z→ d$C$F$F$Ymove right$C
V.17 := $O$Z↑ w$C$F$F$Yrotate$C
V.18 := $O$Z↓ s$C$F$F$Ysoft drop$C
V.19 := $O$Z␣ z$C$F$F$Yhard drop$C
V.20 := $O$Z$F$Fq$C$F$F$Yquit$C
Co = $O$X│$C$O$(subst _,$F$F,$(subst B,$(l.$(h.$(Ai))),$(call Am,$(foreach c,0 1 2 3,$(if $(filter $c.$1,$(D.$(Ai).0)),B,_)))))$O$X│$C
Cr = $O$Ylevel$C $Z$(words $G)$C$F$F$Ylines$C $Z$(words $(Ao))$C
Bm = $(if $(filter 3 4 5 6,$1),$(call Co,$(Ae.$(Ae.$(Ae.$1)))),$(if $(filter 11,$1),$O$Z$(An)$C,$(if $(filter 12,$1),$(call Cr),$(V.$1))))
Ca = $(subst @0,$(Cv),$(subst @1,$(l.1),$(subst @2,$(l.2),$(subst @3,$(l.3),$(subst @4,$(l.4),$(subst @5,$(l.5),$(subst @6,$(l.6),$(subst @7,$(l.7),$(call Am,$(foreach v,$(g$1),@$v))))))))))
Cn = $F$X║$C$(if $(and $(OVER),$(filter 10,$1)),$(Cx),$(call Ca,$1))$X║$C$(call Bm,$1)$(Ar)
Bj = $(if $(OVER),,$(call Ax,$(h.$(Af))))$(info $(if $(Bn),$U[J)$U[H$(Cy))$(info $(Cp))$(foreach i,$(Aa),$(info $(call Cn,$i)))$(info $(Cw))$(eval Bn := 1)$(if $(OVER),,$(call Ax,0))
-include $(STATE)
Cm = $(eval Av := $(call Bq,$(call Cb,$(call Ah,$1))))$(foreach r,$(Aa),$(eval g$r := $(Bw)))$(eval An := 0)$(eval Ao :=)$(eval G := x)$(eval OVER :=)$(call Bg)$(eval Af := $(Ai))$(call Bg)$(call Bl)$(eval Cd := 1)$(call Bj)
Bp := $(file <$(FIFO).$(or $(MAKE_RESTARTS),0))
ifndef Bp
At := 1
endif
Al := $(Bp)
ifndef Cd
$(call Cm,$(firstword $(Al)))
Al := $(wordlist 2,999999,$(Al))
endif
$(foreach e,$(Al),$(call Db,$e))
Cu := Cd Av Af Ai Q W Ab T G Ao An OVER Bn $(foreach r,$(Aa),g$r)
all: ;
ifdef At
$(info $U[J)
else
$(STATE): FORCE ; @$(file >$(STATE),$(foreach v,$(Cu),$v := $($v)$(Cl)))true
FORCE: ;
endif
