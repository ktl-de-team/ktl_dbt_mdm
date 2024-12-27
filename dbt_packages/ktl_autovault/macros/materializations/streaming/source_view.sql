{%- macro source_view(schema_name, table_name, from_psa_model) -%}
    {{ '{' }}
    {%- if from_psa_model -%}
        {{ ref(table_name) }}
    {%- else -%}
        {{ source(schema_name, table_name) }}
    {%- endif -%}
    {{ '}' }}
{%- endmacro -%}
