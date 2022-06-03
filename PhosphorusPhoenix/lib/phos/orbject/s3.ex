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

  def get(path) do
    signer(:get, path)
  end
  def get(archetype, uuid, form) do
    path = archetype <> "/" <> uuid <> "/" <> form
    signer(:get, path)
  end

  def get!(archetype, uuid, form) do
    path = archetype <> "/" <> uuid <> "/" <> form
    {:ok, url} = signer(:get, path)
    url
  end

  def put(archetype, uuid, form) do
    path = archetype <> "/" <> uuid <> "/" <> form
    signer(:put, path)
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
        [expires_in: 888, virtual_host: false, query_params: [{"ContentType", "application/octet-stream"}]])

  end


end
