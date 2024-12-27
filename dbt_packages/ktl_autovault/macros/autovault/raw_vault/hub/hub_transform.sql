{% macro hub_transform(model, dv_system, from_psa_model=false, include_ghost_record=true) -%}

    {%- set sources = model.get('sources', [model]) -%}

    {%- if (sources | length) > 1 -%}
        
    {%- for source in sources -%}

        {%- do model.update(source) -%}

    select * from (
        {{ ktl_autovault.hub_transform_single(model, dv_system, from_psa_model) }}
    )

    {% if not loop.last -%}
        {%- if config.get('materialized') == "streaming" -%} ;
        {%- else -%} union all
        {%- endif %}

    {% endif -%}

    {%- endfor -%}

    {%- else -%}

        {%- do model.update(sources[0]) -%}
        {{ ktl_autovault.hub_transform_single(model, dv_system, from_psa_model) }}

    {% endif -%}

    {%- if not ktl_autovault.is_streaming() and not is_incremental() and include_ghost_record -%}

    union all

    {{ ktl_autovault.hub_ghost_record(model, dv_system) }}

    {%- endif -%}

{%- endmacro %}


{% macro hub_transform_single(model, dv_system, from_psa_model=false) -%}

    {%- set hkey_name = ktl_autovault.render_hash_key_hub_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}

    with
        cte_stg_hub as (
            select
                {{ ktl_autovault.render_hash_key_hub_treatment(model) }},

                {% for expr in ktl_autovault.render_list_biz_key_treatment(model) -%}
                    {{ expr }},
                {% endfor %}

                {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system) -%}
                    {{ expr }},
                {% endfor %}

                {{ ktl_autovault.render_collision_code_treatment(model) }}

            from
                {{ ktl_autovault.render_source_table_name(model, from_psa_model) }}
            where
                1 = 1
                {%- for expr in ktl_autovault.render_list_hash_key_hub_component(model) %}
                    and {{ expr }} is not null
                {%- endfor %}

                {%- if is_incremental() %}

                    and {{ src_ldt_keys[0] }} > coalesce(
                        (
                            select max({{ ldt_keys[0] }}) from {{ this }}
                            where {{ ktl_autovault.render_collision_code_name() }} = {{ "'" + model.get('collision_code') + "'" }}
                        ),
                        {{ ktl_autovault.timestamp('1900-01-01') }}
                    )

                {%- endif %}
        ),

        cte_stg_hub_latest_records as (
            select *
            from
                (
                    select
                        cte_stg_hub.*,

                        row_number() over (
                            partition by {{ hkey_name }}
                            order by
                                {% for key in ldt_keys -%}
                                    {{ key }} asc {{- ',' if not loop.last }}
                                {% endfor %}
                        ) as row_num

                    from cte_stg_hub
                )
            where row_num = 1
        )

    select
        {{ hkey_name }},

        {% for expr in ktl_autovault.render_list_biz_key_name(model) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
            {{ expr }},
        {% endfor %}

        {{ ktl_autovault.render_collision_code_name() }}

    from
        cte_stg_hub_latest_records src

    {%- if ktl_autovault.is_streaming() or is_incremental() %}

    where
        not exists (
            select 1
            from {{ this }} tgt
            where tgt.{{ hkey_name }} = src.{{ hkey_name }}
        )

    {%- endif -%}

{%- endmacro %}
