// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {AddressArrayUtils} from "./AddressArrayUtils.sol";

contract CCIPTokenTransfer {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector);

    event ChainWhitelisted(uint64 indexed destinationChainSelector);
    event TokensTransferred(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        address feeToken,
        uint256 fees
    );
    event OwnerUpdated(address indexed newOwner);

    // Mapping to track allowed destination chains
    mapping(uint64 => bool) public whitelistedChains;

    // Instance of CCIP Router
    IRouterClient public router;
    // LINK fee token
    IERC20 public LINK;

    // The address with administrative privileges over this contract
    address public owner;

    /// @dev Modifier that checks if the chain with the given destinationChainSelector is whitelisted
    /// @param _destinationChainSelector The selector of the destination chain
    modifier onlyWhitelistedChain(uint64 _destinationChainSelector) {
        if (!whitelistedChains[_destinationChainSelector]) {
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
        }
        _;
    }

    /// @dev Modifier that checks whether the msg.sender is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Constructor initializes the contract with the router address
    /// @param _router The address of the router contract
    /// @param _link The address of the link contract
    constructor(address _router, address _link, address _owner) {
        router = IRouterClient(_router);
        LINK = IERC20(_link);
        owner = _owner;
    }

    function _previewFee(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeToken
    ) internal view returns (uint256) {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, _feeToken);
        return router.getFee(_destinationChainSelector, evm2AnyMessage);
    }

    function _maxApproveLink() internal {
        if (LINK.allowance(owner, address(router)) == 0) {
            LINK.approve(address(router), type(uint256).max);
        }
    }

    function _maxApproveToken(address _token) internal {
        if (IERC20(_token).allowance(owner, address(router)) == 0) {
            IERC20(_token).approve(address(router), type(uint256).max);
        }
    }

    /// @notice Find all tokens from input address array that are supported on destination chain
    /// @param _chainSelector The identifier for destination blockchain
    /// @param _tokens array of token addresses
    /// @return filteredTokens Address array of tokens that are supported
    function filterSupportedTokens(uint64 _chainSelector, address[] memory _tokens)
        public
        view
        returns (address[] memory)
    {
        address[] memory supportedTokens = router.getSupportedTokens(_chainSelector);
        return AddressArrayUtils.intersect(supportedTokens, _tokens);
    }

    /// @notice Test whether a specific token is valid on destination chain
    /// @param _chainSelector The identifier for destination blockchain
    /// @param _token token address
    /// @return isSupported Boolean indicating whether token is supported
    function tokenIsValid(uint64 _chainSelector, address _token) external view returns (bool isSupported) {
        address[] memory tokenArray = new address[](1);
        tokenArray[0] = _token;
        address[] memory supportedTokens = filterSupportedTokens(_chainSelector, tokenArray);
        return supportedTokens.length == 1;
    }

    /// @notice Estimate fee transfer tokens to destination chain paying LINK as gas
    /// @param _destinationChainSelector The identifier for destination blockchain
    /// @param _receiver The address of the recipient on destination blockchai
    /// @param _token token address
    /// @param _amount token amount
    /// @return fee Amount of LINK token to provide as fee
    function previewFeeLINK(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)
        external
        view
        returns (uint256 fee)
    {
        return _previewFee(_destinationChainSelector, _receiver, _token, _amount, address(LINK));
    }

    /// @notice Estimate fee transfer tokens to destination chain paying in native gas
    /// @param _destinationChainSelector The identifier for destination blockchain
    /// @param _receiver The address of the recipient on destination blockchai
    /// @param _token token address
    /// @param _amount token amount
    /// @return fee Amount of native token to provide as fee
    function previewFeeNative(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)
        external
        view
        returns (uint256 fee)
    {
        return _previewFee(_destinationChainSelector, _receiver, _token, _amount, address(0));
    }

    /// @notice Transfer tokens to receiver on the destination chain
    /// @notice pay in LINK
    /// @notice the token must be in the list of supported tokens
    /// @notice This function can only be called by the owner
    /// @dev Assumes your contract has sufficient LINK tokens to pay for the fees
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain
    /// @param _receiver The address of the recipient on the destination blockchain
    /// @param _token token address
    /// @param _amount token amount
    /// @return messageId The ID of the message that was sent
    function transferTokensPayLINK(uint64 _destinationChainSelector, address _receiver, address _token, uint256 _amount)
        external
        onlyWhitelistedChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
        // Create EVM2AnyMessage with information for sending cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, address(LINK));

        // Get the required fee
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        // Approve the Router to transfer LINK tokens on contract's behalf
        _maxApproveLink();
        // Approve the Router to spend tokens on contract's behalf
        _maxApproveToken(_token);

        // Pull funds to transfer and gas fee from user to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        LINK.transferFrom(msg.sender, address(this), fees);

        // Send the message through the router
        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);
        emit TokensTransferred(messageId, _destinationChainSelector, _receiver, _token, _amount, address(LINK), fees);
        return messageId;
    }

    /// @notice Transfer tokens to receiver on the destination chain
    /// @notice Pay in native gas such as ETH on Ethereum or MATIC on Polgon
    /// @notice the token must be in the list of supported tokens
    /// @dev Assumes your contract has sufficient native gas like ETH on Ethereum or MATIC on Polygon
    /// @param _destinationChainSelector The identifier for destination blockchain
    /// @param _receiver The address of the recipient on destination blockchain
    /// @param _token token address
    /// @param _amount token amount
    /// @return messageId The ID of the message that was sent
    function transferTokensPayNative(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable onlyWhitelistedChain(_destinationChainSelector) returns (bytes32 messageId) {
        // Create EVM2AnyMessage with information for sending cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _token, _amount, address(0));

        // Get the required fee
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);
        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }

        // approve the Router to spend token on contract's behalf
        _maxApproveToken(_token);

        // Pull funds to transfer from user to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Send the message through the router
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);
        emit TokensTransferred(messageId, _destinationChainSelector, _receiver, _token, _amount, address(0), fees);
        return messageId;
    }

    /// @notice Construct a CCIP message
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer
    /// @param _receiver The address of the receiver
    /// @param _token The token to be transferred
    /// @param _amount The amount of the token to be transferred
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message
    function _buildCCIPMessage(address _receiver, address _token, uint256 _amount, address _feeTokenAddress)
        internal
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        // Set the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: _token, amount: _amount});

        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: "", // No data
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit to 0 as we are not sending any data and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 0, strict: false})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
    }

    /// @notice Fallback function to allow the contract to receive Ether
    /// It is automatically called when Ether is transferred to the contract without any data
    receive() external payable {}

    /// @dev Updates the whitelist status of a destination chain for transactions
    /// @notice This function can only be called by the owner
    /// @param _destinationChainSelector The selector of the destination chain to be updated
    /// @param allowed The whitelist status to be set for the destination chain
    function whitelistDestinationChain(uint64 _destinationChainSelector, bool allowed) external onlyOwner {
        whitelistedChains[_destinationChainSelector] = allowed;
    }

    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract
    /// @notice This function can only be called by the owner
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails
    /// @param _beneficiary The address to which the Ether should be transferred
    function withdraw(address _beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent,) = _beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token
    /// @notice This function can only be called by the owner
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw
    /// @param _beneficiary The address to which the tokens will be sent
    /// @param _token The contract address of the ERC20 token to be withdrawn
    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }

    /// @notice Updates the owner address of this contract.
    /// @notice This function can only be called by the owner
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /// @notice Sets router allowance to 0 to disable transferring tokens out of contract
    /// @notice This function can only be called by the owner
    /// @param _token The contract address of the ERC20 token to disable
    function revokeRouterAllowance(address _token) external onlyOwner {
        LINK.approve(address(router), 0);
        IERC20(_token).approve(address(router), 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit and strict = false.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR BETA TESTING
    bool strict; // See strict sequencing details below.
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns guaranteed execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// @notice A stripped down version of the utils from https://github.com/cryptofinlabs/cryptofin-solidity/
library AddressArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
     * @param A The first array
     * @param B The second array
     * @return The intersection of the two arrays
     */
    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            if (includeMap[i]) {
                newAddresses[j] = A[i];
                j++;
            }
        }
        return newAddresses;
    }
}