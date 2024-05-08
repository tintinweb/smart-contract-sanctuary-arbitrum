// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "ReentrancyGuard.sol";
import "AccessControl.sol";
import "SafeERC20.sol";
import "draft-IERC20Permit.sol";
import "InterfacesUD.sol";
import "ECDSA.sol";
import "Validator.sol";

/**
 * @author Heisenberg
 * @notice Buffer Options Router Contract
 */
contract BufferRouterUD is AccessControl, IBufferRouterUD {
    using SafeERC20 for ERC20;
    uint16 public constant MAX_DELAY_FOR_OPEN_TRADE = 1 minutes;
    uint64 public constant MAXIMUM_PRICE_DELAY_FOR_RESOLVING = 5 seconds;
    uint64 public constant QUEUE_TIME_LAG = 3 seconds;

    uint256 public lastSavedQueueId = 0;
    address public sfPublisher;
    address public spreadPublisher;
    address public admin;
    IAccountRegistrar public accountRegistrar;
    IPyth public pyth;

    mapping(uint256 => QueuedTrade) public queuedTrades;
    mapping(address => bool) public contractRegistry;
    mapping(address => bool) public isKeeper;
    mapping(bytes => bool) public prevSignature;
    mapping(address => mapping(uint256 => uint256)) public optionIdMapping;
    mapping(uint256 => QueueIdInfo) public queueIdInfo;
    constructor(
        address _sfPublisher,
        address _spreadPublisher,
        address _admin,
        address _accountRegistrar,
        IPyth _pyth
    ) {
        pyth = _pyth;
        sfPublisher = _sfPublisher;
        spreadPublisher = _spreadPublisher;
        admin = _admin;
        accountRegistrar = IAccountRegistrar(_accountRegistrar);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /************************************************
     *  ADMIN ONLY FUNCTIONS
     ***********************************************/

    function setContractRegistry(
        address targetContract,
        bool register
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractRegistry[targetContract] = register;

        emit ContractRegistryUpdated(targetContract, register);
    }

    function setKeeper(
        address _keeper,
        bool _isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isKeeper[_keeper] = _isActive;
    }

    /************************************************
     *  KEEPER ONLY FUNCTIONS
     ***********************************************/

    function approveViaSignature(
        address tokenX,
        address user,
        uint256 queueId,
        Permit memory permit
    ) internal returns (bool) {
        IERC20Permit token = IERC20Permit(tokenX);
        uint256 nonceBefore = token.nonces(user);
        try
            token.permit(
                user,
                address(this),
                permit.value,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            )
        {} catch Error(string memory reason) {
            emit FailResolve(queueId, reason);
            return false;
        }
        uint256 nonceAfter = token.nonces(user);
        if (nonceAfter != nonceBefore + 1) {
            emit FailResolve(queueId, "Router: Permit did not succeed");
            return false;
        }
        emit ApproveRouter(
            user,
            nonceBefore,
            permit.value,
            permit.deadline,
            tokenX
        );
        return true;
    }

    function revokeApprovals(RevokeParams[] calldata revokeParams) external {
        for (uint256 index = 0; index < revokeParams.length; index++) {
            RevokeParams memory params = revokeParams[index];
            IERC20Permit token = IERC20Permit(params.tokenX);
            uint256 nonceBefore = token.nonces(params.user);
            try
                token.permit(
                    params.user,
                    address(this),
                    params.permit.value,
                    params.permit.deadline,
                    params.permit.v,
                    params.permit.r,
                    params.permit.s
                )
            {} catch Error(string memory reason) {
                emit FailRevoke(params.user, params.tokenX, reason);
            }
            uint256 nonceAfter = token.nonces(params.user);
            if (nonceAfter != nonceBefore + 1) {
                emit FailRevoke(
                    params.user,
                    params.tokenX,
                    "Router: Permit did not succeed"
                );
            }
            emit RevokeRouter(
                params.user,
                nonceBefore,
                params.permit.value,
                params.permit.deadline,
                params.tokenX
            );
        }
    }

    function initiateTrade(TradeParamsV2 calldata params) external {
        if (!contractRegistry[params.targetContract]) {
            revert("Router: Unauthorized contract");
        }
        IOptionsConfigUD config = IOptionsConfigUD(
            IBufferBinaryOptionsUD(params.targetContract).config()
        );
        // Transfer platform fee
        ERC20 tokenX = ERC20(
            IBufferBinaryOptionsUD(params.targetContract).tokenX()
        );
        tokenX.safeTransferFrom(msg.sender, admin, config.platformFee());
        lastSavedQueueId += 1;

        queuedTrades[lastSavedQueueId] = QueuedTrade({
            user: msg.sender,
            targetContract: params.targetContract,
            strike: params.strike,
            slippage: params.slippage,
            period: params.period,
            allowPartialFill: params.allowPartialFill,
            totalFee: params.totalFee,
            referralCode: params.referralCode,
            settlementFee: params.settlementFee,
            isTradeResolved: false,
            isEarlyCloseAllowed: config.isEarlyCloseAllowed(),
            isAbove: params.isAbove,
            limitOrder: params.limitOrder,
            queueTime: block.timestamp + QUEUE_TIME_LAG
        });

        emit InitiateTrade(
            msg.sender,
            lastSavedQueueId,
            params.targetContract,
            params.strike,
            params.slippage,
            params.period,
            params.allowPartialFill,
            params.totalFee,
            params.referralCode,
            params.settlementFee,
            params.isAbove
        );
    }

    function openTrades(OpenTxn[] calldata params) external payable {
        _validateKeeper();
        for (uint32 index = 0; index < params.length; index++) {
            TradeParams memory currentParams = params[index].tradeParams;
            lastSavedQueueId = currentParams.queueId;
            address user = params[index].user;
            IBufferBinaryOptionsUD optionsContract = IBufferBinaryOptionsUD(
                currentParams.targetContract
            );
            IOptionsConfigUD config = IOptionsConfigUD(
                optionsContract.config()
            );
            ERC20 tokenX = ERC20(optionsContract.tokenX());
            Permit memory permit = params[index].permit;
            uint256 amountToPay = currentParams.totalFee + config.platformFee();
            if (tokenX.balanceOf(user) < amountToPay) {
                emit FailResolve(
                    currentParams.queueId,
                    "Router: Insufficient balance"
                );
                continue;
            }
            if (
                ((tokenX.allowance(user, address(this)) < amountToPay) &&
                    (!permit.shouldApprove)) ||
                ((tokenX.allowance(user, address(this)) + permit.value) <
                    amountToPay)
            ) {
                emit FailResolve(
                    currentParams.queueId,
                    "Router: Incorrect allowance"
                );
                continue;
            } else if (permit.shouldApprove) {
                bool success = approveViaSignature(
                    address(optionsContract.tokenX()),
                    user,
                    currentParams.queueId,
                    permit
                );
                if (!success) continue;
            }
            if (params[index].register.shouldRegister) {
                try
                    accountRegistrar.registerAccount(
                        params[index].register.oneCT,
                        user,
                        params[index].register.signature
                    )
                {} catch Error(string memory reason) {
                    emit FailResolve(
                        currentParams.queueId,
                        "Router: Registration failed"
                    );
                    continue;
                }
            }
            (address signer, uint256 nonce) = getAccountMapping(user);
            (bool isValid, string memory errorResaon) = verifyTrade(
                currentParams,
                user,
                signer,
                optionsContract
            );
            if (!isValid) {
                emit FailResolve(currentParams.queueId, errorResaon);
                continue;
            }
            queuedTrades[currentParams.queueId] = QueuedTrade({
                user: user,
                targetContract: currentParams.targetContract,
                strike: currentParams.strike,
                slippage: currentParams.slippage,
                period: currentParams.period,
                allowPartialFill: currentParams.allowPartialFill,
                totalFee: currentParams.totalFee,
                referralCode: currentParams.referralCode,
                settlementFee: currentParams.userSignedSettlementFee,
                isTradeResolved: false,
                isEarlyCloseAllowed: config.isEarlyCloseAllowed(),
                isAbove: currentParams.isAbove,
                limitOrder: currentParams.limitOrder,
                queueTime: currentParams.queueTime
            });
            tokenX.safeTransferFrom(user, admin, config.platformFee());
            prevSignature[currentParams.userSignInfo.signature] = true;
            // Transfer Platform fee
            resolveTrade(
                currentParams.queueId,
                ResolveParams({
                    spread: currentParams.spread,
                    settlementFee: currentParams.settlementFee,
                    settlementFeeSignInfo: currentParams.settlementFeeSignInfo,
                    spreadSignInfo: currentParams.spreadSignInfo,
                    priceUpdateData: currentParams.priceUpdateData,
                    priceIds: currentParams.priceIds,
                    limitOrderOpenTime: currentParams
                        .limitOrder
                        .limitOrderOpenTime
                })
            );
        }
    }
    function closeAnytime(
        CloseAnytimeParams[] calldata closeParams
    ) external payable {
        _validateKeeper();
        for (uint32 index = 0; index < closeParams.length; index++) {
            CloseAnytimeParams memory closeParam = closeParams[index];
            CloseTradeParams memory params = closeParam.closeTradeParams;
            IBufferBinaryOptionsUD optionsContract = IBufferBinaryOptionsUD(
                params.targetContract
            );

            QueuedTrade memory queuedTrade = queuedTrades[
                optionIdMapping[params.targetContract][params.optionId]
            ];
            address owner = optionsContract.ownerOf(params.optionId);
            (, , , , , , , uint256 createdAt, ) = optionsContract.options(
                params.optionId
            );
            if (closeParam.register.shouldRegister) {
                try
                    accountRegistrar.registerAccount(
                        closeParam.register.oneCT,
                        owner,
                        closeParam.register.signature
                    )
                {} catch Error(string memory reason) {
                    emit FailUnlock(
                        params.optionId,
                        params.targetContract,
                        reason
                    );
                    continue;
                }
            }
            if (
                !queuedTrade.isEarlyCloseAllowed ||
                (block.timestamp - createdAt <
                    IOptionsConfigUD(optionsContract.config())
                        .earlyCloseThreshold())
            ) {
                emit FailUnlock(
                    params.optionId,
                    params.targetContract,
                    "Router: Early close is not allowed"
                );
                continue;
            }
            (address signer, ) = getAccountMapping(queuedTrade.user);

            bool isUserSignValid = Validator.verifyCloseAnytime(
                optionsContract.assetPair(),
                closeParam.userSignInfo.timestamp,
                params.optionId,
                closeParam.userSignInfo.signature,
                signer
            );

            if (!isUserSignValid) {
                emit FailUnlock(
                    params.optionId,
                    params.targetContract,
                    "Router: User signature didn't match"
                );
                continue;
            }
            uint256 priceAtExpiry = getPrice(
                params.closingTime,
                params.priceUpdateData,
                params.priceIds
            );
            try
                optionsContract.unlock(
                    params.optionId,
                    priceAtExpiry,
                    params.closingTime
                )
            {} catch Error(string memory reason) {
                emit FailUnlock(params.optionId, params.targetContract, reason);
                continue;
            }
        }
    }

    function executeOptions(
        CloseTradeParams[] calldata optionData
    ) external payable {
        _validateKeeper();

        uint32 arrayLength = uint32(optionData.length);
        for (uint32 i = 0; i < arrayLength; i++) {
            CloseTradeParams memory params = optionData[i];

            IBufferBinaryOptionsUD optionsContract = IBufferBinaryOptionsUD(
                params.targetContract
            );
            (, , , , , uint256 expiration, , , ) = optionsContract.options(
                params.optionId
            );

            QueuedTrade memory queuedTrade = queuedTrades[
                optionIdMapping[params.targetContract][params.optionId]
            ];

            if (expiration > block.timestamp) {
                emit FailUnlock(
                    params.optionId,
                    params.targetContract,
                    "Router: Wrong closing time"
                );
                continue;
            }
            uint256 priceAtExpiry = getPrice(
                expiration,
                params.priceUpdateData,
                params.priceIds
            );
            try
                optionsContract.unlock(
                    params.optionId,
                    priceAtExpiry,
                    expiration
                )
            {} catch Error(string memory reason) {
                emit FailUnlock(params.optionId, params.targetContract, reason);
                continue;
            }
        }
    }

    function getPrice(
        uint256 timestamp,
        bytes[] memory priceUpdateData,
        bytes32[] memory priceId
    ) public returns (uint256) {
        IPyth.PriceFeed[] memory prices = pyth.parsePriceFeedUpdates{
            value: pyth.getUpdateFee(priceUpdateData)
        }(
            priceUpdateData,
            priceId,
            uint64(timestamp),
            uint64(timestamp + MAXIMUM_PRICE_DELAY_FOR_RESOLVING)
        );
        // Doubt: Should maxPublishTime and minPublishTime be the reversed?

        IPyth.Price memory price = prices[0].price;

        require(price.price > 0, "invalid price");
        return uint256(int256(price.price));
    }
    /************************************************
     *  INTERNAL FUNCTIONS
     ***********************************************/
    function _validateKeeper() private view {
        require(isKeeper[msg.sender], "Keeper: forbidden");
    }

    function getAccountMapping(
        address user
    ) public view returns (address, uint256) {
        (address oneCT, uint256 nonce) = accountRegistrar.accountMapping(user);
        return (oneCT, nonce);
    }

    function getSafeStrike(
        uint256 strike,
        bool isAbove,
        uint256 spread
    ) public view returns (uint256) {
        return
            isAbove
                ? (strike * (1e8 + spread)) / 1e8
                : (strike * (1e8 - spread)) / 1e8;
    }

    function verifyTrade(
        TradeParams memory params,
        address user,
        address tradeSigner,
        IBufferBinaryOptionsUD optionsContract
    ) internal view returns (bool, string memory) {
        SignInfo memory userSignInfo = params.userSignInfo;

        if (!contractRegistry[params.targetContract]) {
            return (false, "Router: Unauthorized contract");
        }
        if (queuedTrades[params.queueId].isTradeResolved) {
            return (false, "Router: Trade has already been opened");
        }
        if (prevSignature[userSignInfo.signature]) {
            return (false, "Router: Signature already used");
        }
        if (!Validator.verifyUserTradeParamsUD(params, user, tradeSigner)) {
            return (false, "Router: User signature didn't match");
        }

        if (!params.limitOrder.isLimitOrder) {
            if (
                block.timestamp - userSignInfo.timestamp >
                MAX_DELAY_FOR_OPEN_TRADE
            ) {
                return (false, "Router: Invalid user signature timestamp");
            }
            if (params.settlementFee != params.userSignedSettlementFee) {
                return (false, "Router: Settlement fee is not valid");
            }
        } else {
            if (params.settlementFee > params.userSignedSettlementFee) {
                return (false, "Router: Settlement fee is not valid");
            }
        }

        return (true, "");
    }

    function _verifySigners(
        ResolveParams memory params,
        QueuedTrade memory queuedTrade,
        IBufferBinaryOptionsUD optionsContract,
        uint256 safeStrike
    ) internal view returns (bool, string memory) {
        SignInfo memory settlementFeeSignInfo = params.settlementFeeSignInfo;
        SignInfo memory spreadSignInfo = params.spreadSignInfo;

        if (
            !Validator.verifySettlementFee(
                optionsContract.assetPair(),
                params.settlementFee,
                settlementFeeSignInfo.timestamp,
                settlementFeeSignInfo.signature,
                sfPublisher
            )
        ) {
            return (false, "Router: Wrong settlement fee");
        }
        if (
            !Validator.verifySpread(
                optionsContract.assetPair(),
                params.spread,
                spreadSignInfo.timestamp,
                spreadSignInfo.signature,
                spreadPublisher
            )
        ) {
            return (false, "Router: Wrong spread");
        }

        if (settlementFeeSignInfo.timestamp < block.timestamp) {
            return (false, "Router: Settlement fee has expired");
        }

        if (spreadSignInfo.timestamp < block.timestamp) {
            return (false, "Router: Spread has expired");
        }

        if (
            !optionsContract.isStrikeValid(
                queuedTrade.slippage,
                safeStrike,
                queuedTrade.strike
            )
        ) {
            return (false, "Router: Slippage limit exceeded");
        }

        return (true, "");
    }

    function resolveTrade(
        uint256 queueId,
        ResolveParams memory params
    ) public payable {
        _validateKeeper();
        if (queuedTrades[queueId].isTradeResolved) {
            emit FailResolve(queueId, "Router: Trade has already been opened");
            return;
        }
        QueuedTrade memory queuedTrade = queuedTrades[queueId];
        IBufferBinaryOptionsUD optionsContract = IBufferBinaryOptionsUD(
            queuedTrade.targetContract
        );
        LimitOrder memory limitOrder = queuedTrade.limitOrder;

        if (
            limitOrder.isLimitOrder &&
            block.timestamp > limitOrder.limitOrderExpiry
        ) {
            emit FailResolve(
                queueId,
                "Router: Limit order has already expired"
            );
            return;
        }
        if (
            !limitOrder.isLimitOrder &&
            block.timestamp - queuedTrade.queueTime > MAX_DELAY_FOR_OPEN_TRADE
        ) {
            emit FailResolve(queueId, "Router: Wait time too high");
            return;
        }

        uint256 safeStrike = getSafeStrike(
            getPrice(
                limitOrder.isLimitOrder
                    ? params.limitOrderOpenTime
                    : queuedTrade.queueTime,
                params.priceUpdateData,
                params.priceIds
            ),
            queuedTrade.isAbove,
            params.spread
        );

        (bool isValid, string memory errorResaon) = _verifySigners(
            params,
            queuedTrade,
            optionsContract,
            safeStrike
        );

        if (!isValid) {
            emit FailResolve(queueId, errorResaon);
            return;
        }
        // Check all the parameters and compute the amount and revised fee
        uint256 amount;
        uint256 revisedFee;
        IBufferBinaryOptionsUD.OptionParams
            memory optionParams = IBufferBinaryOptionsUD.OptionParams(
                safeStrike,
                0,
                queuedTrade.period,
                queuedTrade.allowPartialFill,
                queuedTrade.totalFee,
                queuedTrade.user,
                queuedTrade.referralCode,
                queuedTrade.settlementFee,
                queuedTrade.isAbove
            );

        try
            optionsContract.evaluateParams(optionParams, queuedTrade.slippage)
        returns (uint256 _amount, uint256 _revisedFee) {
            (amount, revisedFee) = (_amount, _revisedFee);
        } catch Error(string memory reason) {
            emit CancelTrade(queuedTrade.user, queueId, reason);
            return;
        }

        // Transfer the fee specified from the user to options contract.
        // User has to approve first inorder to execute this function
        ERC20 tokenX = ERC20(optionsContract.tokenX());

        tokenX.safeTransferFrom(
            queuedTrade.user,
            queuedTrade.targetContract,
            revisedFee
        );

        optionParams.strike = safeStrike;
        optionParams.amount = amount;
        optionParams.totalFee = revisedFee;

        uint256 optionId = optionsContract.createFromRouter(
            optionParams,
            limitOrder.isLimitOrder
                ? params.limitOrderOpenTime
                : queuedTrade.queueTime
        );

        queuedTrades[queueId].isTradeResolved = true;
        queueIdInfo[queueId] = QueueIdInfo({
            optionId: optionId,
            targetContract: queuedTrade.targetContract
        });
        optionIdMapping[queuedTrade.targetContract][optionId] = queueId;
        emit OpenTrade(
            queuedTrade.user,
            queueId,
            optionId,
            queuedTrade.targetContract
        );
    }

    function adminWithdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
import "ERC20.sol";
import "Interfaces.sol";
pragma solidity 0.8.4;

interface IBufferRouterUD {
    struct QueuedTrade {
        address user;
        uint256 totalFee;
        uint256 period;
        address targetContract;
        uint256 strike;
        uint256 slippage;
        bool allowPartialFill;
        string referralCode;
        uint256 settlementFee;
        LimitOrder limitOrder;
        bool isTradeResolved;
        bool isEarlyCloseAllowed;
        bool isAbove;
        uint256 queueTime;
    }

    struct QueueIdInfo {
        address targetContract;
        uint256 optionId;
    }

    struct OptionInfo {
        uint256 queueId;
        address signer;
        uint256 nonce;
    }

    struct SignInfo {
        bytes signature;
        uint256 timestamp;
    }

    struct LimitOrder {
        bool isLimitOrder;
        uint256 limitOrderExpiry;
        uint256 limitOrderOpenTime;
    }

    struct TradeParams {
        uint256 queueId;
        uint256 totalFee;
        uint256 period;
        address targetContract;
        uint256 strike;
        uint256 slippage;
        bool allowPartialFill;
        string referralCode;
        bool isAbove;
        uint256 settlementFee;
        LimitOrder limitOrder;
        uint256 userSignedSettlementFee;
        uint256 spread;
        uint256 queueTime;
        SignInfo settlementFeeSignInfo;
        SignInfo userSignInfo;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
        SignInfo spreadSignInfo;
    }

    struct TradeParamsV2 {
        uint256 totalFee;
        uint256 period;
        address targetContract;
        uint256 strike;
        uint256 slippage;
        bool allowPartialFill;
        string referralCode;
        bool isAbove;
        uint256 settlementFee;
        LimitOrder limitOrder;
    }
    struct ResolveParams {
        uint256 settlementFee;
        uint256 spread;
        SignInfo settlementFeeSignInfo;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
        SignInfo spreadSignInfo;
        uint256 limitOrderOpenTime;
    }
    struct Register {
        address oneCT;
        bytes signature;
        bool shouldRegister;
    }

    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool shouldApprove;
    }
    struct RevokeParams {
        address tokenX;
        address user;
        Permit permit;
    }
    struct OpenTxn {
        TradeParams tradeParams;
        Register register;
        Permit permit;
        address user;
    }

    struct AccountMapping {
        address oneCT;
        uint256 nonce;
    }

    struct CloseTradeParams {
        uint256 optionId;
        address targetContract;
        uint256 closingTime;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
    }

    struct CloseAnytimeParams {
        CloseTradeParams closeTradeParams;
        Register register;
        SignInfo userSignInfo;
    }

    struct IdMapping {
        uint256 id;
        bool isSet;
    }

    event OpenTrade(
        address indexed account,
        uint256 queueId,
        uint256 optionId,
        address targetContract
    );
    event CancelTrade(address indexed account, uint256 queueId, string reason);
    event FailUnlock(
        uint256 indexed optionId,
        address targetContract,
        string reason
    );
    event FailResolve(uint256 indexed queueId, string reason);
    event FailRevoke(address indexed user, address tokenX, string reason);
    event ContractRegistryUpdated(address targetContract, bool register);
    event ApproveRouter(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );
    event RevokeRouter(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );

    event InitiateTrade(
        address indexed user,
        uint256 queueId,
        address targetContract,
        uint256 strike,
        uint256 slippage,
        uint256 period,
        bool allowPartialFill,
        uint256 totalFee,
        string referralCode,
        uint256 settlementFee,
        bool isAbove
    );
}

interface IBufferBinaryOptionsUD {
    event Create(
        address indexed account,
        uint256 indexed id,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(
        address indexed account,
        uint256 indexed id,
        uint256 profit,
        uint256 priceAtExpiration,
        bool isAbove
    );
    event Expire(
        uint256 indexed id,
        uint256 premium,
        uint256 priceAtExpiration,
        bool isAbove
    );
    event Pause(bool isPaused);
    event UpdateReferral(
        address user,
        address referrer,
        bool isReferralValid,
        uint256 totalFee,
        uint256 referrerFee,
        uint256 rebate,
        string referralCode
    );

    event LpProfit(uint256 indexed id, uint256 amount);
    event LpLoss(uint256 indexed id, uint256 amount);

    function createFromRouter(
        OptionParams calldata optionParams,
        uint256 queuedTime
    ) external returns (uint256 optionID);

    function evaluateParams(
        OptionParams calldata optionParams,
        uint256 slippage
    ) external returns (uint256 amount, uint256 revisedFee);

    function tokenX() external view returns (ERC20);

    function pool() external view returns (ILiquidityPool);

    function config() external view returns (IOptionsConfigUD);

    function token0() external view returns (string memory);

    function token1() external view returns (string memory);

    function ownerOf(uint256 id) external view returns (address);

    function assetPair() external view returns (string memory);

    function totalMarketOI() external view returns (uint256);

    function getMaxOI() external view returns (uint256);

    function fees(
        uint256 amount,
        address user,
        string calldata referralCode,
        uint256 baseSettlementFeePercent
    )
        external
        view
        returns (uint256 total, uint256 settlementFee, uint256 premium);

    function isStrikeValid(
        uint256 slippage,
        uint256 currentPrice,
        uint256 strike
    ) external pure returns (bool);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }

    enum AssetCategory {
        Forex,
        Crypto,
        Commodities
    }
    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    event CreateOptionsContract(
        address config,
        address pool,
        address tokenX,
        string token0,
        string token1,
        AssetCategory category
    );
    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        uint256 totalFee;
        uint256 createdAt;
        bool isAbove;
    }
    struct OptionParams {
        uint256 strike;
        uint256 amount;
        uint256 period;
        bool allowPartialFill;
        uint256 totalFee;
        address user;
        string referralCode;
        uint256 baseSettlementFeePercentage;
        bool isAbove;
    }

    function options(
        uint256 optionId
    )
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            uint256 totalFee,
            uint256 createdAt,
            bool isAbove
        );

    function unlock(
        uint256 optionID,
        uint256 priceAtExpiration,
        uint256 closingTime
    ) external;
}

interface IOptionsConfigUD {
    event UpdateMaxPeriod(uint32 value);
    event UpdateMinPeriod(uint32 value);
    event UpdateEarlyCloseThreshold(uint32 earlyCloseThreshold);
    event UpdateEarlyClose(bool isAllowed);
    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatetraderNFTContract(address value);
    event UpdateMinFee(uint256 value);
    event UpdateOptionStorageContract(address value);
    event UpdateCreationWindowContract(address value);
    event UpdatePlatformFee(uint256 _platformFee);
    event UpdatePoolOIStorageContract(address _poolOIStorageContract);
    event UpdatePoolOIConfigContract(address _poolOIConfigContract);
    event UpdateMarketOIConfigContract(address _marketOIConfigContract);
    event UpdateIV(uint32 _iv);
    event UpdateBoosterContract(address _boosterContract);
    event UpdateSpreadConfig1(uint256 spreadConfig1);
    event UpdateSpreadConfig2(uint256 spreadConfig2);
    event UpdateIVFactorITM(uint256 ivFactorITM);
    event UpdateIVFactorOTM(uint256 ivFactorOTM);
    event UpdateSpreadFactor(uint32 ivFactorOTM);
    event UpdateCircuitBreakerContract(address _circuitBreakerContract);

    function circuitBreakerContract() external view returns (address);

    function settlementFeeDisbursalContract() external view returns (address);

    function maxPeriod() external view returns (uint32);

    function minPeriod() external view returns (uint32);

    function minFee() external view returns (uint256);

    function platformFee() external view returns (uint256);

    function optionStorageContract() external view returns (address);

    function creationWindowContract() external view returns (address);

    function poolOIStorageContract() external view returns (address);

    function poolOIConfigContract() external view returns (address);

    function marketOIConfigContract() external view returns (address);

    function iv() external view returns (uint32);

    function earlyCloseThreshold() external view returns (uint32);

    function isEarlyCloseAllowed() external view returns (bool);

    function boosterContract() external view returns (address);

    function spreadConfig1() external view returns (uint256);

    function spreadConfig2() external view returns (uint256);

    function spreadFactor() external view returns (uint32);

    function getFactoredIv(bool isITM) external view returns (uint32);
}

interface IPoolOIStorage {
    function updatePoolOI(bool isIncreased, uint256 interest) external;

    function totalPoolOI() external view returns (uint256);
}

interface IPoolOIConfig {
    function getMaxPoolOI() external view returns (uint256);

    function getPoolOICap() external view returns (uint256);
}

interface IMarketOIConfig {
    function getMaxMarketOI(
        uint256 currentMarketOI
    ) external view returns (uint256);

    function getMarketOICap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
import "ERC20.sol";

pragma solidity 0.8.4;

interface IBufferBinaryOptionPauserV2_5 {
    function isPaused() external view returns (bool);

    function setIsPaused() external;
}

interface IBufferBinaryOptionPauserV2 {
    function isPaused() external view returns (bool);

    function toggleCreation() external;
}

interface ICircuitBreaker {
    struct MarketPoolPair {
        address market;
        address pool;
    }
    struct Configs {
        int256 value;
        address contractAddress;
    }
    struct OverallStats {
        address contractAddress;
        int256 loss;
        int256 sf;
        int256 lp_sf;
        int256 net_loss;
    }
    struct MarketStats {
        address pool;
        int256 loss;
        int256 sf;
    }
    struct PoolStats {
        address[] markets;
        int256 loss;
        int256 sf;
    }

    function update(int256 loss, int256 sf, uint256 option_id) external;

    event Update(
        int256 loss,
        int256 sf,
        address market,
        address pool,
        uint256 option_id
    );

    event MarketPaused(address market, address pool);
    event PoolPaused(address pool);
}

interface IBooster {
    struct UserBoostTrades {
        uint256 totalBoostTrades;
        uint256 totalBoostTradesUsed;
    }

    function getUserBoostData(
        address user,
        address token
    ) external view returns (UserBoostTrades memory);

    function updateUserBoost(address user, address token) external;

    function getBoostPercentage(
        address user,
        address token
    ) external view returns (uint256);

    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool shouldApprove;
    }
    event ApproveTokenX(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );
    event BuyCoupon(address indexed token, address indexed user, uint256 price);
    event SetPrice(uint256 couponPrice);
    event SetBoostPercentage(uint256 boost);
    event UpdateBoostTradesUser(address indexed user, address indexed token);
    event Configure(uint8[4] nftTierDiscounts);
}

interface IAccountRegistrar {
    struct AccountMapping {
        address oneCT;
        uint256 nonce;
    }
    event RegisterAccount(
        address indexed user,
        address indexed oneCT,
        uint256 nonce
    );
    event DeregisterAccount(address indexed account, uint256 nonce);

    function accountMapping(
        address
    ) external view returns (address oneCT, uint256 nonce);

    function registerAccount(
        address oneCT,
        address user,
        bytes memory signature
    ) external;
}

interface ILiquidityPool {
    struct LockedAmount {
        uint256 timestamp;
        uint256 amount;
    }
    struct ProvidedLiquidity {
        uint256 unlockedAmount;
        LockedAmount[] lockedAmounts;
        uint256 nextIndexForUnlock;
    }
    struct LockedLiquidity {
        uint256 amount;
        uint256 premium;
        bool locked;
    }
    event Profit(uint256 indexed id, uint256 amount);
    event Loss(uint256 indexed id, uint256 amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event UpdateMaxLiquidity(uint256 indexed maxLiquidity);
    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 writeAmount
    );

    function unlock(uint256 id) external;

    function totalTokenXBalance() external view returns (uint256 amount);

    function availableBalance() external view returns (uint256 balance);

    function send(uint256 id, address account, uint256 amount) external;

    function lock(uint256 id, uint256 tokenXAmount, uint256 premium) external;
}

interface ITraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateTiers(uint256[] tokenIds, uint8[] tiers, uint256[] batchIds);
}

interface IFakeTraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateNftBasePrice(uint256 nftBasePrice);
    event UpdateMaxNFTMintLimits(uint256 maxNFTMintLimit);
    event UpdateBaseURI(string baseURI);
    event Claim(address indexed account, uint256 claimTokenId);
    event Mint(address indexed account, uint256 tokenId, uint8 tier);
}

interface IReferralStorage {
    function codeOwner(string memory _code) external view returns (address);

    function traderReferralCodes(address) external view returns (string memory);

    function getTraderReferralInfo(
        address user
    ) external view returns (string memory, address);

    function setTraderReferralCode(address user, string memory _code) external;

    function setReferrerTier(address, uint8) external;

    function referrerTierStep(
        uint8 referralTier
    ) external view returns (uint8 step);

    function referrerTierDiscount(
        uint8 referralTier
    ) external view returns (uint32 discount);

    function referrerTier(address referrer) external view returns (uint8 tier);

    struct ReferrerData {
        uint256 tradeVolume;
        uint256 rebate;
        uint256 trades;
    }

    struct ReferreeData {
        uint256 tradeVolume;
        uint256 rebate;
    }

    struct ReferralData {
        ReferrerData referrerData;
        ReferreeData referreeData;
    }

    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    event UpdateTraderReferralCode(address indexed account, string code);
    event UpdateReferrerTier(address referrer, uint8 tierId);
    event RegisterCode(address indexed account, string code);
    event SetCodeOwner(
        address indexed account,
        address newAccount,
        string code
    );
}

interface IOptionStorage {
    function save(
        uint256 optionId,
        address optionsContract,
        address user
    ) external;
}

interface ICreationWindowContract {
    function isInCreationWindow(uint256 period) external view returns (bool);
}

interface IPyth {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory priceFeeds);

    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}
interface IIncentivePool {
    // Events
    event Withdrawal(address indexed token, address to, uint256 amount);

    event JackpotTriggered(
        address indexed userAddress,
        uint256 jackpotWinAmount,
        address indexed optionContract,
        uint256 amount,
        address indexed router,
        uint256 optionId
    );
    event UpdateIncentivePoolPercentForJackpot(
        uint256 _incentivePoolPercentForJackpot
    );
    event UpdateMinBetSizeForJackpot(
        address indexed token,
        uint256 _minBetSizeForJackpot
    );
    event UpdateMaxJackpotWinPercentForUser(
        uint256 _maxJackpotWinPercentForUser
    );
    event UpdateIncentivePercentForWager(uint256 _incentivePercentForWager);
    event UpdateMinWinningsForTransfer(
        address indexed token,
        uint256 _minWinningsForTransfer
    );
    event UpdateJackpotToken(address indexed token);
    event UpdateKeyHash(bytes32 keyHash);

    function executeIncentives(
        address userAddress,
        uint256 amount,
        address optionContract,
        uint256 optionId,
        address router,
        address tokenAddress
    ) external returns (uint256 jackpotWinAmount);

    function minBetSizeForJackpot(address) external view returns (uint256);
    function jackpotToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import "ECDSA.sol";
import "SignatureChecker.sol";
import "InterfacesUD.sol";
import "InterfacesAB.sol";

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same,there is no
 * need to store it,thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library Validator {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    function domainSperator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Validator")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _validate(
        bytes32 hashData,
        bytes memory expectedSignature,
        address expectedSigner
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSperator(), hashData)
        );
        return
            SignatureChecker.isValidSignatureNow(
                expectedSigner,
                digest,
                expectedSignature
            );
    }

    function verifyUserTradeParamsUD(
        IBufferRouterUD.TradeParams memory params,
        address user,
        address signer
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256(
                    "UserTradeSignatureWithSettlementFee(address user,uint256 totalFee,uint256 period,address targetContract,uint256 strike,uint256 slippage,bool allowPartialFill,string referralCode,uint256 timestamp,uint256 settlementFee,bool isAbove)"
                ),
                user,
                params.totalFee,
                params.period,
                params.targetContract,
                params.strike,
                params.slippage,
                params.allowPartialFill,
                keccak256(bytes(params.referralCode)),
                params.userSignInfo.timestamp,
                params.userSignedSettlementFee,
                params.isAbove
            )
        );

        return _validate(hashData, params.userSignInfo.signature, signer);
    }

    function verifyUserTradeParamsAB(
        IBufferRouterAB.TradeInitiationParamas memory params,
        address user,
        address signer,
        IBufferRouterAB.SignInfo memory userSignInfo
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256(
                    "UserTradeSignature(address user,address targetContract,uint32 expiration,uint256 totalFee,uint256 strike,bool isAbove,uint256 maxFeePerContract,bool allowPartialFill,string referralCode,uint256 timestamp)"
                ),
                user,
                params.targetContract,
                params.expiration,
                params.totalFee,
                params.strike,
                params.isAbove,
                params.maxFeePerContract,
                params.allowPartialFill,
                keccak256(bytes(params.referralCode)),
                userSignInfo.timestamp
            )
        );

        return _validate(hashData, userSignInfo.signature, signer);
    }

    function verifyCloseAnytime(
        string memory assetPair,
        uint256 timestamp,
        uint256 optionId,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256(
                    "CloseAnytimeSignature(string assetPair,uint256 timestamp,uint256 optionId)"
                ),
                keccak256(bytes(assetPair)),
                timestamp,
                optionId
            )
        );
        return _validate(hashData, signature, signer);
    }

    function verifySettlementFee(
        string memory assetPair,
        uint256 settlementFee,
        uint256 expiryTimestamp,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256(
                    "SettlementFeeSignature(string assetPair,uint256 expiryTimestamp,uint256 settlementFee)"
                ),
                keccak256(bytes(assetPair)),
                expiryTimestamp,
                settlementFee
            )
        );
        return _validate(hashData, signature, signer);
    }

    function verifySpread(
        string memory assetPair,
        uint256 spread,
        uint256 expiryTimestamp,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256(
                    "SpreadSignature(string assetPair,uint256 expiryTimestamp,uint256 spread)"
                ),
                keccak256(bytes(assetPair)),
                expiryTimestamp,
                spread
            )
        );
        return _validate(hashData, signature, signer);
    }

    function verifyUserRegistration(
        address oneCT,
        address user,
        uint256 nonce,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256(
                    "RegisterAccount(address oneCT,address user,uint256 nonce)"
                ),
                oneCT,
                user,
                nonce
            )
        );
        return _validate(hashData, signature, user);
    }

    function verifyUserDeregistration(
        address user,
        uint256 nonce,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encode(
                keccak256("DeregisterAccount(address user,uint256 nonce)"),
                user,
                nonce
            )
        );
        return _validate(hashData, signature, user);
    }
    function verifyIv(
        string memory assetPair,
        uint256 timestamp,
        uint256 iv,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        bytes32 hashData = keccak256(
            abi.encodePacked(assetPair, timestamp, iv)
        );
        bytes32 digest = ECDSA.toEthSignedMessageHash(hashData);
        return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "ECDSA.sol";
import "Address.sol";
import "IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: BUSL-1.1
import "ERC20.sol";
import "Interfaces.sol";

pragma solidity 0.8.4;
interface IApprovals {
    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool shouldApprove;
    }
    struct RevokeParams {
        address tokenX;
        address user;
        Permit permit;
    }
    event FailRevoke(address indexed user, address tokenX, string reason);
    event ApproveRouter(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );
    event RevokeRouter(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );
}
interface IBufferRouterAB is IApprovals {
    struct QueuedTrade {
        address user;
        address targetContract;
        uint128 strike;
        uint32 expiration;
        uint256 contracts;
        bool allowPartialFill;
        bool isQueued;
        uint256 optionId;
        bool isAbove;
        uint32 queueTimestamp;
        uint256 maxFeePerContract;
        string referralCode;
        uint256 totalFee;
    }

    struct OptionInfo {
        uint256 queueId;
        address signer;
        uint256 nonce;
    }
    struct Register {
        address oneCT;
        bytes signature;
        bool shouldRegister;
    }

    struct SignInfo {
        bytes signature;
        uint32 timestamp;
    }
    struct TradeInitiationParamas {
        address targetContract;
        bool allowPartialFill;
        string referralCode;
        bool isAbove;
        uint256 totalFee;
        uint128 strike;
        uint32 expiration;
        uint256 maxFeePerContract;
    }

    struct ResolveTradeParams {
        uint256 iv;
        uint256 sf;
        SignInfo publisherSignInfo;
        SignInfo sfSignInfo;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
    }

    struct TradeInitiationParamsV2 {
        uint256 queueId;
        uint32 queueTimestamp;
        TradeInitiationParamas tradeInitiationParamas;
        SignInfo userSignInfo;
        Register register;
        Permit permit;
        address user;
        ResolveTradeParams resolveTradeParams;
    }

    struct CloseTradeParams {
        uint256 optionId;
        address targetContract;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
    }

    struct IdMapping {
        uint256 id;
        bool isSet;
    }

    event OpenTrade(
        address indexed user,
        uint256 indexed queueId,
        uint256 indexed optionId,
        address targetContract
    );
    event CancelTrade(
        address indexed account,
        uint256 queueId,
        string reason,
        address targetContract
    );
    event FailUnlock(
        uint256 indexed optionId,
        address targetContract,
        string reason
    );
    event FailResolve(uint256 indexed queueId, string reason);
    event ContractRegistryUpdated(address targetContract, bool register);

    event InitiateTrade(
        address indexed user,
        uint256 queueId,
        uint256 timestamp,
        address targetContract,
        bool isAbove,
        uint128 strike,
        uint256 contracts,
        uint32 expiration,
        uint256 maxFeePerContract
    );
}

interface IBufferBinaryOptionsAB {
    event Create(
        address indexed account,
        uint256 indexed id,
        uint256 settlementFee,
        uint256 totalFee,
        int256 skew,
        bytes32 marketId,
        uint256 amount
    );
    event CreateMarket(
        uint128 strike,
        uint32 expiration,
        bytes32 marketId,
        address optionsContract
    );

    event Exercise(
        address indexed account,
        uint256 indexed id,
        uint256 profit,
        uint256 priceAtExpiration,
        bool isAbove
    );
    event Expire(
        uint256 indexed id,
        uint256 premium,
        uint256 priceAtExpiration,
        bool isAbove
    );
    event Pause(bool isPaused);
    event UpdateReferral(
        address user,
        address referrer,
        bool isReferralValid,
        uint256 totalFee,
        uint256 referrerFee,
        uint256 rebate,
        string referralCode
    );

    event LpProfit(uint256 indexed id, uint256 amount);
    event LpLoss(uint256 indexed id, uint256 amount);

    function createFromRouter(
        OptionParams calldata optionParams,
        uint32 queueTimestamp
    ) external returns (uint256 optionID);

    function evaluateParams(
        OptionParams calldata optionParams
    ) external view returns (RevisedData memory revisedData);

    function tokenX() external view returns (ERC20);

    function pool() external view returns (ILiquidityPool);

    function config() external view returns (IOptionsConfigAB);

    function token0() external view returns (string memory);

    function token1() external view returns (string memory);

    function ownerOf(uint256 id) external view returns (address);

    function assetPair() external view returns (string memory);

    function totalMarketOI() external view returns (uint256);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }

    enum AssetCategory {
        Forex,
        Crypto,
        Commodities
    }
    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    event CreateOptionsContract(
        address config,
        address pool,
        address tokenX,
        string token0,
        string token1,
        AssetCategory category
    );
    struct Option {
        State state;
        uint128 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint32 expiration;
        uint256 totalFee;
        uint32 createdAt;
        bool isAbove;
    }
    struct OptionParams {
        address user;
        uint256 sf;
        uint256 iv;
        bool allowPartialFill;
        bool isAbove;
        uint256 contracts;
        uint128 strike;
        uint32 expiration;
        uint256 amount;
        uint256 totalFee;
        uint256 maxFeePerContract;
        uint256 currentPrice;
        string referralCode;
    }

    struct RevisedData {
        uint256 amount;
        uint256 fee;
        uint256 revisedContracts;
        uint256 revisedSf;
    }
    function options(
        uint256 optionId
    )
        external
        view
        returns (
            State state,
            uint128 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint32 expiration,
            uint256 totalFee,
            uint32 createdAt,
            bool isAbove
        );

    function unlock(uint256 optionID, uint256 closingPrice) external;

    function runInitialChecks(uint128 strike, uint32 expiration) external;
}

interface IOptionsConfigAB {
    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatetraderNFTContract(address value);
    event UpdateOptionStorageContract(address value);
    event UpdateCreationWindowContract(address value);
    event UpdatePlatformFee(uint256 _platformFee);
    event UpdateIV(uint32 _iv);
    event UpdateMaxSkew(int256 _maxSkew);

    event UpdateCircuitBreakerContract(address _circuitBreakerContract);
    event UpdateSf(uint256 sf);
    event UpdatePayout(uint256 payout);
    event UpdateStrikeStepSize(uint128 strikeStepSize);

    function maxSkew() external view returns (int256);

    function circuitBreakerContract() external view returns (address);

    function settlementFeeDisbursalContract() external view returns (address);

    function platformFee() external view returns (uint256);

    function payout() external view returns (uint256);

    function optionStorageContract() external view returns (address);

    function creationWindowContract() external view returns (address);

    function strikeStepSize() external view returns (uint128);
}