// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCVC1 {

    event HouseBuilt(address indexed user);

    struct House {
        address owner;
        string publicKey;
        string privateKeyEncrypted;
        uint256 blockNumber;
    }

    function buildHouse(
        string memory publicKey,
        string memory privateKeyEncrypted
    ) external;

    function getResidence(address _address) external view returns (House memory);

    function getHouses(address _address) external view returns (House[] memory);

    function getAllHouses() external view returns (House[] memory);

    function getAllHousesLength() external view returns (uint256);
}
