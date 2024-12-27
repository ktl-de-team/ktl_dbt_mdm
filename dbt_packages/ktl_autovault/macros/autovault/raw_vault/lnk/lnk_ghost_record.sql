{% macro lnk_ghost_record(model, dv_system) -%}
    {{ return(adapter.dispatch('lnk_ghost_record', 'ktl_autovault') (model, dv_system)) }}
{%- endmacro %}


{% macro spark__lnk_ghost_record(model, dv_system) -%}

    select
        {{ ktl_autovault.render_hash_key_lnk_treatment(model, ghost_record = true) }},

        {% for expr in ktl_autovault.render_list_hash_key_hub_treatment(model, ghost_record = true) -%}
            {{ expr }},
        {% endfor %}

        {% for expr in ktl_autovault.render_list_dv_system_column_treatment(dv_system, ghost_record = true) -%}
            {{ expr }},
        {% endfor %}

        {{ ktl_autovault.render_collision_code_treatment(model, ghost_record = true) }}

{%- endmacro %}


{% macro oracle__lnk_ghost_record(model, dv_system) -%}

    {{ ktl_autovault.spark__lnk_ghost_record(model, dv_system) }}

    from dual

{%- endmacro %}
