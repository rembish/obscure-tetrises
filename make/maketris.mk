# maketris.mk - a falling-block puzzle game written in GNU make.
#
#   make -s -f maketris.mk FIFO=<named pipe> STATE=<state file>
#
# Events (../SPEC.md) arrive through named pipes FIFO.0, FIFO.1, ... (one per
# pass): $(file <FIFO.N) blocks until the writer has written and closed it.
# Frames go to stdout via $(info).
#
# make has no loops, no arithmetic and no input, so:
#   - The game loop is make restarting itself. STATE is an included makefile
#     that holds the whole game. Its rule rewrites it and runs `true`, so make sees
#     an included makefile that was rebuilt and re-executes with the new state.
#   - Small numbers are unary: "x x x" is 3. $(words) counts and $(word n,...)
#     compares. The score is a decimal string with digit-by-digit addition,
#     and the random-number generator works on lists of bits.
#   - Every assignment during a pass is a $(eval) inside a function.

ESC := 
empty :=
SP := $(empty) $(empty)
SP3 := $(SP)$(SP)$(SP)
define NL


endef

# ---- unary numbers ----------------------------------------------------------
X2 := x x
X8 := $(X2) $(X2) $(X2) $(X2)
X64 := $(X8) $(X8) $(X8) $(X8) $(X8) $(X8) $(X8) $(X8)
X := $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64) $(X64)
# U(n): the unary number n, for 0 <= n <= 1024
U = $(wordlist 1,$1,$(X))
# INC.n and DEC.n for 0..200, made by counting
$(foreach k,$(wordlist 1,201,$(X)),$(eval INC.$(words $(_acc)) := $(words $(_acc) x))$(eval DEC.$(words $(_acc) x) := $(words $(_acc)))$(eval _acc += x))
N10 := 1 2 3 4 5 6 7 8 9 10
N20 := $(N10) 11 12 13 14 15 16 17 18 19 20
N31 := $(N20) 21 22 23 24 25 26 27 28 29 30 31
E20 := e e e e e e e e e e e e e e e e e e e e
ZROW := 0 0 0 0 0 0 0 0 0 0

# ---- decimal numbers ----------------------------------------------------------
digits = $(strip $(subst 9,9 ,$(subst 8,8 ,$(subst 7,7 ,$(subst 6,6 ,$(subst 5,5 ,$(subst 4,4 ,$(subst 3,3 ,$(subst 2,2 ,$(subst 1,1 ,$(subst 0,0 ,$1)))))))))))
rev = $(if $1,$(call rev,$(wordlist 2,999,$1)) $(firstword $1))
glue = $(subst $(SP),,$(strip $1))
# dadd(a, b, carry): add two digit lists, least significant digit first
dsum = $(call U,$(or $(firstword $1),0)) $(call U,$(or $(firstword $2),0)) $3
ddig = $(if $(word 10,$1),$(words $(wordlist 11,99,$1)),$(words $1))
dadd = $(if $(strip $1$2$3),$(call ddig,$(call dsum,$1,$2,$3)) $(call dadd,$(wordlist 2,999,$1),$(wordlist 2,999,$2),$(if $(word 10,$(call dsum,$1,$2,$3)),x)))
add = $(call glue,$(call rev,$(call dadd,$(call rev,$(call digits,$1)),$(call rev,$(call digits,$2)),)))
# div10(n) = n / 10, rounded down
div10 = $(or $(call glue,$(wordlist 1,$(DEC.$(words $(call digits,$1))),$(call digits,$1))),0)

# ---- random numbers: Park-Miller on 31-bit lists, least significant bit first ----------
# full adder: number of 1s among the two bits and the carry -> "sum carry"
FA.0 := 0
FA.1 := 1
FA.2 := 0 1
FA.3 := 1 1
fa = $(FA.$(words $(filter 1,$(firstword $1) $(firstword $2) $3)))
badd = $(if $(strip $1$2$3),$(firstword $(call fa,$1,$2,$3)) $(call badd,$(wordlist 2,999,$1),$(wordlist 2,999,$2),$(word 2,$(call fa,$1,$2,$3))))
Z31 := 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
pad31 = $(wordlist 1,31,$1 $(Z31))
# s * 16807: 16807 = 2^0 + 2^1 + 2^2 + 2^5 + 2^7 + 2^8 + 2^14
mul = $(call badd,$1,$(call badd,0 $1,$(call badd,0 0 $1,$(call badd,0 0 0 0 0 $1,$(call badd,0 0 0 0 0 0 0 $1,$(call badd,0 0 0 0 0 0 0 0 $1,0 0 0 0 0 0 0 0 0 0 0 0 0 0 $1))))))
# mod 2^31 - 1: since 2^31 = 1 (mod 2^31 - 1), add the high bits onto the low ones
fold = $(call badd,$(wordlist 1,31,$1),$(wordlist 32,999,$1))
rng = $(call pad31,$(call fold,$(call fold,$(call mul,$1))))
# s mod 7: bit i is worth 2^i mod 7 = 1, 2, 4, 1, 2, 4, ...
W31 := 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1 2 4 1
MOD7 := $(foreach k,1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19,0 1 2 3 4 5 6)
mod7 = $(word $(INC.$(words $(foreach i,$(N31),$(if $(filter 1,$(word $i,$1)),$(call U,$(word $i,$(W31))))))),$(MOD7))
# decimal -> bits, by halving: HALF.<remainder>.<digit> = "quotient-digit new-remainder"
HALF.0.0 := 0 0
HALF.0.1 := 0 1
HALF.0.2 := 1 0
HALF.0.3 := 1 1
HALF.0.4 := 2 0
HALF.0.5 := 2 1
HALF.0.6 := 3 0
HALF.0.7 := 3 1
HALF.0.8 := 4 0
HALF.0.9 := 4 1
HALF.1.0 := 5 0
HALF.1.1 := 5 1
HALF.1.2 := 6 0
HALF.1.3 := 6 1
HALF.1.4 := 7 0
HALF.1.5 := 7 1
HALF.1.6 := 8 0
HALF.1.7 := 8 1
HALF.1.8 := 9 0
HALF.1.9 := 9 1
halve = $(if $1,$(word 1,$(HALF.$2.$(firstword $1))) $(call halve,$(wordlist 2,999,$1),$(word 2,$(HALF.$2.$(firstword $1)))),R$2)
tobin = $(if $(filter-out 0,$1),$(patsubst R%,%,$(lastword $(call halve,$1,0))) $(call tobin,$(filter-out R%,$(call halve,$1,0))))

# ---- pieces --------------------------------------------------------------------
# CELLS.<piece>.<rotation>: the four cells as dx.dy, decoded from the masks in SPEC.md
CELLS.0.0 := 0.1 1.1 2.1 3.1
CELLS.0.1 := 2.0 2.1 2.2 2.3
CELLS.0.2 := 0.2 1.2 2.2 3.2
CELLS.0.3 := 1.0 1.1 1.2 1.3
CELLS.1.0 := 1.0 2.0 1.1 2.1
CELLS.1.1 := 1.0 2.0 1.1 2.1
CELLS.1.2 := 1.0 2.0 1.1 2.1
CELLS.1.3 := 1.0 2.0 1.1 2.1
CELLS.2.0 := 1.0 0.1 1.1 2.1
CELLS.2.1 := 1.0 1.1 2.1 1.2
CELLS.2.2 := 0.1 1.1 2.1 1.2
CELLS.2.3 := 1.0 0.1 1.1 1.2
CELLS.3.0 := 1.0 2.0 0.1 1.1
CELLS.3.1 := 1.0 1.1 2.1 2.2
CELLS.3.2 := 1.1 2.1 0.2 1.2
CELLS.3.3 := 0.0 0.1 1.1 1.2
CELLS.4.0 := 0.0 1.0 1.1 2.1
CELLS.4.1 := 2.0 1.1 2.1 1.2
CELLS.4.2 := 0.1 1.1 1.2 2.2
CELLS.4.3 := 1.0 0.1 1.1 0.2
CELLS.5.0 := 0.0 0.1 1.1 2.1
CELLS.5.1 := 1.0 2.0 1.1 1.2
CELLS.5.2 := 0.1 1.1 2.1 2.2
CELLS.5.3 := 1.0 1.1 0.2 1.2
CELLS.6.0 := 2.0 0.1 1.1 2.1
CELLS.6.1 := 1.0 1.1 1.2 2.2
CELLS.6.2 := 0.1 1.1 2.1 0.2
CELLS.6.3 := 0.0 1.0 1.1 1.2
VAL.0 := 1
VAL.1 := 2
VAL.2 := 3
VAL.3 := 4
VAL.4 := 5
VAL.5 := 6
VAL.6 := 7
NEXTROT.0 := 1
NEXTROT.1 := 2
NEXTROT.2 := 3
NEXTROT.3 := 0
dx = $(firstword $(subst ., ,$1))
dy = $(lastword $(subst ., ,$1))

# The piece's box column is stored as unary x+5 (XU) and its row as unary y (YU).
# col1/row1 turn a box position plus a cell offset into 1-based board indices.
col1 = $(words $(wordlist 5,999,$1 $(call U,$2)))
row1 = $(words $1 $(call U,$2) x)
cellok = $(if $(filter $1,$(N10)),$(if $(filter $2,$(N20)),$(filter 0,$(word $1,$(ROW$2)))))
# fits(XU, YU, rotation): non-empty if the current piece fits there
fits = $(filter 4,$(words $(foreach c,$(CELLS.$(CUR).$3),$(call cellok,$(call col1,$1,$(call dx,$c)),$(call row1,$2,$(call dy,$c))))))

setcell = $(eval ROW$2 := $(wordlist 1,$(DEC.$1),$(ROW$2)) $3 $(wordlist $(INC.$1),10,$(ROW$2)))
paint = $(foreach c,$(CELLS.$(CUR).$(ROT)),$(call setcell,$(call col1,$(XU),$(call dx,$c)),$(call row1,$(YU),$(call dy,$c)),$1))

# ---- game rules ---------------------------------------------------------------
draw = $(eval SEED := $(call rng,$(SEED)))$(eval NXT := $(call mod7,$(SEED)))
spawn = $(eval XU := $(call U,8))$(eval YU :=)$(eval ROT := 0)$(eval T :=)$(if $(call fits,$(XU),$(YU),0),,$(eval OVER := 1))

# compact: K = indices of the rows that aren't full; CLR = rows cleared (unary)
compact = $(eval K := $(foreach r,$(N20),$(if $(filter 0,$(ROW$r)),$r)))$(eval CLR := $(wordlist $(INC.$(words $(K))),20,$(X)))$(foreach r,$(N20),$(eval TMP$r := $(ROW$r)))$(eval NEWIDX := $(wordlist 1,$(words $(CLR)),$(E20)) $(K))$(foreach i,$(N20),$(eval ROW$i := $(if $(filter e,$(word $i,$(NEWIDX))),$(ZROW),$(TMP$(word $i,$(NEWIDX))))))
# points for 1..4 rows: 40, 100, 300, 1200 times the level (LV, unary)
pts1 = $(words $(LV) $(LV) $(LV) $(LV))0
pts2 = $(words $(LV))00
pts3 = $(words $(LV) $(LV) $(LV))00
pts4 = $(words $(LV) $(LV) $(LV) $(LV) $(LV) $(LV) $(LV) $(LV) $(LV) $(LV) $(LV) $(LV))00
addscore = $(if $(CLR),$(eval SCORE := $(call add,$(SCORE),$(call pts$(words $(CLR))))))
setlevel = $(eval LV := x $(call U,$(call div10,$(words $(LINES)))))
lock = $(call paint,$(VAL.$(CUR)))$(call compact)$(call addscore)$(eval LINES += $(CLR))$(call setlevel)$(eval CUR := $(NXT))$(call draw)$(call spawn)

stepdown = $(if $(call fits,$(XU),$(YU) x,$(ROT)),$(eval YU += x),$(call lock))
left = $(if $(call fits,$(wordlist 2,999,$(XU)),$(YU),$(ROT)),$(eval XU := $(wordlist 2,999,$(XU))))
right = $(if $(call fits,$(XU) x,$(YU),$(ROT)),$(eval XU += x))
kick.0 = $1
kick.m1 = $(wordlist 2,999,$1)
kick.p1 = $1 x
kick.m2 = $(wordlist 3,999,$1)
kick.p2 = $1 x x
rotate = $(eval NR := $(NEXTROT.$(ROT)))$(eval KD :=)$(foreach k,0 m1 p1 m2 p2,$(if $(KD),,$(if $(call fits,$(call kick.$k,$(XU)),$(YU),$(NR)),$(eval XU := $(call kick.$k,$(XU)))$(eval ROT := $(NR))$(eval KD := 1))))
hard = $(if $(call fits,$(XU),$(YU) x,$(ROT)),$(eval YU += x)$(call hard),$(call lock))
tick = $(eval T += x)$(if $(word 11,$(T) $(LV)),$(eval T :=)$(call stepdown),$(eval EMIT :=))
ev.0 = $(call tick)
ev.1 = $(call left)
ev.2 = $(call right)
ev.3 = $(call rotate)
ev.4 = $(call stepdown)
ev.5 = $(call hard)
event = $(if $(DONE),,$(if $(filter 9,$1),$(eval DONE := 1),$(if $(filter 0 1 2 3 4 5,$1),$(eval EMIT := 1)$(call ev.$1)$(if $(EMIT),$(call render))$(if $(OVER),$(eval DONE := 1)))))

# ---- rendering ------------------------------------------------------------------
RST := $(ESC)[m
BC := $(ESC)[38;5;60m
DIM := $(ESC)[38;5;244m
BOLD := $(ESC)[1m
EOLK := $(ESC)[K
DOT := $(ESC)[38;5;237m ·$(RST)
COL.1 := 51
COL.2 := 226
COL.3 := 135
COL.4 := 46
COL.5 := 196
COL.6 := 33
COL.7 := 208
$(foreach v,1 2 3 4 5 6 7,$(eval BLK.$v := $(ESC)[38;5;$(COL.$v)m██$(RST)))
BANNER := $(ESC)[1;7m     GAME  OVER     $(RST)
TITLE := $(SP)$(SP)$(ESC)[1;38;5;75mM A K E T R I S$(RST)$(EOLK)
TOPLINE := $(SP)$(BC)╔════════════════════╗$(RST)$(EOLK)
BOTLINE := $(SP)$(BC)╚════════════════════╝$(RST)$(EOLK)

# side panel, by 1-based board row
PANEL.1 := $(SP3)$(BC)╭──$(RST) $(DIM)next$(RST) $(BC)──────╮$(RST)
PANEL.2 := $(SP3)$(BC)│$(RST)              $(BC)│$(RST)
PANEL.7 := $(PANEL.2)
PANEL.8 := $(SP3)$(BC)╰──────────────╯$(RST)
PANEL.10 := $(SP3)$(DIM)score$(RST)
PANEL.14 := $(SP3)$(DIM)controls$(RST)
PANEL.15 := $(SP3)$(BOLD)← a$(RST)$(SP)$(SP)$(DIM)move left$(RST)
PANEL.16 := $(SP3)$(BOLD)→ d$(RST)$(SP)$(SP)$(DIM)move right$(RST)
PANEL.17 := $(SP3)$(BOLD)↑ w$(RST)$(SP)$(SP)$(DIM)rotate$(RST)
PANEL.18 := $(SP3)$(BOLD)↓ s$(RST)$(SP)$(SP)$(DIM)soft drop$(RST)
PANEL.19 := $(SP3)$(BOLD)␣ z$(RST)$(SP)$(SP)$(DIM)hard drop$(RST)
PANEL.20 := $(SP3)$(BOLD)$(SP)$(SP)q$(RST)$(SP)$(SP)$(DIM)quit$(RST)
nextrow = $(SP3)$(BC)│$(RST)$(SP3)$(subst _,$(SP)$(SP),$(subst B,$(BLK.$(VAL.$(NXT))),$(call glue,$(foreach c,0 1 2 3,$(if $(filter $c.$1,$(CELLS.$(NXT).0)),B,_)))))$(SP3)$(BC)│$(RST)
levelrow = $(SP3)$(DIM)level$(RST) $(BOLD)$(words $(LV))$(RST)$(SP)$(SP)$(DIM)lines$(RST) $(BOLD)$(words $(LINES))$(RST)
panel = $(if $(filter 3 4 5 6,$1),$(call nextrow,$(DEC.$(DEC.$(DEC.$1)))),$(if $(filter 11,$1),$(SP3)$(BOLD)$(SCORE)$(RST),$(if $(filter 12,$1),$(call levelrow),$(PANEL.$1))))
cells = $(subst @0,$(DOT),$(subst @1,$(BLK.1),$(subst @2,$(BLK.2),$(subst @3,$(BLK.3),$(subst @4,$(BLK.4),$(subst @5,$(BLK.5),$(subst @6,$(BLK.6),$(subst @7,$(BLK.7),$(call glue,$(foreach v,$(ROW$1),@$v))))))))))
rowline = $(SP)$(BC)║$(RST)$(if $(and $(OVER),$(filter 10,$1)),$(BANNER),$(call cells,$1))$(BC)║$(RST)$(call panel,$1)$(EOLK)
render = $(if $(OVER),,$(call paint,$(VAL.$(CUR))))$(info $(ESC)[H$(TITLE))$(info $(TOPLINE))$(foreach i,$(N20),$(info $(call rowline,$i)))$(info $(BOTLINE))$(if $(OVER),,$(call paint,0))

# ---- one pass: load the state, read events, play them, save the state ----------
-include $(STATE)

init = $(eval SEED := $(call pad31,$(call tobin,$(call digits,$1))))$(foreach r,$(N20),$(eval ROW$r := $(ZROW)))$(eval SCORE := 0)$(eval LINES :=)$(eval LV := x)$(eval OVER :=)$(call draw)$(eval CUR := $(NXT))$(call draw)$(call spawn)$(eval STARTED := 1)$(call render)

# Pass N reads pipe FIFO.N. MAKE_RESTARTS is make's own restart counter. One
# pipe per pass means each write is paired with exactly one read.
INPUT := $(file <$(FIFO).$(or $(MAKE_RESTARTS),0))
ifndef INPUT
# the writer closed the pipe without sending anything: end of input
DONE := 1
endif
EVENTS := $(INPUT)
ifndef STARTED
$(call init,$(firstword $(EVENTS)))
EVENTS := $(wordlist 2,999999,$(EVENTS))
endif
$(foreach e,$(EVENTS),$(call event,$e))

SAVED := STARTED SEED CUR NXT XU YU ROT T LV LINES SCORE OVER $(foreach r,$(N20),ROW$r)

all: ;

ifndef DONE
$(STATE): FORCE ; @$(file >$(STATE),$(foreach v,$(SAVED),$v := $($v)$(NL)))true
FORCE: ;
endif
