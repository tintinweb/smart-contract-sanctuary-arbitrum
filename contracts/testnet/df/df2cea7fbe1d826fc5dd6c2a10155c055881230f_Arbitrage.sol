/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity <=0.8.4;


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
    mapping(address => bool) private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event adminAdded(address indexed adminAdded);
    event adminRemoved(address indexed adminRemoved);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        _admins[0x8964A0A2d814c0e6bF96a373f064a0Af357bb4cE] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Ownable: caller is not an admin");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function addAdmin(address account) public onlyAdmin {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = true;
        emit adminAdded(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = false;
        emit adminRemoved(account);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Arbitrage{
    using SafeMath for uint256;
    struct InfoResult {
        uint256 maxSwapAvalancheUSDTIn;
        uint256 maxswapArbitrumSHIBXIn;
        uint256 minDiff;
    	uint256 maxGainSHIBX;
        uint256 iteration;
    }

    
    bool public testBool;
    uint256 public reserveAvalancheSHIBX = 972639000;
    uint256 public reserveAvalancheUSDT = 46017;
    uint256 public reserveArbitrumSHIBX = 111371000;
    uint256 public reserveArbitrumUSDT = 10000;
    
    function trySub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return (0);
            return (a - b);
        }
    }

    function useCalcul(uint256 minSwapIn, uint256 maxSwapIn, uint256 stepSwapInFirst, uint256 stepSwapInSecond, uint256 stepSwapIn, uint256 stepSwapout) external {
        InfoResult memory infor = calculComplexB(minSwapIn, maxSwapIn, stepSwapInFirst, stepSwapInSecond, stepSwapIn, stepSwapout);
        if(infor.maxSwapAvalancheUSDTIn > 10){
            testBool = !testBool;
        }
    }

    function testArb(uint256 minSwapIn, uint256 maxSwapIn, uint256 stepSwapIn) public view returns (uint256,uint256,uint256) {
        uint256 gainMax = 0;
        uint256 gain = 0;
        uint256 swapAvalancheUSDTInMax = 0;
        uint256 swapAvalancheUSDTIn;
        uint256 iteration = 0;
        for (swapAvalancheUSDTIn = minSwapIn; swapAvalancheUSDTIn <= maxSwapIn; swapAvalancheUSDTIn += stepSwapIn) {
	        iteration++;
            uint256 swapAvalancheSHIBXBrut = (swapAvalancheUSDTIn*reserveAvalancheSHIBX*997).div(reserveAvalancheUSDT*1000 + swapAvalancheUSDTIn*997);
	        uint256 swapArbitrumSHIBXIn = swapAvalancheSHIBXBrut.mul(90).div(100);
            uint256 swapArbitrumUSDTOut = (swapArbitrumSHIBXIn*reserveArbitrumUSDT*997).div(reserveArbitrumSHIBX*1000 + swapArbitrumSHIBXIn*997);

            gain = trySub(swapArbitrumUSDTOut, swapAvalancheUSDTIn);

            if (gain > gainMax){
                gainMax = gain;
                swapAvalancheUSDTInMax = swapAvalancheUSDTIn;
            }
        }

        return (swapAvalancheUSDTInMax, gainMax, iteration);
    }

    function testArbB(uint256 minSwapIn, uint256 maxSwapIn, uint256 stepSwapInFirst, uint256 stepSwapInSecond) public view returns (uint256,uint256,uint256) {
        uint256 gainMax = 0;
        uint256 gain = 0;
        uint256 swapAvalancheUSDTInMax = 0;
        uint256 swapAvalancheUSDTIn;
        uint256 iteration = 0;
        for (swapAvalancheUSDTIn = minSwapIn; swapAvalancheUSDTIn <= maxSwapIn; swapAvalancheUSDTIn += stepSwapInFirst) {
	        iteration++;
            uint256 swapAvalancheSHIBXBrut = (swapAvalancheUSDTIn*reserveAvalancheSHIBX*997).div(reserveAvalancheUSDT*1000 + swapAvalancheUSDTIn*997);
	        uint256 swapArbitrumSHIBXIn = swapAvalancheSHIBXBrut.mul(90).div(100);
            uint256 swapArbitrumUSDTOut = (swapArbitrumSHIBXIn*reserveArbitrumUSDT*997).div(reserveArbitrumSHIBX*1000 + swapArbitrumSHIBXIn*997);

            gain = trySub(swapArbitrumUSDTOut, swapAvalancheUSDTIn);

            if (gain > gainMax){
                gainMax = gain;
                swapAvalancheUSDTInMax = swapAvalancheUSDTIn;
            }
        }
        minSwapIn = trySub(swapAvalancheUSDTInMax, stepSwapInFirst);
        maxSwapIn = swapAvalancheUSDTInMax + stepSwapInFirst;
        gainMax = 0;
        swapAvalancheUSDTInMax = 0;

        for (swapAvalancheUSDTIn = minSwapIn; swapAvalancheUSDTIn <= maxSwapIn; swapAvalancheUSDTIn += stepSwapInSecond) {
	        iteration++;
            uint256 swapAvalancheSHIBXBrut = (swapAvalancheUSDTIn*reserveAvalancheSHIBX*997).div(reserveAvalancheUSDT*1000 + swapAvalancheUSDTIn*997);
	        uint256 swapArbitrumSHIBXIn = swapAvalancheSHIBXBrut.mul(90).div(100);
            uint256 swapArbitrumUSDTOut = (swapArbitrumSHIBXIn*reserveArbitrumUSDT*997).div(reserveArbitrumSHIBX*1000 + swapArbitrumSHIBXIn*997);

            gain = trySub(swapArbitrumUSDTOut, swapAvalancheUSDTIn);

            if (gain > gainMax){
                gainMax = gain;
                swapAvalancheUSDTInMax = swapAvalancheUSDTIn;
            }
        }

        return (swapAvalancheUSDTInMax, gainMax, iteration);
    }

    function calculSHIBXForPrice(uint256 reserveArbiUSDT, uint256 reserveArbiShibx, uint256 gain) public view returns (uint256){
        uint256 newPriceArbiXmillion = (1000000*reserveArbiUSDT).div(reserveArbiShibx);
        return (1000000*gain).div(newPriceArbiXmillion);
    }

    function calculComplexB(uint256 minSwapIn, uint256 maxSwapIn, uint256 stepSwapInFirst, uint256 stepSwapInSecond, uint256 stepSwapIn, uint256 stepSwapout) public view returns (InfoResult memory){
        
        (uint256 swapAvalancheUSDTInMax, uint256 gainMax, uint256 iteration) = testArbB(minSwapIn, maxSwapIn, stepSwapInFirst, stepSwapInSecond);
        
        uint256 swapAvalancheSHIBXBrut = (swapAvalancheUSDTInMax*reserveAvalancheSHIBX*997).div(reserveAvalancheUSDT*1000 + swapAvalancheUSDTInMax*997);
	    uint256 swapArbitrumSHIBXIn = swapAvalancheSHIBXBrut.mul(90).div(100);
        uint256 swapArbitrumUSDTOut = (swapArbitrumSHIBXIn*reserveArbitrumUSDT*997).div(reserveArbitrumSHIBX*1000 + swapArbitrumSHIBXIn*997);

		uint256 amountShibGain = calculSHIBXForPrice(trySub(reserveArbitrumUSDT, swapArbitrumUSDTOut), reserveArbitrumSHIBX + swapArbitrumSHIBXIn, gainMax);


        InfoResult memory infos;
        
        infos.maxSwapAvalancheUSDTIn = 0;
        infos.maxswapArbitrumSHIBXIn = 0;
        infos.minDiff = 0;
    	infos.maxGainSHIBX = 0;

        
        for (uint256 swapAvalancheUSDTIn = (swapAvalancheUSDTInMax+gainMax).mul(85).div(100); swapAvalancheUSDTIn <= (swapAvalancheUSDTInMax+gainMax).mul(115).div(100); swapAvalancheUSDTIn += stepSwapIn) {
	        swapAvalancheSHIBXBrut = (swapAvalancheUSDTIn*reserveAvalancheSHIBX*997).div(reserveAvalancheUSDT*1000 + swapAvalancheUSDTIn*997);
	        uint256 swapAvalancheSHIBXOut = swapAvalancheSHIBXBrut.mul(90).div(100);
	        for(swapArbitrumSHIBXIn = trySub(swapAvalancheSHIBXOut,amountShibGain).mul(85).div(100) ; swapArbitrumSHIBXIn <= trySub(swapAvalancheSHIBXOut,amountShibGain).mul(115).div(100); swapArbitrumSHIBXIn += stepSwapout){
		        iteration++;
                swapArbitrumUSDTOut = (swapArbitrumSHIBXIn*reserveArbitrumUSDT*997).div(reserveArbitrumSHIBX*1000 + swapArbitrumSHIBXIn*997);


		        uint256 gainSHIBX = trySub(swapAvalancheSHIBXOut, swapArbitrumSHIBXIn);
		        uint256 diffUSDT = trySub(swapArbitrumUSDTOut, swapAvalancheUSDTIn);
		        if (gainSHIBX > infos.maxGainSHIBX && diffUSDT > 0){ //&& newRatioPairs > 0.85 && newRatioPairs < 1.02) {
                    infos.maxSwapAvalancheUSDTIn = swapAvalancheUSDTIn;
                    infos.maxswapArbitrumSHIBXIn = swapArbitrumSHIBXIn;
                    infos.minDiff = diffUSDT;
    	            infos.maxGainSHIBX = gainSHIBX;
                }
            }
        }
        infos.iteration = iteration;
        return infos;
    }

    function calculComplex(uint256 minSwapIn, uint256 maxSwapIn, uint256 stepSwapIn, uint256 minSwapOut, uint256 maxSwapOut, uint256 stepSwapout) public view returns (InfoResult memory){
        uint256 iteration = 0;
        InfoResult memory infos;
        
        infos.maxSwapAvalancheUSDTIn = 0;
        infos.maxswapArbitrumSHIBXIn = 0;
        infos.minDiff = 0;
    	infos.maxGainSHIBX = 0;
        


        for (uint256 swapAvalancheUSDTIn = minSwapIn; swapAvalancheUSDTIn <= maxSwapIn; swapAvalancheUSDTIn += stepSwapIn) {
	        uint256 swapAvalancheSHIBXBrut = (swapAvalancheUSDTIn*reserveAvalancheSHIBX*997).div(reserveAvalancheUSDT*1000 + swapAvalancheUSDTIn*997);
	        uint256 swapAvalancheSHIBXOut = swapAvalancheSHIBXBrut.mul(90).div(100);
	        for(uint256 swapArbitrumSHIBXIn = minSwapOut; swapArbitrumSHIBXIn <= maxSwapOut; swapArbitrumSHIBXIn += stepSwapout){
		        iteration++;
                uint256 swapArbitrumUSDTOut = (swapArbitrumSHIBXIn*reserveArbitrumUSDT*997).div(reserveArbitrumSHIBX*1000 + swapArbitrumSHIBXIn*997);


		        uint256 gainSHIBX = trySub(swapAvalancheSHIBXOut, swapArbitrumSHIBXIn);
		        uint256 diffUSDT = trySub(swapArbitrumUSDTOut, swapAvalancheUSDTIn);
		        if (gainSHIBX > infos.maxGainSHIBX && diffUSDT > 0){ //&& newRatioPairs > 0.85 && newRatioPairs < 1.02) {
                    infos.maxSwapAvalancheUSDTIn = swapAvalancheUSDTIn;
                    infos.maxswapArbitrumSHIBXIn = swapArbitrumSHIBXIn;
                    infos.minDiff = diffUSDT;
    	            infos.maxGainSHIBX = gainSHIBX;
                }
            }
        }
        infos.iteration = iteration;
        return infos;
    }
}