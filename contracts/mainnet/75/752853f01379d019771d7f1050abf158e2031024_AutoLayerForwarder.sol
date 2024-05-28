// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


import {AggregatorV3Interface} from "../lib/foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {AutoLayerPoints} from "./AutoLayerPoints.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import './utils/AutoLayerUtils.sol';
import "./interfaces/IParaSwap.sol";
import "./interfaces/IBalancer.sol";
import "./interfaces/IGamma.sol";
import "./interfaces/INFTPool.sol";
import "./interfaces/IHipervisor.sol";
import "./interfaces/IGammaUniProxy.sol";

contract AutoLayerForwarder is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    AutoLayerPoints autoLayerPoints;
    AggregatorV3Interface priceFeed;
    address router;
    IBalancer balancerVault;
    IGamma gammaProxy;
    address tokenProxy;
    mapping(address => bool) isTokenWhitelisted;
    mapping(address => uint8) public tokenBoost;

    constructor(address autoLayerPointsAddress_, address routerAddress_, address ETHUSDPriceFeedAdress_, address balancerVaultAddress_, address tokenProxyAddress_, address gammaProxyAddress_) Ownable(msg.sender) {
        autoLayerPoints = AutoLayerPoints(autoLayerPointsAddress_);
        priceFeed = AggregatorV3Interface(ETHUSDPriceFeedAdress_);
        router = routerAddress_;
        balancerVault = IBalancer(balancerVaultAddress_);
        tokenProxy = tokenProxyAddress_;
        gammaProxy = IGamma(gammaProxyAddress_);
    }

    function swapTokensWithETH(bytes calldata swapData_) external payable returns(uint256 swappedAmount) {
        bytes memory dataWithoutFunctionSelector_ = bytes(swapData_[4:]);
        (Utils.SellData memory sellData_) = abi.decode(dataWithoutFunctionSelector_, (Utils.SellData));

        address toToken_ = address(sellData_.path[sellData_.path.length - 1].to);
        require(sellData_.fromToken != toToken_, "Swapping to same token is not allowed");

        if (sellData_.fromToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) require(msg.value == sellData_.fromAmount, "Amount not matching");
        else {
            IERC20(sellData_.fromToken).safeTransferFrom(msg.sender, address(this), sellData_.fromAmount);
            IERC20(sellData_.fromToken).approve(tokenProxy, sellData_.fromAmount);
        }

        uint256 balanceBefore_;
        if (toToken_ != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            balanceBefore_ = IERC20(toToken_).balanceOf(address(this));
        } else balanceBefore_ = address(this).balance;

        (bool success, ) = router.call{value: msg.value}(swapData_);
        require(success, "Swap failed");

        uint256 balanceAfter_;
        if (toToken_ != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) balanceAfter_ = IERC20(toToken_).balanceOf(address(this));
        else balanceAfter_ = address(this).balance;
        swappedAmount = balanceAfter_ - balanceBefore_;

        if(isTokenWhitelisted[toToken_]) {
            uint8 tokenBoost_ = tokenBoost[toToken_];
            addUserPoints(swappedAmount, tokenBoost_);
        }

        if (toToken_ != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) IERC20(toToken_).safeTransfer(msg.sender, swappedAmount);
        else {
            (bool success_, ) = msg.sender.call{value: swappedAmount}("");
            require(success_, "ETH send failed");
        }
    }

    function swapTokens(bytes calldata swapData_) external returns(uint256 swappedAmount) {
        bytes memory dataWithoutFunctionSelector_ = bytes(swapData_[4:]);
        (Utils.SellData memory sellData_) = abi.decode(dataWithoutFunctionSelector_, (Utils.SellData));

        address toToken_ = address(sellData_.path[sellData_.path.length - 1].to);
        require(sellData_.fromToken != toToken_, "Swapping to same token is not allowed");

        IERC20(sellData_.fromToken).safeTransferFrom(msg.sender, address(this), sellData_.fromAmount);
        uint256 balanceBefore_ = IERC20(toToken_).balanceOf(address(this));

        IERC20(sellData_.fromToken).approve(tokenProxy, sellData_.fromAmount);
        (bool success, ) = router.call(swapData_);
        require(success, "Swap failed");
        uint256 balanceAfter_ = IERC20(toToken_).balanceOf(address(this));
        swappedAmount = balanceAfter_ - balanceBefore_;

        if(isTokenWhitelisted[toToken_]) {
            uint8 tokenBoost_ = tokenBoost[toToken_];
            addUserPoints(swappedAmount, tokenBoost_);
        }
        IERC20(toToken_).safeTransfer(msg.sender, swappedAmount);
    }

    function addLiquidityToBalancer(bytes calldata swapData_, address[] memory tokens_, address[] memory tokensWithBpt_, bytes32 poolId_) external payable returns (uint256 bptAmount_){
        (uint256 fromAmount, uint256 swappedAmount, address fromToken_, address toToken_) = internalSwap(swapData_);

        if (fromToken_ == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) require(fromAmount == msg.value, "Incorrect ETH amount");

        address bptAddress = getBptAddress(poolId_);
        uint256[] memory amountsWithBPT = AutoLayerUtils.generateAmounts(swappedAmount, tokensWithBpt_, toToken_);
        uint256[] memory amountsWithoutBPT = AutoLayerUtils.generateAmounts(swappedAmount, tokens_, toToken_);
        bytes memory userDataEncoded_ = abi.encode(1, amountsWithoutBPT);
        JoinPoolRequest memory joinRequest_ = JoinPoolRequest(tokensWithBpt_, amountsWithBPT, userDataEncoded_, false);

        uint256 bptAmountBeforeDeposit_ = IERC20(bptAddress).balanceOf(address(this));
        IERC20(toToken_).approve(address(balancerVault), swappedAmount);
        balancerVault.joinPool(poolId_, address(this), address(this), joinRequest_);
        bptAmount_ = IERC20(bptAddress).balanceOf(address(this)) - bptAmountBeforeDeposit_;

        IERC20(bptAddress).safeTransfer(msg.sender, bptAmount_);
    }

    function removeLiquidityFromBalancer(bytes32 poolId_, address bptToken_, address tokenOut_, address[] memory tokens_, uint256[] memory minAmountsOut_, uint256 bptAmount_) external {
        require(tokens_.length == minAmountsOut_.length, "Not matching lengths");

        IERC20(bptToken_).safeTransferFrom(msg.sender, address(this), bptAmount_);
        IERC20(bptToken_).approve(address(balancerVault), bptAmount_);

        bytes memory userDataEncoded_ = abi.encode(0, bptAmount_, 0);
        IAsset[] memory assets_ = AutoLayerUtils.tokensToAssets(tokens_);
        ExitPoolRequest memory request_ = ExitPoolRequest(assets_, minAmountsOut_, userDataEncoded_, false);

        uint256 balanceBefore_ = IERC20(tokenOut_).balanceOf(address(this));
        balancerVault.exitPool(poolId_, address(this), payable(address(this)), request_);
        uint256 balanceAfter_ = IERC20(tokenOut_).balanceOf(address(this));

        IERC20(tokenOut_).safeTransfer(msg.sender, balanceAfter_ - balanceBefore_);
    }

    function addLiquidityToCamelot(bytes calldata swapData0_, bytes calldata swapData1_, address pos, uint256[4] memory minIn, address nftPool, uint256 lockDuration) public payable {
        (uint256 fromAmount0, uint256 swappedAmount0, address fromToken_0, address toToken_0) = internalSwap(swapData0_);
        (uint256 fromAmount1, uint256 swappedAmount1, address fromToken_1, address toToken_1) = internalSwap(swapData1_);

        if (fromToken_0 == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) require(fromAmount0 + fromAmount1 == msg.value, "Incorrect ETH amount");

        address gammaUniProxyAddress = gammaProxy.gammaUniProxy();
        (uint256 requiredSecondLow, uint256 requiredSecondHigh) = IGammaUniProxy(gammaUniProxyAddress).getDepositAmount(pos, toToken_0, swappedAmount0);
        (uint256 requiredFirstLow, uint256 requiredFirstHigh) = IGammaUniProxy(gammaUniProxyAddress).getDepositAmount(pos, toToken_1, swappedAmount1);

        uint256 finalAmount0;
        uint256 finalAmount1;
        uint256 resendAmount;
        address resendToken;
        if (swappedAmount0 >= requiredFirstLow && swappedAmount0 <= requiredFirstHigh) {
            finalAmount0 = swappedAmount0;
            finalAmount1 = swappedAmount1;
        } else if (swappedAmount0 > requiredFirstHigh) {
            finalAmount0 = requiredFirstHigh;
            finalAmount1 = swappedAmount1;
            resendAmount = swappedAmount0 - requiredFirstHigh;
            resendToken = toToken_0;
        } else if (swappedAmount1 > requiredSecondHigh) {
            finalAmount0 = swappedAmount0;
            finalAmount1 = requiredSecondHigh;
            resendAmount = swappedAmount1 - requiredSecondHigh;
            resendToken = toToken_1;
        } else {
            revert("Incorrect swapped amounts");
        }

        IERC20(toToken_0).approve(address(gammaProxy), swappedAmount0);
        IERC20(toToken_1).approve(address(gammaProxy), swappedAmount1);

        uint256 NFTId = INFTPool(nftPool).lastTokenId();
        gammaProxy.deposit(toToken_0, toToken_1, finalAmount0, finalAmount1, pos, minIn, nftPool, lockDuration);
        IERC721(nftPool).safeTransferFrom(address(this), msg.sender, NFTId + 1);
        if (resendAmount != 0) IERC20(resendToken).safeTransfer(msg.sender, resendAmount);
    }

    function withdrawFromCamelotPosition(address nftPool, uint256 tokenId, uint256 amountToWithdraw) public {
        INFTPool(nftPool).withdrawFromPosition(tokenId, amountToWithdraw);
    }

    function unbindCamelotPosition(address positionAddress, uint256 sharesAmount, uint256[4] memory minAmounts) external {
        IERC20(positionAddress).safeTransferFrom(msg.sender, address(this), sharesAmount);
        IHipervisor(positionAddress).withdraw(sharesAmount, msg.sender, address(this), minAmounts);
    }

    function internalSwap(bytes calldata swapData_) internal returns(uint256 fromAmount, uint256 swappedAmount, address fromToken, address toToken) {
        bytes memory dataWithoutFunctionSelector_ = bytes(swapData_[4:]);
        (Utils.SellData memory sellData_) = abi.decode(dataWithoutFunctionSelector_, (Utils.SellData));

        fromToken = sellData_.fromToken;
        toToken = address(sellData_.path[sellData_.path.length - 1].to);

        require(fromToken != toToken, "Swapping to same token is not allowed");
        if (fromToken != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            IERC20(fromToken).safeTransferFrom(msg.sender, address(this), sellData_.fromAmount);
            IERC20(fromToken).approve(tokenProxy, sellData_.fromAmount);
        }

        fromAmount = sellData_.fromAmount;

        uint256 balanceBefore_;
        if (toToken != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            balanceBefore_ = IERC20(toToken).balanceOf(address(this));
        } else balanceBefore_ = address(this).balance;

        bool success;
        if (fromToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            (success, ) = router.call{value: fromAmount}(swapData_);
        } else (success, ) = router.call(swapData_);

        require(success, "Swap failed");

        uint256 balanceAfter_;
        if (toToken != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) balanceAfter_ = IERC20(toToken).balanceOf(address(this));
        else balanceAfter_ = address(this).balance;
        swappedAmount = balanceAfter_ - balanceBefore_;

        if(isTokenWhitelisted[toToken]) {
            uint8 tokenBoost_ = tokenBoost[toToken];
            addUserPoints(swappedAmount, tokenBoost_);
        }
    }

    function getBptAddress(bytes32 poolId_) public view returns(address bptAddress) {
        (bptAddress, ) = balancerVault.getPool(poolId_);
    }


    function addUserPoints(uint256 ETHAmount_, uint8 tokenBoost_) internal {
        uint256 ETHCurrentPrice = retrieveETHPrice() / (10 ** priceFeed.decimals());
        uint256 points = ETHAmount_ * ETHCurrentPrice;
        autoLayerPoints.addPoints(msg.sender, points * tokenBoost_);
    }

    function retrieveETHPrice() internal view returns(uint256 answer_) {
       (, int answer,,,) = priceFeed.latestRoundData();

       if (answer < 0) return 0;
       else return uint256(answer);
    }

    function whitelistTokens(address[] memory tokenAddresses_) external onlyOwner() {
        for (uint8 i; i < tokenAddresses_.length; i++) {
            isTokenWhitelisted[tokenAddresses_[i]] = true;
            tokenBoost[tokenAddresses_[i]] = 1;
        }
    }

    function blackListTokens(address[] memory tokenAddresses_) external onlyOwner() {
        for (uint8 i; i < tokenAddresses_.length; i++) {
            isTokenWhitelisted[tokenAddresses_[i]] = false;
        }
    }

    function changeTokenBoost(address tokenAddress_, uint8 newBoost) external onlyOwner() {
        require(isTokenWhitelisted[tokenAddress_], "Token is not whitelisted");
        tokenBoost[tokenAddress_] = newBoost;
    }

    receive() external virtual payable {

    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId) external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );
  function latestRoundData() external view returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract AutoLayerPoints is Ownable {

    mapping(address => uint256) public userPoints;
    mapping(address => bool) public isAllowed;

    event AutoLayerPointsAdded(address user, uint256 pointsAdded);
    event AutoLayerPointsRemoved(address user, uint256 pointsAdded);

    modifier onlyAllowed() {
        require(isAllowed[msg.sender] || msg.sender == owner(), "Not allowed forwarder");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function setAllowed(address allowedAddress_) public onlyOwner() {
        isAllowed[allowedAddress_] = true;
    }

    function removeAllowed(address notAllowedAddress_) public onlyOwner() {
        isAllowed[notAllowedAddress_] = false;
    }

    function addPoints(address userAddress_, uint256 pointsAmount_) public onlyAllowed() {
        userPoints[userAddress_] += pointsAmount_;
        emit AutoLayerPointsAdded(userAddress_, pointsAmount_);
    }

    function removePoints(address userAddress_, uint256 pointsAmount_) public onlyAllowed() {
        userPoints[userAddress_] -= pointsAmount_;
        emit AutoLayerPointsRemoved(userAddress_, pointsAmount_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IBalancer.sol";

library AutoLayerUtils {
    function generateAmounts(uint256 swappedAmount, address[] memory tokens_, address depositedToken) internal pure returns (uint256[] memory amounts) {
        amounts = new uint256[](tokens_.length);
        for (uint i = 0; i < tokens_.length; i++) {
            if (tokens_[i] == depositedToken) amounts[i] = swappedAmount;
            else amounts[i] = 0;
        }
    }

    function tokensToAssets(address[] memory tokens_) internal pure returns(IAsset[] memory assets) {
        assets = new IAsset[](tokens_.length);
        for (uint8 i = 0; i < tokens_.length; i++) {
            assets[i] = IAsset(tokens_[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library Utils {

struct SimpleData {
    address fromToken;
    address toToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expectedAmount;
    address[] callees;
    bytes exchangeData;
    uint256[] startIndexes;
    uint256[] values;
    address payable beneficiary;
    address payable partner;
    uint256 feePercent;
    bytes permit;
    uint256 deadline;
    bytes16 uuid;
}

struct SellData {
    address fromToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expectedAmount;
    address payable beneficiary;
    Utils.Path[] path;
    address payable partner;
    uint256 feePercent;
    bytes permit;
    uint256 deadline;
    bytes16 uuid;
}

struct Path {
    address to;
    uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
    Adapter[] adapters;
}

struct Adapter {
    address payable adapter;
    uint256 percent;
    uint256 networkFee; //NOT USED
    Route[] route;
}

struct Route {
    uint256 index; //Adapter at which index needs to be used
    address targetExchange;
    uint256 percent;
    bytes payload;
    uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IAsset.sol";

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

struct BatchSwap {
    SwapKind kind;
    BatchSwapStep[] swaps;
    IAsset[] assets;
    FundManagement funds;
    int256[] limits;
    uint256 deadline;
}

struct Swap {
    SingleSwap singleSwap;
    FundManagement funds;
    uint256 limit;
    uint256 deadline;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
}

struct SingleSwap {
    bytes32 poolId;
    uint8 kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

enum PoolSpecialization {
    GENERAL,
    MINIMAL_SWAP_INFO,
    TWO_TOKEN
}

interface IBalancer {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPool(
        bytes32 poolId
    ) external view returns (address, PoolSpecialization);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGamma {
    function depositETH(address token0, address token1, uint256 deposit0, uint256 deposit1, address pos, uint256[4] memory minIn, address nftPool, uint256 lockDuration) external payable;
    function deposit(address token0, address token1, uint256 deposit0, uint256 deposit1, address pos, uint256[4] memory minIn, address nftPool, uint256 lockDuration) external;
    function gammaUniProxy() external returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INFTPool {

function lastTokenId() external view returns (uint256);
function withdrawFromPosition(uint256 tokenId, uint256 amountToWithdraw) external;
function getPoolInfo() external returns(address, address, address, uint256, uint256, uint256, uint256, uint256);
function getStakingPosition(uint256 tokenId) external returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IHipervisor {
    function withdraw(uint256 shares, address to, address from, uint256[4] memory minAmounts) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGammaUniProxy {
    function getDepositAmount(address pos, address token, uint256 _deposit) external returns(uint256 amountStart, uint256 amountEnd);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}