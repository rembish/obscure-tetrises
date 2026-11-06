BEGIN{split("240 102 114 54 99 113 116 51 226 135 46 196 33 208 0 40 100 300 1200",M)
E="[";R=E"m";S="   ";W=E"1m";c=E"38;5;";g=c"244m";b=c"60m";V=b"║"R;k=b"│"R;Q=E"K\n "
for(;i++<7;)K[i]=c M[i+7]"m██"R
K[" "]=c"237m ·"R
Z="<          >";for(;j++<20;){h=h"═";B=B Z;if(j<15)u=u"─"}
T=E"H  "E"1;38;5;75mA W K T R I S"R Q b"╔"h"╗"R Q;O=E"1;7m     GAME  OVER     "R
A[0]=S b"╭──"R" "g"next"R" "b"──────╮"R;A[1]=A[6]=S k"              "k;A[7]=S b"╰"u"╯"R;A[9]=S g"score"R;A[13]=S g"controls"R
split("← a|move left|→ d|move right|↑ w|rotate|↓ s|soft drop|␣ z|hard drop|  q|quit",X,"|");for(i=1;i<13;i+=2)A[i/2+13.5]=S W X[i]R"  "g X[i+1]R}
function f(X,Y,R,v,i,j,m,a,z,q){for(m=M[p];m;i++){if(m%2){a=i%4;z=(i-a)/4;for(q=p-2?R:0;q--;){j=a;a=2+(p<2)-z;z=j}j=(Y+z)*12+X+a+2;if(v)G=substr(G,1,j-1)p substr(G,j+1);else if(substr(B,j,1)!=" ")return}m=int(m/2)}return 1}
function l(n){G=B;f(x,y,r,1);B=G;n=gsub(/<[1-7]+>/,"",B);C+=M[n+15]*(v+1);L+=n;v=int(L/10);while(n--)B=Z B;p=N;N=(s=s*16807%2147483647)%7+1;x=3;y=r=t=0;o=!f(3,0,0)}
function w(i,j,c,m){G=B;o||f(x,y,r,1)
m=M[N];for(;i<16;i++){j=2+int(i/4);A[j]=(i%4?A[j]:S k S)(m%2?K[N]:"  ")(i%4>2?S k:"");m=int(m/2)}
A[10]=S W C R;A[11]=S g"level"R" "W v+1 R"  "g"lines"R" "W L R
c=T;for(j=0;j<20;j++){c=c V;if(o&&j==9)c=c O;else for(i=2;i<12;i++)c=c K[substr(G,j*12+i,1)];c=c V A[j]Q}printf"%s",c b"╚"h"╝"R E"K\n";fflush()}
NR<2{s=$1;l();l();w()}
NR>1{if((e=$1)==9)exit
if(!e){if(++t+v<10)next;t=0;e=4}
if(e==5){while(f(x,y+1,r))y++;e=4}
if(e==4)f(x,y+1,r)?y++:l();else if(e==3){for(d=0;d>-3;d=-d-(d>=0))if(f(x+d,y,n=(r+1)%4)){x+=d;r=n;break}}else if(e>0&&e<3){d=2*e-3;x+=d*f(x+d,y,r)}else next
w();if(o)exit}
