"test/mazurka_test/services/**/*.ex"
|> Path.wildcard()
|> Enum.map(&Code.require_file/1)

"test/mazurka_test/resources/**/*.ex"
|> Path.wildcard()
|> Enum.map(&Code.require_file/1)

Code.require_file "test/mazurka_test/dispatch.ex"

"test/mazurka_test/http/**/*.ex"
|> Path.wildcard()
|> Enum.map(&Code.require_file/1)
