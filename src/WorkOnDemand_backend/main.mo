import Rand "mo:random-class/Rand";
import Set "mo:map/Set";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import { phash; thash } "mo:map/Map";
import Types "./types"

actor {

    ///////////////////// declaraciones de tipos /////////////////////////////////////

    public type UserID = Types.UserID;
    public type User = Types.User;

    public type Gig = Types.Gig;
    public type GigInit = Types.GigInit;
    public type GigID = Types.GigID;



    ////////////////////////////// Registros de usuarios y servicios ///////////////////

    stable let users = Map.new<Principal, User>();
    stable let gigs = Map.new<GigID, Gig>();

    //////////// Objeto fuente de aleatoriedad para generar ids ///////////////////////


    let randStore = Rand.Rand();
    randStore.setRange(100000, 999999);

    ///////////////////////////////////////////////////////////////////////////////////
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
        let newUser = {userID; name; email; avatar; gigs = []; score = 0};
        ignore Map.put<Principal, User>(users, phash, caller, newUser);
        ?userID;
    };

    ////////////////////////////// Funciones de verificacion ///////////////////////////////////

    func isUser(p: Principal): Bool{ Map.has<Principal, User>(users, phash, p) };


    ////////////////////////// Creacion de servicios ///////////////////////////////////////////

    public shared ({caller}) func createGig(gig: GigInit ): async GigID {
        let user = Map.get<Principal, User>(users, phash, caller);
        switch user {
            case null {assert false; ""};  //Tiene pinta de mala practica :D
            case (?user){
                randStore.setRange(10_000_000_000, 99_999_999_999);
                let gigID = await generateID("G");
                randStore.setRange(100000, 999999);
                let newGig = {
                    gig with 
                    userID = user.userID;
                    score = 0;
                    reviews = [];
                    };
                ignore Map.put<GigID, Gig>(gigs, thash, gigID, newGig);
                gigID;
            };
        };

    };

};
