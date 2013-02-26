grammar PRDL;

options {
  language = Java;
  output = template;
}

scope access_stmts {
  List dataObjectsList;
  List purposesList;
  List destinationActors;
}

@header {
  package eu.endorse.prdl;
  import org.antlr.stringtemplate.*;
}

@lexer::header {package eu.endorse.prdl;}
    
LETTER
  	: ('a'..'z'|'A'..'Z')
    ;	

DIGIT :	'0'..'9'
    ;


COMMENT
    :   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

WS  :   ( ' '
        | '\t'
        | '\r'
        | '\n'
        ) {$channel=HIDDEN;}
    ;


CHAR:  '\'' ( ESC_SEQ | ~('\''|'\\') ) '\''
    ;

fragment
EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
ESC_SEQ
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   UNICODE_ESC
    |   OCTAL_ESC
    ;

fragment
OCTAL_ESC
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UNICODE_ESC
    :   '\\' 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
    ;

Logical_value 
	:	 ('TRUE' | 'FALSE' )
	;

Separator 
	:	 ('#' | ',' | '.' | ':' | ';')
	;

Bracket :	(')' | '(' | ']' | '[' )
	;

Arithmetic_operator 
	:	('+' | '-' | '*' | '/' | '//' | '**' | '^')
	;
	
Quote : ('"')
  ;

Relational_operator 
	:	('<' | '=' | '>' );

Logical_operator 
	:	('AND' | 'OR' )
	;
	
MAY
  : 'MAY'
  ;

MUST_NOT
  : 'MUST_NOT'
  ;

MUST
  : 'MUST'
  ;

modality
	:	 (MAY | MUST_NOT | MUST)
	;
  
Conditional
  : ('IF' | 'UNLESS')
  ;
  
ON
  : ('ON')
  ;
 
FOR
  : ('FOR')
  ;
  
TO
  : ('TO')
  ;
  
conjunction
  : (ON | FOR | TO)
  ;
  
Single_actor_action 
  : ('VIEW' | 'ADD' | 'DELETE' | 'MODIFY' | 'STORE' | 'ANONYMISE' |
    'CHECK' | 'VALIDATE' | 'COLLECT' | 'CORRECT' | 'DISSEMINATE' | 'END_PROCESSING' | 'REQUEST' |
    'REVOKE'
    | 'CREATE_PURPOSE' 
    )
  ;

Multi_actor_action 
  : ('TRANSFER' | 'COMMUNICATE' | 'INFORM' | 'OBTAIN_PERMISSION_FROM')
  ;
 
action
  : (Single_actor_action | Multi_actor_action)
  ;

Variable 
  : '$' LETTER (LETTER | DIGIT)*
  ;

STRING 
  : LETTER (LETTER | DIGIT)*
  ;

Numerical_value 
	:	DIGIT (DIGIT)*
	;

variable_lhs
  : Variable
  ;

variable_rhs
  : Variable
  ;
	
boolean_expression 
	: variable_lhs Relational_operator variable_rhs 
	-> bool_var_relop_var(var1={$variable_lhs.text}, relop={$Relational_operator.text}, var2={$variable_rhs.text})
	| variable_lhs Logical_operator variable_rhs
	-> bool_var_logop_var(var1={$variable_lhs.text}, logop={$Logical_operator.text}, var2={$variable_rhs.text})
	| variable_lhs Relational_operator STRING
	-> bool_var_relop_string(var1={$variable_lhs.text}, relop={$Relational_operator.text}, str={$STRING.text})
	| variable_lhs Relational_operator Numerical_value
	-> bool_var_relop_num(var1={$variable_lhs.text}, relop={$Relational_operator.text}, num={$Numerical_value.text})
	| variable_lhs Logical_operator STRING
	-> bool_var_logop_string(var1={$variable_lhs.text}, logop={$Logical_operator.text}, str={$STRING.text})
  | variable_lhs Logical_operator Numerical_value
  -> bool_var_logop_num(var1={$variable_lhs.text}, logop={$Logical_operator.text}, num={$Numerical_value.text})
	;	
	
conditionStatementBoolean_expression
  : boolean_expression {$conditionStatement::logicOps.add($boolean_expression.text);}
  ;
	
conditionStatementLogicalOperator
  : Logical_operator {$conditionStatement::logicOps.add($Logical_operator.text);}
  ;
  
conditionStatementConditional  
  : Conditional {$conditionStatement::conditionals.add($Conditional.text);}
  ;

conditionStatement
scope {
  List logicOps;
  List conditionals;
  List booleanExpressionsList;
}
@init {
  $conditionStatement::logicOps = new ArrayList();
  $conditionStatement::conditionals = new ArrayList();
  $conditionStatement::booleanExpressionsList = new ArrayList();
}
  : (conditionStatementLogicalOperator conditionStatementConditional conditionStatementBoolean_expression)+
  -> conditionStatement(logops={$conditionStatement::logicOps}, conditionals={$conditionStatement::conditionals}, boolexprs={$conditionStatement::booleanExpressionsList})
  ;

actor	:	 STRING
	;
	
subject : actor
  ;
  
object 
  : actor {$access_stmts::destinationActors.add($actor.text);}
  ;

dataObject 
	:  STRING {$access_stmts::dataObjectsList.add($STRING.text);}
	;
	
purpose
  :	STRING {$access_stmts::purposesList.add($STRING.text);}
	;
  
dataObjects
  : dataObject (',' dataObject)*
  ;
  
purposes
  : purpose (',' purpose)*
  ;
  
destinations
  : object (',' object)*
  ;

permission
scope access_stmts;
@init {
  $access_stmts::dataObjectsList = new ArrayList();
  $access_stmts::purposesList = new ArrayList();
  $access_stmts::destinationActors = new ArrayList();
}
  : subject MAY Single_actor_action ON dataObjects FOR purposes conditionStatement?
  -> permissionSingleActor(subject={$subject.text}, action={$Single_actor_action.text}, dataObjects={$access_stmts::dataObjectsList}, purposes={$access_stmts::purposesList}, conditions={$conditionStatement.st})
  | subject MAY Multi_actor_action ON dataObjects FOR purposes (TO destinations)? conditionStatement?
  -> permissionMultiActor(subject={$subject.text}, action={$Multi_actor_action.text}, dataObjects={$access_stmts::dataObjectsList}, purposes={$access_stmts::purposesList}, destinations={$access_stmts::destinationActors}, conditions={$conditionStatement.st})
  ;
  
prohibition
scope access_stmts;
@init {
  $access_stmts::dataObjectsList = new ArrayList();
  $access_stmts::purposesList = new ArrayList();
  $access_stmts::destinationActors = new ArrayList();
}
  : subject MUST_NOT Single_actor_action ON dataObjects FOR purposes conditionStatement?
  -> prohibitionSingleActor(subject={$subject.text}, action={$Single_actor_action.text}, dataObjects={$access_stmts::dataObjectsList}, purposes={$access_stmts::purposesList}, conditions={$conditionStatement.st})
  | subject MUST_NOT Multi_actor_action ON dataObjects FOR purposes (TO destinations)? conditionStatement?
  -> prohibitionMultiActor(subject={$subject.text}, action={$Multi_actor_action.text}, dataObjects={$access_stmts::dataObjectsList}, purposes={$access_stmts::purposesList}, destinations={$access_stmts::destinationActors}, conditions={$conditionStatement.st})
  ;
  
obligation
scope access_stmts;
@init {
  $access_stmts::dataObjectsList = new ArrayList();
  $access_stmts::purposesList = new ArrayList();
  $access_stmts::destinationActors = new ArrayList();
}
  : subject MUST Single_actor_action ON dataObjects FOR purposes conditionStatement?
  -> obligationSingleActor(subject={$subject.text}, action={$Single_actor_action.text}, dataObjects={$access_stmts::dataObjectsList}, purposes={$access_stmts::purposesList}, conditions={$conditionStatement.st})
  | subject MUST Multi_actor_action ON dataObjects FOR purposes (TO destinations)? conditionStatement?
  -> obligationMultiActor(subject={$subject.text}, action={$Multi_actor_action.text}, dataObjects={$access_stmts::dataObjectsList}, purposes={$access_stmts::purposesList}, destinations={$access_stmts::destinationActors}, conditions={$conditionStatement.st})
  ;
  
policy_statement 
  : permission {$policy_file_contents::policies.add($permission.st);}
  | prohibition {$policy_file_contents::policies.add($prohibition.st);}
  | obligation {$policy_file_contents::policies.add($obligation.st);}
  ;
  
policy_set 
  : policy_statement ( ';' policy_statement)*
  ;
  
policy_name : STRING
  ;
  
policy_file_contents
scope {
  List policies;
}
@init {
  $policy_file_contents::policies = new ArrayList();
}
  : policy_name ';' policy_set ';'? -> policy_file_contents(policy_name={$policy_name.text}, policy_set={$policy_file_contents::policies})
  ;
  
policy_file
  : policy_file_contents EOF -> policy_file(policy_file_contents={$policy_file_contents.st})
  ;