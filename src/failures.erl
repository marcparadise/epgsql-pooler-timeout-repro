-module(failures).
-export([do_it/0,
         init/0,
         ping_forever/0,
         ping/0]).

do_it() ->
    init(),
    spawn(fun ping_forever/0).


init() ->
    Host = os:getenv("test_pgsql_host", "localhost"),
    io:fwrite("Connecting to host: ~p~n", [Host]),
    SqerlEnv = [{db_host, Host},
                {db_port, 5432},
                {db_user, "epgsql_test"},
                {db_pass, "epgsql_test"},
                {db_name, "epgsql_test"},
                {idle_check, 1000},
                {prepared_statements, [{ping, <<"select current_timestamp">>}]},
                {column_transforms, []}],
    [ ok = application:set_env(sqerl, Key, Val) || {Key, Val} <- SqerlEnv ],

    io:format("Sqerl env: ~p~n", [SqerlEnv]),

    PoolConfig = [{name, sqerl},
                  {max_count, 5},
                  {init_count, 5},
                  {start_mfa, {sqerl_client, start_link, []}}],
    ok = application:set_env(pooler, pools, [PoolConfig]),
    application:ensure_all_started(sqerl).

ping_forever() ->
    ping(),
    timer:sleep(100),
    ping_forever().

% This version will recover because of the try block - this is
% probably not the approach we want but it's a starting point.
ping() ->
    try sqerl:execute(ping)  of
        {ok, _} -> io:fwrite(".");
        Error -> io:fwrite("~nOopsie: ~p~n", [Error])
    catch Error:Reason ->
        io:fwrite("~nError thrown! ~p:~p ~n", [Error, Reason])
    end.

% This version will not - it will no longer hang indefnitely
% but the pool will be exhausted and the supervisor will give up on
% creating new connectionn.
%ping() ->
    %case sqerl:execute(ping)  of
        %{ok, _} -> io:fwrite(".");
        %Error -> io:fwrite("~nOopsie: ~p~n", [Error])
    %end.
