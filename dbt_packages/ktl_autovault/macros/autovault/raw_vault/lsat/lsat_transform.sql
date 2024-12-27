{%- macro lsat_transform(
    model,
    dv_system,
    from_psa_model=false,
    include_ghost_record=true
) -%}

    {{ config(
        materialized="incremental"
    ) }}

    {%- if var('ref_eod_table', none) -%}
        {%- set initial_date = ktl_autovault.eod_initial_date(ref(var('ref_eod_table'))) -%}
        {%- set start_date = ktl_autovault.eod_incre_start_date(ref(var('ref_eod_table'))) -%}
        {%- set end_date = ktl_autovault.eod_incre_end_date(ref(var('ref_eod_table'))) -%}
    {%- else -%}
        {%- set initial_date = var('initial_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d')) -%}
        {%- set start_date = var('incre_start_date', none) -%}
        {%- set end_date = var('incre_end_date', run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")).strftime('%Y-%m-%d')) -%}
    {%- endif -%}

    -- depends_on: {{ ktl_autovault.render_target_der_table_name(model) }}
    -- depends_on: {{ ktl_autovault.render_source_table_name(model, from_psa_model) }}
    
    {% if not is_incremental() -%}

        {{ ktl_autovault.lsat_transform_initial(model=model, dv_system=dv_system, from_psa_model=from_psa_model, initial_date=initial_date) }}

        {% if include_ghost_record -%}
        
        union all

        {{ ktl_autovault.lsat_ghost_record(model, dv_system) }}
        
        {% endif -%}

    {%- elif is_incremental() -%}

        {{ ktl_autovault.lsat_transform_incremental(model=model, dv_system=dv_system, start_date=start_date, end_date=end_date) }}

    {%- endif -%}

{%- endmacro -%}
