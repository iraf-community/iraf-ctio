# Evaluator common. This common handles the evaluation stack, defined
# as a structure buffer, and the stack pointer.

int	eval_sp			# evaluation stack pointer
pointer	eval_stack		# evaluation stack

common	/evalcom/	eval_sp, eval_stack
