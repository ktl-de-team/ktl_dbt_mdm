{%- macro ktlmdm_general_config_yml() -%} 
{%- set yml -%}

name: ktlmdm
version: '1.0.0'

prefix_table_name: KTLMDM

run_date_config:
  {# cob_date: "(SELECT CURRENT_COB_DATE FROM LAKEHOUSE.MDM_INFO_RUN WHERE UPPER(PROJECT_NAME) = UPPER('{{ this.name.split("_")[0] }}'))" #}
  {# last_cob_date: "(SELECT LAST_COB_DATE FROM LAKEHOUSE.MDM_INFO_RUN WHERE UPPER(PROJECT_NAME) = UPPER('{{ this.name.split("_")[0] }}'))" #}

  {# cob_date: "TO_DATE('15102024','DDMMYYYY')"
  last_cob_date: "TO_DATE('14102024','DDMMYYYY')" #}

  cob_date: "TO_DATE('16102024','DDMMYYYY')"
  last_cob_date: "TO_DATE('15102024','DDMMYYYY')"

general_config:
  match_column_cnt: 3
  match_group_cnt: 1

KTL_MDM:
  - product: INDIVIDUAL
    source_system:
      - name: COREBANK
        component:
          - INGEST
          - CLEAN
          - VALIDATE
          - MATCH

      - name: CORECARD
        component:
          - INGEST
          - CLEAN
          - VALIDATE
          - MATCH

      - name: CRM
        component:
          - INGEST
          - CLEAN
          - VALIDATE
          - MATCH

    mdm_system:
      - merge_type: choose_best
        from_source:
          - name: COREBANK
            component: MATCH
          - name: CORECARD
            component: MATCH
          - name: CRM
            component: MATCH
  
  - product: CORP
    source_system:
      - name: COREBANK
        component:
          - INGEST
          - CLEAN
          - VALIDATE
          - MATCH

      - name: CORECARD
        component:
          - INGEST
          - CLEAN
          - VALIDATE
          - MATCH

    mdm_system:
      - merge_type: choose_best
        from_source:
          - name: COREBANK
            component: MATCH
          - name: CORECARD
            component: MATCH

{%- endset -%} 
{%- set model = fromyaml(yml) -%} 
{{ return(model) }} 
{%- endmacro -%}




