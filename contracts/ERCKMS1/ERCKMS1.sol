// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title ERC-KMS1 - Ethereum Key Management Service Version 1
 * @notice ERC-KMS1 is a contract standard made by 'Null Technologies Ltd' that manages cryptographic keys.
 * Each key is associated with cryptographic properties, and owners can create keys.
 * @dev This contract allows users to create and manage virtual "keys."
 * Each key is associated with an encrypted private key and a public key.
 * The private key of each key is encrypted using AES256.
 */
contract ERCKMS1 is Ownable { // Changed the name to reflect Key Management Service

    uint256 public _fee;

    // Fee and management
    constructor(uint256 _initialFee, address _owner) {
        _fee = _initialFee;
        transferOwnership(_owner);
    }

    function setFee(uint256 newFee) public onlyOwner {
        _fee = newFee;
    }

    function collectFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to collect");
        payable(owner()).transfer(balance);
    }

    // Struct representing a Key within the KeyRing.
    struct Key {
        string keyName; // The name of the key.
        uint256 keyNumber; // The key number in the address's keyring.
        address owner; // Address of the key owner.
        bytes publicRSAKey; // Public RSA key for the key.
        bytes privateRSAKeyEncrypted; // Corresponding Private RSA key encrypted with AES256.
        uint256 blockNumber; // Block number when the key was created or modified.
    }

    // Event emitted when a new key is made.
    event KeyMade(address indexed user);

    // Mapping from an address to an array of keys owned by that address - their keyring.
    mapping(address => Key[]) public keyRing;

    // Array of all keys.
    Key[] public allKeys;

    /**
     * @notice Allows a user to create a new key. Keyring keys are append only.
     * @param keyName The name of the key (Optional).
     * @param publicRSAKey The public key associated with the key.
     * @param privateRSAKeyEncrypted The private key encrypted using AES256.
     */
    function craftKey(
        string memory keyName,
        bytes memory publicRSAKey,
        bytes memory privateRSAKeyEncrypted
    ) public payable  {
        require(msg.value >= _fee, "Fee not met");
        uint256 keyNumber = allKeys.length + 1;
        Key memory newKey = Key(
            keyName,
            keyNumber,
            msg.sender,
            publicRSAKey,
            privateRSAKeyEncrypted,
            block.number
        );
        keyRing[msg.sender].push(newKey);
        allKeys.push(newKey);
        emit KeyMade(msg.sender);
    }

    /**
     * @notice Retrieves the most recent key for the given address.
     * @param _address The address whose key is to be retrieved.
     * @return Key The most recent key for the given address.
     */
    function getCurrentKey(address _address) public view returns (Key memory) {
        require(keyRing[_address].length > 0, "No keys found for the address");
        return keyRing[_address][keyRing[_address].length - 1];
    }

    /**
     * @notice Retrieves all the keys for the given address.
     * @param _address The address whose keys are to be retrieved.
     * @return Key[] An array containing all the keys for the given address.
     */
    function getKeyRing(address _address) public view returns (Key[] memory) {
        return keyRing[_address];
    }

    /**
     * @notice Retrieves all the keys.
     * @return Key[] An array containing all the keys.
     */
    function getAllKeys() public view returns (Key[] memory) {
        return allKeys;
    }

    /**
     * @notice Retrieves the total number of keys.
     * @return uint256 The total number of keys.
     */
    function getAllKeysLength() public view returns (uint256) {
        return allKeys.length;
    }

    function getDecryptionInstructions() public pure returns (string memory) {
        return (
            "The 'privateRSAKeyEncrypted' of each key is encrypted using AES256, a symmetric encryption algorithm. "
            "This means the same secret key is used for both encryption and decryption. "
            "The decryption process for 'privateRSAKeyEncrypted' is as follows: "
            "1) The 'owner' of the key signs the 'publicRSAKey' using their private Ethereum key. "
            "2) The entire signature is then hashed using the Keccak256 algorithm, a cryptographic hash function used in Ethereum. "
            "3) The resulting hash serves as the AES256 secret key for decrypting the 'privateRSAKeyEncrypted'. "
            "This process ensures that only the 'owner' with the correct private key can derive the AES256 secret key and decrypt the 'privateRSAKeyEncrypted'. "
            "Since AES256 uses a fixed key size of 256 bits, the derived secret key must fit this size. "
            "The AES256 algorithm is standardized, so this process will work with any correct implementation of AES256."
        );
    }
}
