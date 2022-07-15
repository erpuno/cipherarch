CIPHER: Цифровий Шифроархів
===========================

[![Hex pm](http://img.shields.io/hexpm/v/cipherarch.svg?style=flat&x=1)](https://hex.pm/packages/cipherarch)

Інформація
----------

Тут представлений конектор на мові Elixir для <a href="https://cipher.com.ua/en/products/cipher-arch">Шифроархіву компанії CIPHER</a>.

Конфігурація
------------

Перед роботою додайте креденшиали для тестового середовища:

```
config: :n2o,
  cipher_auth: 'https://ccs-dev-api.cipher.kiev.ua/ccs/auth-2/token',
  cipher_upload: 'https://archive-api.cipher.com.ua/arch/api/v1/object/',
  bearer: 'Bearer xxxx',
  jwt_prod: false,
```

Пререквізити
------------

```
$ sudo apt install erlang elixir
```

Білд
----

Компіляція та запуск:

```
$ mix deps.get
$ iex -S mix
> CIPHER.send 1, "N2O.docx"
```

Автор
-----

* Максим Сохацький
