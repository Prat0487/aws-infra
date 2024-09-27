import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Load data from Glue Data Catalog
datasource0 = glueContext.create_dynamic_frame.from_catalog(database = "my_database", table_name = "my_table", transformation_ctx = "datasource0")

# Apply transformations
applymapping1 = ApplyMapping.apply(frame = datasource0, mappings = [("col1", "string", "col1", "string"),
                                                                    ("col2", "int", "col2", "int"),
                                                                    ("col3", "double", "col3", "double")], transformation_ctx = "applymapping1")

# Write transformed data to S3
datasink2 = glueContext.write_dynamic_frame.from_options(frame = applymapping1, connection_type = "s3", connection_options = {"path": "s3://my-data-lake-bucket/transformed/"}, format = "csv", transformation_ctx = "datasink2")

job.commit()
