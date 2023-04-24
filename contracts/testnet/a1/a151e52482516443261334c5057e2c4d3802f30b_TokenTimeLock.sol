/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity >=0.6.0;


library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
  
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

  
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferWithoutDeflationary(address recipient, uint256 amount) external returns (bool) ;
   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract TokenTimeLock {
    using SafeMath for uint256;
    IERC20 private _aibb;
    event TokensReleased(address beneficiary, uint256 amount);
    address payable private owner;
    // beneficiary of tokens after they are released
    string public name = "BullBear AI: Token Vesting";

    struct Vesting {
        
        address Beneficiary;
        uint256 Cliff;
        uint256 Start;
        uint256 AmountReleaseInOne;
        uint256 MaxRelease;
        bool IsExist;
    }
    mapping(address => Vesting) private _vestingList;

    constructor(
        address aibb
       
    ) public {
       
        _aibb = IERC20(aibb);
    
        owner = msg.sender;
    }

    function depositETHtoContract() public payable {}

    function addLockingFund(
        address beneficiary,
        uint256 cliff,
        uint256 start,
        uint256 amountReleaseInOne,
        uint256 maxRelease
    ) public {
        require(msg.sender == owner, "only owner can addLockingFund");
       
        _vestingList[beneficiary].Beneficiary = beneficiary;
        _vestingList[beneficiary].Cliff = cliff;
        _vestingList[beneficiary].Start = start;
        _vestingList[beneficiary].AmountReleaseInOne = amountReleaseInOne;
        _vestingList[beneficiary].MaxRelease = maxRelease;
        _vestingList[beneficiary].IsExist = true;
    }

    function beneficiary(address acc) public view returns (address) {
        return _vestingList[acc].Beneficiary;
    }

    function cliff(address acc) public view returns (uint256) {
        return _vestingList[acc].Cliff;
    }

    function start(address acc) public view returns (uint256) {
        return _vestingList[acc].Start;
    }

    function amountReleaseInOne(address acc) public view returns (uint256) {
        return _vestingList[acc].AmountReleaseInOne;
    }

    function getNumberCycle(address acc) public view returns (uint256) {
        return
            (block.timestamp.sub(_vestingList[acc].Start)).div(
                _vestingList[acc].Cliff
            );
    }

    function getRemainBalance() public view returns (uint256) {
        return _aibb.balanceOf(address(this));
    }

    function getRemainUnlockAmount(address acc) public view returns (uint256) {
        return _vestingList[acc].MaxRelease;
    }

    function isValidBeneficiary(address _wallet) public view returns (bool) {
        return _vestingList[_wallet].IsExist;
    }

    function release(address acc) public {
        require(acc != address(0), "TokenRelease: address 0 not allow");
        require(
            isValidBeneficiary(acc),
            "TokenRelease: invalid release address"
        );

        require(
            _vestingList[acc].MaxRelease > 0,
            "TokenRelease: no more token to release"
        );

        uint256 unreleased = _releasableAmount(acc);

        require(unreleased > 0, "TokenRelease: no tokens are due");

        _aibb.transfer(_vestingList[acc].Beneficiary, unreleased);
        _vestingList[acc].MaxRelease -= unreleased;

        emit TokensReleased(_vestingList[acc].Beneficiary, unreleased);
    }

    function _releasableAmount(address acc) private returns (uint256) {
        uint256 currentBalance = _aibb.balanceOf(address(this));
        if (currentBalance <= 0) return 0;
        uint256 amountRelease = 0;
       
        if (
            _vestingList[acc].Start.add(_vestingList[acc].Cliff) >
            block.timestamp
        ) {
            //not on time

            amountRelease = 0;
        } else {
            uint256 numberCycle = getNumberCycle(acc);
            if (numberCycle > 0) {
                amountRelease =
                    numberCycle *
                    _vestingList[acc].AmountReleaseInOne;
            } else {
                amountRelease = 0;
            }

            _vestingList[acc].Start = block.timestamp; //update start
        }
        return amountRelease;
    }

    function withdrawEtherFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }
}