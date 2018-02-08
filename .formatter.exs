locals = [
  action: :*,
  collection: :*,
  condition: :*,
  constant: :*,
  field: :*,
  input: :*,
  let: :*,
  param: :*,
  resolve: :*,
  validate: :*
]

[
  locals_without_parens: [
    {:block, :*},
    {:describe, :*}
    | locals
  ],
  inputs: ["mix.exs", ".formatter.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: locals
  ]
]
