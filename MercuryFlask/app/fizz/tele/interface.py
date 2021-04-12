from mypy_extensions import TypedDict

class TeleMessagingInterface(TypedDict, total=False):
    acceptor_id: str
    user_id: int
    username: str

class TelePostingInterface(TypedDict, total=False):
    orb_UUID: str
    acceptor_id: int
    user_id: int
    star_user: bool
    tele_username: str
    message_id: int
    user_location: int
    title: str
    info: str
    where: str
    when: str
    tip: str
    user_id_list: list
    if_commercial: bool
