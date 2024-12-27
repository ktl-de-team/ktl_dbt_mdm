{% macro derive_column(column) -%}

    {%- set source_col = column.get('source') -%}
    {%- set target_expr = ktl_autovault.cast(source_col.get('name'), source_col.get('dtype'), column.get('dtype'), source_col.get('format')) -%}

    {{ target_expr }} {%- if target_expr != column.get('target') %} as {{ column.get('target') }} {%- endif -%}

{%- endmacro %}


{% macro render_list_biz_key_treatment(model, ghost_record = false) -%}
    
    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr("key_type", "equalto", "biz_key") -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {%- if api.Column.translate_type(column.get('dtype')) == dbt.type_string() -%}
                    {{ ktl_autovault.prepare_hash_component(column.get('source').get('name'), error_code = "-1", upper = true) }} as {{ column.get('target') }}
                {%- else -%}
                    {{ ktl_autovault.derive_column(column) }}
                {%- endif -%}

            {%- endif -%}

        {%- endset -%}

        {%- do outs.append(tmp) -%}
        
    {%- endfor -%}

    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_dependent_key_treatment(model, ghost_record = false) -%}

    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr('key_type', 'equalto', "dependent_key") -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {{ ktl_autovault.derive_column(column) }}
            
            {%- endif -%}
        
        {%- endset -%}

        {%- do outs.append(tmp) -%}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{% macro render_list_attr_column_treatment(model, ghost_record = false) -%}

    {%- set outs = [] -%}

    {%- for column in model.get('columns') | selectattr('key_type', 'undefined') -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {{ ktl_autovault.derive_column(column) }}
            
            {%- endif -%}
        
        {%- endset -%}

        {%- do outs.append(tmp) -%}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro %}


{%- macro render_list_dv_system_column_treatment(dv_system, ghost_record = false) -%}

    {%- set outs = [] -%}

    {%- for column in dv_system.get('columns') -%}

        {%- set tmp -%}

            {%- if ghost_record -%}
                {{ ktl_autovault.render_ghost_record(column) }} as {{ column.get('target') }}
            
            {%- else -%}
                {{ ktl_autovault.derive_column(column) }}
            
            {%- endif -%}
        
        {%- endset -%}

        {%- do outs.append(tmp) -%}
    
    {%- endfor -%}
    
    {{ return(outs) }}

{%- endmacro -%}
