# sparksh

When `spark-shell` starts it always creates some files in current directory like:

```
metastore_db/
derby.log
```

If you usually start `spark-shell` from various locations you will end up with lots of garbages. It's easier then to use a custom shell script which will always point `spark-shell` to it's fixed working directory. It can also setup spark-shell with some startup parameters, e.g. `--packages` that adds some Maven dependencies to classpath.

`spark-shell` is also quite verbose by default. You can tune amount of logs by editing `$SPARK_INSTALL_DIR/conf/log4j.properties` and setting:

```
log4j.rootCategory=WARN, console
```
