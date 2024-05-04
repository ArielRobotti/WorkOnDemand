import Rand "mo:random-class/Rand";
import Set "mo:map/Set";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
// import Iter "mo:base/Iter";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import Types "./types";
import Prim "mo:⛔";

actor {

    ///////////////////// declaraciones de tipos /////////////////////////////////////

    public type UserID = Types.UserID;
    public type User = Types.User;

    public type Laburo = Types.Laburo;
    public type LaburoInit = Types.LaburoInit;
    public type LaburoID = Types.LaburoID;
    public type Laburo_settings = Types.Laburo_settings;
    public type VariantService = Types.VariantService;
    public type User_settings = Types.User_settings;
    type LaburoPreview = Types.LaburoPreview;

    ////////////////////////////// Registros de usuarios y servicios ///////////////////

    stable let users = Map.new<Principal, User>();
    stable let globalLaburos = Map.new<LaburoID, Laburo>();

    //////////// Objeto Rand. Fuente de aleatoriedad para generar ids ///////////////////////

    let randStore = Rand.Rand();
    randStore.setRange(100000, 999999);

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
        let userID = await generateID("US"); //el parametro enviado es el prefijo del id. "US" para ids de usuarios
        let newUser = { userID; name; email; avatar; laburos = []; score = 0 };
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

    ////////////////////////// CRUD de servicios (Laburos) ////////////////////////////////////////

    public shared ({ caller }) func createLaburo(laburo : LaburoInit) : async LaburoID {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { assert false; "" }; //Tiene pinta de mala practica :D
            case (?user) {
                randStore.setRange(10_000_000_000, 99_999_999_999);
                let laburoID = await generateID("G");
                randStore.setRange(100000, 999999);
                let newLaburo = {
                    laburo with
                    userID = user.userID;
                    score = 0;
                    reviews = [];
                    status = #Active;
                };
                ignore Map.put<LaburoID, Laburo>(globalLaburos, thash, laburoID, newLaburo);

                let updateLaburos = Prim.Array_tabulate<LaburoID>(
                    user.laburos.size() + 1,
                    func i {
                        if (i < user.laburos.size()) { user.laburos[i] } else {
                            laburoID;
                        };
                    },
                );
                ignore Map.put<Principal, User>(users, phash, caller, { user with laburos = updateLaburos });
                laburoID;
            };
        };
    };

    public query func readLaburo(_id : LaburoID) : async ?Laburo {
        Map.get<LaburoID, Laburo>(globalLaburos, thash, _id);
    };

    public shared ({ caller }) func updateLaburo(_id : LaburoID, _data : Laburo_settings) : async Bool {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { false };
            case (?user) {
                let laburo = Map.get<LaburoID, Laburo>(globalLaburos, thash, _id);
                switch laburo {
                    case null { false };
                    case (?laburo) {
                        if (laburo.userID != user.userID) { return false };
                        let laburoUpdate = {
                            laburo with
                            title = switch (_data.title) {
                                case null { laburo.title };
                                case (?title) { title };
                            };
                            description = switch (_data.description) {
                                case null { laburo.description };
                                case (?description) { description };
                            };
                            image = switch (_data.image) {
                                case null { laburo.image };
                                case (?image) { image };
                            };
                            variantService = switch (_data.variantService) {
                                case null { laburo.variantService };
                                case (?variantService) { variantService };
                            };
                        };
                        ignore Map.put<LaburoID, Laburo>(globalLaburos, thash, _id, laburoUpdate);
                        true;
                    };
                };
            };
        };
    };

    public shared ({ caller }) func deleteLaburo(_id : LaburoID) : async Bool {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { false };
            case (?user) {
                let laburo = Map.get<LaburoID, Laburo>(globalLaburos, thash, _id);
                switch laburo {
                    case null { false };
                    case (?laburo) {
                        if (laburo.userID != user.userID) { return false };
                        ignore Map.remove<LaburoID, Laburo>(globalLaburos, thash, _id);
                        true;
                    };
                };
            };
        };
    };

    public shared ({ caller }) func toogleStatusLaburo(_id : LaburoID) : async Text {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null { "User Error" };
            case (?user) {
                let laburo = Map.get<LaburoID, Laburo>(globalLaburos, thash, _id);
                switch laburo {
                    case null { "Laburo id error" };
                    case (?laburo) {
                        if (laburo.userID != user.userID) {
                            return "User is not owner";
                        };
                        let status = if (laburo.status == #Active) {
                            { update = #Suspended; show = "Suspend" };
                        } else {
                            { update = #Active; show = "Active" };
                        };
                        let laburoUpdate = { laburo with status = status.update };
                        ignore Map.put<LaburoID, Laburo>(globalLaburos, thash, _id, laburoUpdate);
                        "Laburo " # _id # " is now " # status.show;
                    };
                };
            };
        };
    };

    public shared ({ caller }) func getMyLaburos() : async [Laburo] {
        _getLaburosFromUser(caller);
    };

    func _getLaburosFromUser(_p : Principal) : [Laburo] {
        let user = Map.get<Principal, User>(users, phash, _p);
        switch (user) {
            case null { [] };
            case (?user) {
                let tempBuffer = Buffer.fromArray<Laburo>([]);
                for (id in user.laburos.vals()) {
                    switch (Map.get<LaburoID, Laburo>(globalLaburos, thash, id)) {
                        case (?laburo) {
                            tempBuffer.add(laburo);
                        };
                        case null {};
                    };
                };
                Buffer.toArray<Laburo>(tempBuffer);
            };
        };
    };

    ////////////////////////////////////   Public Getters  ///////////////////////////////////////

    public func getLaburoByUser(p : Principal) : async [Laburo] {
        _getLaburosFromUser(p);
    };

    public func getLaburosPreview() : async [LaburoPreview] {
        let laburosEntries = Map.entries<LaburoID, Laburo>(globalLaburos);
        let tempBuffer = Buffer.fromArray<LaburoPreview>([]);
        for ((id, laburo) in laburosEntries) {
            if (laburo.status == #Active) {
                tempBuffer.add({ title = laburo.title; image = laburo.image; id });
            };
        };
        Buffer.toArray<LaburoPreview>(tempBuffer);
    };

    public func getLaburoById(_id: Text): async ?Laburo {
        Map.get<LaburoID,Laburo>(globalLaburos, thash, _id);
    };

};
