from typing import List
# from .model import OrbModel
from .interface import OrbInterface
from .model import OrbModel
import boto3


class OrbService:
    @staticmethod
    def get_all():
        return OrbModel.query('orb_uuid')

    @staticmethod
    def get_by_id(orb_uuid: int):
        return OrbModel.query(KeyConditionExpression = boto3.dynamodb.conditions.Key('orb_uuid').eq(orb_uuid))

    @staticmethod
    def update(orb: OrbModel, Orb_change_updates: OrbInterface):
        # RETHINK THIS
        print("UPDATE")
        orb.update(Orb_change_updates)
        # db.session.commit() # Need to somehow change this
        return orb

    @staticmethod
    def delete_by_id(orb_uuid: int):
        orb = OrbModel.orb_uuid.delete({orb_uuid})
        if not orb:
            return []

        return [orb_uuid]

    @staticmethod
    def create(new_attrs: OrbInterface):
        new_orb = OrbModel(orb_uuid=new_attrs["orb_uuid"], epoch_time_loc=new_attrs["epoch_time_loc"], epoch_time_nature=new_attrs["epoch_time_nature"], title=new_attrs["title"], acceptor_id=new_attrs["acceptor_id"], location=new_attrs["location"], payload=new_attrs["payload"], init_uuid=new_attrs["init_uuid"], dormancy=new_attrs["dormancy"])

        # db.session.add(new_fizzbar)
        # db.session.commit()

        return new_orb
