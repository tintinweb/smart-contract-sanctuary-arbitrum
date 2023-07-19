/**
 *Submitted for verification at Arbiscan on 2023-07-19
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.8;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// Interface for Rango Receiver contract
interface IRangoMessageReceiver {
  enum ProcessStatus {
    SUCCESS,
    REFUND_IN_SOURCE,
    REFUND_IN_DESTINATION
  }

  function handleRangoMessage(
    address token,
    uint amount,
    ProcessStatus status,
    bytes memory message
  ) external;
}

// Interface for compound WETH contract
// https://github.com/compound-finance/comet/blob/main/contracts/IWETH9.sol
interface IWETH9 {
  function deposit() external payable;

  function withdraw(uint wad) external;

  function approve(address guy, uint wad) external returns (bool);
}

// Interface for Compound Comet contract
// https://github.com/compound-finance/comet/blob/main/contracts/Comet.sol
// https://github.com/compound-finance/comet/blob/main/contracts/CometExt.sol
interface IComet {
  /**
   * @notice Supply an amount of asset to dst
   * @param dst The address which will hold the balance
   * @param asset The asset to supply
   * @param amount The quantity to supply
   */
  function supplyTo(address dst, address asset, uint amount) external;

  /**
   * @notice Withdraw an amount of asset from src to `to`, if allowed
   * @param src The sender address
   * @param to The recipient address
   * @param asset The asset to withdraw
   * @param amount The quantity to withdraw
   */
  function withdrawFrom(
    address src,
    address to,
    address asset,
    uint amount
  ) external;
}

error RangoCometIntermediary__NotOwner();
error RangoCometIntermediary__NotRango();
error RangoCometIntermediary__RangoCrosschainCallFailed();
error RangoCometIntermediary__InvalidRangoContract();

contract RangoCometIntermediary is ReentrancyGuard, IRangoMessageReceiver {
  /* Type & Enum declarations */
  struct RangoCometMessageParams {
    address userAddress;
    address cometAddress;
  }

  /* State variables */
  // address for use instead of Ether address
  address private constant ETHER_ADDRESS = address(0);

  // WETH contract used by comet
  address private s_weth;

  // owner (admin) of the contract
  address private s_owner;

  // address of Rango Contract
  address[] private s_rango;

  /* Events */
  event SuppliedTo(
    address onBehalfOf,
    address comet,
    address token,
    uint256 amount
  );
  event SupplyFailed(
    address onBehalfOf,
    address comet,
    address token,
    uint256 amount,
    string reason
  );
  event WithdrawAndSupplyTo(
    address onBehalfOf,
    address comet,
    address token,
    uint256 amount
  );
  event OwnerChanged(address prevOwner, address newOwner);
  event RangoAddressAdded(address rangoAddress);
  event RangoAddressRemoved(address rangoAddress);

  /* Modifiers */
  /**
   * @notice A modifier which indicates that a function can be only called by owner
   */
  modifier onlyOwner() {
    if (msg.sender != s_owner) revert RangoCometIntermediary__NotOwner();
    _;
  }

  /**
   * @notice A modifier which indicates that a function can be only called by Rango contract addresses
   */
  modifier onlyRango() {
    bool found = false;
    for (uint256 i = 0; i < s_rango.length; i++) {
      if (s_rango[i] == msg.sender) {
        found = true;
        break;
      }
    }
    if (!found) {
      revert RangoCometIntermediary__NotRango();
    }
    _;
  }

  /* Constructor */
  constructor() {
    s_owner = msg.sender;
    s_weth = address(0);
  }

  /* Owner functions */
  function setWeth(address wethAddress) external onlyOwner {
    s_weth = wethAddress;
  }

  /**
   * @notice Owner must be able to add a contract to rango list
   * @param rangoContractAddress the contract address which should be added to rango contracts list
   */
  function addRangoContract(address rangoContractAddress) external onlyOwner {
    s_rango.push(rangoContractAddress);
    emit RangoAddressAdded(rangoContractAddress);
  }

  /**
   * @notice Owner must be able to remove a contract from rango list
   * @param rangoContractAddress the contract address which should be removed from rango contracts list
   */
  function removeRangoContract(
    address rangoContractAddress
  ) external onlyOwner {
    uint256 index = s_rango.length + 1;
    for (uint256 i = 0; i < s_rango.length; i++) {
      if (s_rango[i] == rangoContractAddress) {
        index = i;
        break;
      }
    }
    if (index < s_rango.length) {
      s_rango[index] = s_rango[s_rango.length - 1];
      s_rango.pop();
      emit RangoAddressRemoved(rangoContractAddress);
    } else {
      revert("Rango contract address not found");
    }
  }

  /**
   * @notice In case anything bad happens and token gets stuck in intermediary contract, owner should be able to refund it to user
   * @param token the token which should be refunded, address(0) for native token
   * @param amount the amount of token that needs to be refunded
   * @param user the user that must be receiving the refund
   */
  function refund(
    address token,
    uint256 amount,
    address user
  ) external onlyOwner {
    TransferHelper.safeTransfer(token, user, amount, true);
  }

  /**
   * @notice Owner must be able to transfer ownership to another address, for example a multi-sig/contract for future governance
   * @param newOwner The new owner which should be able to manage intermediary contract
   */
  function transferOwnership(address newOwner) external onlyOwner {
    address prevOwner = s_owner;
    s_owner = newOwner;
    emit OwnerChanged(prevOwner, newOwner);
  }

  /* Rango functions */
  /**
   * @dev This function should not revert in any case, since it might result in tokens getting stuck in contract. In any case, we have a refund function to handle such scenarios.
   * @notice Rango supplies token into the Comet
   * @param token The token which is provided by Rango, for native Eth, token is equal to address(0)
   * @param amount The amount of token which is provided by Rango
   */
  function handleRangoMessage(
    address token,
    uint256 amount,
    ProcessStatus status,
    bytes memory message
  ) external onlyRango nonReentrant {
    RangoCometMessageParams memory decodedMessage = abi.decode(
      message,
      (RangoCometMessageParams)
    );

    if (status != ProcessStatus.SUCCESS) {
      TransferHelper.safeTransfer(
        token,
        decodedMessage.userAddress,
        amount,
        false
      );
      return;
    }

    // if token is native, change it to weth and consider weth as final token
    address finalToken = token;
    if (token == ETHER_ADDRESS) {
      if (s_weth == address(0)) {
        revert("Weth address not found");
      }
      IWETH9 weth = IWETH9(s_weth);
      weth.deposit{value: amount}();
      finalToken = s_weth;
    }
    // approve comet on final token
    bool cometApproveSuccess = TransferHelper.safeApprove(
      finalToken,
      decodedMessage.cometAddress,
      amount,
      false
    );
    if (!cometApproveSuccess) {
      // if unable to approve comet on token, trnasfer token to user
      TransferHelper.safeTransfer(
        finalToken,
        decodedMessage.userAddress,
        amount,
        false
      );
      return;
    }
    // supply to comet
    IComet comet = IComet(decodedMessage.cometAddress);
    bool supplySuccess = true;
    string memory supplyError = "";
    try comet.supplyTo(decodedMessage.userAddress, finalToken, amount) {
      emit SuppliedTo(
        decodedMessage.userAddress,
        decodedMessage.cometAddress,
        token,
        amount
      );
    } catch Error(string memory reason) {
      // catch failing revert() and require()
      supplySuccess = false;
      supplyError = reason;
    } catch {
      // catch failing assert() or other
      supplySuccess = false;
    }
    if (supplySuccess == false) {
      // if unable to supply on comet, transfer funds to user
      TransferHelper.safeTransferToken(
        finalToken,
        decodedMessage.userAddress,
        amount,
        false
      );
      // then remove approval on token for comet
      TransferHelper.safeApprove(
        finalToken,
        decodedMessage.cometAddress,
        0,
        false
      );
      emit SupplyFailed(
        decodedMessage.userAddress,
        decodedMessage.cometAddress,
        token,
        amount,
        supplyError
      );
    }
  }

  /* User/Public functions */
  /**
   * @notice Users must be able to withdraw funds from a Comet instance on 1 chain, then bridge and supply it to another comet instance on another chain
   * @param sourceComet The comet contract on source blockchain which the fund must be withdrawn from
   * @param sourceToken The token contract on source blockchain which is the underlying asset of comet, address(0) for native token
   * @param sourceRango The rango contract on source blockchain which should receive the funds withdrawn from comet, it should be the included in s_rango addresses list
   * @param amount The amount of token which should be withdrawn from comet and sent to rango as input
   * @param rangoData The calldata created by Rango for cross-chain transfer
   */
  function withdrawAndCrosschainSupply(
    address sourceComet,
    address sourceToken,
    address sourceRango,
    uint256 amount,
    bytes calldata rangoData
  ) external nonReentrant {
    IComet comet = IComet(sourceComet);
    comet.withdrawFrom(msg.sender, address(this), sourceToken, amount);

    bool foundRango = false;
    for (uint256 i = 0; i < s_rango.length; i++) {
      if (s_rango[i] == sourceRango) {
        foundRango = true;
        break;
      }
    }
    if (!foundRango) {
      revert RangoCometIntermediary__InvalidRangoContract();
    }

    bool success = false;
    if (sourceToken == ETHER_ADDRESS) {
      // send native coin to rango
      (success, ) = payable(sourceRango).call{value: amount}(rangoData);
    } else {
      // approve token to rango
      success = TransferHelper.safeApprove(
        sourceToken,
        sourceRango,
        amount,
        false
      );
      // call rango if approve was successful
      if (success == true) {
        (success, ) = sourceRango.call(rangoData);
      }
    }

    if (success == false) {
      // revert transaction if rango approve or rango call failed
      revert RangoCometIntermediary__RangoCrosschainCallFailed();
    }

    emit WithdrawAndSupplyTo(msg.sender, sourceComet, sourceToken, amount);
  }

  /** receive and fallback */
  receive() external payable {
    // no receive logic yet
  }

  fallback() external payable {
    // no fallback logic yet
  }

  /** Getter Functions */
  /**
   * @notice Returns the owner of blockchain
   */
  function getOwner() public view returns (address) {
    return s_owner;
  }

  /**
   * @notice Returns the address index in s_rango address list
   */
  function getRango(uint index) public view returns (address) {
    return s_rango[index];
  }

  /**
   * @notice Returns the length of s_rango address list
   */
  function getRangoLength() public view returns (uint256) {
    return s_rango.length;
  }

  /**
   * @notice Returns the weth token address on this chain
   */
  function getWeth() public view returns (address) {
    return s_weth;
  }
}

// TransferHelper library from UniSwapV2
error TransferHelper__ApproveFailed();
error TransferHelper__TransferFailed();
error TransferHelper__TransferFromFailed();
error TransferHelper__EthTransferFailed();

library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value,
    bool raiseError
  ) internal returns (bool) {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x095ea7b3, to, value)
    );
    bool hasError = !success && (data.length == 0 || abi.decode(data, (bool)));
    if (hasError && raiseError) {
      revert TransferHelper__ApproveFailed();
    }
    return !hasError;
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value,
    bool raiseError
  ) internal returns (bool) {
    if (token == address(0)) {
      return TransferHelper.safeTransferETH(payable(to), value, raiseError);
    } else {
      return TransferHelper.safeTransferToken(token, to, value, raiseError);
    }
  }

  function safeTransferToken(
    address token,
    address to,
    uint256 value,
    bool raiseError
  ) internal returns (bool) {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0xa9059cbb, to, value)
    );
    bool hasError = !success && (data.length == 0 || abi.decode(data, (bool)));
    if (hasError && raiseError) {
      revert TransferHelper__TransferFailed();
    }
    return !hasError;
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value,
    bool raiseError
  ) internal returns (bool) {
    // bytes4(keccak256(bytes(' (address,address,uint256)')));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x23b872dd, from, to, value)
    );
    bool hasError = !(success &&
      (data.length == 0 || abi.decode(data, (bool))));
    if (hasError && raiseError) {
      revert TransferHelper__TransferFromFailed();
    }
    return !hasError;
  }

  function safeTransferETH(
    address to,
    uint256 value,
    bool raiseError
  ) internal returns (bool) {
    (bool success, ) = to.call{value: value}(new bytes(0));
    if (!success && raiseError) {
      revert TransferHelper__EthTransferFailed();
    }
    return success;
  }
}