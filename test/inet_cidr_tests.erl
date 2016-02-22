-module(inet_cidr_tests).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

parse_ipv4_test() ->
	?assert(inet_cidr:parse("192.168.0.0/0", true) == {{0,0,0,0}, {255,255,255,255}, 0}),
	?assert(inet_cidr:parse("192.168.0.0/8", true) == {{192,0,0,0}, {192,255,255,255}, 8}),
	?assert(inet_cidr:parse("192.168.0.0/15", true) == {{192,168,0,0}, {192,169,255,255}, 15}),
	?assert(inet_cidr:parse("192.168.0.0/16") == {{192,168,0,0}, {192,168,255,255}, 16}),
	?assert(inet_cidr:parse("192.168.0.0/17") == {{192,168,0,0}, {192,168,127,255}, 17}),
	?assert(inet_cidr:parse("192.168.0.0/18") == {{192,168,0,0}, {192,168,63,255}, 18}),
	?assert(inet_cidr:parse("192.168.0.0/19") == {{192,168,0,0}, {192,168,31,255}, 19}),
	?assert(inet_cidr:parse("192.168.0.0/20") == {{192,168,0,0}, {192,168,15,255}, 20}),
	?assert(inet_cidr:parse("192.168.0.0/21") == {{192,168,0,0}, {192,168,7,255}, 21}),
	?assert(inet_cidr:parse("192.168.0.0/22") == {{192,168,0,0}, {192,168,3,255}, 22}),
	?assert(inet_cidr:parse("192.168.0.0/23") == {{192,168,0,0}, {192,168,1,255}, 23}),
	?assert(inet_cidr:parse("192.168.0.0/24") == {{192,168,0,0}, {192,168,0,255}, 24}),
	?assert(inet_cidr:parse("192.168.0.0/31") == {{192,168,0,0}, {192,168,0,1}, 31}),
	?assert(inet_cidr:parse("192.168.0.0/32") == {{192,168,0,0}, {192,168,0,0}, 32}).

parse_ipv6_test() ->
	?assert(inet_cidr:parse("2001:abcd::/0", true) == {{0, 0, 0, 0, 0, 0, 0, 0}, {65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535}, 0}),
	?assert(inet_cidr:parse("2001:abcd::/32") == {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 65535, 65535, 65535, 65535, 65535, 65535}, 32}),
	?assert(inet_cidr:parse("2001:abcd::/33") == {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 32767, 65535, 65535, 65535, 65535, 65535}, 33}),
	?assert(inet_cidr:parse("2001:abcd::/34") == {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 16383, 65535, 65535, 65535, 65535, 65535}, 34}),
	?assert(inet_cidr:parse("2001:abcd::/35") == {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 8191, 65535, 65535, 65535, 65535, 65535}, 35}),
	?assert(inet_cidr:parse("2001:abcd::/36") == {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 4095, 65535, 65535, 65535, 65535, 65535}, 36}),
	?assert(inet_cidr:parse("2001:abcd::/128") == {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 0, 0, 0, 0, 0, 0}, 128}).


to_string_test() ->
	?assertEqual(inet_cidr:to_string({{192,168,0,0}, {192,168,255,255}, 16}),
				 "192.168.0.0/16"),
	?assertEqual(inet_cidr:to_string({{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 65535, 65535, 65535, 65535, 65535, 65535}, 32}), "2001:ABCD::/32").

ipv4_address_count_test() ->
	{ok, Addr} = inet:parse_address("192.168.0.0"),
	?assert(inet_cidr:address_count(Addr, 0) == 4294967296),
	?assert(inet_cidr:address_count(Addr, 16) == 65536),
	?assert(inet_cidr:address_count(Addr, 17) == 32768),
	?assert(inet_cidr:address_count(Addr, 24) == 256),
	?assert(inet_cidr:address_count(Addr, 32) == 1).

ipv6_address_count_test() ->
	{ok, Addr} = inet:parse_address("2001::abcd"),
	?assert(inet_cidr:address_count(Addr, 0) == math:pow(2,128)),
	?assert(inet_cidr:address_count(Addr, 64) == math:pow(2, 64)),
	?assert(inet_cidr:address_count(Addr, 128) == 1).

ipv4_contains_test() ->
	Block = {{192,168,0,0}, {192,168,255,255}, 16},
	?assert(inet_cidr:contains(Block, {192,168,0,0}) == true),
    ?assert(inet_cidr:contains(Block, {192,168,0,1}) == true),
    ?assert(inet_cidr:contains(Block, {192,168,1,0}) == true),
    ?assert(inet_cidr:contains(Block, {192,168,0,255}) == true),
    ?assert(inet_cidr:contains(Block, {192,168,255,0}) == true),
    ?assert(inet_cidr:contains(Block, {192,168,255,255}) == true),
    ?assert(inet_cidr:contains(Block, {192,168,255,256}) == false),
    ?assert(inet_cidr:contains(Block, {192,169,0,0}) == false),
    ?assert(inet_cidr:contains(Block, {192,167,255,255}) == false).

ipv6_contains_test() ->
	Block = {{8193, 43981, 0, 0, 0, 0, 0, 0}, {8193, 43981, 8191, 65535, 65535, 65535, 65535, 65535}, 35},
    ?assert(inet_cidr:contains(Block, {8193, 43981, 0, 0, 0, 0, 0, 0}) == true),
    ?assert(inet_cidr:contains(Block, {8193, 43981, 0, 0, 0, 0, 0, 1}) == true),
    ?assert(inet_cidr:contains(Block, {8193, 43981, 8191, 65535, 65535, 65535, 65535, 65534}) == true),
    ?assert(inet_cidr:contains(Block, {8193, 43981, 8191, 65535, 65535, 65535, 65535, 65535}) == true),
    ?assert(inet_cidr:contains(Block, {8193, 43981, 8192, 65535, 65535, 65535, 65535, 65535}) == false),
    ?assert(inet_cidr:contains(Block, {65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535}) == false).

is_ipv4_test() ->

    ?assert(inet_cidr:is_ipv4({192,168,0,0}) == true),
    ?assert(inet_cidr:is_ipv4({192,168,0,256}) == false),
    ?assert(inet_cidr:is_ipv4({192,168,0}) == false),
    ?assert(inet_cidr:is_ipv4({192,168,0,0,0}) == false),
    {ok, Addr} = inet:parse_address("2001::abcd"),
    ?assert(inet_cidr:is_ipv4(Addr) == false).

is_ipv6_test() ->
    ?assert(inet_cidr:is_ipv6({8193, 43981, 0, 0, 0, 0, 0, 0}) == true),
    ?assert(inet_cidr:is_ipv6({192,168,0,0}) == false),
    ?assert(inet_cidr:is_ipv6({8193, 43981, 0, 0, 0, 0, 0, 70000}) == false),
    ?assert(inet_cidr:is_ipv6({8193, 43981, 0, 0, 0, 0, 0}) == false),
    ?assert(inet_cidr:is_ipv6({8193, 43981, 0, 0, 0, 0, 0, 0, 0}) == false).

