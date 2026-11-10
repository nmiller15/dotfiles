# C# / .NET style

Apply these conventions when writing or editing C# code:

- Always use braces for control-flow bodies, including single-line `if`, `else`, `for`, `foreach`, `while`, and `using` statements. Do not rely on indentation alone.
- When iterating over a LINQ query, assign the query result to a descriptively named local variable before the loop instead of embedding the query in `foreach`.
- Use `string.Empty` instead of `""` for empty strings.
- Prefer `[]` for empty lists and other collections when the project supports collection expressions (C# 12 or later) and the target type is clear.
