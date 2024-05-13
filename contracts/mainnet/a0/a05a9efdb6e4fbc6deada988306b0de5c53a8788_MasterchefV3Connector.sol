// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "../interfaces/IFarmConnector.sol";
import "../interfaces/ILiquidityConnector.sol";
import "../interfaces/external/uniswap/INonfungiblePositionManager.sol";
import "../interfaces/external/IMasterchefV3.sol";

struct MasterchefV3ExtraData {
    uint256 tokenId;
    bool isIncrease;
    // User's existing NFT balance in the Sickle, typically 0
    uint256 tokenBalance;
    uint128 maxAmount0;
    uint128 maxAmount1;
}

contract MasterchefV3Connector is IFarmConnector, ILiquidityConnector {
    error Unsupported();

    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable override {
        // MasterchefV3 deposits use onERC721Received
        MasterchefV3ExtraData memory data =
            abi.decode(extraData, (MasterchefV3ExtraData));

        if (!data.isIncrease) {
            uint256 tokenId = IERC721Enumerable(token).tokenOfOwnerByIndex(
                address(this), data.tokenBalance
            );

            IERC721(token)
                // only deposit if its not a IncreaseLiquidity
                .safeTransferFrom(address(this), target, tokenId);
        }
    }

    function withdraw(
        address target,
        uint256, // amount
        bytes memory extraData
    ) external override {
        MasterchefV3ExtraData memory data =
            abi.decode(extraData, (MasterchefV3ExtraData));
        IMasterchefV3(target).withdraw(data.tokenId, address(this));
    }

    function claim(address target, bytes memory extraData) external override {
        MasterchefV3ExtraData memory data =
            abi.decode(extraData, (MasterchefV3ExtraData));
        IMasterchefV3(target).harvest(data.tokenId, address(this));
        if (data.maxAmount0 > 0 || data.maxAmount1 > 0) {
            INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: data.tokenId,
                recipient: address(this),
                amount0Max: data.maxAmount0,
                amount1Max: data.maxAmount1
            });
            INonfungiblePositionManager(target).collect(params);
        }
    }

    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable
        override
    {
        MasterchefV3ExtraData memory extraData =
            abi.decode(addLiquidityData.extraData, (MasterchefV3ExtraData));

        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
        INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: extraData.tokenId,
            amount0Desired: addLiquidityData.desiredAmounts[0],
            amount1Desired: addLiquidityData.desiredAmounts[1],
            amount0Min: addLiquidityData.minAmounts[0],
            amount1Min: addLiquidityData.minAmounts[1],
            deadline: block.timestamp + 1
        });

        INonfungiblePositionManager(addLiquidityData.router).increaseLiquidity(
            params
        );
    }

    function removeLiquidity(RemoveLiquidityData memory)
        external
        pure
        override
    {
        revert Unsupported();
    }

    function swapExactTokensForTokens(SwapData memory)
        external
        payable
        override
    {
        revert Unsupported();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - The `operator` cannot be the caller.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmConnector {
    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable;

    function withdraw(
        address target,
        uint256 amount,
        bytes memory extraData
    ) external;

    function claim(address target, bytes memory extraData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AddLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256[] desiredAmounts;
    uint256[] minAmounts;
    bytes extraData;
}

struct RemoveLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256 lpAmountIn;
    uint256[] minAmountsOut;
    bytes extraData;
}

struct SwapData {
    address router;
    uint256 amountIn;
    uint256 minAmountOut;
    address tokenIn;
    bytes extraData;
}

interface ILiquidityConnector {
    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable;

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external;

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INonfungiblePositionManager {
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function increaseLiquidity(IncreaseLiquidityParams memory params)
        external
        payable
        returns (uint256 amount0, uint256 amount1, uint256 liquidity);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function mint(MintParams memory params)
        external
        payable
        returns (uint256 tokenId, uint256 amount0, uint256 amount1);

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterchefV3 {
    function harvest(
        uint256 _tokenId,
        address _to
    ) external returns (uint256 reward);
    function withdraw(
        uint256 _tokenId,
        address _to
    ) external returns (uint256 reward);
    function pendingCake(uint256 _tokenId)
        external
        view
        returns (uint256 reward);
    function nonfungiblePositionManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}