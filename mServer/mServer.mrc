; mServer - an example of linking to an ircu based IRCd in mIRC
;
; This script will not work unless you have a C:line[1] on a ircu based IRCd. (E.g. http://ircd.bircd.org/)
;
; Example commands:
; --------------------
; /mServer.sraw P #channel :Hello! - Makes the server itself say "Hello!" in #channel.
; /mServer.sraw M #channel +v ATAAx - Gives a +v to the user who has the numeric of ATAAx[2] on #channel.
;
; //mServer.sraw N FBI 1 $ctime noreply fbi.gov +iko $inttobase64($longip(127.0.0.1),6) $+($inttobase64($mServer.numeric,2),$inttobase64(0,3)) :FBI
;
; ...will create the user FBI!noreply@fbi.gov with usermodes +iko and an ip of 127.0.0.1 (B]AAAB) as user APAAA[3] on mServer's server.
; NOTE: Creating APAAA on top of APAAA might[4] result in a SQUIT, so you might want to keep track of who has been created.
;
; /mServer.raw APAAA J #channel - Will make our newly created "FBI" user join #channel.
; /mServer.sraw J #channel - Will cause the server to SQUIT because servers cannot join channels. :P
;
; Further reading:
; --------------------
; 1. http://web.mit.edu/klmitch/Sipb/devel/src/ircu2.10.11/doc/p10.html (incomplete)
; 2. http://ircd.bircd.org/bewarep10.txt (recommended)

alias mServer.numeric { return 15 }
alias -l mServer.password { return changeme }
; `-> Plaintext password.
alias -l mServer.port { return 4400 }
alias -l mServer.server { return localhost }
alias -l mServer.serverName { return passionlip.localhost }

on *:sockclose:mServer:{
  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [C]: $sockname closed }
}
on *:sockopen:mServer:{
  if ($sockerr == 0) {
    var %this.numeric = $inttobase64($mServer.numeric,2)
    mServer.raw PASS $colonize($mServer.password))
    ; `-> PASS must _ALWAYS_ come first.
    mServer.raw SERVER $mServer.serverName 1 $ctime $ctime J10 $+(%this.numeric,]]]) :mSL IRC Server
    ; |-> We're joining the server, so we use J10 here, not P10. ]]] means the maximum number of users allowed. (262,143)
    ; |-> No flags are used here, but +s would mean Services. E.g. AS]]] +s :Services
    ; `-> SERVER <our server name> <hop count> <connection time> <link time> <protocol> <our server numeric><max users as numeric> [+flags] :<description>
    mServer.raw %this.numeric EB
    ; `-> END_OF_BURST.
  }
  else {
    if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [E]: failed to open $sockname }
  }
}
on *:sockread:mServer:{
  var %mServer.sockRead = $null
  sockread %mServer.sockRead
  tokenize 32 %mServer.sockRead

  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [R]: $1- }
  if ($sockerr > 0) { sockclose $sockname }
  else {
    if ($2 == G) {
      ; <server numeric> G [:]<arg>
      mServer.sraw Z $3-
      ; `-> PING/PONG. (Saying PONG instead of Z should also work; but let's leave it alone.)
    }
  }
}
on *:unload:{ sockclose mServer }

; mServer Functions

alias mServer.raw {
  ; /mServer.raw <args>

  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [W]: $1- }
  sockwrite -nt mServer $1-
}
alias mServer.sraw {
  ; /mServer.sraw <args>

  if ($window($mServer.window) != $null) { echo -ci2t "Info text" $v1 [W]: $inttobase64($mServer.numeric,2) $1- }
  sockwrite -nt mServer $inttobase64($mServer.numeric,2) $1-
}
alias mServer.start {
  ; /mServer.start

  var %echo = !echo $+(-ac,$iif($active == Status Window,e)) "Info text" * /mServer.start:
  if ($sock(mServer) == $null) {
    sockopen mServer $mServer.server $mServer.port
    %echo done
  }
  else { %echo server is already running }
}
alias mServer.stop {
  ; /mServer.stop

  var %echo = !echo $+(-ac,$iif($active == Status Window,e)) "Info text" * /mServer.stop:
  if ($sock(mServer) != $null) {
    sockclose $v1
    %echo done
  }
  else { %echo server is not running }
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
alias colonize { return $iif($left($1-,1) != :,$+(:,$1-),$1-) }
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
; [5]

; Footnotes:
; ----------
; [1]: C:127.0.0.1:changeme:passionlip.localhost::15 in an ircd.conf
; [2]: Example only. Factors like the main server's numeric (AA, AB, etc.) will change this. (AAAAx, ABAAx, ACAAx, etc.)
;      You'll be able to tell what the main server's numeric is from B information on linking. (Or hopefully doing /map.)
; [3]: This is assuming you don't fiddle with the numeric number above.
; [4]: I could be wrong about this. It's been over a decade since I last played around with P10 that I actually need to check this.
; [5]: Thanks for Hero_Number_Zero (Dave) for once sharing the numeric/P10 conversion code with me nearly a decade ago.
;
; EOF
