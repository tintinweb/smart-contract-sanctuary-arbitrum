/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract LubgAirdrop {
    uint256 public lastRecordTime;
    address public highestMultiplierAddr;
    uint256 public highestMultiplier;
    uint256 public totalnum;
    IERC20 public token;
    address public  _owner;
     mapping (address => uint256) public callCount;
    struct AddressInfo {
        address info;
        uint256 count;
    }

    AddressInfo[] public addressList;
    event Transfer(address indexed from,  uint256 value);

     /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    constructor(address token_) {
      token = IERC20(token_);
      _owner=msg.sender;
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }


    function isValidSignature(bytes32 message, bytes memory signature) public pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        address signer=0x895cF3F03d7C92Da11f317A8246890928f90eE99;
        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return false;
        } else {
            return ecrecover(message, v, r, s) == signer;
        }
    }
   
    function mint(bytes memory signature) public payable {
        bytes32 message = keccak256(abi.encode(address(this), msg.sender));
        require(isValidSignature(message,signature), "SignatureChecker: Invalid signature");
        require(callCount[msg.sender] < 6, "You have exceeded the maximum number of calls.");
         require(callCount[msg.sender] < 1|| msg.value >= 0.005 ether, "You have exceeded the maximum number of calls.");
        callCount[msg.sender]++;
    uint256 amount = 330000000000000 * 10 ** 18;
    uint256 extraAmount = 0;
    uint256 multiplier=0;
    if (msg.value >= 0.005 ether) {
        bytes32 blockHash = blockhash(block.number - 1);
        uint256 timestamp = block.timestamp;
        uint256 blockNumber = block.number;
        bytes32 transactionData = keccak256(abi.encodePacked(msg.data));
        bytes32 combinedData = keccak256(abi.encodePacked(blockHash, timestamp, blockNumber, transactionData));
        uint256 randomNumber = uint256(combinedData) % 20 + 1;
        multiplier=randomNumber;
        extraAmount = amount * randomNumber;
        amount += extraAmount;
    }
    emit Transfer(msg.sender,amount);
    token.transfer(msg.sender, amount);
    if (block.timestamp > lastRecordTime + 1 hours) {
        if(highestMultiplierAddr != address(0)){
             totalnum =totalnum * 5 / 100;
             addressList.push(AddressInfo(highestMultiplierAddr, totalnum));
            token.transfer(highestMultiplierAddr, totalnum);
            }
            totalnum=0;
            totalnum+=amount;
            highestMultiplierAddr = msg.sender;
            highestMultiplier = multiplier;
            lastRecordTime = block.timestamp;
            } else {
                totalnum+=amount;
                if (multiplier >= highestMultiplier) {
                highestMultiplierAddr = msg.sender;
                highestMultiplier = multiplier;
                }
            }
}
function withdraw() external onlyOwner {
    (bool success, ) = _owner.call{value: address(this).balance}("");
    require(success, "Withdraw failed");
}
 function getAllAddressInfo() public view returns (AddressInfo[] memory) {
        return addressList;
    }


}