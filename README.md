CIPHER: Цифровий Шифроархів
===========================

[![Hex pm](http://img.shields.io/hexpm/v/cipherarch.svg?style=flat&x=1)](https://hex.pm/packages/cipherarch)

Інформація
----------

Тут представлений конектор (250 рядків) на мові Elixir
для <a href="https://cipher.com.ua/en/products/cipher-arch">Шифроархіву компанії CIPHER</a>.

Конфігурація
------------

Перед роботою додайте креденшиали для тестового середовища:

```
config: :n2o,
  cipher_auth: 'https://ccs-dev-api.cipher.kiev.ua/ccs/auth-2/token',
  cipher_upload: 'https://archive-api.cipher.com.ua/arch/api/v1/object/',
  jwt_prod: false,
  bearer: 'Bearer xxxx', # jwt_prod = false
  login: "Максим Сохацький", # jwt_prod = true
  pass: "1234",
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
03:09:43.394 [debug] CIPHER UPLOAD: {"HTTP/1.1",200,[]}
03:09:43.394 [debug] CIPHER UPLOAD ID: "c9983ae3f517fbc9a147d5c34f22932f42fe965b"
03:09:45.641 [debug] CIPHER UPLOAD SIGNATURE: c9983ae3f517fbc9a147d5c34f22932f42fe965b
03:09:47.636 [debug] CIPHER PUBLISH: c9983ae3f517fbc9a147d5c34f22932f42fe965b
03:09:48.633 [debug] CIPHER METAINFO: c9983ae3f517fbc9a147d5c34f22932f42fe965b
03:09:48.634 [warn]  CIPHER CIPHER: {<0.276.0>,<<"N2O.docx">>}
> CIPHER.down 'c9983ae3f517fbc9a147d5c34f22932f42fe965b'
03:15:43.413 [debug] CIPHER DOWNLOAD c9983ae3f517fbc9a147d5c34f22932f42fe965b
03:15:43.477 [debug] CIPHER DOWNLOAD SIGNATURE: c9983ae3f517fbc9a147d5c34f22932f42fe965b
03:15:43.479 [debug] CIPHER DOWNLOAD SIGNATURE: signature-9e208b8
```

```
> :supervisor.which_children CIPHER
[
  {{:cipher, 'c9983ae3f517fbc9a147d5c34f22932f42fe965b'}, #PID<0.465.0>, :worker, [CIPHER.DOWN]},
  {{:cipher, "N2O.docx"}, #PID<0.276.0>, :worker, [CIPHER.UP]},
  {{:cipher, "cipherLink"}, #PID<0.219.0>, :worker, [CIPHER]}
]
```

Автор
-----

* Максим Сохацький
