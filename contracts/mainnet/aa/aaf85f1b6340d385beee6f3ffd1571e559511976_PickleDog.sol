/**
 *Submitted for verification at Arbiscan.io on 2024-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PickleDog is IERC20 { 
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
	uint256 private _totalSupply;
	address private immutable _atoken = 0x724dc807b04555b71ed48a6896b6F41593b8C637;    //aUSDC 
    string public name;// "Pickle Dog Meme Coin";
    string public symbol;// "PKLD";
    uint8 public decimals;// = 6;
    using Address for address;
	uint256 private immutable maxSupply = 69420000000000*(1e6); //69.42T;
	uint256 private tkReserve = 6000 * (1e6); //Virtual Assets
   	
	error SafeERC20FailedOperation(address token);
	error InsufficientBalance(address sender, uint256 balance, uint256 needed);
	error InsufficientFunds();
	error InvalidApprover();
	error InvalidSpender();
    error InvalidReceiver();
	error InvalidAmount();
	error InvalidAssets();
	error ExceededCap(uint256 increasedSupply, uint256 cap);
	error ExpiredSignature(uint256 deadline);
	
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
	
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
	
	function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
	
    function transfer(address recipient, uint256 value) external returns (bool) {
		_transfer(msg.sender, recipient, value);      
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
	    if (msg.sender == address(0)) {
            revert InvalidApprover();
        }
        if (spender == address(0)) {
            revert InvalidSpender();
        } 
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
	    uint256 currAllow =  _allowances[sender][msg.sender];
        if (currAllow != type(uint256).max) {
            if (currAllow < amount) {
                revert InsufficientFunds();
            }
            unchecked {
                _allowances[sender][msg.sender] -= amount;
            }
        }       
        _transfer(sender, recipient, amount);
        return true;
    }
    
	function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert InvalidSpender();
        }
        if (to == address(0)) {
            revert InvalidReceiver();
        }
        _update(from, to, value);
    }
	
	function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that _totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= _totalSupply.
                _balances[from] = fromBalance - value;
            }
        }
        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= _totalSupply or value <= fromBalance <= _totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most _totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }
        emit Transfer(from, to, value);
    }
    
	function pklReserve() public view virtual returns (uint256) {
        unchecked {
          return maxSupply - _totalSupply;
        }
    }  
  	
    function LiquidityMining(uint256 assets) external returns (bool) {
	    if (assets <= 0) revert InvalidAssets();
        safeTransferFrom(IERC20(_atoken), msg.sender, address(this), assets); 				
		uint256 pklamt = assets * pklReserve() / totalAssets(); 	
        _update(address(0), msg.sender, pklamt);
        if (_totalSupply > maxSupply) {
                revert ExceededCap(_totalSupply, maxSupply);
        }		
		return true;
    }
	
    function Redeem(uint256 amount) external returns (bool){ 
	    if (amount <= 0) revert InvalidAmount(); 
        _update(msg.sender, address(0), amount);    	
		uint256 tkAmount =  amount * totalAssets()/pklReserve();	
		safeTransfer(IERC20(_atoken), msg.sender, tkAmount);		 
		return true;
    }
	
	function totalAssets() public view returns (uint256) { 
		unchecked {
		    return tkReserve + IERC20(_atoken).balanceOf(address(this));
		}
    }
	
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }
	
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }
}