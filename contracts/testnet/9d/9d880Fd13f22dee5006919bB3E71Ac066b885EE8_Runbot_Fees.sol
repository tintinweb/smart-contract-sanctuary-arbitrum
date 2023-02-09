/**
 *Submitted for verification at Arbiscan on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Version: 1.0.0

abstract contract A_Base{
}
// Version: 1.0.0


// Version: 1.0.0

interface I_Math{
    struct Fraction{
        uint256 numerator;
        uint256 denominator;
    }
}

abstract contract A_Math is A_Base, I_Math{
    /**
     * @notice Compute the number of digits in an uint256 number.
     *
     * Node that if number = 0, it returns 0.
     */
    function numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }
    
    function _min(uint256 a, uint256 b) internal pure returns (uint256){
        return (a<b ? a : b);
    }
    
    function _max(uint256 a, uint256 b) internal pure returns (uint256){
        return (a>b ? a : b);
    }
}


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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


interface I_Runbot_Fees is I_Math {
	
	////
	////
	////
	//////////////// Structs & Events ////////////////
    struct BorrowFees{
        uint256 feesMin;
        uint256 feesMax;
        uint256 durationMin;
        uint256 durationMax;
    }
	
	struct RoyaltyFees{
		address receiver;
		Fraction fees;
	}
	
	////
	////
	////
	//////////////// Public functions ////////////////
	function getETHDust() external;
	
	function getTokenDust(IERC20 token) external;
	
	function setTransferFees(uint256 fees) external ;
	
	function getTransferFees() external view returns (uint256);
	
	function getFeesBase(uint256 nftType) external view returns (uint256, Fraction memory, BorrowFees memory);
	
	function getFeesAddBase(uint256 nftType, uint256 nftSubType) external view returns (uint256, Fraction memory, BorrowFees memory);
	
	function getMintFeesType(uint256 nftType) external view returns (uint256);
	
	function getMintFeesTypeAdd(uint256 nftType, uint256 nftSubType) external view returns (uint256);
	
	function setFundingFees(uint256 nftType, uint256 numerator, uint256 denominator) external;
	
	function setMintFeesRebate(uint256 nbMint, uint256 numerator, uint256 denominator) external;
	
	function getMintFeesRebate() external view returns (uint256, Fraction memory);
	
	function setFundingFeesAdd(uint256 nftType, uint256 nftSubType, uint256 numerator, uint256 denominator) external;
	
	function setBaseFees(uint256 nftType, uint256 fees) external;
	
	function setBaseFeesAdd(uint256 nftType, uint256 nftSubType, uint256 fees) external;
	
	function setBorrowFees(uint256 nftType, uint256 feesMin, uint256 feesMax, uint256 durationMin, uint256 durationMax) external;
	
	function setBorrowFeesAdd(uint256 nftType, uint256 nftSubType, uint256 feesMin, uint256 feesMax, uint256 durationMin, uint256 durationMax) external;
	
	function setMintTypeFees(uint256 nftType, uint256 feesType) external;
	
	function setMintTypeFeesAdd(uint256 nftType, uint256 nftSubType, uint256 feesType) external;
	
	function addRoyaltyFees(uint256 nftType, address receiver, uint256 numerator, uint256 denominator) external;
	
	function addRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, address receiver, uint256 numerator, uint256 denominator) external;
	
	function updateRoyaltyFees(uint256 nftType, uint256 index, address receiver, uint256 numerator, uint256 denominator) external;
	
	function updateRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, uint256 index, address receiver, uint256 numerator, uint256 denominator) external;
	
	function deleteRoyaltyFees(uint256 nftType, uint256 index) external;
	
	function deleteRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, uint256 index) external;
	
	function getNbRoyaltyFees(uint256 nftType) external view returns (uint256);
	
	function getNbRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType) external view returns (uint256);
	
	function getRoyaltyFees(uint256 nftType, uint256 index) external view returns (RoyaltyFees memory);
	
	function getRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, uint256 index) external view returns (RoyaltyFees memory);
	
	
	function getBaseFees(uint256 nftType, uint256 nftSubType, uint256 borrowDuration, bool isMint, uint256 mintNb) external view returns (uint256);
	
	
	function getFees(uint256 nftType, uint256 nftSubType, uint256 bidPrice, bool withFirstBuyRebate, uint256 initialBorrowDuration, uint256 currentBorrowDuration) external view returns (uint256);
	
	function dispatchRoyaltyTransferFees(uint256 nftType, uint256 nftSubType) external payable;
	
	function dispatchRoyaltySellFees(uint256 nftType, uint256 nftSubType) external payable;
	
	function dispatchRoyaltyMintFees(uint256 nftType, uint256 nftSubType) external payable;
	
	////
	////
	////
	//////////////// Private functions ////////////////
	
	////
	////
	////
	//////////////// Default functions ////////////////
	receive() external payable;
	
	fallback() external payable;
}
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


contract Runbot_Fees is A_Base, A_Math, Ownable, I_Runbot_Fees {
	
	////
	////
	////
	//////////////// Public variables ////////////////
		
	////
	////
	////
	//////////////// Private variables ////////////////
	mapping(uint256 => RoyaltyFees[]) private _royaltyFees;
	mapping(uint256 => mapping(uint256 => RoyaltyFees[])) private _royaltyFeesAdd;
	
	mapping(uint256 => Fraction) private _fundingFees;
	mapping(uint256 => mapping(uint256 => Fraction)) private _fundingFeesAdd;
	
	mapping(uint256 => uint256) private _baseFees;
	mapping(uint256 => mapping(uint256 => uint256)) private _baseFeesAdd;
	
	mapping(uint256 => BorrowFees) private _borrowFees;
	mapping(uint256 => mapping(uint256 => BorrowFees)) private _borrowFeesAdd;
	
	mapping(uint256 => uint256) private _mintFeesType;
	mapping(uint256 => mapping(uint256 => uint256)) private _mintFeesTypeAdd;
	
	uint256 private _transferFees;
	
	Fraction private _groupMintFeesRebate;
	uint256 private _groupMintNbLimit;
	
	////
	////
	//////////////// Constructor & Modifiers ////////////////
	constructor(){
		_groupMintFeesRebate.numerator = 30;
		_groupMintFeesRebate.denominator = 100;
		_groupMintNbLimit = 50;
		
		
		_fundingFees[0].numerator = 10;
		_fundingFees[0].denominator = 100;
		
		_fundingFees[1].numerator = 10;
		_fundingFees[1].denominator = 100;
		
		_fundingFees[2].numerator = 10;
		_fundingFees[2].denominator = 100;
		
		
		_baseFees[0] = 0.01 ether;
		_baseFees[1] = 0.01 ether;
		
		
		_borrowFees[2] = BorrowFees(0.001 ether, 0.01 ether, 30 days, 365 days);
		
		
		_mintFeesType[0] = 1;
		_mintFeesType[1] = 1;
		_mintFeesType[2] = 2;
		
		
		_transferFees = 0.001 ether;
	}
	
	////
	////
	////
	//////////////// Public functions ////////////////
	function getETHDust() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
	
	function getTokenDust(IERC20 token) external onlyOwner {
		token.transfer(owner(), token.balanceOf(address(this)));
	}
	
	function setTransferFees(uint256 fees) external onlyOwner {
		_transferFees = fees;
	}
	
	function getTransferFees() external view returns (uint256){
		return _transferFees;
	}
	
	function getFeesBase(uint256 nftType) external view returns (uint256, Fraction memory, BorrowFees memory){
		return (_baseFees[nftType], _fundingFees[nftType], _borrowFees[nftType]);
	}
	
	function getFeesAddBase(uint256 nftType, uint256 nftSubType) external view returns (uint256, Fraction memory, BorrowFees memory){
		return (_baseFeesAdd[nftType][nftSubType], _fundingFeesAdd[nftType][nftSubType], _borrowFeesAdd[nftType][nftSubType]);
	}
	
	function getMintFeesType(uint256 nftType) external view returns (uint256){
		return _mintFeesType[nftType];
	}
	
	function getMintFeesTypeAdd(uint256 nftType, uint256 nftSubType) external view returns (uint256){
		return _mintFeesTypeAdd[nftType][nftSubType];
	}
	
	function setFundingFees(uint256 nftType, uint256 numerator, uint256 denominator) external onlyOwner {
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator <= denominator, "Runbot: Numerator cannot be greater than denominator");
		
		_fundingFees[nftType].numerator = numerator;
		_fundingFees[nftType].denominator = denominator;
	}
	
	function setMintFeesRebate(uint256 nbMint, uint256 numerator, uint256 denominator) external onlyOwner {
		require(nbMint > 1, "Runbot: Nb mint cannot be lower than 2");
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator < denominator, "Runbot: Numerator cannot be greater or equal than denominator");
		
		_groupMintFeesRebate.numerator = numerator;
		_groupMintFeesRebate.denominator = denominator;
		_groupMintNbLimit = nbMint;
	}
	
	function getMintFeesRebate() external view returns (uint256, Fraction memory){
		return (_groupMintNbLimit, _groupMintFeesRebate);
	}
	
	function setFundingFeesAdd(uint256 nftType, uint256 nftSubType, uint256 numerator, uint256 denominator) external onlyOwner {
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator <= denominator, "Runbot: Numerator cannot be greater than denominator");
		
		_fundingFeesAdd[nftType][nftSubType].numerator = numerator;
		_fundingFeesAdd[nftType][nftSubType].denominator = denominator;
	}
	
	function setBaseFees(uint256 nftType, uint256 fees) external onlyOwner {
		_baseFees[nftType] = fees;
	}
	
	function setBaseFeesAdd(uint256 nftType, uint256 nftSubType, uint256 fees) external onlyOwner {
		_baseFeesAdd[nftType][nftSubType] = fees;
	}
	
	function setBorrowFees(uint256 nftType, uint256 feesMin, uint256 feesMax, uint256 durationMin, uint256 durationMax) external onlyOwner {
		require(feesMin <= feesMax, "Runbot: feesMin cannot be greater than feesMax");
		require(durationMin < durationMax, "Runbot: durationMin cannot be greater or equal than durationMax");
		
		_borrowFees[nftType].feesMin = feesMin;
		_borrowFees[nftType].feesMax = feesMax;
		_borrowFees[nftType].durationMin = durationMin;
		_borrowFees[nftType].durationMax = durationMax;
	}
	
	function setBorrowFeesAdd(uint256 nftType, uint256 nftSubType, uint256 feesMin, uint256 feesMax, uint256 durationMin, uint256 durationMax) external onlyOwner {
		require(feesMin <= feesMax, "Runbot: feesMin cannot be greater than feesMax");
		require(durationMin < durationMax, "Runbot: durationMin cannot be greater or equal than durationMax");
		
		_borrowFeesAdd[nftType][nftSubType].feesMin = feesMin;
		_borrowFeesAdd[nftType][nftSubType].feesMax = feesMax;
		_borrowFeesAdd[nftType][nftSubType].durationMin = durationMin;
		_borrowFeesAdd[nftType][nftSubType].durationMax = durationMax;
	}
	
	function setMintTypeFees(uint256 nftType, uint256 feesType) external onlyOwner {
		_mintFeesType[nftType] = feesType;
	}
	
	function setMintTypeFeesAdd(uint256 nftType, uint256 nftSubType, uint256 feesType) external onlyOwner {
		_mintFeesTypeAdd[nftType][nftSubType] = feesType;
	}
	
	function addRoyaltyFees(uint256 nftType, address receiver, uint256 numerator, uint256 denominator) external onlyOwner {
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator <= denominator, "Runbot: Numerator cannot be greater than denominator");
		
		_royaltyFees[nftType].push(RoyaltyFees(receiver, Fraction(numerator, denominator)));
	}
	
	function addRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, address receiver, uint256 numerator, uint256 denominator) external onlyOwner {
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator <= denominator, "Runbot: Numerator cannot be greater than denominator");
		
		_royaltyFeesAdd[nftType][nftSubType].push(RoyaltyFees(receiver, Fraction(numerator, denominator)));
	}
	
	function updateRoyaltyFees(uint256 nftType, uint256 index, address receiver, uint256 numerator, uint256 denominator) external onlyOwner {
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator <= denominator, "Runbot: Numerator cannot be greater than denominator");
		require(index < _royaltyFees[nftType].length, "Runbot: Index out of bounds");
		
		_royaltyFees[nftType][index] = RoyaltyFees(receiver, Fraction(numerator, denominator));
	}
	
	function updateRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, uint256 index, address receiver, uint256 numerator, uint256 denominator) external onlyOwner {
		require(denominator > 0, "Runbot: Denominator cannot be null");
		require(numerator <= denominator, "Runbot: Numerator cannot be greater than denominator");
		require(index < _royaltyFeesAdd[nftType][nftSubType].length, "Runbot: Index out of bounds");
		
		_royaltyFeesAdd[nftType][nftSubType][index] = RoyaltyFees(receiver, Fraction(numerator, denominator));
	}
	
	function deleteRoyaltyFees(uint256 nftType, uint256 index) external onlyOwner {
		require(index < _royaltyFees[nftType].length, "Runbot: Index out of bounds");
		
		uint256 lastIndex = _royaltyFees[nftType].length - 1;
		_royaltyFees[nftType][index] = _royaltyFees[nftType][lastIndex];
		_royaltyFees[nftType].pop();
	}
	
	function deleteRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, uint256 index) external onlyOwner {
		require(index < _royaltyFeesAdd[nftType][nftSubType].length, "Runbot: Index out of bounds");
		
		uint256 lastIndex = _royaltyFeesAdd[nftType][nftSubType].length - 1;
		_royaltyFeesAdd[nftType][nftSubType][index] = _royaltyFeesAdd[nftType][nftSubType][lastIndex];
		_royaltyFeesAdd[nftType][nftSubType].pop();
	}
	
	function getNbRoyaltyFees(uint256 nftType) external view returns (uint256){
		return _royaltyFees[nftType].length;
	}
	
	function getNbRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType) external view returns (uint256){
		return _royaltyFeesAdd[nftType][nftSubType].length;
	}
	
	function getRoyaltyFees(uint256 nftType, uint256 index) external view returns (RoyaltyFees memory){
		require(index < _royaltyFees[nftType].length, "Runbot: Index out of bounds");
		
		return _royaltyFees[nftType][index];
	}
	
	function getRoyaltyFeesAdd(uint256 nftType, uint256 nftSubType, uint256 index) external view returns (RoyaltyFees memory){
		require(index < _royaltyFeesAdd[nftType][nftSubType].length, "Runbot: Index out of bounds");
		
		return _royaltyFeesAdd[nftType][nftSubType][index];
	}
	
	
	function getBaseFees(uint256 nftType, uint256 nftSubType, uint256 borrowDuration, bool isMint, uint256 mintNb) public view returns (uint256){
		uint256 mintFeesType = _mintFeesType[nftType];
		uint256 mintFeesTypeAdd = _mintFeesTypeAdd[nftType][nftSubType];
		
		if (mintFeesTypeAdd != 0){
			mintFeesType = mintFeesTypeAdd;
		}
		
		uint256 baseFees = 0;
		
		if (!isMint || mintFeesType == 1 || mintFeesType == 3){
			baseFees += _baseFees[nftType] + _baseFeesAdd[nftType][nftSubType];
		}
		
		
		if(!isMint || mintFeesType == 2 || mintFeesType == 3){
			BorrowFees storage borrowFeesBase = _borrowFees[nftType];
			BorrowFees storage borrowFeesAddBase = _borrowFeesAdd[nftType][nftSubType];
			
			if (borrowFeesBase.feesMax > 0){
				uint256 borrowFees = borrowFeesBase.feesMin;
				if (borrowDuration >= borrowFeesBase.durationMax){
					borrowFees = borrowFeesBase.feesMax;
				}else if (borrowDuration >= borrowFeesBase.durationMin){
					borrowFees = borrowFeesBase.feesMin + ((borrowFeesBase.feesMax - borrowFeesBase.feesMin) * (borrowDuration - borrowFeesBase.durationMin)) / (borrowFeesBase.durationMax - borrowFeesBase.durationMin);
				}
				baseFees += borrowFees;
			}
			
			if (borrowFeesAddBase.feesMax > 0){
				uint256 borrowFeesAdd = borrowFeesAddBase.feesMin;
				if (borrowDuration >= borrowFeesAddBase.durationMax){
					borrowFeesAdd = borrowFeesAddBase.feesMax;
				}else if (borrowDuration >= borrowFeesAddBase.durationMin){
					borrowFeesAdd = borrowFeesAddBase.feesMin + ((borrowFeesAddBase.feesMax - borrowFeesAddBase.feesMin) * (borrowDuration - borrowFeesAddBase.durationMin)) / (borrowFeesAddBase.durationMax - borrowFeesAddBase.durationMin);
				}
				baseFees += borrowFeesAdd;
			}
		}
		
		if (isMint && baseFees>0 && mintNb>1){
			baseFees *= mintNb;
			uint256 feesRebate = (baseFees * (mintNb-1) * _groupMintFeesRebate.numerator) / ((_groupMintNbLimit-1) * _groupMintFeesRebate.denominator);
			baseFees -= feesRebate;
		}
		
		return baseFees;
	}
	
	
	function getFees(uint256 nftType, uint256 nftSubType, uint256 bidPrice, bool withFirstBuyRebate, uint256 initialBorrowDuration, uint256 currentBorrowDuration) public view returns (uint256){
		uint256 fundingFees = 0;
		if (_fundingFees[nftType].denominator > 0){
			if (_fundingFeesAdd[nftType][nftSubType].denominator > 0){
				fundingFees = (bidPrice * (_fundingFees[nftType].numerator*_fundingFeesAdd[nftType][nftSubType].denominator + _fundingFeesAdd[nftType][nftSubType].numerator*_fundingFees[nftType].denominator)) / (_fundingFees[nftType].denominator * _fundingFeesAdd[nftType][nftSubType].denominator);
			}else{
				fundingFees = (bidPrice * _fundingFees[nftType].numerator) / _fundingFees[nftType].denominator;
			}
		}else{
			if (_fundingFeesAdd[nftType][nftSubType].denominator > 0){
				fundingFees = (bidPrice * _fundingFeesAdd[nftType][nftSubType].numerator) / _fundingFeesAdd[nftType][nftSubType].denominator;
			}
		}
		
		uint256 rebateMintFees = 0;
		if (withFirstBuyRebate){
			rebateMintFees = getBaseFees(nftType, nftSubType, initialBorrowDuration, true, 1);
		}
		
		uint256 baseFees = getBaseFees(nftType, nftSubType, currentBorrowDuration, false, 1);
		
		uint256 finalFees = _max(baseFees, fundingFees);
		
		if (rebateMintFees > finalFees){
			return 0;
		}else{
			return finalFees - rebateMintFees;
		}
	}
	
	function dispatchRoyaltyTransferFees(uint256 nftType, uint256 nftSubType) external payable{
		payable(owner()).transfer(msg.value);
	}
	
	function dispatchRoyaltyMintFees(uint256 nftType, uint256 nftSubType) external payable{
		payable(owner()).transfer(msg.value);
	}
	
	function dispatchRoyaltySellFees(uint256 nftType, uint256 nftSubType) external payable{
		uint256 fees = msg.value;
		
		if (fees > 0){
			uint256 l = _royaltyFeesAdd[nftType][nftSubType].length;
			
			for (uint256 i = 0; i < l; i++){
				RoyaltyFees storage rf = _royaltyFeesAdd[nftType][nftSubType][i];
				uint256 royaltyFees = (fees * rf.fees.numerator) / rf.fees.denominator;
				
				if (royaltyFees > 0){
					payable(rf.receiver).transfer(royaltyFees);
					fees -= royaltyFees;
				}
			}
		}
		
		if (fees > 0){
			uint256 l = _royaltyFees[nftType].length;
			
			for (uint256 i = 0; i < l; i++){
				RoyaltyFees storage rf = _royaltyFees[nftType][i];
				uint256 royaltyFees = (fees * rf.fees.numerator) / rf.fees.denominator;
				
				if (royaltyFees > 0){
					payable(rf.receiver).transfer(royaltyFees);
					fees -= royaltyFees;
				}
			}
		}
		
		if (fees > 0){
			payable(owner()).transfer(fees);
		}
	}
	////
	////
	////
	//////////////// Private functions ////////////////
	
	////
	////
	////
	//////////////// Default functions ////////////////
	receive() external payable {
		payable(owner()).transfer(msg.value);
	}
	
	fallback() external payable{
		payable(owner()).transfer(msg.value);
	}
}