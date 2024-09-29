// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface ISBT {
    // ERROR
    error InvalidOwner(); //"ERROE: owner is not valid"
    error InvalidTokenId(); //"ERROE: token id is not valid"
    error InvalidReceiver(); //"ERROR: Invalid recipient address"
    error NonexistentTokenOwner(uint);
    error SBTNotSupported(string message);

    //Event
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenI
    );

    event Attest(address indexed _to, uint256 indexed _tokenId);
    event Revoke(address indexed _to, uint256 indexed _tokenId);
    event VocationBound(
        address indexed _owner,
        uint256 indexed _tokenId,
        string _vocation
    );
    event BurnOwnersToken(
        address indexed _owner,
        uint256 indexed _tokenId,
        string typeString
    );

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    //Query
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    //IERC721Metadata
    function Name() external view returns (string memory);

    function Symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract SBT is ISBT, AccessControl {
    string private name;
    string private symbol;

    uint256 private currentTokenId = 1;
    uint256 private mintedCount; //已经铸造的token数量

    // 常量定义不同角色，用于后续对不同角色进行授权
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(uint256 => string) private tokenURIs; //tokenId 与 URI 的映射
    mapping(uint256 => string) private vocationTypes; //tokenid 与 typeString 的映射

    mapping(uint256 => address) private owners; //tokenid 跟 owner 地址的映射
    mapping(address => uint256[]) private ownersTokenIds; //owner 跟 tokenid 地址的映射--owner所有的tokenid（SBT）

    mapping(address => uint256) private balances; //某个地址对应的SBT数量

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        //授予调用者msg.sender管理角色权限
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function Name() external view returns (string memory) {
        return name;
    }

    function Symbol() external view returns (string memory) {
        return symbol;
    }

    // 现存--已铸造的token数量
    function existingTokenCount() public view returns (uint256) {
        return mintedCount;
    }

    // 查询某个拥有者的SBT数量
    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) {
            revert InvalidOwner();
        }
        return balances[_owner];
    }

    function tokenID(address _owner) public view returns (uint256[] memory) {
        require(
            ownersTokenIds[_owner].length > 0,
            "ERROR: Owner does not have any tokens"
        );
        return ownersTokenIds[_owner];
    }

    //查看tokenid--owner 的vocationType
    function vocation(uint256 _tokenId) external view returns (string memory) {
        _requireOwned(_tokenId);
        return vocationTypes[_tokenId];
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        _requireOwned(_tokenId);
        return tokenURIs[_tokenId];
    }

    // 设置指定token的tokenURI
    function setTokenURI(uint256 _tokenId, string memory URI) internal {
        address owner = owners[_tokenId];
        if (owner == address(0)) {
            revert InvalidTokenId();
        }
        tokenURIs[_tokenId] = URI;
    }

    // 检查指定的tokenId是否有 owner所有者
    function _requireOwned(uint256 _tokenId) internal view returns (address) {
        address owner = owners[_tokenId];
        if (owner == address(0)) {
            revert NonexistentTokenOwner(_tokenId);
        }
        return owner;
    }

    // 查询指定tokenid的拥有者地址
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return _requireOwned(_tokenId);
    }

    // 检查调用者msg.sender是否拥有某个角色权利
    function _requireRole(
        bytes32 role,
        string memory errorMessage
    ) internal view {
        // 验证msg.sender是否拥有指定角色权利，如果没有，则抛出errorMessage
        require(hasRole(role, msg.sender), errorMessage);
    }

    // 查询是否支持某个指定的接口
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(AccessControl, ISBT) returns (bool) {
        // return
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // 铸造token给指定地址
    function mint(
        address _to,
        string memory URI,
        string memory typeString
    ) internal returns (uint256) {
        _requireRole(MINTER_ROLE, "ERROR: Must have minter role to mint");

        // 检查接收地址，确保地址有效 || _to == owner
        if (_to == address(0)) {
            revert InvalidReceiver();
        }

        uint256 _tokenId = currentTokenId; //tokenId从1开始
        currentTokenId += 1;

        safeMint(_to, _tokenId, typeString);
        setTokenURI(_tokenId, URI);
        return _tokenId;
    }

    // 铸造token给指定地址
    function safeMint(
        address _to,
        uint256 _tokenId,
        string memory typeString
    ) internal {
        _requireRole(MINTER_ROLE, "ERROR: Must have minter role to mint");

        _beforeTokenTransfer(address(0), _to, _tokenId);

        balances[_to] += 1;

        owners[_tokenId] = _to;
        ownersTokenIds[_to].push(_tokenId); //添加新tokenid到对应用户的tokenid列表

        vocationTypes[_tokenId] = typeString; //写入职业类型

        mintedCount += 1;

        require(
            _checkOnERC721Received(address(0), _to, _tokenId, ""),
            "ERROR: ERC721Receiver is not implemented"
        );

        _afterTokenTransfer(address(0), _to, _tokenId);

        emit VocationBound(_to, _tokenId, typeString);
        emit Transfer(address(0), _to, _tokenId);
    }

    // 销毁指定token
    function burn(uint256 _tokenId) internal {
        // 获取token的拥有者
        address owner = _requireOwned(_tokenId);
        string memory typeString = vocationTypes[_tokenId];
        require(owner == msg.sender, "ERROR: Sender is not token owner");
        // 检查调用者是否具有销毁权限
        _requireRole(BURNER_ROLE, "ERROR: Must have burner role to burn");
        _beforeTokenTransfer(owner, address(0), _tokenId);

        balances[owner] -= 1;

        //删除token的信息
        delete owners[_tokenId]; //删除tokenid 与 owner的映射关系
        deleteOwnersToken(owner, _tokenId);

        mintedCount -= 1;

        if (
            bytes(tokenURIs[_tokenId]).length != 0 &&
            bytes(vocationTypes[_tokenId]).length != 0
        ) {
            delete tokenURIs[_tokenId];
            delete vocationTypes[_tokenId];
        }

        emit Transfer(owner, address(0), _tokenId);
        emit BurnOwnersToken(owner, _tokenId, typeString);
        _afterTokenTransfer(owner, address(0), _tokenId);
    }

    function burnFrom(address owner, uint256 _tokenId) internal {
        _requireRole(BURNER_ROLE, "ERROR: Must have burner role to burn");
        require(ownerOf(_tokenId) == owner, "ERROR:Both address are not same");
        burn(_tokenId);
    }

    // burn函数调用-销毁指定的SBt
    function deleteOwnersToken(address _owner, uint256 _tokenId) private {
        uint256[] storage ownersToken = ownersTokenIds[_owner];
        for (uint256 i = 0; i < ownersToken.length; i++) {
            if (ownersToken[i] == _tokenId) {
                ownersToken[i] = ownersToken[ownersToken.length - 1];
                ownersToken.pop();
                break;
            }
        }
    }

    /*
        禁止用户自行转账
    */

    // 授权给某个地址权限管理指定的tokenID的NFT
    function approve(address, uint256) external pure {
        revert SBTNotSupported("approve is not allowed");
    }

    // 获取指定tokenId的管理地址
    function getApproved(uint256) external pure returns (address) {
        revert SBTNotSupported("getApprove is not allowed");
    }

    //转移功能，但限制个人转移
    function transferFrom(address, address, uint256) external pure {
        revert SBTNotSupported("transferFrom is not allowed");
    }

    // 限制个人转移token
    function transfer(address, address, uint256) external pure {
        revert SBTNotSupported("transfer is not allowed");
    }

    // 检查ERC721接收是否成功
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) private returns (bool) {
        // 如果接收地址是合约，则调用onERC721Received函数，并检查返回值是否正确
        if (_to.code.length > 0) {
            try
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                // 如果接收失败，并且没有返回原因，则抛出错误
                if (reason.length == 0) {
                    revert(
                        "ERROR : transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // 如果有返回原因，通过assenbly指令抛出错误（revert）
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            // 如果接收地址不是合约，则返回true
            return true;
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256
    ) internal virtual {
        require(
            _from == address(0) || _to == address(0),
            "Soulbound token cannot be transferred. It can only be burned by the token owner."
        );
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        if (_from == address(0)) {
            emit Attest(_to, _tokenId);
        } else if (_to == address(0)) {
            emit Revoke(_to, _tokenId);
        }
    }
}


