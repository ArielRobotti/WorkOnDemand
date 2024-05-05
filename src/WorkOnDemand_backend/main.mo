import Rand "mo:random-class/Rand";
import Set "mo:map/Set";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
// import Iter "mo:base/Iter";
import Map "mo:map/Map";
import List "mo:base/List";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

import { phash; thash } "mo:map/Map";
import Types "./types";
import Prim "mo:⛔";

actor {

    ///////////////////// declaraciones de tipos /////////////////////////////////////

    public type UserID = Types.UserID;
    public type User = Types.User;

    public type Work = Types.Work;
    public type WorkInit = Types.WorkInit;
    public type WorkID = Types.WorkID;
    public type Work_settings = Types.Work_settings;
    public type VariantWork = Types.VariantWork;
    public type User_settings = Types.User_settings;
    public type WorkPreview = Types.WorkPreview;
    public type ChatID = Types.ChatID;
    public type Chat = Types.Chat;
    public type Msg = Types.Msg;
    public type Offer = Types.Offer;

    ////////////////////////////// Registros de usuarios y servicios ///////////////////

    stable let users = Map.new<Principal, User>();
    stable let globalWorks = Map.new<WorkID, Work>();
    stable let chats = Map.new<ChatID, Chat>();

    //////////// Objeto Rand. Fuente de aleatoriedad para generar ids ///////////////////////

    let randStore = Rand.Rand();

    //////////////// Generacion y registro de disponibilidad de ids ///////////////////

    let idsUsed = Set.new<Text>();

    func availableID(id : Text) : Bool {
        switch (Set.contains<Text>(idsUsed, thash, id)) {
            case (?true) { false };
            case _ { true };
        };
    };

    func generateID(prefix : Text) : async Text {
        var postfix = Nat.toText(await randStore.next());
        while (not availableID(prefix # postfix)) {
            postfix := Nat.toText(await randStore.next());
        };
        prefix # postfix;
    };

    ////////////////////////////////////////////////////////////////////////////////////

    public shared ({ caller }) func signUp(name : Text, email : Text, avatar : ?Blob) : async ?UserID {
        assert (not Principal.isAnonymous(caller));
        if (isUser(caller)) { return null };
        randStore.setRange(1000000, 9999999);
        let userID = await generateID("US"); //el parametro enviado es el prefijo del id. "US" para ids de usuarios
        let newUser = {
            principal = caller;
            userID;
            name;
            email;
            avatar;
            works = [];
            score = 0;
            chats = [];
        };
        ignore Map.put<Principal, User>(users, phash, caller, newUser);
        ?userID;
    };

    public shared ({ caller }) func editProfile(settings : User_settings) : async Bool {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { false };
            case (?user) {
                let updateDataUser = {
                    user with
                    name = switch (settings.name) {
                        case null { user.name };
                        case (?name) { name };
                    };
                    email = switch (settings.email) {
                        case null { user.email };
                        case (?email) { email };
                    };
                };
                ignore Map.put(users, phash, caller, updateDataUser);
                true;
            };
        };
    };

    public shared ({ caller }) func getMyUser() : async ?User {
        Map.get(users, phash, caller);
    };

    ////////////////////////////// Funciones de verificacion ///////////////////////////////////

    func isUser(p : Principal) : Bool {
        Map.has<Principal, User>(users, phash, p);
    };

    ////////////////////////// CRUD de servicios (Works) ////////////////////////////////////////

    public shared ({ caller }) func createWork(work : WorkInit) : async WorkID {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { assert false; "" }; //Tiene pinta de mala practica :D
            case (?user) {
                randStore.setRange(10000000000, 99999999999);
                let workID = await generateID("G");
                let newWork = {
                    work with
                    userID = user.userID;
                    owner = caller;
                    score = 0;
                    reviews = [];
                    status = #Active;
                };
                ignore Map.put<WorkID, Work>(globalWorks, thash, workID, newWork);

                let updateWorks = Prim.Array_tabulate<WorkID>(
                    user.works.size() + 1,
                    func i {
                        if (i < user.works.size()) { user.works[i] } else {
                            workID;
                        };
                    },
                );
                ignore Map.put<Principal, User>(users, phash, caller, { user with works = updateWorks });
                workID;
            };
        };
    };

    public query func readWork(_id : WorkID) : async ?Work {
        Map.get<WorkID, Work>(globalWorks, thash, _id);
    };

    public shared ({ caller }) func updateWork(_id : WorkID, _data : Work_settings) : async Bool {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { false };
            case (?user) {
                let work = Map.get<WorkID, Work>(globalWorks, thash, _id);
                switch work {
                    case null { false };
                    case (?work) {
                        if (work.userID != user.userID) { return false };
                        let workUpdate = {
                            work with
                            title = switch (_data.title) {
                                case null { work.title };
                                case (?title) { title };
                            };
                            description = switch (_data.description) {
                                case null { work.description };
                                case (?description) { description };
                            };
                            image = switch (_data.image) {
                                case null { work.image };
                                case (?image) { image };
                            };
                            variantService = switch (_data.variantService) {
                                case null { work.variantService };
                                case (?variantService) { variantService };
                            };
                        };
                        ignore Map.put<WorkID, Work>(globalWorks, thash, _id, workUpdate);
                        true;
                    };
                };
            };
        };
    };

    public shared ({ caller }) func deleteWork(_id : WorkID) : async Bool {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { false };
            case (?user) {
                let work = Map.get<WorkID, Work>(globalWorks, thash, _id);
                switch work {
                    case null { false };
                    case (?work) {
                        if (work.userID != user.userID) { return false };
                        // se remueve la entrada Work correspondiente al WorkID en el mapa
                        ignore Map.remove<WorkID, Work>(globalWorks, thash, _id);
                        // se actualiza la lista de WorkIDs en el perfil del usuario
                        let worksSet = Set.fromIter<WorkID>(user.works.vals(), thash);
                        ignore Set.remove<WorkID>(worksSet, thash, _id);
                        let works = Set.toArray<WorkID>(worksSet);
                        ignore Map.put<Principal, User>(users, phash, caller, {user with works});
                        true;
                    };
                };
            };
        };
    };

    public shared ({ caller }) func toogleStatusWork(_id : WorkID) : async Text {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { "User Error" };
            case (?user) {
                let work = Map.get<WorkID, Work>(globalWorks, thash, _id);
                switch work {
                    case null { "Work id error" };
                    case (?work) {
                        if (work.userID != user.userID) {
                            return "User is not owner";
                        };
                        let status = if (work.status == #Active) {
                            { update = #Suspended; show = "Suspend" };
                        } else {
                            { update = #Active; show = "Active" };
                        };
                        let workUpdate = {
                            work with status = status.update
                        };
                        ignore Map.put<WorkID, Work>(globalWorks, thash, _id, workUpdate);
                        "Work " # _id # " is now " # status.show;
                    };
                };
            };
        };
    };

    public shared ({ caller }) func getMyWorks() : async [Work] {
        _getWorksFromUser(caller);
    };

    func _getWorksFromUser(_p : Principal) : [Work] {
        let user = Map.get<Principal, User>(users, phash, _p);
        switch (user) {
            case null { [] };
            case (?user) {
                let tempBuffer = Buffer.fromArray<Work>([]);
                for (id in user.works.vals()) {
                    switch (Map.get<WorkID, Work>(globalWorks, thash, id)) {
                        case (?work) {
                            tempBuffer.add(work);
                        };
                        case null {};
                    };
                };
                Buffer.toArray<Work>(tempBuffer);
            };
        };
    };

    ////////////////////////////////////   Public Getters  ///////////////////////////////////////

    public func getWorksByUser(p : Principal) : async [Work] {
        _getWorksFromUser(p);
    };

    public func getWorkById(_id : Text) : async ?Work {
        Map.get<WorkID, Work>(globalWorks, thash, _id);
    };

    //////////////////////////// Llamar a esta funcion al cargar galeria de servicios principal /////////////////////////y//////
    // TODO la idea es devolver una cantidad limitada y cuando el usuario escrolee en la galeria ir pidiendo mas desde el front

    public func getWorksPreview() : async [WorkPreview] {
        let worksEntries = Map.entries<WorkID, Work>(globalWorks);
        let tempBuffer = Buffer.fromArray<WorkPreview>([]);
        for ((id, work) in worksEntries) {
            if (work.status == #Active) {
                tempBuffer.add({
                    title = work.title;
                    image = work.image;
                    id;
                });
            };
        };
        Buffer.toArray<WorkPreview>(tempBuffer);
    };

    ////////////////////////////////// Chat entre usuarios //////////////////////////////////////////////

    func pushChatID(_chatMembers : [Principal], _chatID : Text) : () {
        for (member in _chatMembers.vals()) {
            let user = Map.get<Principal, User>(users, phash, member);
            switch user {
                case null {};
                case (?user) {
                    let chatsUpdate = Set.fromIter<ChatID>(user.chats.vals(), thash);
                    ignore Set.put<ChatID>(chatsUpdate, thash, _chatID);
                    let chats = Set.toArray<ChatID>(chatsUpdate);
                    Debug.print(chats[0]);
                    ignore Map.put<Principal, User>(users, phash, member, { user with chats });
                };
            };
        };
    };

    public shared ({ caller }) func askAboutTheWork(_workId : WorkID, _msg : Text, _adjunts : [Blob]) : async () {
        let sender = Map.get<Principal, User>(users, phash, caller);
        switch sender {
            case null { return };
            case (?sender) {
                let work = Map.get<WorkID, Work>(globalWorks, thash, _workId);
                switch work {
                    case null { return };
                    case (?work) {
                        let chatID = sender.userID # " " # _workId;
                        let newMsg : Msg = {
                            sender = caller;
                            date = Time.now();
                            content = _msg;
                            adjunts = _adjunts;
                        };
                        let chat = Map.get<ChatID, Chat>(chats, thash, chatID);

                        var content = switch chat {
                            case null { List.nil<Msg>() };
                            case (?chat) { chat.content };
                        };
                        content := List.push(newMsg, content);
                        let startChat = {
                            members = [caller, work.owner];
                            content;
                        };
                        ignore Map.put<ChatID, Chat>(chats, thash, chatID, startChat);
                        pushChatID([work.owner, caller], chatID);
                    };
                };
            };
        };
    };

    public shared ({ caller }) func readChat(_chatID : ChatID) : async [Msg] {
        //Devuelve los 20 ultimos mensages del chat
        let chat = Map.get<ChatID, Chat>(chats, thash, _chatID);
        switch chat {
            case null { [] };
            case (?chat) {
                assert (Array.find<Principal>(chat.members, func x = x == caller) != null);
                let lastMsg = Buffer.fromArray<Msg>([]);
                var poped = List.pop<Msg>(chat.content);
                var counter = 0;
                while (poped.0 != null and counter < 20) {
                    switch (poped.0) {
                        case (?msg) {
                            lastMsg.add(msg);
                            poped := List.pop<Msg>(poped.1);
                        };
                        case _ {};
                    };
                    counter += 1;
                };
                Buffer.toArray<Msg>(lastMsg);
            };
        };
    };

    public shared ({ caller }) func sendDirectMsg(_receiver : Principal, _msg : Text, _adjunts : [Blob]) : async ChatID {
        let senderUser = Map.get<Principal, User>(users, phash, caller);
        let receiverUser = Map.get<Principal, User>(users, phash, _receiver);
        switch senderUser {
            case null { return "" };
            case (?senderUser) {
                switch receiverUser {
                    case null { return "" };
                    case (?receiverUser) {
                        let chatID = if (senderUser.userID < receiverUser.userID) {
                            senderUser.userID # " " # receiverUser.userID;
                        } else {
                            receiverUser.userID # " " # senderUser.userID;
                        };
                        let newMsg : Msg = {
                            sender = caller;
                            date = Time.now();
                            content = _msg;
                            adjunts = _adjunts;
                        };
                        let chat = Map.get<ChatID, Chat>(chats, thash, chatID);

                        var content = switch chat {
                            case null { List.nil<Msg>() };
                            case (?chat) { chat.content };
                        };
                        content := List.push(newMsg, content);
                        let startChat = {
                            members = [caller, _receiver];
                            content;
                        };
                        ignore Map.put<ChatID, Chat>(chats, thash, chatID, startChat);
                        pushChatID([caller, _receiver], chatID);
                        chatID;
                    };
                };

            };
        };
    };

    public shared ({ caller }) func getMyChats() : async [ChatID] {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch (user) {
            case null { [] };
            case (?user) {
                user.chats;
            };
        };
    };

    public shared ({ caller }) func sendMsgToChat(_chatID : ChatID, _msg : Text, _adjunts : [Blob]) : async Bool {
        assert (isUser(caller));
        let chat = Map.get<ChatID, Chat>(chats, thash, _chatID);
        switch chat {
            case null { false };
            case (?chat) {
                assert (Array.find<Principal>(chat.members, func x = x == caller) != null);
                let newMsg = {
                    sender = caller;
                    date = Time.now();
                    content = _msg;
                    adjunts = _adjunts;
                };
                let content = List.push<Msg>(newMsg, chat.content);
                ignore Map.put<ChatID, Chat>(chats, thash, _chatID, { chat with content });
                true;
            };
        };
    };

    ///////////////////////   Encargo y entrega de servicios //////////////////////////////////////////

    public shared ({caller}) func customOfferWork(_details: Offer): async  Bool{
        let seller = Map.get<Principal, User>(users, phash, caller);
        switch seller {
            case null { false };
            case (?user) {
                assert (user)
            }
        }
    };
};
