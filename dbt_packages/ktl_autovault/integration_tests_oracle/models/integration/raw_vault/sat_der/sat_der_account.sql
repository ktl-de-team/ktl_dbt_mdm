
{%- set model = dv_config('sat_account') -%}
{%- set dv_system = var("dv_system") -%}


{{ ktl_autovault.sat_der_transform(model=model, dv_system=dv_system) }}