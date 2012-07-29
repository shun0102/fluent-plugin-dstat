Dstat plugin for Fluent

Description goes here.

## What's Dstat?

Dstat is a versatile replacement for vmstat, iostat, netstat and ifstat.
If you need more detail, see here[http://dag.wieers.com/home-made/dstat]
This plugin use Dstat, so you need to install Dstat before using this plugin.

## Configuration

```
<source>
  type dstat
  tag dstat
  option -c
  delay 3
 </source>
``

* option:option for dstat command(default: -fcdnm)

## Output Format

When you use option -c, you get structured output data like below.

  {
  "hostname":"tsukuba000",
  "dstat":{"total-cpu-usage":{"usr":"0",
                              "sys":"0",
                              "idl":"100",
                              "wai":"0",
                              "hiq":"0",
                              "siq":"0"}}
  }

## Supported options

```
aio, cpu, cpu24, disk, epoch, fs, int, int24, io, ipc, load, lock, mem, net, page, page24, proc, raw, socket, swap, swapold, sys, tcp, udp, unix, vm, disk-util, freespace, top-bio, top-cpu,top-io, top-mem, top-oom, utmp, top-io -fc
```

## Copyright

Copyright (c) 2011 Shunsuke Mikami. See LICENSE.txt for
further details.

