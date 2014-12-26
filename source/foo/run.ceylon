



"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. All elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First|Mismatch, Second|Mismatch]*} smartZipOr<First, Second>  
        ( Comparison comparing(First x, Second y))
        ({First*} firstElements, {Second*} secondElements){
    
    function merge(First|Mismatch first, Second|Mismatch second) => [first, second];
    
    return smartZip<First,Second>(merge, comparing)(firstElements,secondElements);
}

"zip two already sorted `Iterables` using the `comparing` method
 to match the elements of the Iterables. Only matching elements are kept.
 The original sort (ascending) of the two Iterables must be consistent with the `comparing`
 method."
shared {[First, Second]*} smartZipAnd<First, Second>  
        ( Comparison comparing(First x, Second y))
        ({First*} firstElements, {Second*} secondElements){
    
   function intersect(First|Mismatch first, Second|Mismatch second)
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
    
    function xor(First|Mismatch first, Second|Mismatch second)
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
    
    function remove(First|Mismatch first, Second|Mismatch second)
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
                    firstArgPending = mismatch; // reset
                    Second|Finished secondArg = if(!is Mismatch pending = secondArgPending) then pending else secondIt.next();
                    secondArgPending = mismatch; //reset 
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
    
    
    // OR
    {[Integer|Mismatch, String|Mismatch]*}({Integer*}, {String*}) testZipOr = smartZipOr(intAndString);  
    assert(testZipOr({},{}).sequence() == []);
    assert(testZipOr({1},{"1"}).sequence() == [[1,"1"]]);
    assert(testZipOr({1},{}).sequence() == [[1,mismatch]]);
    assert(testZipOr({},{"1"}).sequence() == [[mismatch,"1"]]);
    assert(testZipOr({1,3},{"2","3","4","5"}).sequence() == [[1,mismatch], [mismatch,"2"], [3,"3"], [mismatch,"4"], [mismatch,"5"]]);
    assert(testZipOr({1,3,7,8},{"2","3","4","5"}).sequence() == [[1,mismatch], [mismatch,"2"], [3,"3"], [mismatch,"4"], [mismatch,"5"], [7,mismatch], [8,mismatch]]);
    assert(testZipOr({1,1,7,7,8},{"1","2","2","3","4","5"}).sequence() == [[1, "1"], [1, mismatch], [mismatch, "2"], [mismatch, "2"], [mismatch, "3"], [mismatch, "4"], [mismatch, "5"], [7, mismatch], [7, mismatch], [8, mismatch]]);
    
    // XOR
    {[Integer|Mismatch, String|Mismatch]*}({Integer*}, {String*}) testZipXor = smartZipXor(intAndString); 
    assert(testZipXor({},{}).sequence() == []);
    assert(testZipXor({1},{"1"}).sequence() == []);
    assert(testZipXor({1},{}).sequence() == [[1,mismatch]]);
    assert(testZipXor({},{"1"}).sequence() == [[mismatch,"1"]]);
    assert(testZipXor({1,3},{"2","3","4","5"}).sequence() == [[1,mismatch], [mismatch,"2"], [mismatch,"4"],[mismatch,"5"]]);
    
    // AND
    {[Integer, String]*}({Integer*}, {String*}) testZipAnd = smartZipAnd(intAndString); 
    assert(testZipAnd({},{}).sequence() == []);
    assert(testZipAnd({1},{"1"}).sequence() == [[1,"1"]]);
    assert(testZipAnd({1},{}).sequence() == []);
    assert(testZipAnd({},{"1"}).sequence() == []);
    assert(testZipAnd({1,3},{"2","3","4","5"}).sequence() == [[3,"3"]]);
    assert(testZipAnd({1,1,2,7,8},{"1","1","2","2"}).sequence() == [[1, "1"], [1, "1"], [2, "2"]]);
    
    // REMOVE
    {[Integer, String|Mismatch]*}({Integer*}, {String*}) testZipRemove = smartZipRemove(intAndString);   
    assert(testZipRemove({},{}).sequence() == []);
    assert(testZipRemove({1},{"1"}).sequence() == []);
    assert(testZipRemove({1},{}).sequence() == [[1,mismatch]]);
    assert(testZipRemove({},{"1"}).sequence() == []);
    assert(testZipRemove({1,3},{"2","3","4","5"}).sequence() == [[1,mismatch]]);
    
}

