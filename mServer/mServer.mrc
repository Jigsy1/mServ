; mServer - Example of linking to an ircu based IRCd in mIRC.
;
; This script will not work unless you have a C:line[1] on a ircu based IRCd. (E.g. http://ircd.bircd.org/)
;
; Example commands:
; --------------------
; /mServer.sraw P #channel :Hello! - Makes the server itself say "Hello!" in #channel.
; /mServer.sraw M #channel +v ATAAx - Gives a +v to the user who has the numeric of ATAAx[2] on #channel.
;
; //mServer.sraw N FBI 1 $ctime noreply fbi.gov +di $inttobase64($longip(127.0.0.1),6) $+($inttobase64($mServer.numeric,2),$inttobase64(0,3)) :FBI
;
; ...will create the user FBI!noreply@fbi.gov with usermodes +di and an ip of 127.0.0.1 (B]AAAB) as user APAAA[3] on mServer's server.
; NOTE: Creating APAAA on top of APAAA will result in a SQUIT, so you might want to keep track of who has been created.
;
; /mServer.raw APAAA J #channel - Will make our newly created "FBI" user join #channel.
; /mServer.sraw J #channel - Will cause the server to SQUIT because servers cannot join channels. :P
;
; Further reading: http://ircd.bircd.org/bewarep10.txt

alias mServer.numeric { return 15 }
alias -l mServer.password { return changeme }
alias -l mServer.port { return 4400 }
alias -l mServer.server { return localhost }
alias -l mServer.serverName { return passionlip.localhost }

on *:sockopen:mServer:{
  if ($sockerr == 0) {
    var %this.numeric = $inttobase64($mServer.numeric,2)
    mServer.raw PASS $+(:,$mServer.password)
    mServer.raw SERVER $mServer.serverName 1 $ctime $ctime J10 $+(%this.numeric,]]]) :mSL IRC Server
    ; |-> J10 here, not P10 as we're joining the server. ]]] means the maximum number of users allowed. (262,143) - No flags are used here, but +s would mean Services.
    ; `-> SERVER <our server name> <hop count> <connection time> <link time> <protocol> <our server numeric><max users as numeric> [+flags] :<description>
    mServer.raw %this.numeric EB
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
      ; <server numeric> G [:]<args>
      mServer.sraw Z $3-
      ; `-> PING/PONG.
    }
  }
}

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
  var %echo = !echo $+(-ac,$iif($active == Status Window,e)) "Info text" * /mServer:
  if ($sock(mServer) == $null) {
    sockopen mServer $mServer.server $mServer.port
  }
  else { %e already running }
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

; Footnotes:
; ----------
; [1]: C:127.0.0.1:changeme:passionlip.localhost::15 in a ircd.conf
; [2]: Example only. Factors like the main server's numeric (AA, AB, etc.) will change this. (AAAAx, ABAAx, ACAAx, etc.)
;      You'll be able to tell what the main server's numeric is from B information on linking. (Or doing /map.)
; [3]: This is assuming you don't fiddle with the numeric number above.
;
; EOF
