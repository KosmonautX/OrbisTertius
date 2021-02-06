from app import db
from typing import List
from .model import TeleServiceModel
from .interface import TeleMessagingInterface, TelePostingInterface


class TeleMessagingService:
    # @staticmethod
    # def get_all() -> List[TeleMessaging]:
    #     return TeleMessaging.query.all()

    # @staticmethod
    # def get_by_id(TeleMessaging_id: int) -> TeleMessaging:
    #     return TeleMessaging.query.get(TeleMessaging_id)

    # @staticmethod
    # def update(TeleMessaging: TeleMessaging, TeleMessaging_change_updates: TeleMessagingInterface) -> TeleMessaging:
    #     TeleMessaging.update(TeleMessaging_change_updates)
    #     db.session.commit()
    #     return TeleMessaging

    # @staticmethod
    # def delete_by_id(TeleMessaging_id: int) -> List[int]:
    #     TeleMessaging = TeleMessaging.query.filter(TeleMessaging.TeleMessaging_id == TeleMessaging_id).first()
    #     if not TeleMessaging:
    #         return []
    #     db.session.delete(TeleMessaging)
    #     db.session.commit()
    #     return [TeleMessaging_id]

    # @staticmethod
    # def create(new_attrs: TeleMessagingInterface) -> TeleMessaging:
    #     new_TeleMessaging = TeleMessaging(name=new_attrs["name"], purpose=new_attrs["purpose"])

    #     db.session.add(new_TeleMessaging)
    #     db.session.commit()

    #     return new_TeleMessaging
    
##########

    @staticmethod
    def post_new_orb(new_attrs: TelePostingInterface) -> TeleServiceModel:
        new_TeleMessaging = TeleServiceModel.posting(
                                    orb_UUID=new_attrs['orbUUID'],
                                    user_id=new_attrs['userId'],
                                    star_user= new_attrs['starUser'],
                                    tele_username= new_attrs['teleUsername'], 
                                    user_location= new_attrs['userLocation'], 
                                    title= new_attrs['title'], 
                                    info= new_attrs['info'], 
                                    where= new_attrs['where'], 
                                    when= new_attrs['when'], 
                                    tip= new_attrs['tip'], 
                                    user_id_list= new_attrs['userIdList'],
                                    if_commercial=new_attrs['ifCommercial'])

        return new_TeleMessaging

    @staticmethod
    def message_user(new_attrs: TeleMessagingInterface) -> TeleServiceModel:
        new_TeleMessaging = TeleServiceModel.message_user(acceptor_id=new_attrs['acceptorId'], poster_id=new_attrs['userId'])

        return new_TeleMessaging
    
