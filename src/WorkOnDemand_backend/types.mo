import List "mo:base/List";

module{
    public type UserID = Text;
    public type WorkID = Text;

    public type User = {
        principal: Principal;
        userID: UserID;
        name: Text;
        email: Text;
        avatar: ?Blob;
        works: [WorkID];
        chats: [ChatID];
        score: Nat;
    };

    public type User_settings = {
        name: ?Text;
        email: ?Text;
    };

    public type VariantWork = {
        #Basic: {price: Float; description: Text};
        #Medium: {price: Float; description: Text};
        #Advanced: {price: Float; description: Text};
        #Custom: {price: Float; description: Text};
    };

    public type Status ={
        #Active;
        #Suspended;
    };
    public type Tag = Text;

    public type WorkInit = {
        title: Text;
        tags: [Tag];
        description: Text;
        image: Blob;
        variantService: [VariantWork];
    };

    public type Review = {
        reviewID: Text;
        reviewer: ?UserID;
        date: Int;
        content: Text
    };

    public type Work = {
        userID: UserID;
        owner: Principal;
        title: Text;
        tags: [Tag];
        description: Text;
        image: Blob;
        variantService: [VariantWork];
        status: Status;
        score: Nat;
        reviews: [Review];
    };
    public type Work_settings = {
        title: ?Text;
        description: ?Text;
        image: ?Blob;
        variantService: ?[VariantWork];
    };

    public type WorkPreview = {
        title: Text; 
        id: Text; 
        image: Blob
    };

    public type ChatID = Text;

    public type Chat = {
        members : [Principal];
        content : List.List<Msg>;
    };

    public type Msg = {
        sender: Principal;
        date: Int;
        content: Text;
        adjunts: [Blob];
    };

    public type Offer = {
        buyer: User;
        workID: WorkID;
        description: Text;
        deliveryDetails: Text;
        deliveryTime: Nat;

    };

    public type OrderStatus = {
        #Sended;
        #Accepted;
        #Rejected;
        #StartedJob: Int; //Timestamp del inicio del trabajo
        #Delivered;
        #Revision: Nat;
        #Mediation;
        #SuccessJob;
    };

    public type Order = {
        orderID: Text;
        buyer: User;
        workID: WorkID;
        description: Text;
        deliveryDetails: Text;
        deliveryTime: Nat;
        status: OrderStatus;
        
    }

    
}