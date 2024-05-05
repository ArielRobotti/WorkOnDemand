// import List "mo:base/List";


module {
    public type Stack<T> = ?(T, Stack<T>);

    public func push<T>(stack: Stack<T>, element: T): Stack<T> = ?(element, stack);

    type A<T> = ?(A<T>, T, A<T>)


};


/*

    A<T> = ?(?(A<T>, T, A<T>), T, ?(A<T>, T, A<T>))



*/

