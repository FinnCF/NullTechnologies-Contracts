// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCKMS1 {
    function setFee(uint256 newFee) external;
    function collectFees() external;
    function craftKey(
        string memory keyName,
        bytes memory publicRSAKey,
        bytes memory privateRSAKeyEncrypted
    ) external payable;
    function getCurrentKey(address _address) external view returns (IERCKMS1.Key memory);
    function getKeyRing(address _address) external view returns (IERCKMS1.Key[] memory);
    function getAllKeys() external view returns (IERCKMS1.Key[] memory);
    function getAllKeysLength() external view returns (uint256);
    function getDecryptionInstructions() external pure returns (string memory);

    struct Key {
        string keyName;
        uint256 keyNumber;
        address owner;
        bytes publicRSAKey;
        bytes privateRSAKeyEncrypted;
        uint256 blockNumber;
    }
}
