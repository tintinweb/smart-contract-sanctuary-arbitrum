/**
 *Submitted for verification at Arbiscan on 2023-01-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256 z){
        require(y > 0);
        z=x/y;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 value, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

contract OwnableData {
    address public owner;
    address public Nodes;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    function setNodesAddress(address _nodes) public {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        Nodes = _nodes;
    }
    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyNodes() {
        require(msg.sender == Nodes, "Ownable: caller is not the nodes");
        _;
    }

}

interface INodes {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function mintFromRewards(uint256 _type, address to) external;
    function getMintPrices() external view returns (uint256[4] memory);
}

contract rewardPool is Ownable {
    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint256;
    struct NftData{
        uint256 nodeType;
        address owner;
        uint256 lastClaim;
        uint256 expiry;
    }
    // Reward rate per day for each type of node (1e9 = 1 Skynet)
    // 0.001, 0.0125, 0.08, 0.2 eachday
    uint256[4] public rewardRates = [1000000, 12500000, 80000000, 200000000];
    uint256[5] public claimTaxRates = [0, 0, 0, 0, 0]; // Claim rates for week 1, 2, 3, 4, and 5 respectively

    mapping (uint256 => NftData) public nftInfo;
    uint256 totalNodes = 0;
    address public Skynet;
    mapping (address => uint256) public soldNodeRewards;
    
    uint256[4] public expiryDays = [150, 200, 250, 300];

    uint256 private mnth = 60 * 60 * 24 * 30;
    uint256 private wk = 60 * 60 * 24 * 7;
    uint256 private day = 60 * 60 * 24;

    uint256 public discount = 10; // Will get 10% if you mint with rewards

    mapping (address => uint256) public lastClaimed;

    constructor(address _skynetAddress, address _nodeAddress) {     
        Skynet = _skynetAddress;
        Nodes = _nodeAddress;
    }
    
    receive() external payable {

  	}

    function updateDiscount(uint256 _discount) public onlyOwner {
        discount = _discount;
    }

    function updateClaimTaxRates(uint256[5] memory _claimTaxRates) public onlyOwner {
        claimTaxRates = _claimTaxRates;
    }

    function addNodeInfo(uint256 _nftId, uint256 _nodeType, address _account) external onlyNodes returns (bool success) {
        require(nftInfo[_nftId].owner == address(0), "Node already exists");
        nftInfo[_nftId].nodeType = _nodeType;
        nftInfo[_nftId].owner = _account;
        nftInfo[_nftId].lastClaim = block.timestamp;
        nftInfo[_nftId].expiry = block.timestamp + (day*expiryDays[_nodeType]);
        totalNodes += 1;
        return true;
    }


    // 20% claim tax first week, 10% second week, 5% third week, 2% fourth week, 1% fifth week  else 0%
    function _calculateClaimTax(address _account) internal view returns (uint256 tax) {
        tax = claimTaxRates[0];
        uint256 lastClaim = lastClaimed[_account];
        if (lastClaim != 0){

            uint256 currentTime = block.timestamp;
            uint256 timeDifference = currentTime - lastClaim;
            uint256 wks = (timeDifference / (wk));
            if (wks == 0) {
                tax = claimTaxRates[0];
            } else if (wks == 1) {
                tax = claimTaxRates[1];
            } else if (wks == 2) {
                tax = claimTaxRates[2];
            } else if (wks == 3) {
                tax = claimTaxRates[3];
            } else if (wks == 4) {
                tax = claimTaxRates[4];
            }
            else{
                tax = 0;
            }
        }
        return tax;
    }

    function claimTax(address _address) external view returns (uint256 tax) {
        tax = _calculateClaimTax(_address);
        return tax;
    }

    function updateNodeOwner(uint256 _nftId, address _account) external onlyNodes returns (bool success) {
        require(nftInfo[_nftId].owner != address(0), "Node does not exist");
        uint256 pendingRewards = pendingRewardFor(_nftId);
        soldNodeRewards[nftInfo[_nftId].owner] += pendingRewards;
        nftInfo[_nftId].lastClaim = block.timestamp;
        nftInfo[_nftId].owner = _account;
        return true;
    }


    function pendingRewardFor(uint256 _nftId) public view returns (uint256 _reward) {
        uint256 _nodeType = nftInfo[_nftId].nodeType;
        uint256 _lastClaim = nftInfo[_nftId].lastClaim;
        uint256 _expiry = nftInfo[_nftId].expiry;
        uint256 _currentTime = block.timestamp;
        uint256 _daysSinceLastClaim;
        if (_currentTime > _expiry) {
            //node expired
            if (_expiry <= _lastClaim){
                _daysSinceLastClaim = 0;
            }
            else{
                _daysSinceLastClaim = ((_expiry - _lastClaim).mul(1e9)) / 86400;
            }    
        }
        else{
                _daysSinceLastClaim = ((_currentTime - _lastClaim).mul(1e9)) / 86400;
        }
        _reward = (_daysSinceLastClaim * rewardRates[_nodeType-1]).div(1e9);
        return _reward;
    }

    function saveRewards(address _account) private{
        uint256[] memory tokens = INodes(Nodes).walletOfOwner(_account);
        uint256 totalReward = soldNodeRewards[_account];
        for (uint256 i; i < tokens.length; i++) {
            totalReward += pendingRewardFor(tokens[i]);
            nftInfo[tokens[i]].lastClaim = block.timestamp;
        }
        
        soldNodeRewards[_account] = totalReward;
    }

    function mintNode(uint256 _type) public{
        saveRewards(msg.sender);
        uint256 pendingRewards = soldNodeRewards[msg.sender];
        uint256[4] memory mintPrices = INodes(Nodes).getMintPrices();
        uint256 priceAfterDiscount = mintPrices[_type-1].mul(discount).div(1e2);
        require(pendingRewards >= priceAfterDiscount, "Not enough rewards");
        soldNodeRewards[msg.sender] -= priceAfterDiscount;
        INodes(Nodes).mintFromRewards(_type, msg.sender);

    }


    function claimRewards() public returns (bool success) {
        
        saveRewards(msg.sender);
        uint256 totalReward = soldNodeRewards[msg.sender];

        uint256 tax = _calculateClaimTax(msg.sender);
        uint256 totalTax = totalReward * tax / 100;
        uint256 amount = (totalReward - totalTax);
        
        soldNodeRewards[msg.sender] = 0;
        lastClaimed[msg.sender] = block.timestamp;
        
        IERC20(Skynet).transfer(msg.sender, amount);
        return true;
    }

    function claimableRewards() public view returns (uint256 _reward) {
        uint256 totalReward = soldNodeRewards[msg.sender];
        uint256[] memory tokens = INodes(Nodes).walletOfOwner(msg.sender);
        for (uint256 i; i < tokens.length; i++) {
            totalReward += pendingRewardFor(tokens[i]);
        }
        return totalReward;
    }

    function emergenceyWithdrawTokens() public onlyOwner {
        IERC20(Skynet).transfer(owner, IERC20(Skynet).balanceOf(address(this)));
    }


    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }


}