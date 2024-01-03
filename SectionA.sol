// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;


// Section A Learnings
// 1. slot, offset
// 2. sload, store
// 3. How to write a for loop in assembly and if statements
/*
    for { let i:=0 } lt(i,10) { i:=add(i,1) }
    {

    }
*/
// 4. iszero, not, lt, gt
// 5. all basic functions - add, sub, mul, div, mod, chl, chr, and, or, xor
// 6. How to write in a slot and How to write in a specific offset in a slot
/*
    function writeToD(uint96 newVal) external {

        assembly{

            let c:= sload(D.slot)

            let clearedD := and(c,0xffffffff000000000000000000000000ffffffffffffffffffffffffffffffff)

            let shiftedNewD := shl(mul(D.offset,8),newVal)

            let modifiedValue := and(clearedD,shiftedNewD)

            sstore(D.slot,modifiedValue)
        }
    } 
*/
// 7. How are arrays stored? Fixed Length, Variable Length
/*

    Fixed Length arrays are as usual stored

    uint256[4] public fixedArray;
    slot 0 => fixedArray[0]
    slot 1 => fixedArray[1]
    slot 2 => fixedArray[2]
    slot 3 => fixedArray[3]

    Variable Length array are stored using the keccak256 of the slot of the array

    uint256[] public variableArray;
    slot := variableArray.slot => Length of the array
    bytes32 location = keccak256(abi.encode(slot))
    
    variableArray[0] = sload(add(location,0))
    variableArray[1] = sload(add(location,1))
    variableArray[2] = sload(add(location,2))
    variableArray[3] = sload(add(location,3))

*/
// 8. How are mappings stored?
/*
    Mappings are stored using the keccak256 of the key and the slot of the mapping
    There is no length in mapping

    mapping(address=>bool) public isWhitelisted;
    slot := isWhitelisted.slot 
    bytes32 location = keccak256(abi.encode(key,slot))
    value := sload(location)

*/
// 9. How are nested mappings stored?
/*
    Nested mappings are created by taking keccak256 of the key1 first and taking the keccak of the next key
    There is no length in nested mapping

    mapping(uint=>mapping(address=>bytes32)) public testMapping;
    slot := testMapping.slot
    bytes32 location = keccak256(abi.encode(key2,keccak256(abi.encode(key1,slot))))
    value := sload(location)

*/

contract YulTypes{

uint128 public C=4;
uint96 public D=6;
uint16 public E=8;
uint8 public  F=1;

uint8[] public nums;
uint128[] public packedNums;

mapping(address => uint16) public isWhitelisted;
mapping(uint256=>mapping(address=>bytes16)) public testMapping;

constructor()
{
    nums=[1,2,3,4,5];
    packedNums=[88,22];

}

function setWhitelisted(address whitelist, uint16 value) public {
    isWhitelisted[whitelist]=value;
}

function setNestedMappingValue(uint256 value,address setterAddress,bytes16 result) public {
    testMapping[value][setterAddress]=result;
}

function getNumsSlot(uint256 index)public view returns(uint256 length,bytes32 value){
    uint256 slot;
    assembly{
        slot:=nums.slot
        length:=sload(nums.slot)
    }   
    bytes32 location=keccak256(abi.encode(slot));

    assembly{
        value:=sload(add(location,index))
    }

}



function getPackedNumsSlot(uint256 index)public view returns(uint256 length,bytes32 value){
   uint256 slot;
    assembly{
        slot:=packedNums.slot
        length:=sload(packedNums.slot)
    }   
    bytes32 location=keccak256(abi.encode(slot));

    assembly{
        value:=sload(add(location,index))
    }
}

    function getMapping(address key)public view returns(bytes32 value){
        uint256 slot;
        assembly{
            slot:=isWhitelisted.slot
        }   
        bytes32 location=keccak256(abi.encode(key,slot));

        assembly{
            value:=sload(location)
        }
    }


    function getNestedMapping(uint256 key1,address key2) public view returns(bytes32 value){
        uint256 slot;
        assembly{
            slot := testMapping.slot
        }
        bytes32 location=keccak256(abi.encode(key2,keccak256(abi.encode(key1,slot))));

        assembly{
            value := sload(location)
        }

    }
    function readSlot() public view returns(bytes32 x)
    {
        assembly{
            x:=sload(0)
        }
    }

    function getOffset() public pure returns(uint256)
    {
        uint256 offset;
        assembly{
            offset:=D.offset
        }
        return offset;
    }
    
    // How to write into a specific offset in a slot
    function writeToD(uint96 newVal) external {
        assembly{

            let c:= sload(D.slot)

            let clearedD := and(c,0xffffffff000000000000000000000000ffffffffffffffffffffffffffffffff)

            let shiftedNewD := shl(mul(D.offset,8),newVal)

            let modifiedValue := and(clearedD,shiftedNewD)

            sstore(D.slot,modifiedValue)
        }
    } 


}