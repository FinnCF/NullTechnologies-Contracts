// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IsnessFileManager {

    struct File {
        address creator;
        string encryptedDataBase64;
        string encryptedAESKeyBase64;
        string ivBase64;
        uint256 blockNumber;
        string contentHashBase64; // Hash of the original file content
        address[] sentTo;
    }

    // Mapping from user address to file metadata
    mapping(address => File[]) public userFiles;
    mapping(address => File[]) public receivedFiles;

    // Event emitted when a new file is added
    event FileAdded(address indexed user);

    // Event emitted when a file is sent
    event FileSent(address indexed sender, address indexed receiver, uint256 index);

    function addFile(
        string memory encryptedDataBase64,
        string memory encryptedAESKeyBase64,
        string memory ivBase64,
        string memory contentHashBase64
    ) public {
        File memory newFile = File(
            msg.sender,
            encryptedDataBase64,
            encryptedAESKeyBase64,
            ivBase64,
            block.number,
            contentHashBase64,
            new address[](0) // Initialize the sentTo array with an empty array
        );
        userFiles[msg.sender].push(newFile);
        emit FileAdded(msg.sender);
    }

    function sendFile(address receiver, uint fileIndex, string memory encryptedDataBase64, string memory encryptedAESKeyBase64, string memory ivBase64) public {
        require(fileIndex < userFiles[msg.sender].length, "File index out of bounds");

        File storage fileToSend = userFiles[msg.sender][fileIndex];
        fileToSend.sentTo.push(receiver);

        File memory sentFile = File(
            fileToSend.creator,
            encryptedDataBase64,
            encryptedAESKeyBase64,
            ivBase64,
            fileToSend.blockNumber,
            fileToSend.contentHashBase64,
            fileToSend.sentTo
        );

        receivedFiles[receiver].push(sentFile);
        emit FileSent(msg.sender, receiver, receivedFiles[receiver].length - 1);
    }

    function getFileCount(address user) public view returns (uint256) {
        return userFiles[user].length;
    }

    function getFile(
        address user,
        uint256 index
    ) public view returns (File memory) {
        require(index < userFiles[user].length, "File index out of bounds");
        return userFiles[user][index];
    }

    function getReceivedFile(
        address user,
        uint256 index
    ) public view returns (File memory) {
        require(index < receivedFiles[user].length, "File index out of bounds");
        return receivedFiles[user][index];
    }
}
