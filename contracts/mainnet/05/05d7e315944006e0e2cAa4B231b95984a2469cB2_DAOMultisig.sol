/**
 *Submitted for verification at Arbiscan on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IERC20Permit {
 
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


library Address {
  
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount, 
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        
        require(
            success, 
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value, 
            "Address: insufficient balance for call"
        );

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(
        address target, 
        bytes memory data
    ) internal view returns (bytes memory) {
        return functionStaticCall(
            target, 
            data, 
            "Address: low-level static call failed"
        );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(
            target, 
            success, 
            returndata, 
            errorMessage
        );
    }

    function functionDelegateCall(
        address target, 
        bytes memory data
    ) internal returns (bytes memory) {
        return functionDelegateCall(
            target, 
            data, 
            "Address: low-level delegate call failed"
        );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token, 
            abi.encodeWithSelector(
                token.transfer.selector, 
                to, 
                value
            )
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token, 
            abi.encodeWithSelector(
                token.transferFrom.selector, 
                from, 
                to, 
                value
            )
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token, 
            abi.encodeWithSelector(
                token.approve.selector, 
                spender, 
                value
            )
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token, 
            abi.encodeWithSelector(
                token.approve.selector, 
                spender, 
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value, 
                "SafeERC20: decreased allowance below zero"
            );

            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token, 
                abi.encodeWithSelector(
                    token.approve.selector, 
                    spender, 
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1, 
            "SafeERC20: permit did not succeed"
        );
    }

    function _callOptionalReturn(
        IERC20 token, 
        bytes memory data
    ) private {
        bytes memory returndata = address(token).functionCall(
            data, 
            "SafeERC20: low-level call failed"
        );

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


interface IDAO {
    function setMultisig(address _multiSig) external returns(bool);
    function multisig() external view returns(address);
    function ethWithdraw(uint256 _amount, bool _all) external returns(bool);
    function ERC20Withdraw(IERC20 token, uint256 _amount, bool _all) external returns(bool);
}


contract DAOMultisig {

    using SafeERC20 for IERC20;
    mapping(address => mapping(bytes32 => bool)) public ownerApproved;
    address[] public owners;
 
    constructor(address[] memory _owners) {
        require(_owners.length > 0, "wrong owner count");
        owners = _owners;
    }
    
    receive() external payable {}

    function setMultisig(address _contract, address _newMultiSig) external {
        require(address(_contract) != address(0), "zero address");
        verifyOwnership(msg.sender);
        bytes32 signature = encodeSetMultisig(_contract, _newMultiSig);
        verifySignature(signature);
        require(IDAO(_contract).setMultisig(_newMultiSig), "tx error");
        require(consumeApproved(signature), "consume error");
    }

    function contractsEthWithdraw(
        address _contract, 
        uint256 _amount, 
        bool _all
    ) external {
        require(address(_contract) != address(0), "zero address");
        verifyOwnership(msg.sender);
        bytes32 signature = encodeContractsEthWithdraw(_contract, _amount, _all);
        verifySignature(signature);
        require(IDAO(_contract).ethWithdraw(_amount, _all), "tx error");
        require(consumeApproved(signature), "consume error");
    }

    function contractsERC20Withdraw(
        address _contract, 
        IERC20 token, 
        uint256 _amount, 
        bool _all
    ) external {
        require(
            address(_contract) != address(0), 
            "zero address contract"
        );

        require(address(token) != address(0), "zero address token");
        verifyOwnership(msg.sender);

        bytes32 signature = encodeContractsERC20Withdraw(
            _contract, 
            token, 
            _amount, 
            _all
        );

        verifySignature(signature);
        require(
            IDAO(_contract).ERC20Withdraw(token, _amount, _all),
            "tx error"
        );

        require(consumeApproved(signature), "consume error");
    }
    
    function ethWithdraw(uint256 _amount, bool _all) external {
        verifyOwnership(msg.sender);
        bytes32 signature = encodeEthWithdraw(_amount, _all);
        verifySignature(signature);
        uint256 balance = balanceEth();
        uint256 amountTotal;

        if(!_all){
            amountTotal = _amount;
        } else {
            amountTotal = balance;
        }

        require(
            amountTotal > 0 &&
            amountTotal <= balance,
            "wrong amount"
        );

        uint256 length = ownersLength();
        uint256 amountEach = uint256(amountTotal / length);

        for(uint256 i = 0; i < length;){
            (bool success,) = owners[i].call{value: amountEach}(bytes(""));
            require(success, "transfer error");

            unchecked {
                i++;
            }
        }

        require(consumeApproved(signature), "consume error");
    }

    function ERC20Withdraw(IERC20 token, uint256 amount, bool all) external {
        verifyOwnership(msg.sender);
        bytes32 signature = encodeERC20Withdraw(token, amount, all);
        verifySignature(signature);
        uint256 amountTotal;
        uint256 balance = balanceERC20(token);
        
        if(!all){
            amountTotal = amount;
        } else {
            amountTotal = balance;
        }

        require(
            amountTotal > 0 &&
            amountTotal <= balance,
            "wrong amount"
        );

        uint256 length = ownersLength();
        uint256 amountEach = uint256(amountTotal / length);

        for(uint256 i = 0; i < length;){
            token.safeTransfer(owners[i], amountEach);

            unchecked {
                i++;
            }
        }

        require(consumeApproved(signature), "consume error");
    }

    function ERC20transfer(
        address _to, 
        IERC20 _token, 
        uint256 _amount, 
        bool _all
    ) external {
        require(address(_to) != address(0), "zero address");
        verifyOwnership(msg.sender);

        bytes32 signature = encodeERC20transfer(
            _to, 
            _token, 
            _amount, 
            _all
        );

        verifySignature(signature);
        uint256 amountToSend;
        uint256 balance = balanceERC20(_token);
        
        if(!_all){
            amountToSend = _amount;
        } else {
            amountToSend = balance;
        }

        require(
            amountToSend > 0 &&
            amountToSend <= balance,
            "wrong amount"
        );

        _token.safeTransfer(_to, amountToSend);
        require(consumeApproved(signature), "consume error");
    }

    function ethTransfer(address _to, uint256 _amount, bool _all) external {
        require(address(_to) != address(0), "zero address");
        verifyOwnership(msg.sender);
        
        bytes32 signature = encodeEthTransfer(
            _to, 
            _amount,
            _all
        );

        verifySignature(signature);
        uint256 balance = balanceEth();
        uint256 amountToSend;

        if(!_all){
            amountToSend = _amount;
        } else {
            amountToSend = balance;
        }

        require(
            amountToSend > 0 &&
            amountToSend <= balance,
            "wrong amount"
        );

        (bool success,) = _to.call{value: amountToSend}(bytes(""));
        require(success, "transfer error");
        require(consumeApproved(signature), "consume error");
    }

    function approveTx(bytes32 _tx, bool _allow) external {
        verifyOwnership(msg.sender);
        ownerApproved[msg.sender][_tx] = _allow;
    }

    function setOwners(address[] memory _owners) external {
        require(_owners.length > 0, "no owner not allowed");
        verifyOwnership(msg.sender);
        bytes32 signature = encodeSetOwners(_owners);
        verifySignature(signature);
        owners = _owners;
        require(consumeApproved(signature), "consume error");
    }

    function universalTx(
        bytes memory data, 
        address to, 
        uint256 value
    ) external {
        verifyOwnership(msg.sender);
        
        bytes32 signature = keccak256(
            abi.encodePacked(
                data,
                to,
                value
            )
        );
        
        verifySignature(signature);
        (bool success, ) = to.call{value: value}(data);
        require(success, "tx error");
        require(consumeApproved(signature), "consume error");
    }

    function getMultisig(address _contract) public view returns(address){
        return IDAO(_contract).multisig();
    }

    function verifySignature(bytes32 _signature) public view {
        require(isApproved(_signature), "unauthorized");
    }

    function verifyOwnership(address _owner) public view {
        require(isOwner(_owner), "not owner");
    }

    function isOwner(address _owner) public view returns(bool){
        uint256 length = ownersLength();
        bool included;
        
        if(length > 0){
            for(uint256 i = 0; i < length;){
                
                if(_owner == owners[i]) {
                    included = true;
                    break;
                } 

                unchecked {
                    i++;
                }
            }
        }

        return included;
    }

    function ownersLength() public view returns(uint256) {
        return owners.length;
    }

    function isApproved(bytes32 _tx) public view returns(bool) {
        bool approved;
        uint256 length = ownersLength();
        
        if(length > 0){
            uint256 count;

            for(uint256 i = 0; i < length;){
                if(ownerApproved[owners[i]][_tx]) count += 1;

                unchecked {
                    i++;
                }
            }

            if(length <= 1){
               approved = count == 1 ? true : false;
            } else if( length % 2 == 0) {
                approved = count > length / 2 ? true : false;
            } else {
                approved = count >= (length + 1) / 2 ? true : false;
            }
        } 

        return approved;
    }

    function encodeERC20Withdraw(
        IERC20 token, 
        uint256 amount, 
        bool all
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "ERC20Withdraw(address,uint256,bool)", 
                address(token), 
                amount, 
                all
            )
        );
    }

    function encodeEthWithdraw(
        uint256 amount, 
        bool all
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "ethWithdraw(uint256,bool)", 
                amount, 
                all
            )
        );
    }

    function encodeSetMultisig(
        address _contract, 
        address _newMultisig
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "setMultisig(address,address)", 
                _contract, 
                _newMultisig
            )
        );
    }

    function encodeSetOwners(
        address[] memory _owners
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "setOwners(address[])", 
                _owners
            )
        );
    }

    function encodeContractsEthWithdraw(
        address _contract, 
        uint256 _amount, 
        bool _all
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "contractsEthWithdraw(address,uint256,bool)", 
                _contract,  
                _amount,  
                _all
            )
        );
    }

    function encodeContractsERC20Withdraw(
        address _contract, 
        IERC20 token, 
        uint256 _amount, 
        bool _all
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "contractsERC20Withdraw(address,address,uint256,bool)", 
                _contract, 
                address(token), 
                _amount, 
                _all
            )
        );
    }

    function encodeERC20transfer(
        address _to, 
        IERC20 token, 
        uint256 amount, 
        bool _all
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "ERC20transfer(address,address,uint256,bool)",  
                _to, 
                address(token), 
                amount, 
                _all
            )
        );
    }

    function encodeEthTransfer(
        address _to, 
        uint256 _amount, 
        bool _all
    ) public pure returns(bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "ethTransfer(address,uint256,bool)",  
                _to, 
                _amount, 
                _all
            )
        );
    }

    function consumeApproved(bytes32 _tx) private returns(bool){
        uint256 length = ownersLength();
        
        if(length > 0){
            
            for(uint256 i = 0; i < length;){
                
                if(ownerApproved[owners[i]][_tx]){
                    delete ownerApproved[owners[i]][_tx];
                }

                unchecked {
                    i++;
                }
            }
        }
        
        return true;     
    }

    function balanceERC20(IERC20 token) public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function balanceEth() public view returns(uint256){
        return address(this).balance;
    }
}