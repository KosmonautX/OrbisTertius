export interface MulticastMessage extends BaseMessage {
    tokens: string[];
}


export interface TopicMessage extends BaseMessage{
    topic: string
}

export interface BaseMessage {
    data?: {
        [key: string]: string;
    };
    notification?: Notification;
    // android?: AndroidConfig;
    // webpush?: WebpushConfig;
    // apns?: ApnsConfig;
    // fcmOptions?: FcmOptions;
}

export interface Notification {
        title?: string;
        body?: string;
        imageUrl?: string;
}
