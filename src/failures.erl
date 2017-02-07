-module(failures).
-export([do_it/0, do_it/1,
         spawn_it/0,
         init/0,
         ping_forever/0,
         real_ping/1,
         ping/0]).

-define(DELAY, 500).
-define(TIMEOUT, 1000).

do_it() ->
    init(),
    spawn_it().

do_it(N) ->
    init(),
    do_it0(N).

do_it0(0) ->
    ok;
do_it0(N) ->
    spawn_it(),
    timer:sleep(100),
    do_it0(N-1).

spawn_it() ->
    spawn(fun ping_forever/0).


init() ->
    Host = os:getenv("test_pgsql_host", "localhost"),
    io:fwrite("Connecting to host: ~p~n", [Host]),
    SqerlEnv = [{db_host, Host},
                {db_port, 5432},
                {db_user, "epgsql_test"},
                {db_pass, "epgsql_test"},
                {db_name, "epgsql_test"},
                {db_timeout, ?TIMEOUT},
                %{ssl, required},
                {req_timeout, ?TIMEOUT},
                {idle_check, 1000},
                {prepared_statements, [{ping, <<"select current_timestamp">>}]},
                {column_transforms, []}],
    [ ok = application:set_env(sqerl, Key, Val) || {Key, Val} <- SqerlEnv ],

    io:format("Sqerl env: ~p~n", [SqerlEnv]),

    PoolConfig = [{name, sqerl},
                  {max_count, 50},
                  {init_count, 50},
                  {start_mfa, {sqerl_client, start_link, []}}],
    ok = application:set_env(pooler, pools, [PoolConfig]),
    application:ensure_all_started(sqerl),
    error_logger:tty(false).

ping_forever() ->
    ping(),
    timer:sleep(?DELAY),
    ping_forever().

real_ping(Parent) ->
    Parent ! sqerl:execute(ping).

% This version will recover because of the try block - this is
% probably not the approach we want but it's a starting point.
ping() ->
    try sqerl:execute(ping) of
        {ok, _} -> io:fwrite(".");
        {error, no_connections} -> io:fwrite("n");
        _Error -> io:fwrite(" ~p ", _Error)
    catch exit:{error, timeout} -> io:fwrite("t");
          exit:shutdown -> io:fwrite("s");
          Type:{Reason, _Term} -> io:fwrite(" ~p:~p ", [Type, Reason])
    end.



  %Pid = spawn(failures, real_ping, [self()]),
    %try sqerl:execute(ping)  of
    %catch Error:Reason ->

  %receive
    %_Any ->
      %io:fwrite(".")
  %after
    %1000 ->
      %erlang:exit(Pid, timeout),
      %io:fwrite("x")
  %end.
  %Pid = spawn(fun() ->
                  %sqerl
    %try sqerl:execute(ping)  of
        %{ok, _} -> io:fwrite(".");
        %Error -> io:fwrite("~nOopsie: ~p~n", [Error])
    %catch Error:Reason ->
        %io:fwrite("~nError thrown! ~p:~p ~n", [Error, Reason])
    %end.

% This version will not - it will no longer hang indefnitely
% but the pool will be exhausted and the supervisor will give up on
% creating new connectionn.
%ping() ->
    %case sqerl:execute(ping)  of
        %{ok, _} -> io:fwrite(".");
        %Error -> io:fwrite("~nOopsie: ~p~n", [Error])
    %end.
