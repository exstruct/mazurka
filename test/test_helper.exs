"test/mazurka_test//**/*.ex"
|> Path.wildcard()
|> Enum.map(&Code.require_file/1)

ExUnit.start()