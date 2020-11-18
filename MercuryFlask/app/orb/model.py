from .interface import OrbInterface
from app import dynamodb

OrbModel = dynamodb.Table('ORB_NET')

'''    
class Orb(dynamoDB.tables):  # type: ignore
    """A snazzy Orb"""

    __tablename__ = "Orb"

    fizzbar_id = Column(Integer(), primary_key=True)
    name = Column(String(255))
    purpose = Column(String(255))

    def update(self, changes:  ):
        for key, val in changes.items():
            setattr(self, key, val)
        return self
'''

# import logging

# logging.basicConfig()
# log = logging.getLogger("pynamodb")
# log.setLevel(logging.DEBUG)
# log.propagate = True

# for item in OrbModel.scan():
#     print(item)