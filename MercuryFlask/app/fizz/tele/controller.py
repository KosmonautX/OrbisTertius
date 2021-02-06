from flask import request
from flask_accepts import accepts, responds
from flask_restx import Namespace, Resource
from flask.wrappers import Response
from typing import List

from .schema import TeleMessagingSchema
from .service import TeleMessagingService
from .model import TeleServiceModel

api = Namespace("TeleMessaging", description="Link app api to tele bot")  # noqa


@api.route("/posting")
class TelePostingResource(Resource):

    @accepts(schema=TeleMessagingSchema, api=api)
    @responds(schema=TeleMessagingSchema)
    def post(self) -> TeleServiceModel:
        """for jun wei app posting"""
        return TeleMessagingService.post_new_orb(request.parsed_obj)

@api.route("/messaging")
class TeleMessagingResource(Resource):
    @accepts(schema=TeleMessagingSchema, api=api)
    @responds(schema=TeleMessagingSchema)
    def post(self) -> TeleServiceModel:
        """for nicole messaging"""
        
        return TeleMessagingService.message_user(request.parsed_obj)

