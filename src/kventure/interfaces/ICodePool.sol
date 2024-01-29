// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICode.sol";

interface ICodePool {
    function addCode(Code memory code) external returns (bool);

    function getCodeInfo(bytes32 codeHash) external returns (Code memory);

    function burnCode(bytes32 codeHash) external returns (bool);

    function updateCode(Code memory updatedCode) external returns (bool);

    function activateCode(
        string memory codeStr,
        address activator
    ) external returns (bool);

    function blockCode(
        address caller,
        bytes32[] memory codeHash
    ) external returns (bool[] memory);

    function unblockCode(
        address caller,
        bytes32[] memory codeHash
    ) external returns (bool[] memory);

    function updateExpiredCode(bytes32 codeHash) external returns (bool);

    function updateCodeWalletKey(
        address caller,
        bytes32 codeHash,
        string calldata rawKey,
        bytes32 newKeyHash
    ) external returns (bool);

    function unlockCodeWalletKey(
        address caller,
        bytes32 codeHash,
        string calldata rawKey
    ) external returns (bool);

    function setCodeLockTime(
        address caller,
        bytes32 codeHash,
        uint256 newLockTime,
        uint256 lockRate
    ) external returns (bool);

    function getCodeList(address caller) external returns (Code[] memory codes);
}
