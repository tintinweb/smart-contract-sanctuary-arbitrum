// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";


interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenids(address addr) external view returns (uint256[] memory);
}

// Farm distributes the ERC20 rewards based on nft to each user.
//
// Modified by ERC20 to work for non-mintable.
contract DigerFarm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256[] tokenids;     // How many tokens the user has provided.
        uint256 lastRewardTime; 
        uint256 lastRewardToken; 
        uint256 totalClaimed;
        bool    staking;
    }

    // Info of lp pool.
    struct PoolInfo {
        uint256 allocToken;         // How many reward tokens per-period, ERC20s to distribute per block.
        // uint256 lastRewardTime;    // Last block number that ERC20s distribution occurs.
        uint256 totalStaked;

    }
    
    uint256 public computerPeriod;
    uint256 public deRate;
    uint256 public startTime;
    uint256 public updateTime;
    uint256 public currentToken;
    bool    public initialed;
    bool    public open; 
    address public owner;

    // Address of the ERC20 Token contract.
    IERC20  public erc20;
    // Address of the LP ERC20 Token contract.
    INFT    public farm_token;
    // Info of pool.
    PoolInfo public poolInfo;

    mapping (uint256 => address) public depositInfo;
    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function initdata() public {
        require(initialed == false, "already init");
        computerPeriod = 30 minutes;
        deRate = 30;
        poolInfo = PoolInfo({
                allocToken: 1000000 * 10**18,
                totalStaked: 0
            });
        currentToken = poolInfo.allocToken;
        owner = msg.sender;
        initialed = true;
    }

    modifier Open() {
        require(open, "not open");
        _;
    }

    function setDigAmount(uint256 _amount) public onlyOwner {
        poolInfo.allocToken = _amount;
    }

    function setComputerPeriod (uint256 _value) public onlyOwner {
        computerPeriod = _value;
    }

    function setDeRate(uint256 _rate) public onlyOwner {
        deRate = _rate;
    }

    function toggleOpen() public onlyOwner {
        open = !open;
    }

    function start() public onlyOwner {
        open = true;
        startTime = block.timestamp;
        updateTime = startTime;
    }

    // stake tokens to Farm for ERC20 allocation.
    function stake() public Open {
        updateCurrentToken();
        UserInfo storage user = userInfo[msg.sender];
        require(user.staking == false, "Already Staking");
        payToken();

        uint256[] memory tokenids = farm_token.tokenids(msg.sender);
        for (uint i = 0; i < tokenids.length; i++) {
            require(farm_token.ownerOf(tokenids[i]) == msg.sender, "Not NFT Owner");
            // farm_token.safeTransferFrom(address(msg.sender), address(this), _tokenIDs[i]);
            depositInfo[tokenids[i]] = msg.sender;
            user.tokenids = tokenids;
        }
        user.staking = true;
        user.lastRewardTime = block.timestamp;
        user.lastRewardToken = currentToken;
        poolInfo.totalStaked += tokenids.length;
        emit Deposit(msg.sender, tokenids.length);
    }

    /**
     * unStake 
     */
    function unStake() public {
        updateCurrentToken();
        UserInfo storage user = userInfo[msg.sender];
        require(user.staking == true, "No Staking");
        uint256 amounts = user.tokenids.length;
        payToken(); 
        delete user.tokenids;
        user.staking = false;
        user.lastRewardTime = block.timestamp;
        poolInfo.totalStaked -= amounts;
        emit Withdraw(msg.sender, amounts);
    }

    function payToken() internal {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amounts = user.tokenids.length;
        for (uint i = 0; i < amounts; i++) {
            require(depositInfo[user.tokenids[i]] == msg.sender, "Not NFT Owner");
        }
        if (amounts > 0) {
            uint256 pendingAmount = _pending(msg.sender);
            if (pendingAmount > 0) {
                erc20.transfer(address(msg.sender), pendingAmount);
                user.totalClaimed += pendingAmount;
            }
        }
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
    function _pending(address _user) internal view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 endtime = block.timestamp;
        if (endtime <= user.lastRewardTime) {
            return 0;
        }
        uint256 depositTime = block.timestamp - user.lastRewardTime;
        uint256 avarageToken = user.lastRewardToken.add(currentToken).div(2);
        uint256 pendingAmount = user.tokenids.length.mul(depositTime.div(computerPeriod)).mul(avarageToken);
        return pendingAmount;
    }

    // View function to see pending ERC20s for a user.
    function pending(address _user) public view returns (uint256) {
        uint256 cToken = computerCurrentToken();
        
        UserInfo storage user = userInfo[_user];
        uint256 endtime = block.timestamp;
        if (endtime <= user.lastRewardTime) {
            return 0;
        }
        uint256 depositTime = block.timestamp - user.lastRewardTime;
        uint256 avarageToken = user.lastRewardToken.add(cToken).div(2);
        uint256 pendingAmount = user.tokenids.length.mul(depositTime.div(computerPeriod)).mul(avarageToken);
        return pendingAmount;
    }

    function computerCurrentToken() public view returns (uint256) {
        uint256 cToken = currentToken;
        if (block.timestamp - startTime > computerPeriod * 2) {
            uint256 offset = block.timestamp - updateTime;
            if (offset > computerPeriod) {
                cToken = currentToken.mul(100 - deRate).div(100);
            }
        }
        return cToken;
    }

    function updateCurrentToken() public {
        if (block.timestamp - startTime < computerPeriod * 2) {
            return;
        }

        uint256 offset = block.timestamp - updateTime;
        if (offset > computerPeriod) {
            updateTime = block.timestamp;
            currentToken = currentToken.mul(100 - deRate).div(100);
        }
    }

    function balanceLeft() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

}