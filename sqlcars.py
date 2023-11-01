
# Import PySpark
import pyspark
from pyspark.sql import SparkSession

#Create SparkSession
spark = SparkSession.builder.master("local[1]").appName("SparkByExamples.com").getOrCreate()




dficeberg= spark.sql("show tblproperties default.iceberg_weblogs")
dficeberg.show(35)

dfweblogs= spark.sql("select * from iceberg_weblogs")
dfweblogs.show(35)
