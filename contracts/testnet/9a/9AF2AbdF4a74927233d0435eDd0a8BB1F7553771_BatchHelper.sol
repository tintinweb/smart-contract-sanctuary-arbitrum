// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IHyphenLiquidityFarmingV2 {
    function changePauser(address newPauser) external;

    function deposit(uint256 _nftId, address _to) external;

    function extractRewards(
        uint256 _nftId,
        address[] memory _rewardTokens,
        address _to
    ) external;

    function getNftIdsStaked(address _user) external view returns (uint256[] memory nftIds);

    function getRewardRatePerSecond(address _baseToken, address _rewardToken) external view returns (uint256);

    function getRewardTokens(address _baseToken) external view returns (address[] memory);

    function getStakedNftIndex(address _staker, uint256 _nftId) external view returns (uint256);

    function getUpdatedAccTokenPerShare(address _baseToken, address _rewardToken) external view returns (uint256);

    function initialize(
        address _trustedForwarder,
        address _pauser,
        address _liquidityProviders,
        address _lpToken
    ) external;

    function isPauser(address pauser) external view returns (bool);

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function liquidityProviders() external view returns (address);

    function lpToken() external view returns (address);

    function nftIdsStaked(address, uint256) external view returns (uint256);

    function nftInfo(uint256) external view returns (address staker, bool isStaked);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pendingToken(uint256 _nftId, address _rewardToken) external view returns (uint256);

    function poolInfo(address, address) external view returns (uint256 accTokenPerShare, uint256 lastRewardTime);

    function reclaimTokens(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function renounceOwnership() external;

    function renouncePauser() external;

    function rewardRateLog(
        address,
        address,
        uint256
    ) external view returns (uint256 rewardsPerSecond, uint256 timestamp);

    function setRewardPerSecond(
        address _baseToken,
        address _rewardToken,
        uint256 _rewardPerSecond
    ) external;

    function setTrustedForwarder(address _tf) external;

    function totalSharesStaked(address) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateLiquidityProvider(address _liquidityProviders) external;

    function withdraw(uint256 _nftId, address _to) external;

    function withdrawAtIndex(
        uint256 _nftId,
        address _to,
        uint256 _index
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ILiquidityProviders {
    function BASE_DIVISOR() external view returns (uint256);

    function initialize(address _trustedForwarder, address _lpToken) external;

    function addLPFee(address _token, uint256 _amount) external;

    function addNativeLiquidity() external;

    function addTokenLiquidity(address _token, uint256 _amount) external;

    function claimFee(uint256 _nftId) external;

    function getFeeAccumulatedOnNft(uint256 _nftId) external view returns (uint256);

    function getSuppliedLiquidityByToken(address tokenAddress) external view returns (uint256);

    function getTokenPriceInLPShares(address _baseToken) external view returns (uint256);

    function getTotalLPFeeByToken(address tokenAddress) external view returns (uint256);

    function getTotalReserveByToken(address tokenAddress) external view returns (uint256);

    function getSuppliedLiquidity(uint256 _nftId) external view returns (uint256);

    function increaseNativeLiquidity(uint256 _nftId) external;

    function increaseTokenLiquidity(uint256 _nftId, uint256 _amount) external;

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function removeLiquidity(uint256 _nftId, uint256 amount) external;

    function renounceOwnership() external;

    function setLiquidityPool(address _liquidityPool) external;

    function setLpToken(address _lpToken) external;

    function setWhiteListPeriodManager(address _whiteListPeriodManager) external;

    function sharesToTokenAmount(uint256 _shares, address _tokenAddress) external view returns (uint256);

    function totalLPFees(address) external view returns (uint256);

    function totalLiquidity(address) external view returns (uint256);

    function totalReserve(address) external view returns (uint256);

    function totalSharesMinted(address) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function whiteListPeriodManager() external view returns (address);

    function increaseCurrentLiquidity(address tokenAddress, uint256 amount) external;

    function decreaseCurrentLiquidity(address tokenAddress, uint256 amount) external;

    function getCurrentLiquidity(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../structures/LpTokenMetadata.sol";

interface ILPToken {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);

    function exists(uint256 _tokenId) external view returns (bool);

    function getAllNftIdsByUser(address _owner) external view returns (uint256[] memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _trustedForwarder
    ) external;

    function isApprovedForAll(address _owner, address operator) external view returns (bool);

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function liquidityPoolAddress() external view returns (address);

    function mint(address _to) external returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function paused() external view returns (bool);

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setLiquidityPool(address _lpm) external;

    function setWhiteListPeriodManager(address _whiteListPeriodManager) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenMetadata(uint256)
        external
        view
        returns (
            address token,
            uint256 totalSuppliedLiquidity,
            uint256 totalShares
        );

    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function updateTokenMetadata(uint256 _tokenId, LpTokenMetadata memory _lpTokenMetadata) external;

    function whiteListPeriodManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

struct LpTokenMetadata {
    address token;
    uint256 suppliedLiquidity;
    uint256 shares;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../hyphen/interfaces/ILPToken.sol";
import "../hyphen/interfaces/ILiquidityProviders.sol";
import "../hyphen/interfaces/IHyphenLiquidityFarmingV2.sol";

contract BatchHelper {
    function execute(
        IERC20 token,
        ILPToken lpToken,
        ILiquidityProviders liquidityProviders,
        IHyphenLiquidityFarmingV2 farming,
        address receiver
    ) external {
        uint256 balance = token.balanceOf(address(this));
        token.approve(address(liquidityProviders), balance);
        liquidityProviders.addTokenLiquidity(address(token), balance);
        uint256[] memory tokensOwned = lpToken.getAllNftIdsByUser(address(this));
        lpToken.approve(address(farming), tokensOwned[0]);
        farming.deposit(tokensOwned[0], receiver);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}