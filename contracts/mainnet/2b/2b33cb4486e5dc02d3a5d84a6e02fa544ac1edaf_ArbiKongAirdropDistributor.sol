/**
 *Submitted for verification at Arbiscan on 2023-04-03
*/

/**

░█████╗░██████╗░██████╗░██╗██╗░░██╗░█████╗░███╗░░██╗░██████╗░
██╔══██╗██╔══██╗██╔══██╗██║██║░██╔╝██╔══██╗████╗░██║██╔════╝░
███████║██████╔╝██████╦╝██║█████═╝░██║░░██║██╔██╗██║██║░░██╗░
██╔══██║██╔══██╗██╔══██╗██║██╔═██╗░██║░░██║██║╚████║██║░░╚██╗
██║░░██║██║░░██║██████╦╝██║██║░╚██╗╚█████╔╝██║░╚███║╚██████╔╝
╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░╚═════╝░

░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░
██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝
██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░
██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░
╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░

██████╗░██╗░██████╗████████╗██████╗░██╗██████╗░██╗░░░██╗████████╗░█████╗░██████╗░
██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗██║██╔══██╗██║░░░██║╚══██╔══╝██╔══██╗██╔══██╗
██║░░██║██║╚█████╗░░░░██║░░░██████╔╝██║██████╦╝██║░░░██║░░░██║░░░██║░░██║██████╔╝
██║░░██║██║░╚═══██╗░░░██║░░░██╔══██╗██║██╔══██╗██║░░░██║░░░██║░░░██║░░██║██╔══██╗
██████╔╝██║██████╔╝░░░██║░░░██║░░██║██║██████╦╝╚██████╔╝░░░██║░░░╚█████╔╝██║░░██║
╚═════╝░╚═╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝╚═════╝░░╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;


interface IERC20Upgradeable {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;


interface IERC20PermitUpgradeable {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;


    function nonces(address owner) external view returns (uint256);


    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity ^0.8.0;


interface IVotesUpgradeable {

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);


    function getVotes(address account) external view returns (uint256);


    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

 
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);


    function delegates(address account) external view returns (address);


    function delegate(address delegatee) external;


    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity 0.8.16;




function uncheckedInc(uint256 x) pure returns (uint256) {
    unchecked {
        return x + 1;
    }
}


interface IERC20VotesUpgradeable is
    IVotesUpgradeable,
    IERC20Upgradeable,
    IERC20PermitUpgradeable
{}

pragma solidity 0.8.16;

contract ArbiKongAirdropDistributor is Ownable {

    IERC20VotesUpgradeable public immutable token;

    address payable public sweepReceiver;

    mapping(address => uint256) public claimableTokens;

    uint256 public totalClaimable;

    uint256 public immutable claimPeriodStart;

    uint256 public immutable claimPeriodEnd;


    event CanClaim(address indexed recipient, uint256 amount);

    event HasClaimed(address indexed recipient, uint256 amount);

    event Swept(uint256 amount);

    event SweepReceiverSet(address indexed newSweepReceiver);

    event Withdrawal(address indexed recipient, uint256 amount);

    constructor(
        IERC20VotesUpgradeable _token,
        address payable _sweepReceiver,
        address _owner,
        uint256 _claimPeriodStart,
        uint256 _claimPeriodEnd
    ) Ownable() {
        require(address(_token) != address(0), "TokenDistributor: zero token address");
        require(_sweepReceiver != address(0), "TokenDistributor: zero sweep address");
        require(_owner != address(0), "TokenDistributor: zero owner address");
        require(_claimPeriodEnd > _claimPeriodStart, "TokenDistributor: start should be before end");



        token = _token;
        _setSweepReciever(_sweepReceiver);
        claimPeriodStart = _claimPeriodStart;
        claimPeriodEnd = _claimPeriodEnd;
        _transferOwnership(_owner);
    }

    function setSweepReciever(address payable _sweepReceiver) external onlyOwner {
        _setSweepReciever(_sweepReceiver);
    }

    function _setSweepReciever(address payable _sweepReceiver) internal {
        require(_sweepReceiver != address(0), "TokenDistributor: zero sweep receiver address");
        sweepReceiver = _sweepReceiver;
        emit SweepReceiverSet(_sweepReceiver);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount), "TokenDistributor: fail transfer token");
        emit Withdrawal(msg.sender, amount);
    }

    function setRecipients(address[] calldata _recipients, uint256[] calldata _claimableAmount)
        external
        onlyOwner
    {
        require(
            _recipients.length == _claimableAmount.length, "TokenDistributor: invalid array length"
        );
        uint256 sum = totalClaimable;
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(claimableTokens[_recipients[i]] == 0, "TokenDistributor: recipient already set");
            claimableTokens[_recipients[i]] = _claimableAmount[i];
            emit CanClaim(_recipients[i], _claimableAmount[i]);
            unchecked {
                sum += _claimableAmount[i];
            }
        }


        require(token.balanceOf(address(this)) >= sum, "TokenDistributor: not enough balance");
        totalClaimable = sum;
    }


    function sweep() external {
        require(block.number >= claimPeriodEnd, "TokenDistributor: not ended");
        uint256 leftovers = token.balanceOf(address(this));
        require(leftovers != 0, "TokenDistributor: no leftovers");

        require(token.transfer(sweepReceiver, leftovers), "TokenDistributor: fail token transfer");

        emit Swept(leftovers);

        selfdestruct(payable(sweepReceiver));
    }


    function claim() public {
        require(block.number >= claimPeriodStart, "TokenDistributor: claim not started");
        require(block.number < claimPeriodEnd, "TokenDistributor: claim ended");

        uint256 amount = claimableTokens[msg.sender];
        require(amount > 0, "TokenDistributor: nothing to claim");

        claimableTokens[msg.sender] = 0;

        require(token.transfer(msg.sender, amount), "TokenDistributor: fail token transfer");
        emit HasClaimed(msg.sender, amount);
    }
}