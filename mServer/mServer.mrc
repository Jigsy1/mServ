; mServer - an example of linking to an ircu based IRCd in mIRC.
;
; This script will not work unless you have a C:line[1] on an ircu based IRCd. (E.g. http://ircd.bircd.org/)
;
; Example commands:
; --------------------
; /mServer.sraw P #channel :Hello! - Makes the server itself say "Hello!" in #channel.
; /mServer.sraw M #channel +v ATAAx - Gives a +v to the user who has the numeric of ATAAx[2] on #channel.
;
; //mServer.sraw N FBI 1 $ctime noreply fbi.gov +iko $inttobase64($longip(127.0.0.1),6) $+($inttobase64($mServer.numeric,2),$inttobase64(0,3)) :FBI
;
; ...will create the user FBI!noreply@fbi.gov with usermodes +iko and an ip of 127.0.0.1 (B]AAAB) as user APAAA[3] on mServer's server.
; NOTE: Creating APAAA on top of APAAA will[4] result in a SQUIT, so you might want to keep track of who has been created.
;
; /mServer.raw APAAA J #channel - Will make our newly created "FBI" user join #channel.
; /mServer.sraw J #channel - Will cause the server to SQUIT because servers cannot join channels. :P
; /mServer.sraw I FBI #channel - Will also cause the server to SQUIT because servers cannot invite users.[5]
;
; Further reading:
; --------------------
; 1. [P10]:  http://ircd.bircd.org/bewarep10.txt (recommended)
; 2. [P10]:  https://web.archive.org/web/20100209040721/http://www.xs4all.nl/~carlo17/irc/P10.html
; 3. [Raws]: https://modern.ircdocs.horse/index.html
; 4. [P10]:  http://web.mit.edu/klmitch/Sipb/devel/src/ircu2.10.11/doc/p10.html (incomplete)

; "Settings"

alias mServer.flags { return +s }
; `-> Append flags - which in this case is basically just +s or +6 (or both) - with +.
alias mServer.info { return A jupe server for ircu's P10 protocol written in mSL. }
alias mServer.numeric { return 0 }
; `-> Limited between 0 and 4095.
alias -l mServer.password { return changeme }
; `-> Plaintext password.
alias -l mServer.port { return 4400 }
alias -l mServer.server { return localhost }
alias -l mServer.serverName { return changeme.localhost }

; Core

on *:sockclose:mServer:{
  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [C]: $sockname closed }
}
on *:sockopen:mServer:{
  if ($sockerr > 0) {
    if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [E]: failed to open $sockname }
    return
  }
  var %this.numeric = $inttobase64($mServer.numeric,2)
  mServer.raw PASS $+(:,$mServer.password))
  ; `-> PASS must _ALWAYS_ come first.
  mServer.raw SERVER $mServer.serverName 1 $ctime $ctime J10 $+(%this.numeric,]]]) $mServer.flags $+(:,$mServer.info)
  ; ¦-> SERVER <our server name> <hop count> <connection time> <link time> <protocol> <our server numeric><max users as numeric> [+flags] :<description>
  ; ¦-> We're joining the server, so we use J10 here, not P10. And ]]] means the maximum number of users allowed. (262,143)
  ; `-> No flags are used here, but +s would mean Services. E.g. ... J10 AS]]] +s :Services
  mServer.raw %this.numeric EB
  ; `-> END_OF_BURST
}
on *:sockread:mServer:{
  var %mServer.sockRead = $null
  sockread %mServer.sockRead
  tokenize 32 %mServer.sockRead

  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [R]: $1- }
  if ($sockerr > 0) {
    sockclose $sockname
    return
  }
  if ($istok(F INFO,$2,32) == $true) {
    ; <numeric> F <server numeric>
    mServer.sraw 371 $1 $+(:,$mServer.serverName)
    mServer.sraw 371 $1 $+(:,$mServer.info)
    mServer.sraw 374 $1 :End of /INFO list.
    return
  }
  if ($istok(G PING,$2,32) == $true) {
    ; <server numeric> G [:]<arg>
    mServer.sraw Z $3-
    ; `-> PING/PONG. (Saying PONG instead of Z should also work; but let's leave it alone.)
    return
  }
  if ($istok(MO MOTD,$2,32) == $true) {
    ; <numeric> MO <server numeric>
    mServer.sraw 422 $1 :MOTD File is missing
    return
  }
  if ($istok(TI TIME,$2,32) == $true) {
    ; <numeric> TI <server numeric>
    mServer.sraw 391 $1 $mServer.serverName $ctime 0 $+(:,$asctime($ctime,dddd mmmm dd yyyy -- HH:nn:ss))
    ; `-> 0 is offset. I don't know what to put here, so I'm leaving it as zero.
    return
  }
}
; ¦-> Technically I'd make this more compact - like checking if the command exists - but INFO, MOTD and TIME are merely demonstrations.
; ¦-> These are called via the token - F instead of INFO, for example - but if the server were to use the full name, it will work.
; |-> E.g. /mServer.sraw INFO <the numeric of the server you're connected to>
; `-> If you wish to test them, do: /COMMAND this.server - E.g. /INFO this.server
on *:unload:{ sockclose mServer }

; mServer Functions

alias mServer.raw {
  ; /mServer.raw <args>

  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [W]: $1- }
  if ($sock(mServer) != $null) { sockwrite -nt mServer $1- }
}
alias mServer.sraw {
  ; /mServer.sraw <args>

  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [W]: $inttobase64($mServer.numeric,2) $1- }
  if ($sock(mServer) != $null) { sockwrite -nt mServer $inttobase64($mServer.numeric,2) $1- }
}
alias mServer.start {
  ; /mServer.start

  var %echo = !echo $+(-ac,$iif($active == Status Window,e)) "Info text" * /mServer.start:
  if ($sock(mServer) != $null) {
    %echo server is already running
    return
  }
  sockopen mServer $mServer.server $mServer.port
  %echo done
}
alias mServer.stop {
  ; /mServer.stop

  var %echo = !echo $+(-ac,$iif($active == Status Window,e)) "Info text" * /mServer.stop:
  if ($sock(mServer) == $null) {
    %echo server is not running
    return
  }
  sockclose $v1
  %echo done
}
alias -l mServer.window { return @mServer }

; Server Functions

alias base64toint {
  ; $base64toint(<N>)
  var %o = 0, %x = 1
  while ($mid($1,%x,1) != $null) { 
    var %o = $calc(%o * 64)
    var %o = $calc(%o + $i($v1))
    inc %x
  }
  return %o
}
alias -l i { return $calc($poscs(ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[],$1)-1) }
alias -l ii { return $mid(ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[],$calc($int($1) + 1),1) }
alias inttobase64 {
  ; $inttobase64(<N>,<pad to N chars>)
  var %c = $2, %o, %v = $1
  while (%c) {
    var %o = $+($ii($and(%v,63)),%o)
    var %v = $calc(%v / 64) 
    dec %c
  }
  return %o
}
; [6]

; Footnotes:
; ----------
; [1]: C:127.0.0.1:changeme:passionlip.localhost::971 in an ircd.conf
; [2]: Example only. Factors like the main servers numeric (AA, AB, etc.) will change this. (AAAAx, ABAAx, ACAAx, etc.)
;      You'll be able to tell what the main servers numeric is from B information on linking. (Or hopefully doing /map.)
; [3]: This is assuming you don't fiddle with the numeric number above.
; [4]: APAAA on top of APAAA will result in a numeric collision (thus SQUIT). However, making "APAAA Q :Quit" first is fine.
; [5]: I honestly fail to see how a server inviting a user to a channel is a problem. (They can change modes, kick users, talk...
;      ...so why can't they invite?)
; [6]: Thanks to Dave (Codex` / Hero_Number_Zero) for once sharing the numeric/P10 conversion code with me nearly a decade ago.
;
; EOF
