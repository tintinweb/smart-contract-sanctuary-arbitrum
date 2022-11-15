/**
 *Submitted for verification at Arbiscan on 2022-11-01
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/crossChain/ArbGoerli_golier_eth.sol


pragma solidity ^0.8.7;
//走通


interface IOfficialBridgeEth{

    function withdrawEth(address destination) external payable returns (uint256);
    
}


//goerli cross chain
contract EchoooEthSwap  is ReentrancyGuard{
    // address private officialBridge = 0x4c7708168395aea569453fc36862d2ffcdac588c;
    // address private USDCtoken = 	0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    // address to = 0x4d2E1A38d07Eadf5C62CfDaF93547DAe09F1EF83;

    // 
    // amount = 13500000
    // masGas = 96111
    // gasPriceBid = 300000000
    // _data = 0x000000000000000000000000000000000000000000000000000520715223274000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000

    uint256 private MAX_INT = type(uint256).max;

    

    function echoooCrossChahin(address _officialBridge) 
        public 
        payable 
        nonReentrant{
       
        IOfficialBridgeEth(_officialBridge).withdrawEth{value: msg.value}(msg.sender);
        


    }







}