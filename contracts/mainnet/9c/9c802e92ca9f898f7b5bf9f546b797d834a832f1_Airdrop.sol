/**
 *Submitted for verification at Arbiscan on 2023-06-28
*/

//SPDX-License-Identifier: MIT

pragma  solidity  =0.8.19;
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }   
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Airdrop is Ownable{

    struct user{
        bool share;
        bool threeReward;
        bool fiveReward;
        uint256 balance;     
        uint256 payoutBalance;
        uint256 team;
        address uplineAddr;
    }

    address public acceptAddr;    
    uint256 public shareBonus = 0.001 ether;
    uint256 public meBonus = 100 * 1e8 * 1e18;
    uint256 public bonus = 5 * 1e8 * 1e18;
    uint256 public additionalAmount = 500 * 1e8 * 1e18;
    uint256 public peopleMaxNum = 0;
    address public MonsterToken = 0xFB2289d2B1f9809E015e7854A69FEBf0D7652068;

    mapping(address => user) public users;

    event Additional(address addr,uint256 value);
    event Share(address addr,uint256 meBonus);
    event Withdrawal(address,uint256);    

    receive() external payable{}

    constructor(address ACCEPTADDR)
    {
        acceptAddr = ACCEPTADDR;
        users[owner()].share = true;
    }

    function share(address UPADDR)
    public payable
    {        
        require(peopleMaxNum < 60000,"people Max 60000");
        require(users[_msgSender()].share == false,"recommend once");
        require(_msgSender() != owner(),"not the owner");
        require(msg.value >= shareBonus,"lt shareBonus");
        payable(acceptAddr).transfer(shareBonus);
        users[_msgSender()].share = true;
        require(safeTransfer(MonsterToken,_msgSender(),meBonus),"Transfer err");
        peopleMaxNum ++;
        if(UPADDR != address(0)){
            _bindUpline(UPADDR);
        }
        emit Share(_msgSender(),meBonus);
    }

    function _bindUpline(address _upline)
    private 
    {
        require(_msgSender() != _upline,"it cannot be oneself");
        require(users[_msgSender()].uplineAddr == address(0) ,"your have upline");
        if(_upline != owner())
        {
            users[_upline].team ++;
            users[_upline].balance += bonus;
            if(users[_upline].team == 30) 
            {               
                users[_upline].threeReward = true;
                _additional(_upline,additionalAmount);               
            }
            else if(users[_upline].team == 50)
            {                
                users[_upline].fiveReward = true;
                _additional(_upline,additionalAmount);              
            }
            users[_msgSender()].uplineAddr = _upline;
        }        
    }

    function _additional(address _addr,uint256 _amount)
    private
    {
        users[_addr].balance += _amount;
        emit Additional(_addr,_amount);
    }      

    function withdrawal(uint256 AMOUNT)
    external 
    {
        require(users[_msgSender()].share,"you not activation");
        require(users[_msgSender()].balance  >= AMOUNT,"wd lt balance");
        require(safeTransfer(MonsterToken,_msgSender(),AMOUNT),"Transfer err");
        users[_msgSender()].balance -= AMOUNT;
        users[_msgSender()].payoutBalance += AMOUNT;
        emit Withdrawal(_msgSender(),AMOUNT);
    }    

    function claimETH(uint256 amount) 
    external  onlyOwner
    {
        (bool success, bytes memory data) = acceptAddr.call{value : amount}(new bytes(0));
        if (success && data.length > 0) {}
    }

    function claimERC20(uint256 amount) 
    external  onlyOwner
    {
       safeTransfer(MonsterToken,acceptAddr,amount);
    }

    function safeTransfer(address token, address to, uint value) 
    internal  returns(bool variable)
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (success && data.length > 0) return true;
    }    

    function selectUserInfo()
    public view  returns(bool,uint256,uint256,address)
    {
        return (users[_msgSender()].share,
        users[_msgSender()].balance,users[_msgSender()].team,users[_msgSender()].uplineAddr);
    }


}