let Z=repeat([0],10)+[9,9]
let b=repeat(Z,20)+repeat([9],12)
let C=map([237,51,226,135,46,196,33,208],'"`".v:val.(v:key?"██`":" ·`")')
let O=[]
for k in range(7)
let a=split('4567125614561245015604562456'[k*4:k*4+3],'\zs')
let O+=[map(range(4),'[map(copy(a),"v:val/4*12+v:val%4"),map(a,"(v:val%4-(k==1))*4+2+!k-v:val/4")][0]')]
endfo
let S='let q=q*16807%2147483647|let[c,m,p,r,t,k]=[m,q%7,3,0,0,0]|let o=max(map(O[c][0]+[],"b[3+v:val]"))'
let H=repeat('═',20)
let[q,m,s,l,o]=[0,0,0,0,0]
wh !o
let e=input('')
if q
if e==9
q!
en
if e!~'\d'
con
en
let t=(t+!e)%max([1,10-l/10])
if e>5||!e*t
con
en
let[U,n]=[(r+(e==3))%4,0]
for d in [[12],[-1],[1],[0,-1,1,-2,2],[12],repeat([12],20)][e]
if !n&&!max(map(O[c][U]+[],'b[p+d+v:val]'))
let[p,r,n]=[p+d,U,e<5]
en
endfo
if d>9&&!n
for v in O[c][r]
let b[p+v]=c+1
endfo
for y in range(20)
if min(b[y*12:y*12+9])
unl b[y*12:y*12+11]
let b=Z+b
let k+=1
en
endfo
let s+=[0,40,100,300,1200][k]*(l/10+1)
let l+=k
exe S
en
el
let q=e
exe S
exe S
en
let P=split(substitute('   `60╭──` `244next` `60'.repeat('─',6).'╮`;;;;;;;   `60╰'.repeat('─',14).'╯`;;   `244score`;   [1m'.s.'[m;   `244level` [1m'.(l/10+1).'[m  `244lines` [1m'.l.'[m;;   `244controls`;← a,move left;→ d,move right;↑ w,rotate;↓ s,soft drop;␣ z,hard drop;  q,quit','\v([^,;]*),([^;]*)','   [1m\1[m  `244\2`','g'),';')
let f='[H  [1;38;5;75mV I M T R I S[m[K `60╔'.H.'╗`[K'
for y in range(20)
let f.=' `60║`'.(o&&y==9?'[1;7m     GAME  OVER     [m':join(map(b[y*12:y*12+9],'C[o||index(O[c][r],y*12+v:key-p)<0?v:val:c+1]'),'')).'`60║`'.(y&&y<7?'   `60│`   '.join(map(range(4),'index(O[m][0],y*12+v:val-24)<0?"  ":C[m+1]'),'').'   `60│`':P[y]).'[K'
endfo
cal writefile(split(substitute(f.' `60╚'.H.'╝`[K[J','\v`(\d*)([^`]*)`','[38;5;\1m\2[m','g'),'\[K\zs'),'/dev/fd/1','abS')
endw
q!
