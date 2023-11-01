from pyspark import SparkContext
from os.path import abspath
from pyspark.sql import SparkSession


# Import PySpark
import pyspark
from pyspark.sql import SparkSession

#Create SparkSession
spark = SparkSession.builder.master("local[1]").appName("SparkByExamples.com").getOrCreate()

df=spark.read.option("header", "true").option("inferSchema", "true").csv("ofs://ip-10-10-76-91.us-west-2.compute.internal/tenant1/carsales/car_sales.csv")

df.show()
