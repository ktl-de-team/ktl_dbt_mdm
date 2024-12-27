{%- macro render_target_table_name(model) -%}
    {{ ref(model.get('target_table')) }}
{%- endmacro -%}

{%- macro render_target_der_table_name(model) -%}
    {{ ref(model.get('target_table').replace("sat_", "sat_der_")) }}
{%- endmacro -%}


{%- macro render_target_snp_table_name(model) -%}
    {{ ref(model.get('target_table').replace("sat_", "sat_snp_")) }}
{%- endmacro -%}


{%- macro render_target_lsate_table_name(model) -%}
    {{ ref(model.get('target_table').replace("lnk_", "lsate_")) }}
{%- endmacro -%}


{%- macro render_source_table_name(model, from_psa_model=false) -%}
    {% if config.get('materialized') == "streaming" -%}
        {{ ktl_autovault.source_view(model.get('source_schema'), model.get('source_table'), from_psa_model) }}
    {%- else -%}
        {{ adapter.dispatch('render_source_table_name', 'ktl_autovault')(model, from_psa_model) }}
    {%- endif -%}
{%- endmacro -%}


{%- macro default__render_source_table_name(model, from_psa_model) -%}
    {%- set schema_name = model.get('source_schema') -%}
    {%- set table_name = model.get('source_table') -%}

    {%- if from_psa_model -%}
        {{ ref(table_name) }}
    {%- else -%}
        {{ source(schema_name, table_name) }}
    {%- endif -%}
{%- endmacro -%}


{%- macro render_source_view_name(model) -%}
    {{ ktl_autovault.source_view(model.get('source_schema'), model.get('source_table')) }}
{%- endmacro -%}


{%- macro render_parent_table_name(model, target_column=none) -%}
    {%- if column_name == none -%} {{ model.get('parent_table') }}
    {%- else -%}
        {%- set column = model.get('columns') | selectattr("target", "equalto", target_column) | first -%}
        {%- if column.parent is defined -%} {{ column.get('parent') }}
        {%- else -%} {{ model.get('parent_table') }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro -%}
