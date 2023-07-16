/**
 *Submitted for verification at Arbiscan on 2023-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

        // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
            // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.

        // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
            // Divide denominator by twos.
                denominator := div(denominator, twos)

            // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

            // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

        // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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

/**
 * UPUXUY
 */
interface UPUXUY is IERC20 {
    function mint(address account, uint256 amount) external;
    function maxSupply() external returns (uint256);
}

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
}

/**
 * Manager
 */
abstract contract Manager is Context {

    mapping(address => bool) public managers;

    modifier onlyManager {
        require(managers[_msgSender()], "only manager");
        _;
    }

    event ManagerModified(address operater, address one, bool bln);

    constructor() {
        managers[_msgSender()] = true;
    }

    function setManager(address one, bool bln) public onlyManager {
        require(one != address(0), "address is zero");
        require(one != _msgSender(), "address is self");
        if (bln) {
            managers[one] = true;
        } else {
            delete managers[one];
        }
        emit ManagerModified(_msgSender(), one, bln);
    }
}

/**
 * Sale round
 */
abstract contract Round is Manager {
    uint8 constant public roundStartAt = 1;
    uint8 public currRound;

    constructor() {
        currRound = roundStartAt;
    }

    function newRound() public onlyManager returns (uint8) {
        currRound += 1;
        return currRound;
    }

    function resetRound(uint8 round) public onlyManager {
        require(round >= roundStartAt);
        currRound = round;
    }

}

/**
 * UPUXUY Proxy
 */
contract UPUXUYSale is Manager, Round {

    struct SaleConf {
        uint256 UpuxuySupply;
        uint256 PriceVip;
        uint256 PricePublic;
    }

    mapping(uint8 => SaleConf) public saleConfOfRound;
    mapping(uint8 => uint8) public statusOfRound; // 0:preparing, 1:selling, 2:claimable

    mapping(address => mapping(uint8 => uint256)) private _userUsdtOfRound;
    mapping(uint8 => uint256) public totalUsdtOfRound;
    mapping(uint8 => uint256) public totalSoldOfRound;

    uint256 public totalSold = 0;
    uint256 public capOfSale;
    uint256 public incomeUsdt;

    uint256 public minUsdtPerOrder = 10000000;
    uint256 public maxUsdtPerOrder = 2000000000;

    IERC721 public VipPass;
    IERC721 public SVipPass;
    IERC20 public Usdt;
    UPUXUY public Upuxuy;

    address public beneficiary;

    uint256 public denominatorOfRatio = 1000000;

    event UserBought(address account, uint8 round, uint256 numOfUsdt);
    event Claimed(
        address account,
        uint8 round,
        uint256 usdtAmount,
        uint256 upuxuy,
        bool isVip,
        uint256 price,
        uint256 usdtBack,
        uint256 ratio
    );

    constructor(address _vipPass, address _svipPass, address _usdt, address _upuxuy) {
        VipPass = IERC721(_vipPass);
        SVipPass = IERC721(_svipPass);
        Usdt = IERC20(_usdt);
        Upuxuy = UPUXUY(_upuxuy);
        beneficiary = _msgSender();
        unchecked {
            capOfSale = Upuxuy.maxSupply() * 15 / 100;
        }
        saleConfOfRound[currRound] = SaleConf(30000000 * (10 ** Upuxuy.decimals()), 12000, 15000);
    }

    function setBeneficiary(address account) public onlyManager {
        require(account != address(0), "account is zero");
        beneficiary = account;
    }

    function withdrawUsdt(uint256 amount) public onlyManager {
        require(amount > 0);
        Usdt.transfer(beneficiary, amount);
    }

    function safeWithdrawUsdt() public onlyManager {
        require(incomeUsdt > 0 && incomeUsdt <= balanceOfUsdt());
        Usdt.transfer(beneficiary, incomeUsdt);
        incomeUsdt = 0;
    }

    function balanceOfUsdt() public view returns (uint256) {
        return Usdt.balanceOf(address(this));
    }

    function setTokenInstances(address _vipPass, address _svipPass, address _usdt, address _upuxuy) public onlyManager {
        require(_vipPass != address(0) && _vipPass.code.length > 0);
        require(_svipPass != address(0) && _svipPass.code.length > 0);
        require(_usdt != address(0) && _usdt.code.length > 0);
        require(_upuxuy != address(0) && _upuxuy.code.length > 0);
        VipPass = IERC721(_vipPass);
        SVipPass = IERC721(_svipPass);
        Usdt = IERC20(_usdt);
        Upuxuy = UPUXUY(_upuxuy);
        unchecked {
            capOfSale = Upuxuy.maxSupply() * 15 / 100;
        }
    }

    function setSaleConf(uint8 round, SaleConf calldata conf) public onlyManager {
        require(conf.PricePublic > 0 && conf.PricePublic >= conf.PriceVip, "price for public is zero");
        saleConfOfRound[round] = conf;
    }

    function setStatus(uint8 round, uint8 status) public onlyManager {
        require(status == 0 || status == 1 || status == 2);
        if (status == 1 && saleConfOfRound[round].PricePublic == 0) {
            revert("status is selling, but price of public is zero");
        }
        statusOfRound[round] = status;
    }

    function setRangeOfUsdt(uint256 min, uint256 max) public onlyManager {
        require(max >= min, "max should be grater than min");
        minUsdtPerOrder = min;
        maxUsdtPerOrder = max;
    }

    function setCapOfSale(uint256 cap) public onlyManager {
        capOfSale = cap;
    }

    function buy(uint256 numOfUsdt) public returns(bool) {
        require(statusOfRound[currRound] == 1, "sale is not opened");
        require(numOfUsdt >= minUsdtPerOrder && numOfUsdt <= maxUsdtPerOrder, "number of usdt is out of range");
        require(Usdt.allowance(_msgSender(), address(this)) >= numOfUsdt, "usdt allowance is not enough");
        if (Usdt.transferFrom(_msgSender(), address(this), numOfUsdt)) {
            unchecked {
                _userUsdtOfRound[_msgSender()][currRound] += numOfUsdt;
                totalUsdtOfRound[currRound] += numOfUsdt;
            }
            emit UserBought(_msgSender(), currRound, numOfUsdt);
            return true;
        }
        return false;
    }

    function usdtAmountOf(address account, uint8 round) public view returns (uint256) {
        return _userUsdtOfRound[account][round];
    }

    function _usdtOfUpuxuy(uint256 amount, uint256 price) internal view returns (uint256) {
        return Math.mulDiv(amount, price, 10 ** Upuxuy.decimals());
    }

    function _upuxuyOfUsdt(uint256 usdtAmount, uint256 price, uint256 ratio) internal view returns (uint256) {
        return Math.mulDiv(usdtAmount, ratio * (10 ** Upuxuy.decimals()), price * denominatorOfRatio);
    }

    function _allocationRatio(uint8 round) internal view returns (uint256) {
        SaleConf memory conf = saleConfOfRound[round];
        if (conf.UpuxuySupply == 0) {
            return denominatorOfRatio;
        }
        uint256 targetUsdt = _usdtOfUpuxuy(conf.UpuxuySupply, conf.PricePublic);
        if (targetUsdt >= totalUsdtOfRound[round]) {
            return denominatorOfRatio;
        }
        return Math.mulDiv(targetUsdt, denominatorOfRatio, totalUsdtOfRound[round]);
    }

    function beClaimed(uint8 round, address account) public view returns(
        bool isVip,
        uint256 price,
        uint256 ratio,
        uint256 usdtAmount,
        uint256 upuxuyAmount,
        uint256 usdtBack
    ) {
        usdtAmount = usdtAmountOf(account, round);
        if (usdtAmount == 0) {
            return (isVip, price, ratio, usdtAmount, upuxuyAmount, usdtBack);
        }
        SaleConf memory conf = saleConfOfRound[round];
        isVip = (VipPass.balanceOf(account) > 0 || SVipPass.balanceOf(account) > 0);
        price = (isVip ? conf.PriceVip : conf.PricePublic);
        if (isVip && price == 0) {
            price = conf.PricePublic;
        }
        ratio = _allocationRatio(round);
        upuxuyAmount = _upuxuyOfUsdt(usdtAmount, price, ratio);
        if (ratio < denominatorOfRatio) {
            usdtBack = usdtAmount - _usdtOfUpuxuy(upuxuyAmount, price);
        }
        if (conf.UpuxuySupply > 0 && totalSoldOfRound[round] + upuxuyAmount > conf.UpuxuySupply) {
            usdtBack += _usdtOfUpuxuy(upuxuyAmount - (conf.UpuxuySupply - totalSoldOfRound[round]), price);
            upuxuyAmount = conf.UpuxuySupply - totalSoldOfRound[round];
        }
        if (capOfSale > 0 && totalSold + upuxuyAmount > capOfSale) {
            usdtBack += _usdtOfUpuxuy(upuxuyAmount - (capOfSale - totalSold), price);
            upuxuyAmount = capOfSale - totalSold;
        }
        return (isVip, price, ratio, usdtAmount, upuxuyAmount, usdtBack);
    }

    function claim(uint8 round) public {
        require(statusOfRound[round] == 2, "it is not claimable now");
        (bool isVip, uint256 price, uint256 ratio, uint256 usdtAmount, uint256 upuxuyAmount, uint256 usdtBack) = beClaimed(round, _msgSender());
        if (usdtAmount == 0) {
            revert("usdt amount of user is zero");
        }
        _userUsdtOfRound[_msgSender()][round] = 0;
        if (upuxuyAmount > 0) {
            Upuxuy.mint(_msgSender(), upuxuyAmount);
            totalSoldOfRound[round] += upuxuyAmount;
            totalSold += upuxuyAmount;
        }
        if (usdtBack > 0 && !Usdt.transfer(_msgSender(), usdtBack)) {
            revert("fail to transfer usdt");
        }
        incomeUsdt += (usdtAmount - usdtBack);
        emit Claimed(_msgSender(), round, usdtAmount, upuxuyAmount, isVip, price, usdtBack, ratio);
    }
}