// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERCKMS1 - Ethereum RSA Cryptographic Key Management System
 * @dev A contract for managing cryptographic keys using RSA encryption.
 */
contract ERCKMS1 is Ownable {

    uint256 public _fee; // The fee required to add a new key

    constructor(uint256 _initialFee, address _owner) {
        _fee = _initialFee;
        transferOwnership(_owner);
    }

    /**
     * @dev Sets a new fee required for adding a new key.
     * @param newFee The new fee value.
     */
    function setFee(uint256 newFee) public onlyOwner {
        _fee = newFee;
    }

    /**
     * @dev Collects accumulated fees and transfers them to the contract owner.
     */
    function collectFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to collect");
        payable(owner()).transfer(balance);
    }

    struct Key {
        address owner;
        bytes publicRSAKey;
        bytes privateRSAKeyEncrypted;
        bytes16 iv; 
        uint256 blockNumber;
    }

    event KeyMade(address indexed user); // Event emitted when a new key is made

    mapping(address => Key[]) public keys; // Mapping to store keys for each user

    Key[] public allKeys; // Array to store all keys added to the system

    /**
     * @dev Adds a new key to the system.
     * @param publicRSAKey The public RSA key.
     * @param privateRSAKeyEncrypted The encrypted private RSA key.
     * @param iv The initialization vector for encryption.
     */
    function addKey(
        bytes memory publicRSAKey,
        bytes memory privateRSAKeyEncrypted,
        bytes16 iv 
    ) public payable {
        require(msg.value == _fee, "Exact fee not met");
        Key memory newKey = Key(
            msg.sender,
            publicRSAKey,
            privateRSAKeyEncrypted,
            iv, 
            block.number
        );
        keys[msg.sender].push(newKey);
        allKeys.push(newKey);
        emit KeyMade(msg.sender);
    }

    /**
     * @notice Retrieves the most recent key for the given address.
     * @param _address The address whose key is to be retrieved.
     * @return Key The most recent key for the given address.
     */
    function getCurrentKey(address _address) public view returns (Key memory) {
        require(keys[_address].length > 0, "No keys found for the address");
        return keys[_address][keys[_address].length - 1];
    }

    /**
     * @notice Retrieves all the keys for the given address.
     * @param _address The address whose keys are to be retrieved.
     * @return Key[] An array containing all the keys for the given address.
     */
    function getKeys(address _address) public view returns (Key[] memory) {
        return keys[_address];
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

    /**
     * @notice Retrieves the number of keys for the given address.
     * @param _address The address whose keys count is to be retrieved.
     * @return uint256 The number of keys for the given address.
     */
    function getUserKeysLength(address _address) public view returns (uint256) {
        return keys[_address].length;
    }

    /**
     * @dev Provides instructions for encrypting and decrypting the privateRSAKeyEncrypted.
     * @return Explanation of the encryption and decryption process.
     */    
    function getDecryptionInstructions() public pure returns (string memory) {
        return (
            "ENCRYPTION PROCESS:\n"
            "1) Key Pair Generation [bytes]: A public-private key pair is generated using the RSASSA-PKCS1-v1_5 algorithm. A 4096-bit modulus and a public exponent of [1, 0, 1] are used, and the hash algorithm is SHA-256.\n"
            "2) Signature Creation [bytes]: The owner of the key creates a signature by signing the public RSA key (bytes) with their private Ethereum key (bytes).\n"
            "3) Signature Hashing [bytes]: The signature (bytes) is hashed with the SHA-256 algorithm, resulting in a fixed-size hash value (bytes).\n"
            "4) Encryption of Private Key [bytes]: Using the hashed signature (bytes) as a secret key, the private RSA key (bytes) is encrypted with AES-256. AES in Cipher Block Chaining (CBC) mode is used, and a random initialization vector (IV) [bytes16] is generated to ensure unique encryption.\n"
            "5) Decryption of Private Key [bytes]: To decrypt the encrypted private key (bytes), the owner recreates the hash by signing the public RSA key (bytes) and hashing it with SHA-256 again. The encrypted private key (bytes) and the IV (bytes16) are then decrypted using the hashed signature (bytes) and AES-CBC.\n"
            "This process ensures that only the owner, with the correct private Ethereum key (bytes), can derive the secret key needed for decryption. Standardized algorithms are used, enabling compatibility with various implementations."
        );
    }

}
