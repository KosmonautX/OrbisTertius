from flask import request
from flask_accepts import accepts, responds
from flask_restx import Namespace, Resource
from flask.wrappers import Response
from typing import List

from .schema import OrbSchema
from .service import OrbService
from .model import OrbModel
from .interface import OrbInterface

api = Namespace("ORB", description="Calls to ORBland")


@api.route("/")
class OrbResource(Resource):
    """Orbs"""

    @responds(schema=OrbSchema, many=True)
    def get(self):
        """Get all Orbs"""

        return OrbService.get_all()

    @accepts(schema=OrbSchema, api=api)
    @responds(schema=OrbSchema)
    def post(self):
        """Create a Single Orb"""
        print(OrbService.create(request.parsed_obj))

        return OrbService.create(request.parsed_obj)


@api.route("/<int:OrbId>")
@api.param("OrbId", "Orb database ID")
class OrbIdResource(Resource):
    @responds(schema=OrbSchema)
    def get(self, OrbId: int):
        """Get Single Orb"""

        return OrbService.get_by_id(OrbId)

    def delete(self, OrbId: int):
        """Delete Single Orb"""
        from flask import jsonify

        print("OrbId = ", OrbId)
        id = OrbService.delete_by_id(OrbId)
        return jsonify(dict(status="Success", id=id))

    @accepts(schema=OrbSchema, api=api)
    @responds(schema=OrbSchema)
    def put(self, OrbId: int):
        """Update Single Orb"""

        changes: OrbInterface = request.parsed_obj
        Orb = OrbService.get_by_id(OrbId)
        return OrbService.update(Orb, changes)
