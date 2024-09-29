// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract MetaMeStorageContract {
    address _owner;
    // 用户经历映射
    mapping(uint256 => mapping(bytes32 => bytes[])) private userList;
    mapping(uint256 => mapping(bytes32 => uint256)) private userDataTypeCount;
    // 当前数据存储量
    uint256 private _dataCount;
    // 最大数据存储量
    uint256 private _maxDataCount;
    // 最后一个地址
    uint256 private _lastID;
    // 链表中的下一个合约
    MetaMeStorageContract private _nextContract; // 二叉树中的左右子节点
    MetaMeStorageContract private _leftChild;
    MetaMeStorageContract private _rightChild;

    // 构造函数
    constructor(address owner, uint256 maxDataCount) {
        _owner = owner;
        _dataCount = 0;
        _maxDataCount = maxDataCount;
        _lastID = 0;
        _nextContract = MetaMeStorageContract(address(0));
        _leftChild = MetaMeStorageContract(address(0));
        _rightChild = MetaMeStorageContract(address(0));
    }
    // 添加经历
    function addExperience(uint256 tokenID, bytes32 typeHash, bytes memory serializedExperience) public returns (uint8) {
        require(msg.sender == _owner, "Only the owner can add experiences");
        require(tokenID > 0, "User address cannot be empty");
        // 判断是否还有空间
        if (_dataCount < _maxDataCount) {
            
            userList[tokenID][typeHash].push(serializedExperience);
            userDataTypeCount[tokenID][typeHash]++;
            _dataCount++;
            _lastID = tokenID;
            return 0;
        } else {
            // 没有则返回状态，表示是否需要在左（右）节点创建新的合约
            if (userDataTypeCount[tokenID][typeHash] > 0) {
                return 1;
            } else {
                return 2;
            }
        }
    }
    // 设置链表中的下一个合约
    function addNext(MetaMeStorageContract _next) public {
        require(msg.sender == _owner, "Only the owner can add experiences");
        require(_nextContract == MetaMeStorageContract(address(0)), "Next contract must be empty");
        require(_next != MetaMeStorageContract(address(0)), "Next contract cannot be empty");
        _nextContract = _next;
    }
    // 设置二叉树中的左右子节点
    function setLeftChild(MetaMeStorageContract _left) public {
        require(msg.sender == _owner, "Only the owner can add experiences");
        require(_leftChild == MetaMeStorageContract(address(0)), "Left child must be empty");
        require(_left != MetaMeStorageContract(address(0)), "Left child cannot be empty");
        _leftChild = _left;
    }
    function setRightChild(MetaMeStorageContract _right) public {
        require(msg.sender == _owner, "Only the owner can add experiences");
        require(_rightChild == MetaMeStorageContract(address(0)), "Right child must be empty");
        require(_right != MetaMeStorageContract(address(0)), "Right child cannot be empty");
        _rightChild = _right;
    }
    // 获取链表中的下一个合约
    function getNextContract() public view returns (MetaMeStorageContract) {
        if (_nextContract == MetaMeStorageContract(address(0))) {
            return MetaMeStorageContract(address(0));
        } else {
            return _nextContract;
        }
    }
    // 获取二叉树中的左右子节点
    function getLeftChild() public view returns(MetaMeStorageContract) {
        if (_leftChild == MetaMeStorageContract(address(0))) {
            return MetaMeStorageContract(address(0));
        } else {
            return _leftChild;
        }
    }
    function getRightChild() public view returns(MetaMeStorageContract) {
        if (_rightChild == MetaMeStorageContract(address(0))) {
            return MetaMeStorageContract(address(0));
        } else {
            return _rightChild;
        }
    }
    // 获取最后一个用户的ID
    function getLastUserId() public view returns(uint256) {
        if (_lastID < 1) {
            return 0;
        } else {
            return _lastID;
        }
    }
    // 获取用户经历
    function getUserExperience(uint256 tokenID, bytes32 typeHash) public view returns (bytes[] memory, uint256, MetaMeStorageContract) {
        // 返回数据(如果有)和地址(如果没找到用户数据或者链 表上还有用户数据)
        if (userDataTypeCount[tokenID][typeHash] > 0) {
            if (_nextContract != MetaMeStorageContract(address(0))) {
                return (userList[tokenID][typeHash], userDataTypeCount[tokenID][typeHash], _nextContract);
            } else {
                return (userList[tokenID][typeHash], userDataTypeCount[tokenID][typeHash], MetaMeStorageContract(address(0)));
            }
        } else {
            if (tokenID > _lastID) {
                if (_rightChild != MetaMeStorageContract(address(0))) {
                    return (new bytes[](0), 0, _rightChild);
                } else {
                    return (new bytes[](0), 0, MetaMeStorageContract(address(0)));
                }
            } else {
                if (_leftChild != MetaMeStorageContract(address(0))) {
                    return (new bytes[](0), 0, _leftChild);
                } else {
                    return (new bytes[](0), 0, MetaMeStorageContract(address(0)));
                }
            }
        }
    }
    // 获取用户经历计数
    function getUserExperienceCount(uint256 tokenID, bytes32 typeHash) public view returns(uint256, MetaMeStorageContract) {
        // 返回数据(如果有)和地址(如果没找到用户数据或者链 表上还有用户数据)
        if (userDataTypeCount[tokenID][typeHash] > 0) {
            if (_nextContract != MetaMeStorageContract(address(0))) {
                return (userDataTypeCount[tokenID][typeHash], _nextContract);
            } else {
                return (userDataTypeCount[tokenID][typeHash], MetaMeStorageContract(address(0)));
            }
        } else {
            if (tokenID > _lastID) {
                if (_rightChild != MetaMeStorageContract(address(0))) {
                    return (0, _rightChild);
                } else {
                    return (0, MetaMeStorageContract(address(0)));
                }
            } else {
                if (_leftChild != MetaMeStorageContract(address(0))) {
                    return (0, _leftChild);
                } else {
                    return (0, MetaMeStorageContract(address(0)));
                }
            }
        }
    }
}