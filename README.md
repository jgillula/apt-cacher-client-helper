# apt-cacher-client-helper
Helper for clients that use apt-cacher or apt-cacher-ng

apt-cacher-ng is a thing that caches package files you'd normally retrieve through apt. You typically use it by telling apt to use your apt-cacher server as a proxy, and then you just do your apt stuff like normal.

The problem is that for https repos, apt cacher needs to be told when to use HTTPS, per https://www.unix-ag.uni-kl.de/~bloch/acng/html/howtos.html#ssluse

# How it works

`apt-cacher-client-helper` adds a file to the directory `/etc/apt/apt.conf.d' that tells `apt` to call a script called `https_repo_fixer.sh` just before `apt` tries to actually contact any repos. That script modifies all of the list files in `/etc/apt/sources.list.d`, rewriting lines with "https" in them from
```
deb https://some.repo.com/path something something_else
```
to
```
deb http://HTTPS///some.repo.com/path something something_else
```

And that's it. Any time you add a new repo, the script will automatically update it so that apt-cacher-ng knows how to understand it as an https repo.
