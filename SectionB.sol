// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Section B Learnings

// 1. How is data stored in Memory
/*
    In memory each slot stores 1 byte unlike 32 bytes in storage
    The slots in the memory is grouped in 32 slots like [0x00 to 0x20)[0x20 to 0x40)
    
    mload(location) => Loads 32 bytes from the location
    mstore(location,value) => Stores 32 bytes of value to the location 
    mstore8(location,value) => Stores 1 byte of value to the location
    msize() => Returns the farthest memory pointer
*/

// 2. How solidity uses Memory 
/*
    Slots [0x00 to 0x20)[0x20 to 0x40) => Scratch space => Values stored here last only for a short period of time. It may contain values from the previous operations too. 
    Slots [0x40 to 0x60) => Free memory pointer. It points to the location where the new memory variables are gonna be written. 
    Slots [0x60 to 0x80) => Required to be left empty by Solidity.
    Slots [0x80 to ... => All memory vars. Structs and Arrays and everything
*/

// 3. How memory gets stored
/*
    When you declare a struct or an uint it gets stored from the memory 0x80 
    uint occupies 32 bytes from 0x80 to 0x9F

    When you declare bytes using abi.encode, first it will store the total length of bytes of the data.
    for example,
        abi.encode(5,10)
    [0x80 to 0xa0) => 0x0000000000000000000000000000000000000000000000000000000000000040 (64)
    [0xa0 to 0xc0) => 0x0000000000000000000000000000000000000000000000000000000000000005 (5)
    [0xc0 to 0xe0) => 0x000000000000000000000000000000000000000000000000000000000000000a (10)

    For abi.encode, Smaller uints like uint16, uint128 gets padded to fit the bytes32
    for example,
        abi.encode(uint256(10),uint16(20),uint8(10));
    [0x80 to 0xa0) => 0x0000000000000000000000000000000000000000000000000000000000000060 (96) // Indicating the next 96 bytes are occupied by bytes data
    [0xa0 to 0xc0) => 0x000000000000000000000000000000000000000000000000000000000000000a (10) // Uint256 occupies the entire 32 bytes
    [0xc0 to 0xe0) => 0x0000000000000000000000000000000000000000000000000000000000000014 (20) // Uint16 only requires 2 bytes but occupies the entire 32 bytes
    [0xe0 to 0x100) => 0x000000000000000000000000000000000000000000000000000000000000000a (10) // Uint8 only requires 1 byte but occupies the entire 32 bytes

    For abi.encodePacked, It tries to take the least space possible.
    for example,
        abi.encodePacked(uint256(21),uint8(8),uint64(39));
    [0x80 to 0xa0) => 0x0000000000000000000000000000000000000000000000000000000000000060 (64) // Indicating the next 64 byets are occupied by bytes data
    [0xa0 to 0xc0) => 0x0000000000000000000000000000000000000000000000000000000000000015 (21) // Uint256 occupies the entire 32 bytes
    [0xc0 to 0xe0) => 0x0800000000000000270000000000000000000000000000000000000000000000 (8 and 39) // Uint8 and Uint64 are packed into the same 32 bytes data
    Note that Free space pointer (0x40) points at 0xc9 which is the end of the uint64 data.

    For fixed length arrays, the values get placed sequentially.

    For dynamic arrays, just like abi.encode or abi.encodePacked bytes data, the first item consists of the length of the array.
    Hence, to read the values in the array, let's say a uint256 array you need to jump 0x20 bytes until you read the entire data.
    Small length arrays like uint16 take up the entire 32 bytes each element just like abi.encode.

*/

// 4. Storage to memory writing
/*
    Writing a packed array from storage, unpacks it and stores in the memory

    For example,
        uint8[] foo=[1,2,3,4,5,6] is stored within 32 bytes
    But when stored in memory from storage,
        function unpacked() external {
            uint8[] memory bar = foo;
        }
    Each uint8 value gets stored in a seperate bytes32 slot.
*/

// 5. How to return value
/*
    To return some data, you need to pass the starting and ending pointer to the return function
    For ex,
        function return2and4() external pure returns(uint256, uint256){
            assembly {
                mstore(0x00, 2) // Stores 2 in the scratch space
                mstore(0x20, 4) // Stores 4 in the scratch space
                return(0x00, 0x40) // Returns 64 bytes from 0x00 to 0x40
            }
        }
    One thing to note about return function,
    If you provide incorrect data length, it does not cause error in the transaction.
    But it causes error in the client side which expects the correct length to be decoded.
    For ex,
        return(0x00, 0x20) will result in error in the client side
    where,
        return(0x00, 0x60) will not result in error but only returns the first 64 bytes
*/


// 6. How to revert
/*
    In regular, revert or require you can stop execution by just throwing the error message
    But now, you can revert by returning a value.
    function require() external view{
        assembly{
            if iszero(eq(caller(), 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5)) {
                revert(0, 0)
            }
        }
    }
*/

// 7. How to Keccack256
/*
    IMPORTANT: Note that the free memory pointer does not get updated on it's own in assembly.
    We need to manually move the freeMemoryPointer to the right place.
    function hashFunction() external pure returns(bytes32)
    {
        assembly{
            let freeMemoryPointer := mload(0x40) // Loading the Free Memory Pointer = 0x80
            mstore(freeMemoryPointer, 1)  // Storing 1 in 0x80
            mstore(add(freeMemoryPointer, 0x20), 2) // Storing 2 in 0xa0
            mstore(add(freeMemoryPointer, 0x40), 3) // Storing 3 in 0xc0
            mstore(0x40, add(freeMemoryPointer, 0x60)) // Adjusting the Free Memory Pointer to point at the right slot
            mstore(0x00, keccak256(freeMemoryPointer, 0x60)) // Reading the next 96 bytes from 0x80 and taking the keccak256 hash and storing it in the scratch space

            return(0x00, 0x20) // Returning the hash from the scratch space
        }
    }
*/

// 8. Logging/Emitting events
/*
    There are two types of params
        i. indexed
        ii. non-indexed (data)
    Syntax,
        logn(messageLocation, length, topic1, topic2, ....., topicn)
    
    For ex,
        event SomeLog(uint256 indexed a, uint256 indexed b)
        event SomeLogV2(uint256 indexed c, bool yea)

    function emitSomeLog() external{
        assembly{
            let signature := 0x846f63ba0e83ed1660a06bee093114d2d037ae0f2ca59ebbf117675fe9b2e494 // keccak256("SomeLog(uint256,uint256)")
            log3(0, 0, signature, 4, 10) // This is equivalent to emit SomeLog(4,10)
        }
    }

    function emitSomeLogV2() external {
        assembly{
            let signature := 0x96990723f05e4383865237ead93d95e5b95376f511b564c3e6a05a7b83ac348a // keccak256("SomeLogV2(uint256,bool)")
            mstore(0x00, 1)
            log2(0x00, 0x20, signature, 69); // Equivalent to emit SomeLogV2(69, true);
        }
    }
*/

// 9. Usage of selfdestruct
/*
    Syntax,
        selfdestruct(address)
    When a contract is self-destructed using selfdestruct, the contract's code and storage are not automatically cleared.
    However, once a contract is destroyed, its code is no longer reachable or executable.
    The storage and code may still persist on the blockchain, but it becomes effectively unreachable.
*/

contract Memory {

    struct Point{
        uint256 x;
        uint256 y;
    }

    event MemoryPointer(bytes32);
    event MemoryPointerWithSize(bytes32,bytes32);

    function mstore() public pure {
        assembly{
            mstore(0x0,69)
            mstore8(0x0,99)
        }
    }

    function abiEncode() external {
        bytes32 x;
        assembly{
            x := mload(0x40)
        }
        emit MemoryPointer(x);
        abi.encode(uint256(10),uint16(20),uint8(10));

        assembly{
            x := mload(0x40)
        }
        emit MemoryPointer(x);
    }

    function abiEncodePacked()external {
        bytes32 x;
        assembly{
            x := mload(0x40)
        }
        emit MemoryPointer(x);
        abi.encodePacked(uint256(21),uint8(8),uint64(39));
        assembly{
            x := mload(0x40)
        }
        emit MemoryPointer(x);
    }

    event ArrayData(bytes32 loc,bytes32 size);

    function arrayPointer(uint32[] memory arr) external {

        bytes32 location;
        bytes32 length;
        assembly{
             location := arr
             length := mload(arr)
        }

        emit ArrayData(location,length);
    }

    function breakFreeMemoryPointer(uint256[2] memory foo) external  returns(uint256)
    {
        bytes32 location;
        bytes32 length;
         assembly{
             location := foo
             length := mload(foo)
        }

        emit ArrayData(location,length);
        return foo[0];
    }

    
    function memPointer() external {
        bytes32 x40;
        bytes32 _size;
        assembly{
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);
        Point memory p = Point({x: 1,y: 1});

        assembly{
            x40 := mload(0x40)
            _size := msize()
        }   
        emit MemoryPointerWithSize(x40,_size);

        assembly{
            pop(mload(0xff))
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);

        assembly{
            pop(mload(0x401))
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);
    }

    function memPointer1() external {
        bytes32 x40;
        bytes32 _size;
        assembly{
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);
        Point memory p = Point({x: 1,y: 1});

        assembly{
            x40 := mload(0x40)
            _size := msize()
        }   
        emit MemoryPointerWithSize(x40,_size);

        assembly{
            pop(mload(0xff))
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);

        assembly{
            pop(mload(0x3ff))
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);
    }

    function memPointer2() external {
        bytes32 x40;
        bytes32 _size;
        assembly{
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);
        Point memory p = Point({x: 1,y: 1});

        assembly{
            x40 := mload(0x40)
            _size := msize()
        }   
        emit MemoryPointerWithSize(x40,_size);

        assembly{
            pop(mload(0xff))
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);

        assembly{
            pop(mload(0x400))
            x40 := mload(0x40)
            _size := msize()
        }
        emit MemoryPointerWithSize(x40, _size);
    }

function revertFunction() external view{
        assembly{
            if iszero(eq(caller(), 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5)) {
                revert(0, 0)
            }
        }
    }

        function hashFunction() external pure returns(bytes32)
    {
        assembly{
            let freeMemoryPointer := mload(0x40) // Loading the Free Memory Pointer = 0x80
            mstore(freeMemoryPointer, 1)  // Storing 1 in 0x80
            mstore(add(freeMemoryPointer, 0x20), 2) // Storing 2 in 0xa0
            mstore(add(freeMemoryPointer, 0x40), 3) // Storing 3 in 0xc0
            mstore(0x40, add(freeMemoryPointer, 0x60)) // Adjusting the Free Memory Pointer to point at the right slot
            mstore(0x00, keccak256(freeMemoryPointer, 0x60)) // Reading the next 96 bytes from 0x80 and taking the keccak256 hash and storing it in the scratch space

            return(0x00, 0x20) // Returning the hash from the scratch space
        }
    }

} 