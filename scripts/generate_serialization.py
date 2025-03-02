import os
import json
import re

source_base = os.path.sep.join('src/include/duckdb/storage/serialization'.split('/'))
target_base = os.path.sep.join('src/storage/serialization'.split('/'))

file_list = []
for fname in os.listdir(source_base):
    if '.json' not in fname:
        continue
    file_list.append(
        {
            'source': os.path.join(source_base, fname),
            'target': os.path.join(target_base, 'serialize_' + fname.replace('.json', '.cpp'))
        }
    )


include_base = '#include "${FILENAME}"\n'

header = '''//===----------------------------------------------------------------------===//
// This file is automatically generated by scripts/generate_serialization.py
// Do not edit this file manually, your changes will be overwritten
//===----------------------------------------------------------------------===//

${INCLUDE_LIST}
namespace duckdb {
'''

footer = '''
} // namespace duckdb
'''

serialize_base = '''
void ${CLASS_NAME}::FormatSerialize(FormatSerializer &serializer) const {
${MEMBERS}}
'''

serialize_element = '\tserializer.WriteProperty("${PROPERTY_KEY}", ${PROPERTY_NAME});\n'

base_serialize = '\t${BASE_CLASS_NAME}::FormatSerialize(serializer);\n'

deserialize_base = '''
unique_ptr<${BASE_CLASS_NAME}> ${CLASS_NAME}::FormatDeserialize(${EXTRA_PARAMETERS}FormatDeserializer &deserializer) {
${MEMBERS}
}
'''

switch_code = '''\tswitch (${SWITCH_VARIABLE}) {
${CASE_STATEMENTS}\tdefault:
\t\tthrow SerializationException("Unsupported type for deserialization of ${BASE_CLASS}!");
\t}
'''

switch_statement = '''\tcase ${ENUM_TYPE}::${ENUM_VALUE}:
\t\tresult = ${CLASS_DESERIALIZE}::FormatDeserialize(${EXTRA_PARAMETERS}deserializer);
\t\tbreak;
'''

deserialize_element = '\tauto ${PROPERTY_NAME} = deserializer.ReadProperty<${PROPERTY_TYPE}>("${PROPERTY_KEY}");\n'
deserialize_element_class = '\tdeserializer.ReadProperty("${PROPERTY_KEY}", result->${PROPERTY_NAME});\n'
deserialize_element_class_base = '\tauto ${PROPERTY_NAME} = deserializer.ReadProperty<unique_ptr<${BASE_PROPERTY}>>("${PROPERTY_KEY}");\n\tresult->${PROPERTY_NAME} = unique_ptr_cast<${BASE_PROPERTY}, ${DERIVED_PROPERTY}>(std::move(${PROPERTY_NAME}));\n'

move_list = [
    'string', 'ParsedExpression*', 'CommonTableExpressionMap'
]

def is_container(type):
    return '<' in type

def is_pointer(type):
    return '*' in type

def replace_pointer(type):
    return re.sub('([a-zA-Z0-9]+)[*]', 'unique_ptr<\\1>', type)

def get_serialize_element(property_name, property_key, property_type, is_optional):
    write_method = 'WriteProperty'
    if is_optional:
        write_method = 'WriteOptionalProperty'
    return serialize_element.replace('${PROPERTY_NAME}', property_name).replace('${PROPERTY_KEY}', property_key).replace('WriteProperty', write_method)

def get_deserialize_element_template(template, property_name, property_key, property_type, is_optional):
    read_method = 'ReadProperty'
    if is_optional:
        read_method = 'ReadOptionalProperty'
    return template.replace('${PROPERTY_NAME}', property_name).replace('${PROPERTY_KEY}', property_key).replace('ReadProperty', read_method).replace('${PROPERTY_TYPE}', property_type)


def get_deserialize_element(property_name, property_key, property_type, is_optional):
    return get_deserialize_element_template(deserialize_element, property_name, property_key, property_type, is_optional)

for entry in file_list:
    source_path = entry['source']
    target_path = entry['target']
    with open(source_path, 'r') as f:
        json_data = json.load(f)

    base_class_name = None
    base_class_data = {}
    serialize_data = {}
    constructors = {}
    include_list = ['duckdb/common/serializer/format_serializer.hpp', 'duckdb/common/serializer/format_deserializer.hpp']
    extra_parameters = []
    class_name_list = []

    for entry in json_data:
        class_name = entry['class']
        if 'class_type' in entry:
            # base class
            base_class_name = class_name
            base_class_data[class_name] = {
                "__enum_value": entry['class_type']
            }
            include_list += entry['includes']
            if 'extra_parameters' in entry:
                extra_parameters = entry['extra_parameters']
        elif 'base' in entry:
            base_class = entry['base']
            enum_entry = entry['enum']
            if 'constructor' in entry:
                constructors[class_name] = entry['constructor']
            if base_class not in base_class_data:
                raise Exception(f"Base class \"{base_class}\" not found")
            if enum_entry in base_class_data[base_class]:
                raise Exception(f"Duplicate enum entry \"{enum_entry}\"")
            base_class_data[base_class][enum_entry] = class_name
        class_name_list.append(class_name)
        serialize_data[class_name] = entry['members']

    with open(target_path, 'w+') as f:
        f.write(header.replace('${INCLUDE_LIST}', ''.join([include_base.replace('${FILENAME}', x) for x in include_list])))

        # generate the base class serialization
        base_class_serialize = ''
        base_class_deserialize = ''

        # properties
        enum_type = ''
        for entry in serialize_data[base_class]:
            property_name = entry['property'] if 'property' in entry else entry['name']
            type_name = entry['type']
            if is_pointer(type_name):
                type_name = replace_pointer(type_name)
            if property_name == base_class_data[base_class_name]['__enum_value']:
                enum_type = entry['type']
            is_optional = False
            if 'optional' in entry and entry['optional']:
                is_optional = True
            base_class_serialize += get_serialize_element(property_name, entry['name'], type_name, is_optional)
            base_class_deserialize += get_deserialize_element(property_name, entry['name'], type_name, is_optional)
        expressions = [x for x in base_class_data[base_class_name].items() if x[0] != '__enum_value']
        expressions = sorted(expressions, key=lambda x: x[0])

        base_class_deserialize += f'\tunique_ptr<{base_class_name}> result;\n'
        switch_cases = ''
        extra_parameter_txt = ''
        for extra_parameter in extra_parameters:
            extra_parameter_txt += extra_parameter + ', '
        for expr in expressions:
            switch_cases += switch_statement.replace('${ENUM_TYPE}', enum_type).replace('${ENUM_VALUE}', expr[0]).replace('${CLASS_DESERIALIZE}', expr[1]).replace('${EXTRA_PARAMETERS}', extra_parameter_txt)

        assign_entries = []
        for entry in  serialize_data[base_class]:
            entry_name = entry['name']
            entry_property = entry_name
            if 'property' in entry:
                entry_property = entry['property']
            skip = False
            for check_entry in [entry_name, entry_property]:
                if check_entry in extra_parameters:
                    skip = True
                if check_entry == base_class_data[base_class_name]['__enum_value']:
                    skip = True
            if skip:
                continue
            move = False
            if entry['type'] in move_list or is_container(entry['type']) or is_pointer(entry['type']):
                move = True
            assign_entries.append([entry_property, move])

        # class switch statement
        base_class_deserialize += switch_code.replace('${SWITCH_VARIABLE}', base_class_data[base_class_name]['__enum_value']).replace('${CASE_STATEMENTS}', switch_cases).replace('${BASE_CLASS}', base_class_name)

        for entry in assign_entries:
            name = entry[0]
            move = entry[1]
            if move:
                base_class_deserialize+= f'\tresult->{name} = std::move({name});\n'
            else:
                base_class_deserialize+= f'\tresult->{name} = {name};\n'
        base_class_deserialize += '\treturn result;'
        base_class_generation = ''
        base_class_generation += serialize_base.replace('${CLASS_NAME}', base_class_name).replace('${MEMBERS}', base_class_serialize)
        base_class_generation += deserialize_base.replace('${BASE_CLASS_NAME}', base_class_name).replace('${CLASS_NAME}', base_class_name).replace('${MEMBERS}', base_class_deserialize).replace('${EXTRA_PARAMETERS}', '')
        f.write(base_class_generation)

        # generate the extra class serialization
        for class_name in class_name_list:
            if class_name == base_class:
                continue
            extra_parameter_txt = ''
            for extra_parameter in extra_parameters:
                extra_parameter_type = ''
                for member in serialize_data[base_class]:
                    if member['name'] == extra_parameter:
                        extra_parameter_type = member['type']
                if len(extra_parameter_type) == 0:
                    raise Exception('Extra parameter type not found')
                extra_parameter_txt += extra_parameter_type + ' ' + extra_parameter + ', '

            if class_name in constructors:
                if len(constructors[class_name]) != 0:
                    raise Exception("Only empty constructors supported right now")
                constructor_parameters = ''
            else:
                constructor_parameters = ', '.join(extra_parameters)

            class_serialize = ''
            class_serialize += base_serialize.replace('${BASE_CLASS_NAME}', base_class_name)
            class_deserialize = f'\tauto result = duckdb::unique_ptr<{class_name}>(new {class_name}({constructor_parameters}));\n'
            for entry in serialize_data[class_name]:
                property_name = entry['property'] if 'property' in entry else entry['name']
                property_key = entry['name']
                is_optional = False
                write_property_name = property_name
                if 'optional' in entry and entry['optional']:
                    is_optional = True
                if entry['type'].endswith('*'):
                    if not is_optional:
                        write_property_name = '*' + property_name
                elif is_optional:
                    raise Exception(f"Optional can only be combined with pointers (in {class_name}, type {entry['type']}, member {entry['name']})")
                deserialize_template_str = deserialize_element_class
                if 'base' in entry:
                    write_property_name = f"({entry['base']} &)" + write_property_name
                    deserialize_template_str = deserialize_element_class_base.replace('${BASE_PROPERTY}', entry['base'].replace('*', '')).replace('${DERIVED_PROPERTY}', entry['type'].replace('*', ''))
                class_serialize += get_serialize_element(write_property_name, property_key, entry['type'], is_optional)
                class_deserialize += get_deserialize_element_template(deserialize_template_str, property_name, property_key, entry['type'], is_optional)

            class_deserialize += '\treturn std::move(result);'

            class_generation = ''
            class_generation += serialize_base.replace('${CLASS_NAME}', class_name).replace('${MEMBERS}', class_serialize)
            class_generation += deserialize_base.replace('${BASE_CLASS_NAME}', base_class_name).replace('${CLASS_NAME}', class_name).replace('${MEMBERS}', class_deserialize).replace('${EXTRA_PARAMETERS}', extra_parameter_txt)


            f.write(class_generation)

        f.write(footer)
