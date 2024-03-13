/**
 *Submitted for verification at Arbiscan.io on 2024-03-11
*/

// File: @gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol


// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.1;

/**
 * @dev Context variant with ERC2771 support.
 */
// based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
abstract contract ERC2771Context {
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// File: lib/SafeMath.sol


pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: lib/Ownable.sol


pragma solidity ^0.8.0;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: UmiversePaymentV2.sol


pragma solidity ^0.8.0;





contract UmiversePaymentV2 is ERC2771Context {
    using SafeMath for uint256;

    address public owner;
    address public signerAddress;

    uint256 public presaleFeeToDeveloper = 490;
    uint256 public presaleFeeToUmi = 210;
    uint256 public presaleFeeToRewardFund = 300;

    address public feeAddress; // umi
    address public rewardPoolAddress; //reward pool

    IERC20 public usdt = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 public usdc = IERC20(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);
    IERC20 public umi = IERC20(address(0));
    IERC20 public eth = IERC20(address(0));

    event PaymentSent(
        address indexed recipient,
        uint256 orderId,
        uint256 amount,
        string _priceType,
        bytes _signature
    );
    event TokensWithdrawn(uint256 amount);

    struct Order {
        address recipient;
        uint256 orderId;
        uint256 amount;
        string _priceType;
        uint256 timestamp;
    }

    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId = 1;

    constructor(
        address trustedForwarder,
        address _rewardPoolAddress,
        address _feeAddress,
        address _signerAddress
    ) ERC2771Context(trustedForwarder) {
        owner = msg.sender;
        rewardPoolAddress = _rewardPoolAddress;
        feeAddress = _feeAddress;
        signerAddress = _signerAddress;
    }

    modifier onlyTrustedForwarder() {
        require(
            isTrustedForwarder(msg.sender),
            "Only callable by Trusted Forwarder"
        );
        _;
    }

    // config
    function setFee(
        uint256 _presaleFeeToDeveloper,
        uint256 _presaleFeeToUmi,
        uint256 _presaleFeeToRewardFund
    ) public onlyOwner {
        presaleFeeToDeveloper = _presaleFeeToDeveloper;
        presaleFeeToUmi = _presaleFeeToUmi;
        presaleFeeToRewardFund = _presaleFeeToRewardFund;
    }

    function setUsdt(address _usdt) public onlyOwner {
        usdt = IERC20(_usdt);
    }

    function setUsdc(address _usdc) public onlyOwner {
        usdc = IERC20(_usdc);
    }

    function setUmi(address _umi) public onlyOwner {
        umi = IERC20(_umi);
    }

    function setEth(address _eth) public onlyOwner {
        eth = IERC20(_eth);
    }

    // config
    function config(
        address _feeAddress,
        address _rewardPoolAddress,
        address _signerAddress
    ) public onlyOwner {
        feeAddress = _feeAddress;
        rewardPoolAddress = _rewardPoolAddress;
        signerAddress = _signerAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function sendPayment(
        address from,
        address recipient,
        uint256 orderId,
        uint256 amount,
        string memory _priceType,
        uint256 _timestamp,
        bytes memory _signature
    ) external onlyTrustedForwarder {
        require(amount > 0, "Invalid amount");
        require(from != address(0), "CV: from to the zero address");
        require(
            verify(
                from,
                recipient,
                orderId,
                amount,
                _priceType,
                _timestamp,
                _signature
            ),
            "CV: invalid _signature"
        );

        IERC20 sendToken;
        if (amount > 0) {
            if (compareStrings(_priceType, "usdt")) {
                require(address(usdt) != address(0), "usdt address not config");
                sendToken = usdt;
            }
            if (compareStrings(_priceType, "usdc")) {
                require(address(usdc) != address(0), "usdc address not config");
                sendToken = usdc;
            }

            if (compareStrings(_priceType, "eth")) {
                require(address(eth) != address(0), "eth address not config");
                sendToken = eth;
            }

            if (compareStrings(_priceType, "umi")) {
                require(address(umi) != address(0), "umi address not config");
                sendToken = umi;
            }
            processTrade(sendToken, from, recipient, amount);
        }

        orders[orderId] = Order(
            recipient,
            orderId,
            amount,
            _priceType,
            _timestamp
        );
        nextOrderId += 1;

        emit PaymentSent(recipient, orderId, amount, _priceType, _signature);
    }

    function withdrawTokens(IERC20 token, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        require(token.transfer(owner, amount), "Token transfer failed");
        emit TokensWithdrawn(amount);
    }

    function processTrade(
        IERC20 token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        uint256 toDeveloper = 0;
        uint256 toUmi = 0;
        uint256 toRewardFund = 0;
        token.transferFrom(sender, address(this), amount);
        toDeveloper = amount.mul(presaleFeeToDeveloper).div(1000);
        toUmi = amount.mul(presaleFeeToUmi).div(1000);
        toRewardFund = amount.mul(presaleFeeToRewardFund).div(1000);

        uint256 toSeller = amount - toDeveloper - toUmi - toRewardFund;

        if (toDeveloper > 0) {
            token.transfer(receiver, toDeveloper);
        }

        if (toUmi > 0) {
            token.transfer(feeAddress, toUmi);
        }

        if (toRewardFund > 0) {
            token.transfer(rewardPoolAddress, toRewardFund);
        }

        if (toSeller > 0) {
            token.transfer(receiver, toSeller);
        }
    }

    // signer
    function getMessageHash(
        address _from,
        address _recipient,
        uint256 _orderId,
        uint256 _amount,
        string memory priceType,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _from,
                    _recipient,
                    _orderId,
                    _amount,
                    priceType,
                    _timestamp
                )
            );
    }

    //verify(_buyer, _seller, _tokenid, _price, _amount, _timestamp, _signature
    function verify(
        address _from,
        address _recipient,
        uint256 _orderId,
        uint256 _amount,
        string memory priceType,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _from,
            _recipient,
            _orderId,
            _amount,
            priceType,
            _timestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signerAddress;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function recoverSignerPublic(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function isTokenSupported(string memory token) public pure returns (bool) {
        return (compareStrings(token, "usdt") ||
            compareStrings(token, "usdc") ||
            compareStrings(token, "umi") ||
            compareStrings(token, "divepoint") ||
            compareStrings(token, "eth"));
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(b)));
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}