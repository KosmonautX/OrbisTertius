from mypy_extensions import TypedDict
from typing import Dict, List

class OrbInterface(TypedDict, total=False):
    orb_uuid: int
    time_created: int
    title: str
    postal_code: int
    acceptor_uuid: List[int]
    payload: Dict[str, str]
    init_uuid: str
    dormancy: int
    nature: int
