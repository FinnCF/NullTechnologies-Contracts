// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCKMS1 {
    function setFee(uint256 newFee) external;
    function collectFees() external;
    function addKey(string calldata publicKeyBase64, string calldata encryptedPrivateKeyBase64, string calldata ivBase64) external payable;
    function getCurrentKey(address _address) external view returns (address owner, string memory publicKeyBase64, string memory encryptedPrivateKeyBase64, string memory ivBase64, uint256 blockNumber);
    function getKeys(address _address) external view returns (Key[] memory);
    function getAllKeys() external view returns (Key[] memory);
    function getAllKeysLength() external view returns (uint256);
    function getUserKeysLength(address _address) external view returns (uint256);
    function getDecryptionInstructions() external pure returns (string memory);
}

struct Key {
    address owner;
    string publicKeyBase64;
    string encryptedPrivateKeyBase64;
    string ivBase64;
    uint256 blockNumber;
}
