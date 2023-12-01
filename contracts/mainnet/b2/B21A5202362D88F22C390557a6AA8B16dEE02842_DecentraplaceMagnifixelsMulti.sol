// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract DecentraplaceMagnifixelsMulti is ReentrancyGuard{

address private owner;
    uint256 public accumulatedFees;
    uint256 public painterCount = 0;
    uint256 public currentCanvasSize = 2;
    uint256 public pixelAmount = 1;
    uint256 public totalCount = 0;
    uint256[] public feeOptions = [100000000000000, 1000000000000000, 10000000000000000, 100000000000000000, 1000000000000000000];
mapping(uint256 => mapping(uint256 => uint256)) public pixelColors;
mapping(uint256 => mapping(uint256 => address)) public lastPixelChanged;
     mapping(address => uint256) public totalPixels;
    event PixelPainted(address indexed painter, uint256 x, uint256 y, uint256 color);
event AmountPixel(address indexed sender, uint256 PixelAmount);
event RewardDistributed(address indexed sender, uint256 Reward);
event SelectedFee(address indexed sender, uint256 Payment);

    constructor() {
        owner = msg.sender;
    }

    
    
    function paintPixel(uint256 x, uint256 y, uint256 color, uint256 selectedFeeIndex) external payable nonReentrant{
            require(selectedFeeIndex < feeOptions.length, "Invalid fee option selected");
        require(msg.value == feeOptions[selectedFeeIndex], "Incorrect payment amount");
         require(x <= currentCanvasSize,"the out of bounds is not paintable");
        require(y <= currentCanvasSize,"the out of bounds is not paintable");
        require(x >= 1,"the out of bounds is not paintable");
        require(y >= 1,"the out of bounds is not paintable");
        // Increment the painter count
        painterCount++;
        totalCount++;
        totalPixels[msg.sender]++;
        lastPixelChanged[x][y] = msg.sender;
        pixelColors[x][y] = color;
        // Paint the pixel
        emit PixelPainted(msg.sender, x, y, color);
        emit AmountPixel(msg.sender, pixelAmount);
        emit SelectedFee(msg.sender, feeOptions[selectedFeeIndex]);
        // Accumulate fees
        accumulatedFees += msg.value;
        
        // Check if the painter count is a power of 2
        if (painterCount == currentCanvasSize * currentCanvasSize) {
            // If it is, distribute 90% of accumulated fees to the painter
            uint256 reward = (address(this).balance * 9) / 10;
               (bool successReward, ) = payable(msg.sender).call{value: reward}("");
        require(successReward, "Transfer of Growth-Reward failed");
             (bool successTeam, ) = payable(owner).call{value: address(this).balance}("");
        require(successTeam, "Tranfer of Team Reward failed");
             currentCanvasSize ++;
             accumulatedFees = 0;
             // Emit an event for the reward
        emit RewardDistributed(msg.sender, reward);
        }
        
    }

receive() external payable {
 revert("This contract does not accept Ether directly. Use paintPixel function.");
}

}