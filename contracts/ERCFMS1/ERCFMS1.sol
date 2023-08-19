// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERCFMS1 {
    
    struct File {
        bytes encryptedData;
        bytes encryptedName;
        bytes encryptedFolder; // Added the folder field
        bytes encryptedKind;
        bytes encryptedAESKey;
        bytes iv;
        bytes contentHash;
        uint256 blockNumber;
        uint256 timestamp;
        address[] sentTo;
    }

    mapping(address => File[]) public userFiles;
    mapping(address => File[]) public receivedFiles;

    event FileAdded(address indexed user, uint256 indexed index);
    event FileSent(
        address indexed sender,
        address indexed receiver,
        uint256 indexed index
    );

    function addFile(
        bytes memory encryptedData,
        bytes memory encryptedName,
        bytes memory encryptedFolder,  // Added the folder parameter
        bytes memory encryptedKind,
        bytes memory encryptedAESKey,
        bytes memory iv,
        bytes memory contentHash
    ) public {
        File memory newFile = File(
            encryptedData,
            encryptedName,
            encryptedFolder,  // Added the folder field here
            encryptedKind,
            encryptedAESKey,
            iv,
            contentHash,
            block.number,
            block.timestamp,
            new address[](0)
        );
        userFiles[msg.sender].push(newFile);
        emit FileAdded(msg.sender, userFiles[msg.sender].length - 1);
    }

    function sendFile(
        address receiver,
        uint fileIndex,
        bytes memory encryptedData,
        bytes memory encryptedName,
        bytes memory encryptedFolder, // Added the folder parameter
        bytes memory encryptedKind,
        bytes memory encryptedAESKey,
        bytes memory iv
    ) public {
        require(
            fileIndex < userFiles[msg.sender].length,
            "File index out of bounds"
        );
        File storage originalFile = userFiles[msg.sender][fileIndex];
        originalFile.sentTo.push(receiver);
        File memory sentFile = File(
            encryptedData,
            encryptedName,
            encryptedFolder,  // Added the folder field here
            encryptedKind,
            encryptedAESKey,
            iv,
            originalFile.contentHash,
            block.number,
            block.timestamp,
            new address[](0)
        );
        receivedFiles[receiver].push(sentFile);
        emit FileSent(msg.sender, receiver, receivedFiles[receiver].length - 1);
    }

    function getUserFilesCount(address user) public view returns (uint256) {
        return userFiles[user].length;
    }

    function getUserFiles(address user) public view returns (File[] memory) {
        return userFiles[user];
    }

    function getReceivedFilesCount(address user) public view returns (uint256) {
        return receivedFiles[user].length;
    }

    function getReceivedFiles(address user) public view returns (File[] memory) {
        return receivedFiles[user];
    }
}
