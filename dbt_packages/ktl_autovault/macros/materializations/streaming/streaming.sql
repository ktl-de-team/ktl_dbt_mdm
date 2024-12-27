{% materialization streaming, adapter='spark', supported_languages=['sql'] -%}

  {%- set grant_config = config.get('grants') -%}

  {#-- Set vars --#}

  {%- set target_relation = this -%}
  {%- set existing_relation = load_relation(this) -%}

  {#-- Run pre-hooks --#}
  {{ run_hooks(pre_hooks) }}

  {%- if existing_relation is none -%}

    {%- call statement('main', language='python') -%}
      {{ ktl_autovault.pyspark_streaming(compiled_code, target_relation) }}
    {%- endcall -%}
    {% do persist_constraints(target_relation, model) %}

  {%- elif existing_relation.is_view or should_full_refresh() -%}

    {% do adapter.drop_relation(existing_relation) %}
    {%- call statement('main', language='python') -%}
      {{ ktl_autovault.pyspark_streaming(compiled_code, target_relation, full_refresh=true) }}
    {%- endcall -%}
    {% do persist_constraints(target_relation, model) %}
  
  {%- else -%}

    {%- call statement('main', language='python') -%}
      {{ ktl_autovault.pyspark_streaming(compiled_code, target_relation) }}
    {%- endcall -%}
  
  {%- endif -%}

  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode) %}
  {% do apply_grants(target_relation, grant_config, should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization %}


{% macro pyspark_streaming(compiled_code, target_relation, full_refresh=false) %}

checkpoint_prefix = "{{ config.get('streaming_checkpoint_path', '') }}"
if not checkpoint_prefix:
    raise ValueError("streaming_checkpoint_path config is required for streaming materialization.")

file_format = "{{ config.get('file_format', '') }}"
if file_format != "iceberg":
    raise ValueError("file_format=iceberg config is required for streaming materialization.")

import os
import re
import boto3
import shutil

{%- if full_refresh %}
def full_refresh_directory(path):
    match = re.match(r's3a://([^/]+)/(.+)', path)
    if not match:
        shutil.rmtree(path)
        return
    
    bucket_name, directory_path = match.groups()
    
    # Ensure the directory path ends with a '/'
    if not directory_path.endswith('/'):
        directory_path += '/'
    
    if not os.environ.get('AWS_DEFAULT_REGION'):
        os.environ['AWS_DEFAULT_REGION'] = os.environ.get('AWS_REGION', '')

    s3 = boto3.client(
        's3',
        endpoint_url=spark.conf.get("spark.hadoop.fs.s3a.endpoint")
    )

    ### full refresh
    # Use paginator to list all objects under the directory prefix

    paginator = s3.get_paginator('list_objects_v2')

    for page in paginator.paginate(Bucket=bucket_name, Prefix=directory_path):
        if 'Contents' in page:
            delete_objects = [{'Key': obj['Key']} for obj in page['Contents']]

            if delete_objects:
                response = s3.delete_objects(
                    Bucket=bucket_name,
                    Delete={'Objects': delete_objects}
                )
                print(f"Deleted objects: {response}")

    {# s3.put_object(Bucket=bucket_name, Key=directory_path + "offsets/")
    s3.put_object(Bucket=bucket_name, Key=directory_path + "commits/")
    s3.put_object(Bucket=bucket_name, Key=directory_path + "sources/") #}

{%- endif %}

def batch_exec(batch_df, batch_id):
    spark = batch_df.sparkSession
    spark.sql(sql_text, **{source_table: batch_df}) \
        .coalesce(10) \
        .write \
        .format("iceberg") \
        .mode("append") \
        .saveAsTable(target_relation)

sql_text = """
    {{ compiled_code }}
"""

for sql_text in sql_text.split(";"):

    source_match = re.search(r"\{([\w.]+)\}", sql_text)

    if not source_match:
        spark.sql(sql_text).write \
            .format("iceberg") \
            .mode("append") \
            .saveAsTable("{{ target_relation }}")

    else:
        source_relation = source_match.group(1)
        source_db, source_table = source_relation.split('.')[-2:]
        sql_text = sql_text.replace("{" + source_relation + "}", "{" + source_table + "}")

        target_relation = "{{ target_relation }}"
        checkpoint_path = checkpoint_prefix + f"/{source_relation}_to_{target_relation}".lower().replace(".", "_")

        {% if full_refresh -%}
            full_refresh_directory(checkpoint_path)
        {% endif -%}
        {#- create_s3_directory(checkpoint_path) -#}

        try:
            spark.readStream \
                .format("iceberg") \
                .option("streaming-skip-delete-snapshots", "true") \
                .option("streaming-skip-overwrite-snapshots", "true") \
                .load(source_relation) \
                .writeStream \
                .trigger(once=True) \
                .option("checkpointLocation", checkpoint_path) \
                .option("fanout-enabled", "true") \
                .foreachBatch(batch_exec) \
                .start() \
                .awaitTermination()

        except Exception as err:
            raise err

{% endmacro %}
