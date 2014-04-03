
**Build**

`mvn assembly:assembly`

**Run App**

```bash
cat data.huge | nc -lk localhost 10.40.31.239 9394
spark-class cm.demo.spark.CountWord spark://hzs-sparc01:7077 10.40.31.239 9394
```

Edit the `\$SPARK_HOME/bin/compute-classpath.sh` to add your jar to classpath, so that it can be used with `spark-class`.
