A Tiger Compiler in OCaml
=========================

[todo]


TopLevel
--------

You can specify an action sequence to manipulate the loaded
program. For example, you can do the following to print the AST and
then print the IR.

./main.byte -load ./tests/samples/test1.tig -ast -p -ir -p


Trouble Shooting
----------------

1. On my GNU/Linux laptop, compiling runtime.c with `-m32` complains
   `fatal error: sys/cdefs.h: No such file or directory`

```
apt-get install gcc-multilib
```
