set print "-"
array M[28]=[240,17476,3840,8738,102,102,102,102,114,610,624,562,\
54,1122,864,561,99,612,1584,306,113,550,1136,802,\
116,1570,368,547]
array S[7]=[51,226,135,46,196,33,208]
array U[5]=[0,40,100,300,1200]
array I[5]=[0,-1,1,-2,2]
array b[200]
E="\033["
R=E."m"
K=E."K\n"
B=E."38;5;60m"
D=E."38;5;244m"
W=E."1m"
array w[8]
w[1]=E."38;5;237m ·".R
do for[p=0:6]{w[p+2]=sprintf("%s38;5;%dm██%s",E,S[p+1],R)}
array c[20]
do for[p=1:20]{c[p]=""}
c[1]="   ".B."╭──".R." ".D."next".R." ".B."──────╮".R
c[2]="   ".B."│".R."              ".B."│".R
c[7]=c[2]
c[8]="   ".B."╰──────────────╯".R
c[10]="   ".D."score".R
c[14]="   ".D."controls".R
c[15]="   ".W."← a".R."  ".D."move left".R
c[16]="   ".W."→ d".R."  ".D."move right".R
c[17]="   ".W."↑ w".R."  ".D."rotate".R
c[18]="   ".W."↓ s".R."  ".D."soft drop".R
c[19]="   ".W."␣ z".R."  ".D."hard drop".R
c[20]="   ".W."  q".R."  ".D."quit".R
u=0
o=0
function $a()<<EOD
s=(s*16807)%2147483647
H=s%7
return 0
EOD
function $b(Z,aa,Y)<<EOD
local m=M[z*4+Y+1]
local i=0
local P=0
local Q=0
do for[i=0:15]{
if((m>>i)&1){
P=Z+i%4
Q=aa+i/4
if(P<0||P>9||Q<0||Q>19){return 0}
if(b[Q*10+P+1]!=0){return 0}
}
}
return 1
EOD
function $c(v)<<EOD
local m=M[z*4+r+1]
local i=0
do for[i=0:15]{
if((m>>i)&1){b[(y+i/4)*10+x+i%4+1]=v}
}
return 0
EOD
function $d()<<EOD
x=3
y=0
r=0
t=0
if(!$b(3,0,0)){n=1}
return 0
EOD
function $e()<<EOD
local d=$c(z+1)
local A=19
local L=0
local j=0
local G=0
do for[L=19:0:-1]{
G=0
do for[j=0:9]{if(b[L*10+j+1]!=0){G=G+1}}
if(G<10){
do for[j=0:9]{b[A*10+j+1]=b[L*10+j+1]}
A=A-1
}
}
local O=A+1
if(O>0){do for[j=1:O*10]{b[j]=0}}
l=l+U[O+1]*(g/10+1)
g=g+O
z=H
d=$a()
d=$d()
return 0
EOD
function $f()<<EOD
if($b(x,y+1,r)){y=y+1}else{local d=$e()}
return 0
EOD
function $g(V)<<EOD
if($b(x+V,y,r)){x=x+V}
return 0
EOD
function $h()<<EOD
local X=(r+1)%4
local q=0
do for[q=1:5]{
if($b(x+I[q],y,X)){
x=x+I[q]
r=X
break
}
}
return 0
EOD
function $i()<<EOD
while($b(x,y+1,r)){y=y+1}
local d=$e()
return 0
EOD
function $j()<<EOD
local d=0
if(!n){d=$c(z+1)}
local f=(o?E."J":"").E."H  ".E."1;38;5;75mG N U P L O T T R I S".R.K
f=f." ".B."╔════════════════════╗".R.K
local ab=M[H*4+1]
local h=0
local j=0
local q=0
do for[h=0:19]{
f=f." ".B."║".R
if(n&&h==9){
f=f.E."1;7m     GAME  OVER     ".R
}else{
do for[j=0:9]{f=f.w[b[h*10+j+1]+1]}
}
f=f.B."║".R
if(h>=2&&h<=5){
f=f."   ".B."│".R."   "
do for[q=0:3]{
f=f.(((ab>>((h-2)*4+q))&1)?w[H+2]:"  ")
}
f=f."   ".B."│".R
}else{
if(h==10){
f=f.sprintf("   %s%d%s",W,l,R)
}else{
if(h==11){
f=f.sprintf("   %slevel%s %s%d%s  %slines%s %s%d%s",D,R,W,g/10+1,R,D,R,W,g,R)
}else{
f=f.c[h+1]
}
}
}
f=f.K
}
f=f." ".B."╚════════════════════╝".R.E."K"
print f
o=1
if(!n){d=$c(0)}
return 0
EOD
function $step(e)<<EOD
local d=0
local k=0
if(!u){
s=e
do for[k=1:200]{b[k]=0}
l=0
g=0
n=0
d=$a()
z=H
d=$a()
d=$d()
u=1
d=$j()
return 0
}
if(e==9){
print E."J"
return 1
}
local F=1
if(e==0){
t=t+1
if(t+g/10>=10){t=0; d=$f()}else{F=0}
}else{
if(e==1){d=$g(-1)}else{
if(e==2){d=$g(1)}else{
if(e==3){d=$h()}else{
if(e==4){d=$f()}else{
if(e==5){d=$i()}else{F=0}
}
}
}
}
}
if(F){
d=$j()
if(n){
print E."J"
return 1
}
}
return 0
EOD
