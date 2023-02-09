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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20Interface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transfer(
        address dst,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return success Whether or not the approval succeeded
     */
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

interface GLPManagerInterface {
    function getAum(bool maximise) external view returns (uint256);

    function getPrice(bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

interface plvGLPInterface {
    function totalAssets() external view returns (uint256);
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/GLPManagerInterface.sol";
import "./Interfaces/plvGLPInterface.sol";
import "./Interfaces/ERC20Interface.sol";
import "./Whitelist.sol";

//TODO: optimize integer sizes for gas efficiency?

/** @title Oracle for Plutus Vault GLP employing moving average calculations for pricing
    @author Lodestar Finance
    @notice This contract uses a moving average calculation to report a plvGLP/GLP exchange
    rate. The "window size" is adjustable to allow for flexibility in calculation parameters. The price
    returned from the getPlvGLPPrice function is denominated in USD wei.
*/
contract PlvGLPOracle is Ownable {
    uint256 public averageIndex;
    uint256 public windowSize;

    address public GLP;
    address public GLPManager;
    address public plvGLP;
    address public whitelist;

    uint256 private constant BASE = 1e18;
    uint256 private constant DECIMAL_DIFFERENCE = 1e6;
    uint256 private constant MAX_SWING = 10000000000000000; //1%
    bool public constant isGLPOracle = true;

    struct IndexInfo {
        uint256 timestamp;
        uint256 recordedIndex;
    }

    IndexInfo[] public HistoricalIndices;

    event IndexAlert(uint256 previousIndex, uint256 possiblyBadIndex, uint256 timestamp);
    event updatePosted(uint256 averageIndex, uint256 timestamp);

    constructor(address _GLP, address _GLPManager, address _plvGLP, address _whitelist, uint256 _windowSize) {
        GLP = _GLP;
        GLPManager = _GLPManager;
        plvGLP = _plvGLP;
        whitelist = _whitelist;
        windowSize = _windowSize;
        uint256 index = getPlutusExchangeRate();
        require(index > 0, "First index cannot be zero.");
        //initialize indices, this push will be stored in position 0
        HistoricalIndices.push(IndexInfo(block.timestamp, index));
    }

    /**
        @notice Pulls requisite data from GLP contract to calculate the current price of GLP
        @return Returns the price of GLP denominated in USD wei.
     */
    function getGLPPrice() public view returns (uint256) {
        //retrieve the minimized AUM from GLP Manager Contract
        uint256 glpAUM = GLPManagerInterface(GLPManager).getAum(false);
        //retrieve the total supply of GLP
        uint256 glpSupply = ERC20Interface(GLP).totalSupply();
        //GLP Price = AUM / Total Supply
        uint256 price = (glpAUM / glpSupply) * DECIMAL_DIFFERENCE;
        return price;
    }

    /**
        @notice Pulls requisite data from Plutus Vault contract to calculate the current exchange rate.
        @return Returns the current plvGLP/GLP exchange rate directly from Plutus vault contract.
     */
    function getPlutusExchangeRate() public view returns (uint256) {
        //retrieve total assets from plvGLP contract
        uint256 totalAssets = plvGLPInterface(plvGLP).totalAssets();
        //retrieve total supply from plvGLP contract
        uint256 totalSupply = ERC20Interface(plvGLP).totalSupply();
        //plvGLP/GLP Exchange Rate = Total Assets / Total Supply
        uint256 exchangeRate = (totalAssets * BASE) / totalSupply;
        return exchangeRate;
    }

    /**
        @notice Computes the moving average over a period of "windowSize". For the initialization period,
        the average is computed over the length of the indices array.
        @return Returns the moving average of the index over the specified window.
     */
    function computeAverageIndex() public returns (uint256) {
        uint256 latestIndexing = HistoricalIndices.length - 1;
        uint256 sum;
        if (latestIndexing <= windowSize) {
            for (uint256 i = 0; i < latestIndexing; i++) {
                sum += HistoricalIndices[i].recordedIndex;
            }
            averageIndex = sum / HistoricalIndices.length;
            return averageIndex;
        } else {
            uint256 firstIndex = latestIndexing - windowSize + 1;
            for (uint256 i = firstIndex; i <= latestIndexing; i++) {
                sum += HistoricalIndices[i].recordedIndex;
            }
            averageIndex = sum / windowSize;
            return averageIndex;
        }
    }

    /**
        @notice Returns the value of the previously accepted exchange rate.
     */
    function getPreviousIndex() public view returns (uint256) {
        uint256 previousIndexing = HistoricalIndices.length - 1;
        uint256 previousIndex = HistoricalIndices[previousIndexing].recordedIndex;
        return previousIndex;
    }

    /**
        @notice Checks the currently reported exchange rate against the last accepted exchange rate.
        Requested updates are compared against a range of +/- 1% of the previous exchange rate.
        @param currentIndex the currently reported index from Plutus to check swing on
        @return returns TRUE if requested update is within the bounds of maximum swing, returns FALSE otherwise.
     */
    function checkSwing(uint256 currentIndex) public returns (bool) {
        uint256 previousIndex = getPreviousIndex();
        uint256 allowableSwing = (previousIndex * MAX_SWING) / BASE;
        uint256 minSwing = previousIndex - allowableSwing;
        uint256 maxSwing = previousIndex + allowableSwing;
        if (currentIndex > maxSwing || currentIndex < minSwing) {
            emit IndexAlert(previousIndex, currentIndex, block.timestamp);
            return false;
        }
        return true;
    }

    /**
        @notice Update the current, cumulative and average indices when required conditions are met.
        If the price fails to update, the posted price will fall back on the last previously 
        accepted average index. Access is restricted to only whitelisted addresses.
        @dev we only ever update the index if requested update is within +/- 1% of previously accepted
        index.
     */
    function updateIndex() external {
        require(Whitelist(whitelist).isWhitelisted(msg.sender), "NOT_AUTHORIZED");
        uint256 currentIndex = getPlutusExchangeRate();
        uint256 previousIndex = getPreviousIndex();
        bool indexCheck = checkSwing(currentIndex);
        if (!indexCheck) {
            currentIndex = previousIndex;
            HistoricalIndices.push(IndexInfo(block.timestamp, currentIndex));
            averageIndex = computeAverageIndex();
            emit updatePosted(averageIndex, block.timestamp);
        } else {
            HistoricalIndices.push(IndexInfo(block.timestamp, currentIndex));
            averageIndex = computeAverageIndex();
            emit updatePosted(averageIndex, block.timestamp);
        }
    }

    /**
        @notice Computes the TWAP price of plvGLP based on the current price of GLP and moving average of the
        plvGLP/GLP exchange rate.
        @return Returns the TWAP price of plvGLP denominated in USD wei.
     */
    function getPlvGLPPrice() external view returns (uint256) {
        uint256 glpPrice = getGLPPrice();
        uint256 plvGlpPrice = (averageIndex * glpPrice) / BASE;
        return plvGlpPrice;
    }

    //* ADMIN FUNCTIONS */

    event newGLPAddress(address oldGLPAddress, address newGLPAddress);
    event newGLPManagerAddress(address oldManagerAddress, address newManagerAddress);
    event newPlvGLPAddress(address oldPlvGLPAddress, address newPlvGLPAddress);
    event newWindowSize(uint256 oldWindowSize, uint256 newWindowSize);

    /**
        @notice Admin function to update the address of GLP, restricted to only be 
        usable by the contract owner.
     */
    function _updateGlpAddress(address _newGlpAddress) external onlyOwner {
        address oldGLPAddress = GLP;
        GLP = _newGlpAddress;
        emit newGLPAddress(oldGLPAddress, GLP);
    }

    /**
        @notice Admin function to update the address of the GLP Manager Contract, restricted to only be 
        usable by the contract owner.
     */
    function _updateGlpManagerAddress(address _newGlpManagerAddress) external onlyOwner {
        address oldManagerAddress = GLPManager;
        GLPManager = _newGlpManagerAddress;
        emit newGLPManagerAddress(oldManagerAddress, GLPManager);
    }

    /**
        @notice Admin function to update the address of plvGLP, restricted to only be 
        usable by the contract owner.
     */
    function _updatePlvGlpAddress(address _newPlvGlpAddress) external onlyOwner {
        address oldPlvGLPAddress = plvGLP;
        plvGLP = _newPlvGlpAddress;
        emit newPlvGLPAddress(oldPlvGLPAddress, plvGLP);
    }

    /**
        @notice Admin function to update the moving average window size, restricted to only be 
        usable by the contract owner.
     */
    function _updateWindowSize(uint256 _newWindowSize) external onlyOwner {
        uint256 oldWindowSize = windowSize;
        windowSize = _newWindowSize;
        emit newWindowSize(oldWindowSize, windowSize);
    }
}

//SPDX-License-Indentifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public isWhitelisted;

    function updateWhitelist(address _address, bool _isActive) external onlyOwner {
        isWhitelisted[_address] = _isActive;
    }

    function getWhitelisted(address _address) external view returns (bool) {
        return isWhitelisted[_address];
    }
}