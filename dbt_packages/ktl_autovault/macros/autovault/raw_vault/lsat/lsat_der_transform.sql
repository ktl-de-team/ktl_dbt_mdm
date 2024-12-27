{% macro lsat_der_transform(
    model,
    dv_system,
    from_psa_model=false
) -%}

    {%- if var('ref_eod_table', none) -%}
        {%- set initial_date = ktl_autovault.eod_initial_date(ref(var('ref_eod_table'))) -%}
    {%- else -%}
        {%- set initial_date = var('initial_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d')) -%}
    {%- endif -%}

    {%- set src_hkey_lnk = ktl_autovault.render_list_hash_key_lnk_component(model) -%}
    {%- set src_dep_keys = ktl_autovault.render_list_source_dependent_key_name(model) -%}
    {%- set src_ldt_keys = ktl_autovault.render_list_source_ldt_key_name(dv_system) -%}
    {%- set ldt_keys = ktl_autovault.render_list_dv_system_ldt_key_name(dv_system) -%}

    select
        {{ ktl_autovault.render_hash_key_lsat_treatment(model, dv_system) }},
        {{ ktl_autovault.render_hash_key_lnk_treatment(model) }},
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
        1 = 1
        {% for expr in src_hkey_lnk + src_dep_keys -%}
            and {{ expr }} is not null
        {% endfor %}

        and {{ src_ldt_keys[0] }} >= {{ ktl_autovault.timestamp(initial_date) }}

        {% if is_incremental() -%}
            and {{ src_ldt_keys[0] }} > coalesce((select max({{ ldt_keys[0] }}) from {{ this }}), {{ ktl_autovault.timestamp('1900-01-01') }})
        {%- endif %}

{%- endmacro %}
