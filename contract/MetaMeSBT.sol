// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./SBT.sol";

contract METAMESBT is SBT {
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol
    ) SBT(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function Mint(
        address _to,
        string memory URI,
        string memory typeString
    ) public returns (uint256){
        _requireRole(MINTER_ROLE, "ERROR: Must have minter role to mint");
        return mint(_to, URI, typeString);
    }

    function Burn(address _owner, uint256 _tokenId) public {
        _requireRole(BURNER_ROLE, "ERROR: Must have burner role to burn");
        burnFrom(_owner, _tokenId);
    }
}