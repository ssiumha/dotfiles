; Java context: @context.start로 어노테이션 건너뛰고 선언 라인부터 표시
; @context.final로 선언 줄까지만 표시 (body 진입 전)

(class_declaration
  name: (_) @context.start @context.final
) @context

(interface_declaration
  name: (_) @context.start @context.final
) @context

(enum_declaration
  name: (_) @context.start @context.final
) @context

(method_declaration
  type: (_) @context.start
  parameters: (_) @context.final
) @context

(constructor_declaration
  name: (_) @context.start
  parameters: (_) @context.final
) @context

(if_statement) @context
(for_statement) @context
(enhanced_for_statement) @context
(switch_expression) @context
