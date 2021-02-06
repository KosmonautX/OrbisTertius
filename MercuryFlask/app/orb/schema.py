from marshmallow import fields, Schema

class OrbSchema(Schema):
    """Orb schema"""

    orbUUID = fields.Number(attribute="orb_uuid")
    timeCreated = fields.Number(attribute="time_created")
    title = fields.String(attribute="title")
    postalCode = fields.Number(attribute="postal_code")
    acceptorUUID = fields.List(fields.Number())
    payload= fields.Dict(keys=fields.String(), values=fields.String())
    initUUID = fields.String(attribute="init_uuid")
    dormancy = fields.Number(attribute="dormancy")
    nature = fields.Number(attribute="nature")

