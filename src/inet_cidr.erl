%%% -*- erlang -*-
%%% This file is part of nat-pmp released under the MIT license.
%%% See the NOTICE for more information.
%%%
%%% Copyright (c) 2016 Benoît Chesneau <benoitc@refuge.io>

-module(inet_cidr).

-export([parse/1, parse/2]).
-export([address_count/2]).
-export([contains/2]).
-export([to_string/1]).
-export([is_ipv4/1]).
-export([is_ipv6/1]).

%% @doc parses S as a CIDR notation IP address and mask
parse(S) ->
    parse(S, false).

parse(S, Adjust) ->
    {StartAddr, PrefixLen} = parse_cidr(S, Adjust),
    EndAddr = calc_end_address(StartAddr, PrefixLen),
    {StartAddr, EndAddr, PrefixLen}.

%% @doc returnt the number of IP addresses included in the CIDR block
address_count(IP, Len) ->
    1 bsl (bit_count(IP)  - Len).

%% @doc return true if the CIDR block contains the IP address, false otherwise.
contains({{A, B, C, D}, {E, F, G, H}, _Len}, {W, X, Y, Z}) ->
    (((W >= A) and (W =< E)) and
     ((X >= B) and (X =< F)) and
     ((Y >= C) and (Y =< G)) and
     ((Z >= D) and (Z =< H)));
contains({{A, B, C, D, E, F, G, H}, {I, J, K, L, M, N, O, P}, _Len},
         {R, S, T, U, V, W, X, Y}) ->
    (((R >= A) and (R =< I)) and
     ((S >= B) and (S =< J)) and
     ((T >= C) and (T =< K)) and
     ((U >= D) and (U =< L)) and
     ((V >= E) and (V =< M)) and
     ((W >= F) and (W =< N)) and
     ((X >= G) and (X =< O)) and
     ((Y >= H) and (Y =< P)));
contains(_, _) ->
    false.

to_string({StartAddr, _EndAddr, Len}) ->
    inet:ntoa(StartAddr) ++ "/" ++ integer_to_list(Len).

%% @doc return true if the value is an ipv4 address
is_ipv4({A, B, C, D}) ->
    (((A >= 0) and (A =< 255)) and
     ((B >= 0) and (B =< 255)) and
     ((C >= 0) and (C =< 255)) and
     ((D >= 0) and (D =< 255)));
is_ipv4(_) ->
    false.

%% @doc return true if the value is an ipv6 address
is_ipv6({A, B, C, D, E, F, G, H}) ->
    (((A >= 0) and (A =< 65535)) and
     ((B >= 0) and (B =< 65535)) and
     ((C >= 0) and (C =< 65535)) and
     ((D >= 0) and (D =< 65535)) and
     ((E >= 0) and (E =< 65535)) and
     ((F >= 0) and (F =< 65535)) and
     ((G >= 0) and (G =< 65535)) and
     ((H >= 0) and (H =< 65535)));
is_ipv6(_) ->
    false.

%% internals

bit_count({_, _, _, _}) -> 32;
bit_count({_, _, _, _, _, _, _, _}) -> 128.

parse_cidr(S, Adjust) ->
    [Prefix, LenStr] = re:split(S, "/", [{return, list}, {parts, 2}]),
    {ok, StartAddr} = inet:parse_address(Prefix),
    {PrefixLen, _} = string:to_integer(LenStr),
    Masked = band_with_mask(StartAddr, start_mask(StartAddr, PrefixLen)),

    if
        Adjust /= true, Masked /= StartAddr -> error(invalid_cidr);
        true -> ok
    end,

    {Masked, PrefixLen}.

start_mask({_, _, _, _}=Addr, Len) when Len >= 0, Len =< 32 ->
    {A, B, C, D} = end_mask(Addr, Len),
    {bnot A, bnot B, bnot C, bnot D};

start_mask({_, _, _, _, _, _, _, _}=Addr, Len) when Len >= 0, Len =< 128 ->
    {A, B, C, D, E, F, G, H} = end_mask(Addr, Len),
    {bnot A, bnot B, bnot C, bnot D, bnot E, bnot F, bnot G, bnot H}.

end_mask({_, _, _, _}, Len) when Len >= 0, Len =< 32 ->
    if
        Len == 32 -> {0, 0, 0, 0};
        Len >= 24 -> {0, 0, 0, bmask(Len, 8)};
        Len >= 16 -> {0, 0, bmask(Len, 8), 16#FF};
        Len >= 8 -> {0, bmask(Len, 8), 16#FF, 16#FF};
        Len >= 0 -> {bmask(Len, 8), 16#FF, 16#FF, 16#FF}
    end;

end_mask({_, _, _, _, _, _, _, _}, Len) when Len >= 0, Len =< 128 ->
    if
        Len == 128 -> {0, 0, 0, 0, 0, 0, 0, 0};
        Len >= 112 -> {0, 0, 0, 0, 0, 0, 0, bmask(Len, 16)};
        Len >= 96 -> {0, 0, 0, 0, 0, 0, bmask(Len, 16), 16#FFFF};
        Len >= 80 ->  {0, 0, 0, 0, 0, bmask(Len, 16), 16#FFFF, 16#FFFF};
        Len >= 64 -> {0, 0, 0, 0, bmask(Len, 16), 16#FFFF, 16#FFFF, 16#FFFF};
        Len >= 49 -> {0, 0, 0, bmask(Len, 16), 16#FFFF, 16#FFFF, 16#FFFF,
                      16#FFFF};
        Len >= 32 -> {0, 0, bmask(Len, 16), 16#FFFF, 16#FFFF, 16#FFFF, 16#FFFF,
                      16#FFFF};
        Len >= 16 -> {0, bmask(Len, 16), 16#FFFF, 16#FFFF, 16#FFFF, 16#FFFF,
                      16#FFFF, 16#FFFF};
        Len >= 0 -> {bmask(Len, 16), 16#FFFF, 16#FFFF, 16#FFFF, 16#FFFF,
                     16#FFFF, 16#FFFF, 16#FFFF}
    end.

bmask(I, 8) when I >= 0, I =< 32 ->
    16#FF bsr (I rem 8);
bmask(I, 16) when I >= 0, I =< 128 ->
    16#FFFF bsr (I rem 16).

calc_end_address(Addr, Len) ->
    bor_with_mask(Addr, end_mask(Addr, Len)).

bor_with_mask({A, B, C, D}, {E, F, G, H}) ->
    {A bor E, B bor F, C bor G, D bor H};
bor_with_mask({A, B, C, D, E, F, G, H}, {I, J, K, L, M, N, O, P}) ->
    {A bor I, B bor J, C bor K, D bor L, E bor M, F bor N, G bor O, H bor P}.

band_with_mask({A, B, C, D}, {E, F, G, H}) ->
    {A band E, B band F, C band G, D band H};
band_with_mask({A, B, C, D, E, F, G, H}, {I, J, K, L, M, N, O, P}) ->
    {A band I, B band J, C band K, D band L, E band M, F band N, G band O,
     H band P}.


