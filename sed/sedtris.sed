#!/usr/bin/sed -nf
# sedtris.sed - sed tetris
# 26th of May, 2008
# Julia Jomantaite <julia.jomantaite@gmail.com>
1{
s/.*/ 2a2a2a2a|3a3a3a3a3a3a3a3a3a3a|2a2a2a2a~/
s/[^~]*~$/&&&/
s/.*/& 2a2a2a2a|0a0a0a0a0a0a0a0a0a0a|2a2a2a2a~/
s/[^~]*~$/&&&&&&&&&&&&&&&&&&&&/
s// 2a2a2a2a|4a4a4a4a4a4a4a4a4a4a|2a2a2a2a~/
s/[^~]*~$/&&&/ 
s/.*/~&/
s/$/#....,,,~/
s/$/#AAAA AAAA APPA APPA~/
s/$/#AAAA ANAA LPOA AHAA~/
s/$/#AAAA BKIA FPFA CKEA~/
s/$/#AAAA EDCA GPJA IMBA~/
s/$/#ACIA EGME BDJB ACIA~/
s/$/#AAAA IKEA FPFA BKCA~/
s/$/#AAAA CGBA MPDA EJIA~/
s/$/#NEXTAAAA ANAA LPOA AHAA 5~/
s/$/#SCORE0~/
h
b display
}

/1/{s/1//;x;s/#\.\.*/&./;s/#\.\{8\}/#./;x;}

/^w/b rotate
/^a/b left
/^d/b right
/^s/b nothing
/^\[A/b rotate
/^\[D/b left
/^\[C/b right
/^\[B/b nothing
/^$/b nothing
/^[z ]/{
g 
s/#\.*/&.../
s/#\.\{8\}/#./ 
s/$/#FALL~/
h
b nothing
}
b display

:rotate
g
s/#\.*/&./
s/#\.\{8\}/#./  
/[14-9x][e-h]/! {/2[e-h]/!y/abcdefghijklmnop/acegikmobdfhjlnp/;}
h
b display

:left
g
s/#\.*/&../
s/#\.\{8\}/#./  
/|[0-9x][i-p]/! {/[14-9x][a-p][0-9x][i-p]/! {
s/\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1\4\2\3a/g
s/\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1\2\3\6\4\5a/g
s/\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1\2\3\6\4\5a/g
s/\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1\2\3\6\4\5a/g
};}
h
b display

:right
g
s/#\.*/&./
s/#\.\{8\}/#./  
/[i-p]|/! {/[i-p][14-9x]/!{
s/\([0-9x]\)\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a/\1a\3\4\2/g
s/\([0-9x]\)\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1a\3\4\2\5\6\7/g
s/\([0-9x]\)\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1a\3\4\2\5\6\7/g
s/\([0-9x]\)\([b-p]\)\(|\{0,1\}\)\([0-9x]\)a\(|\{0,1\}\)\([0-9x]\)\([b-p]\)/\1a\3\4\2\5\6\7/g
};};
h
b display

:nothing
g

#New brick 
/~ \(2a\)*|\([15-9x]a\)*|\(2a\)*~/! {
/[b-p]/! {
#Set % before all 4-letter "words"
t e
:e
s/\(#NEXT\(\( \)\{0,1\}%[A-P]\)*\)\( \)\{0,1\}\([A-P]\)/\1\4%\5/
t e

#Set @ before probable new letters
s/^\(~[^~]*~[^~]*~.\{17\}\)\(..\)\(..\)\(..\)\(..\)/\1@\2@\3@\4@\5/
s/^\(~[^~]*~[^~]*~[^~]*~.\{17\}\)\(..\)\(..\)\(..\)\(..\)/\1@\2@\3@\4@\5/
t blank2
:blank2
/#NEXT\([^%]*%\)\{13\}[A-H]%[A-H]%[A-H]%[A-H]/{
s/^\(~[^~]*~[^~]*~[^~]*~[^~]*~.\{17\}\)\(..\)\(..\)\(..\)\(..\)/\1@\2@\3@\4@\5/
/#NEXT\([^%]*%\)\{9\}[A-H]%[A-H]%[A-H]%[A-H]/{
s/^\(~[^~]*~[^~]*~[^~]*~[^~]*~[^~]*~.\{17\}\)\(..\)\(..\)\(..\)\(..\)/\1@\2@\3@\4@\5/
b v2
}
b v1
}
s/^\(~.\{17\}\)\(..\)\(..\)\(..\)\(..\)/\1@\2@\3@\4@\5/
:v1
s/^\(~[^~]*~.\{17\}\)\(..\)\(..\)\(..\)\(..\)/\1@\2@\3@\4@\5/
:v2

#Add real new letters (capital)
t f
:f
/^\([^@]*\)[15-9x]@.\([^%]*\)%[I-P]/s/$/#OVER~/
s/^\([^@]*\)@.\([^%]*\)%\([A-P]\)/\1\3\2\3/
t f

#Decapitalization
h
s/^\(~[^~]*\)\{6\}~//
x
s/^\(\(~[^~]*\)\{6\}\)\(.*\)$/\1/
y/ABCDEFGHIJKLMNOP/abcdefghijklmnop/
x
H
#Add "Current"
g
s/\n/~/
s/#CURRENT.~//g
s/\(#NEXT[^~]*\)\([0-9x]\)\(.*\)$/\1\2\3#CURRENT\2~/ 

#Add NEXT
:g
/\./{
s/#/$/
s/\./@/
b g
}
s/@/./g 
s/^\([^#]*\)#\([^~]*\)\(.*\)\(#NEXT[^~]*\)/\1#\2\3#NEXT\2/

s/\([^.]\)\(\.\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 1/
s/\([^.]\)\(\.\{2\}\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 5/
s/\([^.]\)\(\.\{3\}\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 6/ 
s/\([^.]\)\(\.\{4\}\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 7/ 
s/\([^.]\)\(\.\{5\}\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 8/ 
s/\([^.]\)\(\.\{6\}\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 9/ 
s/\([^.]\)\(\.\{7\}\)\([^.]*\)\(#NEXT[^~]*\)/\1\2\3\4 x/
s/\$/#/g

h
s/\(,*\)\([^,]*#NEXT[^~]*\)/\1\2\1/
s/.*#NEXT\([^~]*\)~.*/\1/

:g2
/,/{
s/\,/@/
y/ABCDEFGHIJKLMNOP/ACEGIKMOBDFHJLNP/
b g2
}
s/@//g
H
g
s/\n/~/
s/\(#NEXT\)[^~]*\(~.*\)~\([^~]*\)$/\1\3\2/
h
b display
};};

#Eat that line
t d
:d
/~ \(2a\)*|\([15-9x]a\)*|\(2a\)*~/ {
s/~ \(2a\)*|\([15-9x]a\)*|\(2a\)*//
s/^~\([^~]*~\)\{3\}/& 2a2a2a2a|0a0a0a0a0a0a0a0a0a0a|2a2a2a2a~/
s/#SCORE[^~]*/&A/
b d
}
#Scoring
/#SCORE[^~]*A/{
s/\(#SCORE[^~]*\)AAAA/\1+1200z/
s/\(#SCORE[^~]*\)AAA/\1+300z/
s/\(#SCORE[^~]*\)AA/\1+100z/
s/\(#SCORE[^~]*\)A/\1+40z/

/#SCORE[0-9]*+[0-9]*z/{
s/+/@+/
:finnul
/0z/{
/#SCORE@/b endsum
s/\(.\)@/@\1/
s/0z/z/
/+z/b endsum
b finnul
}
t incr
:incr
s/9\(%*\)@/%\1@/
t incr
s/#SCORE\(%*\)@/#SCORE0\1@/
s/8\(%*\)@/9\1@/
s/7\(%*\)@/8\1@/
s/6\(%*\)@/7\1@/
s/5\(%*\)@/6\1@/
s/4\(%*\)@/5\1@/
s/3\(%*\)@/4\1@/
s/2\(%*\)@/3\1@/
s/1\(%*\)@/2\1@/
s/0\(%*\)@/1\1@/
s/%/0/g
t blank
:blank
s/9z/8z/
t incr
s/8z/7z/
t incr
s/7z/6z/
t incr
s/6z/5z/
t incr
s/5z/4z/
t incr
s/4z/3z/
t incr
s/3z/2z/
t incr
s/2z/1z/
t incr
s/1z/0z/
t finnul
:endsum
s/@//
s/#SCORE\([0-9]*\)+\([0-9]*\)z/#SCORE\2\1/
}
h
b display
}

#Falling down
:fall
/~[^~]*[03][i-p].\{38\}[14-9x]/! {
:c
#Find the lowest line with the...
s/\(~[^~]*[b-p][^~]*\)~\([^b-p~]*~\)/\1z\2/
s/~\([^~b-p]*\)\([b-p]\)\([^~]\{39\}\)[a-p]/~\1a\3\2/
s/~\([^~b-p]*\)\([b-p]\)\([^~]\{39\}\)[a-p]/~\1a\3\2/
s/~\([^~b-p]*\)\([b-p]\)\([^~]\{39\}\)[a-p]/~\1a\3\2/
s/~\([^~b-p]*\)\([b-p]\)\([^~]\{39\}\)[a-p]/~\1a\3\2/
s/z/~/
/[^~]*[b-p][^~]*~[^~b-p]*~[^~]*[b-p][^~]*/b c
/#FALL~$/b fall
h
b display
}
s/#FALL~//g

#Freezing
s/0[b-h]/0a/g
t i
:i
s/\(0[i-p]\)\(.*#CURRENT\)\(.\)/\3a\2\3/
t i

s/\([15-9x]\)[b-p]/\1a/g
s/2[b-p]/2a/g
s/3[b-h]/3a/g
s/4[b-p]/4a/g

#if it's over
/3[i-p]/ s/$/#OVER~/
/[15-9x][i-p]/{
s/\([15-9x]\)\([i-p]\)/\1a/g
s/$/#OVER~/
}
h

#Display
:display
g
s/#\.*/&./
s/#\.\{8\}/#./
s/,\{1,\}/&,/
s/,\{5\}/,/ 
s/#FALL~//g
h

#Everything below works on a throwaway copy of the state: presentation only.
#Cells are first turned into one-byte placeholders, expanded to colour at the end:
#  .=empty  {=O  }=T  <=J  >=S  !=I  ==L  %=Z  _/*=next piece  @=game over
s/^~/~ (~/
s/~[^~]*~$/& )/
s/~[^~]*|[^~]*3[^~]*//g
s/~[^~]*|[^~]*4[^~]*//g
s/2[a-h]//g
s/\([15-9x]\)[i-p]/\1a/g

/#OVER/s/^\(\(~[^~]*\)\{10\}~\)\([^~]*~\)/\1 |@|~/

/#CURRENT1/s/0[i-p]/{/g
/#CURRENT5/s/0[i-p]/}/g
/#CURRENT6/s/0[i-p]/</g
/#CURRENT7/s/0[i-p]/>/g
/#CURRENT8/s/0[i-p]/!/g
/#CURRENT9/s/0[i-p]/=/g
/#CURRENTx/s/0[i-p]/%/g
s/0[a-h]/./g
s/1[a-h]/{/g
s/5[a-h]/}/g
s/6[a-h]/</g
s/7[a-h]/>/g
s/8[a-h]/!/g
s/9[a-h]/=/g
s/x[a-h]/%/g

#Next piece: _ = empty, * = filled; keep the 4x4 grid, drop an empty top row
:decap
/#NEXT[^~]*[A-P]/{
s/\(#NEXT[^~]*\)[A-H]/\1_/
s/\(#NEXT[^~]*\)[I-P]/\1*/
b decap
}
s/#NEXT____ \([^ ~]* [^ ~]* [^ ~]*\) /#NEXT\1 ____ /
/#NEXT[^~]* 1~/y/*/{/
/#NEXT[^~]* 5~/y/*/}/
/#NEXT[^~]* 6~/y/*/</
/#NEXT[^~]* 7~/y/*/>/
/#NEXT[^~]* 8~/y/*/!/
/#NEXT[^~]* 9~/y/*/=/
/#NEXT[^~]* x~/y/*/%/

#Side panel
s/^\(\(~[^~]*\)\{2\}\)/\1   [38;5;60m╭──[m [38;5;244mnext[m [38;5;60m──────╮[m/
s/^\(\(~[^~]*\)\{3\}\)/\1   [38;5;60m│[m              [38;5;60m│[m/
s/^\(\(~[^~]*\)\{4\}\)\(.*\)\(#NEXT\([^ ~]*\)\)/\1   [38;5;60m│[m   \5   [38;5;60m│[m\3\4/
s/^\(\(~[^~]*\)\{5\}\)\(.*\)\(#NEXT\([^ ~]* \)\{1\}\([^ ~]*\)\)/\1   [38;5;60m│[m   \6   [38;5;60m│[m\3\4/
s/^\(\(~[^~]*\)\{6\}\)\(.*\)\(#NEXT\([^ ~]* \)\{2\}\([^ ~]*\)\)/\1   [38;5;60m│[m   \6   [38;5;60m│[m\3\4/
s/^\(\(~[^~]*\)\{7\}\)\(.*\)\(#NEXT\([^ ~]* \)\{3\}\([^ ~]*\)\)/\1   [38;5;60m│[m   \6   [38;5;60m│[m\3\4/
s/^\(\(~[^~]*\)\{8\}\)/\1   [38;5;60m│[m              [38;5;60m│[m/
s/^\(\(~[^~]*\)\{9\}\)/\1   [38;5;60m╰──────────────╯[m/
s/^\(\(~[^~]*\)\{11\}\)/\1   [38;5;244mscore[m/
s/^\(\(~[^~]*\)\{12\}\)\(.*\)\(#SCORE\([^~]*\)\)/\1   [1m\5[m\3\4/
s/^\(\(~[^~]*\)\{14\}\)/\1   [38;5;244mcontrols[m/
s/^\(\(~[^~]*\)\{15\}\)/\1   [1m← a[m  [38;5;244mmove left[m/
s/^\(\(~[^~]*\)\{16\}\)/\1   [1m→ d[m  [38;5;244mmove right[m/
s/^\(\(~[^~]*\)\{17\}\)/\1   [1m↑ w[m  [38;5;244mrotate[m/
s/^\(\(~[^~]*\)\{18\}\)/\1   [1m↓ s[m  [38;5;244msoft drop[m/
s/^\(\(~[^~]*\)\{19\}\)/\1   [1m␣ z[m  [38;5;244mhard drop[m/

#uncomment the line below to switch colours off (blocks stay visible)
#s/\[\([0-9]*;\)*[0-9]*m//g
s/#[^~]*~//g

#Expand placeholders
s/|/[38;5;60m║[m/g
s/(/[38;5;60m╔════════════════════╗[m/
s/)/[38;5;60m╚════════════════════╝[m/
s/\./[38;5;237m ·[m/g
s/_/  /g
s/{/[38;5;226m██[m/g
s/}/[38;5;135m██[m/g
s/</[38;5;33m██[m/g
s/>/[38;5;46m██[m/g
s/!/[38;5;51m██[m/g
s/=/[38;5;208m██[m/g
s/%/[38;5;196m██[m/g
s/@/[1;7m     GAME  OVER     [m/

s/^~/~  [1m[38;5;75mS E D T R I S[m~/
s/^~//
s/~/[K\
/g
s/$/[K[J/
i\
[H
p
/GAME  OVER/q
