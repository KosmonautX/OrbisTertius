from marshmallow import fields, Schema


class TeleMessagingSchema(Schema):
    """Scratchbac schema"""

    fizzbarId = fields.Number(attribute="fizzbar_id")
    name = fields.String(attribute="name")
    purpose = fields.String(attribute="purpose")

    orb_UUID = fields.String(attribute="orbUUID")
    acceptor_id = fields.Int(attribute="acceptorId")
    user_id = fields.Int(attribute="userId")
    star_user = fields.Boolean(attribute="starUser")
    tele_username = fields.String(attribute="teleUsername")
    message_id = fields.Int(attribute="messageId")
    user_location = fields.Int(attribute="userLocation")
    title = fields.String(attribute="title")
    info = fields.String(attribute="info")
    where = fields.String(attribute="where")
    when = fields.String(attribute="when")
    tip = fields.String(attribute="tip")
    user_id_list = fields.List(fields.Int, attribute="userIdList")
    if_commercial = fields.Boolean(attribute="ifCommercial")
