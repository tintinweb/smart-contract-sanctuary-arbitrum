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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
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

/**
 * https://arcadeum.io
 * https://arcadeum.gitbook.io/arcadeum
 * https://twitter.com/arcadeum_io
 * https://discord.gg/qBbJ2hNPf8
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";

contract VestingContractA is Ownable, ReentrancyGuard {
    address public immutable ARC;
    IERC20 public immutable arc;
    address public immutable ALP;
    IERC20 public immutable alp;

    mapping (address => uint256) public ethAmount;
    mapping (address => mapping (uint256 => bool)) public claims;
    mapping (address => uint256) public claimedTokens;
    mapping (address => uint256) public claimedLpTokens;
    uint256 public ethTotal = 113.7397075 ether;
    uint256 public start;
    uint256 public alpTotal;

    constructor (address _ARC, address _ALP) {
        ARC = _ARC;
        arc = IERC20(_ARC);
        ALP = _ALP;
        alp = IERC20(_ALP);

        ethAmount[0x21a138B7b784B33e25C0C0f7C8b4CC3d5F0a1A68] = 1.01507872 ether;
        ethAmount[0x940122cD634fE1f78516fb4b43Cb50a483e19bcF] = 0.04 ether;
        ethAmount[0x9b883561D4b698bE756E4E6feD39294A395714B4] = 0.69 ether;
        ethAmount[0x1C4e90fC8bdAdE442aeD58f8011db5A17A2E7199] = 0.4 ether;
        ethAmount[0x3BFFe09239a9C6f8edD82bD492E8FC5e33BeF2FB] = 0.25 ether;
        ethAmount[0x504C11bDBE6E29b46E23e9A15d9c8d2e2e795709] = 0.4 ether;
        ethAmount[0x505920cf689Dc11bc0Fb6013c4d0ec5C59EbB7C1] = 0.5 ether;
        ethAmount[0x3A2b83D7BcC7193835b66e82Ae67543499a0Fa4D] = 5.99296542 ether;
        ethAmount[0xd0Ab8b0a1b06dCBECAa84d153D6230bB59Cf0B75] = 1 ether;
        ethAmount[0xb88a66748152b5FfA55073a49D17F92d9a678b59] = 1 ether;
        ethAmount[0xf6a6600676e86cb0E9bB03DB53421F3447BF9521] = 0.5 ether;
        ethAmount[0x43aD4E9b8C700243593bF36C1589141F37fdE50A] = 0.1 ether;
        ethAmount[0xf5d63F15FD8981C86216c5A75d1c33824B35Ea7F] = 0.7 ether;
        ethAmount[0x6Ff93966600654Bb3ce79b48611EB5b645866E60] = 0.1 ether;
        ethAmount[0xe564D4c8CEd4B55806a9c506daCB45316F161509] = 0.971 ether;
        ethAmount[0xd3f5e357b72209221b40042927802Cf6735B8F29] = 1 ether;
        ethAmount[0x4d96b836AA9B8Ef3Df1D5C0dfE236e30A47aA492] = 0.275 ether;
        ethAmount[0x51359C4b8bA769096Db4F29E9EdC1E66072508A1] = 0.25 ether;
        ethAmount[0x322EC9A02c79B8E9f9f59d69907236022518B184] = 1.5 ether;
        ethAmount[0x3e9e097A6AE52E55071d31A3AcF39A9d6BdF45d1] = 0.95 ether;
        ethAmount[0xA867f01382bdDB3BC9525D1151c96c42F4d6d4bc] = 1 ether;
        ethAmount[0xAc324b01C417dBf1c694c18e804047125558f0eB] = 1 ether;
        ethAmount[0xe6F67C6584CCF9af065E4029Cfc14931689B8533] = 0.5 ether;
        ethAmount[0xAAEfd6dfEfEd6877af7B99811C8CC712D35F6f4c] = 0.65 ether;
        ethAmount[0x8eA0142615c68352149A786bfa4DcA78a9a15804] = 1 ether;
        ethAmount[0x2592552707B9575AfB566178134118A69D97FE29] = 0.3 ether;
        ethAmount[0x1fCE7B2cDd7296395674DA2896AdE417163590d4] = 1 ether;
        ethAmount[0xc0DFCF7715f1CC0B774f760F9C050DFc18870355] = 1 ether;
        ethAmount[0xe267D998977C5dDA00Bd5b7aE6e6eF4Ed13598B4] = 1 ether;
        ethAmount[0x486cC315bcB7AF362D7C57dCdDBb1E8e5e802840] = 0.2 ether;
        ethAmount[0x7045a0282F1E2A5C6B05BB3e4f2dCb5FE20aa0be] = 0.63 ether;
        ethAmount[0xFdF178a734992a8b065008b35199951Eda8568a8] = 0.6496633454 ether;
        ethAmount[0x20145790f8537a2790c9d93578Fc1BD52B2b8EDC] = 1 ether;
        ethAmount[0x9Df282356F1D84410732F3ba71E862aDde9bee57] = 1 ether;
        ethAmount[0x8F18547e9FFBB4417Bd32c6FBEb78bdEBBbA1F07] = 1 ether;
        ethAmount[0x517f70d1ECFC3a221fbd8Ce28749E591B545134e] = 0.3 ether;
        ethAmount[0x3e9D51eB02948E6D0680DD94C9a707B352453407] = 1.15 ether;
        ethAmount[0x4696260a63EA4cccCF3Ff51a2074556BA7d75277] = 1 ether;
        ethAmount[0x704AdC4DB623E34E84C6eEA0E36a12cCa079005b] = 0.45 ether;
        ethAmount[0xC04789074529e8F5d7f44f9A16d4C10D7b6660F0] = 1 ether;
        ethAmount[0x6ee6481Aa4Ca96c480D128EBc0e8181E3821c1e1] = 1 ether;
        ethAmount[0x198E18EcFdA347c6cdaa440E22b2ff89eaA2cB6f] = 1 ether;
        ethAmount[0x808518fe8159254D3372b31474BE6520B38d17F5] = 0.85 ether;
        ethAmount[0x104B2618231020b4320580b40FE05dce77323fa1] = 1 ether;
        ethAmount[0xEd660e8d8585d0e87fda16e52dcd9fdf4Bca60b8] = 0.8 ether;
        ethAmount[0x94964248c6e186EE55e3d20B9CB28808aD386bDD] = 1 ether;
        ethAmount[0x314cA4B2517DA4FA848444FE1eE2d107b2CB4Bb8] = 5 ether;
        ethAmount[0x0891C5d51232f4b98c53132dA4F642bb394382E7] = 1 ether;
        ethAmount[0xd978284426E4b8F7A36724527CDdced79f373E7d] = 1 ether;
        ethAmount[0xb85e9E5Bb74C113d2ca13c6786e8599ba4fca3FE] = 0.69 ether;
        ethAmount[0x7a14C9fD3C6BfEb91Ee27313C53De2FFe0ca3A87] = 1 ether;
        ethAmount[0xCCb500F042A25EA50d4076CEE6f0d6C7fCd488d3] = 0.2 ether;
        ethAmount[0xC443D816a011D720DC8f3dD69390B16554ff2A3B] = 0.5 ether;
        ethAmount[0xbAB05baA77c2D843e6F599B7a13F1d5d3c7BfA95] = 1 ether;
        ethAmount[0xd961431087eb2A313E0E4a8F1f45FfFD667b60CB] = 1 ether;
        ethAmount[0x065C84641EE62d032ea5F20C49d59817C87A2747] = 0.3 ether;
        ethAmount[0xbDF50c8987C00F182D18bEc4E4bb29FB75D4Cf24] = 0.5 ether;
        ethAmount[0x3a983C4Cecd5AfD77D77DCd7BbEDEA6D0C9ED58a] = 0.3 ether;
        ethAmount[0xcBA64393Ab4087bf5fDC63E8D47580CE9cf6e977] = 2.5 ether;
        ethAmount[0x9C8c2E523caF5f3AEC666067dA55E0F8FfCafFf7] = 1 ether;
        ethAmount[0x087F09C79656E86092d759ECDC3bB6AE2C45a2B5] = 1 ether;
        ethAmount[0x57a17699c0BE27bABd42aE92E1549e5cD34d8313] = 2 ether;
        ethAmount[0x9A60e13219a2A354Ee000Ea6DFf4e55C95894F89] = 1 ether;
        ethAmount[0x1143b2ce2D1a86892CEB131725F95D30d69e12C6] = 10 ether;
        ethAmount[0x282AAf3097A22194264BeFf53e8AE8003122b841] = 1 ether;
        ethAmount[0x98dE6469060cAcBf342bfF4Df01E5D4D51EEd42e] = 1 ether;
        ethAmount[0x517f70d1ECFC3a221fbd8Ce28749E591B545134e] = 0.2 ether;
        ethAmount[0x0d9F4B77956AC86A75aCA47601c4E7AFC9021A3d] = 1 ether;
        ethAmount[0xC38E6E02fCbC9436Ac89ee4234d6bFd3755E0A07] = 3.08 ether;
        ethAmount[0x943fbbC1F2D8806966482cE5D93623C4FF1Aca76] = 1 ether;
        ethAmount[0xdE33e58F056FF0f23be3EF83Ab6E1e0bEC95506f] = 1 ether;
        ethAmount[0x0B516Edc029eC08075B7d4E0267f6D5015E2C342] = 0.5 ether;
        ethAmount[0xeC52a9033264Bf31E13fe252813b6cf21d81672F] = 3 ether;
        ethAmount[0xc6571c2FB66825F13b7751b1c334810D397618Eb] = 0.33 ether;
        ethAmount[0x80CA46AD1f1618678F1433B05c610ba664231Ae5] = 0.2 ether;
        ethAmount[0xb273F2eFDab32bDF5639b58A7993a096f054A7d1] = 0.3 ether;
        ethAmount[0x8adF1453d0FC7Dcfa198E17810F94Ca6AC604929] = 0.31 ether;
        ethAmount[0x29152B33FB4765f54c3146b64EcC9355d534c12c] = 0.026 ether;
        ethAmount[0x8aD9dBC38ea6D4022Dc6E93e2BA003Ed364759C7] = 0.1 ether;
        ethAmount[0x93f5af632Ce523286e033f0510E9b3C9710F4489] = 3 ether;
        ethAmount[0xC13A80fD29cdDF5290d2e301b3121DF0B73b4401] = 0.2 ether;
        ethAmount[0xe1c022F562Df88fB46C36Ac3F5630530105805DC] = 2 ether;
        ethAmount[0x0c18cc3c5851802aBeF52E10118c2Ad6F391bf7A] = 2 ether;
        ethAmount[0xE5397b6E5afA8Fa9911FaC6b9bA51DA86A8dC353] = 0.2 ether;
        ethAmount[0xF3E36e557A325AF44aCc5834759055819e22Aece] = 0.03 ether;
        ethAmount[0x11C4847ed35d77C7B77AbBde78D760Bc91d1ad61] = 0.2 ether;
        ethAmount[0x1388675fD5D12F9Ffd0BC24b242277C7C6289F61] = 0.1 ether;
        ethAmount[0xb273F2eFDab32bDF5639b58A7993a096f054A7d1] = 0.2 ether;
        ethAmount[0xACD87A183f0e4D5E7cBC2314543e64F8344B9e56] = 0.1 ether;
        ethAmount[0xA763De28d2Ee0c6Ae75A6e2d9c611fB78744149c] = 0.3 ether;
        ethAmount[0x8EcAE2e000b1e08278711ae6195514661Eb3ef52] = 0.2 ether;
        ethAmount[0xfbbea58a9905776C146e2f0B1FddD19d8550Ea95] = 0.24 ether;
        ethAmount[0xB199eA67d5352674BB3A432b5E669B8CAE21ffc8] = 2 ether;
        ethAmount[0xf889Faab204590702c5eFE0f4A72C642a59Ad28A] = 1 ether;
        ethAmount[0xFE2fc25f5e8D82737efd1a55f6e4830EbcAc5087] = 0.7 ether;
        ethAmount[0xD3E47274ecA0bA20491CD7DCc51f50153645132A] = 2 ether;
        ethAmount[0x57d1Ac9360225B41D5E3EAd77a0b648d37CaE124] = 0.3 ether;
        ethAmount[0xCA2CC5B667D84af46b7DFf0beda86E51d1Ef22A5] = 1 ether;
        ethAmount[0xBc3ec9Ddcb6cABff1EFFC993198D1d7cB90eB90D] = 0.1 ether;
        ethAmount[0x35876B48399436664Aa7cEf8d6787aE0C25A2771] = 1 ether;
        ethAmount[0x8Ae2b29590F10cdFf143C979Fb426f8aba57201C] = 1 ether;
        ethAmount[0x373B393a729838d4b9a33a466c072f7C0a82A00D] = 0.6 ether;
        ethAmount[0x130790E1B173236af3ACDFFF814083f566c5Ebc8] = 1 ether;
        ethAmount[0x708F2D42c28659eEB32A6b091300079DE5Da762A] = 1 ether;
        ethAmount[0xB167013b024600e390b2A358AECB74a5FbBd6010] = 0.1 ether;
        ethAmount[0x5BCf75FF702e90c889Ae5c41ee25aF364ABC77cb] = 1 ether;
        ethAmount[0x5b15BAa075982Ccc6Edc7C830646030757d5272d] = 2 ether;
        ethAmount[0x93664dF1ec8D29b801419d178F9Aec0DE59fbb26] = 1 ether;
        ethAmount[0x322EC9A02c79B8E9f9f59d69907236022518B184] = 0.6 ether;
        ethAmount[0xF1b917Dc36503BA9e904f6327b698867f377592e] = 0.3 ether;
        ethAmount[0x4849fDA432A907BbFCAAc7A0e8E4B3abAED5F5c7] = 0.4 ether;
        ethAmount[0x7d1EF2483c0Ff94DEe60709EEBA0FB38b2F2953f] = 0.35 ether;
        ethAmount[0xB130a894187664b22b823DE7bB886E5C09e27d51] = 1 ether;
        ethAmount[0x047A793EC5cbFc7b110E2C5a746C72c420ac7665] = 1 ether;
        ethAmount[0x88B5CC7BC4eD7bF3763A14e52a26324f5C0aB324] = 0.16 ether;
        ethAmount[0x8aD9dBC38ea6D4022Dc6E93e2BA003Ed364759C7] = 0.1 ether;
        ethAmount[0x8d005CC8c0ff30Ac7e2343351107dE2591E3c59a] = 0.1 ether;
        ethAmount[0xEEdA7f71Df5A589a9B8c5794AA3D28D66a4ee672] = 0.15 ether;
        ethAmount[0xB199eA67d5352674BB3A432b5E669B8CAE21ffc8] = 1 ether;
        ethAmount[0x28d835135D47397f0C6A17B90f4a077796e46436] = 0.36 ether;
        ethAmount[0x84e12d5C22Ae76d666F1ee06D12EE0266fB06F3E] = 1.5 ether;

        start = block.timestamp;
    }

    function setALPTotal(uint256 _alpTotal) external nonReentrant onlyOwner {
        alpTotal = _alpTotal;
    }

    function getTokensPerAccount(address _account) public view returns (uint256) {
        if (ethAmount[_account] == 0) {
            return 0;
        }
        return (2000000 * (10**18)) * ethAmount[_account] / ethTotal;
    }

    function getLpTokensPerAccount(address _account) public view returns (uint256) {
        if (ethAmount[_account] == 0) {
            return 0;
        }
        return alpTotal * ethAmount[_account] / ethTotal;
    }

    function getClaimsByAccount(address _account) external view returns (uint256, uint256) {
        return (claimedTokens[_account], claimedLpTokens[_account]);
    }

    function claim() external nonReentrant {
        uint256 _tokens;
        uint256 _lpTokens;
        if ((block.timestamp) >= start && (!claims[msg.sender][0])) {
            _tokens += getTokensPerAccount(msg.sender) * 3100 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claims[msg.sender][0] = true;
        }
        if ((block.timestamp >= start + (86400 * 7)) && (!claims[msg.sender][1])) {
            _tokens += getTokensPerAccount(msg.sender) * 2300 / 10000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 3000 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][1] = true;
        }
        if ((block.timestamp >= start + (86400 * 14)) && (!claims[msg.sender][2])) {
            _tokens += getTokensPerAccount(msg.sender) * 2300 / 10000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 3000 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][2] = true;
        }
        if ((block.timestamp >= start + (86400 * 21)) && (!claims[msg.sender][3])) {
            _tokens += getTokensPerAccount(msg.sender) * 2300 / 10000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 4000 / 10000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][3] = true;
        }
        if (_tokens > 0) {
            arc.transfer(msg.sender, _tokens);
        }
        if (_lpTokens > 0) {
            alp.transfer(msg.sender, _lpTokens);
        }
    }

    function emergencyWithdrawToken(address _token, uint256 _amount) external nonReentrant onlyOwner {
        IERC20BackwardsCompatible(_token).transfer(msg.sender, _amount);
    }

    function emergencyWithdrawETH(uint256 _amount) external nonReentrant onlyOwner {
        payable(msg.sender).call{value: _amount}("");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BackwardsCompatible {
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
    function transfer(address to, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

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
    ) external;
}