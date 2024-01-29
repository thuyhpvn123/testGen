// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IBinaryTree {
    struct Node {
        address _address;
        uint256 left; 
        uint256 right; 
        uint256 index; 
    }

    function init(address _address, uint256 _index) external returns (bool);
    function addNode(address pAddress, address _address) external returns (address);
}