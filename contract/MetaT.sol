// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MetaT is AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SEND_ROLE = keccak256("SEND_ROLE");

    IERC20 public token;
    uint256 public baseAmount = 1 * 10 ** 18;
    uint256 public per = 50000000 * 10 ** 18;
    uint256 public reward = 1 * 10 ** 18;
    uint256 public minted = 0;


    constructor(address _token) {
        token = IERC20(_token);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SEND_ROLE, msg.sender);
    }

    event SendToken(address, uint256);

    //当前合约余额为0时返回0，当前合约余额不足时返回当前合约余额，当前合约余额充足时返回用户要求的数量
    function sendToken(address _to, uint256 amount) external onlyRole(SEND_ROLE) returns(uint256){

        require(amount > 0, "Amount must be greater than 0");
        if (token.balanceOf(address(this)) == 0){
            return 0;
        }
        if (token.balanceOf(address(this)) >= amount){
            token.transfer(_to,amount);
            minted += amount;
            updateReward();
            emit SendToken(_to,amount);
            return amount;
        }else{
            amount = token.balanceOf(address(this));
            token.transfer(_to,amount);
            minted += amount;
            updateReward();
            emit SendToken(_to,amount);
            return amount;
        }
       
    }

    function updateReward() internal {
        if (minted >= per) {
            reward = reward / 2;
            minted = 0;
        }
    }

    function setReward(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        reward = _amount;
    }

    
}