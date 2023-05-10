/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// File: Recharge/Recharge.sol


pragma solidity >= 0.8.17 < 0.9.0;


interface MyERC  {
    function transferFrom(
        address _from, address _to, uint _value
    ) external;
    function balanceOf(address tokenHolder) external  view returns (uint256);
}
contract Recharge is Ownable
{
    mapping(uint8 => address) private _ReChangeAddress;
    mapping(uint64 => bool) private _PayStatus;
    address public official;
    ReChangeLogs[] private _Logs;

    struct ReChangeLogs
    {
        uint8 Type;
        uint64 OrderId;
        uint64 Amount;
        uint64 Time;
        address Address;
    }
    constructor(address _official)
    {
        setOfficial(_official);
    }
    
    function setOfficial(address  _newOfficial) public onlyOwner {
        official = _newOfficial;
    }

    function SetReChangeAddress(uint8 _type, address erc20Address) external onlyOwner
    {
        require(_type > 0, "id less 1");
        require(erc20Address != address(0), "address error!");
        _ReChangeAddress[_type] = erc20Address;
    }

    function ReChange(uint64 orderId, uint64 amount, uint8 _type) external
    {
        address mContractAddress = _ReChangeAddress[_type];

        require(mContractAddress != address(0), "not set this id");
        require(amount > 0, "amount is to small");
        require(_PayStatus[orderId] == false, "order has been paid");
        
        MyERC mERC20 = MyERC(mContractAddress);

        require(mERC20.balanceOf(msg.sender) >= amount , "Not enough sent");
        mERC20.transferFrom(msg.sender, official , amount);

        _Logs.push(ReChangeLogs(
            {
                Type: _type,
                OrderId: orderId,
                Amount: amount,
                Time:uint64(block.timestamp),
                Address:msg.sender
            }
        ));
         _PayStatus[orderId] = true;
    }
    function GetOrderLength() public view returns(uint256)
    {
        return _Logs.length;
    }
    function GetPayOrderInfo(uint256 index) public view returns(ReChangeLogs memory)
    {
        return _Logs[index];
    }
}