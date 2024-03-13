/**
 *Submitted for verification at Arbiscan.io on 2024-03-09
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// File: lib/Strings.sol


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}
// File: lib/IWETH.sol


pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external payable;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}
// File: lib/Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: lib/Pausable.sol


pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// File: UmiverseMarket.sol


pragma solidity ^0.8.0;









contract UmiverseMarket is Ownable, ERC2771Context {
    using SafeMath for uint256;
    using Strings for uint256;

    event Buy(uint256 gold, uint256 price, address buyer, address seller);
    event Sell(uint256 gold, uint256 price, address seller, address buyer);

    address public admin;
    address public feeAddress; // umi
    address public rewardPoolAddress; //reward pool
    address public signerAddress; // get from backend private key

    // okbc testnet
    IERC20 public usdt = IERC20(0x0E9bB892A38d60B53085Af77eda888790Ef1DD33);
    IERC20 public usdc = IERC20(0x7FC5e3e61700E34218a00cC01E92957A4e6C8883);
    IERC20 public umi = IERC20(address(0));
    IERC20 public eth = IERC20(address(0));

    uint256 public presaleFeeToDeveloper = 490;
    uint256 public presaleFeeToUmi = 210;
    uint256 public presaleFeeToRewardFund = 300;

    uint256 public tradeFeeToUmi = 10;
    uint256 public tradeFeeToDeveloper = 10;
    uint256 public tradeFeeToRewardFund = 5;

    constructor(
        address trustedForwarder,
        address _admin,
        address _feeAddress,
        address _signerAddress,
        address _rewardPoolAddess
    ) ERC2771Context(trustedForwarder) {
        admin = _admin;
        feeAddress = _feeAddress;
        signerAddress = _signerAddress;
        rewardPoolAddress = _rewardPoolAddess;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlySigner() {
        require(msg.sender == signerAddress);
        _;
    }

    modifier onlyTrustedForwarder() {
        require(
            isTrustedForwarder(msg.sender),
            "Only callable by Trusted Forwarder"
        );
        _;
    }

    function setAdmin(address _address) public onlyOwner {
        admin = _address;
    }

    function setFee(
        uint256 _presaleFeeToDeveloper,
        uint256 _presaleFeeToUmi,
        uint256 _presaleFeeToRewardFund,
        uint256 _tradeFeeToUmi,
        uint256 _tradeFeeToDeveloper,
        uint256 _tradeFeeToRewardFund
    ) public onlyOwner {
        presaleFeeToDeveloper = _presaleFeeToDeveloper;
        presaleFeeToUmi = _presaleFeeToUmi;
        presaleFeeToRewardFund = _presaleFeeToRewardFund;
        tradeFeeToUmi = _tradeFeeToUmi;
        tradeFeeToDeveloper = _tradeFeeToDeveloper;
        tradeFeeToRewardFund = _tradeFeeToRewardFund;
    }

    function setUsdt(address _usdt) public onlyAdmin {
        usdt = IERC20(_usdt);
    }

    function setUsdc(address _usdc) public onlyAdmin {
        usdc = IERC20(_usdc);
    }

    function setUmi(address _umi) public onlyAdmin {
        umi = IERC20(_umi);
    }

    function setEth(address _eth) public onlyAdmin {
        eth = IERC20(_eth);
    }

    function setFeeAddress(address _address) public onlyAdmin {
        feeAddress = _address;
    }

    function setSignerAddress(address _address) public onlyAdmin {
        signerAddress = _address;
    }

    function setRewardPoolAddress(address _rewardPoolAddress) public onlyAdmin {
        rewardPoolAddress = _rewardPoolAddress;
    }

    function getMessageHash(
        address _buyer,
        address _seller,
        uint256 _tokenid,
        uint256 _price,
        uint256 _amount,
        string memory _priceType,
        address _developerAddress,
        bool _presale,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        require(isTokenSupported(_priceType), "token not support");
        return
            keccak256(
                abi.encodePacked(
                    _buyer,
                    _seller,
                    _tokenid,
                    _price,
                    _amount,
                    _priceType,
                    _developerAddress,
                    _presale,
                    _timestamp
                )
            );
    }

    //verify(_buyer, _seller, _tokenid, _price, _amount, _timestamp, _signature
    function verify(
        address _buyer,
        address _seller,
        uint256 _tokenid,
        uint256 _price,
        uint256 _amount,
        string memory _priceType,
        address _developerAddress,
        bool _presale,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        require(isTokenSupported(_priceType), "token not support");
        bytes32 messageHash = getMessageHash(
            _buyer,
            _seller,
            _tokenid,
            _price,
            _amount,
            _priceType,
            _developerAddress,
            _presale,
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

    function processTrade(
        IERC20 token,
        address buyer,
        address seller,
        address _developer,
        bool presale,
        uint256 amount
    ) internal {
        uint256 toDeveloper = 0;
        uint256 toUmi = 0;
        uint256 toRewardFund = 0;


        token.transferFrom(buyer, address(this), amount);

        if (presale) {
            toDeveloper = amount.mul(presaleFeeToDeveloper).div(1000);
            toUmi = amount.mul(presaleFeeToUmi).div(1000);
            toRewardFund = amount.mul(presaleFeeToRewardFund).div(1000);
        } else {
            toDeveloper = amount.mul(tradeFeeToDeveloper).div(1000);
            toUmi = amount.mul(tradeFeeToUmi).div(1000);
            toRewardFund = amount.mul(tradeFeeToRewardFund).div(1000);
        }

        uint256 toSeller = amount - toDeveloper - toUmi - toRewardFund;

        if (toDeveloper > 0) {
            token.transfer(_developer, toDeveloper);
        }

        if (toUmi > 0) {
            token.transfer(feeAddress, toUmi);
        }

        if (toRewardFund > 0) {
            token.transfer(rewardPoolAddress, toRewardFund);
        }

        if (toSeller > 0) {
            token.transfer(seller, toSeller);
        }
    }

    function buy(
        IERC721 nft,
        address _buyer,
        uint256 _tokenid,
        uint256 _price,
        uint256 _amount,
        string memory _priceType,
        address _developerAddress,
        bool _presale,
        uint256 _timestamp,
        address _seller,
        bytes memory _signature
    ) external onlyTrustedForwarder {
        require(_buyer != address(0), "CV: buyer to the zero address");
        require(
            verify(
                _buyer,
                _seller,
                _tokenid,
                _price,
                _amount,
                _priceType,
                _developerAddress,
                _presale,
                _timestamp,
                _signature
            ),
            "CV: invalid _signature"
        );
        require(_price == _amount, "CV: invalid amount");

        // buy with usdt/usdc/umi/eth
        if (_amount > 0) {
            if (compareStrings(_priceType, "usdt")) {
                require(address(usdt) != address(0), "usdt address not config");
                processTrade(
                    usdt,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }

            if (compareStrings(_priceType, "usdc")) {
                require(address(usdc) != address(0), "usdc address not config");
                processTrade(
                    usdc,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }

            if (compareStrings(_priceType, "eth")) {
                require(address(eth) != address(0), "eth address not config");
                processTrade(
                    eth,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }

            if (compareStrings(_priceType, "umi")) {
                require(address(umi) != address(0), "umi address not config");
                processTrade(
                    umi,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }
        }

        bytes memory _data;

        require(
            nft.isApprovedForAll(_seller, address(this)),
            "CV: seller is not approved"
        );
        nft.safeTransferFrom(_seller, _buyer, _tokenid, _data);
        emit Buy(_tokenid * 1e8, _price, _buyer, _seller);
    }

    function sell(
        IERC721 nft,
        address _seller,
        uint256 _tokenid,
        uint256 _price,
        uint256 _amount,
        string memory _priceType,
        address _developerAddress,
        bool _presale,
        uint256 _timestamp,
        address _buyer,
        bytes memory _signature
    ) external onlyTrustedForwarder {
        require(_buyer != address(0), "CV: buyer to the zero address");
        require(
            verify(
                _buyer,
                _seller,
                _tokenid,
                _price,
                _amount,
                _priceType,
                _developerAddress,
                _presale,
                _timestamp,
                _signature
            ),
            "CV: invalid _signature"
        );
        require(_price == _amount, "CV: invalid amount");

        if (_amount > 0) {
            if (compareStrings(_priceType, "usdt")) {
                require(address(usdt) != address(0), "usdt address not config");
                processTrade(
                    usdt,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }

            if (compareStrings(_priceType, "usdc")) {
                require(address(usdc) != address(0), "usdc address not config");
                processTrade(
                    usdc,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }

            if (compareStrings(_priceType, "eth")) {
                require(address(usdt) != address(0), "eth address not config");
                processTrade(
                    eth,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }

            if (compareStrings(_priceType, "umi")) {
                require(address(umi) != address(0), "umi address not config");
                processTrade(
                    umi,
                    _buyer,
                    _seller,
                    _developerAddress,
                    _presale,
                    _amount
                );
            }
        }

        bytes memory _data;

        nft.safeTransferFrom(_seller, _buyer, _tokenid, _data);
        emit Sell(_tokenid * 1e8, _price, _seller, _buyer);
    }
}