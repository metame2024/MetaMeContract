// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MetaMeSBT.sol";
import "./MetaMeStorageManager.sol";
import "./MetaMe.sol";

contract EnterpriseLifeNFT is ERC721URIStorage, Ownable {

    // 用于跟踪是否已经铸造过NFT
    mapping(address => bool) private _registeredAddresses;
    mapping(address => uint256) private _registerTokenId;

    // 用于存储NFT的附加信息
    mapping(uint256 => string) private _instituteName;
    mapping(uint256 => string) private _instituteCode;
    mapping(uint256 => string) private _instituteLegalRep;
    mapping(uint256 => string) private _instituteAddress;
    mapping(uint256 => string) private _instituteType;
    mapping(uint256 => uint256) private _authorityScore;

    // 机构信息结构体
    struct InstituteInfo {
        string name;
        string code;
        string legalRep;
        string instituteAddress;
        string typeStr;
        uint256 authorityScore;
    }

    METAMESBT private sbtContract; // SBT合约实例
    MetaMeStorageManager private dataStorageContract; // 数据存储合约实例
    MetaMe private tokenContract;
    uint256 private _curTokenId;
    string private contractURI; // 合约级的元数据URI
    uint256 alpha = 256;
    uint256 m = 50;
    uint256 n = 10;
    uint256 halfReduce = 5000 * 10000;

    constructor(
        string memory _name,
        string memory _symbol,
        address _metaMeSbtContract,
        address _dataStorageContract,
        address _toeknContract,
        address initialOwner
    ) ERC721(_name, _symbol) Ownable(initialOwner) { // 调用父类构造函数
        sbtContract = METAMESBT(_metaMeSbtContract);
        dataStorageContract = MetaMeStorageManager(_dataStorageContract);
        tokenContract = MetaMe(_toeknContract);
        _curTokenId = 0;
    }

    // 设置contractURI参数
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // 创建token接口，传入tokenURI和机构信息
    function registerInstitute(string memory _tokenURI, InstituteInfo calldata info) external {
        require(!_registeredAddresses[msg.sender], "EnterpriseLifeNFT: Already registered");
        uint256 tokenId = mint(msg.sender, _tokenURI);
        _setInstituteInfo(tokenId, info);
        _registeredAddresses[msg.sender] = true;
        _registerTokenId[msg.sender] = tokenId;
        tokenContract.transfer(msg.sender, (alpha/4));
    }

    // 更新权威度
    function updateAuthorityScore(uint256 tokenId, uint256 score) external onlyOwner {
        if (_authorityScore[tokenId] <= 0) {
            tokenContract.transfer(msg.sender, alpha*3/4);
        }
        else {
            tokenContract.transfer(msg.sender, alpha+n);
        }
        _authorityScore[tokenId] = score;
    }

    // 向用户发放SBT方法
    function issueSBT(address user, string memory URI, string memory typeString, string memory serializedExperienceString) external onlyOwner {
        // 继续发行 SBT
        uint256 tokenId = sbtContract.Mint(user, URI, typeString);
        // 存储数据到数据存储合约
        dataStorageContract.addUserExperience(tokenId, typeString, serializedExperienceString);
        tokenContract.transfer(msg.sender, alpha+m);
    }

    function getUserSBT(address user) public returns (uint256) {
        require (tokenContract.balanceOf(msg.sender) > m, "user have not enough token");
        tokenContract.transferFrom(msg.sender, address(this), m);
        return sbtContract.balanceOf(user);
    }

    // 私有函数，用于铸造NFT
    function mint(address _to, string memory _tokenURI) private returns (uint256) {
        _curTokenId += 1;
        _mint(_to, _curTokenId);
        _setTokenURI(_curTokenId, _tokenURI);
        return _curTokenId;
    }

    // 设置NFT的额外信息
    function _setInstituteInfo(uint256 tokenId, InstituteInfo memory info) private {
        _instituteName[tokenId] = info.name;
        _instituteCode[tokenId] = info.code;
        _instituteLegalRep[tokenId] = info.legalRep;
        _instituteAddress[tokenId] = info.instituteAddress;
        _instituteType[tokenId] = info.typeStr;
        _authorityScore[tokenId] = info.authorityScore;
    }

    // 获取NFT的详细信息
    function getInstituteInfo() external view returns(InstituteInfo memory) {
        uint256 tokenId = _registerTokenId[msg.sender];
        InstituteInfo memory info;
        info.name = _instituteName[tokenId];
        info.code = _instituteCode[tokenId];
        info.legalRep = _instituteLegalRep[tokenId];
        info.instituteAddress = _instituteAddress[tokenId];
        info.typeStr = _instituteType[tokenId];
        info.authorityScore = _authorityScore[tokenId];
        return info;
    }
}