%%
%% function cal generator
%%

-module(fcg).

-export([run/4, prun/5]).
-export([worker_run/5]).

% main API

% call function N times
run(M,F,A,N) ->
    T1 = erlang:monotonic_time(),
    run_loop(M,F,A,N,N),
    T2 = erlang:monotonic_time(),
    USec = erlang:convert_time_unit(T2 - T1, native, microsecond),
    report(N, USec).

% call function N times in W workers.
prun(M,F,A,N,W) ->
    WDiv = N div W,
    WRem = N rem W,
    WN = lists:foldl(fun(Id, Acc) ->
                             if Id =< WRem ->
                                    [ WDiv + 1 | Acc];
                                true ->
                                    [ WDiv | Acc]
                             end
                     end,
                     [], lists:seq(1, W)),
    ParentPid = self(),

    % start workers
    Workers = [ spawn_link(?MODULE, worker_run, [ParentPid, M, F, A, WorkerN]) || WorkerN <-  WN ],

    % start computing
    T1 = erlang:monotonic_time(),
    [ P ! start || P <- Workers],

    % wait for results
    Result = [ receive
                   {result, P, RN, RT} -> {RN, RT}
               end || P <- Workers],
    T2 = erlang:monotonic_time(),

    % sumarize output
    {TotN, TotT} = lists:foldl(fun({RN, RT}, {TN, TT}) ->
                                       {RN+TN, RT+TT}
                               end, {0,0}, Result),

    % print report
    report(TotN, TotT),
    USec = erlang:convert_time_unit(T2 - T1, native, microsecond),
    io:format("run time: ~p uSec~n", [USec]).

% internal loop
run_loop(M,F,A,Tot,N) when N > 0 ->
    apply(M,F,A),
    run_loop(M,F,A,Tot,N-1);

run_loop(_,_,_,_,0) -> ok.

report(N, USec) ->
    T = USec / N,
    io:format("calls: ~p, tot:~p uSec, call: ~p uSec~n", [N, USec, T]).

worker_run(ParentPid, M, F, A, N) ->
    receive
        start -> ok
    end,

    T1 = erlang:monotonic_time(),
    run_loop(M,F,A,N,N),
    T2 = erlang:monotonic_time(),
    USec = erlang:convert_time_unit(T2 - T1, native, microsecond),

    ParentPid ! {result, self(), N, USec}.
