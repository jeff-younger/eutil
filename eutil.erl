%% @author Jeffrey D Younger
%% @copyright 2015 Jeffrey D Younger
%% @version 1
%% @title eutil - a module of Erlang utilities

-module(eutil).

-export([
	explicate/2, 
	forf/4,
	mapfactory/1,
	new_map/1,
	mapfactoryc/1,
	test/0
]).

%
% The usual utility function to read Erlang 
% terms from a file created with consult.

explicate(Path, Data) ->
	file:write_file(Path, io_lib:fwrite("~p.\n", Data)).


%%
%% @spec forf(Start:: term(), ContinueF::fun(Start)->boolean(), 
%%            IncDeF::fun(Start)->Start(), GeneratorF::fun()->term())
%%        -> list()
%%
%% @doc An interator, using functions
%%
forf(Start, ContinueF, IncDecF, GeneratorF) ->
	forf(Start, ContinueF, IncDecF, GeneratorF, []).
forf(Start, ContinueF, IncDecF, GeneratorF, Lacc) ->
	case ContinueF(Start) of
		true -> forf(IncDecF(Start), ContinueF, IncDecF, 
			GeneratorF, [GeneratorF(Start) | Lacc]);
		false -> lists:reverse(Lacc)
	end.

%-------------------------------------------------------------------------------
%% The mapfactory functions provide a way to enforce creation maps with 
%% identical keys. Erlang shares the keys, as long as they are the same across
%% the maps. IF we are creating lots of maps, this saves lots of space.
%-------------------------------------------------------------------------------

%% @spec mapfactory(L::list())
%%
%% @doc A map factory using the stateful module technique.
%%
mapfactory(L) -> {eutil, mapfactory, make_map(L)}.
new_map({eutil, mapfactory, Map}) -> Map.

%% @spec mapfactoryc(L::list())
%%
%% @doc A map factory using closure. For use when a true function is necessary.
%%
mapfactoryc(L) when is_list(L) ->
	M = make_map(L),
	fun() ->
		M
	end.


%%
%% Private functions
%%
make_map(L) when is_list(L) -> make_map(L, #{}).
make_map([], M)             -> M;
make_map([H|T], M)          -> make_map(T, M#{H=>undefined}).


%
% Tests
%
test() ->
	[1,2,3,4,5,6,7,8,9,10] = forf(1, fun(I) -> I =< 10 end, 
		fun(I) -> I + 1 end, fun(I) -> I end),
	["a", "aa", "aaa", "aaaa"] = forf("a", fun(S) -> string:len(S) =< 4 end,
		fun(S) -> string:concat(S,"a") end, fun(S) -> S end),
	{eutil, mapfactory, #{a := undefined, b := undefined}} = mapfactory([a,b]),
	MF1 = {eutil, mapfactory, #{a => undefined, b => undefined}},
	#{a := undefined, b := undefined} = MF1:new_map(),
	MF2 = mapfactoryc([a,b]),
	#{a := undefined, b := undefined} = MF2(),
	ok.