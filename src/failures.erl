-module(failures).
-compile(export_all).
% You;ll need to define HOST, USER, PASS, NAME, PORT

init() ->
    SqerlEnv = [{db_host, ?HOST},
                {db_port, ?PORT),
                {db_user, ?USER},
                {db_pass, ?PASS},
                {db_name, ?NAME},
                {idle_check, 1000},
                {prepared_statements, [{ping, <<"select current_timestamp">>}]},
                {column_transforms, []}],
    [ ok = application:set_env(sqerl, Key, Val) || {Key, Val} <- SqerlEnv ],

    io:format("Sqerl env: ~p~n", [SqerlEnv]),

    PoolConfig = [{name, sqerl},
                  {max_count, 1},
                  {init_count, 1},
                  {start_mfa, {sqerl_client, start_link, []}}],
    ok = application:set_env(pooler, pools, [PoolConfig]),
    application:ensure_all_started(sqerl).

ping_forever() ->
    case sqerl:execute(ping) of
        {ok, _} ->
            io:fwrite("."),
            ok;
        Error ->
            io:fwrite("~nOopsie: ~p~n", [Error])
    end,
    timer:sleep(100),
    ping_forever().


do_it() ->
    init(),
    spawn(fun ping_forever/0).
