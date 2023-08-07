// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERCVC1 - Village Contract Version 1
 * @notice ERCVC1 is a contract that simulates a village with virtual houses. Each house is
 * associated with cryptographic keys, and owners can build houses in the village.
 * @dev This contract allows users to create and manage virtual "houses" in a village.
 * Each house is associated with an encrypted private key and a public key.
 * The private key of each house is encrypted using AES256, and the decryption process is
 * specified in the House struct.
 */
contract ERCVC1 {

    /**
     * @notice Represents a House within the Village.
     * @dev The private key is encrypted with AES256 and decrypted through a three-step process:
     * 1. Sign the public key using the owner address's private key.
     * 2. Hash the signature using keccak256.
     * 3. Enter the hashed signature into AES256 to decrypt the private key.
     */
    struct House {
        address owner; // Address of the house owner.
        string publicKey; // Public key for the house.
        string privateKeyEncrypted; // Private key encrypted with AES256.
        uint256 blockNumber; // Block number when the house was created or modified.
    }

    // Event emitted when a new house is built.
    event HouseBuilt(address indexed user);

    // Mapping from an address to an array of houses owned by that address.
    mapping(address => House[]) public houses;

    // Array of all houses in the village.
    House[] public allHouses;

    /**
     * @notice Allows a user to build a new house.
     * @param publicKey The public key associated with the house.
     * @param privateKeyEncrypted The private key encrypted using AES256.
     */
    function buildHouse(
        string memory publicKey,
        string memory privateKeyEncrypted
    ) public {
        House memory newHouse = House(msg.sender, publicKey, privateKeyEncrypted, block.number);
        houses[msg.sender].push(newHouse);
        allHouses.push(newHouse);
        emit HouseBuilt(msg.sender);
    }

    /**
     * @notice Retrieves the most recent house for the given address.
     * @param _address The address whose house is to be retrieved.
     * @return House The most recent house for the given address.
     */
    function getResidence(address _address) public view returns (House memory) {
        require(houses[_address].length > 0, "No houses found for the address");
        return houses[_address][houses[_address].length - 1];
    }

    /**
     * @notice Retrieves all the houses for the given address.
     * @param _address The address whose houses are to be retrieved.
     * @return House[] An array containing all the houses for the given address.
     */
    function getHouses(address _address) public view returns (House[] memory) {
        return houses[_address];
    }

    /**
     * @notice Retrieves all the houses in the village.
     * @return House[] An array containing all the houses.
     */
    function getAllHouses() public view returns (House[] memory) {
        return allHouses;
    }

    /**
     * @notice Retrieves the total number of houses in the village.
     * @return uint256 The total number of houses.
     */
    function getAllHousesLength() public view returns (uint256) {
        return allHouses.length;
    }

}
