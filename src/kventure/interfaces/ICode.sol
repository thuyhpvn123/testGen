// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Status {
    Block,
    Unblock,
    Active,
    Expired
}
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xce5b4dffeb636293708c79f81c22e23cd9e58de35c143478790754258cb2cd38",1,1,1,1,1,"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",0,"haha",1,1,1,"0x0000000000000000000000000000000000000000000000000000000000000000","loc",["truong","duy"]]
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x7177650000000000000000000000000000000000000000000000000000000000",1,1,1,1,1,"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",0,"haha",1,1,1,"0x0000000000000000000000000000000000000000000000000000000000000000","loc",["truong","duy"]]
struct Code {
    address owner;
    bytes32 codeHash;
    uint256 activeTime; // Expiration time = activeTime + boostTime
    uint256 expirationActiveTime;
    uint256 boostSpeed; // 2 Decimal => Remember to divide 100
    uint256 boostTime;
    uint256 rateBoost;
    address delegate;
    Status status;
    string origin; //value: MTI || KVENTURE
    uint256 mintedAmount;
    uint256 releasePercentage; // releasePercent of mintedAmount (100 - LockRate)
    uint256 lockTime;
    bytes32 keyHash; // Pass (Device Generate) == (Keccak256) ==> PassHash (bytes32) => Send PassHash to Smart Contract
    uint256 currentDeposit;
}
