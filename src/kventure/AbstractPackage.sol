//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
    struct PackageInfo {
        address owner;
        bytes32 codeHash;
        uint256 activeTime; // Expiration time = activeTime + boostTime
        uint256 expirationActiveTime;
        uint256 boostSpeed; // 2 Decimal => Remember to divide 100
        uint256 boostTime;
        uint256 rateBoost;
        address delegate;
        PackageStatus status;
        string origin; //value: MTI || KVENTURE
        uint256 mintedAmount;
        uint256 releasePercentage; // releasePercent of mintedAmount (100 - LockRate)
        uint256 lockTime;
        bytes32 keyHash; // Pass (Device Generate) == (Keccak256) ==> PassHash (bytes32) => Send PassHash to Smart Contract
        uint256 currentDeposit;
    }
    enum PackageStatus {
        Block,
        Unblock,
        Active,
        Expired
    }
abstract contract PackageInfoStruct {



    struct Product{
        bytes32 id;
        bytes imgUrl;
        uint256 memberPrice;
        uint256 retailPrice;
        bytes desc;
        bool active;
    }
    struct Order{
        bytes32 id;
        address buyer;
        bytes32[] productIds;
        uint256[] quantities;
        uint256 creatAt;
        uint256 []tokenIds;
        ShippingInfo shipInfo;
        address paymentAdd;
    }
    struct ShippingInfo{
        // bytes32 orderId;
        string fullname;
        string add;
        string phone;
        string zipcode;
        string email;
        uint256 receivingTime;
    }

}