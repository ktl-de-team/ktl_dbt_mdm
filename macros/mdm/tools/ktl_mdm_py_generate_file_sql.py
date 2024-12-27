import yaml
import pandas as pd
import numpy as np


class CustomDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(CustomDumper, self).increase_indent(flow, False)
    
class YamlRuleGenerator:  
    def __init__(self, df):  
        self.df = df 
    
    def generate_yml_rules(self, is_template):
        cleansing_rules = []
        validate_rules = []

        for _, row in self.df.iterrows():
            rule = self.create_rule(row, is_template)

            if self.determine_component(row) == "clean":  
                cleansing_rules.append(rule)  
            elif self.determine_component(row) == "validate":  
                validate_rules.append(rule)  

        return {"cleansing": cleansing_rules, "validate": validate_rules}  
    
    def create_rule(self, row, is_template):
        if is_template == "rule_info_template":
            rule = {
                "name": f"{row['template_name']}",
                "rule_type": "common",
                "description": row['description']
            }
            self.add_conditions(rule, row, is_template)
        elif is_template == "rule_desc":
            rule =  {
                    "code": row['code'],
                    "description": f"'{row['description_rule_desc']}'"
            }
            self.add_conditions(rule, row, is_template)

        return rule
        
    def add_conditions(self, rule, row, is_template):
        if is_template == "rule_info_template":
            rule["condition"] = row['condition']

        elif is_template == "rule_desc":
            if row['condition_rule_template'] is not None and row['condition_rule_desc'] is not None:  
                lst_x = row['condition_rule_template'].split("|")  
                lst_y = row['condition_rule_desc'].split("|")  

                if len(lst_x) == len(lst_y):  
                    for index, item in enumerate(lst_x):
                        rule[item] = False if item == 'warning_null' and lst_y[index] == 'False' else (True if item == 'warning_null' else lst_y[index])

    def determine_component(self, row):    
            return str(row["component"])  

def write_to_yaml_file_sql(yaml_structure, file_path="output.sql",  name_macro = "ktlmdm_rule_template_config_yml"):
    
    str_macro = f"""{{%- macro {name_macro}() -%}}"""
    str_set = '{%- set yml -%}'
    str_endset = '{%- endset -%}'

    str_setmodel = '{%- set model = fromyaml(model_yml) -%}'
    str_return = '{{ return(model) }}'
    str_endmacro = '{%- endmacro -%}'

    with open(file_path, "w", encoding="utf-8") as file:
        file.write(f"{str_macro} \n")
        file.write(f"{str_set} \n")
        file.write("\n")

        yaml.dump(yaml_structure, file, Dumper=CustomDumper, default_flow_style=False, sort_keys=False, allow_unicode=True, indent=2) 

        file.write("\n")
        file.write(f"{str_endset} \n")
        file.write(f"{str_setmodel} \n")
        file.write(f"{str_return} \n")
        file.write(f"{str_endmacro} \n")


if __name__ == "__main__":
    path_info_rule_desc = "MDM_INFO_RULE_DESC.csv"
    path_info_rule_template = "MDM_RULE_INFO_TEMPLATE.csv"
    
    df_desc = pd.read_csv(path_info_rule_desc).replace({np.nan:None})
    df_info_template = pd.read_csv(path_info_rule_template).replace({np.nan:None})
    df_merge_info = pd.merge(df_info_template, df_desc, on = ['component', 'template_name'], suffixes=('_rule_template', '_rule_desc'))

    yml_structure = YamlRuleGenerator(df_merge_info).generate_yml_rules(is_template='rule_desc')
    yml_structure_template = YamlRuleGenerator(df_info_template).generate_yml_rules(is_template='rule_info_template')

    #write ktlmdm_rule_info_desc.sql
    write_to_yaml_file_sql(yaml_structure=yml_structure, file_path="ktlmdm_info_rule_desc.sql", name_macro="ktlmdm_rule_info_desc")
    write_to_yaml_file_sql(yaml_structure=yml_structure_template, file_path="ktlmdm_info_rule_template.sql", name_macro="ktlmdm_rule_info_template")