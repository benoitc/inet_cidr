[![Hex.pm version](https://img.shields.io/hexpm/v/erl_cidr.svg?style=flat)](https://hex.pm/packages/erl_cidr)

# inet_cidr

CIDR library for Erlang.

> Based on the Elixir library [InetCidr](https://github.com/Cobenian/inet_cidr) 
but rewritten so it can be easily used in an Erlang application without 
requiring Elixir.

Available on [hex.pm](https://hex.pm) as [erl_cidr](https://hex.pm/packages/erl_cidr).

## Usage

### Parsing a CIDR string

```erlang
1> inet_cidr:parse("192.168.0.0/16").
{{192,168,0,0},{192,168,255,255},16}
2> inet_cidr:parse("2001:abcd::/32").
{{8193,43981,0,0,0,0,0,0},
 {8193,43981,65535,65535,65535,65535,65535,65535},
 32}
```
