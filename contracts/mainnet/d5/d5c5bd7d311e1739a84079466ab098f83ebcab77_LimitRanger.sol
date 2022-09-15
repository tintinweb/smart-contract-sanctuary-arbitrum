// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.9;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import 'contracts/interfaces/uniswap/INonfungiblePositionManager.sol';
import 'contracts/interfaces/uniswap/IUniswapV3Pool.sol';
import 'contracts/interfaces/uniswap/IUniswapV3Factory.sol';
import 'contracts/interfaces/uniswap/IWETH9.sol';

import './UniswapTransferHelper.sol';

/// @title A contract which allows automated range orders for Uniswap by opening a liquidity position 
///        and allowing anyone to close the position once the selling price is reached and returning the assets
///        to the original owner - minus a protocol fee (this is usually done by a bot). 
contract LimitRanger {

    /// Uniswap smart contracts
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;

    /// Smart contract of eth wrapper token
    IWETH9 public immutable weth9;

    /// Uniswap liquidity position NFT smart contract
    IERC721 public immutable uniNft;

    /// @dev Address of the protocol operator who has administrative rights
    address public protocolOperator;

    /// @dev Address where protocol fees are sent to
    address payable public protocolFeeReceiver;
    
    /// current fee in per thousand
    uint16 public currentMinFee;

    /// current stop position reward in percentage of fee (payed to the address which triggers a successful close position)
    uint8 public currentStopPositionReward;

    /// switch to disable opening of new positions
    bool public depositsActive;

    /// @dev Uniswap maximum tick value of a liquidity pool
    int24 constant MAX_TICK = (2**24/2)-1;

    /// Event for the opening of a new position
    /// @param token The ID of the uniswap NFT which got created opening the position
    /// @param owner The address which opened the position
    event AddPosition(uint256 token, address indexed owner, uint128 liquidity, bool sellAbove);

    /// Event for when a user takes ownership of his liquidity position which got created opening a position
    /// @param token The ID of the uniswap NFT the user takes ownership off 
    /// @param owner The address which opened the position
    event RemovePosition(uint256 token, address indexed owner);

    /// Event for when a position gets closed because the sell price was reached. Closing transfers the tokens in the liquidity position 
    /// to the initial owner minus the fees which get transferred to the protocolFeeReceiver address
    /// @param token The ID of the uniswap NFT which got closed
    /// @param owner The address which opened the position
    event ClosePosition(uint256 token, address indexed owner);

    /// Event for when a user cancels one of his positions which removes all liquidity from the liquidity position and transfers
    /// all tokens back to him, without applying any fees
    /// @param token The ID of the uniswap NFT representing the position which gets cancelled
    /// @param owner The address which opened the position
    event CancelPosition(uint256 token, address indexed owner);

    /// Event for when a new minimum protocol fee is set.
    /// @param newFee The new fee amount in per thousand.
    event MinimumFeeSet(uint16 newFee);

    /// Event for when a new address for the fee receiver is set.
    /// @param newFeeReceiver The address which receives all protocol fees.
    event FeeReceiverSet(address newFeeReceiver);

    /// Event for when a new address for the protocol operator is set.
    /// @param newOperator The address of the new protocol operator.
    event OperatorSet(address newOperator);

    /// Event for when deposits are activated/disabled.
    /// @param active If true deposits are active, if false deposits are disabled.
    event DepositsActiveSet(bool active);

    /// Event for when a new reward percentage is set for closing positions.
    /// @param reward The new reward as percentage of fees collected.
    event StopPositionRewardSet(uint8 reward);

    /// @dev Information about a position
    /// @param owner The address which opened the position
    /// @param sellTarget The tick at which the position can be closed
    /// @param fee The fee in per thounsand which gets deducted when the position is closed
    /// @param sellAboveTarget true if the tick of the liquidity pool needs to be at or above the sellTarget.
    ///                        false if it needs to be at or below
    /// @param unwrapToNative if true wrapped ether will be unwrapped before being sent to the owner when the position is closed
    struct PositionInfo {
        address owner;
        int24 sellTarget;
        uint16 fee;
        bool sellAboveTarget;
        bool unwrapToNative;
    }

    /// @dev Mint params for a LimitRanger position.
    struct MintParams {
        address token0; 
        address token1;
        uint256 token0Amount;
        uint256 token1Amount;
        int24 lowerTick;
        int24 upperTick;
        uint24 poolFee;
        uint256 deadline;
        uint16 protocolFee;
        bool unwrapToNative;
    }

    /// @dev positionInfos[tokenId] => PositionInfo - Lookup of position infos by uniswap tokenId
    mapping(uint256 => PositionInfo) public positionInfos;

    /// @dev ownedTokens[ownerAddress] => tokenIds[] - Lookup of owned positions (uniswap tokenIds) by owner address.
    ///      Owned token Ids are stored in an array.
    mapping(address => uint256[]) internal ownedTokens;

    /// @dev ownedTokensIndex[tokenId] => index - Lookup of the index of a position in the ownedTokens array.
    mapping(uint256 => uint256) internal ownedTokensIndex;

    /// Create instance of contract
    /// @param _nonfungiblePositionManager Corresponding Uniswap contract
    /// @param _uniswapV3Factory Corresponding Uniswap contract
    /// @param _weth9 Eth ERC20 wrapper token contract
    constructor(
        INonfungiblePositionManager _nonfungiblePositionManager,
        IUniswapV3Factory _uniswapV3Factory,
        IWETH9 _weth9
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        uniswapV3Factory = _uniswapV3Factory;
        uniNft = _nonfungiblePositionManager;
        weth9 = _weth9;
        protocolOperator = msg.sender;
        protocolFeeReceiver = payable(msg.sender);
        currentMinFee = 1;
        currentStopPositionReward = 0;
        depositsActive = true;
    }

    /*****************************************/
    /*************** MODIFIERS ***************/
    /*****************************************/
    /// Modifier to check deadline of a transaction.
    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, 'Transaction too old');
        _;
    }

    /// Modifier which checks if the operation is performed by the owner of the given token.
    modifier onlyOwner(uint256 tokenId) {
        require(positionInfos[tokenId].owner == msg.sender, 'Operation only allowed for owner of position');
        _;
    }

    /// Modifier which checks if the operation is performed by the protocol operator.
    modifier onlyOperator() {
        require(msg.sender == protocolOperator, 'Operaton only allowed for operator of contract');
        _;
    }

    /// Modifier which checks if new deposits are currently allowed
    modifier onlyDepositsActive() {
        require(depositsActive, 'Deposits are currently disabled');
        _;
    }

    /*****************************************/
    /******** PROTOCOL ADMINISTRATION ********/
    /*****************************************/

    /// Sets the address to which protocol fees are sent
    /// @param receiver The new protocol fee receiver address.
    function setProtocolFeeReceiver(address receiver) external onlyOperator {        
        require(address(0) != receiver, '0x0 address not allowed');
        protocolFeeReceiver = payable(receiver);
        emit FeeReceiverSet(receiver);
    }

    /// Sets the address of the new protocol operator
    /// @param newOperator The new protocol operator address.
    function setProtocolOperator(address newOperator) external onlyOperator {        
        require(address(0) != newOperator, '0x0 address not allowed');
        protocolOperator = newOperator;
        emit OperatorSet(newOperator);
    }

    /// Sets the minimumb protocol fee for new positions in per thousand.
    /// @param fee The new minimum fee.
    function setMinimumFee(uint16 fee) external onlyOperator {
        currentMinFee = fee;
        emit MinimumFeeSet(fee);
    }

    /// Toggles if new deposits are allowed or not.
    /// @param active If true new deposits are allowed. Otherwise no new deposits can be made.
    function setDepositsActive(bool active) external onlyOperator {
        depositsActive = active;
        emit DepositsActiveSet(active);
    }

    /// Sets new reward percentage for successfully closing positions. 
    /// @param reward The new reward as percentage of fees collected.
    function setStopPositionReward(uint8 reward) external onlyOperator {
        require(reward <= 100, 'reward >100 not allowed');
        currentStopPositionReward = reward;
        emit StopPositionRewardSet(reward);
    }


    /*****************************************/
    /********** PUBLIC FUNCTIONS *************/
    /*****************************************/

    /// Returns the address of the owner of a given token.
    /// @param tokenId The tokenId of the position to retrieve the owner address of.
    /// @return Address of the owner of the given position.
    function getOwner(uint256 tokenId) external view returns (address) {
        return(positionInfos[tokenId].owner);
    }

    /// Returns all owned tokenIds for the given address
    /// @param owner The address for which the owned positions should be returned.
    /// @return Token IDs of the positions owned by the given address.
    function getOwnedPositions(address owner) external view returns (uint256[] memory) {
        return ownedTokens[owner];
    }

    /// Retrieve position information for the given token ID.
    /// @param tokenId The token ID identifying the position to be returned.
    /// @return Position information for the position identified by the given token ID.
    function getPositionInfo(uint256 tokenId) external view returns (PositionInfo memory) {
        return positionInfos[tokenId];
    }

    /// Cancels a position, removing all liquidity and fees from the Uniswap liquidity position and returning the assets 
    /// to the owner without charging a protocol fee.
    /// Can only be triggered by the owner of the position.
    /// @param tokenId Token ID identifying the position to be cancelled.
    /// @return success True if the position was successfully canceled. False otherwise.
    function cancelPosition(uint256 tokenId) external onlyOwner(tokenId) returns (bool success) {
        bool result = _payOutPosition(tokenId, false);
        if(result) {
            emit CancelPosition(tokenId, msg.sender);
        }
        return result;
    }

    /// Stops a position, removing all liquidity and fees from the Uniswap liquidity position and returning the assets 
    /// to the owner minus the set fee which is sent to the protocol fee receiver address.
    /// Can only be triggered when the tick value requirement of the position is met.
    /// @param tokenId Token ID identifying the position to be stopped.
    /// @return success True if the position was successfully stopped. False otherwise.
    function stopPosition(uint256 tokenId) external returns (bool success){
        address owner = positionInfos[tokenId].owner;
        bool result = _payOutPosition(tokenId, true);
        if(result) {
            emit ClosePosition(tokenId, owner);
        }
        return result;
    }


    /// Transfers the NFT identifying the Uniswap liqudity position to the owner of the position.
    /// Can only be called by the owner.
    /// @param tokenId The id of the position to be returned to the owner
    function retrieveNFT(uint256 tokenId) external onlyOwner(tokenId) {        
        _removePosition(tokenId, msg.sender);
        emit RemovePosition(tokenId, msg.sender); 
    }

    /// Opens a new position.
    /// @param params Mint new position parameters
    /// @return tokenId The token ID identifying this position and the corresponding Uniswap liquidity position.
    function mintNewPosition(MintParams calldata params)
        external
        payable 
        onlyDepositsActive
        checkDeadline(params.deadline)
        returns (           
            uint256 tokenId      
        )
    {       
        require(params.token0Amount == 0 || params.token1Amount == 0, 'Token amount of token0 or token1 must be 0');
        require(params.token0Amount > 0 || params.token1Amount > 0, 'Invalid token amount');
        require(params.protocolFee >= currentMinFee && params.protocolFee <= 500, 'Invalid protocol fee');

        uint256 ethAmount = 0;
        // if msg value is greater than 0, check if sent ether matches weth token amount value 
        if(msg.value > 0) {
            if(params.token0 == address(weth9)) {            
                ethAmount = params.token0Amount;
            } else if (params.token1 == address(weth9)) {
                ethAmount = params.token1Amount;
            } else {
                revert('Message value not 0');
            }
            require(ethAmount == msg.value, 'Invalid message value');
        }
        
        {
            IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Factory.getPool(params.token0, params.token1, params.poolFee));        
            //check if current tick is outside sell range
            (,int24 tick,,,,,) = pool.slot0();
            if(params.token0Amount > 0) {
                require(tick <= params.lowerTick, "Current price of pool doesn't match desired sell range");
            } else {
                require(tick >= params.upperTick, "Current price of pool doesn't match desired sell range");
            }
        }
        // Approve the position manager
        if(params.token0Amount > 0) {
            // get token from user    
            if(params.token0 != address(weth9) || ethAmount == 0) {
                UniswapTransferHelper.safeTransferFrom(params.token0, msg.sender, address(this), params.token0Amount);            
                UniswapTransferHelper.safeApprove(params.token0, address(nonfungiblePositionManager), params.token0Amount);
            }
        } else {
            if(params.token1 != address(weth9) || ethAmount == 0) {
                UniswapTransferHelper.safeTransferFrom(params.token1, msg.sender, address(this), params.token1Amount);
                UniswapTransferHelper.safeApprove(params.token1, address(nonfungiblePositionManager), params.token1Amount);
            }
        }
        INonfungiblePositionManager.MintParams memory uniParams =
            INonfungiblePositionManager.MintParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.poolFee,
                tickLower: params.lowerTick,
                tickUpper: params.upperTick,
                amount0Desired: params.token0Amount,
                amount1Desired: params.token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        uint128 liquidity = 0;
        (tokenId,liquidity,,) = nonfungiblePositionManager.mint{value: ethAmount}(uniParams);

        if(params.token0Amount > 0) {
            _storePositionInfo(tokenId, params.upperTick, true, msg.sender, params.protocolFee, params.unwrapToNative);
        } else {
            _storePositionInfo(tokenId, params.lowerTick, false, msg.sender, params.protocolFee, params.unwrapToNative);
        }
        emit AddPosition(tokenId, msg.sender, liquidity, params.token0Amount > 0);
        return tokenId;
    }

    /*****************************************/
    /********** INTERNAL FUNCTIONS ***********/
    /*****************************************/

    /// @dev Transfers the uniswap liquidity position NFT to the receiver and removes the given position data from the internal storage.
    /// @param tokenId Token ID identifying the position to be removed.
    /// @param receiver Receiver of the uniswap liqudity position NFT.
    function _removePosition(uint256 tokenId, address receiver) internal {
        // remove information related to tokenId
        delete positionInfos[tokenId];
        // remove token from ownedTokens array by reducing the arrays size and moving the token in last position to the spot of the to be deleted one.
        // set last token to index of removed token, then decrease array size (so we don't have gaps in the array)
        uint256 tokenIndex = ownedTokensIndex[tokenId];
        uint256 lastTokenIndex = (ownedTokens[receiver].length - 1);
        uint256 lastToken = ownedTokens[receiver][lastTokenIndex];
        ownedTokens[receiver][tokenIndex] = lastToken;
        ownedTokens[receiver].pop();
        ownedTokensIndex[tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        // transfer ownership to original owner
        nonfungiblePositionManager.safeTransferFrom(address(this), receiver, tokenId);
    }

    /// @dev Saves information about a position in smart contract storage.
    /// @param tokenId Token ID of the position to be stored.
    /// @param sellTarget Uniswap liquidity pool tick which needs to be reached to close the position.
    /// @param sellAboveTarget When true the uniswap liquidity pool tick needs to be at or over the saved sellTarget value. If false it needs to be at or under the value.
    /// @param owner The address of the owner of the position.
    /// @param fee The protocol fee for this position.
    function _storePositionInfo(uint256 tokenId, int24 sellTarget, bool sellAboveTarget, address owner, uint16 fee, bool unwrapToNative) internal {
        positionInfos[tokenId] = PositionInfo({owner: owner, sellTarget: sellTarget, sellAboveTarget: sellAboveTarget, fee: fee, unwrapToNative: unwrapToNative});
        uint256 length = ownedTokens[owner].length;
        ownedTokens[owner].push(tokenId);
        ownedTokensIndex[tokenId] = length;
    }

    /// @dev Closes the uniswap liquidity position and returning the assets to the position owner. If stoppedByProtocol is set the protocol fee is deducted and sent 
    ///      to the protocol fee receiver address.
    /// @param tokenId The token ID identifying the position.
    /// @param stoppedByProtocol If true the function was triggered by stop position and the protocol fee is deducted from the assets.
    ///                          Otherwise it was triggered by the owner itself and no fee is deducted.
    /// @return success True if the position could be liquidated and paid out.
    function _payOutPosition(uint256 tokenId, bool stoppedByProtocol) internal returns (bool success) {
        // get position & pool info
        (,,address token0, address token1, uint24 fee,,, uint128 liquidity,,,,) =  nonfungiblePositionManager.positions(tokenId);        
        PositionInfo memory position = positionInfos[tokenId];

        require(position.owner != address(0), 'Position not found');
        {
            IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Factory.getPool(token0, token1, fee));        
            // only check sell targets when stopped by protocol
            if(stoppedByProtocol) {
                (,int24 tick,,,,,) = pool.slot0();
                if(position.sellAboveTarget) {
                    require(tick >= position.sellTarget, 'Sell target not reached. Current tick below sell target tick.');
                } else {
                    require(tick <= position.sellTarget, 'Sell target not reached. Current tick above sell target tick.');
                }
            }
            // remove all liquidity from position
            INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams(tokenId,
            liquidity,
            0, //amount0Min
            0, //amount1Min;
            block.timestamp // deadline
            );
            // not checking return value since we collect maximum anyways
            nonfungiblePositionManager.decreaseLiquidity(params);
        }
        {
            // collect all tokens (fees + removed liquidity)
            INonfungiblePositionManager.CollectParams memory params2 =
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });
            (uint256 collectedAmount0, uint256 collectedAmount1) = nonfungiblePositionManager.collect(params2);
            
            // calculate fee
            uint256 fee0 = 0;
            uint256 fee1 = 0;
            
            if(stoppedByProtocol) {
                // we accept loss of precision here
                fee0 = (collectedAmount0 / 1000) * position.fee;
                fee1 = (collectedAmount1 / 1000) * position.fee;
            }
                    
            // transfer tokens to position owner and fees to protocol owner if applicable
            _payOutToken(collectedAmount0, fee0, token0, position.owner, position.unwrapToNative);
            _payOutToken(collectedAmount1, fee1, token1, position.owner, position.unwrapToNative);        
            _removePosition(tokenId, position.owner);
        }
        return true;
    }


    /// @dev sends the specified token amount to the owner minus the specified fee which is sent to the protocol fee receiver address
    /// @param collectedAmount Amount of the token which is to be paid out
    /// @param fee Fee amount to be deduced from the amount to be paid out
    /// @param token Address of the token which is to be paid out
    /// @param receiver Receiver of the token to be paid out
    /// @param unwrapToNative If true wrapped ether gets unwrapped before being sent out
    function _payOutToken(uint256 collectedAmount, uint256 fee, address token, address receiver, bool unwrapToNative) internal {
        if(collectedAmount > 0) {
            if (unwrapToNative && token == address(weth9)) {
                weth9.withdraw(collectedAmount);
                UniswapTransferHelper.safeTransferETH(receiver, collectedAmount - fee);
            } else {
                UniswapTransferHelper.safeTransfer(token, receiver, collectedAmount - fee);
            }
        }
        if(fee > 0) {
            // calculate reward for address who closed position
            uint256 reward = (fee * currentStopPositionReward)/100;
            if (unwrapToNative && token == address(weth9)) {
                UniswapTransferHelper.safeTransferETH(protocolFeeReceiver, fee - reward);
            } else {
                UniswapTransferHelper.safeTransfer(token, protocolFeeReceiver, fee - reward);
            }
            if(reward > 0) {
                if (unwrapToNative && token == address(weth9)) {
                    UniswapTransferHelper.safeTransferETH(msg.sender, reward);
                } else {
                    UniswapTransferHelper.safeTransfer(token, msg.sender, reward);
                }    
            }
        }
    }


    // @dev Escape hatch for any eth stranded in the contract. Only callable by operator.
    function retrieveEth() external onlyOperator returns(bool){
        return protocolFeeReceiver.send(address(this).balance);
    }

    // @dev Escape hatch to retrieve ERC20s stranded in the contract. Only callable by operator.
    function retrieveERC20(address token) external onlyOperator {
        IERC20 erc20 = IERC20(token);
        UniswapTransferHelper.safeTransfer(token, protocolFeeReceiver, erc20.balanceOf(address(this)));
    }

    // @dev receive function to be able to receive ether on contract 
    receive() external payable { }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INonfungiblePositionManager is IERC721 {
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

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;
pragma abicoder v2;

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;
pragma abicoder v2;

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

pragma solidity >=0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.6;

import "contracts/interfaces/uniswap/IWETH9.sol";

// File @uniswap/v3-periphery/contracts/libraries/[email protected]
//
library UniswapTransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    // @notice Transfers tokens from msg.sender to a recipient
    // @dev Errors with ST if transfer fails
    // @param token The contract address of the token which will be transferred
    // @param to The recipient of the transfer
    // @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    // @notice Approves the stipulated contract to spend the given allowance in the given token
    // @dev Errors with "SA" if transfer fails
    // @param token The contract address of the token to be approved
    // @param to The target of the approval
    // @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
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