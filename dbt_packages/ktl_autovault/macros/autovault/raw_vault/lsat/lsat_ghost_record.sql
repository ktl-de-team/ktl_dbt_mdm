{% macro lsat_ghost_record(model, dv_system) -%}
    {{ return(adapter.dispatch('lsat_ghost_record', 'ktl_autovault') (model, dv_system)) }}
{%- endmacro %}


{% macro spark__lsat_ghost_record(model, dv_system) -%}

    select
        {{ ktl_autovault.render_hash_key_lsat_treatment(model, dv_system, ghost_record = true) }},
        {{ ktl_autovault.render_hash_key_lnk_treatment(model, ghost_record = true) }},
        {{ ktl_autovault.render_hash_diff_treatment(model, ghost_record = true) }},

        {% for expr in ktl_autovault.render_list_dependent_key_treatment(model, ghost_record = true) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_attr_column_treatment(model, ghost_record = true) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system, ghost_record = true) -%}
            {{ expr }} {{- ',' if not loop.last }}
        {% endfor %}

{%- endmacro %}


{% macro oracle__lsat_ghost_record(model, dv_system) -%}

    {{ ktl_autovault.spark__lsat_ghost_record(model, dv_system) }}

    from dual

{%- endmacro %}
