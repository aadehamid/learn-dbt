{% macro show_db_details(schema = target.schema, role = target.user, name = target.name) %}
{{name}}
{{schema}}
{{log('Showing DB schema = ' ~ schema ~ ' plus name = ' ~ name, info = True)}}
{% endmacro %}
