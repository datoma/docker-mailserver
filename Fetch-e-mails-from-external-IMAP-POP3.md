To enable fetchmail feature, set `ENABLE_FETCHMAIL` to `true` in your docker-compose.yml :

```
environment:
  - ENABLE_FETCHMAIL=true
```

Then add retrieval settings in postfixadmin like this :

![](https://i.imgur.com/I1j91jq.png)

You can change the fetchmail polling interval with `FETCHMAIL_INTERVAL` (in minutes) :

```
environment:
  - ENABLE_FETCHMAIL=true
  - FETCHMAIL_INTERVAL=5
```

A dedicated port (10025) is available with less restrictions for delivery. Use `FETCHMAIL_EXTRA_OPTIONS` with postfixadmin docker image for that purpose. 

Example :

```yml
postfixadmin:
  environment:
    FETCHMAIL_EXTRA_OPTIONS="smtp localhost/10025"
```
