whacamole
=========

Here’s what Heroku says about dyno memory usage:

> Dynos are available in 1X or 2X sizes and are allocated 512MB or 1024MB respectively.
>
> Dynos whose processes exceed their memory quota are identified by an R14 error in the logs. This doesn’t terminate the process, but it does warn of deteriorating application conditions: memory used above quota will swap out to disk, which substantially degrades dyno performance.
>
> If the memory size keeps growing until it reaches three times its quota, the dyno manager will restart your dyno with an R15 error.
>
> - From https://devcenter.heroku.com/articles/dynos on 8/8/13

Heroku dynos swap to disk for up to 3GB. That is not good. Luckily, Heroku exposes dyno
size to our logs through the log-runtime-metrics beta feature, which we can use to
find and restart dynos that are running out of RAM.

This project is a formalization of this proof of concept: https://gist.github.com/arches/6187697
