use Mix.Config

config :n2o,
  tables: [:cookies, :file, :web, :caching, :async, :cipher],
  logger: [
    {:handler, :synrc, :logger_std_h,
     %{
       level: :info,
       id: :synrc,
       max_size: 2000,
       module: :logger_std_h,
       config: %{type: :file, file: 'cipher.log'},
       formatter:
         {:logger_formatter,
          %{ template: [:time, ' ', :pid, ' ', :module, ' ', :msg, '\n'],
             single_line: true }}}}],
  logger_level: :info
