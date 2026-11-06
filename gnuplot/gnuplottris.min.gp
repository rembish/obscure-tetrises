set pr "-"
array M[28]=[240,17476,3840,8738,102,102,102,102,114,610,624,562,54,1122,864,561,99,612,1584,306,113,550,1136,802,116,1570,368,547]
array b[200]
E="\033["
R=E."m"
K=E."K\n "
B=E."38;5;60m"
D=E."38;5;244m"
W=E."1m"
S="   "
X(a)=B.a.R
Y(a)=D.a.R
Z(a)=W.a.R
T(k,a)=S.Z(k)."  ".Y(a)
O=S.X("│")
V=O."           ".O
C=X("║")
w(v)=E."38;5;".(v?word("51 226 135 46 196 33 208",v)."m██":"237m ·").R
array c[20]=[S.X("╭──")." ".Y("next")." ".X("──────╮"),V,O.S,O.S,O.S,O.S,V,S.X("╰──────────────╯"),"",S.Y("score"),S.Z("%d"),S.Y("level")." ".Z("%d")."  ".Y("lines")." ".Z("%d"),"",S.Y("controls"),T("← a","move left"),T("→ d","move right"),T("↑ w","rotate"),T("↓ s","soft drop"),T("␣ z","hard drop"),T("  q","quit")]
o=1
function $b(a,m,p)<<F
do for[i=0:15]{if(M[z*4+p+1]>>i&1&&((F=a+i%4)<0||F>9||(N=m+i/4)>19||b[N*10+F+1])){return 0}}
return 1
F
function $c(v)<<F
do for[i=0:15]{if(M[z*4+r+1]>>i&1){b[y*10+x+i+i/4*6+1]=v}}
F
function $n()<<F
z=H
H=(s=s*16807%2147483647)%7
x=3
y=r=t=0
n=!$b(3,0,0)
F
function $step(e)<<F
if(o){s=e;do for[k=1:200]{b[k]=0};l=g=n=H=o=0;d=$n();d=$n();e=5.5}
if(e<1&&(t=t+1)+g/10>9){t=0;e=4}
if(e>0&&e<3&&$b(x+2*e-3,y,r)){x=x+2*e-3}
if(e==3){v=(r+1)%4;do for[q=1:5]{if($b(x+(k=q/2*(q%2*2-1)),y,v)){x=x+k;r=v;break}}}
if(e==5){while($b(x,y+1,r)){y=y+1};e=4}
if(e==4){if($b(x,y+1,r)){y=y+1}else{
d=$c(z+1)
A=19
do for[L=19:0:-1]{G=1;do for[j=1:10]{G=G*b[L*10+j]};do for[j=1:10*!G]{b[A*10+j]=b[L*10+j]};A=A-!G}
do for[j=1:A*10+10]{b[j]=0}
l=l+word("0 40 100 300 1200",A+2)*(g/10+1)
g=g+A+1
d=$n()
}}
if(e>0&&e<6){
d=n?0:$c(z+1)
f=E."H  ".E."1;38;5;75mG N U P L O T T R I S".R.K.X("╔════════════════════╗").K
do for[h=0:19]{
f=f.C
if(n&&h==9){f=f.E."1;7m     GAME  OVER     ".R}else{do for[j=1:10]{f=f.w(b[h*10+j])}}
f=f.C.sprintf(c[h+1],h>10?g/10+1:l,g)
if(h>1&&h<6){do for[q=h*4-8:h*4-5]{f=f.(M[H*4+1]>>q&1?w(H+1):"  ")};f=f.O}
f=f.K
}
pr f.X("╚════════════════════╝").E."K"
d=n?0:$c(0)
}
return n||e==9
F
