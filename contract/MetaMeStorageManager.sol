// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./MetaMeStorageContract.sol";

contract MetaMeStorageManager {
    // 存储合约数量
    uint256 private _storageCount;
    // 单个数据存储合约存储最大数量
    uint256 private _storageMaxCount;
    // 保存所有数据存储合约的地址
    MetaMeStorageContract[] private storageContracts;
    // 保存二叉树中的根节点
    MetaMeStorageContract private rootContract;

    // 构造函数
    constructor(uint256 storageMaxCount) {
        _storageMaxCount = storageMaxCount;
        // MetaMeStorageContract storageContract = new MetaMeStorageContract(address(this), _storageMaxCount);
        MetaMeStorageContract storageContract = addNewStorageContract();
        storageContracts.push(storageContract);
        rootContract = storageContract;
    }

    // 获取所有存储合约的数量
    function getAllStorageNums() public view returns (uint256) {
        return _storageCount;
    }

    // 获取单个数据存储合约存储最大数量
    function getMaxStorageNums() public view returns (uint256) {
        return _storageMaxCount;
    }

    // 添加新的数据存储合约
    function addNewStorageContract() private returns (MetaMeStorageContract) {
        MetaMeStorageContract storageContract = new MetaMeStorageContract(address(this), _storageMaxCount);
        storageContracts.push(storageContract);
        _storageCount = _storageCount + 1;
        return storageContract;
    }

    // 合并两个字节数组
    function concatenateBytesArrays(bytes[] memory firstArray, bytes[] memory secondArray) private pure returns (bytes[] memory) {
        // 检查两个数组的长度
        uint256 firstLength = firstArray.length;
        uint256 secondLength = secondArray.length;

        // 创建一个新的数组，长度为两个数组长度之和
        bytes[] memory combinedArray = new bytes[](firstLength + secondLength);

        // 复制第一个数组的内容
        for (uint256 i = 0; i < firstLength; i++) {
            combinedArray[i] = firstArray[i];
        }

        // 如果第二个数组不为空，则复制其内容
        if (secondLength > 0) {
            for (uint256 j = 0; j < secondLength; j++) {
                combinedArray[firstLength + j] = secondArray[j];
            }
        }

        // 返回合并后的数组
        return combinedArray;
    }

    // 根据用户ID查找数据存储合约
    function findUserExperenceByType(uint256 tokenID, string memory typeString) public view returns (string[] memory, uint256) {
        bytes32 typeHash = keccak256(abi.encodePacked(typeString));
        MetaMeStorageContract expression = rootContract;
        bytes[] memory userExperience;
        uint256 userExperienceCount = 0;
        // 循环查找所有对应的用户经历
        do {
            bytes[] memory tmpUserExperience;
            uint256 tmpUserExperienceCount = 0;
            (tmpUserExperience, tmpUserExperienceCount, expression) = expression.getUserExperience(tokenID, typeHash);
            // 当次查找到的用户经历与已经查出的经历合并
            userExperience = concatenateBytesArrays(userExperience, tmpUserExperience);
            userExperienceCount = userExperienceCount + tmpUserExperienceCount;
        } while (expression != MetaMeStorageContract(address(0)));
        // 将bytes数组转换为字符串数组
        string[] memory userExperienceString = new string[](userExperienceCount);
        for (uint256 i = 0; i < userExperienceCount; i++) {
            userExperienceString[i] = string(userExperience[i]);
        }
        return (userExperienceString, userExperienceCount);
    }

    // 根据用户ID查找用户经历总数
    function findUserExperenceCountByType(uint256 tokenID, string memory typeString) public view returns (uint256) {
        bytes32 typeHash = keccak256(abi.encodePacked(typeString));
        MetaMeStorageContract expression = rootContract;
        uint256 userExperienceCount = 0;
        // 循环查找所有对应的用户经历的数量
        do {
            uint256 tmpUserExperienceCount = 0;
            (tmpUserExperienceCount, expression) = expression.getUserExperienceCount(tokenID, typeHash);
            userExperienceCount = userExperienceCount + tmpUserExperienceCount;
        } while (expression != MetaMeStorageContract(address(0)));
        return (userExperienceCount);
    }

    // 添加用户数据
    function addUserExperience(uint256 tokenID, string memory typeString, string memory serializedExperienceString) public returns(bool) {
        uint8 addStatus = 0;
        MetaMeStorageContract expression = rootContract;
        bytes32 typeHash = keccak256(abi.encodePacked(typeString));
        bytes memory serializedExperience = bytes(serializedExperienceString);
        do {
            addStatus = expression.addExperience(tokenID, typeHash, serializedExperience);
            // 可以成功写入数据
            if (addStatus == 1) {
                // 如果当前数据存储合约没有下一个数据存储合约，则添加下一个数据存储合约
                if (expression.getNextContract() == MetaMeStorageContract(address(0))) {
                    MetaMeStorageContract tmpStorageContract = addNewStorageContract();
                    expression.addNext(tmpStorageContract);
                    expression = tmpStorageContract;
                } else {
                    expression = expression.getNextContract();
                }
            } else if (addStatus == 2) {
                // 需要在左右节点查找
                if (tokenID > expression.getLastUserId()) {
                    // 左节点部署
                    if (expression.getRightChild() == MetaMeStorageContract(address(0))) {
                        MetaMeStorageContract tmpStorageContract = addNewStorageContract();
                        expression.setRightChild(tmpStorageContract);
                        expression = tmpStorageContract;
                    } else {
                        expression = expression.getRightChild();
                    }
                } else {
                    // 右节点部署
                    if (expression.getLeftChild() == MetaMeStorageContract(address(0))) {
                        MetaMeStorageContract tmpStorageContract = addNewStorageContract();
                        expression.setLeftChild(tmpStorageContract);
                        expression = tmpStorageContract;
                    } else {
                        expression = expression.getLeftChild();
                    }
                }
            }
        } while (addStatus != 0);
        return true;
    }
}