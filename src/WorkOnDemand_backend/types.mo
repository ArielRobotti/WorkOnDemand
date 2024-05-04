module{
    public type UserID = Text;
    public type GigID = Text;

    public type User = {
        userID: UserID;
        name: Text;
        email: Text;
        avatar: ?Blob;
        gigs: [GigID];
        score: Nat;
    };

    public type VariantService = {
        #Basic: {price: Float; description: Text};
        #Medium: {price: Float; description: Text};
        #Advanced: {price: Float; description: Text};
        #Custom: {price: Float; description: Text};
    };

    public type GigInit = {
        title: Text;
        description: Text;
        image: Blob;
        variantService: [VariantService];
    };

    public type Gig = {
        userID: UserID;
        title: Text;
        description: Text;
        image: Blob;
        variantService: [VariantService];
        score: Nat;
        reviews: [Text];
    };
}