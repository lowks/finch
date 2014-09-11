# defmodule Finch.Middleware.Authorizor do
#     defmacro __using__(_options) do
#     quote [unquote: false] do
#         #noop, authorize everything
#       def handle({verb, conn, params, module, bundle}), do: {verb, conn, params, module, bundle}
#     end
#   end
# end