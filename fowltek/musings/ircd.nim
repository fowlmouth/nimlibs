
import asyncio,  sockets
import strutils  ,tables
import macros,re, hashes
import fowltek/macro_dsl
import        parseutils
import     ircd_hostname

{.deadCodeElim: ON.}
proc hash (some: PAsyncSocket): THash = cast[pointer](some).hash
proc `$`  (some: PAsyncSocket): string = 
  result = "0x"
  result.add(toHex(cast[int](some), 8))
proc `$`[A](some: seq[A]): string =
  result = "["
  let highest = len(some)-1
  for i in 0 .. highest:
    result.add($ some[i])
    if i < highest: result.add ", "
  result.add ']'
  

#http://www.rfc-editor.org/rfc/rfc2812.txt
#http://www.rfc-editor.org/rfc/rfc1459.txt

const
  VersionStr = "Ðiesnuz-1.0"

type
  TNumeric = enum ##in rfc order
    RPL_WELCOME = "001", RPL_YOURHOST= "002", RPL_CREATED = "003",
    RPL_MYINFO  = "004", RPL_BOUNCE  = "005", RPL_USERHOST= "302",
    RPL_ISON    = "303", RPL_AWAY    = "304", RPL_UNAWAY  = "305",
    RPL_NOWAWAY = "306", RPL_WHOISUSER="311", RPL_WHOISSERVER="312",
    RPL_WHOISOPERATOR="313", RPL_WHOISIDLE="317", RPL_ENDOFWHOIS="318",
    RPL_WHOISCHANNELS="319", RPL_WHOWASUSER="314", RPL_ENDOFWHOWAS="369",
    RPL_LISTSTART = "321", RPL_LIST = "322", RPL_LISTEND = "323",
    RPL_UNIQOPIS = "325",
    RPL_CHANNELMODEIS = "324",
    RPL_NOTOPIC = "331",
    RPL_TOPIC = "332",
    RPL_INVITING = "341",
    RPL_SUMMONING= "342",
    RPL_INVITELIST="346",
    RPL_ENDOFINVITELIST="347",
    RPL_EXCEPTLIST = "348",
    RPL_ENDOFEXCEPTLIST = "349",
    RPL_VERSION = "351",
    RPL_WHOREPLY = "352",
    RPL_ENDOFWHO = "315",
    RPL_NAMEREPLY = "353",
    RPL_ENDOFNAMES = "366",
    RPL_LINKS = "364",
    RPL_ENDOFLINKS = "365",
    RPL_BANLIST = "367",
    RPL_ENDOFBANLIST = "368",
    RPL_INFO = "371",
    RPL_ENDOFINFO = "374",
    RPL_MOTDSTART = "375",
    RPL_MOTD = "372",
    RPL_ENDOFMOTD = "376",
    RPL_YOUREOPER = "381",
    RPL_REHASHING = "382",
    RPL_YOURESERVER = "383",
    RPL_TIME = "391",
    RPL_USERSSTART = "392",
    RPL_USERS = "393",
    RPL_ENDOFUSERS = "394",
    RPL_NOUSERS = "395",
    RPL_TRACELINK = "200",
    RPL_TRACECONNECTING = "201",
    RPL_TRACEHANDSHAKE = "202",
    RPL_TRACEUNKNOWN = "203",
    RPL_TRACEOPERATOR = "204",
    RPL_TRACEUSER = "205",
    RPL_TRACESERVER = "206",
    RPL_TRACESERVICE = "207",
    RPL_TRACENEWTYPE = "208",
    RPL_TRACECLASS = "209",
    RPL_TRACERECONNECT = "210",
    RPL_TRACELOG = "261",
    RPL_TRACEEND = "262",
    RPL_STATSLINKINFO = "211", RPL_STATSCOMMAND = "212", RPL_ENDOFSTATS = "219",
    RPL_STATSOLINE = "243", RPL_UMODEIS = "221", RPL_SERVLIST = "234",
    RPL_SERVLISTEND = "235", RPL_LUSERCLIENT = "251", RPL_LUSEROP = "252",
    RPL_LUSERUNKNOWN = "253", RPL_LUSERCHANNELS = "254", RPL_LUSERME = "255",
    RPL_ADMINME = "256", RPL_ADMINLOC1 = "257", RPL_ADMINLOC2 = "258",
    RPL_ADMINEMAIL = "259", RPL_TRYAGAIN = "263",
    ERR_NOSUCHNICK = "401", ERR_NOSUCHSERVER = "402", ERR_NOSUCHCHANNEL = "403",
    ERR_CANNOTSENDTOCHAN = "404", ERR_TOOMANYCHANNELS = "405", ERR_WASNOSUCHNICK = "406",
    ERR_TOOMANYTARGETS = "407", ERR_NOSUCHSERVICE = "408", ERR_NOORIGIN = "409",
    ERR_NORECIPIENT = "411", ERR_NOTEXTTOSEND = "412", ERR_NOTOPLEVEL = "413",
    ERR_WILDTOPLEVEL = "414", ERR_BADMASK = "415", ERR_UNKNOWNCOMMAND = "421",
    ERR_NOMOTD = "422", ERR_NOADMININFO = "423", ERR_FILEERROR = "424", 
    ERR_NONICKNAMEGIVEN = "431", ERR_ERRONEUSNICKNAME = "432", ERR_NICKNAMEINUSE = "433",
    ERR_NICKCOLLISION = "436", ERR_UNAVAILRESOURCE = "437", ERR_USERNOTINCHANNEL = "441",
    ERR_NOTONCHANNEL = "442", ERR_USERONCHANNEL = "443", ERR_NOLOGIN = "444",
    ERR_SUMMONDISABLED = "445", ERR_USERDISABLED = "446", ERR_NOTREGISTERED = "451",
    ERR_NEEDMOREPARAMS = "461", ERR_ALREADYREGISTERED = "462", ERR_NOPERMFORHOST = "463",
    ERR_PASSWDMISMATCH = "464", ERR_YOURBANNEDCREEP = "465", ERR_YOUWILLBEBANNED = "466",
    ERR_KEYSET = "467", ERR_CHANNELISFULL = "471", ERR_UNKNOWNMODE = "472", 
    ERR_INVITEONLYCHAN = "473", ERR_BANNEDFROMCHAN = "474", ERR_BADCHANNELKEY = "475",
    ERR_BADCHANNELMASK = "476", ERR_NOCHANMODES = "477", ERR_BANLISTFULL = "478",
    ERR_NOPRIVILEGES = "481", ERR_CHANOPRIVSNEEDED = "482", ERR_CANTKILLSERVER = "483",
    ERR_RESTRICTED = "484", ERR_UNIQOPRIVSNEEDED = "485", ERR_NOOPERHOST = "491",
    ERR_UMODEUNKNOWNFLAG = "501", ERR_USERSDONTMATCH = "502"
    
    

  TUserMode* = enum
    UserInvisible= "i",
    UserNotices  = "s",
    UserWallops  = "w",#RFC 2812:
    UserOper     = "o" #, UserRestricted="r", UserLocalOper="O", UserAway="a"
  TChannelMode* = enum
    ChannelPrivate    = "p",
    ChannelSecret     = "s",
    ChannelInviteOnly = "i",
    ChannelTopicLocked= "t",
    ChannelNoExternal = "n",
    ChannelModerated  = "m",
    ChannelLimit      = "l",
    ChannelOp         = "o",
    ChannelVoice      = "v",
    ChannelBan        = "b",
    ChannelKey        = "k"

const
  ChannelModesWithParams = {ChannelLimit, ChannelOp, ChannelVoice, ChannelBan,
    ChannelKey}

proc allModes*[T: enum]: string {.compileTime.}=
  result = ""
  for it in items(T):
    result.add($it)
proc collectEnum*[T: enum](some: set[T]): string {.compileTime.}=
  result = ""
  for it in items(some):
    result.add($it)
const
  UserModesStr = allModes[TUserMode]()
  ChannelModesStr = allModes[TChannelMode]()
  ChannelModesWithParamsStr = collectEnum(channelModesWithParams)


type  
  PClient* = ref TClient
  TClient* = object
    nick, user, host: string
    mode: set[TUserMode]
    sock: PAsyncSocket
  
  TChannelParticipant = object
    mode: string
    client: PClient
  
  PChannel = ptr TChannel
  TChannel = object
    name, topic: string
    users: seq[TChannelParticipant]

  PServer* = ref object
    name: string
    host: string
    running: bool
    sock: PAsyncSocket
    disp: PDispatcher
    clients: TTable[PAsyncSocket, PClient]
    nicks: TTable[string, PClient]
    channels: TTable[string, TChannel]


proc getClient (serv: PServer; sock: PAsyncSocket): PClient = serv.clients[sock]
proc findClient(serv: PServer; nick: string): tuple[found: bool; client: PClient] =
  for n, c in serv.nicks.mpairs:
    if cmpIgnoreCase(n, nick) == 0:
      return (true, c)
  return (false, nil)

proc findChannel(serv: PServer; chan: string): tuple[found: bool; chan: PChannel] =
  for n, c in serv.channels.mpairs:
    if cmpIgnoreCase(n, chan) == 0:
      return (true, c.addr)
  return (false, nil)

proc drop* (chan: PChannel; client: PClient) =
  for i in 0..high(chan.users):
    if chan.users[i].client == client:
      chan.users.del i
      break
proc drop* (serv: PServer; client: PClient) =
  for v in mvalues(serv.channels):
    v.addr.drop client
  
  client.sock.close
  if not client.nick.isNil:
    serv.nicks.del client.nick
  serv.clients.del client.sock

proc fullHost(client: PClient): string = "$#!$#@$#".format(
  client.nick, client.user, client.host)

template debugIncoming(L): stmt =
  when defined(Debug):
    echo ">> ", L
template debugOutgoing(L): stmt =
  when defined(Debug):
    echo "<< ", L
    
proc sendLine* (client: PClient; line: string) {.inline.} =
  client.sock.send line
  client.sock.send "\c\L"
  debugOutgoing line
  
proc send* (client: PClient; str: varargs[string]){.inline.}=
  for s in str:
    client.sock.send s
  client.sock.send "\c\L"
   
proc serverNotice* (client: PClient; msg: string) =
  client.send "NOTICE * :", msg

proc parseCommand(cmd: string): tuple[prefix, command: string, args: seq[string]]=
  const whitespace = {' ','\t'}
  var i = 0
  
  if cmd[i] == ':':
    inc i
    inc i, cmd.parseUntil(result.prefix, whitespace, i)
    inc i
  else:
    result.prefix = ""
  inc i, cmd.parseUntil(result.command, whitespace, i)
  
  result.args = @[]
  while cmd[i] in whitespace:
    inc i
    if cmd[i] in {':','\0'}: break
    
    result.args.setLen result.args.len+1
    inc i, cmd.parseUntil(result.args[result.args.len - 1], {' ','\t','\0'}, i)
    
  if cmd[i] == ':':
    result.args.add cmd[i+1 .. cmd.high]

when false:
  proc parseCommand(cmd: string): seq[string] =
    result = @[]
    var i = cmd.find(' ')
    result.add cmd[0 .. <i]
    inc i
    while cmd[i] notin {'\c', '\L', '\0'}:
      template last:string = result[result.high]
      if cmd[i] == ':':
        inc i
        result.add ""
        while i < cmd.len():
          last.add cmd[i]
          inc i
        break
      else:
        result.add ""
        while cmd[i] notin {' ', '\c', '\L', '\0'}:
          last.add cmd[i]
          inc i
        if cmd[i] == ' ':
          inc i

proc add* (chan: PChannel; client: PClient) =
  chan.users.add TChannelParticipant(client: client)
  echo "User ", client.nick, " joint ", chan.name

proc getChannel (serv: PServer; name: string): PChannel {.
  inline.} = serv.channels.mget(name).addr

proc sendReply (serv: PServer; client: PClient;
      prefix: string = nil; cmd: string = ""; 
      args: varargs[string]=[]; msg: string = nil){.inline.} =
  var s = ":"
  if prefix.isNil:
    s.add serv.host
  else:
    s.add prefix
  s.add ' '
  s.add(cmd)
  for arg in args:
    s.add ' '
    s.add arg
  if not msg.isNil:
    s.add " :"
    s.add msg
  client.sendLine s

proc sendNumeric (serv: PServer; client: PClient; num: TNumeric;
      prefix: string = nil; args: varargs[string]=[]; msg: string = nil){.inline.}=
  serv.sendReply(client, prefix, $num, args, msg)

proc sendTopic (serv: PServer; client: PClient; chan: PChannel) =
  if chan.topic.len == 0:
    serv.sendNumeric(client, RPL_NOTOPIC, args = chan.name, msg = "No topic is set.")
  else:
    serv.sendNumeric(client, RPL_TOPIC, args = chan.name, msg = chan.topic)
    
proc validChannelName (name: string): bool =
  if name[0] notin {'#', '&', '!'}:
    return
  var i = 1
  while i < high(name):
    if name[i] notin 33.char .. 126.char:
      return
  result = true

proc joinChan (serv: PServer; client: PClient; chan, key: string) =
  if not chan.validChannelName:
    serv.sendNumeric(client, ERR_NOSUCHCHANNEL, args = chan, msg = "No such channel '"&chan&"'")
    return
  
  var (found, c) = serv.findChannel(chan)
  if found:
    c.add client
  else:
    serv.channels[chan] = TChannel(name: chan, topic: "", users: @[])
    c = serv.getChannel(chan)
    c.add client
  
  serv.sendReply(client, cmd = "JOIN", prefix = client.fullHost(), msg = c.name)
  serv.sendTopic(client, c)

proc handleRead(serv: PServer): proc(s: PAsyncSocket){.closure.}=
  result = proc (s: PAsyncSocket) =
    let client = serv.getClient(s)
    
    var line = ""
    if s.readLine(line):
      if line.len == 0:
        serv.drop client
        return 
      
      debugIncoming line
      
      template tryToWelcome =
        if not(client.nick.isNil or client.user.isNil):
          serv.sendNumeric(client, 
            RPL_WELCOME, args = client.nick,
            msg = "Welcome to a server")
          serv.sendNumeric(client,
            RPL_YOURHOST,
            msg = "Your host is "& serv.host &" running "& VersionStr)
          serv.sendNumeric(client,
            RPL_CREATED,
            msg = "This server was created a while ago.")
          serv.sendNumeric(client,
            RPL_MYINFO,
            args = [serv.name, VersionStr, UserModesStr, ChannelModesStr,
              ChannelModesWithParamsStr])
          ##send LUSERS
          ##send MOTD
          
      
      #let cmd = line.parseCommands
      let (prefix, command, args) = line.parseCommand
      case command
      of "NICK":
        if client.nick.len == 0:
          client.nick = args[0]
          tryToWelcome
      of "USER":
        if client.user.len == 0:
          client.user = args[0]
          tryToWelcome
      of "MODE":
        if false: nil
      of "QUIT":
        # msg = cmd[1]
        serv.drop client
      of "PASS":
        # passwd = cmd[1]
      of "JOIN":
        let channels = args[0].split(',')
        if channels[0] == "0":
          ## part all, do later
          return
        var keys: seq[string]
        if args.len > 1: 
          keys = args[1].split(',')
        for i in 0 .. high(channels):
          serv.joinChan(
            client,
            channels[i],
            if not(keys.isNil) and i < keys.len: keys[i]
            else: nil
          )
        
      of "CAP": 
        # http://www.leeh.co.uk/draft-mitchell-irc-capabilities-02.html
      else:
        #

proc newClient* (sock: PAsyncSocket; host: string): PClient {.
  inline.} = PClient(sock: sock, host: host, nick: "", user: "")

proc newServer* (port = 6667.TPort; buffered = true; name = "Disparity"): PServer =
  result = PServer(
    name: name,
    host: gethostname(),
    disp: newDispatcher(), 
    sock: AsyncSocket(buffered = buffered, typ = SOCK_STREAM),
    clients: initTable[PAsyncSocket, PClient](512),
    nicks: initTable[string, PClient](512),
    channels: initTable[string, TChannel](512)
  )
  
  let serv = result
  let disp = result.disp
  result.sock.handleAccept = proc(s: PAsyncSocket) =
    var client = new(TAsyncSocket)
    var addy: string
    s.acceptAddr client, addy
    
    client.handleRead = handleRead(serv)
    disp.register client
    serv.clients[client] = newClient(client, getHostByAddr(addy).name)


  result.disp.register result.sock
  result.sock.bindAddr port
  result.sock.listen
  
  echo "Listening on port ", port.int, ".."
  
proc loop* (serv: PServer) =
  serv.running = true
  while serv.running:
    if not serv.disp.poll():
      serv.running = false
proc run* (serv: PServer) =
  try:
    serv.loop
  finally:
    serv.sock.close
    echo "Closed socket."

when isMainModule:
  var port = 1776.TPort
  import parseopt
  for kind, k,v in getOpt():
    case kind
    of cmdLongOption,cmdShortOption:
      case k
      of "p", "port":
        port = v.parseInt.TPort
      else:
        echo "Unrecognized option: ", k
    else:
      echo "What option is this? ", k
  
  var s = newServer(port = port)
  setControlCHook proc{.noConv.} =
    s.running = false
    echo "Interrupt shutdown!"
  
  s.run
  
  
