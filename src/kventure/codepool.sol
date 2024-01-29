// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts@v4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@v4.9.0/access/AccessControl.sol";

import {ICodePool} from "./interfaces/ICodePool.sol";
import "./interfaces/ICode.sol";
// import "forge-std/Test.sol";

contract CodePool is ICodePool, AccessControl {
    bytes32 public constant PC_CON = keccak256("POOL_CODE_CONTROLLER_ROLE");
    mapping(bytes32 => address[]) mRoleArrList;

    mapping(bytes32 => Code) mCodeInfo;

    mapping(address => bytes32[]) mCodeList;

    constructor() payable {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        super._grantRole(role, account);
        mRoleArrList[role].push(account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        super._revokeRole(role, account);
        for (uint8 index = 0; index > mRoleArrList[role].length; index++) {
            if (mRoleArrList[role][index] == account) {
                mRoleArrList[role][index] = mRoleArrList[role][
                    mRoleArrList[role].length - 1
                ];
                mRoleArrList[role].pop();
            }
        }
    }

    function addCode(
        Code memory code
    ) external override  returns (bool) {
        // console.log("ppppppppppp");
        require(
            mCodeInfo[code.codeHash].owner == address(0),
            "PoolCode: Code Exist"
        );
        mCodeInfo[code.codeHash] = code;
        mCodeList[code.owner].push(code.codeHash);
        return true;
    }

    function _removeCodeHash(address oldOwner, bytes32 codeHash) internal {
        for (uint256 index; index < mCodeList[oldOwner].length; index++) {
            if (mCodeList[oldOwner][index] == codeHash) {
                mCodeList[oldOwner][index] = mCodeList[oldOwner][
                    mCodeList[oldOwner].length - 1
                ];
                mCodeList[oldOwner].pop();
            }
        }
    }

    function getCodeList(
        address caller
    ) external view override onlyRole(PC_CON) returns (Code[] memory codes) {
        codes = new Code[](mCodeList[caller].length);
        for (uint256 index; index < codes.length; index++) {
            codes[index] = mCodeInfo[mCodeList[caller][index]];
        }
    }

    function _validateCodeHash(bytes32 oldCodeHash) internal view {
        require(
            mCodeInfo[oldCodeHash].owner != address(0),
            "PoolCode: Code Not Exist"
        );
    }

    function updateCode(
        Code memory updatedCode
    ) external onlyRole(PC_CON) returns (bool) {
        _validateCodeHash(updatedCode.codeHash);
        mCodeInfo[updatedCode.codeHash] = updatedCode;
        return true;
    }

    function burnCode(
        bytes32 codeHash
    ) external onlyRole(PC_CON) returns (bool) {
        _validateCodeHash(codeHash);
        delete mCodeInfo[codeHash];
        return true;
    }

    function getCodeInfo(
        bytes32 codeHash
    ) external view override returns (Code memory) {
        _validateCodeHash(codeHash);
        return mCodeInfo[codeHash];
    }

    function activateCode(
        string memory codeStr,
        address activator
    ) external override onlyRole(PC_CON) returns (bool) {
        bytes32 codeHash = keccak256(abi.encodePacked(codeStr));
        _validateCodeHash(codeHash);
        require(
            mCodeInfo[codeHash].expirationActiveTime >= block.timestamp,
            "PoolCode: Expired Activation Time"
        );
        require(
            mCodeInfo[codeHash].status == Status.Unblock,
            "PoolCode: Not Unblocked Code"
        );
        _removeCodeHash(mCodeInfo[codeHash].owner, codeHash);
        mCodeInfo[codeHash].status = Status.Active;
        mCodeInfo[codeHash].activeTime = block.timestamp;
        mCodeInfo[codeHash].owner = activator;
        mCodeList[activator].push(codeHash); // Add New Code To Code List
        return true;
    }

    function blockCode(
        address caller,
        bytes32[] memory codeHashes
    ) external override onlyRole(PC_CON) returns (bool[] memory) {
        bool[] memory result = new bool[](codeHashes.length);
        for (uint16 index = 0; index < codeHashes.length; index++) {
            if (
                mCodeInfo[codeHashes[index]].owner == caller &&
                mCodeInfo[codeHashes[index]].status == Status.Unblock
            ) {
                mCodeInfo[codeHashes[index]].status = Status.Block;
                result[index] = true;
            }
        }
        return result;
    }

    function unblockCode(
        address caller,
        bytes32[] memory codeHashes
    ) external override onlyRole(PC_CON) returns (bool[] memory) {
        bool[] memory result = new bool[](codeHashes.length);
        for (uint16 index = 0; index < codeHashes.length; index++) {
            if (
                mCodeInfo[codeHashes[index]].owner == caller &&
                mCodeInfo[codeHashes[index]].status == Status.Block
            ) {
                mCodeInfo[codeHashes[index]].status = Status.Unblock;
                result[index] = true;
            }
        }
        return result;
    }

    function updateExpiredCode(
        bytes32 codeHash
    ) external override onlyRole(PC_CON) returns (bool) {
        _validateCodeHash(codeHash);
        mCodeInfo[codeHash].status = Status.Expired;
        return true;
    }

    function setCodeLockTime(
        address caller,
        bytes32 codeHash,
        uint256 newLockTime,
        uint256 lockRate
    ) external override onlyRole(PC_CON) returns (bool) {
        require(newLockTime > block.timestamp, "PoolCode: Invalid Lock Time");
        require(
            block.timestamp >= mCodeInfo[codeHash].lockTime,
            "PoolCode: Still Lock"
        );
        require(lockRate <= 100, "PoolCode: Invalid Lock Rate");
        require(
            mCodeInfo[codeHash].owner == caller,
            "PoolCode: Not Code Owner" // ! Sửa lại thông báo lỗi
        );
        mCodeInfo[codeHash].lockTime = newLockTime;
        mCodeInfo[codeHash].releasePercentage = 100 - lockRate;
        return true;
    }

    function updateCodeWalletKey(
        address caller,
        bytes32 codeHash,
        string calldata rawKey,
        bytes32 newKeyHash
    ) external override onlyRole(PC_CON) returns (bool) {
        require(
            mCodeInfo[codeHash].owner == caller,
            "PoolCode: Invalid Wallet Key"
        );
        if (mCodeInfo[codeHash].keyHash != bytes32(0)) {
            require(
                mCodeInfo[codeHash].keyHash ==
                    keccak256(abi.encodePacked(rawKey)),
                "PoolCode: Invalid key hash"
            );
        }
        mCodeInfo[codeHash].keyHash = newKeyHash;
        return true;
    }

    function unlockCodeWalletKey(
        address caller,
        bytes32 codeHash,
        string calldata rawKey
    ) external override onlyRole(PC_CON) returns (bool) {
        require(
            mCodeInfo[codeHash].owner == caller,
            "PoolCode: Invalid Wallet Key"
        );
        require(
            mCodeInfo[codeHash].keyHash == keccak256(abi.encodePacked(rawKey)),
            "PoolCode: Invalid key hash"
        );
        mCodeInfo[codeHash].keyHash = bytes32(0);
        return true;
    }
}
