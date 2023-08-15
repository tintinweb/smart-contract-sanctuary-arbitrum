//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Bridge is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 feeForAdminGas;
    uint24 public feeForAdmin;
    uint24 public feeForLPProvider;    
    uint256[] public chains;
    address[] public tokens;     
    mapping(address=>string) public logos;
    mapping(address => uint256) public isTokenListed;
    mapping(uint256 => uint256) public isChainListed;   
    mapping(address=>mapping(uint256=>address)) public tokensInOtherChains;
    mapping(address=>uint256) public totalBalance;
    mapping(address=>uint256) public totalLPBalance;
    mapping(address=>mapping(address=>uint256)) public LPBalanceOf;
    mapping(address=>uint256) public feeCollectedForAdmin;
    mapping(address=>uint256) public bridgeNonce;
    mapping(address=>mapping(uint256=>bool)) public nonceProcessed;

    event FeeUpdated(uint256 feeForAdminGas, uint24 feeForAdmin, uint24 feeForLPProvider);
    event AddLiquidity(address LPProvider, address token, uint256 amount, uint256 totalBalance, uint256 totalLPBalance, uint256 LPBalanceOf);
    event LiquidityRequired(address LPProvider, address[] tokens, uint256[] chains, uint256 amount);
    event RemoveLiquidity(address LPProvider, address token, uint256 amount, uint256 totalBalance, uint256 totalLPBalance, uint256 LPBalanceOf);
    event WithdrawLiquidity(address owner, address rootToken, uint256 amount, uint256 rootChain);
    event LiquidityRequiredInOtherChain(address owner, address[] tokens, uint256[] chains, uint256 amount, uint256 originChain);
    event BridgeIn(address sender, address token, uint256 chain, address to, uint256 amount, uint256 bridgeNonce);
    event BridgeOut(address sender, address to, address token, uint256 rootChain, uint256 amount);
    event BridgeReverted(address sender, address to, address token, uint256 rootChain, uint256 amount);
    event LiquidityRequiredForAdmin(address[] tokens, uint256[] chains, uint256 amount);
    event WithdrawAdminFeeInOtherChain(address token, uint256 amount, uint256 rootChain);
    event LiquidityRequiredForAdminInOtherChain(address[] tokens, uint256[] chains, uint256 amount, uint256 rootChain);

    function initialize(
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function addChain(uint256 _chain) onlyOwner external {
        require(isChainListed[_chain]==0, "already existed");
        chains.push(_chain);
        isChainListed[_chain] = chains.length;
    }

    function removeChain(uint256 _chain) onlyOwner external {
        require(isChainListed[_chain]>0, "not existed");
        chains[isChainListed[_chain]-1] = chains[chains.length-1];
        isChainListed[chains[chains.length-1]] = isChainListed[_chain];
        delete isChainListed[_chain];
        chains.pop();      
    }

    function updateFee(uint256 _feeForAdminGas, uint24 _feeForAdmin, uint24 _feeForLPProvider) onlyOwner external {
        feeForAdminGas = _feeForAdminGas;
        feeForAdmin = _feeForAdmin;
        feeForLPProvider = _feeForLPProvider;
        emit FeeUpdated(feeForAdminGas, feeForAdmin, feeForLPProvider);
    }
    
    function addToken(address _token, string memory _logo) onlyOwner external {
        require(isTokenListed[_token]==0, "already existed");
        tokens.push(_token);
        logos[_token]=_logo;
        isTokenListed[_token] = tokens.length;
    }
    function removeToken(address _token) onlyOwner external {
        require(isTokenListed[_token]>0, "not existed");
        tokens[isTokenListed[_token]-1] = tokens[tokens.length-1];
        isTokenListed[tokens[tokens.length-1]] = isTokenListed[_token];
        delete isTokenListed[_token];
        delete logos[_token];
        tokens.pop(); 
        for(uint256 i=0;i<chains.length;i++){
            delete tokensInOtherChains[_token][chains[i]];
        }         
    }

    function setTokenForOtherChain(address _token, uint256 _chain, address _tokenForOtherChain) onlyOwner external {
        require(isTokenListed[_token]>0, "not existed");
        tokensInOtherChains[_token][_chain] = _tokenForOtherChain;
    }

    function addLiquidity(address _token, uint256 amount) external {
        require(isTokenListed[_token]>0, "not existed");
        IERC20Upgradeable(_token).safeTransferFrom(_msgSender(), address(this), amount);
        uint256 LPBalance = totalBalance[_token] > 0 ? amount * totalLPBalance[_token] / totalBalance[_token] : amount;
        totalBalance[_token] += amount;
        totalLPBalance[_token] += LPBalance;
        LPBalanceOf[_token][_msgSender()] += LPBalance;
        emit AddLiquidity(_msgSender(), _token, amount, totalBalance[_token], totalLPBalance[_token], LPBalanceOf[_token][_msgSender()]);
    }

    function removeLiquidity(address _token, uint256 amount, uint256[] memory chainsListIfInsufficient) external nonReentrant {
        require(isTokenListed[_token]>0, "not existed");
        uint256 LPBalance = totalBalance[_token] > 0 ? amount * totalLPBalance[_token] / totalBalance[_token] : amount;
        require(totalLPBalance[_token] >= LPBalance, "insufficient liquidity");
        require(LPBalanceOf[_token][_msgSender()] >= LPBalance, "You don't have enogh Liquidity");
        require(totalBalance[_token] >= amount, "insufficient token");
        if(IERC20Upgradeable(_token).balanceOf(address(this))>=amount){
            IERC20Upgradeable(_token).safeTransfer(_msgSender(), amount);
            totalLPBalance[_token] -= LPBalance;
            LPBalanceOf[_token][_msgSender()] -= LPBalance;
            totalBalance[_token] -= amount;
            emit RemoveLiquidity(_msgSender(), _token, amount, totalBalance[_token], totalLPBalance[_token], LPBalanceOf[_token][_msgSender()]);
        }else{
            uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));
            if(_amount > 0){
                LPBalance = totalBalance[_token] > 0 ? _amount * totalLPBalance[_token] / totalBalance[_token] : _amount;
                IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
                totalLPBalance[_token] -= LPBalance;
                LPBalanceOf[_token][_msgSender()] -= LPBalance;
                totalBalance[_token] -= _amount;
                emit RemoveLiquidity(_msgSender(), _token, _amount, totalBalance[_token], totalLPBalance[_token], LPBalanceOf[_token][_msgSender()]);
            }        
            address[] memory _tokens;
            uint256[] memory _chains;
            uint256 count=0;
            for(uint256 i=0;i<chainsListIfInsufficient.length;i++){
                if(tokensInOtherChains[_token][chainsListIfInsufficient[i]] != address(0)){
                    _tokens[count]=tokensInOtherChains[_token][chainsListIfInsufficient[i]];
                    _chains[count]=chainsListIfInsufficient[i];
                    count++;
                }
                
            }    
            emit LiquidityRequired(_msgSender(), _tokens, _chains, amount-_amount);
        }        
    }
    function withdrawLiquidity(address owner, address _token, uint256 amount, uint256 rootChain) external onlyOwner nonReentrant {
        require(isTokenListed[_token]>0, "not existed");
        if(IERC20Upgradeable(_token).balanceOf(address(this))>=amount){
            IERC20Upgradeable(_token).safeTransfer(owner, amount);            
            emit WithdrawLiquidity(owner, tokensInOtherChains[_token][rootChain], amount, rootChain);
        }else{
            uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));
            if(_amount > 0){
                IERC20Upgradeable(_token).safeTransfer(owner, _amount);
                emit WithdrawLiquidity(owner, tokensInOtherChains[_token][rootChain], _amount, rootChain);
            }        
            address[] memory _tokens;
            uint256[] memory _chains;
            uint256 count=0;
            for(uint256 i=0;i<chains.length;i++){
                if(tokensInOtherChains[_token][chains[i]] != address(0)){
                    _tokens[count]=tokensInOtherChains[_token][chains[i]];
                    _chains[count]=chains[i];
                }
                
            }    
            emit LiquidityRequiredInOtherChain(owner, _tokens, _chains, amount-_amount, rootChain);
        } 
    }

    function forceRemoveLiquidity(address owner, address _token, uint256 amount) external onlyOwner nonReentrant {
        require(isTokenListed[_token]>0, "not existed");
        uint256 LPBalance = totalBalance[_token] > 0 ? amount * totalLPBalance[_token] / totalBalance[_token] : amount;
        require(totalLPBalance[_token] >= LPBalance, "insufficient liquidity");
        require(LPBalanceOf[_token][owner] >= LPBalance, "You don't have enogh Liquidity");
        require(totalBalance[_token] >= amount, "insufficient token");
        totalLPBalance[_token] -= LPBalance;
        LPBalanceOf[_token][owner] -= LPBalance;
        totalBalance[_token] -= amount;
        emit RemoveLiquidity(owner, _token, amount, totalBalance[_token], totalLPBalance[_token], LPBalanceOf[_token][owner]);   
    }

    function bridgeIn(address _token, uint256 _chain, address to, uint256 amount) external payable {
        require(msg.value >= feeForAdminGas, "Insufficient fee");        
        (bool sent, ) = payable(owner()).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        require(isTokenListed[_token]>0, "not existed");
        require(tokensInOtherChains[_token][_chain]!=address(0), "no token registered");
        IERC20Upgradeable(_token).safeTransferFrom(_msgSender(), address(this), amount);
        bridgeNonce[_token] += 1;
        emit BridgeIn(_msgSender(), tokensInOtherChains[_token][_chain], _chain, to, amount, bridgeNonce[_token]);
    }

    function bridgeOut(address _token, uint256 rootChain, address sender, address to, uint256 amount, uint256 _bridgeNonce) external onlyOwner nonReentrant{
        require(isTokenListed[_token]>0, "not existed");
        require(!nonceProcessed[_token][_bridgeNonce], "already bridged!");
        nonceProcessed[_token][_bridgeNonce] = true;
        uint256 amountForAdmin = amount * feeForAdmin / 1000000;
        uint256 amountForLPProvider = amount * feeForLPProvider / 1000000;
        
        amount = amount - amountForAdmin - amountForLPProvider;
        if(IERC20Upgradeable(_token).balanceOf(address(this)) >= amount){
            feeCollectedForAdmin[_token] += amountForAdmin;
            totalBalance[_token] += amountForLPProvider;
            IERC20Upgradeable(_token).safeTransfer(to, amount);
            emit BridgeOut(sender, to, _token, rootChain, amount);
        }else{
            uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));
            amountForAdmin = _amount * feeForAdmin / (1000000 - feeForAdmin - feeForLPProvider);
            amountForLPProvider = _amount * feeForLPProvider / (1000000 - feeForAdmin - feeForLPProvider);
            feeCollectedForAdmin[_token] += amountForAdmin;
            totalBalance[_token] += amountForLPProvider;
            if(_amount > 0){
                IERC20Upgradeable(_token).safeTransfer(to, _amount);
                emit BridgeOut(sender, to, _token, rootChain, _amount);
            }        
            
            emit BridgeReverted(sender, to, tokensInOtherChains[_token][rootChain], rootChain, (amount-_amount) * 1000000 / (1000000 - feeForAdmin - feeForLPProvider));
        }        
    }

    function bridgeRevert(address sender, address _token, uint256 amount) external onlyOwner nonReentrant{
        require(isTokenListed[_token]>0, "not existed");
        IERC20Upgradeable(_token).safeTransfer(sender, amount);
    }

    function withdrawAdminFee(address _token, uint256[] memory chainsListIfInsufficient) external onlyOwner {
        require(isTokenListed[_token]>0, "not existed");
        if(feeCollectedForAdmin[_token] <= IERC20Upgradeable(_token).balanceOf(address(this))){
            IERC20Upgradeable(_token).safeTransfer(owner(), feeCollectedForAdmin[_token]);
            feeCollectedForAdmin[_token] = 0;
        }else{
            feeCollectedForAdmin[_token] -= IERC20Upgradeable(_token).balanceOf(address(this));
            IERC20Upgradeable(_token).safeTransfer(owner(), IERC20Upgradeable(_token).balanceOf(address(this)));
            address[] memory _tokens;
            uint256[] memory _chains;
            uint256 count=0;
            for(uint256 i=0;i<chainsListIfInsufficient.length;i++){
                if(tokensInOtherChains[_token][chainsListIfInsufficient[i]] != address(0)){
                    _tokens[count]=tokensInOtherChains[_token][chainsListIfInsufficient[i]];
                    _chains[count]=chainsListIfInsufficient[i];
                    count++;
                }
                
            }    
            emit LiquidityRequiredForAdmin(_tokens, _chains, feeCollectedForAdmin[_token]);
        }

    }

    function withdrawAdminFeeInOtherChain(address _token, uint256 amount, uint256 rootChain) external onlyOwner {
        require(isTokenListed[_token]>0, "not existed");
        if(amount <= IERC20Upgradeable(_token).balanceOf(address(this))){
            IERC20Upgradeable(_token).safeTransfer(owner(), amount);
            emit WithdrawAdminFeeInOtherChain(tokensInOtherChains[_token][rootChain], amount, rootChain);
        }else{
            amount -= IERC20Upgradeable(_token).balanceOf(address(this));
            emit WithdrawAdminFeeInOtherChain(tokensInOtherChains[_token][rootChain], IERC20Upgradeable(_token).balanceOf(address(this)), rootChain);
            IERC20Upgradeable(_token).safeTransfer(owner(), IERC20Upgradeable(_token).balanceOf(address(this)));
            address[] memory _tokens;
            uint256[] memory _chains;
            uint256 count=0;
            for(uint256 i=0;i<chains.length;i++){
                if(tokensInOtherChains[_token][chains[i]] != address(0)){
                    _tokens[count]=tokensInOtherChains[_token][chains[i]];
                    _chains[count]=chains[i];
                }
                
            }    
            emit LiquidityRequiredForAdminInOtherChain(_tokens, _chains, amount, rootChain);
        }        
    }

    function forceWithdrawAdminFee(address _token, uint256 amount) external onlyOwner{
        require(isTokenListed[_token]>0, "not existed");
        feeCollectedForAdmin[_token] -= amount;
    }

    function balanceOf(address LPProvider, address _token) external view returns(uint256 amount){
        amount = totalLPBalance[_token]>0 ? LPBalanceOf[_token][LPProvider] * totalBalance[_token] / totalLPBalance[_token] : LPBalanceOf[_token][LPProvider];
    }

    function getChainsAndTokens() external view returns(uint256[] memory _chains, address[] memory _tokens, string[] memory _logos){
        _chains = chains;
        _tokens = tokens;
        for(uint256 i=0;i<tokens.length;i++){
            _logos[i] = logos[tokens[i]];
        }
    }

    function getFee() external view returns(uint256 _feeForAdminGas, uint24 _feeForAdmin, uint24 _feeForLPProvider){
        _feeForAdminGas = feeForAdminGas;
        _feeForAdmin = feeForAdmin;
        _feeForLPProvider = feeForLPProvider;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}