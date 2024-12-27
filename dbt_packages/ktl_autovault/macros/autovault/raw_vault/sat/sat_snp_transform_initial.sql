{%- macro sat_snp_transform_initial(
    model,
    dv_system,
    from_psa_model=false,
    initial_date = var('initial_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d'))
) -%}

    {%- set hkey_hub_name = ktl_autovault.render_hash_key_hub_name(model) -%}
    {%- set dep_keys = ktl_autovault.render_list_dependent_key_name(model) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}
    {%- set src_hkey_hub = ktl_autovault.render_list_hash_key_hub_component(model) -%}
    {%- set src_dep_keys = ktl_autovault.render_list_source_dependent_key_name(model) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}

    with
        cte_stg_sat as (
            select
                {{ ktl_autovault.render_hash_key_sat_treatment(model, dv_system) }},
                {{ ktl_autovault.render_hash_key_hub_treatment(model) }},
                {{ ktl_autovault.render_hash_diff_treatment(model) }},

                {% for expr in ktl_autovault.render_list_dependent_key_treatment(model) -%}
                    {{ expr }},
                {% endfor %}

                {% for expr in ktl_autovault.render_list_attr_column_treatment(model) -%}
                    {{ expr }},
                {% endfor %}

                {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system) -%}
                    {{ expr }} {{- ',' if not loop.last }}
                {% endfor %}

            from
                {{ ktl_autovault.render_source_table_name(model, from_psa_model) }}
            where
                {{ src_ldt_keys[0] }} < {{ ktl_autovault.timestamp(initial_date) }}
                
                {% for expr in src_hkey_hub + src_dep_keys -%}
                    and {{ expr }} is not null
                {% endfor %}
        ),

        cte_stg_sat_set_row_num as (
            select
                cte_stg_sat.*,

                row_number() over (
                    partition by
                        {% for key in [hkey_hub_name] + dep_keys -%}
                            {{ key }} {{- ',' if not loop.last }}
                        {% endfor %}
                    order by
                        {% for key in ldt_keys -%}
                            {{ key }} desc {{- ',' if not loop.last }}
                        {%- endfor %}
                ) as row_num

            from cte_stg_sat
        )
    
    select
        {{ ktl_autovault.render_hash_key_sat_name(model) }},
        {{ ktl_autovault.render_hash_key_hub_name(model) }},
        {{ ktl_autovault.render_hash_diff_name(model) }},

        {% for name in ktl_autovault.render_list_dependent_key_name(model) -%}
            {{ name }},
        {% endfor %}

        {% for name in ktl_autovault.render_list_attr_column_name(model) -%}
            {{ name }},
        {% endfor %}

        {% for name in ktl_autovault.render_list_dv_system_column_name(dv_system) -%}
            {{ name }} {{- ',' if not loop.last }}
        {% endfor %}
        
    from cte_stg_sat_set_row_num
    where row_num = 1

{%- endmacro -%}
