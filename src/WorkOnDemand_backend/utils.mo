
module {
    public let LOGO : Blob = "00/00/00/00"; //Diseñar un logo y cnvertirlo a Blob

    public func inArray<T>(a : [T], e : T, equal : (T, T) -> Bool) : Bool {
        for (i in a.vals()) {
            if (equal(i, e)) {
                return true;
            };
        };
        return false;
    };
}