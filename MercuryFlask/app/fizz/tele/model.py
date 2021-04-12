import telegram
from .interface import TeleMessagingInterface, TelePostingInterface
from os import getenv as env
from telegram import (ReplyKeyboardMarkup, InlineKeyboardMarkup, InlineKeyboardButton)
from telegram.ext import (Updater, CommandHandler, MessageHandler, Filters, ConversationHandler, CallbackQueryHandler, InlineQueryHandler)
import requests
import jwt
import datetime
import uuid
import hashlib
import concurrent.futures

class TeleServiceModel():
    def message_user(acceptor_id, poster_id, username, title):
        bot = telegram.Bot(token=env("NEIB"))      #neib
        buttons = [[InlineKeyboardButton("Sign up form", url='https://scrbac.com/yihling_form')]]
        keyboard = InlineKeyboardMarkup(buttons)
        bot.send_message(chat_id= acceptor_id, text = "Click [here](tg://user?id={}) to private message \"{}\" {}".format(str(poster_id), username, title), parse_mode="markdown")


    # def posting(info, where, when, tip, comm, postal):
    def posting(orb_UUID, user_id, star_user, tele_username, user_location, title, info, where, when, tip, user_id_list, if_commercial):
        bot = telegram.Bot(token=env("NEIB"))      #neib

        ### since this is sent from the app, it doesnt need to handle the case: 'no username'


        user_location = str(user_location)
        
        if if_commercial == True:
            if star_user:
                text = '[COMMERCIAL POST]\n'\
                        'Enable/Disable commercial post at /start\n\n'\
                        'From postal code: ' + user_location[:2] + 'xxxx\n'\
                        'Sent from the app!\n'\
                        '🙏 REQUEST! \n \n'\
                        'Title: {}\n'\
                        '🔮 Info: {}\n'\
                        '📍 Where: {}\n'\
                        '🕒 When: {}\n'\
                        '💰 Tip/Charge: {}\n'\
                        '👤 Requested by: ⭐️[[[{}]]]⭐️\n \n'\
                        'Press /start to open menu📖'.format(title, info, where, when, tip, tele_username)
            else:
                text = '[COMMERCIAL POST]\n'\
                        'Enable/Disable commercial post at /start\n\n'\
                        'From postal code: ' + user_location[:2] + 'xxxx\n'\
                        'Sent from the app!\n'\
                        '🙏 REQUEST! \n \n'\
                        'Title: {}\n'\
                        '🔮 Info: {}\n'\
                        '📍 Where: {}\n'\
                        '🕒 When: {}\n'\
                        '💰 Tip/Charge: {}\n'\
                        '👤 Requested by: [[[{}]]]\n \n'\
                        'Press /start to open menu📖'.format(title, info, where, when, tip, tele_username)
        else:
            if star_user:
                text = 'From postal code: ' + user_location[:2] + 'xxxx\n'\
                        'Sent from the app!\n'\
                        '🙏 REQUEST! \n \n'\
                        'Title: {}\n'\
                        '🔮 Info: {}\n'\
                        '📍 Where: {}\n'\
                        '🕒 When: {}\n'\
                        '💰 Tip/Charge: {}\n'\
                        '👤 Requested by: ⭐️[[[{}]]]⭐️\n \n'\
                        'Press /start to open menu📖'.format(title, info, where, when, tip, tele_username)
            else:
                text = 'From postal code: ' + user_location[:2] + 'xxxx\n'\
                    'Sent from the app!\n'\
                    '🙏 REQUEST! \n \n'\
                    'Title: {}\n'\
                    '🔮 Info: {}\n'\
                    '📍 Where: {}\n'\
                    '🕒 When: {}\n'\
                    '💰 Tip/Charge: {}\n'\
                    '👤 Requested by: [[[{}]]]\n \n'\
                    'Press /start to open menu📖'.format(title, info, where, when, tip, tele_username)

        forwarding_text = 'From postal code: ' + user_location[:2] + 'xxxx\n'\
                            'Sent from the app!\n'\
                            '🙏 REQUEST! \n \n'\
                            'Title: {}\n'\
                            '🔮 Info: {}\n'\
                            '📍 Where: {}\n'\
                            '🕒 When: {}\n'\
                            '💰 Tip/Charge: {}\n'\
                            '👤 Requested by: @{}\n \n'.format(title, info, where, when, tip, tele_username)
        
        def format_for_forwarding(text):
            reserved_characters = {'&':'%26', '?': '%3F', ';': '%3B', ':': '%3A', '"': '%22', '<': '%3C', '>': '%3E', ' ': '%20', '\'': '%27', '\n': '%0a', '#': '%23'}
            forward_url = 'https://t.me/share/url?url=From%20@Scratchbac_sg_bot&text='

            for i in range(len(text)):
                if text[i] in reserved_characters:
                    forward_url += reserved_characters[text[i]]
                else:
                    forward_url += text[i]

            return forward_url

        forward_url = format_for_forwarding(forwarding_text)
        
        delete_dictionary = {}
        buttons = [[InlineKeyboardButton("Message Neighbour", callback_data=str(88)+ orb_UUID)]]
        keyboard = InlineKeyboardMarkup(buttons)
        with concurrent.futures.ThreadPoolExecutor() as executor:
            results = [executor.submit(bot.send_message, ids, text, reply_markup = keyboard) for ids in user_id_list]
            for future in concurrent.futures.as_completed(results):
                try:
                    data = future.result()
                    delete_dictionary[data['chat']['id']] = data['message_id']
                except Exception as exc:
                    pass

        ### need to return delete_dictionary to junwei's api
        
        time = str(datetime.datetime.now().strftime("%m/%d/%Y, %H:%M:%S") ).replace('/','-')     # e.g 06/25/2020, 14:37:34 => 06-25-2020, 14:37:34
        # if ud['is_commercial'] == True:
        #     db.child('commercial buffer').update({user_id:time}, user['idToken']) 

        # send to the team admin account
        admin_button = [[InlineKeyboardButton(text = "message user", callback_data=str(88)+ orb_UUID)]]
        admin_keyboard = InlineKeyboardMarkup(admin_button)
        bot.send_message(chat_id='1349902925', text = user_location + '\n' + text, reply_markup = admin_keyboard)   #SB admin
        bot.send_message(chat_id = '-1001250889655', text = 'Postal code: ' + user_location[:2] + '****\n' + text)
        
