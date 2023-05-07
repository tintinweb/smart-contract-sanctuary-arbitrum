// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./ERC721Holder.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
}

// Farm distributes the ERC20 rewards based on nft to each user.
//
// Modified by ERC20 to work for non-mintable.
contract WAFarm is Ownable, ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256[] tokenids;     // How many tokens the user has provided.
        uint256 lastRewardTime; 
    }

    // Info of lp pool.
    struct PoolInfo {
        uint256 allocToken;         // How many reward tokens per-period, ERC20s to distribute per block.
        // uint256 lastRewardTime;    // Last block number that ERC20s distribution occurs.
        uint256 totalStaked;
    }
    
    // Address of the ERC20 Token contract.
    IERC20 public erc20;
    // Address of the LP ERC20 Token contract.
    INFT public farm_token;

    // Info of pool.
    PoolInfo public poolInfo;

    bool public open; 

    uint256 public computerPeriod;

    mapping (uint256 => address) public depositInfo;

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        computerPeriod = 30 minutes;
        poolInfo = PoolInfo({
                allocToken: 2500000 * 10**18,
                totalStaked: 0
            });
    }

    modifier Open() {
        require(open, "not open");
        _;
    }

    function setDigAmount(uint256 _amount) public onlyOwner {
        poolInfo.allocToken = _amount;
    }

    function toggle() public onlyOwner {
        open = !open;
    }

    /*
     * set reward period
    */
    function setComputerPeriod (uint256 _value) public onlyOwner {
        computerPeriod = _value;
    }

    // stake tokens to Farm for ERC20 allocation.
    function stake(uint256[] calldata _tokenIDs) public Open {
        UserInfo storage user = userInfo[msg.sender];
        
        uint256 amounts = user.tokenids.length;
        if (amounts > 0) {
            uint256 pendingAmount = pending(msg.sender);
            if (pendingAmount > 0) {
                erc20.transfer(address(msg.sender), pendingAmount);
            }
        }

        for (uint i = 0; i < _tokenIDs.length; i++) {
            require(farm_token.ownerOf(_tokenIDs[i]) == msg.sender, "Not NFT Owner");
            // farm_token.safeTransferFrom(address(msg.sender), address(this), _tokenIDs[i]);
            depositInfo[_tokenIDs[i]] = msg.sender;
            user.tokenids.push(_tokenIDs[i]);
        }
        user.lastRewardTime = block.timestamp;
        poolInfo.totalStaked += _tokenIDs.length;
        emit Deposit(msg.sender, _tokenIDs.length);
    }

    /**
     * unStake 
     */
    function unStake() public {
        UserInfo storage user = userInfo[msg.sender];
        uint _amount = user.tokenids.length;
        for (uint i = 0; i < _amount; i++) {
            require(depositInfo[user.tokenids[i]] == msg.sender, "Not NFT Owner");
            delete depositInfo[user.tokenids[i]];
        }
        
        if (user.tokenids.length > 0) {
            uint256 pendingAmount = pending(msg.sender);
            if (pendingAmount > 0) {
                erc20.transfer(address(msg.sender), pendingAmount);
            }
            delete user.tokenids;
        }
        user.lastRewardTime = block.timestamp;
        poolInfo.totalStaked -= _amount;
        emit Withdraw(msg.sender, _amount);
    }
    
    // Emergency withdraw
    function withdrawerc20() public onlyOwner {
        erc20.transfer(address(msg.sender), erc20.balanceOf(address(this)));
    }

    // Set ERC20
    function setToken(address _erc20) public onlyOwner {
        erc20 = IERC20(_erc20);
    }

    // Set NFT Token
    function setFarmToken(address _farm) public onlyOwner {
        farm_token = INFT(_farm);
    }
   
    // View function to see deposited LP for a user.
    function deposited(address _user) external view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_user];
        return user.tokenids;
    }

    // View function to see pending ERC20s for a user.
    function pending(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 endtime = block.timestamp;
        if (endtime <= user.lastRewardTime) {
            return 0;
        }
        uint256 depositTime = block.timestamp - user.lastRewardTime;
        uint256 pendingAmount = user.tokenids.length.mul(depositTime.div(computerPeriod)).mul(poolInfo.allocToken);
        return pendingAmount;
    }

    function balanceLeft() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

        // Compute apy of pool
    function APYPercent() external view returns (uint256) {
        if (poolInfo.totalStaked == 0) {
            return 500000;
        }
        uint256 apy = poolInfo.allocToken.mul(52).mul(1000).div(poolInfo.totalStaked);
        return apy;
    }
}