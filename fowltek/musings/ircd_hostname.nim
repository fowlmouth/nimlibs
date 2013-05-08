proc getHostname* : string {.raises: [EIO].}

when defined(LINUX):
  import posix
  
  proc getHostname : string =
    var hostname_t: array[0 .. <256, char]
    var hostname = hostname_t[0].addr
    if gethostname(hostname, 256) != 0:
      return ""

    var hints: TAddrInfo
    var info: ptr TAddrInfo
    hints.ai_family = AF_UNSPEC
    hints.ai_socktype = SOCK_STREAM
    hints.ai_flags = AI_CANONNAME

    let res =  getaddrinfo(hostname, nil, hints.addr, info)
    if res != 0: 
      raise newException(system.EIO, "getaddrinfo: "& $gai_strerror(res))
    
    when true:
      result = $info.ai_canonname
    else:
      #is this useful?
      var p = info
      while not p.isNil:
        echo "hostname: ", p.ai_canonname
        p = p.ai_next

    freeaddrinfo info


when isMainModule:
  echo "This hostname: ", getHostname()
