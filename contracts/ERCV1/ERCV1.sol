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
    // Address of the Village Council.
    address public council;

    // The fee for building a house (in wei).
    uint256 public buildingFee;

    // Struct representing a House within the Village.
    struct House {
        string houseName; // The name of the house (Optional).
        uint256 houseNumber; // The house number in the village.
        address owner; // Address of the house owner.
        string publicKey; // Public 4096 bytes RSA key for the house. Public Key Mechanism: Signed by the owner's private ethereum key, then the Signature is Keccak256 hashed to recieve AES256 secret key of privateKeyEncrypted.
        string privateKeyEncrypted; // Corresponding Private 4096 bytes RSA key encrypted with AES256 - decrypted with the secret key from the public key mechanism.
        uint256 blockNumber; // Block number when the house was created or modified.
    }

    // Event emitted when a new house is built.
    event HouseBuilt(address indexed user);

    // Mapping from an address to an array of houses owned by that address.
    mapping(address => House[]) public houses;

    // Array of all houses in the village.
    House[] public allHouses;

    // Constructor to initialize the building fee.
    constructor(uint256 _buildingFee) {
        council = msg.sender;
        buildingFee = _buildingFee;
    }

    // Modifier to allow only the current council to call a function.
    modifier onlyCouncil() {
        require(msg.sender == council, "Only the council can call this function");
        _;
    }

    /**
     * @notice Allows the current council to change the council address.
     * @param _newCouncil The address of the new council.
     */
    function changeCouncil(address _newCouncil) public onlyCouncil {
        require(_newCouncil != address(0), "New council address cannot be zero");
        council = _newCouncil;
    }

    /**
     * @notice Allows a user to build a new house.
     * @param houseName The name of the house (Optional).
     * @param publicKey The public key associated with the house.
     * @param privateKeyEncrypted The private key encrypted using AES256.
     */
    function buildHouse(
        string memory houseName,
        string memory publicKey,
        string memory privateKeyEncrypted
    ) public payable {
        require(msg.value == buildingFee, "Incorrect building fee sent");
        // Transfer the fee to the council's address.
        payable(council).transfer(msg.value);
        uint256 houseNumber = allHouses.length + 1;
        House memory newHouse = House(houseName, houseNumber, msg.sender, publicKey, privateKeyEncrypted, block.number);
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
