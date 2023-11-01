from pyspark import SparkContext
from os.path import abspath
from pyspark.sql import SparkSession

spark = SparkSession \
    .builder \
    .appName("Data Cleaner") \
    .config("spark.dynamicAllocation.enabled" , "false") \
    .config("spark.dynamicAllocation.shuffleTracking.enabled", "false") \
    .config("spark.executor.instances", "10") \
    .config("spark.executor.cores", "1") \
    .config("spark.driver.memory","8g") \
    .config("spark.executor.memory","4g") \
    .config("spark.yarn.access.hadoopFileSystems","/ofs://ozone1/tenant1/carsales/") \
    .config("spark.kerberos.keytab", "dexuser.keytab") \
    .config("spark.kerberos.principal","dexuser@SME.CLOUDERA.LAB") \
.getOrCreate()


   val df=spark.read.option("header", "true").option("inferSchema", "true").csv("ofs://ip-10-10-76-91.us-west-2.compute.internal/tenant1/carsales/car_sales.csv")
