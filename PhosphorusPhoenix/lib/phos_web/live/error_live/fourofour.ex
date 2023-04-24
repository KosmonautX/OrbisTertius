defmodule PhosWeb.ErrorLive.FourOThree do
  defexception [:message, plug_status: 403]
end

defmodule PhosWeb.ErrorLive.FourOFour do
  defexception [:message, plug_status: 404]
end
