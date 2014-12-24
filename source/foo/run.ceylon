



"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. All elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First?, Second?]*} smartZipOr<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements)
        given First satisfies Object
        given Second satisfies Object{
    
    [First?, Second?]? merge(First? first, Second? second) 
            => [first, second];
    
    return smartZip(merge, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only matching elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First?, Second?]*} smartZipAnd<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements)
        given First satisfies Object
        given Second satisfies Object{
    
    [First, Second]? intersect(First? first, Second? second)
        => if(exists first, exists second) then [first, second] else null;
    
    
    return smartZip(intersect, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only non matching elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First?, Second?]*} smartZipXor<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements)
        given First satisfies Object
        given Second satisfies Object{
    
    [First?, Second?]? xor(First? first, Second? second)
        => first exists != second exists then [first, second];
    
    
    return smartZip(xor, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only elements from the first
 iterables are kept, if they do not match elements from the second Iterable.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First?, Second?]*} smartZipRemove<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements)
        given First satisfies Object
        given Second satisfies Object{
    
    [First, Null]? remove(First? first, Second? second)
        => if(exists first, !exists second) then [first, null] else null;
    
    
    return smartZip(remove, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. The `zipping`
 methods decides if two matching items must be kept or discarded.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
{[First?, Second?]*} smartZip<First, Second>  
        ([First?, Second?]? zipping(First? firstArg, Second? secondArg),
    Comparison comparing(First x, Second y))
({First*} firstArguments, {Second*} secondArguments)
        given First satisfies Object
        given Second satisfies Object
{
    object iterable satisfies {[First?, Second?]?*} {
        shared actual Iterator<[First?, Second?]?> iterator() {
            value firstIt = firstArguments.iterator();
            value secondIt = secondArguments.iterator();
            variable First? firstArgPending = null;
            variable Second? secondArgPending = null;
            object iterator  satisfies Iterator<[First?, Second?]?> { 
                shared actual [First?, Second?]?|Finished next() {
                    First|Finished firstArg = firstArgPending else firstIt.next();
                    firstArgPending = null;
                    Second|Finished secondArg = secondArgPending else secondIt.next();
                    secondArgPending = null;
                    if(!is Finished firstArg){
                        if(!is Finished secondArg){
                            switch(comparing(firstArg, secondArg))
                            case(equal){ 
                                return zipping(firstArg,secondArg);
                            }
                            case(larger){ // firstArg > secondArg
                                firstArgPending = firstArg;
                                return zipping(null,secondArg);
                            }
                            case(smaller){ // firstArg < secondArg
                                secondArgPending = secondArg;
                                return zipping(firstArg,null);
                            }
                        }else{
                            return zipping(firstArg,null) else finished;
                        }
                    }else{
                        return if(!is Finished secondArg)
                            then (zipping(null,secondArg) else finished)
                            else finished;
                    }
                }
            }
            return iterator ;
        }
    }
    return iterable.coalesced;
}

"test"        
shared void run(){
    
    Comparison intAndString(Integer x, String s){
        assert(exists y = parseInteger(s));
        return x <=> y;
    }
    
    {[Integer?, String?]*}({Integer*}, {String*}) zipOr = smartZipOr(intAndString);   
    assert(zipOr({},{}).sequence() == []);
    assert(zipOr({1},{"1"}).sequence() == [[1,"1"]]);
    assert(zipOr({1},{}).sequence() == [[1,null]]);
    assert(zipOr({},{"1"}).sequence() == [[null,"1"]]);
    assert(zipOr({1,3},{"2","3","4","5"}).sequence() == [[1,null], [null,"2"], [3,"3"], [null,"4"], [null,"5"]]);
    assert(zipOr({1,3,7,8},{"2","3","4","5"}).sequence() == [[1,null], [null,"2"], [3,"3"], [null,"4"], [null,"5"], [7,null], [8,null]]);
    
    
    {[Integer?, String?]*}({Integer*}, {String*}) zipXor = smartZipXor(intAndString); 
    assert(zipXor({},{}).sequence() == []);
    assert(zipXor({1},{"1"}).sequence() == []);
    assert(zipXor({1},{}).sequence() == [[1,null]]);
    assert(zipXor({},{"1"}).sequence() == [[null,"1"]]);
    assert(zipXor({1,3},{"2","3","4","5"}).sequence() == [[1,null], [null,"2"], [null,"4"],[null,"5"]]);
    
    {[Integer?, String?]*}({Integer*}, {String*}) zipAnd = smartZipAnd(intAndString); 
    assert(zipAnd({},{}).sequence() == []);
    assert(zipAnd({1},{"1"}).sequence() == [[1,"1"]]);
    assert(zipAnd({1},{}).sequence() == []);
    assert(zipAnd({},{"1"}).sequence() == []);
    assert(zipAnd({1,3},{"2","3","4","5"}).sequence() == [[3,"3"]]);
    
    {[Integer?, String?]*}({Integer*}, {String*}) zipRemove = smartZipRemove(intAndString);   
    assert(zipRemove({},{}).sequence() == []);
    assert(zipRemove({1},{"1"}).sequence() == []);
    assert(zipRemove({1},{}).sequence() == [[1,null]]);
    assert(zipRemove({},{"1"}).sequence() == []);
    assert(zipRemove({1,3},{"2","3","4","5"}).sequence() == [[1,null]]);
    
}

