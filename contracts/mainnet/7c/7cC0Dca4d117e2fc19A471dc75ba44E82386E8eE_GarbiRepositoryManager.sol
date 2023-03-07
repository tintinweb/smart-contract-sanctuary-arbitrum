// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import '../interfaces/IERC20withBurnAndMint.sol';
import '../interfaces/IGarbiRepository.sol';
import '../interfaces/IGarbiswapWhitelist.sol';

contract GarbiRepositoryManager is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;

    IGarbiswapWhitelist public whitelist; 

    uint256 public totalShares = 1000;

    struct RepoInfo {
        uint256 share;
        uint256 maxCapacityLimit;
    }

    // Array of repo addresses
    address[] public repoAddresses;

    mapping(address => RepoInfo) public repoList;  

    mapping(address => address) public baseToRepo;  

    IERC20withBurnAndMint public GarbiEC;

    uint256 SELL_GARBIEC_FEE = 35; //35/10000 = 0.35%

    uint256 SWAP_FEE = 1; //1/10000 = 0.01%

    address public platformFundAddress;

    modifier onlyRepoInTheList(address repoAddress)
    {
        require(repoAddress != address(0), 'INVALID_REPO_ADDRESS');
        uint flag = 0;
        for (uint i = 0; i < repoAddresses.length; i++) {
            if(repoAddresses[i] == repoAddress) {
                flag = 1;
                break;
            }
        }
        require(flag == 1, "INVALID_PERMISSION");
        _;
    }

    modifier onlyWhitelist()
    {
        if (msg.sender != tx.origin) {
            require(whitelist.whitelisted(msg.sender) == true, 'INVALID_WHITELIST');
        }
        _;
    }

    // Events
    event onAddRepository(address repoAddress, uint256 repoShare, uint256 repoMaxCapacityLimit);
    event onUpdateRepository(address repoAddress, uint256 repoShare, uint256 repoMaxCapacityLimit); 
    event onBuyGarbiEC(address user, address repoInAddress, uint256 assetInAmount, uint256 garbiECOutAmount);
    event onSellGarbiEC(address user, address repoOutAddress, uint256 assetOutAmount, uint256 garbiECInAmount);
    event onSwapTokenToToken(address user, address repoInAddress, address repoOutAddress, uint256 tokenInputAmount, uint256 tokenOutputAmount);

    constructor(
        IERC20withBurnAndMint garbiECContract,
        IGarbiswapWhitelist whitelistContract
    ){
        GarbiEC = garbiECContract;
        whitelist = whitelistContract;
        platformFundAddress = _msgSender();
    }
    
    function addRepository(address repoAddress, uint256 repoShare, uint256 repoMaxCapacityLimit) public onlyOwner {
        require(repoAddress != address(0), 'INVALID_REPO_ADDRESS');
        require(repoShare > 0, 'INVALID_REPO_SHARE');
        require(repoMaxCapacityLimit > 0, 'INVALID_REPO_CAPACITY');

        repoList[repoAddress] = RepoInfo({
            share : repoShare,
            maxCapacityLimit : repoMaxCapacityLimit
        });

        repoAddresses.push(repoAddress);

        IGarbiRepository repo = IGarbiRepository(repoAddress);

        baseToRepo[repo.base()] = repoAddress;

        emit onAddRepository(repoAddress, repoShare, repoMaxCapacityLimit);
    }

    function updateRepository(address repoAddress, uint256 repoShare, uint256 repoMaxCapacityLimit) public onlyOwner {
        require(repoAddress != address(0), 'INVALID_REPO_ADDRESS');
        require(repoShare > 0, 'INVALID_REPO_SHARE');
        require(repoMaxCapacityLimit > 0, 'INVALID_REPO_CAPACITY');

        repoList[repoAddress] = RepoInfo({
            share : repoShare,
            maxCapacityLimit : repoMaxCapacityLimit
        });

        emit onUpdateRepository(repoAddress, repoShare, repoMaxCapacityLimit);
    }

    function setTotalShares(uint256 newTotalShares) public onlyOwner {
        require(newTotalShares > 0, 'INVALID_DATA');
        totalShares = newTotalShares;
    }

    function setSellGarbiECFee(uint256 newFee) public onlyOwner {
        require(newFee > 0, 'INVALID_DATA');
        SELL_GARBIEC_FEE = newFee;
    }

    function setPlatformFundAdress(address newAddress) public onlyOwner {
        platformFundAddress = newAddress;
    }

    function setGarbiEquityCertificateContract(IERC20withBurnAndMint newGarbiECContract) public onlyOwner {
        require(address(newGarbiECContract) != address(0), 'INVALID_DATA');
        GarbiEC = newGarbiECContract;
    }

    function buyGarbiEquityCertificate(address repoInAddress, uint256 assetInAmount) public nonReentrant onlyRepoInTheList(repoInAddress) onlyWhitelist whenNotPaused{
        require(assetInAmount > 0, 'INVALID_ASSET_AMOUNT');
        require(repoList[repoInAddress].share > 0, 'INVALID_REPO');
        
        IGarbiRepository repoIn = IGarbiRepository(repoInAddress);

        require(repoIn.getCapacityByToken().add(assetInAmount) <= repoList[repoInAddress].maxCapacityLimit, 'INVALID_ASSET_CAPACITY');

        IERC20 base = IERC20(repoIn.base());

        uint256 baseUserBalance = base.balanceOf(msg.sender);
        baseUserBalance = repoIn.convertDecimalTo18(baseUserBalance, repoIn.baseDecimal());

        if(assetInAmount > baseUserBalance) {
            assetInAmount = baseUserBalance;
        }
        
        uint256 garbiECOutAmount = getDataToBuyGarbiEC(repoInAddress, assetInAmount);

        //make trade
        uint256 assetInAmountAtAssetDecimal = repoIn.convertToBaseDecimal(assetInAmount, 18);
        base.transferFrom(msg.sender, address(this), assetInAmountAtAssetDecimal);
        GarbiEC.mint(address(this), garbiECOutAmount);
        base.transfer(repoInAddress, assetInAmountAtAssetDecimal);
        GarbiEC.transfer(msg.sender, garbiECOutAmount);

        emit onBuyGarbiEC(msg.sender, repoInAddress, assetInAmount, garbiECOutAmount);
    }

    function sellGarbiEquityCertificate(address repoOutAddress, uint256 garbiECInAmount) public nonReentrant onlyRepoInTheList(repoOutAddress) onlyWhitelist whenNotPaused{
        require(garbiECInAmount > 0, 'INVALID_GARBIEC_AMOUNT');
        require(repoList[repoOutAddress].share > 0, 'INVALID_REPO');
        
        IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);

        IERC20 base = IERC20(repoOut.base());

        uint256 garbiECUserBalance = GarbiEC.balanceOf(msg.sender);

        if(garbiECInAmount > garbiECUserBalance) {
            garbiECInAmount = garbiECUserBalance;
        }

        uint256 baseOutAmount = getDataToSellGarbiEC(repoOutAddress, garbiECInAmount);
        
        require(baseOutAmount > 0, 'INVALID_OUT_AMOUNT_ZERO');
        require(baseOutAmount <= repoOut.getCapacityByToken(), 'INVALID_OUT_AMOUNT');

        uint256 fee = baseOutAmount.mul(getSellGarbiECDynamicFee(repoOutAddress, baseOutAmount, SELL_GARBIEC_FEE)).div(10000);
        uint256 baseOutAmountAfterFee = baseOutAmount.sub(fee);

        //make trade
        GarbiEC.transferFrom(msg.sender, address(this), garbiECInAmount);
        GarbiEC.burn(garbiECInAmount);
        repoOut.withdrawBaseToRepositoryManager(baseOutAmount);
        base.transfer(msg.sender, repoOut.convertToBaseDecimal(baseOutAmountAfterFee, 18));
        //transfer fee
        base.transfer(platformFundAddress, repoOut.convertToBaseDecimal(fee, 18));

        emit onSellGarbiEC(msg.sender, repoOutAddress, baseOutAmountAfterFee, garbiECInAmount);
    }

    function swapTokenToTokenWithTokenInput(address repoInAddress, address repoOutAddress, uint256 tokenInputAmount, uint256 minTokenOutputAmount) public onlyRepoInTheList(repoInAddress) onlyRepoInTheList(repoOutAddress) nonReentrant onlyWhitelist whenNotPaused {
        require(repoInAddress != repoOutAddress, 'INVALID_PAIR');
        require(tokenInputAmount > 0, 'INVALID_TOKEN_INPUT_AMOUNT');
        require(minTokenOutputAmount > 0, 'INVALID_MIN_TOKEN_OUTPUT_AMOUNT');

        IGarbiRepository repoIn = IGarbiRepository(repoInAddress);
        IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);
        
        uint256 tokenOutputAmount = getTokenOutputAmountFromTokenInput(repoIn, repoOut, tokenInputAmount);
        require(tokenOutputAmount <= repoOut.getCapacityByToken(), 'INVALID_OUT_AMOUNT');
        require(tokenOutputAmount >= minTokenOutputAmount, 'CAN_NOT_MAKE_TRADE');

        IERC20 baseIn = IERC20(repoIn.base());

        uint256 baseInUserBalance = repoIn.convertDecimalTo18(baseIn.balanceOf(msg.sender), repoIn.baseDecimal());

        require(tokenInputAmount <= baseInUserBalance, 'TOKEN_INPUT_AMOUNT_HIGHER_USER_BALANCE');
        
        //make trade
        makeTradeOnTwoRepos(repoIn, repoOut, tokenInputAmount, tokenOutputAmount);

        emit onSwapTokenToToken(msg.sender, repoInAddress, repoOutAddress, tokenInputAmount, tokenOutputAmount);
    }

    function makeTradeOnTwoRepos(IGarbiRepository repoIn, IGarbiRepository repoOut, uint256 tokenInputAmount, uint256 tokenOutputAmount) private {
        IERC20 baseIn = IERC20(repoIn.base());
        IERC20 baseOut = IERC20(repoOut.base());
        uint256 fee = tokenOutputAmount.mul(getSellGarbiECDynamicFee(address(repoOut), tokenOutputAmount, SWAP_FEE)).div(10000);
        uint256 tokenOutputAmountAfterFee = tokenOutputAmount.sub(fee);
        uint256 tokenInputAmountAtTokenDecimal = repoIn.convertToBaseDecimal(tokenInputAmount, 18);
        baseIn.transferFrom(msg.sender, address(this), tokenInputAmountAtTokenDecimal);
        baseIn.transfer(address(repoIn), tokenInputAmountAtTokenDecimal);
        repoOut.withdrawBaseToRepositoryManager(tokenOutputAmount);
        baseOut.transfer(msg.sender, repoOut.convertToBaseDecimal(tokenOutputAmountAfterFee, 18));
        //transfer fee
        baseOut.transfer(platformFundAddress, repoOut.convertToBaseDecimal(fee, 18));
    }

    function getTokenOutputAmountFromTokenInput(IGarbiRepository repoIn, IGarbiRepository repoOut, uint256 tokenInputAmount) public view returns (uint256) {
        uint256 tokenInputPriceFromOracle = repoIn.getBasePrice();
        uint256 tokenOuputPriceFromOracle = repoOut.getBasePrice();
        uint256 tokenOutputAmount = tokenInputAmount.mul(tokenInputPriceFromOracle).div(tokenOuputPriceFromOracle);
        return tokenOutputAmount;
    }

    function getTokenOutputWithFee(address repoInAddress, address repoOutAddress, uint256 tokenInputAmount) public view returns (uint256) {
        IGarbiRepository repoIn = IGarbiRepository(repoInAddress);
        IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);
        uint256 tokenOutputAmount = getTokenOutputAmountFromTokenInput(repoIn, repoOut, tokenInputAmount);
        if(tokenOutputAmount > repoOut.getCapacityByToken()) {
            tokenOutputAmount = repoOut.getCapacityByToken();
        }
        uint256 fee = tokenOutputAmount.mul(getSellGarbiECDynamicFee(repoOutAddress, tokenOutputAmount, SWAP_FEE)).div(10000);
        uint256 tokenOutputAmountAfterFee = tokenOutputAmount.sub(fee);
        return tokenOutputAmountAfterFee;
    }

    function getGarbiECPrice() public view returns(uint256 garbiECPrice) {
        uint256 totalCapacityByUSD = 0;
        for (uint i = 0; i < repoAddresses.length; i++) {
            if(repoList[repoAddresses[i]].share > 0) {
                IGarbiRepository repo = IGarbiRepository(repoAddresses[i]);
                totalCapacityByUSD = totalCapacityByUSD.add(repo.getCapacityByUSD());
            }
        }

        uint256 garbiECTotalSupply = GarbiEC.totalSupply();

        if(garbiECTotalSupply == 0) {
            garbiECPrice = 1e18;
        }
        else {
            garbiECPrice = totalCapacityByUSD.mul(1e18).div(garbiECTotalSupply);
        }
    }

    function getDataToBuyGarbiEC(address repoInAddress, uint256 assetInAmount) public view returns (uint256 garbiECOutAmount) {
       uint256 garbiECPrice = getGarbiECPrice();
       IGarbiRepository repoIn = IGarbiRepository(repoInAddress);

       uint256 assetPrice = repoIn.getBasePrice();

       garbiECOutAmount = assetInAmount.mul(assetPrice).div(garbiECPrice);
    }

    function getDataToSellGarbiEC(address repoOutAddress, uint256 garbiECInAmount) public view returns (uint256 assetOutAmount) {
       uint256 garbiECPrice = getGarbiECPrice();
       IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);

       uint256 assetPrice = repoOut.getBasePrice();

       assetOutAmount = garbiECInAmount.mul(garbiECPrice).div(assetPrice);
    }

    function getDataToSellGarbiECWithFee(address repoOutAddress, uint256 garbiECInAmount) public view returns (uint256 assetOutAmountAfterFee) {
       uint256 garbiECPrice = getGarbiECPrice();
       IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);

       uint256 assetPrice = repoOut.getBasePrice();

       uint256 assetOutAmount = garbiECInAmount.mul(garbiECPrice).div(assetPrice);

       if(assetOutAmount > repoOut.getCapacityByToken()) {
            assetOutAmountAfterFee = 0;
       }
       else {
            uint256 fee = assetOutAmount.mul(getSellGarbiECDynamicFee(repoOutAddress, assetOutAmount, SELL_GARBIEC_FEE)).div(10000);
            assetOutAmountAfterFee = assetOutAmount.sub(fee);
       }
    }

    function getTotalAllRepoCapacityByUSD() public view returns (uint256 totalCapacityByUSD) {
        for (uint i = 0; i < repoAddresses.length; i++) {
            if(repoList[repoAddresses[i]].share > 0) {
                IGarbiRepository repo = IGarbiRepository(repoAddresses[i]);
                totalCapacityByUSD = totalCapacityByUSD.add(repo.getCapacityByUSD());
            }
        }
    }

    function getSellGarbiECDynamicFee(address repoOutAddress, uint256 assetOutAmount, uint256 baseFee) public view returns (uint256 fee) {
        uint256 totalCapacityByUSD = getTotalAllRepoCapacityByUSD();
        IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);
        uint256 repoOutTotalCapacityByUSD = repoOut.getCapacityByUSD();
        uint256 assetOutAmountByUSD = assetOutAmount.mul(repoOut.getBasePrice()).div(10**18);
        uint256 repoShareAfterOut = repoOutTotalCapacityByUSD.sub(assetOutAmountByUSD).mul(totalShares).div(totalCapacityByUSD.sub(assetOutAmountByUSD));
        if(repoShareAfterOut > 0) {
            uint256 shareDiff = repoList[repoOutAddress].share.mul(totalShares).div(repoShareAfterOut);
            fee = baseFee.mul(shareDiff).div(totalShares);
            if(fee > baseFee*10) {
                fee = baseFee*10; //max fee
            }
        }
        else {
            fee = baseFee*10; //max fee
        }
    }

    function getFeeWithOutAmount(address repoOutAddress, uint256 assetOutAmount) public view returns (uint256 sellGarbiECfee, uint256 swapFee) {
        uint256 totalCapacityByUSD = getTotalAllRepoCapacityByUSD();
        IGarbiRepository repoOut = IGarbiRepository(repoOutAddress);
        uint256 repoOutTotalCapacityByUSD = repoOut.getCapacityByUSD();
        uint256 assetOutAmountByUSD = assetOutAmount.mul(repoOut.getBasePrice()).div(10**18);
        uint256 repoShareAfterOut = repoOutTotalCapacityByUSD.sub(assetOutAmountByUSD).mul(totalShares).div(totalCapacityByUSD.sub(assetOutAmountByUSD));
        if(repoShareAfterOut > 0) {
            uint256 shareDiff = repoList[repoOutAddress].share.mul(totalShares).div(repoShareAfterOut);
            sellGarbiECfee = SELL_GARBIEC_FEE.mul(shareDiff).div(totalShares);
            swapFee = SWAP_FEE.mul(shareDiff).div(totalShares);
            if(sellGarbiECfee > SELL_GARBIEC_FEE*10) {
                sellGarbiECfee = SELL_GARBIEC_FEE*10; //max fee
            }
            if(swapFee > SWAP_FEE*10) {
                swapFee = SWAP_FEE*10; //max fee
            }
        }
        else {
            sellGarbiECfee = SELL_GARBIEC_FEE*10;
            swapFee = SWAP_FEE*10;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IGarbiswapWhitelist {
	function whitelisted(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IGarbiRepository {
    function base() external view returns(address);
    function getCapacityByToken() external view returns(uint256);
    function getCapacityByUSD() external view returns(uint256);
    function getBasePrice() external view returns(uint256);
    function withdrawBaseToRepositoryManager(uint256 baseOutAmount) external;
    function oraclePriceDecimal() external view returns (uint256);
    function baseDecimal() external view returns (uint256);
    function convertToBaseDecimal(uint256 number, uint256 numberDecimal) external view returns (uint256);
    function convertDecimalTo18(uint256 number, uint256 numberDecimal) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20withBurnAndMint is IERC20 {
    function burn(uint256 amount) external;
    function mint(address _user, uint256 _amount) external; 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}