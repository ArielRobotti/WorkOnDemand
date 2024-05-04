module{
    public type UserID = Text;
    public type LaburoID = Text;

    public type User = {
        userID: UserID;
        name: Text;
        email: Text;
        avatar: ?Blob;
        laburos: [LaburoID];
        score: Nat;
    };

    public type User_settings = {
        name: ?Text;
        email: ?Text;
    };

    public type VariantService = {
        #Basic: {price: Float; description: Text};
        #Medium: {price: Float; description: Text};
        #Advanced: {price: Float; description: Text};
        #Custom: {price: Float; description: Text};
    };

    public type Status ={
        #Active;
        #Suspended;
    };

    public type LaburoInit = {
        title: Text;
        description: Text;
        image: Blob;
        variantService: [VariantService];
    };

    public type Laburo = {
        userID: UserID;
        title: Text;
        description: Text;
        image: Blob;
        variantService: [VariantService];
        status: Status;
        score: Nat;
        reviews: [Text];
    };
    public type Laburo_settings = {
        title: ?Text;
        description: ?Text;
        image: ?Blob;
        variantService: ?[VariantService];
    };

    public type LaburoPreview = {
        title: Text; 
        id: Text; 
        image: Blob
    };
    
}