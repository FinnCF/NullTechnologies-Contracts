// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCKMS1 {

    struct Key {
        address owner;
        string publicKeyBase64;
        string encryptedPrivateKeyBase64;
        string ivBase64;
        uint256 blockNumber;
    }

    event KeyMade(address indexed user);

    function getCurrentKey(address _address) external view returns (Key memory);
    function getUserKeysLength(address _address) external view returns (uint256);
    function getKeys(address _address) external view returns (Key[] memory);
    function getAllKeys() external view returns (Key[] memory);
    function getAllKeysLength() external view returns (uint256);
    function getDecryptionInstructions() external pure returns (string memory);
}
