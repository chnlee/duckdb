add_library_unity(
  duckdb_storage_serialization OBJECT serialize_parsed_expression.cpp
  serialize_query_node.cpp serialize_result_modifier.cpp serialize_tableref.cpp)
set(ALL_OBJECT_FILES
    ${ALL_OBJECT_FILES} $<TARGET_OBJECTS:duckdb_storage_serialization>
    PARENT_SCOPE)
