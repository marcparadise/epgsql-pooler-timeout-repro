This tests a failure scenario in which the epgsql driver does not know that the server has gone away, and waits indefinitely for queries in flight to complete. When used with pooler, this quickly causes all available connections to be utilized and provides no way to recover.

There are two paths to reproducing the issue; the local path is consistent in behavior with the RDS path, but the RDS path is preferred since it mirrors issues we have encountered in production environments.

## Notes:

An experimental branch of epgsql has been made with just adds timeouts to the gen_server calls into connections.  This combined with the uncommented `ping` function in this project do stop the hangs from occurring and successdfully reconnect - but implementing this version as a solution would require adding exception handling any place that sqerl talks to epgsql because `gen_server:call` raises an error instead of returning an error tuple when a timeout occurs.

The next step would be to include the exceptioni handling in epgsql itself.  This combined with the scommented-out version of `ping` prevents the hanging from occurring, but pooler still gives up on retries.  This may be fixable by changing pooler's retry /give up policy - it may be configurable - and is probably the next thing to look into here.

## Reproducing: RDS

Set up a multi-zone RDS instance and ensure you have access to it from your workstation, then do the following:

```
export test_pgsql_host=AWS_HOST_NAME
./rebar3 shell
failures:do_it().
```

Reboot the AWS instance.  If using the webui ensure that the 'failover' box is checked.  If using the AWS CLI, ensure `--force-failover` option is used.

Once the remote node goes offline, all query activity will cease and will not recover, even after failover completes.

## Reproducing: Local

Create a local PG database that uses user, database name, and password  'epgsql_test'.  Run the process the same way but set `test_pgsql_host` env var appropriately for your host.

See `setup.sh` - it contains details and comments that explain how to proceed with setup, and how to use iptables to 
reproduce this issue.

