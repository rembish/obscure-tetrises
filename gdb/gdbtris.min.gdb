set prompt
set pagination off
set height 0
set width 0
set $M={240,17476,3840,8738,102,102,102,102,114,610,624,562,54,1122,864,561,99,612,1584,306,113,550,1136,802,116,1570,368,547}
set $C={51,226,135,46,196,33,208}
set $P={0,40,100,300,1200}
set $Z={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
define R
set $s=$s*16807%2147483647
end
define F
set $o=1
set $m=$M[$c*4+$w]
set $i=0
while $i<16&&$o
if $m>>$i&1
set $p=$u+$i%4
set $q=$v+$i/4
if $p<0||$p>9||$q>19
set $o=0
else
set $o=!($b[$q]>>3*$p&7)
end
end
set $i=$i+1
end
end
define S
set $c=$n
R
set $n=$s%7
set $x=3
set $y=0
set $r=0
set $t=0
set $u=3
set $v=0
set $w=0
F
set $g=!$o
end
define L
set $m=$M[$c*4+$r]
set $i=0
while $i<16
if $m>>$i&1
set $b[$y+$i/4]|=$c+1<<3*($x+$i%4)
end
set $i=$i+1
end
set $j=19
set $f=19
while $f>=0
set $h=1
set $i=0
while $i<10
set $h&=($b[$f]>>3*$i&7)!=0
set $i=$i+1
end
if !$h
set $b[$j--]=$b[$f]
end
set $f=$f-1
end
set $k=$j+1
while $j>=0
set $b[$j--]=0
end
set $a+=$P[$k]*($l/10+1)
set $l+=$k
S
end
define D
set $u=$x
set $v=$y+1
set $w=$r
F
if $o
set $y=$v
else
L
end
end
define G
if $arg0
printf "[38;5;%dm██[m",$C[($arg0)-1]
else
printf "[38;5;237m ·[m"
end
end
define W
set $e=$b
if !$g
set $m=$M[$c*4+$r]
set $i=0
while $i<16
if $m>>$i&1
set $e[$y+$i/4]|=$c+1<<3*($x+$i%4)
end
set $i=$i+1
end
end
printf "[H  [1;38;5;75mG D B T R I S[m[K\n [38;5;60m╔════════════════════╗[m[K\n"
set $j=0
while $j<20
printf " [38;5;60m║[m"
if $g&&$j==9
printf "[1;7m     GAME  OVER     [m"
else
set $i=0
while $i<10
G $e[$j]>>3*$i&7
set $i=$i+1
end
end
printf "[38;5;60m║[m"
if $j==0
printf "   [38;5;60m╭──[m [38;5;244mnext[m [38;5;60m──────╮[m"
end
if $j==1||$j>3&&$j<7
printf "   [38;5;60m│[m              [38;5;60m│[m"
end
if $j==2||$j==3
printf "   [38;5;60m│[m   "
set $i=0
while $i<4
if $M[$n*4]>>($j-2)*4+$i&1
G $n+1
else
printf "  "
end
set $i=$i+1
end
printf "   [38;5;60m│[m"
end
if $j==7
printf "   [38;5;60m╰──────────────╯[m"
end
if $j==9
printf "   [38;5;244mscore[m"
end
if $j==10
printf "   [1m%d[m",$a
end
if $j==11
printf "   [38;5;244mlevel[m [1m%d[m  [38;5;244mlines[m [1m%d[m",$l/10+1,$l
end
if $j==13
printf "   [38;5;244mcontrols[m"
end
if $j>13
printf "   [1m%s[m  [38;5;244m%s[m",$j==14?"← a":$j==15?"→ d":$j==16?"↑ w":$j==17?"↓ s":$j==18?"␣ z":"  q",$j==14?"move left":$j==15?"move right":$j==16?"rotate":$j==17?"soft drop":$j==18?"hard drop":"quit"
end
printf "[K\n"
set $j=$j+1
end
printf " [38;5;60m╚════════════════════╝[m[K\n"
end
define seed
set $s=(long long)$arg0
set $b=$Z
set $a=0
set $l=0
set $g=0
R
set $n=$s%7
S
W
if $g
quit
end
end
define event
set $z=1
if $arg0==0
set $t=$t+1
if $t+$l/10>9
set $t=0
D
else
set $z=0
end
end
if $arg0==1||$arg0==2
set $u=$x+$arg0*2-3
set $v=$y
set $w=$r
F
if $o
set $x=$u
end
end
if $arg0==3
set $K={0,-1,1,-2,2}
set $w=($r+1)%4
set $v=$y
set $k=0
set $o=0
while $k<5&&!$o
set $u=$x+$K[$k++]
F
end
if $o
set $x=$u
set $r=$w
end
end
if $arg0==4
D
end
if $arg0==5
set $u=$x
set $v=$y+1
set $w=$r
F
while $o
set $y=$v++
F
end
L
end
if $arg0>5
set $z=0
end
if $z
W
end
if $g
quit
end
end
