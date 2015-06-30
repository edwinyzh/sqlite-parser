/* Helper Functions */
{
  // Parser utilities
  var _ = require('./parser-util');
}

/* Start Grammar */
start
  = o s:( stmt_list )?
  {
    return {
      'statement': (_.isOkay(s) ? s : [])
    };
  }

stmt_list
  = f:( stmt ) o b:( stmt_list_tail )* c:( sym_semi )*
  { return _.compose([f, b], []); }

/* TODO: Note - you need semicolon between multiple statements, otherwise can omit */
stmt_list_tail
  = ( sym_semi )+ s:( stmt ) o
  { return s; }

/**
 * Expression definition reworked without left recursion for pegjs
 * {@link https://www.sqlite.org/lang_expr.html}
 */
expression "Expression"
  = t:( expression_concat / expression_types ) o
  { return t; }

expression_types
  = expression_wrapped / expression_unary / expression_node / expression_value

expression_concat "Logical Expression Group"
  = l:( expression_types ) o o:( binary_loop_concat ) o r:( expression )
  {
    return {
      'type': 'expression',
      'format': 'binary',
      'variant': 'operation',
      'operation': _.key(o),
      'left': l,
      'right': r,
      'modifier': null
    };
  }

expression_wrapped "Wrapped Expression"
  = sym_popen n:( expression ) o sym_pclose
  { return n; }

expression_value
  = expression_cast
  / expression_exists
  / expression_case
  / expression_raise
  / bind_parameter
  / function_call
  / literal_value
  / id_column

expression_unary "Unary Expression"
  = o:( operator_unary ) e:( expression_types )
  {
    return {
      'type': 'expression',
      'format': 'unary',
      'variant': 'operation',
      'expression': e,
      'operator': _.key(o)
    };
  }

expression_cast "CAST Expression"
  = s:( CAST ) o sym_popen e:( expression ) o a:( type_alias ) o sym_pclose
  {
    return {
      'type': 'expression',
      'format': 'unary',
      'variant': _.key(s),
      'expression': e,
      'modifier': a
    };
  }

type_alias "Type Alias"
  = AS e d:( type_definition )
  { return d; }

expression_exists "EXISTS Expression"
  = n:( expression_exists_ne ) o e:( stmt_select )
  {
    return {
      'type': 'expression',
      'format': 'unary',
      'variant': 'select',
      'expression': e,
      'modifier': n
    };
  }

expression_exists_ne
  = n:( NOT e )? x:( EXISTS ) o
  { return _.compose([n, x]); }

expression_case "CASE Expression"
  = t:( CASE ) e e:( expression )? o w:( expression_case_when )+ o s:( expression_case_else )? o END o
  {
    // TODO: Not sure about this
    return {
      'type': 'expression',
      'format': 'binary',
      'variant': _.key(t),
      'case': e,
      'expression': _.compose([w, s], []),
      'modifier': null
    };
  }


expression_case_when "WHEN Clause"
  = s:( WHEN ) e w:( expression ) o THEN e t:( expression ) o
  {
    return {
      'type': 'condition',
      'format': _.key(s),
      'condition': w,
      'expression': t,
      'modifier': null
    };
  }

expression_case_else "ELSE Clause"
  = s:( ELSE ) e e:( expression ) o
  {
    return {
      'type': 'condition',
      'format': _.key(s),
      'expression': e,
      'modifier': null
    };
  }

/* TODO: Needs final format */
expression_raise "RAISE Expression"
  = s:( RAISE ) o sym_popen o a:( expression_raise_args ) o sym_pclose
  {
    return _.extend({
      'type': 'expression',
      'format': 'unary',
      'variant': _.key(s),
      'modifier': null
    }, a);
  }

expression_raise_args "RAISE Expression Arguments"
  = raise_args_ignore
  / raise_args_message

raise_args_ignore
  = f:( IGNORE )
  { return _.key(f); }

raise_args_message
  = f:( ROLLBACK / ABORT / FAIL ) o sym_comma o m:( error_message )
  {
    return {
      'modifier': _.key(f),
      'message': m
    };
  }

/* Expression Nodes */
expression_node
  = expression_collate
  / expression_compare
  / expression_null
  /*/ expression_is*/
  / expression_between
  / expression_in
  / stmt_select
  / operation_binary

/** @note Removed expression on left-hand-side to remove recursion */
expression_collate "COLLATE Expression"
  = v:( expression_value ) o s:( COLLATE ) e c:( name_collation )
  {
    return _.extend(v, {
      'collate': c
    });
  }

/** @note Removed expression on left-hand-side to remove recursion */
expression_compare
  = v:( expression_value ) o n:( expression_is_not )? m:( LIKE / GLOB / REGEXP / MATCH ) e e:( expression ) o x:( expression_escape )?
  {
    return _.extend({
      'type': 'expression',
      'format': 'binary',
      'variant': 'operation',
      'operation': _.key(_.compose([n, m])),
      'left': v,
      'right': e
    }, x);
  }

expression_escape "ESCAPE Expression"
  = s:( ESCAPE ) o e:( expression )
  {
    return {
      'escape': e
    };
  }

/** @note Removed expression on left-hand-side to remove recursion */
expression_null "NULL Expression"
  = v:( expression_value ) o n:( expression_null_nodes )
  {
    return {
      'type': 'expression',
      'format': 'unary',
      'variant': 'operation',
      'expression': v,
      'operation': n
    };
  }

expression_null_nodes
  = i:( null_nodes_types ) n:( NULL ) e
  { return _.key(_.compose([i, n])); }

null_nodes_types
  = t:( IS / ( NOT o ) )
  { return _.key(t); }

expression_isnt
  = i:( IS ) e n:( expression_is_not )?
  {
    return _.key(_.compose([i, n]));
  }

expression_is_not
  = n:( NOT ) e
  { return _.textNode(n); }

/** @note This rule is now rolled up in operator_binary */
/*expression_is
  = v:( expression_value ) o i:( IS ) e n:( expression_is_not )? e:( expression )
  {
    return {
      'type': 'expression',
      'format': 'binary',
      'variant': 'operation',
      'operation': _.key(_.compose([i, n])),
      'left': v,
      'right': e,
      'modifier': null
    };
  }*/

/** @note Removed expression on left-hand-side to remove recursion */
expression_between "BETWEEN Expression"
  = v:( expression_value ) o n:( expression_is_not )? b:( BETWEEN ) e e1:( expression ) o s:( AND ) e e2:( expression )
  {
    return {
      'type': 'expression',
      'format': 'binary',
      'variant': 'operation',
      'operation': _.key(_.compose([n, b])),
      'left': v,
      'right': {
        'type': 'expression',
        'format': 'binary',
        'variant': 'range',
        'operation': _.key(s),
        'left': e1,
        'right': e2
      },
      'modifier': null
    };
  }


/** @note Removed expression on left-hand-side to remove recursion */
expression_in "IN Expression"
  = v:( expression_value ) o n:( expression_is_not )? i:( IN ) e e:( expression_in_target )
  {
    return {
      'type': 'expression',
      'format': 'binary',
      'variant': 'operation',
      'operation': _.key(_.compose([n, i])),
      'left': v,
      'right': e,
      'modifier': null
    };
  }

expression_in_target
  = expression_list_or_select
  / id_table

expression_list_or_select
  = sym_popen e:( stmt_select / expression_list ) o sym_pclose
  { return e; }


/**
 * Type definitions
 */
 type_definition "Type Definition"
  = n:( datatype_types ) o a:( type_definition_args )?
  {
    return _.extend({
      'type': 'datatype',
      'format': n[0],
      'affinity': n[1],
      'args': [] // datatype definition arguments
    }, a);
  }

type_definition_args "Type Definition Arguments"
  = sym_popen a1:( literal_number_signed ) o a2:( definition_args_loop )? sym_pclose
  {
    return {
      'args': _.compose([a1, a2], [])
    };
  }

definition_args_loop
  = sym_comma o n:( literal_number_signed ) o
  { return n; }

/**
 * Literal value definition
 * {@link https://www.sqlite.org/syntax/literal-value.html}
 */
literal_value "Literal Value"
  = literal_number
  / literal_string
  / literal_blob
  / literal_null
  / literal_date

literal_null "Null Literal"
  = n:( NULL ) o
  {
    return {
      'type': 'literal',
      'variant': 'null',
      'value': _.key(n)
    };
  }

literal_date "Date Literal"
  = d:( CURRENT_DATE / CURRENT_TIMESTAMP / CURRENT_TIME ) o
  {
    return {
      'type': 'literal',
      'variant': 'date',
      'value': _.key(d)
    };
  }

/**
 * Notes:
 *    1) SQL uses single quotes for string literals.
 *    2) Value is an identier or a string literal based on context.
 * {@link https://www.sqlite.org/lang_keywords.html}
 */
literal_string "String Literal"
  = s:( literal_string_single )
  {
    return {
      'type': 'literal',
      'variant': 'string',
      'value': s
    };
  }

literal_string_single "Single-quoted String Literal"
  = sym_sglquote s:( literal_string_schar )* sym_sglquote
  {
    /**
      * @note Unescaped the pairs of literal single quotation marks
      * @note Not sure if the BLOB type should be un-escaped
      */
    return _.unescape(_.textNode(s));
  }

literal_string_schar
  = "''"
  / [^\']

literal_blob "Blob Literal"
  = [x]i b:( literal_string_single )
  {
    return {
      'type': 'literal',
      'variant': 'blob',
      'value': b
    };
  }

number_sign "Number Sign"
  = s:( sym_plus / sym_minus )
  { return _.textNode(s); }

literal_number_signed
  = s:( number_sign )? n:( literal_number )
  {
    if (_.isOkay(s)) {
      n['value'] = _.compose([s, n['value']]);
    }
    return n;
  }

literal_number "Number Literal"
  = literal_number_decimal
  / literal_number_hex

literal_number_decimal
  = d:( number_decimal_node ) e:( number_decimal_exponent )?
  {
    return {
      'type': 'literal',
      'variant': 'decimal',
      'value': _.compose([d, e], '')
    };
  }

number_decimal_node
  = number_decimal_full
  / number_decimal_fraction

number_decimal_full
  = f:( number_digit )+ b:( number_decimal_fraction )?
  { return _.compose([f, b], ''); }

number_decimal_fraction
  = t:( sym_dot ) d:( number_digit )+
  { return _.compose([t, d], ''); }

/* TODO: Not sure about "E"i or just "E" */
number_decimal_exponent
  = e:( "E"i ) s:( [\+\-] )? d:( number_digit )+
  { return _.compose([e, s, d], ''); }

literal_number_hex
  = f:( "0x"i ) b:( number_hex )*
  {
    return {
      'type': 'literal',
      'variant': 'hexidecimal',
      'value': _.compose([f, b], '')
    };
  }

number_hex "Hexidecimal Digit"
  = [0-9a-f]i

number_digit "Decimal Digit"
  = [0-9]

/**
 * Bind Parameters have several syntax variations:
 * 1) "?" ( [0-9]+ )?
 * 2) [\$\@\:] name_char+
 * {@link https://www.sqlite.org/c3ref/bind_parameter_name.html}
 */
bind_parameter "Bind Parameter"
  = bind_parameter_numbered
  / bind_parameter_named
  / bind_parameter_tcl

/**
 * Bind parameters start at index 1 instead of 0.
 */
bind_parameter_numbered "Numbered Bind Parameter"
  = q:( sym_quest ) id:( [1-9] [0-9]* )? o
  {
    return {
      'type': 'variable',
      'format': 'numbered',
      'name': _.compose([q, id], '')
    };
  }

bind_parameter_named "Named Bind Parameter"
  = s:( [\:\@] ) name:( name_char )+ o
  {
    return {
      'type': 'variable',
      'format': 'named',
      'name': _.compose([s, name], '')
    };
  }

bind_parameter_tcl "TCL Bind Parameter"
  = d:( "$" ) name:( name_char / ":" )+ o suffix:( bind_parameter_named_suffix )?
  {
    return {
      'type': 'variable',
      'format': 'tcl',
      'name': _.compose([_.compose([d, name], ''), suffix])
    };
  }

bind_parameter_named_suffix "TCL Bind Parameter Suffix"
  = q1:( sym_dblquote ) n:( !sym_dblquote match_all )* q2:( sym_dblquote )
  { return _.compose([q1, n, q2], ''); }

/** @note Removed expression on left-hand-side to remove recursion */
operation_binary "Binary Expression"
  = v:( expression_value ) o o:( operator_binary ) o e:( expression_types )
  {
    return {
      'type': 'expression',
      'format': 'binary',
      'variant': 'operation',
      'operation': _.key(o),
      'left': v,
      'right': e,
      'modifier': null
    };
  }

binary_loop_concat
  = c:( AND / OR ) e
  { return _.key(c); }

expression_list "Expression List"
  = f:( expression ) o rest:( expression_list_rest )*
  {
    return _.compose([f, rest], []);
  }

expression_list_rest
  = sym_comma e:( expression ) o
  { return e; }

function_call "Function Call"
  = n:( name_function ) sym_popen a:( function_call_args )? o sym_pclose
  {
    return _.extend({
      'type': 'function',
      'name': n,
      'distinct': false,
      'args': []
    }, a);
  }

function_call_args "Function Call Arguments"
  = call_args_star
  / call_args_list

call_args_star
  = s:( select_star )
  {
    return {
      'distinct': false,
      'args': [{
        'type': 'identifier',
        'variant': 'star',
        'name': s
      }]
    };
  }

call_args_list
  = d:( DISTINCT e )? e:( expression_list )
  {
    return {
      'distinct': _.isOkay(d),
      'args': e
    };
  }

error_message "Error Message"
  = m:( literal_string )
  { return m; }

stmt "Statement"
  = m:( stmt_modifier )? s:( stmt_nodes ) o
  {
    return _.extend({
      'modifier': null
    }, m, s);
  }

stmt_modifier "QUERY PLAN"
  = e:( EXPLAIN ) e q:( QUERY e PLAN)? o
  {
    // TODO: Format?
    return {
      'modifier': {
        'type': _.key(e),
        'explain': 'query plan'
      }
    };
  }

stmt_nodes
  = stmt_crud
  / stmt_create
  / stmt_drop
  / stmt_transaction
  / stmt_alter
  / stmt_rollback

stmt_transaction "Transaction"
  = b:( stmt_begin ) s:( stmt_list )? e:( stmt_commit )
  {
    return {
      'type': 'statement',
      'variant': 'transaction',
      'statement': _.isOkay(s) ? s : [],
      'modifier': b
    };
  }

stmt_commit "END Transaction"
  = s:( COMMIT / END ) t:( e TRANSACTION )? o
  {
    return _.key(_.compose([s, t]));
  }

stmt_begin "BEGIN Transaction"
  = s:( BEGIN ) e m:( stmt_begin_modifier )? t:( TRANSACTION e )?
  {
    return _.isOkay(m) ? _.key(m) : null;
  }

stmt_begin_modifier
  = m:( DEFERRED / IMMEDIATE / EXCLUSIVE ) e
  { return _.key(m); }

stmt_rollback "ROLLBACK Statement"
  = s:( ROLLBACK ) e ( TRANSACTION e )? n:( rollback_savepoint )?
  {
    return {
      'type': 'statement',
      'variant': _.key(s),
      'savepoint': n
    };
  }

rollback_savepoint "SAVEPOINT"
  = TO e ( savepoint_alt )? n:( id_savepoint ) o
  { return n; }

savepoint_alt
  = s:( SAVEPOINT ) e
  { return _.key(s); }

stmt_alter "ALTER TABLE Statement"
  = s:( alter_start ) n:( id_table ) o e:( alter_action ) o
  {
    return {
      'type': 'statement',
      'variant': _.key(s)
    };
  }

alter_start
  = a:( ALTER ) e t:( TABLE ) e
  { return _.compose([a, t]); }

alter_action
  = alter_action_rename
  / alter_action_add

alter_action_rename
  = s:( RENAME ) e TO e n:( id_table )
  {
    return {
      'action': _.key(s),
      'name': n
    };
  }

alter_action_add
  = s:( ADD ) e ( action_add_modifier )? d:( source_def_column )
  {
    return {
      'action': _.key(s),
      'definition': d
    };
  }

action_add_modifier
  = s:( COLUMN ) e
  { return _.key(s); }

stmt_crud
  = w:( clause_with )? o s:( stmt_crud_types )
  { return _.extend(s, w); }

clause_with "WITH Clause"
  = s:( WITH ) e v:( clause_with_recursive )? f:( expression_table ) o r:( clause_with_loop )*
  {
    // TODO: final format
    return {
      'with': {
        'type': _.key(s),
        'recursive': _.isOkay(v),
        'expression': _.compose([f, r], [])
      }
    };
  }

clause_with_recursive
  = s:( RECURSIVE ) e
  { return _.key(s); }

clause_with_loop
  = sym_comma e:( expression_table )
  { return e; }

expression_table "Table Expression"
  = n:( name_table ) o a:( loop_columns )? o AS o sym_popen s:( stmt_select ) o sym_pclose o
  {
    return _.extend({
      'type': 'expression',
      'format': 'table',
      'name': _.key(n),
      'expression': s,
      'columns': null
    }, a);
  }

stmt_crud_types
  = stmt_select
  / stmt_insert
  / stmt_update
  / stmt_delete

/** {@link https://www.sqlite.org/lang_select.html} */
stmt_select "SELECT Statement"
  = s:( select_loop ) o o:( stmt_core_order )? o l:( stmt_core_limit )?
  {
    return _.extend(s, {
      'order': o,
      'limit': l
    });
  }

stmt_core_order
  = ORDER e BY e d:( stmt_core_order_list )
  { return d; }

stmt_core_limit
  = s:( LIMIT ) e e:( expression ) o d:( stmt_core_limit_offset )?
  {
    return {
      'start': e,
      'offset': d
    };
  }

stmt_core_limit_offset
  = o:( limit_offset_variant ) e:( expression )
  { return e; }

limit_offset_variant
  = limit_offset_variant_name
  / sym_comma

limit_offset_variant_name
  = s:( OFFSET ) e
  { return _.key(s); }

select_loop
  = s:( select_parts ) o u:( select_loop_union )*
  {
    if (_.isArray(u) && u.length) {
      // TODO: Not final format
      return {
        'type': 'statement',
        'variant': 'compound',
        'statement': s,
        'compound': u
      };
    } else {
      return s;
    }
  }

/* TODO: Not final format */
select_loop_union
  = c:( operator_compound ) o s:( select_parts ) o
  {
    return {
      'type': 'compound',
      'variant': c,
      'statement': s
    };
  }

select_parts
  = select_parts_core
  / select_parts_values

select_parts_core
  = s:( select_core_select ) f:( select_core_from )? w:( stmt_core_where )? g:( select_core_group )?
  {
    return _.extend({
      'type': 'statement',
      'variant': 'select',
      'from': [],
      'where': w,
      'group': g
    }, s, f);
  }

select_core_select
  = SELECT e d:( select_modifier )? o t:( select_target )
  {
    return _.extend({
      'result': t,
      'distinct': false,
      'all': false
    }, d);
  }

select_modifier
  = select_modifier_distinct
  / select_modifier_all

select_modifier_distinct
  = s:( DISTINCT ) e
  {
    return {
      'distinct': true
    };
  }

select_modifier_all
  = s:( ALL ) e
  {
    return {
      'all': true
    };
  }

select_target
  = f:( select_node ) o r:( select_target_loop )*
  { return _.compose([f, r], []); }

select_target_loop
  = sym_comma n:( select_node ) o
  { return n; }

select_core_from "FROM Clause"
  = s:( FROM ) e s:( select_source ) o
  {
    return {
      'from': s
    };
  }

stmt_core_where
  = s:( WHERE ) e e:( expression ) o
  { return _.makeArray(e); }

select_core_group
  = s:( GROUP ) e BY e e:( expression_list ) o h:( select_core_having )?
  {
    // TODO: format
    return {
      'expression': _.makeArray(e),
      'having': h
    };
  }

select_core_having
  = s:( HAVING ) e e:( expression ) o
  { return e; }

select_node
  = select_node_star
  / select_node_aliased

select_node_star
  = q:( select_node_star_qualified )? s:( select_star )
  {
    return {
      'type': 'identifier',
      'variant': 'star',
      'name': _.compose([q, s], '')
    };
  }

select_node_star_qualified
  = n:( name_table ) s:( sym_dot )
  { return _.compose([n, s], ''); }

select_node_aliased
  = e:( expression ) o a:( alias )?
  {
    // TODO: format
    return _.extend(e, {
      'alias': a
    });
  }

select_source
  = select_join_loop
  / select_source_loop

select_source_loop
  = f:( table_or_sub ) o t:( source_loop_tail )*
  { return _.compose([f, t], []); }

source_loop_tail
  = sym_comma t:( table_or_sub ) o
  { return t; }

table_or_sub
  = table_or_sub_sub
  / table_qualified
  / table_or_sub_select

table_qualified
  = d:( table_qualified_id ) o i:( table_or_sub_index_node )
  {
    return _.extend(d, i);
  }

table_qualified_id
  = n:( id_table ) o a:( alias )?
  {
    return _.extend(n, {
      'alias': a
    });
  }


table_or_sub_index_node
  = i:( index_node_indexed / index_node_none )?
  {
    return {
      'index': i
    };
  }

index_node_indexed
  = s:( INDEXED ) e BY e n:( name_index ) o
  { return n; }

index_node_none
  = NOT e INDEXED o
  { return null; }

table_or_sub_sub
  = sym_popen l:( select_source ) o sym_pclose
  { return l; }

table_or_sub_select
  = sym_popen s:( stmt_select ) o sym_pclose a:( alias )?
  {
    return _.extend({
      'alias': a
    }, s);
  }

alias
  = a:( AS e )? n:( name ) o
  { return n; }

select_join_loop
  = t:( table_or_sub ) o j:( select_join_clause )+
  {
    // TODO: format
    return {
      'type': 'map',
      'variant': 'join',
      'source': t,
      'map': j
    };
  }

select_join_clause
  = o:( join_operator ) o n:( table_or_sub ) o c:( join_condition )?
  {
    // TODO: format
    return _.extend({
      'type': 'join',
      'variant': _.key(o),
      'source': n,
      'on': null,
      'using': null
    }, c);
  }

join_operator
  = n:( join_operator_natural )? o t:( join_operator_types )? j:( JOIN )
  { return _.compose([n, t, j]); }

join_operator_natural
  = n:( NATURAL ) e
  { return _.textNode(n); }

join_operator_types
  = operator_types_hand
  / operator_types_misc

operator_types_hand
  = t:( LEFT / RIGHT / FULL ) e o:( types_hand_outer )?
  { return _.compose([t, o]); }

types_hand_outer
  = t:( OUTER ) e
  { return _.textNode(t); }

operator_types_misc
  = t:( INNER / CROSS ) e
  { return _.textNode(t); }

join_condition
  = c:( join_condition_on / join_condition_using )
  { return c; }

join_condition_on
  = s:( ON ) e e:( expression )
  {
    return {
      'on': e
    };
  }

/* TODO: should it be name_column or id_column ? */
join_condition_using
  = s:( USING ) e f:( id_column ) o b:( join_condition_using_loop )*
  {
    return {
      'using': _.compose([f, b], [])
    };
  }

/* TODO: should it be name_column or id_column ? */
join_condition_using_loop
  = sym_comma n:( id_column ) o
  { return n; }

select_parts_values
  = s:( VALUES ) o l:( insert_values_list )
  {
    // TODO: format
    return {
      'type': 'statement',
      'variant': 'select',
      'result': l,
      'from': null,
      'where': null,
      'group': null
    };
  }

stmt_core_order_list
  = f:( stmt_core_order_list_item ) o b:( stmt_core_order_list_loop )?
  {
    return _.compose([f, b], []);
  }

stmt_core_order_list_loop
  = sym_comma i:( stmt_core_order_list_item ) o
  { return i; }

stmt_core_order_list_item
  = e:( expression ) o c:( column_collate )? o d:( stmt_core_order_list_dir )?
  {
    // TODO: Not final format
    return {
      'direction': _.textNode(d) /*|| 'ASC'*/,
      'expression': e,
      'collate': c
    };
  }

stmt_core_order_list_dir
  = primary_column_dir

select_star "All Columns"
  = sym_star

stmt_fallback_types
  = k:( REPLACE / ROLLBACK / ABORT / FAIL / IGNORE )
  { return k; }

/** {@link https://www.sqlite.org/lang_insert.html} */
stmt_insert "INSERT Statement"
  = k:( insert_keyword ) o t:( insert_target ) o p:( insert_parts )
  {
    // TODO: Not final syntax!
    return _.extend({
      'type': 'statement',
      'variant': 'insert',
      'into': null,
      'action': null,
      'or': null,
      'result': []
    }, k, t, p);
  }

insert_keyword
  = insert_keyword_ins
  / insert_keyword_repl

insert_keyword_ins
  = a:( INSERT ) e m:( insert_keyword_mod )?
  {
    return _.extend({
      'action': _.key(a)
    }, m);
  }

insert_keyword_repl
  = a:( REPLACE ) e
  {
    return {
      'action': _.key(a)
    };
  }

insert_keyword_mod
  = s:( OR ) e m:( stmt_fallback_types )
  {
    return {
      'or': _.key(m)
    };
  }

insert_target
  = s:( INTO ) e id:( id_table ) o cols:( loop_columns )?
  {
    return {
      'into': _.extend({
        'target': id,
        'columns': null
      }, cols)
    };
  }

loop_columns
  = sym_popen f:( loop_name_column ) o b:( loop_column_tail )* sym_pclose
  {
    return {
      'columns': _.compose([f, b], [])
    };
  }

loop_column_tail
  = sym_comma c:( loop_name_column ) o
  { return c; }

loop_name_column
  = n:( name_column )
  {
    return {
      'type': 'identifier',
      'variant': 'column',
      'name': n
    };
  }

insert_parts
  = r:( insert_value / stmt_select / insert_default ) o
  {
    return {
      'result': r
    };
  }

insert_value
  = s:( VALUES ) o r:( insert_values_list )
  { return r; }

insert_values_list
  = f:( insert_values ) o b:( insert_values_loop )*
  { return _.compose([f, b], []); }

insert_values_loop
  = sym_comma e:( insert_values ) o
  { return e; }

insert_values
  = sym_popen e:( expression_list ) o sym_pclose
  {
    return {
      'type': 'values',
      'variant': 'list',
      'values': e
    };
  }

insert_default
  = d:( DEFAULT ) e v:( VALUES )
  {
    return {
      'type': 'values',
      'variant': 'default',
      'values': null
    };
  }

operator_compound "Compound Operator"
  = s:( compound_union / INTERSECT / EXCEPT )
  { return _.key(s); }

compound_union
  = s:( UNION ) a:( compound_union_all )?
  { return _.compose([s, a]); }

compound_union_all
  = e a:( ALL )
  { return a; }

/* Unary and Binary Operators */

operator_unary "Unary Operator"
  = sym_tilde
  / sym_minus
  / sym_plus
  / expression_is_not

/* TODO: Needs return format refactoring */
operator_binary "Binary Operator"
  = o:( binary_concat / expression_isnt
  / binary_multiply / binary_mod
  / binary_plus / binary_minus
  / binary_left / binary_right / binary_and / binary_or
  / binary_lte / binary_lt / binary_gte / binary_gt
  / binary_lang / binary_notequal / binary_equal )
  { return _.key(o); }

binary_concat "Or"
  = sym_pipe sym_pipe

binary_plus "Add"
  = sym_plus

binary_minus "Subtract"
  = sym_minus

binary_multiply "Multiply"
  = sym_star

binary_mod "Modulo"
  = sym_mod

binary_left "Shift Left"
  = sym_lt sym_lt

binary_right "Shift Right"
  = sym_gt sym_gt

binary_and "Logical AND"
  = sym_amp

binary_or "Logical OR"
  = sym_pipe

binary_lt "Less Than"
  = sym_lt

binary_gt "Greater Than"
  = sym_gt

binary_lte "Less Than Or Equal"
  = sym_lt sym_equal

binary_gte "Greater Than Or Equal"
  = sym_gt sym_equal

binary_equal "Equal"
  = sym_equal ( sym_equal )?

binary_notequal "Not Equal"
  = ( sym_excl sym_equal )
  / ( sym_lt sym_gt )

binary_lang
  = binary_lang_isnt
  / binary_lang_misc

binary_lang_isnt "IS"
  = i:( IS ) e n:( NOT e )?
  { return _.key(_.compose([i, n])); }

binary_lang_misc "Misc Binary Operator"
  = m:( IN / LIKE / GLOB / MATCH / REGEXP )
  { return _.key(m); }

/* Database, Table and Column IDs */

id_database "Database Identifier"
  = n:( name_database )
  {
    return {
      'type': 'identifier',
      'variant': 'database',
      'name': n
    };
  }

id_table "Table Identifier"
  = d:( id_table_qualified )? n:( name_table )
  {
    return {
      'type': 'identifier',
      'variant': 'table',
      'name': _.compose([d, n], '')
    };
  }

id_table_qualified "Qualified Table Identifier"
  = n:( name_database ) d:( sym_dot )
  { return _.compose([n, d], ''); }

id_column "Column Identifier"
  = d:( id_table_qualified )? t:( id_column_qualified )? n:( name_column )
  {
    return {
      'type': 'identifier',
      'variant': 'column',
      'name': _.compose([d, t, n], '')
    };
  }

id_column_qualified "Qualified Column Identifier"
  = t:( name_table ) d:( sym_dot )
  { return _.compose([t, d], ''); }

id_collation "Collation Identifier"
  = n:( name_collation )
  {
    return {
      'type': 'identifier',
      'variant': 'collation',
      'name': n
    };
  }

id_savepoint "Savepoint Indentifier"
  = n:( name )
  {
    return {
      'type': 'identifier',
      'variant': 'savepoint',
      'name': n
    };
  }

id_index "Index Identifier"
  = d:( id_table_qualified )? n:( name_index )
  {
    return {
      'type': 'identifier',
      'variant': 'index',
      'name': _.compose([d, n], '')
    };
  }

id_trigger "Trigger Identifier"
  = d:( id_table_qualified )? n:( name_trigger )
  {
    return {
      'type': 'identifier',
      'variant': 'trigger',
      'name': _.compose([d, n], '')
    };
  }

id_view "View Identifier"
  = d:( id_table_qualified )? n:( name_view )
  {
    return {
      'type': 'identifier',
      'variant': 'view',
      'name': _.compose([d, n], '')
    };
  }

/* TODO: FIX all name_* symbols */
name_database "Database Name"
  = name

name_table "Table Name"
  = name

name_column "Column Name"
  = name

name_constraint_table "Table Constraint Name"
  = name

name_constraint_column "Column Constraint Name"
  = name

name_collation "Collation Name"
  = name

name_index "Index Name"
  = name

name_trigger "Trigger Name"
  = name

name_view "View Name"
  = name

name_function "Function Name"
  = name

name_module "Module Name"
  = name

/* Column datatypes */

datatype_types "Datatype Name"
  = t:( datatype_text ) { return [t, 'text']; }
  / t:( datatype_real ) { return [t, 'real']; }
  / t:( datatype_numeric ) { return [t, 'numeric']; }
  / t:( datatype_integer ) { return [t, 'integer']; }
  / t:( datatype_none ) { return [t, 'none']; }

datatype_text "TEXT Datatype Name"
  = t:( ( ( "N"i )? ( "VAR"i )? "CHAR"i )
  / ( ( "TINY"i / "MEDIUM"i / "LONG"i )? "TEXT"i )
  / "CLOB"i )
  { return _.key(t); }

datatype_real "REAL Datatype Name"
  = t:( ( "DOUBLE"i ( e "PRECISION"i )? )
  / "FLOAT"i
  / "REAL"i )
  { return _.key(t); }

datatype_numeric "NUMERIC Datatype Name"
  = t:( "NUMERIC"i
  / "DECIMAL"i
  / "BOOLEAN"i
  / ( "DATE"i ( "TIME"i )? )
  / ( "TIME"i ( "STAMP"i )? ) )
  { return _.key(t); }

datatype_integer "INTEGER Datatype Name"
  = t:( ( "INT"i ( "2" / "4" / "8" / "EGER"i ) )
  / ( ( "BIG"i / "MEDIUM"i / "SMALL"i / "TINY"i )? "INT"i ) )
  { return _.key(t); }

datatype_none "BLOB Datatype Name"
  = t:( "BLOB"i )
  { return _.key(t); }

/**
 * @note Includes limited update syntax {@link https://www.sqlite.org/syntax/update-stmt-limited.html}
 */
stmt_update "UPDATE Statement"
  = u:( clause_with )? o s:( update_start ) f:( update_fallback )? t:( table_qualified ) o u:( update_set ) w:( stmt_core_where )? o:( stmt_core_order )? o l:( stmt_core_limit )?
  {
    // TODO: Not final syntax!
    return _.extend({
      'type': 'statement',
      'variant': s,
      'into': t,
      'where': w,
      'set': [],
      'order': o,
      'limit': l
    }, u, f);
  }

update_start "UPDATE"
  = s:( UPDATE ) e
  { return _.key(s); }

update_fallback "Update Fallback"
  = OR e t:( stmt_fallback_types ) e
  {
    return {
      'or': _.key(t)
    };
  }

update_set "Update SET"
  = SET e c:( update_columns ) o
  {
    return {
      'set': c
    };
  }

update_columns
  = f:( update_column ) b:( update_columns_tail )*
  { return _.compose([f, b], []); }

update_columns_tail
  = o sym_comma c:( update_column )
  { return c; }

update_column
  = f:( id_column ) o sym_equal e:( expression_types ) o
  {
    return {
      'type': 'assignment',
      'target': f,
      'value': e
    };
  }

/**
 * @note Includes limited update syntax {@link https://www.sqlite.org/syntax/delete-stmt-limited.html}
 */
stmt_delete "DELETE Statement"
  = u:( clause_with )? o s:( delete_start ) t:( table_qualified ) o w:( stmt_core_where )? o:( stmt_core_order )? l:( stmt_core_limit )?
  {
    // TODO: Not final syntax!
    return _.extend({
      'type': 'statement',
      'variant': s,
      'from': t,
      'where': w,
      'order': o,
      'limit': l
    }, u);
  }

delete_start
  = s:( DELETE ) e FROM e
  { return _.key(s); }

/* TODO: Complete */
stmt_create "CREATE Statement"
  = create_table
  / create_index
  / create_trigger
  / create_view
  / create_virtual

create_table "CREATE Table"
  = s:( CREATE ) e tmp:( create_core_tmp )? t:( TABLE ) e ne:( create_core_ine )?
    id:( id_table ) o r:( create_table_source )
  {
    return _.extend({
      'type': 'statement',
      'variant': _.key(s),
      'format': _.key(t),
      'temporary': _.isOkay(tmp),
      'target': id,
      'conditions': _.compose([ne], []),
      'modifier': null,
      'definition': []
    }, r);
  }

create_core_tmp
  = t:( TEMP / TEMPORARY ) e
  { return _.key(t); }

create_core_ine
  = i:( IF ) e n:( NOT ) e e:( EXISTS ) e
  {
    return {
      'type': 'condition',
      'condition': _.key(_.compose([i, n, e]))
    };
  }

create_table_source
  = table_source_def
  / table_source_select

table_source_def "Table Definition"
  = sym_popen s:( source_def_loop ) t:( source_tbl_loop )* sym_pclose r:( source_def_rowid )?
  {
    return {
      'definition': _.compose([s, t], []),
      'modifier': r
    };
  }

source_def_rowid
  = r:( WITHOUT e ROWID ) o
  { return _.key(r); }

source_def_loop "Column Definitions"
  = f:( source_def_column ) o b:( source_def_tail )*
  { return _.compose([f, b], []); }

source_def_tail
  = sym_comma t:( source_def_column ) o
  { return t; }

source_tbl_loop "Table Constraint Definitions"
  = sym_comma f:( table_constraint )
  { return f; }

/** {@link https://www.sqlite.org/syntaxdiagrams.html#column-def} */
source_def_column "Column Definition"
  = n:( name_column ) (! name_char o ) t:( column_type )? o c:( column_constraints )?
  {
    return _.extend({
      'type': 'definition',
      'variant': 'column',
      'name': n,
      'definition': (_.isOkay(c) ? c : []),
      'datatype': null
    }, t);
  }

column_type "Column Datatype"
  = t:( type_definition )
  {
    return {
      'datatype': t
    };
  }

column_constraints
  = f:( column_constraint ) b:( column_constraint_tail )* o
  { return _.compose([f, b], []); }

column_constraint_tail
  = o c:( column_constraint )
  { return c; }

/** {@link https://www.sqlite.org/syntax/column-constraint.html} */
column_constraint "Column Constraint"
  = n:( column_constraint_name )? c:( column_constraint_types )
  {
    return _.extend({
      'name': n
    }, c);
  }

column_constraint_name
  = CONSTRAINT e n:( name_constraint_column ) o
  { return n; }

column_constraint_types
  = column_constraint_primary
  / column_constraint_null
  / constraint_check
  / column_constraint_default
  / column_constraint_collate
  / column_constraint_foreign

column_constraint_foreign
  = f:( foreign_clause )
  {
    return _.extend({
      'variant': 'foreign key'
    }, f);
  }

column_constraint_primary
  = p:( col_primary_start ) d:( col_primary_dir )? c:( primary_conflict )? a:( col_primary_auto )? o
  {
    return _.extend(p, c, d, a);
  }

col_primary_start
  = s:( PRIMARY ) e k:( KEY ) o
  {
    return {
      'type': 'constraint',
      'variant': _.key(_.compose([s, k])),
      'conflict': null,
      'direction': null,
      'modififer': null,
      'autoIncrement': false
    };
  }

col_primary_dir
  = d:( primary_column_dir ) o
  {
    return {
      'direction': _.key(d)
    };
  }

col_primary_auto
  = a:( AUTOINCREMENT ) o
  {
    return {
      'autoIncrement': true
    };
  }

column_constraint_null
  = s:( constraint_null_types ) c:( primary_conflict )? o
  {
    return _.extend({
      'type': 'constraint',
      'variant': s,
      'conflict': null
    }, c);
  }

constraint_null_types
  = t:( ( NOT e NULL )
  / UNIQUE ) o
  { return _.key(t); }

column_constraint_default
  = s:( DEFAULT ) v:( col_default_val )
  {
    return {
      'type': 'constraint',
      'variant': _.key(s),
      'value': v
    };
  }

col_default_val
  = ( o v:( expression_wrapped ) ) { return v; }
  / ( e v:( literal_number_signed ) ) { return v; }
  / ( e v:( literal_value ) ) { return v; }

column_constraint_collate
  = c:( column_collate )
  {
    return {
      'type': 'constraint',
      'variant': 'collate',
      'collate': c
    };
  }

/** {@link https://www.sqlite.org/syntax/table-constraint.html} */
table_constraint "Table Constraint"
  = n:( table_constraint_name )? o c:( table_constraint_types ) o
  {
    return _.extend({
      'type': 'definition',
      'variant': 'constraint',
      'name': n,
      'definition': null
    }, c);
  }

table_constraint_name
  = CONSTRAINT e n:( name_constraint_table )
  { return n; }

table_constraint_types
  = table_constraint_foreign
  / table_constraint_primary
  / table_constraint_check

table_constraint_check
  = c:( constraint_check )
  {
    return {
      'definition': _.makeArray(c)
    };
  }

table_constraint_primary
  = k:( primary_start ) o c:( primary_columns ) t:( primary_conflict )?
  {
    return {
      'definition': _.makeArray(_.extend(k, t)),
      'columns': c
    };
  }

primary_start
  = s:( primary_start_normal / primary_start_unique ) o
  {
    return {
      'type': 'constraint',
      'variant': _.key(s),
      'conflict': null
    };
  }

primary_start_normal
  = p:( PRIMARY ) e k:( KEY )
  { return _.compose([p, k]); }

primary_start_unique
  = u:( UNIQUE )
  { return _.textNode(u); }

primary_columns
  = sym_popen f:( primary_column ) o b:( primary_column_tail )* sym_pclose
  { return _.compose([f, b], []); }

primary_column "Indexed Column"
  = e:( name_column ) o c:( column_collate )? d:( primary_column_dir )?
  {
    // TODO: Not final format
    return {
      'type': 'identifier',
      'variant': 'column',
      'format': 'indexed',
      'direction': _.key(d) /*|| "ASC"*/,
      'name': e,
      'collate': c
    };
  }

column_collate
  = COLLATE e n:( id_collation ) o
  { return n; }

primary_column_dir
  = t:( ASC / DESC ) o
  { return _.textNode(t); }

primary_column_tail
  = sym_comma c:( primary_column ) o
  { return c; }

primary_conflict
  = o:( ON ) e c:( CONFLICT ) e t:( stmt_fallback_types ) o
  {
    return {
      'conflict': _.key(t)
    };
  }

constraint_check
  = k:( CHECK ) o c:( expression_wrapped )
  {
    return {
      'type': 'constraint',
      'variant': _.key(k),
      'expression': c
    };
  }

table_constraint_foreign
  = k:( foreign_start ) o l:( loop_columns ) o c:( foreign_clause ) o
  {
    return _.extend({
      'definition': _.makeArray(_.extend(k, c)),
      'columns': null
    }, l);
  }

foreign_start
  = f:( FOREIGN ) e k:( KEY )
  {
    return {
      'type': 'constraint',
      'variant': _.key(_.compose([f, k])),
      'target': null,
      'columns': null,
      'action': null,
      'deferrable': null
    };
  }

/** {@link https://www.sqlite.org/syntax/foreign-key-clause.html} */
foreign_clause
  = r:( foreign_references ) a:( foreign_actions )? d:( foreign_deferrable )?
  {
    return _.extend({
      'type': 'constraint',
      'action': a,
      'deferrable': d
    }, r);
  }

foreign_references
  = REFERENCES e t:( id_table ) o c:( loop_columns )?
  {
    // TODO: FORMAT?
    return _.extend({
      'target': t,
      'columns': null
    }, c);
  }

foreign_actions
  = f:( foreign_action ) o b:( foreign_actions_tail )* o
  { return _.collect([f, b], []); }

foreign_actions_tail
  = e a:( foreign_action )
  { return a; }

/* TODO: action format? */
foreign_action
  = foreign_action_on
  / foreign_action_match

foreign_action_on
  = m:( ON ) e a:( DELETE / UPDATE ) e n:( action_on_action )
  {
    return {
      'type': 'action',
      'variant': _.key(m),
      'action': n
    };
  }

action_on_action
  = a:( ( SET e ( NULL / DEFAULT ) )
  / ( CASCADE / RESTRICT )
  / ( NO e ACTION ) )
  { return _.key(a); }

/* TODO: name format? */
foreign_action_match
  = m:( MATCH ) e n:( name )
  {
    return {
      'type': 'action',
      'variant': _.key(m),
      'action': n
    };
  }

foreign_deferrable
  = n:( NOT e )? d:( DEFERRABLE ) i:( e INITIALLY e ( DEFERRED / IMMEDIATE ) )?
  { return _.collect([n, d, i]); }

table_source_select
  = AS e s:( stmt_select )
  {
    return {
      'definition': _.makeArray(s)
    };
  }

/* TODO: Left off here */
create_index "CREATE Index"
  = s:( CREATE ) e u:( index_unique )? i:( INDEX ) e ne:( create_core_ine )?
    n:( id_index ) o o:( index_on ) w:( stmt_core_where )?
  {
    return _.extend({
      'type': 'statement',
      'variant': _.key(s),
      'format': _.key(i),
      'target': n,
      'where': w,
      'on': o,
      'conditions': _.compose([ne], []),
      'unique': false
    }, u);
  }

index_unique
  = u:( UNIQUE ) e
  {
    return {
      'unique': true
    };
  }

index_on
  = o:( ON ) e t:( name_table ) o c:( primary_columns )
  {
    return {
      'target': t,
      'columns': c
    };
  }

/**
 * @note
 *  This statement type has missing syntax restrictions that need to be
 *  enforced on UPDATE, DELETE, and INSERT statements in the trigger_action.
 *  See {@link https://www.sqlite.org/lang_createtrigger.html}.
 */
create_trigger "CREATE Trigger"
  = s:( CREATE ) e p:( create_core_tmp )? t:( TRIGGER ) e ne:( create_core_ine )?
    n:( id_trigger ) o cd:( trigger_conditions ) ( ON ) e o:( name_table ) o
    me:( trigger_foreach )? wh:( trigger_when )? a:( trigger_action )
  {
    return {
      'type': 'statement',
      'variant': _.key(s),
      'format': _.key(t),
      'when': wh,
      'target': n,
      'on': o,
      'conditions': ne,
      'event': cd,
      'temporary': _.isOkay(p),
      'by': (_.isOkay(me) ? me : 'row'),
      'action': _.makeArray(a)
    };
  }

trigger_conditions
  = m:( trigger_apply_mods )? d:( trigger_do )
  {
    return _.extend({
      'type': 'event',
      'occurs': null
    }, m, d);
  }

trigger_apply_mods
  = m:( BEFORE / AFTER / trigger_apply_instead ) e
  {
    return {
      'occurs': _.key(m)
    };
  }

trigger_apply_instead
  = i:( INSTEAD ) e o:( OF )
  { return _.compose([i, o]); }

trigger_do
  = trigger_do_on
  / trigger_do_update

trigger_do_on
  = o:( DELETE / INSERT ) e
  {
    return {
      'event': _.key(o)
    };
  }

trigger_do_update
  = s:( UPDATE ) e f:( do_update_of )?
  {
    return {
      'event': _.key(s),
      'of': f
    };
  }

do_update_of
  = s:( OF ) e c:( do_update_columns )
  { return c; }

do_update_columns
  = f:( loop_name_column ) o b:( loop_column_tail )*
  { return _.compose([f, b], []); }

/**
 *  @note
 *    FOR EACH STATEMENT is not supported by SQLite, but still included here.
 *    See {@link https://www.sqlite.org/lang_createtrigger.html}.
 */
trigger_foreach
  = f:( FOR ) e e:( EACH ) e r:( ROW / "STATEMENT"i ) e
  { return _.key(r); }

trigger_when
  = w:( WHEN ) e e:( expression ) o
  { return e; }

trigger_action
  = s:( BEGIN ) e a:( action_loop ) o e:( END ) o
  { return a; }

action_loop
  = l:( action_loop_stmt )+
  { return l; }

action_loop_stmt
  = s:( stmt ) o c:( sym_semi )
  { return s; }

create_view "CREATE View"
  = s:( CREATE ) e p:( create_core_tmp )? v:( VIEW ) e ne:( create_core_ine )?
    n:( id_view ) o ( AS ) o r:( stmt_select ) o
  {
    return {
      'type': 'statement',
      'variant': _.key(s),
      'format': _.key(v),
      'conditions': ne,
      'temporary': _.isOkay(p),
      'target': n,
      'result': r
    };
  }

/**
 *  @note
 *    This currently only works with expression arguments and does not
 *    support passing column definitions and/or table constraint definitions
 *    as is allowed in the SQLite spec for virtual table module arguments.
 *    See {@link https://www.sqlite.org/lang_createvtab.html}.
 */
create_virtual "CREATE Virtual Table"
  = s:( CREATE ) e v:( VIRTUAL ) e t:( TABLE ) e ne:( create_core_ine )?
    n:( id_table ) e ( USING ) e m:( name_module ) o a:( virtual_args )?
  {
    return {
      'type': 'statement',
      'variant': _.key(s),
      'format': _.key(v),
      'conditions': ne,
      'target': n,
      'result': {
        'type': 'module',
        'name': m,
        'args': (_.isOkay(a) ? a : [])
      }
    };
  }

virtual_args
  = sym_popen f:( virtual_arg_types ) o sym_pclose
  { return f; }

virtual_arg_types
  = ( !( name_column o ( type_definition / column_constraint ) ) l:( expression_list ) ) { return l; }
  / ( l:( source_def_loop ) ) { return l; }

stmt_drop "DROP Statement"
  = s:( drop_start ) t:( drop_types ) i:( drop_ie )? q:( id_table ) o
  {
    return {
      'type': 'statement',
      'variant': s,
      'format': t,
      'target': q,
      'conditions': (_.isOkay(i) ? [i] : [])
    };
  }

drop_start
  = s:( DROP ) e
  { return _.key(s); }

drop_types
  = t:( TABLE / INDEX / TRIGGER / VIEW ) e
  { return _.key(t); }

drop_ie
  = i:( IF ) e e:( EXISTS ) e
  {
    return {
      'type': 'condition',
      'condition': _.key(_.compose([i, e]))
    };
  }

/* Naming rules */

/* TODO: Replace me! */
name_char
  = [a-z0-9\-\_]i

name_char_quoted
  = [a-z0-9\-\_ ]i

name
  = name_bracketed
  / name_backticked
  / name_dblquoted
  / name_unquoted

reserved_nodes
  = ( datatype_types / reserved_words ) !name_char

name_unquoted
  = !reserved_nodes n:( name_char )+
  { return _.textNode(n); }

/** @note Non-standard legacy format */
name_bracketed
  = sym_bopen n:( !sym_bclose name_char_quoted )+ o sym_bclose
  { return _.textNode(n); }

name_dblquoted
  = '"' n:( !'"' name_char_quoted )+ '"'
  { return _.textNode(n); }

/** @note Non-standard legacy format */
name_backticked
  = '`' n:( !'`' name_char_quoted )+ '`'
  { return _.textNode(n); }

/* Symbols */

sym_bopen "Open Bracket"
  = s:( "[" ) o { return _.textNode(s); }
sym_bclose "Close Bracket"
  = s:( "]" ) o { return _.textNode(s); }
sym_popen "Open Parenthesis"
  = s:( "(" ) o { return _.textNode(s); }
sym_pclose "Close Parenthesis"
  = s:( ")" ) o { return _.textNode(s); }
sym_comma "Comma"
  = s:( "," ) o { return _.textNode(s); }
sym_dot "Period"
  = s:( "." ) o { return _.textNode(s); }
sym_star "Asterisk"
  = s:( "*" ) o { return _.textNode(s); }
sym_quest "Question Mark"
  = s:( "?" ) o { return _.textNode(s); }
sym_sglquote "Single Quote"
  = s:( "'" ) o { return _.textNode(s); }
sym_dblquote "Double Quote"
  = s:( '"' ) o { return _.textNode(s); }
sym_backtick "Backtick"
  = s:( "`" ) o { return _.textNode(s); }
sym_tilde "Tilde"
  = s:( "~" ) o { return _.textNode(s); }
sym_plus "Plus"
  = s:( "+" ) o { return _.textNode(s); }
sym_minus "Minus"
  = s:( "-" ) o { return _.textNode(s); }
sym_equal "Equal"
  = s:( "=" ) o { return _.textNode(s); }
sym_amp "Ampersand"
  = s:( "&" ) o { return _.textNode(s); }
sym_pipe "Pipe"
  = s:( "|" ) o { return _.textNode(s); }
sym_mod "Modulo"
  = s:( "%" ) o { return _.textNode(s); }
sym_lt "Less Than"
  = s:( "<" ) o { return _.textNode(s); }
sym_gt "Greater Than"
  = s:( ">" ) o { return _.textNode(s); }
sym_excl "Exclamation"
  = s:( "!" ) o { return _.textNode(s); }
sym_semi "Semicolon"
  = s:( ";" ) o { return _.textNode(s); }
sym_colon "Colon"
  = s:( ":" ) o { return _.textNode(s); }
sym_fslash "Forward Slash"
  = s:( "/" ) o { return _.textNode(s); }
sym_bslash "Backslash"
  = s:( "\\" ) o { return _.textNode(s); }

/* Keywords */

ABORT
  = "ABORT"i
ACTION
  = "ACTION"i
ADD
  = "ADD"i
AFTER
  = "AFTER"i
ALL
  = "ALL"i
ALTER
  = "ALTER"i
ANALYZE
  = "ANALYZE"i
AND
  = "AND"i
AS
  = "AS"i
ASC
  = "ASC"i
ATTACH
  = "ATTACH"i
AUTOINCREMENT
  = "AUTOINCREMENT"i
BEFORE
  = "BEFORE"i
BEGIN
  = "BEGIN"i
BETWEEN
  = "BETWEEN"i
BY
  = "BY"i
CASCADE
  = "CASCADE"i
CASE
  = "CASE"i
CAST
  = "CAST"i
CHECK
  = "CHECK"i
COLLATE
  = "COLLATE"i
COLUMN
  = "COLUMN"i
COMMIT
  = "COMMIT"i
CONFLICT
  = "CONFLICT"i
CONSTRAINT
  = "CONSTRAINT"i
CREATE
  = "CREATE"i
CROSS
  = "CROSS"i
CURRENT_DATE
  = "CURRENT_DATE"i
CURRENT_TIME
  = "CURRENT_TIME"i
CURRENT_TIMESTAMP
  = "CURRENT_TIMESTAMP"i
DATABASE
  = "DATABASE"i
DEFAULT
  = "DEFAULT"i
DEFERRABLE
  = "DEFERRABLE"i
DEFERRED
  = "DEFERRED"i
DELETE
  = "DELETE"i
DESC
  = "DESC"i
DETACH
  = "DETACH"i
DISTINCT
  = "DISTINCT"i
DROP
  = "DROP"i
EACH
  = "EACH"i
ELSE
  = "ELSE"i
END
  = "END"i
ESCAPE
  = "ESCAPE"i
EXCEPT
  = "EXCEPT"i
EXCLUSIVE
  = "EXCLUSIVE"i
EXISTS
  = "EXISTS"i
EXPLAIN
  = "EXPLAIN"i
FAIL
  = "FAIL"i
FOR
  = "FOR"i
FOREIGN
  = "FOREIGN"i
FROM
  = "FROM"i
FULL
  = "FULL"i
GLOB
  = "GLOB"i
GROUP
  = "GROUP"i
HAVING
  = "HAVING"i
IF
  = "IF"i
IGNORE
  = "IGNORE"i
IMMEDIATE
  = "IMMEDIATE"i
IN
  = "IN"i
INDEX
  = "INDEX"i
INDEXED
  = "INDEXED"i
INITIALLY
  = "INITIALLY"i
INNER
  = "INNER"i
INSERT
  = "INSERT"i
INSTEAD
  = "INSTEAD"i
INTERSECT
  = "INTERSECT"i
INTO
  = "INTO"i
IS
  = "IS"i
ISNULL
  = "ISNULL"i
JOIN
  = "JOIN"i
KEY
  = "KEY"i
LEFT
  = "LEFT"i
LIKE
  = "LIKE"i
LIMIT
  = "LIMIT"i
MATCH
  = "MATCH"i
NATURAL
  = "NATURAL"i
NO
  = "NO"i
NOT
  = "NOT"i
NOTNULL
  = "NOTNULL"i
NULL
  = "NULL"i
OF
  = "OF"i
OFFSET
  = "OFFSET"i
ON
  = "ON"i
OR
  = "OR"i
ORDER
  = "ORDER"i
OUTER
  = "OUTER"i
PLAN
  = "PLAN"i
PRAGMA
  = "PRAGMA"i
PRIMARY
  = "PRIMARY"i
QUERY
  = "QUERY"i
RAISE
  = "RAISE"i
RECURSIVE
  = "RECURSIVE"i
REFERENCES
  = "REFERENCES"i
REGEXP
  = "REGEXP"i
REINDEX
  = "REINDEX"i
RELEASE
  = "RELEASE"i
RENAME
  = "RENAME"i
REPLACE
  = "REPLACE"i
RESTRICT
  = "RESTRICT"i
RIGHT
  = "RIGHT"i
ROLLBACK
  = "ROLLBACK"i
ROW
  = "ROW"i
ROWID
  = "ROWID"i
SAVEPOINT
  = "SAVEPOINT"i
SELECT
  = "SELECT"i
SET
  = "SET"i
TABLE
  = "TABLE"i
TEMP
  = "TEMP"i
TEMPORARY
  = "TEMPORARY"i
THEN
  = "THEN"i
TO
  = "TO"i
TRANSACTION
  = "TRANSACTION"i
TRIGGER
  = "TRIGGER"i
UNION
  = "UNION"i
UNIQUE
  = "UNIQUE"i
UPDATE
  = "UPDATE"i
USING
  = "USING"i
VACUUM
  = "VACUUM"i
VALUES
  = "VALUES"i
VIEW
  = "VIEW"i
VIRTUAL
  = "VIRTUAL"i
WHEN
  = "WHEN"i
WHERE
  = "WHERE"i
WITH
  = "WITH"i
WITHOUT
  = "WITHOUT"i

reserved_words
  = r:( reserved_word_list )
  { return _.key(r); }

reserved_word_list
  = ABORT / ACTION / ADD / AFTER / ALL / ALTER / ANALYZE / AND / ASC /
    ATTACH / AUTOINCREMENT / BEFORE / BEGIN / BETWEEN / BY / CASCADE / CASE /
    CAST / CHECK / COLLATE / COLUMN / COMMIT / CONFLICT / CONSTRAINT / CREATE /
    CROSS / CURRENT_DATE / CURRENT_TIME / CURRENT_TIMESTAMP / DATABASE / DEFAULT /
    DEFERRABLE / DEFERRED / DELETE / DESC / DETACH / DISTINCT / DROP / EACH /
    ELSE / END / ESCAPE / EXCEPT / EXCLUSIVE / EXISTS / EXPLAIN / FAIL /
    FOREIGN / FOR / FROM / FULL / GLOB / GROUP / HAVING / IGNORE / IMMEDIATE /
    INDEXED / INDEX / INITIALLY / INNER / INSERT / INSTEAD / INTERSECT / INTO /
    ISNULL / JOIN / KEY / LEFT / LIKE / LIMIT / MATCH / NATURAL /
    NOTNULL / OFFSET / ORDER / OUTER / PLAN / PRAGMA /
    PRIMARY / QUERY / RAISE / RECURSIVE / REFERENCES / REGEXP / REINDEX /
    RELEASE / RENAME / REPLACE / RESTRICT / RIGHT / ROLLBACK / ROW / SAVEPOINT /
    SELECT / SET / TABLE / TEMPORARY / TEMP / THEN / TO / TRANSACTION / TRIGGER /
    UNION / UNIQUE / UPDATE / USING / VACUUM / VALUES / VIEW / VIRTUAL / WHEN /
    WHERE / WITHOUT / WITH / NULL / NOT / IN / IF / IS / OF / ON / OR / NO / AS

/* Generic rules */

/* TODO: Not returning anything in AST for comments, should decide what to do with them */
comment
  = comment_line
  / comment_block
  { return null; }

comment_line "SQL Line Comment"
  = sym_minus sym_minus ( !whitespace_line match_all )*

comment_block "SQL Block Comment"
  = comment_block_start comment_block_feed comment_block_end o

comment_block_start
  = sym_fslash sym_star

comment_block_end
  = sym_star sym_fslash

comment_block_body
  = ( !( comment_block_end ) match_all )+

block_body_nodes
  = comment_block_body / comment_block

comment_block_feed
  = block_body_nodes ( o block_body_nodes )*

match_all "Anything"
  = .
  /*= [\s\S]*/

/* Optional Whitespace */
o
  = n:( whitespace_nodes )*
  { return n; }

/* Enforced Whitespace */
e
  = n:( whitespace_nodes )+
  { return n; }

whitespace_nodes
  = whitespace
  / comment

/* Whitespace */
whitespace
  = whitespace_space
  / whitespace_line

whitespace_space "Whitespace"
  = [ \t]

whitespace_line "New Line"
  = [\n\v\f\r]

/* TODO: Everything with this symbol */
_TODO_
  = "__TODO__"
