defmodule Phos.Orbject.S3 do
  @moduledoc """
  S3 Object Storage Service Communicator  using HTTP POST sigv4
  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
  """

  @doc """
  Signs a form upload.
  The configuration is a map which must contain the following keys:
  * `:region` - The AWS region, such as "ap-southeast-1"
  * `:access_key_id` - The AWS access key id
  * `:secret_access_key` - The AWS secret access key

  Phos.Orbject.S3.get("USR", "xxx-id","1920x1080")

  Phos.Orbject.S3.put("USR", "xxx-id","1920x1080")

  returns {:ok, url}


  """
  alias Phos.Orbject

  def get(path) do
    signer(:get, path)
  end


  def get(archetype, uuid, form) do
    signer(:get, path_constructor(archetype, uuid, form))
  end

  def get!(archetype, uuid, form) do
    signer!(:get, path_constructor(archetype, uuid, form))
  end

  def put(archetype, uuid, form) do
    signer(:put, path_constructor(archetype, uuid, form))
  end

  def put!(archetype, uuid, form) do
    signer!(:put, path_constructor(archetype, uuid, form))
  end

  def get_all!(orbject = %Orbject.Structure{}) do
    root_path = path_constructor(orbject.archetype, orbject.id, "")
    for obj <- orbject.media, into: %{} do
      path = path_constructor(orbject.archetype, orbject.id, obj)
      if orbject.wildcard do
         {:ok, addresses} = get_all(path)
        {path_suffix(path, root_path) , addresses}
      else
        {path_suffix(path, root_path) , signer!(:get, path)}
      end
     end
  end


  def get_all(root_path) do
    with {:ok, response} <- ExAws.S3.list_objects_v2("orbistertius", prefix: root_path, encoding_type: "url") |> ExAws.request(),
         true <- response.status_code >= 200 and response.status_code < 300,
         [_ |_] <- response.body.contents,
           addresses <- (for obj <- response.body.contents, into: %{} do
                                  {path_suffix(obj.key, root_path), signer!(:get,obj.key)} end) do
      {:ok, addresses}
    else
      [] -> {:ok, nil}
      {:error, _err} -> {:ok, nil}  #TODO better error parsing
    end
  end


  def get_all(archetype, uuid, form \\ "") do
    root_path = path_constructor(archetype, uuid, form)
    get_all(root_path)
  end

  def get_all!(archetype, uuid, form \\ "") do
    with {:ok, address} <- Phos.Orbject.S3.get_all(archetype, uuid, form) do
      address
    end
  end

  def put_all!(orbject = %Orbject.Structure{}) do
    root_path = path_constructor(orbject.archetype, orbject.id, "")
    for obj <- orbject.media, into: %{} do
      path = path_constructor(orbject.archetype, orbject.id, obj)
      {path_suffix(path, root_path) , signer!(:put, path)}
    end
  end


  defp signer!(action, path) do
    {:ok, url} = signer(action, path)
    url
  end

  defp signer(:headandget, path) do
    ExAws.S3.head_object("orbistertius", path)
    |> ExAws.request!()
    ## with 200
    signer(:get, path)
    ## else (pass signer link of fallback image function or nil)
  end


  defp signer(action, path) do
    config = %{
      region: "ap-southeast-1",
      bucket: "orbistertius",
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    ExAws.Config.new(:s3, config) |>
      ExAws.S3.presigned_url(action, config.bucket, path,
        [expires_in: 88888, virtual_host: false, query_params: [{"ContentType", "application/octet-stream"}]])
  end

  defp path_constructor(archetype, uuid, m = %Orbject.Structure.Media{count: 0}) do
    "#{archetype}/#{uuid}#{unless is_nil(m.access),
          do: "/#{m.access}"}#{unless is_nil(m.essence),
          do: "/#{m.essence}"}#{unless is_nil(m.resolution),
          do: "/#{m.resolution}"}#{unless is_nil(m.height),
          do: "#{m.height}x#{m.width}"}#{unless is_nil(m.ext),
          do: ".#{m.ext}"}"
  end

  defp path_constructor(archetype, uuid, m = %Orbject.Structure.Media{}) do
    "#{archetype}/#{uuid}#{unless is_nil(m.access),
          do: "/#{m.access}"}#{unless is_nil(m.essence),
          do: "/#{m.essence}"}#{unless is_nil(m.count),
          do: "/#{m.count}"}#{unless is_nil(m.resolution),
          do: "/#{m.resolution}"}#{unless is_nil(m.height),
          do: "#{m.height}x#{m.width}"}#{unless is_nil(m.ext),
          do: ".#{m.ext}"}"
  end

  defp path_constructor(archetype, uuid, form) do
    "#{archetype}/#{uuid}/#{form}"
  end

  defp path_suffix(full, prefix) do
    base = byte_size(prefix)
    <<_::binary-size(base), rest::binary>> = full
    rest
  end

 end
