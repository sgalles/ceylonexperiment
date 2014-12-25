



"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. All elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First?, Second?]*} smartZipOr<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements){
    
    [First?, Second?]? merge(First? first, Second? second) 
            => [first, second];
    
    return smartZip<First,Second>(merge, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only matching elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First, Second]*} smartZipAnd<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements){
    
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
({First*} firstElements, {Second*} secondElements){
    
    [First?, Second?]? xor(First? first, Second? second)
        => first exists != second exists then [first, second];
    
    
    return smartZip<First,Second>(xor, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only elements from the first
 iterables are kept, if they do not match elements from the second Iterable.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First, Second?]*} smartZipRemove<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements){
    
    [First, Null]? remove(First? first, Second? second)
        => if(exists first, !exists second) then [first, null] else null;
    
    
    return smartZip<First,Second,Nothing>(remove, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. The `zipping`
 methods decides if two matching items must be kept or discarded.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
{[First|FirstAbsent, Second|SecondAbsent]*} smartZip<First, Second, FirstAbsent=Null, SecondAbsent=Null>  
        ([First|FirstAbsent, Second|SecondAbsent]? zipping(First? firstArg, Second? secondArg),
    Comparison comparing(First x, Second y))
({First*} firstArguments, {Second*} secondArguments){
    object iterable satisfies {[First|FirstAbsent, Second|SecondAbsent]?*} {
        shared actual Iterator<[First|FirstAbsent, Second|SecondAbsent]?> iterator() {
            value firstIt = firstArguments.iterator();
            value secondIt = secondArguments.iterator();
            variable First|None firstArgPending = none;
            variable Second|None secondArgPending = none;
            object iterator  satisfies Iterator<[First|FirstAbsent, Second|SecondAbsent]?> { 
                shared actual [First|FirstAbsent, Second|SecondAbsent]?|Finished next() {
                    First|Finished firstArg = if(!is None pending = firstArgPending) then pending else firstIt.next();
                    firstArgPending = none;
                    Second|Finished secondArg = if(!is None pending = secondArgPending) then pending else secondIt.next();
                    secondArgPending = none;
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
                            return zipping(firstArg,null);
                        }
                    }else{
                        return if(!is Finished secondArg)
                            then (zipping(null,secondArg))
                            else finished;
                    }
                }
            }
            return iterator ;
        }
    }
    return iterable.coalesced;
}

abstract class None() of none {}
object none extends None() {
    shared actual String string = "none";
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
    
    {[Integer, String]*}({Integer*}, {String*}) zipAnd = smartZipAnd(intAndString); 
    assert(zipAnd({},{}).sequence() == []);
    assert(zipAnd({1},{"1"}).sequence() == [[1,"1"]]);
    assert(zipAnd({1},{}).sequence() == []);
    assert(zipAnd({},{"1"}).sequence() == []);
    assert(zipAnd({1,3},{"2","3","4","5"}).sequence() == [[3,"3"]]);
    
    {[Integer, String?]*}({Integer*}, {String*}) zipRemove = smartZipRemove(intAndString);   
    assert(zipRemove({},{}).sequence() == []);
    assert(zipRemove({1},{"1"}).sequence() == []);
    assert(zipRemove({1},{}).sequence() == [[1,null]]);
    assert(zipRemove({},{"1"}).sequence() == []);
    assert(zipRemove({1,3},{"2","3","4","5"}).sequence() == [[1,null]]);
    
}

