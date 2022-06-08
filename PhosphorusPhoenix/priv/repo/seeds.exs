# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Phos.Repo.insert!(%Phos.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Phos.Users.create_user(%{"username" => "Albert", "fyr" => %{"id" => "614268985908658175"}, "media" => false, "birthday" => NaiveDateTime.utc_now(), "bio" => "Hi, i'm new to scratchbac!", "geohash"=> [%{"type" => "home", "location_description" => "my home", "geohash" => "623276216933351423", "radius" => "10", "geohashingtiny" => 623276216933351423, "chronolock" => 1651765218}]})

# Phos.Action.create_orb(%{"geolocation" => [614268985908658175, 614268985470353407, 614268985912852479, 614268985900269567, 614268985910755327, 614268985652805631, 614268985466159103], "payload"=> %{"image" => "S3 path", "time" => "11pm", "tip" => "bbt", "info" => "more more text"}, "title" => "sembawang NICE food", "extinguish" => NaiveDateTime.utc_now()})
# Phos.Action.create_orb(%{"geolocation" => [623276184907743231, 623276184907710463, 623276184907579391, 623276184907612159, 623276184908038143, 623276184908988415, 623276184908955647], "payload"=> %{"image" => "S3 path", "time" => "12pm", "tip" => "bbt", "info" => "more more text"}, "title" => "sembawang NICE food 2", "extinguish" => NaiveDateTime.utc_now()})
# Phos.Action.create_orb(%{"geolocation" => [614269017678413823, 614269017676316671, 614269017682608127, 614269018120912895, 614269017865060351, 614269017873448959, 614269017686802431], "payload"=> %{"image" => "S3 path", "time" => "1pm", "tip" => "bbt", "info" => "more more text"}, "title" => "simpang NICE food", "extinguish" => NaiveDateTime.utc_now()})
# Phos.Action.create_orb(%{"geolocation" => [614269017680510975, 614269017661636607, 614269018104135679, 614269018106232831, 614269017682608127, 614269017676316671, 614269017688899583], "payload"=> %{"image" => "S3 path", "time" => "2pm", "tip" => "bbt", "info" => "more more text"}, "initiator" => %{"username" => "", "user_id" => ""}, "title" => "sutd NICE food", "extinguish" => NaiveDateTime.utc_now()})
# Phos.Action.create_orb(%{"geolocation" => [614268613639012351, 614268613704024063, 614268613643206655, 614268613630623743, 614268613641109503, 614268613718704127, 614268613699829759], "payload"=> %{"image" => "S3 path", "time" => "3pm", "tip" => "bbt", "info" => "more more text"}, "title" => "bp rock", "extinguish" => NaiveDateTime.utc_now()})
