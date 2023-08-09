// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCKMS1 {
    function setFee(uint256 newFee) external;
    function collectFees() external;
    function addKey(bytes calldata publicRSAKey, bytes calldata privateRSAKeyEncrypted, bytes16 iv) external payable;
    function getCurrentKey(address _address) external view returns (address owner, bytes memory publicRSAKey, bytes memory privateRSAKeyEncrypted, bytes16 iv, uint256 blockNumber);
    function getKeys(address _address) external view returns (address[] memory owners, bytes[] memory publicRSAKeys, bytes[] memory privateRSAKeyEncrypted, bytes16[] memory ivs, uint256[] memory blockNumbers);
    function getAllKeys() external view returns (address[] memory owners, bytes[] memory publicRSAKeys, bytes[] memory privateRSAKeyEncrypted, bytes16[] memory ivs, uint256[] memory blockNumbers);
    function getAllKeysLength() external view returns (uint256);
    function getUserKeysLength(address _address) external view returns (uint256);
    function getDecryptionInstructions() external pure returns (string memory);
}
