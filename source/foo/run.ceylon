



"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. All elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First|Mismatch, Second|Mismatch]*} smartZipOr<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements){
    
    [First|Mismatch, Second|Mismatch]? merge(First|Mismatch first, Second|Mismatch second) 
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
    
    [First, Second]? intersect(First|Mismatch first, Second|Mismatch second)
        => if(!is Mismatch first, !is Mismatch second) then [first, second] else null;
    
    
    return smartZip(intersect, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only non matching elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First|Mismatch, Second|Mismatch]*} smartZipXor<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements){
    
    [First|Mismatch, Second|Mismatch]? xor(First|Mismatch first, Second|Mismatch second)
        => first is Mismatch != second is Mismatch then [first, second];
    
    
    return smartZip<First,Second>(xor, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only elements from the first
 iterables are kept, if they do not match elements from the second Iterable.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First, Second|Mismatch]*} smartZipRemove<First, Second>  
        ( Comparison comparing(First x, Second y))
({First*} firstElements, {Second*} secondElements){
    
    [First, Second|Mismatch]? remove(First|Mismatch first, Second|Mismatch second)
        => if(!is Mismatch first, is Mismatch second) then [first, mismatch] else null;
    
    
    return smartZip<First,Second,Nothing>(remove, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. The `zipping`
 methods decides if two matching items must be kept or discarded.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
{[First|FirstMismatch, Second|SecondMismatch]*} smartZip<First, Second, FirstMismatch=Mismatch, SecondMismatch=Mismatch>  
        ([First|FirstMismatch, Second|SecondMismatch]? zipping(First|Mismatch firstArg, Second|Mismatch secondArg),
    Comparison comparing(First x, Second y))
({First*} firstArguments, {Second*} secondArguments){
    object iterable satisfies {[First|FirstMismatch, Second|SecondMismatch]?*} {
        shared actual Iterator<[First|FirstMismatch, Second|SecondMismatch]?> iterator() {
            value firstIt = firstArguments.iterator();
            value secondIt = secondArguments.iterator();
            variable First|Mismatch firstArgPending = mismatch;
            variable Second|Mismatch secondArgPending = mismatch;
            
            function zippingPostponeFirst(First|Mismatch firstArg, Second|Mismatch secondArg){
                firstArgPending = firstArg;
                return zipping(mismatch,secondArg);
            }
            function zippingPostponeSecond(First|Mismatch firstArg, Second|Mismatch secondArg){
                secondArgPending = secondArg;
                return zipping(firstArg,mismatch);
            }
            object iterator  satisfies Iterator<[First|FirstMismatch, Second|SecondMismatch]?> { 
                shared actual [First|FirstMismatch, Second|SecondMismatch]?|Finished next() {
                    First|Finished firstArg = if(!is Mismatch pending = firstArgPending) then pending else firstIt.next();
                    firstArgPending = mismatch;
                    Second|Finished secondArg = if(!is Mismatch pending = secondArgPending) then pending else secondIt.next();
                    secondArgPending = mismatch;
                    return if(!is Finished firstArg) then ( 
                                 if(!is Finished secondArg) then (
                                       switch(comparing(firstArg, secondArg))
                                            case(equal) zipping(firstArg,secondArg)
                                            case(larger) zippingPostponeFirst(firstArg,secondArg)
                                            case(smaller) zippingPostponeSecond(firstArg,secondArg) 
                                   )
                                  else zipping(firstArg,mismatch) 
                                )
                           else (
                                if(!is Finished secondArg) 
                                then (zipping(mismatch,secondArg))
                                else finished 
                           );
                    
                }
            }
            return iterator ;
        }
    }
    return iterable.coalesced;
}

shared abstract class Mismatch() of mismatch {}
shared object mismatch extends Mismatch() {
    shared actual String string = "mismatch";
}

"test"        
shared void run(){
     
    Comparison intAndString(Integer x, String s){
        assert(exists y = parseInteger(s));
        return x <=> y;
    }
    
    
    
    {[Integer|Mismatch, String|Mismatch]*}({Integer*}, {String*}) zipOr = smartZipOr(intAndString);  
    assert(zipOr({},{}).sequence() == []);
    assert(zipOr({1},{"1"}).sequence() == [[1,"1"]]);
    assert(zipOr({1},{}).sequence() == [[1,mismatch]]);
    assert(zipOr({},{"1"}).sequence() == [[mismatch,"1"]]);
    assert(zipOr({1,3},{"2","3","4","5"}).sequence() == [[1,mismatch], [mismatch,"2"], [3,"3"], [mismatch,"4"], [mismatch,"5"]]);
    assert(zipOr({1,3,7,8},{"2","3","4","5"}).sequence() == [[1,mismatch], [mismatch,"2"], [3,"3"], [mismatch,"4"], [mismatch,"5"], [7,mismatch], [8,mismatch]]);
    assert(zipOr({1,1,7,7,8},{"1","2","2","3","4","5"}).sequence() == [[1, "1"], [1, mismatch], [mismatch, "2"], [mismatch, "2"], [mismatch, "3"], [mismatch, "4"], [mismatch, "5"], [7, mismatch], [7, mismatch], [8, mismatch]]);
    
    {[Integer|Mismatch, String|Mismatch]*}({Integer*}, {String*}) zipXor = smartZipXor(intAndString); 
    assert(zipXor({},{}).sequence() == []);
    assert(zipXor({1},{"1"}).sequence() == []);
    assert(zipXor({1},{}).sequence() == [[1,mismatch]]);
    assert(zipXor({},{"1"}).sequence() == [[mismatch,"1"]]);
    assert(zipXor({1,3},{"2","3","4","5"}).sequence() == [[1,mismatch], [mismatch,"2"], [mismatch,"4"],[mismatch,"5"]]);
    
    {[Integer, String]*}({Integer*}, {String*}) zipAnd = smartZipAnd(intAndString); 
    assert(zipAnd({},{}).sequence() == []);
    assert(zipAnd({1},{"1"}).sequence() == [[1,"1"]]);
    assert(zipAnd({1},{}).sequence() == []);
    assert(zipAnd({},{"1"}).sequence() == []);
    assert(zipAnd({1,3},{"2","3","4","5"}).sequence() == [[3,"3"]]);
    assert(zipAnd({1,1,2,7,8},{"1","1","2","2"}).sequence() == [[1, "1"], [1, "1"], [2, "2"]]);
    
    {[Integer, String|Mismatch]*}({Integer*}, {String*}) zipRemove = smartZipRemove(intAndString);   
    assert(zipRemove({},{}).sequence() == []);
    assert(zipRemove({1},{"1"}).sequence() == []);
    assert(zipRemove({1},{}).sequence() == [[1,mismatch]]);
    assert(zipRemove({},{"1"}).sequence() == []);
    assert(zipRemove({1,3},{"2","3","4","5"}).sequence() == [[1,mismatch]]);
    
}

