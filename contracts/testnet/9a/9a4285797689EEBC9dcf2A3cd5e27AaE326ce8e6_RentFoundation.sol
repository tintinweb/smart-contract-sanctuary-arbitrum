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
pragma solidity 0.8.16;

interface IcToken {
    function crop() external view returns (string memory);
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IKeyProtocolVariables {
    function xTokenMintFee() external view returns (uint256);

    function securityDepositMonths() external view returns (uint8);

    function xTokensSecurityWallet() external view returns (address);

    function landxOperationalWallet() external view returns (address);

    function landxChoiceWallet() external view returns (address);

    function landXOperationsPercentage() external view returns (uint256);

    function landXChoicePercentage() external view returns (uint256);

    function lndxHoldersPercentage() external view returns (uint256);

    function hedgeFundAllocation() external view returns (uint256);

    function hedgeFundWallet() external view returns (address);

    function preLaunch() external view returns (bool);

    function sellXTokenSlippage() external view returns (uint256);
   
    function buyXTokenSlippage() external view returns (uint256);  

    function cTokenSellFee() external view returns (uint256);

    function validatorCommission() external view returns (uint256);

    function validatorCommisionWallet() external view returns (address);

    function payRentFee() external view returns (uint256);

    function maxValidatorFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ILandXNFT {
    function tillableArea(uint256 id) external view returns (uint256);

    function cropShare(uint256 id) external view returns (uint256);

    function crop(uint256 id) external view returns (string memory);

    function validatorFee(uint256 id) external view returns (uint256);

    function validator(uint256 id) external view returns (address);

    function initialOwner(uint256 id) external view returns (address);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ILNDX {
    function feeToDistribute(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOraclePrices {
    function prices(string memory grain) external view returns (uint256);
    
    function getXTokenPrice(address xToken) external view returns (uint256);

    function usdc() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRentFoundation {
    function initialRentApplied(uint256 tokenID) external view returns (bool);

    function spentSecurityDeposit(uint256 tokenID) external view returns (bool);

    function payInitialRent(uint256 tokenID, uint256 amount) external;

    function buyOutPreview(uint256 tokenID) external view returns(bool, uint256);

    function buyOut(uint256 tokenID) external returns(uint256);

     function sellCToken(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IxToken is IERC20 {
    function previewNonDistributedYield() external view returns(uint256);

    function getNonDistributedYield() external returns(uint256);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function xBasketTransfer(address _from, uint256 amount) external;

    function Staked(address)
        external
        view
        returns (uint256 amount, uint256 startTime); // Not

    function availableToClaim(address account) external view returns (uint256);

    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IxTokenRouter {
    function getXToken(string memory _name) external view returns (address);
    function getCToken(string memory _name) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IKeyProtocolVariables.sol";
import "./interfaces/ILandXNFT.sol";
import "./interfaces/IxTokenRouter.sol";
import "./interfaces/IOraclePrices.sol";
import "./interfaces/IRentFoundation.sol";
import "./interfaces/IcToken.sol";
import "./interfaces/IxToken.sol";
import "./interfaces/ILNDX.sol";

contract RentFoundation is IRentFoundation, Context, Ownable {
    struct deposit {
        uint256 timestamp;
        uint256 amount; // in kg
        int256 depositBalance; //in kg
    }

    IERC20 public immutable usdc;

    address public immutable lndx;

    ILandXNFT public landXNFT; //address of landXNFT

    IOraclePrices public grainPrices;

    IxTokenRouter public xTokenRouter; // address of xTokenRouter
    IKeyProtocolVariables public keyProtocolValues;

    mapping(uint256 => deposit) public deposits;

    mapping(uint256 => bool) public initialRentApplied;

    mapping(uint256 => bool) public spentSecurityDeposit;

    address public distributor;
    string[] public crops = ["SOY", "WHEAT", "CORN", "RICE"];

    event rentPaid(uint256 tokenID, uint256 amount);
    event initialRentPaid(uint256 tokenID, uint256 amount);

    constructor(
        address _usdc,
        address _lndx,
        address _grainPrices,
        address _landXNFT,
        address _xTokenRouter,
        address _keyProtocolValues,
        address _distributor
    ) {
        require(_usdc != address(0), "zero address is not allowed");
        require(_lndx != address(0), "zero address is not allowed");
        require(_grainPrices != address(0), "zero address is not allowed");
        require(_landXNFT != address(0), "zero address is not allowed");
        require(_xTokenRouter!= address(0), "zero address is not allowed");
        require(_keyProtocolValues != address(0), "zero address is not allowed");
        usdc = IERC20(_usdc);
        lndx = _lndx;
        xTokenRouter = IxTokenRouter(_xTokenRouter);
        grainPrices = IOraclePrices(_grainPrices);
        landXNFT = ILandXNFT(_landXNFT);
        keyProtocolValues = IKeyProtocolVariables(_keyProtocolValues);
        distributor = _distributor;
    }

    // deposit rent for token ID, in USDC
    function payRent(uint256 tokenID, uint256 amount) public {
        require(initialRentApplied[tokenID], "Initial rent was not applied");
        if (msg.sender == keyProtocolValues.xTokensSecurityWallet()) {
            require(!spentSecurityDeposit[tokenID], "securityDeposit is already spent");
            spentSecurityDeposit[tokenID] = true;
        }
        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
        uint256 platformFee = (amount * keyProtocolValues.payRentFee()) / 10000; // 100% = 10000
        uint256 validatorFee = (amount *
            keyProtocolValues.validatorCommission()) / 10000; // 100% = 10000
        usdc.transfer(
            keyProtocolValues.hedgeFundWallet(),
            ((amount - platformFee - validatorFee) *
                keyProtocolValues.hedgeFundAllocation()) / 10000 // 100% = 10000
        );
        usdc.transfer(
            keyProtocolValues.validatorCommisionWallet(),
            validatorFee
        );
        uint256 grainAmount = (amount - platformFee - validatorFee) * 10 ** 3 / //grainPrices.prices returns price per megatonne, so to get amount in KG we multiply by 10 ** 3 
            grainPrices.prices(landXNFT.crop(tokenID));
        _feeDistributor(platformFee);
        deposits[tokenID].amount += grainAmount;
        emit rentPaid(tokenID, grainAmount);
    }

    // prepay initial rent after sharding in kg
    function payInitialRent(uint256 tokenID, uint256 amount) external {
        string memory crop = landXNFT.crop(tokenID);
        require(
            !initialRentApplied[tokenID],
            "Initial Paymant already applied"
        );
        require(
            xTokenRouter.getXToken(crop) == msg.sender,
            "not initial payer"
        );
        deposits[tokenID].timestamp = block.timestamp;
        deposits[tokenID].amount = amount;
        initialRentApplied[tokenID] = true;
        spentSecurityDeposit[tokenID] = false;
        emit initialRentPaid(tokenID, amount);
    }

    function getDepositBalance(uint256 tokenID) public view returns (int256) {
        uint256 elapsedSeconds = block.timestamp - deposits[tokenID].timestamp;
        uint256 delimeter = 365 * 1 days;
        uint256 rentPerSecond = (landXNFT.cropShare(tokenID) *
            landXNFT.tillableArea(tokenID) * 10 ** 3) /  delimeter; // multiply by 10**3 to not loose precision
        return
            int256(deposits[tokenID].amount) -
            int256(rentPerSecond * elapsedSeconds / 10 ** 7); // landXNFT.tillableArea returns area in square meters(so we divide by 10 ** 4 to get Ha) and diivide by 10 ** 3 from previous step
    }

    // Check and return remainig rent paid
    function buyOut(uint256 tokenID) external returns(uint256) {
        string memory crop = landXNFT.crop(tokenID);
        require(
            initialRentApplied[tokenID],
            "Initial Paymant isn't applied"
        );
        require(
            xTokenRouter.getXToken(crop) == msg.sender,
            "not initial payer"
        );

        int256 depositBalance = getDepositBalance(tokenID);  //KG

        if (depositBalance < 0) {
            revert("NFT has a debt");
        }

        uint256 usdcAmount = (uint256(depositBalance) * grainPrices.prices(crop)) / (10**3); // price per megatonne and usdc has 6 decimals (10**6 / 10**9)


        deposits[tokenID].depositBalance = 0;
        deposits[tokenID].amount = 0;
        deposits[tokenID].timestamp = 0;
        initialRentApplied[tokenID] = false;

        usdc.transfer(msg.sender, usdcAmount);
        return usdcAmount;
    }

     function buyOutPreview(uint256 tokenID) external view returns(bool, uint256) {
        string memory crop = landXNFT.crop(tokenID);
        require(
            initialRentApplied[tokenID],
            "Initial Paymant isn't applied"
        );
        require(
            xTokenRouter.getXToken(crop) == msg.sender,
            "not initial payer"
        );

        int256 depositBalance = getDepositBalance(tokenID);  //KG

        if (depositBalance < 0) {
            return (false, 0);
        }

        uint256 usdcAmount = (uint256(depositBalance) * grainPrices.prices(crop)) / (10**3); // price per megatonne and usdc has 6 decimals (10**6 / 10**9)

        return (true, usdcAmount);
    }

    function sellCToken(address account, uint256 amount) public {
        string memory crop = IcToken(msg.sender).crop();
        require(xTokenRouter.getCToken(crop) == msg.sender, "no valid cToken");
        uint256 usdcAmount = (amount * grainPrices.prices(crop)) / (10**9);
        uint256 sellTokenFee = (usdcAmount *
            keyProtocolValues.cTokenSellFee()) / 10000; // 100% = 10000
        usdc.transfer(account, usdcAmount - sellTokenFee);
        _feeDistributor(sellTokenFee);
    }

    function _feeDistributor(uint256 _fee) internal {
        uint256 lndxFee = (_fee * keyProtocolValues.lndxHoldersPercentage()) /
            10000;
        uint256 operationalFee = (_fee *
            keyProtocolValues.landXOperationsPercentage()) / 10000; // 100% = 10000
        usdc.transfer(lndx, lndxFee);
        ILNDX(lndx).feeToDistribute(lndxFee);
        usdc.transfer(
            keyProtocolValues.landxOperationalWallet(),
            operationalFee
        );
        usdc.transfer(
            keyProtocolValues.landxChoiceWallet(),
            _fee - lndxFee - operationalFee
        );
    }

     function previewSurplusUSDC() public view returns(uint256) {
        uint256 totalUsdcYield;
        for (uint i=0; i<crops.length; i++) {
            address xTokenAddress = xTokenRouter.getXToken(crops[i]);
            uint amount = IxToken(xTokenAddress).previewNonDistributedYield();
            uint usdcYield = (amount * grainPrices.prices(crops[i])) / (10**9);
            totalUsdcYield += usdcYield;
        }
        return totalUsdcYield;
    }

     function _getSurplusUSDC() internal returns(uint256) {
        uint totalUsdcYield;
        for (uint i=0; i<crops.length; i++) {
            address xTokenAddress = xTokenRouter.getXToken(crops[i]);
            uint amount = IxToken(xTokenAddress).getNonDistributedYield();
            uint usdcYield = (amount * grainPrices.prices(crops[i])) / (10**9);
            totalUsdcYield += usdcYield;
        }
        return totalUsdcYield;
    }

    function withdrawSurplusUSDC(uint _amount) public {
        require(msg.sender == distributor, "only distributor can withdraw");
        require(_getSurplusUSDC() >= _amount && _amount < usdc.balanceOf(address(this)), "not enough surplus funds");
        usdc.transfer(distributor, _amount);
    }

    function updateDistributor(address _distributor) public onlyOwner {
        distributor = _distributor;
    }

    function updateCrops(string[] memory _crops) public onlyOwner {
        crops = _crops;
    }

    function setXTokenRouter(address _router) public onlyOwner {
        require(_router != address(0), "zero address is not allowed");
        xTokenRouter = IxTokenRouter(_router);
    }

    function setGrainPrices(address _grainPrices) public onlyOwner {
        require(_grainPrices != address(0), "zero address is not allowed");
        grainPrices = IOraclePrices(_grainPrices);
    }

    // change the address of landxNFT.
    function changeLandXNFTAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "zero address is not allowed");
        landXNFT = ILandXNFT(_newAddress);
    }

    function renounceOwnership() public view override onlyOwner {
        revert ("can 't renounceOwnership here");
    }
}