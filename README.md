Dstat plugin for [Fluentd](http://fluentd.org)

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
```

#### Parameters

* option
  * option for dstat command (default: -fcdnm)

* tag
  * supported ${hostname} placeholder powered by [Fluent::Mixin::RewriteTagName](https://github.com/y-ken/fluent-mixin-rewrite-tag-name)

## Output Format

When you use option -a, you get structured output data like below.

  {
  "hostname":"tsukuba000",
   dstat":{"total cpu usage":"usr":"0.0","sys":"0.0","idl":"100.0","wai":"0.0","hiq":"0.0","siq":"0.0"},
           "dsk/total":{"read":"0.0","writ":"0.0"},"net/total":{"recv":"148.0","send":"164.0"},
           "paging":{"in":"0.0","out":"0.0"},
           "system":{"int":"16.333","csw":"29.0"}}
  }

## Supported options

```
aio, cpu, cpu24, disk, epoch, fs, int, int24, io, ipc, load, lock, mem, net, page, page24, proc, raw, socket, swap, swapold, sys, tcp, udp, unix, vm, disk-util, freespace, top-bio, top-cpu,top-io, top-mem, top-oom, utmp, top-io -fc
```

## Copyright

Copyright (c) 2011 Shunsuke Mikami. See LICENSE.txt for
further details.

